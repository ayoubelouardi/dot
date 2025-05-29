call plug#begin()

" List your plugins here
Plug 'tpope/vim-sensible'
Plug 'lilydjwg/colorizer'

call plug#end()



" Optional: Enable colorizer automatically
autocmd BufReadPost * ColorHighlight
