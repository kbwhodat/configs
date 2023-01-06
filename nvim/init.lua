
require("kato")

-- /usr/local/Cellar/neovim/0.8.1/lib/nvim is where the parser directory is located
local opts = { noremap = true, silent = true }

-- calls the nvim keymap api
local keymap = vim.api.nvim_set_keymap

-- remaps the leader key from \ to <Space>\" "
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd("set shiftwidth=0")
vim.cmd("set tabstop=2")

-- add to clipboard
vim.cmd('set clipboard+=unnamedplus')
-- add the colorscheme that I have defined in .config/nvim/colors
vim.cmd('colorscheme molokai-dark')
-- vim.cmd('hi Normal ctermbg=none guibg=none')

vim.cmd('highlight LineNr guifg=white')
vim.cmd('highlight LineNr ctermfg=white')

-- nvim-tree
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- vim_wiki
vim.g.vimwiki_list = {{path= '~/documents/wiki_notes/', path_html= '~/documents/wiki_notes_html/', syntax= 'markdown', ext= '.md' }}
vim.g.vimwiki_hl_headers = 1
vim.g.vimwiki_hl_cb_checked = 1
vim.g.vimwiki_listing_hl = 1
vim.g.vimwiki_listing_hl = 1
vim.g.vimwiki_global_ext = 0

-- Adding syntax highlighting for markdown files with .md extensions
vim.api.nvim_command('au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown')


-- keymap("n", "<leader>t", ":FloatermNew<CR>", opts)
-- keymap("n", "<F3>", ":FloatermToggle<CR>", opts)

