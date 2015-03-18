setlocal ts=2
setlocal sw=2
setlocal sts=2
setlocal et
setlocal cindent

setlocal tw=80
setlocal fo=cqt
setlocal wm=0 

augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength ctermbg=darkred guibg=#111111
  autocmd BufEnter * match OverLength /\%81v.*/
augroup END
