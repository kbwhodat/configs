#!/bin/bash

# Access the full path using ZED_FILE
full_path="$ZED_FILE"

# Extract filename with extension
filename_ext=$(basename "$full_path")

# Extract filename and extension
filename="${filename_ext%.*}"
extension="${filename_ext##*.}"

echo "[running $filename_ext]"

if [[ "$extension" == "cpp" ]]; then
    g++ "$full_path" -o "$filename" && ./"$filename";
elif [[ "$extension" == "py" ]]; then
    python3 "$full_path";
elif [[ "$extension" == "c" ]]; then
    clang "$full_path" -o "$filename" && ./"$filename" && rm "$filename";
else
    echo "no"
fi
