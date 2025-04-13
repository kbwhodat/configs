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
  { 'glacambre/firenvim', build = ":call firenvim#install(0)" },
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
		delay = 2000,
    dependencies = { {'nvim-lua/plenary.nvim'} }
  },
  { "CRAG666/code_runner.nvim", config = true },
  {
    "frabjous/knap"
  },
  {
    "tris203/precognition.nvim"
  },
  {
    "kbwhodat/alabaster.nvim",
    init = function()
      vim.g.alabaster_dim_comments = true
      vim.g.background = dark
    end,
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = false },
      quickfile = { enable = false },
      dashboard = { enabled = false },
      explorer = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      picker = { enabled = false },
      notifier = { enabled = false },
      quickfile = { enabled = false },
      scope = { enabled = false },
      scroll = { enabled = false },
      gitbrowser = { enabled = false },
      scratch = { enabled = false },
      statuscolumn = { enabled = false },
      image = { 
        enabled = true, 
        force = false,
        doc = {
          enabled = true,
          inline = false,
          float = true,
          max_width = 45,
          max_height = 45,
        },
        cache = vim.fn.stdpath("cache") .. "/snacks/image",
      },
      words = { enabled = true },
    },
    keys = {
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
      { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>G",  function() Snacks.gitbrowse() end, desc = "Git browsing" },
      { "<leader>ff",  function() Snacks.picker() end, desc = "Picking out" },
    }
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
      { "<leader>qw", function() require("persistence").save() end, desc = "Save Current Session" },
    },
  },
  "mbbill/undotree",
	 'alvan/vim-closetag',
	"rebelot/kanagawa.nvim",
	 'tpope/vim-surround',
	{
		"tpope/vim-fugitive",
		delay = 5000,
	},
	{
		'dkarter/bullets.vim',
		lazy = true,
		event = "BufReadPre *.md",
	},
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
	 "petertriho/cmp-git",
	 dependencies = { 'hrsh7th/nvim-cmp' },
	 opts = {
	   -- options go here
	 },
	 init = function()
	   table.insert(require("cmp").get_config().sources, { name = "git" })
	 end,

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
  'hrsh7th/vim-vsnip'
}


local opts = {}

require("lazy").setup(plugins, opts)



