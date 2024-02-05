-- Default options:
--

vim.cmd('highlight @markup.heading.1.marker.markdown guifg=#565F89')
vim.cmd('highlight @markup.heading.1.markdown guifg=#ff757f')
vim.cmd('highlight @markup.heading.2.marker.markdown guifg=#565F89')
vim.cmd('highlight @markup.heading.2.markdown guifg=#e0af68')
vim.cmd('highlight @markup.heading.3.marker.markdown guifg=#565F89')
vim.cmd('highlight @markup.heading.3.markdown guifg=#9ece6a')
vim.cmd('highlight @markup.heading.4.marker.markdown guifg=#565F89')
vim.cmd('highlight @markup.heading.4.markdown guifg=#7dcfff')
vim.cmd('highlight @markup.heading.5.marker.markdown guifg=#565F89')
vim.cmd('highlight @markup.heading.5.markdown guifg=#7aa2f7')
vim.cmd('highlight @markup.heading.6.marker.markdown guifg=#565F89')
vim.cmd('highlight @markup.heading.6.markdown guifg=#bb9af7')

vim.cmd('highlight @markup.italic.markdown_inline guifg=#FFFFFF')

require('kanagawa').setup({
	compile = true,             -- enable compiling the colorscheme
	undercurl = true,            -- enable undercurls
	commentStyle = { italic = true },
	functionStyle = {},
	keywordStyle = { italic = true},
	statementStyle = { bold = true },
	typeStyle = {},
	transparent = false,         -- do not set background color
	dimInactive = false,         -- dim inactive window `:h hl-NormalNC`
	terminalColors = true,       -- define vim.g.terminal_color_{0,17}
	colors = {
		palette = {
			-- change all usages of these colors
			sumiInk0 = "#000000",
			fujiWhite = "#FFFFFF",
		},
		theme = {
			-- change specific usages for a certain theme, or for all of them
			wave = {
				ui = {
					float = {
						bg = "none",
					},
				},
			},
			dragon = {
				syn = {
					parameter = "yellow",
				},
			},
			all = {
				ui = {
					bg_gutter = "none"
				}
			}
		}
	},
	overrides = function(colors) -- add/modify highlights
		return {
			LineNr = { fg = "#C0A36E", bg = "NONE"},
			CursorLineNr = { fg = colors.palette.orange, bg = "NONE"},
			-- update kanagawa to handle new treesitter highlight captures
			["@string.regexp"] = { link = "@string.regex" },
			["@variable.parameter"] = { link = "@parameter" },
			["@exception"] = { link = "@exception" },
			["@string.special.symbol"] = { link = "@symbol" },
			["@markup.strong"] = { link = "@text.strong" },
			["@markup.italic"] = { link = "@text.emphasis" },
			["@markup.heading"] = { link = "@text.title" },
			["@markup.raw"] = { link = "@text.literal" },
			["@markup.quote"] = { link = "@text.quote" },
			["@markup.math"] = { link = "@text.math" },
			["@markup.environment"] = { link = "@text.environment" },
			["@markup.environment.name"] = { link = "@text.environment.name" },
			["@markup.link.url"] = { link = "Special" },
			["@markup.link.label"] = { link = "Identifier" },
			["@comment.note"] = { link = "@text.note" },
			["@comment.warning"] = { link = "@text.warning" },
			["@comment.danger"] = { link = "@text.danger" },
			["@diff.plus"] = { link = "@text.diff.add" },
			["@diff.minus"] = { link = "@text.diff.delete" },
		}
	end,
	theme = "wave",              -- Load "wave" theme when 'background' option is not set
	background = {               -- map the value of 'background' option to a theme
		dark = "wave",           -- try "dragon" !
		light = "lotus"
	},
})
