# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/amazon-q/shell/bashrc.pre.bash" ]] && builtin source "${HOME}/.local/share/amazon-q/shell/bashrc.pre.bash"
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=200
HISTFILESIZE=400

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

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

if [ "$color_prompt" = yes ]; then
   # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]iceman@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ' #change user name
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    #PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}iceman@\h: \w\a\]$PS1" #change gnome terminal title name
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto -F'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


#------------added by tomita------------
PATH=$PATH":/home/tomita/bash"
CDPATH=:/home/tomita/memo/
alias matrix='cmatrix -abs'
alias rm='rm -iv'
alias mv='mv -iv'
alias cp='cp -iv'
alias screenshot='gnome-screenshot'
alias lock="xdg-screensaver lock"
alias lhS='ls -lhS'
alias lsl='clear && ls'
alias upower='upower -i /org/freedesktop/UPower/devices/battery_BAT0'
#alias dd='echo "dd is not available"'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'
alias chrome='google-chrome-stable > /dev/null 2>&1 &'
alias firefox='firefox > /dev/null 2>&1 &'
alias discord='discord > /dev/null 2>&1 &'
#alias vim='source /home/tomita/bash/vim'
if type nvim > /dev/null 2>&1; then
  alias vim='nvim'
fi
alias cd='cd '
alias dl='/home/tomita/Downloads'
alias gs='git status'
alias gb='git branch'
alias mkprg='mkprg.bash'
alias fc='fc -e'
alias winekd='wine ~/app/kindle-for-pc-1-17-44183.exe'
alias vpngate='cd ~/app/vpngate-with-proxy && ./run tui && cd -'
alias torb='cd ~/app/tor_browser && ./start-tor-browser.desktop'
alias vchanger='sox -d -d pitch -700 contrast 100 echo 0.8 0.88 6 0.4 '
alias goldendict='goldendict > /dev/null 2>&1 &'
alias veracrypt='veracrypt > /dev/null 2>&1 &'
alias xsel='xsel -bi'
alias ipython='ipython3'
alias ipython3='ipython3 --TerminalInteractiveShell.editing_mode=vi'
alias unmount='fusermount -u'
alias du='du -h'
alias ping='ping -t 128'
alias redmine='cd /usr/local/bin/redmine-4.2.8 && bundle exec rails server webrick -e production > /dev/null 2>&1 &'


# WSL or Ubuntu desktop
# NOTE: /proc/versionにmicrosoftが入っているかどうかでWSLか判定できる。
if grep -q microsoft /proc/version; then
  alias open='wsl-open'
else
  alias open='xdg-open'
fi


# rm -rf -i
function rm() {
        DIR=$(eval echo '$'$#)
        OPTION=${@%*$DIR}
    if [[ $OPTION =~ r && $OPTION =~ f ]]; then
        echo "rm -rf: remove directory $DIR? [y,n]"
        read judge
        case "$judge" in
            "y")
                :
                ;;
            ?)
                return 0
                ;;
        esac
    fi
    command rm $@
} # end function rm


# command line edit mode vi
set -o vi
bind -f ~/.inputrc # enable ctrl p, ctrl n
# show mode
# NOTE: bashの仕様上ターミナル変数の更新は次回ターミナル変数が表示される時なので動的には変わらない。
function update_prompt {
  # get current mode
  if bind -v | grep 'vi-insert' > /dev/null; then
    mode="ins"
  else
    mode="nrm"
  fi
  # update_prompt
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]iceman@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]('$mode')\[\033[00m\]\$ '
}
# set prompt command
PROMPT_COMMAND=update_prompt
# update_prompt
update_prompt


# convert caps ctrl
if type setxkbmap > /dev/null 2>&1; then
  setxkbmap -model jp106 -layout jp -option ctrl:nocaps
fi


# Ranger
export VISUAL=vim;
export EDITOR=vim;


# tab completion
#source /home/tomita/bash/tabcompletion.bash conda /home/tomita/bash/option/conda_option


# gh tab completion
if type gh > /dev/null 2>&1; then
  eval "$(gh completion -s bash)"
fi


# tor
#export http_proxy=socks5://127.0.0.1:9050
#export https_proxy=$http_proxy
#export ftp_proxy=$http_proxy
#export rsync_proxy=$http_proxy
#export HTTP_PROXY=$http_proxy
#export HTTPS_PROXY=$http_proxy
#export FTP_PROXY=$http_proxy
#export RSYNC_PROXY=$http_proxy


#-----環境ごとの特殊設定，Secretsを外だし-----
if [ -f ~/.shell_secrets ]; then
  source ~/.shell_secrets
fi

# java
#export JAVA_HOME=/usr/lib/jvm/jdk-11.0.15/


# aws
complete -C '/usr/local/bin/aws_completer' aws
alias as='aws sts get-caller-identity'


# SSL decode for Wireshark
# export SSLKEYLOGFILE=/home/tomita/ssl-key.log


# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"


# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# go lang
if command -v go >/dev/null 2>&1; then
  PATH=$PATH":/usr/local/go/bin"
  PATH=$PATH":$(go env GOPATH)/bin"
fi


# aqua
if command -v aqua >/dev/null 2>&1; then
  PATH=$PATH:$(aqua root-dir)/bin
fi


# pyenv
export PYENV_ROOT="~/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && PATH=$PATH":${PYENV_ROOT}/bin"
if pyenv gh > /dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/amazon-q/shell/bashrc.post.bash" ]] && builtin source "${HOME}/.local/share/amazon-q/shell/bashrc.post.bash"
. "/home/tomita/.deno/env"