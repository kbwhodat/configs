-- Set up nvim-cmp and extend LSP capabilities for a better completion experience.
local cmp = require'cmp'
local cmp_nvim_lsp = require('cmp_nvim_lsp')

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

vim.lsp.config["rust"] = {
  filetypes = { 'rust' },
  root_markers = { ".git", "Cargo.lock" },
  cmd = { "rust-analyzer" },
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      check = {
        -- Ignore tests when flychecking.
        allTargets = false,
      },
      files = {
        excludeDirs = {
          ".git",
          ".cargo",
          ".direnv",
          "node_modules",
          "target",
        },
      },
      diagnostics = {
        enable = true;
      },
      completion = {
        -- Don't really use this;
        -- would use my own snippets instead
        postfix = {
          enable = true
        },

        -- Show private fields in completion
        privateEditable = {
          enable = true,
        },
      },
      workspace = {
        symbol = {
          search = {
            -- Or "all_symbols".
            kind = "only_types",
          },
        },
      },
    }
  }
}

