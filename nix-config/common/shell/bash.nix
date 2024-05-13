{ pkgs, config, lib, ... }:

{
	programs.bash = {
		enable = true;
		enableCompletion = false;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    historyIgnore = [ "ls" "cd" "exit" ];

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

PROMPT_COMMAND='
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null);
  if [ -n "$current_branch" ]; then
    # Check git status for different states
    git_status=$(git status --porcelain);
    staged=$(echo "$git_status" | grep "^[MADRC]" | wc -l);
    untracked=$(echo "$git_status" | grep "^?\?" | wc -l);  # Corrected for untracked files
    modified=$(echo "$git_status" | grep "^ M" | wc -l);  # Modified but not staged
    conflicts=$(echo "$git_status" | grep "^UU" | wc -l);  # Merge conflicts
    # Determine if the branch is ahead, behind, or has diverged
    mapfile -t branch_status <<< "$(git status -sb | grep -Eo "\[ahead [0-9]+\]|\[behind [0-9]+\]")"
    ahead=$(echo "''${branch_status[@]}" | grep "ahead" | wc -l);
    behind=$(echo "''${branch_status[@]}" | grep "behind" | wc -l);
    if [ $(echo "$git_status" | wc -l) -eq 0 ]; then
      git_indicator="✔"; # Up-to-date symbol
    else
      git_indicator="";
      [ "$staged" -ne 0 ] && git_indicator+="+";  # Staged changes symbol
      [ "$untracked" -ne 0 ] && git_indicator+="*"; # Untracked files symbol
      [ "$modified" -ne 0 ] && git_indicator+="!"; # Modified files symbol
      [ "$conflicts" -ne 0 ] && git_indicator+="="; # Conflicted files symbol
      [ "$ahead" -ne 0 ] && git_indicator+="⇡"; # Branch is ahead symbol
      [ "$behind" -ne 0 ] && git_indicator+="⇣"; # Branch is behind symbol
    fi
    current_branch="($current_branch $git_indicator)";
  fi;
  PS1="\n[\w] $current_branch\n # "
'

		'';
	};
}
