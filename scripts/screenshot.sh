#!/bin/bash

# Directory where screenshots will be saved
screenshot_dir="$HOME/Documents/screenshots"

# Ensure the screenshot directory exists
mkdir -p "$screenshot_dir"

# Use zenity to input the filename
filename=$(zenity --entry --title="Enter filename" --text="Enter the name for the screenshot:")

# Exit if cancel is pressed or no input is given
if [ -z "$filename" ]; then
    exit
fi

# Full path for the screenshot
file_path="$screenshot_dir/$filename.png"

# Take a screenshot and save it to the specified file path
scrot --select --line mode=edge "$file_path"

# Copy the file path to the clipboard
echo -n "$file_path" | xclip -selection clipboard

# Optional: Notify that the screenshot has been taken and path copied
notify-send "Screenshot saved and path copied to clipboard: $file_path"
