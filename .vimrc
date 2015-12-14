set background=dark
set ruler
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
set ic
set hidden
set nobackup
set noswapfile
set title
set relativenumber
set ttyfast
set laststatus=2
set history=1000
set undolevels=1000
set splitright
set colorcolumn=+1
set t_Co=256

execute pathogen#infect()
colorscheme badwolf
syntax on
filetype on
filetype plugin on
filetype indent on

let g:tagbar_usearrows=1
let g:syntastic_python_flake8_args='--ignore=E123,E126,E127,E128 --max-complexity 10'
let g:tagbar_compact = 1
let g:tagbar_left = 1
let ropevim_vim_completion = 1
let ropevim_extended_complete = 1
let ropevim_guess_project = 1
imap <c-space> <C-R>=RopeCodeAssistInsertMode()<CR>
set runtimepath^=~/.vim/bundle/ctrlp.vim
set wildignore+=*.pyc

autocmd FileType c,cpp,slang setlocal cindent
autocmd FileType c setlocal formatoptions+=ro
autocmd FileType perl setlocal smartindent
autocmd FileType make setlocal noet
autocmd FileType setlocal ominfunc=htmlcomplete#CompleteTags
autocmd FileType setlocal ominfunc=xmlcomplete#Comple
let g:ropevim_autoimport_modules = ["os.*","traceback","django.*","datetime","sys","urllib","urllib2"]
autocmd FileType php noremap <C-M> :w!<CR>:!php %<CR>
autocmd FileType php noremap <leader>L :!php -l %<CR>
autocmd FileType python noremap <leader>L :call Flake8()<CR>
autocmd FileType python setlocal omnifunc=RopeCompleteFunc
nnoremap <leader>l :TagbarToggle<CR>
nnoremap <leader>u :GundoToggle<CR>
nnoremap <leader>i :RopeAutoImport<CR>
nnoremap <leader>o :RopeOrganizeImports<CR>
nnoremap <leader>t :NERDTreeToggle<CR>
nnoremap <leader>c :cclose \| lclose<CR>
nnoremap <C-p> :FZF<CR>

map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength ctermbg=darkred guibg=#111111
  autocmd BufEnter * match OverLength /\%81v.*/
augroup END
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
nnoremap j gj
nnoremap k gk

set tags=./ctags;$HOME;

python << EOF
import vim
def set_breakpoint():
    import re
    line_number = int(vim.eval('line(".")'))
    line = vim.current.line
    white_space = re.search(r'^(\s*)', line).group(1)
    vim.current.buffer.append(
        "%(space)simport pdb; pdb.set_trace() %(mark)s Breakpoint %(mark)s" %
        { 
            'space': white_space,
            'mark': '#' * 30,
        },
        line_number - 1
    )
vim.command('map <leader>b :py set_breakpoint()<CR>')

def remove_breakpoints():
    import re
    current_line_number = int(vim.eval('line(".")'))
    lines = []
    for line_number, line in enumerate(vim.current.buffer):
        if "pdb.set_trace()" in line:
            lines.append(line_number)
    for delete_target in lines[-1::-1]:
        vim.command("normal %dG" % (delete_target + 1,))
        vim.command("normal dd")
        if delete_target < current_line_number:
            current_line_number -= 1
    vim.command('normal %dG' % current_line_number)
vim.command('map <leader>B :py remove_breakpoints()<CR>')
