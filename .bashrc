## Show full path and current branch in bash
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# export MYPS='$(echo -n "${PWD/#$HOME/~}" | awk -F "/" '"'"'{if (length($0) > 14) { if (NF>4) print $1 "/" $2 "/../" $(NF-1) "/" $NF; else if (NF>3) print $1 "/" $2 "/../" $NF; else print $1 "/../" $NF; } else print $0;}'"'"')'
# export PS1="$(eval "echo ${MYPS}")\[\033[37m\]\$(parse_git_branch)\[\033[00m\] $ "
export PS1="\u@\h \w\[\033[37m\]\$(parse_git_branch)\[\033[00m\] $ "
export PATH="/bin:/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin:$PATH"
#export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

## Create symlink for 'subl'
export PATH="/usr/local/bin:$PATH"
export EDITOR='subl -w'
export MODIFIED=`git status --short | sed -ne "s/^ M //p"`

## Git auto-complete branch names and commands
## @usage: TAB to complete/show options
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

## Homebrew auto-complete commands
## @usage: TAB to complete/show options
if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
fi

## Aliases
alias gti='git'
alias pr='git fetch && git pull --rebase'
alias cc='clear'
alias ghash='git rev-parse HEAD && git rev-parse HEAD | pbcopy'
alias glog='git log --color --graph --full-history --all --abbrev-commit --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"'
alias gs='open https://status.github.com/'
alias edit='$EDITOR $MODIFIED'
## USAGE: $ compare branch1..branch2
alias compare="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"

## Set title on each tab
## ====================================
## Gets the repository directory
## name and current branch name
## 
## If the current directory is not a
## git repo, a tabname can be specified
## ====================================
## @usage: tabname (git)
## @usage: tabname name (non-git)
function tabname {
  if [ "$1" ]; then
    printf "\e]1;$1\a"
  elif [ -d .git ]; then
    repo=$(basename `git rev-parse --show-toplevel`)
    branch="$(git symbolic-ref --short -q HEAD)" ||
    branch="(unnamed branch)"     # detached HEAD
    printf "\e]1;("$repo") "$branch"\a"
  else
    printf "\e]1;$1\a"
  fi
}

## Open the current branch in browser
## ====================================
## Open the current repo & branch from the command line
## Use flags to navigate to other areas of the repo such as
## commits, branches, pull requests or issues.
## ====================================
## This is an adaptation of @jasonneylon's script.
## Source: http://jasonneylon.wordpress.com/2011/04/22/opening-github-in-your-browser-from-the-terminal/
## ====================================
## @usage: gh
## @usage: gh c
## @usage: gh pr branch-name
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
 
  if [ "$1" = "" ]; then ## default => code
    giturl=${giturl/\.git/\/tree/}
    giturl=$giturl$branch
    open $giturl
  elif [ "$1" = "h" ]; then ## h => help
    echo ""
    echo "========================================"
    echo "Did you know that 'gh' can be used as is?"
    echo "There are also some other options, listed below:"
    echo "    [h]                      => View help"
    echo "    [c]                      => View commits"
    echo "    [c {SHA}]                => View specific commit from commit SHA"
    echo "    [b]                      => View branches"
    echo "    [pr]                     => View current branch compared to master"
    echo "    [pr branch]              => View current branch compared to specified branch"
    echo "    [i]                      => View issues"
    echo "    [a]                      => View assigned issues (in dev)"
    echo "    [w]                      => View wiki"
    echo "    [s]                      => View settings"
    echo "    [p]                      => View pulse"
    echo "    [g]                      => View graphs"
    echo "    [n]                      => View network"
    echo "    [<filename.ext>]         => Open a file in it's current state in the current branch"
    echo "    [<filename.ext> 101-120] => Open a file and highlight the lines specified"
    echo "    [files]                  => Open all amended files in their current state in the current branch"
    echo "========================================"
    echo ""
  elif [ "$1" = "c" ]; then ## c => commits
    if [ "$2" ]; then
      giturl=${giturl/\.git/\/commit/$2}
    else
      giturl=${giturl/\.git/\/commits/}
      giturl=$giturl$branch
    fi
    open $giturl
  elif [ "$1" = "b" ]; then ## b => branches
    giturl=${giturl/\.git/\/branches}
    open $giturl
  elif [ "$1" = "pr" ]; then ## pr => pull requests
    if [[ -z "$2" ]]; then
      # if a branch has not been specified, compare with master
      giturl=${giturl/\.git/\/compare/$branch?expand=1}
    else
      # if a branch has been specified, compare with current branch
      giturl=${giturl/\.git/\/compare/$2...$branch?expand=1}
    fi
    open $giturl
  elif [ "$1" = "i" ]; then ## i => issues
    giturl=${giturl/\.git/\/issues}
    open $giturl
  # This would be incredibly useful when I have the time
  # elif [ "$1" = "a" ]; then ## a => assigned issues
  #   giturl=${giturl/\.git/\/issues/assigned/$github_user}
  #   open $giturl
  elif [ "$1" = "w" ]; then ## w => wiki
    giturl=${giturl/\.git/\/wiki}
    open $giturl
  elif [ "$1" = "s" ]; then ## w => settings
    giturl=${giturl/\.git/\/settings}
    open $giturl
  elif [ "$1" = "p" ]; then ## w => pulse
    giturl=${giturl/\.git/\/pulse}
    open $giturl
  elif [ "$1" = "g" ]; then ## w => graphs
    giturl=${giturl/\.git/\/graphs}
    open $giturl
  elif [ "$1" = "n" ]; then ## w => network
    giturl=${giturl/\.git/\/network}
    open $giturl
  elif [ -f "$1" ]; then ## <filename.ext>
    lines=""

    if [[ "$2" && "$2" =~ ^-?[0-9]+$ ]]; then ## check if a line number has been specified
      linefrom=$2

      if [[ "$3" && "$3" =~ ^-?[0-9]+$ ]]; then ## check if a second line number has been specified
        lineto=$3
      fi

      if ( $linefrom && $lineto ); then
        if ( $lineto -gt $linefrom ); then
          lines="#L${linefrom}-${lineto}"
        elif ( $linefrom -gt $lineto ); then
          lines="#L${lineto}-${linefrom}"
        elif ( $lineto -eq $linefrom ); then
          lines="#L${linefrom}"
        fi
      elif ( $linefrom ); then
        lines="#L${linefrom}"
      fi
    fi

    giturl=${giturl/\.git/\/blob/$branch/$1$lines}
    open $giturl
  # elif [ "$1" = "all" ]; then ## w => files
  #   modified_count=$(ls -l $MODIFIED | wc -l)

  #   mod_array=($MODIFIED)
  #   IFS=' ' read -a array <<< "$MODIFIED"
  #   for file in "${array[@]}"
  #   do
  #     echo "$file"
  #   done
  else
    echo ""
    echo "========================================"
    echo "That option is invalid."
    echo "Did you mean:"
    echo "    [h]                      => View help"
    echo "    [c]                      => View commits"
    echo "    [c {SHA}]                => View specific commit from commit SHA"
    echo "    [b]                      => View branches"
    echo "    [pr]                     => View current branch compared to master"
    echo "    [pr branch]              => View current branch compared to specified branch"
    echo "    [i]                      => View issues"
    echo "    [a]                      => View assigned issues (in dev)"
    echo "    [w]                      => View wiki"
    echo "    [s]                      => View settings"
    echo "    [p]                      => View pulse"
    echo "    [g]                      => View graphs"
    echo "    [n]                      => View network"
    echo "    [<filename.ext>]         => Open a file in it's current state in the current branch"
    echo "    [<filename.ext> 101-120] => Open a file and highlight the lines specified"
    echo "    [files]                  => Open all amended files in their current state in the current branch"
    echo "========================================"
    echo ""
  fi
}

## Open a saved git-stash in IDE
## ====================================
## Open a specific git stash in a text editor of choice.
## Defaulted to Sublime Text 3
## Ideally, open the stash with color-coded tex background,
## i.e. deletions, -> bg = red, additions -> bg = green
## ====================================
## @usage: gst
## @usage: gst 2
function gst() {
  if [ "$1" = "" ]; then ## default => code
    git stash show -p stash@{0}
  else
    git stash show -p stash@{$1}
  fi
}

## Aliases
alias htdocs='cd /Applications/XAMPP/xamppfiles/htdocs/'
alias prj='cd ~/Projects/'

export PATH="/opt/ruby2.2.1/bin/ruby:$PATH"

## GlobalPersonals server aliases only

[[ -s $HOME/.pythonbrew/etc/bashrc ]] && source $HOME/.pythonbrew/etc/bashrc

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

## Batch setup for GNU 'coreutils' and 'findutils'
PATH=/usr/local/bin:"$PATH"
PATH="$(brew --prefix coreutils)"/libexec/gnubin:"$PATH"

MANPATH="$(brew --prefix coreutils)"{/libexec/gnuman,/share/man}:"$MANPATH"
for pkg in ed findutils ag ctags tree gnu-sed homebrew/dupes/grep vim
do
   MANPATH="$(brew --prefix $pkg)"/share/man:"$MANPATH"
done
