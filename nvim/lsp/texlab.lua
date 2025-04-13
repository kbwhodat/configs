local cmp = require'cmp'
local cmp_nvim_lsp = require('cmp_nvim_lsp')

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

vim.lsp.config["texlab"] = {
  filetypes = { "tex", "bib" },
  capabilities = capabilities,
  root_markers = { ".git", "texmf.cnf", "main.tex" },
  cmd = { "texlab" },
  settings = {
    texlab = {
      build = {
        executable = "latexmk",
        args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
        onSave = true,
      },
      chktex = {
        onEdit = true,
      },
      forwardSearch = {
        executable = "zathura",
        args = { "--synctex-forward", "%l:1:%f", "%p" },
      },
    },
  },
}
