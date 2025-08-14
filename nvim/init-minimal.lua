-- Disable all built-in plugins to reduce startup time
local disabled_built_ins = {
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin", "getscript",
  "getscriptPlugin", "vimball", "vimballPlugin", "2html_plugin",
  "logiPat", "rrhelper", "netrw", "netrwPlugin", "netrwSettings",
  "netrwFileHandlers", "matchit", "matchparen", "sql_completion",
  "syntax_completion", "xmlformat", "tutor_mode_plugin"
}

for _, plugin in ipairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

-- Set essential options
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.shadafile = "NONE"  -- Disable session persistence

vim.opt.termguicolors = true
vim.opt.number = false      -- Disable line numbers for minimal look
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.laststatus = 0
vim.opt.cmdheight = 0       -- Hide command line when not in use
vim.opt.showmode = false
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.shortmess:append("I") -- Disable intro message

-- UI: set dark black background
vim.cmd.highlight("Normal guibg=#000000")
vim.opt.background = "dark"

-- Leader key
vim.g.mapleader = " "

vim.g.kato_minimal = true

pcall(require, "kato")
