
function get_remaining_path_after_workspace(full_path, workspace)
    local i, j = full_path:find(workspace)
    if i and j then
        return full_path:sub(j + 1)
    end
    return ""
end

function get_workspace_from_path(full_path)
    local path_parts = {}
    for part in string.gmatch(full_path, "([^/]+)/") do
        table.insert(path_parts, part)
    end

    -- Assuming ~/notes/ is always the parent folder for workspaces,
    -- the workspace would be the folder immediately after "notes" in the path
    for i, part in ipairs(path_parts) do
        if part == "notes" then
            return path_parts[i+1]
        end
    end

    return nil -- Return nil if workspace could not be determined
end

function neorg_encrypt_a_file(full_path)
	-- print("neorg_encrypt_a_file: ", full_path)
  local directory = full_path:match("(.+)/")
	local workspace = get_workspace_from_path(full_path)
	local filename = full_path:match(".+/([^/]+)$")
	local remaining_path = get_remaining_path_after_workspace(full_path, workspace)

	-- print("Full Path: " .. (full_path or "nil"))
	-- print("Directory: " .. (directory or "nil"))
	-- print("Workspace: " .. (workspace or "nil"))
	-- print("Filename: " .. (filename or "nil"))
	-- print("remaining_path: " .. (remaining_path or "nil"))

  local filepath = vim.fn.expand("~/notes/") .. workspace .. remaining_path
  local gpg_filepath = filepath .. ".gpg"

	-- print("Filepath: " .. (filepath or "nil"))
	-- print("gpg_Filepath: " .. (gpg_filepath or "nil"))

  -- Encryption command
  local encrypt_cmd = string.format("pass show my_passphrase | gpg -r kiyingi --trust-model always --no-tty --batch --yes --passphrase-fd 0 --output %s --encrypt %s >/dev/null 2>&1", gpg_filepath, filepath)


  -- Run the command and capture the exit status
  local exit_status = os.execute(encrypt_cmd)

  -- If the exit status is 0, the command was successful
  if exit_status == 0 then
    vim.cmd("silent !rm " .. filepath)
		git_auto_commit()
  else
    print("Encryption failed, not removing the file.")
  end
end

function wipe_gpg_buffer(gpg_filename)
  local buffers = vim.api.nvim_list_bufs()
  for _, buffer_id in ipairs(buffers) do
    local name = vim.api.nvim_buf_get_name(buffer_id)
    if name:find(gpg_filename) then
      vim.api.nvim_buf_delete(buffer_id, {force = true})
      return
    end
  end
end


function get_base_path(full_path)
    return full_path:match("(.+)/")
end


function neorg_decrypt_and_open(workspace, filename_gpg, full_path)
	local full_path_decrypted, full_path_gpg

	if workspace then
		local base_path = vim.fn.expand("~/notes/") .. workspace
		full_path_decrypted = base_path .. "/" .. string.match(filename_gpg, "(.+)%..+")
		full_path_gpg = base_path .. "/" .. filename_gpg
	end

  if workspace and full_path_gpg:match("%.norg%.gpg$") then
		-- Decrypt command
		local decrypt_cmd = string.format("pass show my_passphrase | gpg -r kiyingi --no-tty --batch --yes --passphrase-fd 0 --output %s --decrypt %s >/dev/null 2>&1", full_path_decrypted, full_path_gpg)

		-- Run the command and capture the exit status
		local exit_status = os.execute(decrypt_cmd)

		-- If the exit status is 0, the command was successful
		if exit_status == 0 then
			os.execute("rm " .. full_path_gpg)
		end

		-- Delegate to Neorg's original workspace handling
		if workspace then
			vim.cmd(string.format("Neorg workspace %s", workspace))
		end
	end
end

function decrypt_and_open()
	local full_path = vim.fn.expand('%:p')

	if full_path:match("%.norg%.gpg$") then
		local decrypted_filepath = full_path:gsub("%.gpg$", "")
		local decrypt_cmd = string.format("pass show my_passphrase | gpg -r kiyingi --trust-model always --no-tty --batch --yes --passphrase-fd 0 --output %s --decrypt %s 2>/dev/null", decrypted_filepath, full_path)

		local exit_status = os.execute(decrypt_cmd)

		if exit_status == 0 then
			os.execute("rm " .. full_path)
			wipe_gpg_buffer(full_path:match("([^/]+)$"))
			vim.cmd("silent e " .. decrypted_filepath)
			vim.cmd("set filetype=norg")
		else
			print("Decryption failed, not switching to the file.")
		end
	end
end


function encrypt_all_buffers()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    local filename = vim.api.nvim_buf_get_name(buf)
    local file_extension = filename:match("^.+(%..+)$")

    if file_extension == ".norg" then  -- Replace with your own file type check
      -- local shortname = filename:match(".+/([^/]+)$")
      neorg_encrypt_a_file(filename)
    end
  end
end

function git_auto_commit()
    local current_file = vim.fn.expand("%:t")

    -- Generate a dynamic commit message
    local commit_message = string.format("Edited %s", current_file)

    local target_dir = "/Users/katob/notes/"
    local current_dir = vim.fn.getcwd()

    vim.cmd("cd " .. target_dir)

		local action = string.format("git add . && git commit -m 'Added notes for %s'", current_file)

    local output = vim.fn.system(action)

    vim.cmd("cd " .. current_dir)
end

