#!/bin/bash

# Access the full path using ZED_FILE
full_path="$ZED_FILE"

# Extract filename with extension
filename_ext=$(basename "$full_path")

# Extract filename and extension
filename="${filename_ext%.*}"
extension="${filename_ext##*.}"

echo "[running $filename_ext]"

# c++
if [[ "$extension" == "cpp" ]]; then
    g++ "$full_path" -o "$filename" && ./"$filename";

# python
elif [[ "$extension" == "py" ]]; then
    python3 "$full_path";

# c
elif [[ "$extension" == "c" ]]; then
    compile_flags="$(pkg-config --cflags libpq)"
    linker_flags="$(pkg-config --libs libpq)"
    clang $compile_flags "$full_path" -o "$filename" $linker_flags && ./"$filename" && rm "$filename";

# golang
elif [[ "$extension" == "go" ]]; then
    go build "$full_path" && ./"$filename" && rm "$filename";

else
    echo "no"
fi
