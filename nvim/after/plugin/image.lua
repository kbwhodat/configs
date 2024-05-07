

local os_type = io.popen('uname'):read("*l")
local backend = "kitty"

if os_type == 'Darwin' then

	backend = "kitty"
	package.path = package.path .. ";"  .. "/Users/katob/.luarocks/share/lua/5.1/?/init.lua;"
	package.path = package.path .. ";" ..  "/Users/katob/.luarocks/share/lua/5.1/?.lua;"
elseif os_type == 'Linux' then
	package.path = package.path .. ";"  .. "/home/katob/.luarocks/share/lua/5.1/?/init.lua;"
	package.path = package.path .. ";" ..  "/home/katob/.luarocks/share/lua/5.1/?.lua;"
end



-- default config
require("image").setup({
  backend = backend,
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = true,
      download_remote_images = true,
      only_render_image_at_cursor = true,
      filetypes = { "markdown" }, -- markdown extensions (ie. quarto) can go here
    },
    neorg = {
      enabled = false,
      clear_in_insert_mode = true,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      filetypes = { "norg" },
    },
  },
  max_width = nil,
  max_height = nil,
  max_width_window_percentage = 80,
  max_height_window_percentage = 30,
  window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
  editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
  tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
  hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
})

