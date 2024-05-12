{ pkgs, config, lib, ... }:

let 
	zshConf = builtins.readFile ./zshrc;
in
{
	programs.bash = {
		enable = true;
		enableCompletion = false;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    historyIgnore = [ "ls" "cd" "exit" ];

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
    
    shopt -s histappend
    shopt -s cmdhist
    shopt -s lithist
    shopt -s interactive_comments
    shopt -s extglob

    shopt -s dirspell

    shopt -s nocaseglob

    shopt -s extglob
    shopt -s globstar

		'';

		initExtra = ''

		export PATH=$PATH:"/run/current-system/sw/bin:/etc/profiles/per-user/katob/bin:${config.home.homeDirectory}/.local/share/tridactyl"

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

		source "${config.home.homeDirectory}"/.config/git-alias/git-aliases.sh

    set -o vi

		stty -ixon

    PROMPT_COMMAND='PS1="\n[\w] $(git branch 2>/dev/null | grep '^*' | colrm 1 2)\n # "'
    RPROMPT='$(if [ $? -ne 0 ]; then echo "error "; fi)$(jobs | wc -l | awk '"'"'{if($1>0) print $1 " jobs";}'"'"')"

		export VIRTUAL_ENV_DISABLE_PROMPT=1

		'';
	};
}
