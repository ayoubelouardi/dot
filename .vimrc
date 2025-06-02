""""""""""""""
" vim-plug
""""""""""""""
call plug#begin()

" List your plugins here
Plug 'tpope/vim-sensible'
Plug 'lilydjwg/colorizer'
" use this if you want a syntax highlighter
" Plug 'sheerun/vim-polyglot'

call plug#end()



" Optional: Enable colorizer automatically
autocmd BufReadPost * ColorHighlight

" Map kj to <Esc> in insert and visual mode, and
" reduce timeout window to prevent false triggers
inoremap <silent> kj <Esc>
vnoremap <silent> kj <Esc>

set timeoutlen=300
