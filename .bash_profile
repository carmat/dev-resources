## Show full path and current branch in bash
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

export MYPS='$(echo -n "${PWD/#$HOME/~}" | awk -F "/" '"'"'{if (length($0) > 14) { if (NF>4) print $1 "/" $2 "/../" $(NF-1) "/" $NF; else if (NF>3) print $1 "/" $2 "/../" $NF; else print $1 "/../" $NF; } else print $0;}'"'"')'
export PS1="$(eval "echo ${MYPS}")\[\033[37m\]\$(parse_git_branch)\[\033[00m\] $ "
# export PS1="\u@\h \w\[\033[32m\]\$(parse_git_branch)\[\033[00m\] $ "
export PATH="/bin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH"
#export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

## Create symlink for 'subl'
export PATH="/usr/local/bin:$PATH"
export EDITOR='subl -w'

## Aliases
alias gti='git'
alias ~='cd ~/Sites/'

## Set title on each tab
## @usage: tabname NAME
function tabname {
  printf "\e]1;$1\a"
}

## Auto-complete branch name
## @usage: TAB to complete/show options
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi
