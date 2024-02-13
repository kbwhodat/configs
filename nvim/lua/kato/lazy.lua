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
  -- Packer can manage itself
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
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
	{
		"3rd/image.nvim"
	},
	{
		"jellydn/hurl.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		ft = "hurl",
		opts = {
			-- Show debugging info
			debug = false,
			-- Show response in popup or split
			mode = "split",
			-- Default formatter
			formatters = {
				json = { 'jq' }, -- Make sure you have install jq in your system, e.g: brew install jq
				html = {
					'prettier', -- Make sure you have install prettier in your system, e.g: npm install -g prettier
					'--parser',
					'html',
				},
			},
		},
		keys = {
			-- Run API request
			{ "<leader>A", "<cmd>HurlRunner<CR>", desc = "Run All requests" },
			{ "<leader>a", "<cmd>HurlRunnerAt<CR>", desc = "Run Api request" },
			{ "<leader>te", "<cmd>HurlRunnerToEntry<CR>", desc = "Run Api request to entry" },
			{ "<leader>tm", "<cmd>HurlToggleMode<CR>", desc = "Hurl Toggle Mode" },
			{ "<leader>tv", "<cmd>HurlVerbose<CR>", desc = "Run Api in verbose mode" },
			-- Run Hurl request in visual mode
			{ "<leader>h", ":HurlRunner<CR>", desc = "Hurl Runner", mode = "v" },
		},
	},
	{
		"tpope/vim-dadbod"
	},
	{
		"kristijanhusak/vim-dadbod-ui"
	},
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    opts = { use_diagnostic_signs = true },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
      { "<leader>xL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").previous({ skip_groups = true, jump = true })
          else
            vim.cmd.cprev()
          end
        end,
        desc = "Previous trouble/quickfix item",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            vim.cmd.cnext()
          end
        end,
        desc = "Next trouble/quickfix item",
      },
    },
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
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
    },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        offsets = {
          {
            filetype = "oil",
            text = "oil",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" } },
    -- stylua: ignore
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
  {
    "echasnovski/mini.indentscope",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- symbol = "▏",
      symbol = "│",
      options = { try_as_border = false },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "toggleterm", "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
    config = function(_, opts)
      require("mini.indentscope").setup(opts)
    end,
  },

  'nvim-treesitter/nvim-treesitter-context',
  "mbbill/undotree",
  "tpope/vim-obsession",
  {
    "lukas-reineke/indent-blankline.nvim",
		main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
    },
  },
	{
		'stevearc/oil.nvim',
		opts = {},
		-- Optional dependencies
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
  'wakatime/vim-wakatime',
  'alvan/vim-closetag',
  'tpope/vim-commentary',
  -- 'preservim/vim-markdown',
	-- 'artempyanykh/marksman',
	-- 'jghauser/follow-md-links.nvim',
	-- "jakewvincent/mkdnflow.nvim",
	"rebelot/kanagawa.nvim",
  'tpope/vim-surround',
  'windwp/nvim-autopairs' ,
	'dkarter/bullets.vim',
  'lewis6991/impatient.nvim',
  "akinsho/toggleterm.nvim",
	{
		"lewis6991/gitsigns.nvim",
	},
	{'epwalsh/obsidian.nvim',
		version = "*",
		lazy = true,
		ft = 'markdown',
		dependencies = {
			"nvim-lua/plenary.nvim"
		},
	},
  'christoomey/vim-tmux-navigator',
	{"airblade/vim-gitgutter"},
	{
		"karb94/neoscroll.nvim",
		config = function ()
			require('neoscroll').setup {}
		end
	},
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



