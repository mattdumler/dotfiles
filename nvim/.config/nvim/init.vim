" Neovim configuration
" Copyright (c) 2025 Matt Dumler
" MIT license

" Visual indicators
set showmode
set wildmenu
set wildmode=longest,full
set cursorline
set number
set ruler
set scrolloff=5
set nowrap

" Syntax highlighting
filetype plugin on
syntax enable

" Search case sensitivity
set ignorecase
set smartcase

" Tabs, spaces, and indention
filetype indent on
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

" Code folding
set foldmethod=syntax

" Splits
set splitbelow
set splitright

" Load plugins with vim-plug
" TODO - look into neovim's built-in pack feature for plugins
call plug#begin()
Plug 'catppuccin/nvim', { 'branch': 'vim', 'as': 'catppuccin' }
Plug 'fatih/vim-go'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim'
Plug 'navarasu/onedark.nvim'
call plug#end()

colorscheme catppuccin-nvim

" Leader
let mapleader = ","

" Custom key mappings
noremap <C-N> :bnext!<CR>
noremap <C-P> :bprevious!<CR>
nnoremap <C-X> :bdelete<CR>
" Quick pane navigation
noremap <C-H> <C-W><C-H>
noremap <C-J> <C-W><C-J>
noremap <C-K> <C-W><C-K>
noremap <C-L> <C-W><C-L>

" Coc LSP navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Coc snippets
imap <C-l> <Plug>(coc-snippets-expand)
vmap <C-j> <Plug>(coc-snippets-select)

" Coc key mappings
nmap <space>e :CocCommand explorer<CR>

" Coc spell check
vmap <leader>a <Plug>(coc-codeaction-selected)
nmap <leader>a <Plug>(coc-codeaction-selected)

" vim-go configuration
let g:go_fmt_command = "goimports"    " Run goimports along gofmt on each save
let g:go_auto_type_info = 1           " Automatically get signature/type info for object under cursor
