#!/bin/sh

xrandr --output eDP-1 --off
xrandr --output DP-1-3.2 --primary --mode 1920x1080 --pos 0x0 --output DP-1-1 --mode 1920x1080 --right-of DP-1-3.2

