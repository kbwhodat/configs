
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

    -- disabling auto complete
    require('cmp').setup.buffer { enabled = false }

    -- Enter insert mode automatically
    vim.api.nvim_command('startinsert')

    -- Key mapping for Enter key in the floating window
    vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '<ESC>:lua create_note_from_float(' .. buf .. ', ' .. win .. ')<CR>', { noremap = true, silent = true })

    -- Set the prompt text and move cursor to the end of prompt
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Enter note title: " })
    vim.api.nvim_win_set_cursor(win, {1, 19}) -- Move cursor one position to the right
end

function DeleteCurrentBufferIfEmpty()
  local buf = vim.api.nvim_get_current_buf()  -- Get the current buffer handle
  local line_count = vim.api.nvim_buf_line_count(buf)  -- Get the number of lines in the buffer

  -- Check if the buffer is empty (only one line and that line is empty)
  if line_count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
    vim.api.nvim_buf_delete(buf, { force = true })  -- Delete the buffer
  else
    vim.api.nvim_command('bnext')
  end
end

function create_note_from_float(buf, win)
    local title = vim.fn.getline(1):sub(19) -- Adjust substring start to match cursor position
    vim.api.nvim_command('ObsidianNew ' .. title)
    -- Close the floating window
    vim.api.nvim_win_close(win, true)
    DeleteCurrentBufferIfEmpty()
end


function ToggleTaskStateComplete()
    local line = vim.api.nvim_get_current_line()
    local newLine

    if line:match("%[ %]") then
        -- Toggle from to-do to complete
        newLine = line:gsub("%[ %]", "[x]", 1)
    elseif line:match("%[~%]") then
        -- Toggle from pending back to to-do
        newLine = line:gsub("%[~%]", "[x]", 1)
    else
        -- If the line doesn't match any task state, do nothing or print a message
        print("No task state found on line")
        return
    end

    -- Set the modified line back
    local lnum = vim.api.nvim_win_get_cursor(0)[1] -- get the current line number
    vim.api.nvim_buf_set_lines(0, lnum-1, lnum, false, {newLine})
end

function ToggleTaskStateTodo()
    local line = vim.api.nvim_get_current_line()
    local newLine

    if line:match("%[~%]") then
        -- Toggle from to-do to complete
        newLine = line:gsub("%[~%]", "[ ]", 1)
    elseif line:match("%[x%]") then
        -- Toggle from pending back to to-do
        newLine = line:gsub("%[x%]", "[ ]", 1)
    else
        -- If the line doesn't match any task state, do nothing or print a message
        print("No task state found on line")
        return
    end

    -- Set the modified line back
    local lnum = vim.api.nvim_win_get_cursor(0)[1] -- get the current line number
    vim.api.nvim_buf_set_lines(0, lnum-1, lnum, false, {newLine})
end

function ToggleTaskStatePending()
    local line = vim.api.nvim_get_current_line()
    local newLine

    if line:match("%[ %]") then
        -- Toggle from to-do to complete
        newLine = line:gsub("%[ %]", "[~]", 1)
    elseif line:match("%[x%]") then
        -- Toggle from pending back to to-do
        newLine = line:gsub("%[x%]", "[~]", 1)
    else
        -- If the line doesn't match any task state, do nothing or print a message
        print("No task state found on line")
        return
    end

    -- Set the modified line back
    local lnum = vim.api.nvim_win_get_cursor(0)[1] -- get the current line number
    vim.api.nvim_buf_set_lines(0, lnum-1, lnum, false, {newLine})
end

