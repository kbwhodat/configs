-- Default options:
--

-- vim.cmd('highlight @markup.heading.1.marker.markdown guifg=#565F89')
-- vim.cmd('highlight @markup.heading.1.markdown guifg=#ff757f')
-- vim.cmd('highlight @markup.heading.2.marker.markdown guifg=#565F89')
-- vim.cmd('highlight @markup.heading.2.markdown guifg=#e0af68')
-- vim.cmd('highlight @markup.heading.3.marker.markdown guifg=#565F89')
-- vim.cmd('highlight @markup.heading.3.markdown guifg=#9ece6a')
-- vim.cmd('highlight @markup.heading.4.marker.markdown guifg=#565F89')
-- vim.cmd('highlight @markup.heading.4.markdown guifg=#7dcfff')
-- vim.cmd('highlight @markup.heading.5.marker.markdown guifg=#565F89')
-- vim.cmd('highlight @markup.heading.5.markdown guifg=#7aa2f7')
-- vim.cmd('highlight @markup.heading.6.marker.markdown guifg=#565F89')
-- vim.cmd('highlight @markup.heading.6.markdown guifg=#bb9af7')

vim.cmd('highlight @markup.italic.markdown_inline guifg=#FFFFFF')

require('kanagawa').setup({
	colors = {
		palette = {
			-- change all usages of these colors
			sumiInk0 = "#000000",
			fujiWhite = "#FFFFFF",
		},
	},
	theme = "wave",              -- Load "wave" theme when 'background' option is not set
})
