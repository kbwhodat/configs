#!/bin/bash

# Check if Kitty is running
KITTY_WINDOW=$(xdotool search --onlyvisible --class kitty)

if [ -z "$KITTY_WINDOW" ]; then
    # If Kitty is not running, start it with tdrop
		if pgrep kitty >/dev/null; then
			tdrop -a -w 50% -h 50% -x 0% -y 0 kitty &
		fi
else
    # If Kitty is running, check its fullscreen state
    FULLSCREEN=$(xprop -id $KITTY_WINDOW | grep "_NET_WM_STATE_FULLSCREEN")

    if [ -z "$FULLSCREEN" ]; then
        # If not fullscreen, make it fullscreen
        i3-msg "[id=$KITTY_WINDOW] fullscreen"
    else
        # If fullscreen, return to half-screen size
        i3-msg "[id=$KITTY_WINDOW] fullscreen disable"
    fi
fi

