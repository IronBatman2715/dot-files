## History
HISTTIMEFORMAT="%F %T " # format with time

# Limit to 100 lines
HISTSIZE=100
HISTFILESIZE=100

shopt -s histappend # append to bash history instead of overwriting

## Aliases
alias lsa="ls -a"

## Colors
blk="\[\033[01;30m\]"   # Black
red="\[\033[01;31m\]"   # Red
grn="\[\033[01;32m\]"   # Green
ylw="\[\033[01;33m\]"   # Yellow
blu="\[\033[01;34m\]"   # Blue
pur="\[\033[01;35m\]"   # Purple
cyn="\[\033[01;36m\]"   # Cyan
wht="\[\033[01;37m\]"   # White
clr="\[\033[00m\]"      # Reset

## Prompt

function git_branch() {
    if [ -d .git ] ; then
        printf "%s " "($(git branch 2> /dev/null | awk '/\*/{print $2}'))";
    fi
}

export PS1="${grn}[\t] ${cyn}\$(git_branch)${blu}\W${clr}$ "