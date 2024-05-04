#!/bin/bash

# Get the ID of the focused window
FOCUSED_WINDOW_ID=$(xdotool getwindowfocus)

# Get the first Kitty window ID
KITTY_WINDOW_ID=$(xdotool search --class kitty | head -1)

if [ -z "$KITTY_WINDOW_ID" ]; then
    # If Kitty is not running, start it
		if pgrep kitty >/dev/null; then
			tdrop -a -w 50% -h 50% -x 0% -y 0 kitty &
		fi
else
    # Get the current and Kitty's workspace
    CURRENT_WORKSPACE=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused == true).name')
    KITTY_WORKSPACE=$(i3-msg -t get_tree | jq -r --arg id "$KITTY_WINDOW_ID" '.. | select(.id? == ($id | tonumber)).workspace.name')

    if [ "$FOCUSED_WINDOW_ID" -eq "$KITTY_WINDOW_ID" ]; then
				WINDOW_PROPERTIES=$(i3-msg -t get_tree | jq -r --arg id "$KITTY_WINDOW_ID" '.. | select(.window? == ($id | tonumber))')

				if echo "$WINDOW_PROPERTIES" | grep -q '"fullscreen_mode": 1'; then
					# If Kitty is focused, minimize it
					i3-msg "[id=$KITTY_WINDOW_ID] move scratchpad, fullscreen enable"
				else
					i3-msg "[id=$KITTY_WINDOW_ID] move scratchpad"
				fi
    elif [ "$CURRENT_WORKSPACE" = "$KITTY_WORKSPACE" ]; then
        # If Kitty is on the current workspace but not focused
        i3-msg "[id=$KITTY_WINDOW_ID] scratchpad show"
    else
        # Switch to the workspace where Kitty is located
				i3-msg "[id=$KITTY_WINDOW_ID] focus"
    fi
fi
