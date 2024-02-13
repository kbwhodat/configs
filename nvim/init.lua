
require("kato")
require("kato.neorg_functions")
require("kato.obsidian")
require("kato.obsidian_functions")


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
--
vim.opt.list = true
-- vim.opt.listchars = {
-- 	eol = ""
-- }

-- Setting Underline
vim.api.nvim_command('set cursorline | hi clear cursorline | hi CursorLine gui=underline cterm=underline')
-- Set highlight cursor line vertically
vim.cmd('set cursorcolumn')
-- add to clipboard
vim.cmd('set clipboard+=unnamedplus')
vim.cmd('set termguicolors')
-- vim.cmd('colorscheme monokai')
vim.cmd('colorscheme kanagawa')

-- setting coneal for markdown stuff
vim.cmd('set conceallevel=3')
vim.cmd('set autochdir')

vim.cmd[[hi Normal guibg=#000000]]
vim.cmd('set background=dark')
vim.cmd[[hi NormalNC guibg=#000000]]
-- vim.cmd('hi Normal ctermbg=none guibg=none')
vim.cmd('highlight LineNr guifg=white')
vim.cmd('highlight LineNr ctermfg=black')

-- git gutter colors
vim.cmd('highlight clear SignColumn')
vim.cmd('highlight GitGutterAdd guifg=green')
vim.cmd('highlight GitGutterChange guifg=orange')
vim.cmd('highlight GitGutterDelete guifg=red')
vim.cmd('highlight GitGutterChangeDelete guifg=red')

-- Spell checking
vim.cmd('set spelllang=en_us')
vim.cmd('set spell')


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


-- Adding syntax highlighting for markdown files with .md extensions
vim.api.nvim_command('au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown')


keymap("n", "<leader>t", ":ToggleTerm<CR>", opts)
keymap("n", "<F3>", ":FloatermToggle<CR>", opts)

-- Bind this function to convenient keymaps or commands
-- vim.api.nvim_set_keymap('n', '<Leader>nh', [[<Cmd>lua neorg_decrypt_and_open("home", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Leader>nw', [[<Cmd>lua neorg_decrypt_and_open("work", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Leader>nj', [[<Cmd>lua neorg_decrypt_and_open("dj", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Leader>nd', [[<Cmd>lua neorg_decrypt_and_open("development", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Leader>nl', [[<Cmd>lua neorg_decrypt_and_open("learning", "index.norg.gpg")<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<Leader>nq', [[<Cmd>lua neorg_decrypt_and_open("notes", "index.norg.gpg")<CR>]], { noremap = true, silent = true })


-- Obsidian key bindings
vim.api.nvim_set_keymap('n', '<leader>gp', ':lua Obsidian_auto_commit()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>os', ':ObsidianSearch<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>on', ':lua create_obsidian_note()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>od', ':ObsidianToday<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oq', ':ObsidianQuickSwitch<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ob', ':ObsidianBacklinks<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>of', ':ObsidianFollowLink<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ol', ':ObsidianLinkNew<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>ol', ':ObsidianLinkNew<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oz', ':ObsidianWorkspace Zettalkasten<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ow', ':ObsidianWorkspace Work<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ot', ':ObsidianWorkspace Travel<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oF', ':ObsidianWorkspace Finance<CR>', { noremap = true, silent = true })


-- Dynamic Autocommands
-- vim.cmd([[
--   augroup obsidian_functions
--     autocmd!
-- 		autocmd VimLeavePre *.md :lua Obsidian_auto_commit()
--   augroup END
-- ]])

vim.cmd([[
  augroup neorg_dynamic
    autocmd!
		autocmd VimLeavePre *.norg :lua encrypt_all_buffers()
		autocmd BufNewFile *.norg.gpg lua decrypt_and_open()
		autocmd BufRead *.norg.gpg :lua decrypt_and_open()

		autocmd BufNewFile *.norg lua decrypt_and_open()

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


