# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

ZSH_TMUX_AUTOSTART=false

setopt autocd              # change directory just by typing its name
setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

eval "$(pyenv init --path)"
eval "$(pyenv init -)"

alias notflix='/Users/katob/Documents/tools/buku-dmenu/notflix'
alias bukuadd='buku -a'
alias ls='ls --color'
alias cat='mdcat'
alias smbmap='python /Users/katob/Documents/tools/smbmap/smbmap.py'
alias cyberchef='open /Users/katob/Downloads/CyberChef_v9.32.3/CyberChef_v9.32.3.html'
alias ffuf='/Users/katob/Documents/tools/ffuf/ffuf'
alias hash-id='/Users/katob/Documents/tools/hash-id/target/release/hash-id'
alias hashid='python /Users/katob/Documents/tools/hash-identifier/hash-id.py'
alias ssh2john='python2 /usr/local/Cellar/john-jumbo/1.9.0/share/john/ssh2john.py'
alias vim="/usr/local/bin/nvim"
alias vi="/usr/local/bin/nvim"
alias zip2john='/usr/local/Cellar/john-jumbo/1.9.0/share/john/zip2john'
alias php="/usr/local/bin/php"
alias vol="python2.7 /usr/local/Cellar/volatility/2.6.1_2/bin/vol.py"
alias patator='python /Users/katob/Documents/patator/patator.py'
alias jsh='python /Users/katob/Documents/tools/JSshell/jsh.py'
alias doom='/Users/katob/.emacs.d/bin/doom'
alias termpdf='python /Users/katob/Documents/tools/termpdf.py/termpdf.py'
alias java='/usr/libexec/java_home'
#alias vol="/Users/katob/Downloads/volatility3/vol.py"



function pyenv (){
	local command
	command="${1:-}"
	
	if [ $command == "install" ];then

    	curl_output=(curl -sSL https://github.com/python/cpython/commit/8ea6353.patch\?full_index\=1)

    	/usr/local/bin/pyenv $@ < <($curl_output)
    else
        /usr/local/bin/pyenv $@
    fi
}


WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word
# hide EOL sign ('%')
PROMPT_EOL_MARK=""

source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
export NUMVERIFY_API_KEY=Asrr9TsR93aH5VShZxA2wTxw65YvplwN
export PATH=$(brew --prefix openvpn)/sbin:/usr/local/sbin:$PATH
export PLUGINSPATH=/Users/katob/Documents/community
export PATH=$PATH:/Applications/Visual\ Studio\ Code\ 2.app/Contents/Resources/app/bin:/Users/katob/Library/Python/2.7/bin
export REACT_EDITOR=code
export PATH=$PATH:/Users/katob/Library/Preferences/qutebrowser/qutebrowser
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/Users/katob/.pyenv/shims/buku:$PATH"
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

# enable completion features
# export ZSH_DISABLE_COMPFIX=true
autoload -Uz compinit
compinit -u -i -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"

# configure `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Autoload zsh add-zsh-hook and vcs_info functions (-U autoload w/o substition, -z use zsh style)
autoload -Uz add-zsh-hook vcs_info
# Enable substitution in the prompt.
setopt prompt_subst
# Run vcs_info just before a prompt is displayed (precmd)
add-zsh-hook precmd vcs_info
# add ${vcs_info_msg_0} to the prompt
# e.g. here we add the Git information in red  
PROMPT='%1~ %F{red}${vcs_info_msg_0_}%f %# '

# Enable checking for (un)staged changes, enabling use of %u and %c
zstyle ':vcs_info:*' check-for-changes true
# Set custom strings for an unstaged vcs repo changes (*) and staged changes (+)
zstyle ':vcs_info:*' unstagedstr ' *'
zstyle ':vcs_info:*' stagedstr ' +'
# Set the format of the Git information for vcs_info
zstyle ':vcs_info:git:*' formats       '(%b%u%c)'
zstyle ':vcs_info:git:*' actionformats '(%b|%a%u%c)'

configure_prompt() {
    prompt_symbol=㉿
    [ "$EUID" -eq 0 ] && prompt_symbol=💀
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PROMPT=$'\n%B%F{%(#.red.grey)}${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}%B%F{%(#.red.grey)}[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%B%F{%(#.red.grey)}] ${vcs_info_msg_0_}\n%B%(#.%B%F{blue}#.%F{grey} #)%b%F{reset} '
            RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
            ;;
        oneline)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{%(#.red.blue)}%n@%m%b%F{reset}:%B%F{%(#.blue.green)}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
        backtrack)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{red}%n@%m%b%F{reset}:%B%F{blue}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
    esac
}

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

if [ "$color_prompt" = yes ]; then
    # override default virtualenv indicator in prompt
    VIRTUAL_ENV_DISABLE_PROMPT=1

    configure_prompt

    # enable syntax-highlighting
    if [ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && [ "$color_prompt" = yes ]; then
        . /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	ZSH_HIGHLIGHT_STYLES[path]=none
	ZSH_HIGHLIGHT_STYLES[path_prefix]=none
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
        ZSH_HIGHLIGHT_STYLES[default]=none
        ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
        ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[global-alias]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[command-substitution]=none
        ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[process-substitution]=none
        ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[assign]=none
        ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
        ZSH_HIGHLIGHT_STYLES[named-fd]=none
        ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
        ZSH_HIGHLIGHT_STYLES[arg0]=fg=green
        ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    fi
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%# '
fi
unset color_prompt force_color_prompt

toggle_oneline_prompt(){
    if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
        PROMPT_ALTERNATIVE=twoline
    else
        PROMPT_ALTERNATIVE=oneline
    fi
    configure_prompt
    zle reset-prompt
}
zle -N toggle_oneline_prompt
bindkey ^P toggle_oneline_prompt

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# enable auto-suggestions based on the history
if [ -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

export FREERDP2_CFLAGS='-I/usr/local/include'
export FREERDP2_LIBS='-I/usr/local/lib/freerdp'

export LDFLAGS="-L/usr/local/opt/openssl@3/lib -L/usr/local/opt/bzip2/lib -L/usr/local/opt/zlib/lib -L/usr/local/opt/readline/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@3/include -I/usr/local/opt/zlib/include -I/usr/local/opt/bzip2/include -I/usr/local/opt/readline/include"

export PKG_CONFIG_PATH="/usr/local/opt/openssl@3/lib/pkgconfig:/usr/local/opt/zlib/lib/pkgconfig:/usr/local/opt/readline/lib/pkgconfig"
#export PKG_CONFIG_PATH="/usr/local/opt/openssl@3/lib/pkgconfig"

export CONFIGURE_OPTS="CPPFLAGS=-I/usr/local/opt/zlib/include,-I/usr/local/opt/openssl@3/include,-I/usr/local/opt/bzip2/include,-I/usr/local/opt/readline/include LDFLAGS=-L/usr/local/opt/zlib/lib,-L/usr/local/opt/openssl@3/lib,-L/usr/local/opt/bzip2/lib,-L/usr/local/opt/readline/lib"

export ZSH="/Users/katob/.oh-my-zsh"
plugins=(git web-search tmux)
source $ZSH/oh-my-zsh.sh


#export GOPATH=`echo $HOME/go`
#export PATH="$GOPATH:$PATH"
export PATH="/usr/local/opt/openssl@3/bin:$PATH"
export PATH="/usr/local/opt/bzip2/bin:$PATH"
export PATH="/usr/local/opt/inetutils/libexec/gnubin:$PATH"


jdk() {
        version=$1
        export JAVA_HOME=$(/usr/libexec/java_home -v"$version");
        java -version
 }
