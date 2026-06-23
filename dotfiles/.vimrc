" vim: set ft=vim:
" Minimal, sensible vimrc

set nocompatible
set encoding=utf-8
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set cursorline
set wildmenu
set laststatus=2
set showmatch
set incsearch
set hlsearch
set ignorecase
set smartcase
set scrolloff=8
set sidescrolloff=8
set signcolumn=yes
set updatetime=300
set undofile
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

" Make directories if missing
let s:dirs = ['backup', 'swap', 'undo']
for s:d in s:dirs
    let s:dir = expand('~/.vim/' . s:d)
    if !isdirectory(s:dir)
        call mkdir(s:dir, 'p')
    endif
endfor

" Key mappings
let mapleader = ' '
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>e :Explore<CR>
nnoremap Y y$
vnoremap < <gv
vnoremap > >gv

" Clear search highlight
nnoremap <leader>h :nohlsearch<CR>
