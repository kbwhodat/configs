-- Default options:
require('kanagawa').setup({
	compile = false,             -- enable compiling the colorscheme
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
		}
	end,
	theme = "wave",              -- Load "wave" theme when 'background' option is not set
	background = {               -- map the value of 'background' option to a theme
		dark = "wave",           -- try "dragon" !
		light = "lotus"
	},
})
