-- Molokai theme with TreeSitter support for Neovim
-- Save this file as ~/.config/nvim/colors/molokai-treesitter.lua

vim.g.colors_name = "molokai-treesitter"

local colors = {
  black = "#1B1D1E",
  white = "#FFFFFF",
  red = "#F92672",
  green = "#A6E22E",
  blue = "#66D9EF",
  yellow = "#E6DB74",
  purple = "#AE81FF",
  gray = "#808080",
}

-- Syntax Groups
vim.cmd(string.format("hi Normal guifg=%s guibg=%s", colors.white, colors.black))
vim.cmd(string.format("hi Comment guifg=%s", colors.gray))
vim.cmd(string.format("hi Keyword guifg=%s", colors.red))
vim.cmd(string.format("hi Identifier guifg=%s", colors.blue))
vim.cmd(string.format("hi String guifg=%s", colors.yellow))
vim.cmd(string.format("hi Function guifg=%s", colors.green))
vim.cmd(string.format("hi Variable guifg=%s", colors.purple))

-- TreeSitter Groups
vim.cmd(string.format("hi TSKeyword guifg=%s", colors.red))
vim.cmd(string.format("hi TSFunction guifg=%s", colors.green))
vim.cmd(string.format("hi TSMethod guifg=%s", colors.green))
vim.cmd(string.format("hi TSVariable guifg=%s", colors.purple))
vim.cmd(string.format("hi TSString guifg=%s", colors.yellow))
