
```

# Terminates user session (display manager and processes), creates container (with flipKey), copies existing HOME directory, mounts over HOME directory, restarts display manager (ie. sddm).

#_mustBeRoot
#cd /root

wget https://bit.ly/rootGrabSh
mv rootGrabSh _rootGrab.sh
chmod u+x _rootGrab.sh
./_rootGrab.sh _hook
echo > /regenerate_rootGrab
./_rootGrab.sh __grab_hook


```

