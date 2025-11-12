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


"""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug
"""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin()
" List your plugins here

Plug 'tpope/vim-sensible'
Plug 'lilydjwg/colorizer'
" use this if you want a syntax highlighter
" Plug 'sheerun/vim-polyglot'
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
set relativenumber
"""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Use highlighting when doing a search.
set hlsearch
"""""""""""""""""""""""""""""""""""""""""""""""""""


