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
	{
		"3rd/image.nvim",
		lazy = true,
		event = "BufReadPre *.md",
	},
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
			model = "codellama"
		}
	},
	{
		"touchmarine/vim-dadbod",
		branch = "feat/duckdb-adapter"
	},
	{
		"kristijanhusak/vim-dadbod-ui"
	},
  -- {
  --   "folke/trouble.nvim",
  --   cmd = { "TroubleToggle", "Trouble" },
  --   opts = { use_diagnostic_signs = true },
  --   keys = {
  --     { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
  --     { "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
  --     { "<leader>xL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
  --     { "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
  --     {
  --       "[q",
  --       function()
  --         if require("trouble").is_open() then
  --           require("trouble").previous({ skip_groups = true, jump = true })
  --         else
  --           vim.cmd.cprev()
  --         end
  --       end,
  --       desc = "Previous trouble/quickfix item",
  --     },
  --     {
  --       "]q",
  --       function()
  --         if require("trouble").is_open() then
  --           require("trouble").next({ skip_groups = true, jump = true })
  --         else
  --           vim.cmd.cnext()
  --         end
  --       end,
  --       desc = "Next trouble/quickfix item",
  --     },
  --   },
  -- },

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
		tag = "v4.5.3",
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
  {
    "echasnovski/mini.indentscope",
		lazy = true,
		delay = 2000,
    version = false, -- wait till new 0.7.0 release to put it back on semver
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- symbol = "▏",
      symbol = "│ ",
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
	{
		'stevearc/oil.nvim',
		opts = {},
		-- Optional dependencies
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
  'alvan/vim-closetag',
  'tpope/vim-commentary',
	"rebelot/kanagawa.nvim",
  'tpope/vim-surround',
	{
		"tpope/vim-fugitive",
		delay = 5000,
	},
	-- {
	-- 	"airblade/vim-gitgutter",
	-- 	delay = 2000,
	-- },
  {
		'windwp/nvim-autopairs',
		event = "InsertEnter",
		config = false
	},
	-- 'dkarter/bullets.vim',
	{
		'dkarter/bullets.vim',
		lazy = true,
		event = "BufReadPre *.md",
	},
	"akinsho/toggleterm.nvim",
	"lewis6991/gitsigns.nvim",
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



