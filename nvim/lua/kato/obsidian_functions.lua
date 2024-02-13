
function GetFormattedTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function PerformVaultBackup()
    local timestamp = getFormattedTimestamp()
		return timestamp
end


function Obsidian_auto_commit()
    local current_file = vim.fn.expand("%:t")

    -- Generate a dynamic commit message
    local commit_message = string.format("vault backup: %s", GetFormattedTimestamp())

    local target_dir = "~/vault/"
    local current_dir = vim.fn.getcwd()

    vim.cmd("cd " .. target_dir)

		local action = string.format("git pull && git add . && git commit -m '%s'&& git push", commit_message)

    local output = vim.fn.system(action)
end

function CreateObsidianNote()
    local title = vim.fn.input('Enter note title: ')
    vim.cmd('ObsidianNew ' .. title)
end


function create_obsidian_note()
    -- Define the floating window size and position
    local width = 40
    local height = 1
    local row = math.ceil((vim.o.lines - height) / 2 - 1)
    local col = math.ceil((vim.o.columns - width) / 2)

    -- Create buffer and window for the floating prompt
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })

    -- Enter insert mode automatically
    vim.api.nvim_command('startinsert')

    -- Key mapping for Enter key in the floating window
    vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '<ESC>:lua create_note_from_float(' .. buf .. ', ' .. win .. ')<CR>', { noremap = true, silent = true })

    -- Set the prompt text and move cursor to the end of prompt
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Enter note title: " })
    vim.api.nvim_win_set_cursor(win, {1, 19}) -- Move cursor one position to the right
end

function create_note_from_float(buf, win)
    local title = vim.fn.getline(1):sub(19) -- Adjust substring start to match cursor position
    vim.api.nvim_command('ObsidianNew ' .. title)
    -- Close the floating window
    vim.api.nvim_win_close(win, true)
end
