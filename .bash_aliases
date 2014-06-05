alias git_svn_commit='git stash; git svn dcommit; git stash pop'
alias clean_git_branches='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'
alias ctags="`brew --prefix`/bin/ctags"
