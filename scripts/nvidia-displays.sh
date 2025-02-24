
if xrandr | grep -q "DP-1 connected" && xrandr | grep -q "DP-3.1 connected"; then
    # Set up the displays using nvidia-settings
    nvidia-settings --assign "CurrentMetaMode=DP-3.1: 1920x1080_75 +0+0, DP-3.2: 1920x1080_75 +1920+0"
    # nvidia-settings --assign "CurrentMetaMode=DP-3.1: 1920x1080_75 +0+0, DP-3.2: 1920x1080_75 +1920+0"
fi
