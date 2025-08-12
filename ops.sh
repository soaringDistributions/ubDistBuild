# 2025.08.11 rmh Address occasional build failures due to missing part file asset

#!/usr/bin/env bash
# ops.sh — runtime overrides loaded by ubiquitous_bash.sh

# --- Strict timeout: non-zero on timeout, prefer coreutils 'timeout' ---
_timeout_strict() {
  _messagePlain_probe "_timeout_strict → $(printf '%q ' "$@")"
  if command -v timeout >/dev/null 2>&1; then
    # Expected exits:
    #  0: success
    #  124: command timeout
    #  125: timeout command failed 
    #  126/7: command could not run
    #  Other: command exit code 
    _messagePlain_probe "_timeout_strict: coreutils timeout path"
    timeout -k 5 "$@"; local rc=$?
    _messagePlain_probe "_timeout_strict: coreutils rc=$rc"
    return "$rc"
  fi

  _messagePlain_probe "_timeout_strict: fallback path"
  (
    set +b
    local secs rc krc
    secs="$1"; shift
    _messagePlain_probe "_timeout_strict(fb): secs=$(printf '%q' "$secs") cmd=$(printf '%q ' "$@")"
    "$@" & local cmd=$!
    _messagePlain_probe "_timeout_strict(fb): cmd pid=$cmd"
    (
      sleep "$secs"
      # Process should have completed. If not, try to Term/Kill
      if kill -0 "$cmd" 2>/dev/null; then
        _messageWARN "_timeout_strict(fb): timeout fired → TERM pid $cmd"
        kill -TERM "$cmd" 2>/dev/null
        sleep 3
        if kill -0 "$cmd" 2>/dev/null; then
          _messageWARN "_timeout_strict(fb): escalation → KILL $cmd"
          kill -KILL "$cmd" 2>/dev/null
        fi
        exit 124      # value for subprocess - not exposed to function
      fi
      exit 0
    ) & local killer=$!
    _messagePlain_probe "_timeout_strict(fb): killer pid=$killer"

    wait "$cmd"; rc=$?
    _messagePlain_probe "_timeout_strict(fb): cmd exited rc=$rc"

    # learn what the timer did
    if kill -0 "$killer" 2>/dev/null; then
      _messagePlain_probe "_timeout_strict(fb): cancel timer pid=$killer"
      kill -TERM "$killer" 2>/dev/null
      wait "$killer" 2>/dev/null
      krc=0
    else
      wait "$killer"; krc=$?
    fi

    case "$krc" in
      124) _messageWARN "_timeout_strict(fb): timer exited 124 (timeout occurred)";;
      0)   _messagePlain_probe "_timeout_strict(fb): timer exited 0 (no timeout)";;
      *)   _messageWARN "_timeout_strict(fb): timer exited rc=$krc";;
    esac

    _messagePlain_probe "_timeout_strict(fb): returning rc=$rc"
    exit "$rc"
    # Expected return values
    #  0: success of command 
    #  143: TERMinated
    #  137: KILLed 
    #  Other: command value 
  )
}


# --- helper: check if an asset name exists on a tag ---
_gh_release_asset_present() {
  local currentTag="$1"
  local assetName="$2"
  "$scriptAbsoluteLocation" _timeout_strict 120 \
    gh release view "$currentTag" --json assets 2>/dev/null \
    | grep -F "\"name\":\"$assetName\"" >/dev/null
}

# --- override: single file uploader with real retries and status ---
_gh_release_upload_part-single_sequence() {
  _messagePlain_nominal '==rmh== _gh_release_upload: '"$1"' '"$2"
  local currentTag="$1"
  local currentFile="$2"

  local currentIteration=0
  local rc=1
  local assetName
  assetName=$(basename -- "$currentFile")

  while [[ "$currentIteration" -le 30 ]]; do
    if "$scriptAbsoluteLocation" _stopwatch \
         _timeout_strict 600 \
         gh release upload --clobber "$currentTag" "$currentFile"
    then
      # Verify asset is visible (eventual consistency guard)
      local vtries=0
      while [[ $vtries -lt 5 ]]; do
        if _gh_release_asset_present "$currentTag" "$assetName"; then
          rc=0
          break
        fi
        sleep 2
        let vtries++
      done
      if [[ $rc -eq 0 ]]; then
        _messagePlain_probe "==rmh== uploaded ✓ $assetName"
        break
      else
        _messageWARN "==rmh== ** gh exited 0 but asset not listed yet; retrying: $assetName"
      fi
    else
      _messageWARN "==rmh== ** upload attempt $((currentIteration+1)) failed: $assetName"
    fi
    sleep 7
    let currentIteration++
  done

  if [[ $rc -ne 0 ]]; then
    _messageFAIL "==rmh== ** upload failed after retries: $assetName → $currentTag"
  fi
  return "$rc"
}

# --- optional override: verify all parts after the fan-out completes ---
_gh_release_upload_parts-multiple_sequence() {
  _messageNormal '==rmh== _gh_release_upload_parts: '"$@"
  local currentTag="$1"; shift

  local currentStream_max=12
  local currentStreamNum=0
  # keep a copy of the file list for verification later
  local -a __files=( "$@" )

  for currentFile in "${__files[@]}"; do
    let currentStreamNum++
    "$scriptAbsoluteLocation" _gh_release_upload_part-single_sequence "$currentTag" "$currentFile" &
    eval local currentStream_${currentStreamNum}_PID="$!"
    _messagePlain_probe_var currentStream_${currentStreamNum}_PID

    while [[ $(jobs | wc -l) -ge "$currentStream_max" ]]; do
      echo; jobs; echo
      sleep 2
      true
    done
  done

  local currentStreamPause
  for currentStreamPause in $(seq "1" "$currentStreamNum"); do
    _messagePlain_probe "==rmh==currentStream_${currentStreamPause}_PID= $(eval "echo \$currentStream_${currentStreamPause}_PID")"
    if eval "[[ \$currentStream_${currentStreamPause}_PID != '' ]]"; then
      _messagePlain_probe "==rmh== _pauseForProcess $(eval "echo \$currentStream_${currentStreamPause}_PID")"
      _pauseForProcess        $(eval "echo \$currentStream_${currentStreamPause}_PID")
    fi
  done

  while [[ $(jobs | wc -l) -ge 1 ]]; do
    echo; jobs; echo
    sleep 2
    true
  done
  wait  # reap

  # Post-verify: ensure every asset exists; fail if any missing
  local rc=0
  local assets_json
  assets_json=$("$scriptAbsoluteLocation" _timeout_strict 180 gh release view "$currentTag" --json assets 2>/dev/null || true)

  local f
  for f in "${__files[@]}"; do
    local name="$(basename -- "$f")"
    if ! printf '%s' "$assets_json" | grep -F "\"name\":\"$name\"" >/dev/null; then
      _messageFAIL "==rmh== ** missing asset on release: $name"
      rc=1
    else
      _messagePlain_probe "==rmh== asset verified: $name"
    fi

  done
  if [[ $rc -ne 0 ]]; then
    _messageFAIL "==rmh== ** some assets were not uploaded successfully"
  else
    _messagePlain_probe "==rmh== all assets verified successfully"
  fi
  return "$rc"
}
