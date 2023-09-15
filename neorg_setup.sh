#!/bin/bash

zig build-exe git_push.zig --name neorg
mv neorg /usr/local/bin/

rm neorg.o
echo "Cleaning Up..."

if [ $? -eq 0 ]; then
	echo "Neorg binary is now in place. You can now use it."
fi


