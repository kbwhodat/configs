#!/usr/bin/env bash


if [[ $# -eq 1 ]]; then
    selected=$1
else
    # Run the selection process in a subshell as one combined command
    selected=$( (fd . ~/Documents ~/.config ~/vault --type d --min-depth 1 | fzf --height 35% --preview="tree -C {} | head -n 10") )
fi

if [[ -z $selected ]]; then
    exit 0
fi

pane_width=$(tmux display -p '#{pane_width}')
pane_height=$(tmux display -p '#{pane_height}')
min_width_for_horizontal=120  # Minimum width to prefer horizontal split

if [[ $pane_width -gt $min_width_for_horizontal ]]; then
	tmux split-window -h -c "$selected"
else
	tmux split-window -v -c "$selected"
fi
