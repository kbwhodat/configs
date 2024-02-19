#!/usr/bin/env bash

i3status -c ~/.config/i3status/config | while :
do
  read line
  pomodoro=`i3-gnome-pomodoro status`
  echo "$pomodoro| $line" || exit 1
done
