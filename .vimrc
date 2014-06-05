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
set ic
set hidden

execute pathogen#infect()
syntax on
filetype on
filetype plugin on
filetype indent on

let g:tagbar_usearrows=1
let g:ctrlp_max_files = 0
let g:ctrlp_root_markers = ['.ctrlp']
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
set runtimepath^=~/.vim/bundle/ctrlp.vim
set wildignore+=*.pyc

autocmd FileType c,cpp,slang setlocal cindent
autocmd FileType c setlocal formatoptions+=ro
autocmd FileType perl setlocal smartindent
autocmd FileType make setlocal noet
autocmd FileType setlocal ominfunc=htmlcomplete#CompleteTags
autocmd FileType setlocal ominfunc=xmlcomplete#Comple
autocmd FileType php noremap <C-M> :w!<CR>:!php %<CR>
autocmd FileType php noremap <C-L> :!php -l %<CR>
autocmd FileType python noremap <C-L> :call Flake8()<CR>
nnoremap <leader>l :TagbarToggle<CR>
nnoremap <leader>u :GundoToggle<CR>
nnoremap <leader>p :CtrlPTag<CR>

augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength ctermbg=darkred guibg=#111111
  autocmd BufEnter * match OverLength /\%81v.*/
augroup END

set tags=./ctags;$HOME

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
EOF
