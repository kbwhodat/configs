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
		'neoclide/coc.nvim',
			branch = 'release'
	},
	{
		"3rd/image.nvim",
	},
	{
		"tpope/vim-dadbod"
	},
	{
		"kristijanhusak/vim-dadbod-ui"
	},
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = { delay = 200 },
    config = function(_, opts)
      require("illuminate").configure(opts)

      local function map(key, dir, buffer)
        vim.keymap.set("n", key, function()
          require("illuminate")["goto_" .. dir .. "_reference"](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
      end

      map("]]", "next")
      map("[[", "prev")

      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map("]]", "next", buffer)
          map("[[", "prev", buffer)
        end,
      })
    end,
    keys = {
      { "]]", desc = "Next Reference" },
      { "[[", desc = "Prev Reference" },
    },
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
            filetype = "neo-tree",
            text = "Neo-tree",
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

  { "MunifTanjim/nui.nvim", lazy = true },

  {
    "nvim-neorg/neorg",
    build = ":Neorg sync-parsers",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("neorg").setup {
        load = {
          ["core.defaults"] = {}, -- Loads default behaviour
					["core.integrations.treesitter"] = {},
					["core.export.markdown"] = {},
					["core.syntax"] = {},
					["core.highlights"] = {},
					["core.mode"] = {},
					["core.neorgcmd"] = {},
					["core.autocommands"] = {},
          ["core.concealer"] = {
						config = {

							icons = {
								heading = {
									icons = {"◉"}
								}
							},
							folds = true,
							init_open_folds = "never"
						},
					}, -- Adds pretty icons to your documents
          ["core.qol.todo_items"] = {}, -- For enhanced to-do list functionalities.
          ["core.esupports.hop"] = {}, -- For enhanced to-do list functionalities.
          ["core.esupports.indent"] = {}, -- For enhanced to-do list functionalities.
          ["core.esupports.metagen"] = {}, -- For enhanced to-do list functionalities.
          ["core.journal"] = {
            config = {
              workspace = "incidents"
            }
          }, -- For enhanced to-do list functionalities.
          ["core.ui"] = {}, -- For a calendar view within Neovim.
          ["core.integrations.truezen"] = {}, -- For executing code blocks within Neorg files.
          ["core.neorgcmd.commands.return"] = {}, -- For executing code blocks within Neorg files.
          ["core.dirman"] = { -- Manages Neorg workspaces
            config = {
              workspaces = {
                work = "~/notes/work",
                incidents = "~/notes/work/Incidents",
                home = "~/notes/home",
                notes = "~/notes/notes",
								dj = "~/notes/dj",
								development = "~/notes/development",
								learning = "~/notes/learning"
              },
              default_workspace = "notes"
            },
          },
        },
      }
      vim.wo.foldlevel = 99
      vim.wo.conceallevel = 3
    end,
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

  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    config = function()
      vim.g.startuptime_tries = 10
    end,
  },

  'nvim-treesitter/nvim-treesitter-context',
  -- 'ThePrimeagen/harpoon',
  {
    "SmiteshP/nvim-navbuddy",
    dependencies = {
			"neovim/nvim-lspconfig",
			"SmiteshP/nvim-navic",
			"MunifTanjim/nui.nvim",
			"numToStr/Comment.nvim",        -- Optional
			"nvim-telescope/telescope.nvim" -- Optional
    },
		opts = { lsp = { auto_attach = true } }
  },
  -- 'sheerun/vim-polyglot',
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
  'preservim/vim-markdown',
	"rebelot/kanagawa.nvim",
  -- {
  --   'nvim-lualine/lualine.nvim',
  --   dependencies = { 'nvim-tree/nvim-web-devicons', opt = true }
  -- },
  'tpope/vim-surround',
  'windwp/nvim-autopairs' ,
  'lewis6991/impatient.nvim',
  "akinsho/toggleterm.nvim",
	"lewis6991/gitsigns.nvim",
  'christoomey/vim-tmux-navigator',
	{"airblade/vim-gitgutter"},
  -- {'vimwiki/vimwiki'},
  'DanilaMihailov/beacon.nvim',
  -- {                                              -- filesystem navigation
  --   'kyazdani42/nvim-tree.lua',
  --   dependencies = 'nvim-tree/nvim-web-devicons'        -- filesystem icons
  -- },
  {
    'VonHeikemen/lsp-zero.nvim',
    dependencies = {
      -- LSP Support
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
    }
  }
}


local opts = {}

require("lazy").setup(plugins, opts)



