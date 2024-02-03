#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then
	~/.tmux/plugins/tpm/tpm
elif [[ $(uname) == "Linux" ]]; then
	/usr/share/tmux-plugin-manager/tpm
fi


