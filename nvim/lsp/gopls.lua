local cmp = require'cmp'
local cmp_nvim_lsp = require('cmp_nvim_lsp')

return {
  cmd = { "gopls" },
  filetypes = { "go" },
  root_markers = {
    "go",
    "gomod",
    "gowork",
    "gotmpl"
  },
  capabilities = require("cmp_nvim_lsp").default_capabilities(
    vim.lsp.protocol.make_client_capabilities()
  ),
}
