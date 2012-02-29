set background=dark
set ruler
set nu
set backspace=indent,eol,start
set wildmenu
set ts=4
set sw=4
set sts=4
set et
set smarttab
set nocompatible
set hlsearch
set incsearch
set smartindent

syntax on
filetype on
filetype plugin on
filetype indent on

autocmd FileType c,cpp,slang setlocal cindent
autocmd FileType c setlocal formatoptions+=ro
autocmd FileType perl setlocal smartindent
autocmd FileType make setlocal noet
autocmd FileType setlocal ominfunc=htmlcomplete#CompleteTags
autocmd FileType setlocal ominfunc=xmlcomplete#Comple
autocmd FileType php noremap <C-M> :w!<CR>:!php %<CR>
autocmd FileType php noremap <C-L> :!php -l %<CR>
autocmd FileType python noremap <C-L> :!pyflakes %<CR>
