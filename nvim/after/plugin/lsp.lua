local lsp = require('lsp-zero')
local cmp = require('cmp')

lsp.preset('recommended')

lsp.set_preferences({
	sign_icons = { }
})

cmp.setup({
  mapping = {
    ['<CR>'] = cmp.mapping.confirm(),
  }
})

-- diagnostics
vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        -- Disable underline, it's very annoying
        underline = false,
        virtual_text = true,
        -- Enable virtual text, override spacing to 4
        -- virtual_text = {spacing = 4},
        -- Use a function to dynamically turn signs off
        -- and on, using buffer local variables
        signs = true,
        update_in_insert = false
    })
lsp.setup()

