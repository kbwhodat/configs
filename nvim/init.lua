
require("kato")
require("kato.neorg_functions")

local vim = vim

-- /usr/local/Cellar/neovim/0.8.1/lib/nvim is where the parser directory is located
local opts = { noremap = true, silent = true }

-- calls the nvim keymap api
local keymap = vim.api.nvim_set_keymap

-- remaps the leader key from \ to <Space>\" "
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- vim.cmd('set cursorline')

-- vim.cmd("set shiftwidth=0")
-- vim.cmd("set tabstop=2")

-- vim.opts.termguicolors = true

-- Setting Underline
vim.api.nvim_command('set cursorline | hi clear cursorline | hi CursorLine gui=underline cterm=underline')
-- Set highlight cursor line vertically
vim.cmd('set cursorcolumn')
-- add to clipboard
vim.cmd('set clipboard+=unnamedplus')
-- add the colorscheme that I have defined in .config/nvim/colors
vim.cmd('colorscheme molokai-dark')
vim.cmd[[hi Normal guibg=#000000]]
vim.cmd[[hi NormalNC guibg=#000000]]
-- vim.cmd('hi Normal ctermbg=none guibg=none')

vim.cmd('highlight LineNr guifg=white')
vim.cmd('highlight LineNr ctermfg=white')

-- nvim-tree
-- keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
-- Oil
keymap("n", "<leader>e", ":Oil<CR>", opts)

-- Buffers
keymap("n", "<leader>;", ":BufferLineCyclePrev<CR>", opts)
keymap("n", "<leader>'", ":BufferLineCycleNext<CR>", opts)
keymap("n", "<leader>no", ":Neorg index<CR>", opts)
keymap("n", "<leader>noh", ":Neorg workspace home<CR>", opts)
keymap("n", "<leader>now", ":Neorg workspace work<CR>", opts)
keymap("n", "<leader>noa", ":Neorg workspace aiazing<CR>", opts)
keymap("n", "<leader>d", ":bw<CR>", opts)

-- vim_wiki
vim.g.vimwiki_list = {{path= '~/documents/wiki_notes/', path_html= '~/documents/wiki_notes_html/', syntax= 'markdown', ext= '.md' }}
vim.g.vimwiki_hl_headers = 1
vim.g.vimwiki_hl_cb_checked = 1
vim.g.vimwiki_listing_hl = 1
vim.g.vimwiki_listing_hl = 1
vim.g.vimwiki_global_ext = 0

-- Adding syntax highlighting for markdown files with .md extensions
vim.api.nvim_command('au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown')


keymap("n", "<leader>t", ":FloatermNew<CR>", opts)
keymap("n", "<F3>", ":FloatermToggle<CR>", opts)

-- Bind this function to convenient keymaps or commands
vim.api.nvim_set_keymap('n', '<Leader>nh', [[<Cmd>lua neorg_decrypt_and_open("home", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nw', [[<Cmd>lua neorg_decrypt_and_open("work", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>na', [[<Cmd>lua neorg_decrypt_and_open("aiazing", "index.norg.gpg")<CR>]], { noremap = true, silent = true })


-- Dynamic Autocommands
vim.cmd([[
  augroup neorg_dynamic
    autocmd!
		autocmd VimLeavePre *.norg :lua encrypt_all_buffers()
		autocmd BufRead *.norg.gpg :lua decrypt_and_open()
		autocmd BufRead *.norg :lua neorg_decrypt_and_open(nil, vim.fn.expand('<afile>:t'), vim.fn.expand('<afile>:p'))
  augroup END
]])

-- -- Encrypt file when writing
-- vim.cmd("autocmd BufWritePre,FileWritePre *.norg :%!gpg --encrypt --recipient 'wbtankeye@gmail.com' 2>/dev/null")

-- will stay on the last line number you were on
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = {"*"},
    callback = function()
        if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
            vim.api.nvim_exec("normal! g'\"",false)
        end
    end
})

