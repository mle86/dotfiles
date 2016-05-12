filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" Vundle plugins:


"Plugin 'bling/vim-airline' 
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-repeat'
Bundle 'tmhedberg/matchit'
Bundle 'dantler/vim-alternate'
Bundle 'Lokaltog/vim-easymotion'

Bundle "MarcWeber/vim-addon-mw-utils"
Bundle "tomtom/tlib_vim"
"Bundle 'garbas/vim-snipmate' 


call vundle#end()
filetype plugin indent on


" easyMotion
map \<Enter> <Plug>(easymotion-bd-w)
let g:EasyMotion_keys = 'asdghklöäqwertzuiopüyxcvbnmfj,-+'

" don't remove indentation on #-lines:
set cinkeys-=0#
set indentkeys-=0#

" show line numbers:
set number
highlight LineNr ctermfg=0 ctermbg=0 cterm=bold

autocmd BufRead,BufNewFile *.php colorscheme mle-php


"""""""""""""""""""""

