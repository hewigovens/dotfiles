" Basic Setup
set nocompatible
set number
set cursorline
set noerrorbells
set encoding=utf-8
set mouse=a

" Indentation
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4
set autoindent

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch
" Press <Space> to turn off highlighting and clear any message already displayed.
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" UI & Status
set laststatus=2
set wildmenu
set wildmode=longest,list,full
set showcmd
set showmode
set scrolloff=5

" File & Backup
set autoread
set hidden
set nobackup
set nowritebackup
set noswapfile

command! -bar -nargs=0 Save w !sudo tee % >/dev/null | edit!
command! -bar -nargs=0 W w !sudo tee % >/dev/null | edit!

" Undo Configuration
if has('persistent_undo')
    set undofile
    set undodir=~/.vim/undodir
    set undolevels=1000
    set undoreload=10000
endif

" Vim-Plug Setup
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline', { 'on': [] }
Plug 'vim-airline/vim-airline-themes', { 'on': [] }
Plug 'tpope/vim-commentary', { 'on': 'Commentary' }
Plug 'vimpostor/vim-lumen', { 'on': [] }

call plug#end()

" Theme
let g:lumen_light_colorscheme = 'shine'
let g:lumen_dark_colorscheme = 'slate'

" Defer heavier plugin loading until after startup
autocmd VimEnter * ++once call plug#load('vim-airline', 'vim-airline-themes', 'vim-lumen')

" Performance 
let g:airline#extensions#tabline#enabled = 0
let g:airline_powerline_fonts = 0

set noshowmode
set lazyredraw
set ttyfast
set synmaxcol=200
set updatetime=300

" Mappings
" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Exit insert mode mapping
imap jj <Esc>
