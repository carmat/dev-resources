## Show full path and current branch in bash
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# export MYPS='$(echo -n "${PWD/#$HOME/~}" | awk -F "/" '"'"'{if (length($0) > 14) { if (NF>4) print $1 "/" $2 "/../" $(NF-1) "/" $NF; else if (NF>3) print $1 "/" $2 "/../" $NF; else print $1 "/../" $NF; } else print $0;}'"'"')'
# export PS1="$(eval "echo ${MYPS}")\[\033[37m\]\$(parse_git_branch)\[\033[00m\] $ "
export PS1="\u@\h \w\[\033[37m\]\$(parse_git_branch)\[\033[00m\] $ "
export PATH="/bin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH"
#export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

## Create symlink for 'subl'
export PATH="/usr/local/bin:$PATH"
export EDITOR='subl -w'

## Aliases
alias gti='git'
alias sites='cd ~/Sites/'

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

## Open the current repo & branch from the command line
## Use flags to navigate to other areas of the repo such as
## commits, branches, pull requests or issues.

## This is an adaptation of @jasonneylon's script.
## Source: http://jasonneylon.wordpress.com/2011/04/22/opening-github-in-your-browser-from-the-terminal/
function gh() {
  giturl=$(git config --get remote.origin.url)
  if [ "$giturl" == "" ]
    then
     echo "Not a git repository or no remote.origin.url set"
     exit 1;
  fi

  giturl=${giturl/git\@github\.com\:/https://github.com/}
  branch="$(git symbolic-ref HEAD 2>/dev/null)" ||
  branch="(unnamed branch)"     # detached HEAD
  branch=${branch##refs/heads/}

  ## This would be great if flags could be added
  ## to view commits, branches, pull requests, issues...
  if [ "$1" = "" ]; then ## default => code
    giturl=${giturl/\.git/\/tree/}
    giturl=$giturl$branch
    open $giturl
  elif [ "$1" = "-c" ]; then ## -c => commits
    giturl=${giturl/\.git/\/commits/}
    giturl=$giturl$branch
    open $giturl
  elif [ "$1" = "-b" ]; then ## -b => branches
    giturl=${giturl/\.git/\/branches}
    open $giturl
  elif [ "$1" = "-p" ]; then ## -p => pull requests
    giturl=${giturl/\.git/\/pulls}
    open $giturl
  elif [ "$1" = "-i" ]; then ## -i => issues
    giturl=${giturl/\.git/\/issues}
    open $giturl
  elif [ "$1" = "-h" ]; then ## -h => help
   echo ""
   echo "========================================"
   echo "Did you know that 'gh' can be used as is?"
   echo "There are also some other options, listed below:"
   echo "    [-c] => View commits"
   echo "    [-b] => View branches"
   echo "    [-p] => View pull requests"
   echo "    [-i] => View issues"
   echo "========================================"
   echo ""
  else
   echo ""
   echo "========================================"
   echo "That option is invalid."
   echo "Did you mean:"
   echo "    [-c] => View commits"
   echo "    [-b] => View branches"
   echo "    [-p] => View pull requests"
   echo "    [-i] => View issues"
   echo "========================================"
   echo ""
  fi
}
