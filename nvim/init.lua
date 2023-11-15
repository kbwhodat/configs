
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
-- vim.cmd('colorscheme molokai-dark')
vim.cmd('colorscheme kanagawa')
vim.cmd[[hi Normal guibg=#000000]]
vim.cmd[[hi NormalNC guibg=#000000]]
-- vim.cmd('hi Normal ctermbg=none guibg=none')
vim.cmd('highlight LineNr guifg=white')
vim.cmd('highlight LineNr ctermfg=black')

-- nvim-tree
-- keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)
-- Oil
keymap("n", "<leader>e", ":Oil<CR>", opts)

-- Buffers
keymap("n", "<leader>;", ":BufferLineCyclePrev<CR>", opts) -- This will move to the left buffer
keymap("n", "<leader>'", ":BufferLineCycleNext<CR>", opts) -- This will move to the right buffer 
keymap("n", "<leader>d", ":bw<CR>", opts) -- This will delete the current buffer

-- Neorg stuff
keymap("n", "<leader>no", ":Neorg index<CR>", opts) -- Will go the root index
keymap("n", "<leader>noh", ":Neorg workspace home<CR>", opts) -- Will go to the home workspace
keymap("n", "<leader>now", ":Neorg workspace work<CR>", opts)
keymap("n", "<leader>nod", ":Neorg workspace dj<CR>", opts)
keymap("n", "<leader>nol", ":Neorg workspace learning<CR>", opts)

-- vim_wiki
-- vim.g.vimwiki_list = {{path= '~/wiki/', path_html= '~/wiki_html/', syntax= 'markdown', ext= '.md' }}
-- vim.g.vimwiki_hl_headers = 1
-- vim.g.vimwiki_hl_cb_checked = 1
-- vim.g.vimwiki_listing_hl = 1
-- vim.g.vimwiki_listing_hl = 1
-- vim.g.vimwiki_global_ext = 0

-- Adding syntax highlighting for markdown files with .md extensions
vim.api.nvim_command('au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown')


keymap("n", "<leader>t", ":FloatermNew<CR>", opts)
keymap("n", "<F3>", ":FloatermToggle<CR>", opts)

-- Bind this function to convenient keymaps or commands
vim.api.nvim_set_keymap('n', '<Leader>nh', [[<Cmd>lua neorg_decrypt_and_open("home", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nw', [[<Cmd>lua neorg_decrypt_and_open("work", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nd', [[<Cmd>lua neorg_decrypt_and_open("dj", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nl', [[<Cmd>lua neorg_decrypt_and_open("learning", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>nq', [[<Cmd>lua neorg_decrypt_and_open("notes", "index.norg.gpg")<CR>]], { noremap = true, silent = true })


-- Dynamic Autocommands
vim.cmd([[
  augroup neorg_dynamic
    autocmd!
		autocmd VimLeavePre *.norg :lua encrypt_all_buffers()
		autocmd BufNewFile *.norg.gpg lua decrypt_and_open()
		autocmd BufRead *.norg.gpg :lua decrypt_and_open()
		autocmd BufRead *.norg :lua neorg_decrypt_and_open(nil, vim.fn.expand('<afile>:t'), vim.fn.expand('<afile>:p'))
		autocmd BufDelete *.norg :lua neorg_encrypt_a_file(vim.fn.expand('<afile>:p'), true)
  augroup END
]])

-- will stay on the last line number you were on
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = {"*"},
    callback = function()
        if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
            vim.api.nvim_exec("normal! g'\"",false)
        end
    end
})

