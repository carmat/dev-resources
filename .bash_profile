# Save file as ".bash_profile" when using

## Show full path and current branch in bash
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \w\[\033[32m\]\$(parse_git_branch)\[\033[00m\] $ "
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

## Aliases
alias gti='git'
## GlobalPersonals local VM only
alias vmupdate='/root/update_VM.sh'
## Additional choices are:
##    -h (show this help menu)
##    -a (will update all wld code, database and run puppet)
##    -w (will update wld code to head of master)
##    -d (will refarm DB from nightly dump on maxi)
##    -p (will do a full puppet run, updating all ruby apps)

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
