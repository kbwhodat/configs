{ pkgs, config, lib, ... }:

# let 
# 	zshConf = builtins.readFile ./zshrc;
# in
let
  inherit (pkgs.stdenv) isDarwin;
in
{
	programs.zsh = {
		enable = true;
		autosuggestion.enable = false;
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
      TMUX_CONF = "~/.config/tmux/tmux.conf";
		};

		profileExtra = ''
			setopt incappendhistory
      setopt histfindnodups
      setopt histreduceblanks
      setopt histverify
      setopt correct                                                  # Auto correct mistakes
      setopt extendedglob                                             # Extended globbing. Allows using regular expressions with *
      setopt nocaseglob                                               # Case insensitive globbing
      setopt numericglobsort                                          # Sort filenames numerically when it makes sense
      setopt appendhistory                                            # Immediately append history instead of overwriting
      unsetopt histignorealldups                                      # If a new command is a duplicate, do not remove the older one
      setopt interactivecomments
      # zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case insensitive tab completion
      # zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"       # Colored completion (different colors for dirs/files/etc)
      zstyle ':completion:*' rehash true                              # automatically find new executables in path
      # Speed up completions
      # zstyle ':completion:*' accept-exact '*(N)'
      # zstyle ':completion:*' use-cache on
      # mkdir -p "$(dirname ${config.xdg.cacheHome}/zsh/completion-cache)"
      # zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/completion-cache"
      # zstyle ':completion:*' menu select
      # WORDCHARS=''${WORDCHARS//\/[&.;]}                                 # Don't consider certain characters part of the word

		'';

		initContent = ''

		export PATH=$PATH:"/run/current-system/sw/bin:/etc/profiles/per-user/katob/bin:${config.home.homeDirectory}/.emacs.d/bin"

    export ${ if isDarwin then "DRI_PRIME=0" else "DRI_PRIME=1" }

    keepassxc_helper() {
      local DATABASE="/home/katob/.database/keedatabase.kdbx"

      keepassxc-cli "$1" "$DATABASE" "''${@:2}"
    }

		alias ls='ls --color'
		alias cat='bat --style plain'
		alias vim="$(which nvim)"
		alias vi="$(which vim)"

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


    if [[ ''${uname} == "Darwin" ]]; then
      if [ ! -f /usr/local/bin/pinentry-mac ]; then
        ln -s /run/current-system/sw/bin/pinentry-mac /usr/local/bin/pinentry-mac
      fi
    else
        alias zed="$(which zeditor)"
    fi

		source "${config.home.homeDirectory}"/.config/git-alias/git-aliases.zsh
		# source "${config.home.homeDirectory}"/.config/git-alias/lib/git.zsh

    alias clear="tput reset"

    if [[ ''${uname} == "Darwin" ]]; then
      export DOCKER_HOST="unix://${config.home.homeDirectory}/.colima/default/docker.sock"
      export LIBRARY_PATH="${if isDarwin then pkgs.libiconv-darwin else pkgs.libiconv}/lib"
    fi

		# configure key keybindings
		bindkey -v                                        # emacs key bindings
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

    zvm_after_init_commands+=("bindkey '^[[1;5C' forward-word")
    zvm_after_init_commands+=("bindkey '^[[1;5D' backward-word")

		stty -ixon

		# Load necessary functions and enable substitution in prompt
		autoload -Uz add-zsh-hook vcs_info
		setopt prompt_subst
		add-zsh-hook precmd vcs_info

		zstyle ':vcs_info:*' check-for-changes true
		zstyle ':vcs_info:*' unstagedstr ' !'
		zstyle ':vcs_info:*' stagedstr ' +'
		zstyle ':vcs_info:git:*' formats '(%b%u%c)'
		zstyle ':vcs_info:git:*' actionformats '(%b|%a%u%c)'

    command_not_found_handler() {
      echo "command not found: $1" >&2
      return 127
    }

		PROMPT=$'\n[%~] ''${vcs_info_msg_0_}\n # '

    RPROMPT=$'%(1j. %j ⚙.)'

		VIRTUAL_ENV_DISABLE_PROMPT=1

		'';
	};
}
