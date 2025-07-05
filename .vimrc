"Basic
set nocompatible
set laststatus=2
set nu
set langmenu=en_US
set noerrorbells
set cursorline

"Statusline
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ %{strftime(\"%d/%m/%y\ -\ %H:%M\")}
set wildmenu
set wildmode=longest,list,full

"Indentation
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4
set autoindent

"Fold
set foldmethod=indent
set foldlevel=99
set completeopt=menuone,longest,preview

"Search 
set ignorecase
set smartcase
set incsearch
set hlsearch

"Edit
set showcmd
set showmode
set showmatch
set linebreak
set report=0
set encoding=utf-8
" set spell
set nowrap

"File
set autoread
set autowrite
set hidden
set backup

"Undo
set undodir=~/.vim/undodir
set undofile
set undolevels=1000 "maximum number of changes that can be undone
set undoreload=10000 "maximum number lines to save for undo on a buffer reload

"GUI
set mouse=a

"Mapping
imap jj <Esc>
map <leader>co :copen<CR>
map <leader>cc :cclose<CR>
nmap <leader>a <Esc>:Ack!

vmap <tab>   >gv
vmap <s-tab> <gv

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

"Custom Command
:command Save w !sudo tee %

colorscheme desert
syntax on
filetype on 
filetype plugin indent on

let g:neocomplcache_enable_at_startup = 1
let g:SuperTabDefaultCompletionType = "context"

autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html,markdown set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
autocmd FileType c set omnifunc=ccomplete#Complete

autocmd VimEnter * wincmd 1
