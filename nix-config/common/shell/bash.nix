{ pkgs, config, lib, ... }:

let
  inherit (pkgs.stdenv) isDarwin;
in
{
	programs.bash = {
		enable = true;
		enableCompletion = true;
    historyControl = [ "ignoreboth" "erasedups" ];
    historyIgnore = [ "ls" "cd" "exit" ];

		sessionVariables = {
			EDITOR = "nvim";
      VISUAL= "vim";
      TERM = "xterm-256color";
			COLORTERM = "truecolor";
		};

		profileExtra = ''

      HISTSIZE=5000
      HISTFILESIZE=10000
      HISTFILE="${config.home.homeDirectory}/.bash_history"
      export HISTSIZE HISTFILESIZE HISTFILE

		'';

		initExtra = ''

eval "$(direnv hook bash)"

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/katob/bin:${config.home.homeDirectory}/.local/share/tridactyl:/usr/local/bin":$PATH

export EDITOR="nvim"
export VISUAL="vim"
export TMUX_CONF="~/.config/tmux/tmux.conf"
export ${ if isDarwin then "DRI_PRIME=0" else "DRI_PRIME=1" }

alias clear="tput reset"

if [[ ''${uname} == "Darwin" ]]; then
  export DOCKER_HOST="unix://${config.home.homeDirectory}/.colima/default/docker.sock"
  export LIBRARY_PATH="${if isDarwin then pkgs.libiconv-darwin else pkgs.libiconv}/lib"
fi

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

  alias zeditor="$(which zed)"

  if [ ! -f /usr/local/bin/pinentry-mac ]; then
    ln -s /run/current-system/sw/bin/pinentry-mac /usr/local/bin/pinentry-mac
  fi
else
    alias zed="$(which zeditor)"
fi



alias ls='ls --color'
alias cat='bat --style plain'
alias vim="$(which nvim)"
alias vi="$(which vim)"

keepassxc_helper() {
  local DATABASE="/home/katob/.database/keedatabase.kdbx"

  keepassxc-cli "$1" "$DATABASE" "''${@:2}"
}

# Alias for the helper script
alias kp="keepassxc_helper"

# if [ -z "$TMUX" ]; then  # Check if not already in a tmux session
#
#   TMUX_SESSION=`hostname -f`
#   if tmux has-session -t $TMUX_SESSION 2>/dev/null; then
#     tmux -f ~/.config/tmux/tmux.conf attach-session -t $TMUX_SESSION
#   else
#     tmux -f ~/.config/tmux/tmux.conf new-session -s $TMUX_SESSION
#   fi
# fi

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

if [ -z "$PROMPT_COMMAND" ]; then
  PROMPT_COMMAND="history -a; history -c; history -r"
else
  # Append only if it's not already included
  case "$PROMPT_COMMAND" in
    *history\ -a*) ;;  # already included
    *) PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND" ;;
  esac
fi

		'';
	};


  home.file."input".target = "${config.home.homeDirectory}/.inputrc";
  home.file."input".source = builtins.toFile "inputrc" ''
    set editing-mode vi
    set show-mode-in-prompt on
    set show-all-if-ambiguous on
    set vi-cmd-mode-string \1\e[2 q\2
    set vi-ins-mode-string \1\e[6 q\2
    set keymap vi-command
    set keymap vi-insert
    set keyseq-timeout 25
  '';
}
