"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""               
"               
"               ██╗   ██╗██╗███╗   ███╗██████╗  ██████╗
"               ██║   ██║██║████╗ ████║██╔══██╗██╔════╝
"               ██║   ██║██║██╔████╔██║██████╔╝██║     
"               ╚██╗ ██╔╝██║██║╚██╔╝██║██╔══██╗██║     
"                ╚████╔╝ ██║██║ ╚═╝ ██║██║  ██║╚██████╗
"                 ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝
"               
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""  


" unable full vim features - no need for vi compatibility
set nocompatible
" prompted to save your file whenever you try to switch out
" of any unsaved buffers
set hidden
" enabling the mouse
set mouse=a


"""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug
"""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin()
" List your plugins here

Plug 'tpope/vim-sensible'
" adding colors for colors code.
Plug 'lilydjwg/colorizer'
" making netwr
Plug 'tpope/vim-vinegar'
" FzF 
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()




set encoding=utf-8

""""""""""""""""""""""""""""""""""""""""""""""""""
" Omni Completion for C
""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin on
set omnifunc=syntaxcomplete#Complete


"""""""""""""""""""""""""""""""""""""""""""""""""""
" Set colorcolumn only for C files
autocmd FileType c setlocal colorcolumn=80
"""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set tabs to 8 spaces for C files
autocmd FileType c setlocal tabstop=8 shiftwidth=8 expandtab
""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set tabs to 4 spaces for all other files by default
set tabstop=4
set shiftwidth=4
set expandtab
""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Optional: Enable colorizer automatically
autocmd BufReadPost * ColorHighlight
"""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Map kj to <Esc> in insert and visual mode, and
" reduce timeout window to prevent false triggers
inoremap <silent> kj <Esc>
vnoremap <silent> kj <Esc>

set timeoutlen=300
"""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""
" adding relative numbers
set number
set relativenumber
"""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Use highlighting when doing a search.
set hlsearch
"""""""""""""""""""""""""""""""""""""""""""""""""""

" changing grep with ripgrep
set grepprg=rg\ --vimgrep\ --smart-case\ --follow

