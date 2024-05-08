{ pkgs, config, lib, ... }:

let 
	zshConf = builtins.readFile ./zshrc;
in
{
	programs.zsh = {
		enable = true;
		enableAutosuggestions = false;
		enableCompletion = false;
		dotDir = ".config/zsh";
		plugins = [
			{
				name = "vi-mode";
				src = pkgs.zsh-vi-mode;
				file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
			}
		];

		history = {
			expireDuplicatesFirst = true;
			ignoreDups = true;
			ignoreSpace = true;
		};

		sessionVariables = {
			EDITOR = "nvim";
			TERM = "xterm-256color";
			COLORTERM = "truecolor";
		};

		profileExtra = ''
			setopt incappendhistory
      setopt histfindnodups
      setopt histreduceblanks
      setopt histverify
      setopt correct                                                  # Auto correct mistakes
      setopt extendedglob                                             # Extended globbing. Allows using regular expressions with *
      setopt nocaseglob                                               # Case insensitive globbing
      setopt rcexpandparam                                            # Array expension with parameters
      #setopt nocheckjobs                                              # Don't warn about running processes when exiting
      setopt numericglobsort                                          # Sort filenames numerically when it makes sense
      setopt appendhistory                                            # Immediately append history instead of overwriting
      unsetopt histignorealldups                                      # If a new command is a duplicate, do not remove the older one
      setopt interactivecomments
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case insensitive tab completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"       # Colored completion (different colors for dirs/files/etc)
      zstyle ':completion:*' rehash true                              # automatically find new executables in path
      # Speed up completions
      # zstyle ':completion:*' accept-exact '*(N)'
      # zstyle ':completion:*' use-cache on
      # mkdir -p "$(dirname ${config.xdg.cacheHome}/zsh/completion-cache)"
      # zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/completion-cache"
      # zstyle ':completion:*' menu select
      # WORDCHARS=''${WORDCHARS//\/[&.;]}                                 # Don't consider certain characters part of the word

		'';

		initExtra = ''

		alias ls='ls --color'
		alias cat='bat --style plain'
		alias vim="$(which nvim)"

		if [ -z "$TMUX" ]; then  # Check if not already in a tmux session
			TMUX_SESSION="genesis"
			if tmux has-session -t $TMUX_SESSION 2>/dev/null; then
				tmux attach-session -t $TMUX_SESSION
			else
				tmux new-session -s $TMUX_SESSION
			fi
		fi

		autoload -Uz compinit
		compinit

		source "${config.home.homeDirectory}"/.config/git-alias/git-aliases.zsh
		source "${config.home.homeDirectory}"/.config/git-alias/lib/git.zsh


		# configure key keybindings
		bindkey -e                                        # emacs key bindings
		bindkey ' ' magic-space                           # do history expansion on space
		bindkey '^[[3;5~' kill-word                       # ctrl + Supr
		bindkey '^[[3~' delete-char                       # delete
		bindkey '^[[1;5C' forward-word                    # ctrl + ->
		bindkey '^[[1;5D' backward-word                   # ctrl + <-
		bindkey '^[[5~' beginning-of-buffer-or-history    # page up
		bindkey '^[[6~' end-of-buffer-or-history          # page down
		bindkey '^[[H' beginning-of-line                  # home
		bindkey '^[[F' end-of-line                        # end
		bindkey '^[[Z' undo                               # shift + tab undo last action

		export PATH=$PATH:"/run/current-system/sw/bin"

		stty -ixon

		'';
	};
}
