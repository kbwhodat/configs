local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
		delay = 2000,
    dependencies = { {'nvim-lua/plenary.nvim'} }
  },
	{
		"https://github.com/apple/pkl-neovim",
		lazy = true,
		event = "BufReadPre *.pkl",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		build = function()
			vim.cmd("TSInstall! pkl")
		end,
	},
	-- {
	-- 	'3rd/image.nvim',
	-- 	lazy = true,
	-- 	event = 'VimEnter',  -- Broad event for testing
	-- 	config = function()
	-- 		require('image').setup()
	-- 	end
	-- },
	{
		"kbwhodat/ollama.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},

		-- All the user commands added by the plugin
		cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },

		keys = {
			-- Sample keybind for prompt menu. Note that the <c-u> is important for selections to work properly.
			{
				"<leader>oo",
				":<c-u>lua require('ollama').prompt()<cr>",
				desc = "ollama prompt",
				mode = { "n", "v" },
			},

			-- Sample keybind for direct prompting. Note that the <c-u> is important for selections to work properly.
			{
				"<leader>oG",
				":<c-u>lua require('ollama').prompt('Generate_Code')<cr>",
				desc = "ollama Generate Code",
				mode = { "n", "v" },
			},
		},

		opts = {
			-- model = "dolphin-mixtral:8x7b-v2.5-q2_K"
      url = "http://174.163.19.205:11434",
			model = "codellama:34b"
		}
	},
	{
		"touchmarine/vim-dadbod",
		branch = "feat/duckdb-adapter"
	},
	{
		"kristijanhusak/vim-dadbod-ui"
	},
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      highlight = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
		delay = 2000,
    opts = {
			options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" },
		},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
  'nvim-treesitter/nvim-treesitter-context',
  "mbbill/undotree",
--	{
--		'stevearc/oil.nvim',
--		opts = {},
--		-- Optional dependencies
--		dependencies = { "nvim-tree/nvim-web-devicons" },
--	},
  'alvan/vim-closetag',
  'tpope/vim-commentary',
	"rebelot/kanagawa.nvim",
  "towolf/vim-helm",
  'tpope/vim-surround',
	{
		"tpope/vim-fugitive",
		delay = 5000,
	},
  {
		'windwp/nvim-autopairs',
		event = "InsertEnter",
		config = false
	},
	{
		'dkarter/bullets.vim',
		lazy = true,
		event = "BufReadPre *.md",
	},
	"akinsho/toggleterm.nvim",
	{'epwalsh/obsidian.nvim',
		version = "*",
		lazy = true,
		event = "BufReadPre *.md",
		ft = "markdown",
		dependencies = {
			"nvim-lua/plenary.nvim"
		},
	},
  'christoomey/vim-tmux-navigator',
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" }
  },
  "petertriho/cmp-git",
  dependencies = { 'hrsh7th/nvim-cmp' },
  opts = {
    -- options go here
  },
  init = function()
    table.insert(require("cmp").get_config().sources, { name = "git" })
  end,
  {
    'VonHeikemen/lsp-zero.nvim',
    dependencies = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-nvim-lua'},

      -- Snippets
      {'rafamadriz/friendly-snippets'},
		  {'L3MON4D3/LuaSnip'},
    }
  }
}


local opts = {}

require("lazy").setup(plugins, opts)



