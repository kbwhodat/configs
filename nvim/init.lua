require("kato")
require("kato.obsidian")
require("kato.obsidian_functions")
require("kato.nil-ls")

local vim = vim

-- /usr/local/Cellar/neovim/0.8.1/lib/nvim is where the parser directory is located
local opts = { noremap = true, silent = true }

-- calls the nvim keymap api
local keymap = vim.api.nvim_set_keymap

-- remaps the leader key from \ to <Space>\" "
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd('set autoindent expandtab tabstop=2 shiftwidth=2')
vim.cmd('nnoremap <tab> %')
vim.cmd('vnoremap <tab> %')			

vim.opt.list = false

-- Setting Underline
vim.api.nvim_command('set cursorline | hi clear cursorline | hi CursorLine gui=underline cterm=underline')
-- Highlight to white
-- Set highlight cursor line vertically
vim.cmd('set cursorcolumn')
-- add to clipboard
vim.cmd('set clipboard+=unnamedplus')
vim.cmd('set termguicolors')
vim.cmd('set nolist')
-- vim.cmd('colorscheme molokai-dark')
vim.cmd('colorscheme kanagawa')

-- setting coneal for markdown stuff
vim.cmd('set conceallevel=2')
vim.cmd('set autochdir')

vim.cmd[[hi Normal guibg=#000000]]
vim.cmd('set background=dark')
vim.cmd[[hi NormalNC guibg=#000000]]
vim.cmd('hi Normal ctermbg=none guibg=none')
vim.cmd('highlight LineNr guifg=white')
vim.cmd('highlight LineNr ctermfg=black')
vim.cmd('hi Visual guibg=Grey')

-- Set the status line for the active window
vim.api.nvim_set_hl(0, 'StatusLine', { fg = '#FFFFFF', bg = '#000000', bold = true })

-- Set the status line for the inactive windows
vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#808080', bg = '#000000' })

-- Set the line number foreground and background colors
vim.api.nvim_set_hl(0, 'LineNr', { fg = '#FFFFFF', bg = '#000000' })  -- Gray numbers on a dark gray background

-- Optional: Set the cursor line number to have a distinct look
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#FFFFFF', bg = '#000000' })  -- White numbers on a slightly lighter gray background

-- allows me to do di* ca* yi*
vim.cmd('onoremap <silent> i* :<C-U>normal! T*vT*<CR> " inside *')
vim.cmd('onoremap <silent> a* :<C-U>normal! F*vF*<CR> " around')

--allows me to do vi*
vim.cmd('xnoremap <silent> i* :<C-U>normal! T*vt*<CR> " inside *')
vim.cmd('xnoremap <silent> a* :<C-U>normal! F*vf*<CR> " around *')

-- vim.cmd('highlight @spell.markdown guifg=#ffffff')

vim.cmd('highlight markdownH1 guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH1Delimiter guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH2 guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH2Delimiter guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH3 guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH3Delimiter guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH4 guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH4Delimiter guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH5 guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH5Delimiter guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH6 guifg=#E6EDF3 gui=bold')
vim.cmd('highlight markdownH6Delimiter guifg=#E6EDF3 gui=bold')

-- For TreeSitter
vim.cmd('highlight @markup.heading.1.markdown guifg=#E6EDF3 gui=bold')
vim.cmd('highlight @markup.heading.2.markdown guifg=#E6EDF3 gui=bold')
vim.cmd('highlight @markup.heading.3.markdown guifg=#E6EDF3 gui=bold')
vim.cmd('highlight @markup.heading.4.markdown guifg=#E6EDF3 gui=bold')
vim.cmd('highlight @markup.heading.5.markdown guifg=#E6EDF3 gui=bold')
vim.cmd('highlight @markup.heading.6.markdown guifg=#E6EDF3 gui=bold')
vim.cmd('highlight @markup.list.markdown guifg=#E6EDF3')
vim.cmd('highlight @spell.markdown guifg=#E6EDF3')
vim.cmd('highlight @markup.italic.markdown_inline guifg=#E6EDF3 gui=italic')
-- vim.cmd('highlight @keyword.directive.markdown guifg=#0F4C81 ')
vim.cmd('highlight @markup.raw.markdown_inline guifg=#b3b7e0')
-- vim.cmd('highlight @markup.link.label.markdown_inline guifg=#0096FF')
-- vim.cmd('highlight @_label.markdown_inline guifg=#0096FF')

-- Spell checking
vim.cmd('set spelllang=en_us')
vim.cmd('set spell')

-- Automatically change the working directory to the directory of the open buffer
vim.cmd([[
  autocmd BufEnter * silent! lcd %:p:h
]])
--
-- Prevent netrw from changing the working directory automatically
vim.g.netrw_keepdir = 0

-- Split windows
keymap('n', '<Leader>v', ':vsplit<CR>', opts)
-- Move to the left and right windows
keymap('n', '<Leader>h', '<C-w>h', opts)
keymap('n', '<Leader>l', '<C-w>l', opts)
-- Move to the top and bottom windows
keymap('n', '<Leader>j', '<C-w>j', opts)
keymap('n', '<Leader>k', '<C-w>k', opts)


-- -- Oil
-- keymap("n", "<leader>e", ":Oil<CR>", opts)

-- Buffers
keymap("n", "<leader>;", ":bp<CR>", opts) -- This will move to the left buffer
keymap("n", "<leader>'", ":bn<CR>", opts) -- This will move to the right buffer 
keymap("n", "<leader>d", ":b#<bar>bd#<CR>", opts) -- This will delete the current buffer
keymap("n", "<leader>bm", ":bm<CR>", opts) -- This will navigate to any buffers that is modified
keymap("n", "<leader>bl", ":ls<CR>", opts) -- This will list the current buffers



-- Adding syntax highlighting for markdown files with .md extensions
vim.api.nvim_command('au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown')
vim.api.nvim_command('autocmd FileType markdown setlocal wrap')


-- keymap("n", "<leader>t", ":ToggleTerm<CR>", opts)
-- keymap("n", "<F3>", ":FloatermToggle<CR>", opts)

vim.g.netrw_bufsettings = 'noma nomod nu nobl nowrap ro buftype=nofile'

-- Obsidian key bindings
-- vim.api.nvim_set_keymap('n', '<leader>gp', ':lua Obsidian_auto_commit()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>os', ':ObsidianSearch<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>on', ':lua create_obsidian_note()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>od', ':ObsidianToday<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oq', ':ObsidianQuickSwitch<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ob', ':ObsidianBacklinks<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>of', ':ObsidianFollowLink<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ol', ':ObsidianLinkNew<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>ol', ':ObsidianLinkNew<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ot', ':ObsidianTags<CR>', { noremap = true, silent = true })
-- workspaces
vim.api.nvim_set_keymap('n', '<leader>oz', ':ObsidianWorkspace Zettelkasten<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ow', ':ObsidianWorkspace Work<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oT', ':ObsidianWorkspace Travel<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oF', ':ObsidianWorkspace Finance<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oc', ':ObsidianWorkspace School<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>od', ':ObsidianWorkspace Dump<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>op', ':ObsidianWorkspace Personal<CR>', { noremap = true, silent = true })


vim.api.nvim_set_keymap('n', '<C-S>', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-S>', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-A>', '<cmd>lua vim.diagnostic.open_float(nil, {focus=false})<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-A>', '<cmd>lua vim.diagnostic.open_float(nil, {focus=false})<CR>', { noremap = true, silent = true })


-- vim.api.nvim_set_keymap('n', '<Leader>tt', '<cmd>lua ToggleTaskState()<CR>', {noremap = true, silent = true})
-- For to-do commands for obsidian
vim.api.nvim_set_keymap('n', '<Leader>tc', '<cmd>lua ToggleTaskStateComplete()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>tp', '<cmd>lua ToggleTaskStatePending()<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>tt', '<cmd>lua ToggleTaskStateTodo()<CR>', {noremap = true, silent = true})

-- vim dadbod ui
vim.api.nvim_set_keymap('n', '<Leader>H', ':DBUIToggle<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>A', ':DBUIAddConnection<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Leader>L', ':DBUILastQueryInfo<CR>', {noremap = true, silent = true})



-- Dynamic Autocommands
-- vim.cmd([[
--   augroup obsidian_functions
--     autocmd!
-- 		autocmd VimLeavePre *.md :lua Obsidian_auto_commit()
--   augroup END
-- ]])


-- will stay on the last line number you were on
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = {"*"},
  callback = function()
    if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
      vim.api.nvim_exec("normal! g'\"",false)
    end
  end
})

-- vim.api.nvim_exec([[
--   augroup RemoveSpellCheck
--     autocmd!
--     autocmd FileType go,c,cpp,python,javascript,html,css,nix setlocal syntax
--   augroup END
-- ]], false)

vim.api.nvim_exec([[
  augroup RemoveSpellCheck
    autocmd!
    autocmd FileType go,c,cpp,python,javascript,html,css,nix setlocal nospell
  augroup END
]], false)


vim.cmd('syntax on')
vim.cmd('set nocompatible')
vim.cmd('set scrolloff=3')
vim.cmd('set ai')
vim.cmd('set showcmd')
vim.cmd('set ignorecase')
vim.cmd('set smartcase')
vim.cmd('set visualbell t_vb=')
vim.cmd('set novisualbell')
vim.cmd('filetype on')
vim.cmd('filetype indent on')

vim.cmd('set guicursor=n-v-c:block,i:ver25,r:hor20,o:hor50')
