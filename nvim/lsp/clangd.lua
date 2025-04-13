-- Set up nvim-cmp and extend LSP capabilities for a better completion experience.
local cmp = require'cmp'
local cmp_nvim_lsp = require('cmp_nvim_lsp')

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

vim.lsp.config["clangd"] = {
  filetypes = { "c", "cpp", "objc", "objcpp" },  -- support for C, C++ and Objective-C files
  root_markers = { ".git", "compile_commands.json", "compile_flags.txt" },  -- common project root indicators
  cmd = {
    "clangd",
    "--background-index",       -- build an index in the background for faster symbol lookups
    "--clang-tidy",             -- enable clang-tidy diagnostics if you have it installed
    "--completion-style=detailed",  -- get more detailed completion information
    "--header-insertion=never"  -- control header insertion behavior (or adjust as needed)
  },
  capabilities = capabilities,  -- assuming you've defined 'capabilities' (for instance, by extending LSP capabilities with nvim-cmp)
}
