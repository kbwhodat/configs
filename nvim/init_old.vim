set nocompatible
set clipboard=unnamed
syntax off
set shiftwidth=4
set background=dark
set cursorline
set autoindent
set smartindent
set relativenumber
set number
set ruler
filetype plugin indent on
filetype plugin on
set encoding=UTF-8
set ignorecase
set smartcase
set showmatch
set hlsearch
set wildmenu
set wildmode=list:longest

" There are certain files that we would never want to edit with Vim.
" Wildmenu will ignore files with these extensions.
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" No backups
set nobackup
set nowritebackup
set nowb
set noswapfile

" Keep lots of history/undo
set undolevels=1000

if &term == 'xterm-kitty'
    let &t_ut=''
endif
autocmd VimEnter * highlight LineNr ctermfg=white

call plug#begin()

Plug 'https://github.com/neovim/nvim-lspconfig.git'

Plug 'wakatime/vim-wakatime'

Plug 'https://github.com/MaxMEllon/vim-jsx-pretty.git'

Plug 'https://github.com/jelera/vim-javascript-syntax.git'

Plug 'https://github.com/jiangmiao/auto-pairs.git'

Plug 'https://github.com/maximbaz/lightline-ale.git'

Plug 'https://github.com/itchyny/lightline.vim.git'

Plug 'https://github.com/alvan/vim-closetag.git'

Plug 'https://github.com/tpope/vim-surround.git'

Plug 'https://github.com/Yggdroot/indentLine.git'

"Plug 'https://github.com/dense-analysis/ale.git'

Plug 'https://github.com/preservim/nerdtree.git'

"Plug 'https://github.com/ycm-core/YouCompvareMe.git'

Plug 'https://github.com/psliwka/vim-smoothie.git'

"Plug 'https://github.com/prabirshrestha/vim-lsp.git'

"Plug 'https://github.com/mattn/vim-lsp-settings.git'

"Plug 'https://github.com/ryanoasis/vim-devicons.git'

"Plug 'https://github.com/tiagofumo/vim-nerdtree-syntax-highlight.git'

Plug 'https://github.com/PhilRunninger/nerdtree-buffer-ops.git'

Plug 'https://github.com/tpope/vim-commentary.git'

Plug 'https://github.com/preservim/vim-markdown.git'

Plug 'https://github.com/TaDaa/vimade.git'

"Plug 'https://github.com/godlygeek/tabular'

"Plug 'https://github.com/jistr/vim-nerdtree-tabs.git'

Plug 'https://github.com/prabirshrestha/asyncomplete.vim.git'

"Plug 'prabirshrestha/asyncomplete-lsp.vim'

Plug 'https://github.com/ctrlpvim/ctrlp.vim.git'

call plug#end()


" Start NERDTree. If a file is specified, move the cursor to its window.
" autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif

" Start NERDTree and put the cursor back in the other window.
"autocmd VimEnter * NERDTree % | wincmd p

"toggle nerdtree
nnoremap <F2> :NERDTreeToggle<cr>

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif


autocmd FileType nerdtree setlocal nolist

autocmd Filetype json let g:indentLine_enabled = 0

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif


colorscheme molokai-dark 


" Returns true if the color hex value is light
function! IsHexColorLight(color) abort
  let l:raw_color = trim(a:color, '#')

  let l:red = str2nr(substitute(l:raw_color, '(.{2}).{4}', '1', 'g'), 16)
  let l:green = str2nr(substitute(l:raw_color, '.{2}(.{2}).{2}', '1', 'g'), 16)
  let l:blue = str2nr(substitute(l:raw_color, '.{4}(.{2})', '1', 'g'), 16)

  let l:brightness = ((l:red * 299) + (l:green * 587) + (l:blue * 114)) / 1000

  return l:brightness > 155
endfunction



