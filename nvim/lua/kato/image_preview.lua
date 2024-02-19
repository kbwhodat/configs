local M = {}

function M.PreviewImage(absolutePath)
    if M.IsImage(absolutePath) then
        local command = ""

        if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
            command = "silent !wezterm cli split-pane -- powershell wezterm imgcat "
            command = command .. "'" .. absolutePath .. "'"
            command = command .. " ; pause"
        else
            command = "silent !wezterm cli split-pane -- bash -c 'wezterm imgcat "
            command = command .. absolutePath
            command = command .. " ; read'"
        end

        vim.api.nvim_command(command)
    else
        print("No preview for file " .. absolutePath)
    end
end


local function GetFileExtension(url)
    return url:match("^.+(%..+)$")
end

function M.IsImage(url)
    local extension = GetFileExtension(url)

    if extension == '.bmp' then
        return true
    elseif extension == '.jpg' or extension == '.jpeg' then
        return true
    elseif extension == '.png' then
        return true
    elseif extension == '.gif' then
        return true
    end

    return false
end

function M.PreviewImageMarkdown()
    local line = vim.api.nvim_get_current_line()
    local imagePath = extractImagePathFromMarkdown(line)
    if imagePath then
        -- Assuming imagePath is either a relative or absolute path, adjust if necessary
        M.PreviewImage(imagePath)
    else
        print("No image link found on the current line")
    end
end

function M.PreviewImageOil()
    local use, imported = pcall(require, "oil")
    if use then
        local entry = imported.get_cursor_entry()

        if (entry['type'] == 'file') then
            local dir = imported.get_current_dir()
            local fileName = entry['name']
            local fullName = dir .. fileName

            M.PreviewImage(fullName)
        end
    else
        return ''
    end
end

-- Function to extract image path from a Markdown line
function extractImagePathFromMarkdown(line)
    -- Pattern to match the Markdown image syntax: ![Alt text](image/path "Optional title")
    -- This pattern focuses on capturing the path inside the parentheses
    local pattern = "%!%[[^%]]*%]%((.-)%)"
    
    -- Using string.match to extract the first occurrence of an image path
    local imagePath = string.match(line, pattern)
    
    -- Check if imagePath was found; if so, remove optional title if present
    if imagePath then
        -- Removing the optional title part, which is indicated by a space followed by a double quote
        imagePath = imagePath:match("^(.-) \"%w+\"$") or imagePath -- Remove title if present
        return imagePath
    else
        return nil -- Return nil if no image path is found
    end
end

