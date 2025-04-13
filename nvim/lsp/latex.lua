-- Set up nvim-cmp and extend LSP capabilities for a better completion experience.
local cmp = require'cmp'
local cmp_nvim_lsp = require('cmp_nvim_lsp')

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

vim.lsp.config["ltex-ls-plus"] = {
  cmd = { "ltex-ls-plus" },
  capabilities = capabilities,
  filetypes = {
    "bib",
    "context",
    "pandoc",
    "plaintex",
    "mail",
    "rmd",
    "tex",
    "text",
  },
  settings = {
    ltex = {
      enabled = { "latex", "typst", "typ", "bib", "plaintex", "tex" },
      language = "en-US",
      disabledRules = {
        ["en-US"] = { " MORFOLOGIK_RULE_EN_US " }  -- disable potential spelling mistake warnings
      },
    },
  },
}

return vim.lsp.config["ltex-ls-plus"]
