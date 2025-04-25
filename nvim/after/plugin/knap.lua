vim.cmd([[
let g:knap_settings = {
    \ "textopdfviewerlaunch": "zathura --synctex-editor-command 'nvim --headless -es --cmd \"lua require('\"'\"'knaphelper'\"'\"').relayjump('\"'\"'%servername%'\"'\"','\"'\"'%{input}'\"'\"',%{line},0)\"' %outputfile%",
    \ "textopdfviewerrefresh": "none",
    \ "textopdfforwardjump": "zathura --synctex-forward=%line%:%column%:%srcfile% %outputfile%"
\ }
]])

-- set shorter name for keymap function
local kmap = vim.keymap.set

-- F5 processes the document once, and refreshes the view
kmap({ 'n', 'v', 'i' },'<F5>', function() require("knap").process_once() end)

-- F6 closes the viewer application, and allows settings to be reset
kmap({ 'n', 'v', 'i' },'<F6>', function() require("knap").close_viewer() end)

-- F7 toggles the auto-processing on and off
kmap({ 'n', 'v', 'i' },'<F7>', function() require("knap").toggle_autopreviewing() end)

-- F8 invokes a SyncTeX forward search, or similar, where appropriate
kmap({ 'n', 'v', 'i' },'<F8>', function() require("knap").forward_jump() end)

-- Create a custom user command 'FullCompile' that automates:
-- pdflatex => biber => pdflatex => pdflatex
vim.api.nvim_create_user_command('FullCompile', function()
    -- Ensure current changes are saved first
    vim.cmd('w')
    -- Get the current filename (with extension) and its root (without extension)
    local texfile = vim.fn.expand('%')
    local basename = vim.fn.expand('%:r')
    
    -- Run commands sequentially
    os.execute('pdflatex ' .. texfile .. ' > /dev/null 2>&1')
    os.execute('biber ' .. basename .. ' > /dev/null 2>&1')
    os.execute('pdflatex ' .. texfile .. ' > /dev/null 2>&1')
    os.execute('pdflatex ' .. texfile .. ' > /dev/null 2>&1')
    
    vim.notify('PDF compilation complete!')
end, { desc = 'Compile with pdflatex, biber, and pdflatex twice' })

-- Map the new 'FullCompile' command to F9
kmap('n', '<F9>', ':FullCompile<CR>', { noremap = true, silent = true })
