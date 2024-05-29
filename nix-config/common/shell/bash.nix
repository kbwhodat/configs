{ pkgs, config, lib, ... }:

{
	programs.bash = {
		enable = true;
		enableCompletion = true;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
    historyIgnore = [ "ls" "cd" "exit" ];

		sessionVariables = {
			EDITOR = "nvim";
      VISUAL= "vim";
			TERM = "screen-256color";
			COLORTERM = "truecolor";
		};

		profileExtra = ''

      HISTSIZE=5000
      HISTFILESIZE=10000
      HISTFILE="${config.home.homeDirectory}/.bash_history"
      export HISTSIZE HISTFILESIZE HISTFILE

		'';

		initExtra = ''

export PATH=$PATH:"/run/current-system/sw/bin:/etc/profiles/per-user/katob/bin:${config.home.homeDirectory}/.local/share/tridactyl:/usr/local/bin"
export EDITOR="nvim"
export VISUAL="vim"
export TMUX_CONF="~/.config/tmux/tmux.conf"



# source "${pkgs.blesh}"/share/blesh/ble.sh
# source "${pkgs.blesh}"/share/blesh/lib/vim-surround.sh
    shopt -s histappend
    shopt -s cmdhist
    shopt -s lithist
    shopt -s interactive_comments
    shopt -s extglob

    shopt -s nocaseglob

    shopt -s extglob
    shopt -s globstar

bind -f "${config.home.homeDirectory}/.config/scripts/inputrc-surround"
bind -m vi-insert "\C-a: beginning-of-line"
bind -m vi-insert "\C-e: end-of-line"
bind -m vi-command "\C-a: beginning-of-line"
bind -m vi-command "\C-e: end-of-line"

HISTSIZE=
HISTFILESIZE=
HISTFILE="${config.home.homeDirectory}/.bash_historys"
export HISTSIZE HISTFILESIZE HISTFILE

if [[ ''${uname} == "Darwin" ]]; then
  if [ ! -f /usr/local/bin/pinentry-mac ]; then
    ln -s /run/current-system/sw/bin/pinentry-mac /usr/local/bin/pinentry-mac
  fi
fi


 
alias ls='ls --color'
alias cat='bat --style plain'
alias vim="$(which nvim)"

if [ -z "$TMUX" ]; then  # Check if not already in a tmux session
  
  TMUX_SESSION=`hostname -f`
  if tmux has-session -t $TMUX_SESSION 2>/dev/null; then
    tmux -f ~/.config/tmux/tmux.conf attach-session -t $TMUX_SESSION
  else
    tmux -f ~/.config/tmux/tmux.conf new-session -s $TMUX_SESSION 
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
    modified=$(echo "$git_status" | grep "^ M" | wc -l);  # Modified but not staged
    # Determine if the branch is ahead, behind, or has diverged
    if [ $(echo "$git_status" | wc -l) -eq 0 ]; then
      git_indicator=" ✔"; # Up-to-date symbol
    else
      git_indicator="";
      [ "$staged" -ne 0 ] && git_indicator+=" +";  # Staged changes symbol
      [ "$modified" -ne 0 ] && git_indicator+=" !"; # Modified files symbol
    fi
    current_branch="($current_branch$git_indicator)";
  fi;
  PS1="\n[\w] $current_branch\n # "
'

PROMPT_COMMAND="history -a; $PROMPT_COMMAND"


		'';
	};


  home.file."input".target = "${config.home.homeDirectory}/.inputrc";
  home.file."input".source = builtins.toFile "inputrc" ''
    set editing-mode vi
    #set keymap vi-command
    set keymap vi-insert
  '';
}
