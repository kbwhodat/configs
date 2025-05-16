-- enable lsp completion
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
    callback = function(ev)
        vim.lsp.completion.enable(true, ev.data.client_id, ev.buf)
    end,
})


-- provides inline diagnoistics in neovim. Only way
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    spacing = 2,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
})


vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- LSP actions - keymaps, etc.
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = {buffer = event.buf}
    vim.keymap.set('n', 'gh', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    -- Navigate to previous diagnostic
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    -- Navigate to next diagnostic
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    -- Place diagnostics in the location list for quick overview
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
  end,
})

vim.opt.signcolumn = 'no'


vim.lsp.enable('rust')
vim.lsp.enable('clangd')
vim.lsp.enable('latex') -- spelling and grammar checks
vim.lsp.enable('texlab') -- latex lsp
vim.lsp.enable("jedi_language_server")
