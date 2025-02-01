
_build_fallback_staging-zUpgradeYML-before_noBoot() {
    _messageNormal 'init: _build_fallback_staging-zUpgrade-before_noBoot'

    true
}

_build_fallback_staging-zUpgradeYML-build() {
    _messageNormal '_build_fallback_staging-zUpgrade-boot'

    ! "$scriptAbsoluteLocation" _openChRoot && _messagePlain_bad 'fail: _openChRoot' && _messageFAIL

    ! _chroot df -h / && _messagePlain_bad 'fail: chroot: df -h /' && _messageFAIL

    ! "$scriptAbsoluteLocation" _closeChRoot && _messagePlain_bad 'fail: _closeChRoot' && _messageFAIL

    true
}


_build_fallback_staging-zCustomYML-before_noBoot() {
    _messageNormal 'init: _build_fallback_staging-zCustomYML-before_noBoot'

    #_build_fallback_staging-zUpgrade-before_noBoot "$@"
    true
}

_build_fallback_staging-zCustomYML-build() {
    _messageNormal '_build_fallback_staging-zCustomYML-boot'

    _build_fallback_staging-zUpgradeYML-build "$@"
}


_build_fallback_staging-buildYML-build_beforeBoot() {
    _messageNormal 'init: _build_fallback_staging-buildYML-build_beforeBoot'

    _build_fallback_staging-zUpgradeYML-build "$@"
}

_build_fallback_staging-buildYML-build() {
    _messageNormal '_build_fallback_staging-buildYML-boot'
    
    #_build_fallback_staging-zUpgradeYML-build "$@"
    true
}



