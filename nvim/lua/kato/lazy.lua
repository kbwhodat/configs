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
  -- { 'glacambre/firenvim', build = ":call firenvim#install(0)" },
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
		delay = 2000,
    dependencies = { {'nvim-lua/plenary.nvim'} }
  },
  { "CRAG666/code_runner.nvim", config = true },
  -- {
  --   "frabjous/knap"
  -- },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- Set a custom highlight group for Oil float
      vim.api.nvim_set_hl(0, "OilNormalFloat", { bg = "#000000" })  -- or "#1e1e1e" for softer black

      require("oil").setup({
        default_file_explorer = false,
        skip_confirm_for_simple_edits = true,

        keymaps = {
          ["<CR>"] = {
            function()
              local oil = require("oil")
              local entry = oil.get_cursor_entry()
              local dir = oil.get_current_dir()

              if entry and entry.type == "file" and dir and vim.g.oil_open_in_zed then
                local file_path = dir .. entry.name
                vim.fn.jobstart({ "zeditor", file_path }, { detach = true })
                vim.cmd("qa!")
              else
                require("oil.actions").select.callback()
              end
            end,
          },
          ["<C-s>"] = { "actions.select", opts = { vertical = true } },
          ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
          ["<C-t>"] = { "actions.select", opts = { tab = true } },
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<C-r>"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["q"] = "actions.close",
          ["<Esc>"] = "actions.close",
        },

        use_default_keymaps = false,

        view_options = {
          show_hidden = true,
          is_always_hidden = function(name)
            return name == ".." or name == ".git"
          end,
          natural_order = true,
          sort = {
            { "type", "asc" },
            { "name", "asc" },
          },
        },
      })

      -- Global mappings
      vim.keymap.set("n", "-", "<CMD>Oil<CR>")
      vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>")
    end,
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
    "nicolasgb/jj.nvim",
    config = function()
      require("jj").setup({})
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
      gitbrowser = { enabled = true },
      scratch = { enabled = false },
      statuscolumn = { enabled = false },
      image = {
        enabled = false,
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
      { "<leader>x",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>G",  function() Snacks.gitbrowse() end, desc = "Git browsing" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>g", function() Snacks.picker.git_grep() end, desc = "Grep" },
      -- { "<leader>e", function() Snacks.explorer() end, desc = "explorer" },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },

      { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "command history" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
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

  -- {'neovim/nvim-lspconfig'},
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
