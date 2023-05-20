-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  -- use 'wbthomason/packer.nvim'

  -- use {
	  -- 'nvim-telescope/telescope.nvim', tag = '0.1.0',
	  -- -- or                            , branch = '0.1.x',
	  -- requires = { {'nvim-lua/plenary.nvim'} }
  -- }

  -- use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})

	-- use('nvim-treesitter/nvim-treesitter-context')

	-- use('ThePrimeagen/harpoon')

  -- use {
  --   "SmiteshP/nvim-navbuddy",
  --   requires = {
  --     "neovim/nvim-lspconfig",
  --     "SmiteshP/nvim-navic",
  --     "MunifTanjim/nui.nvim"
  --   }
  -- }

	-- use('sheerun/vim-polyglot')

	-- -- use {'akinsho/bufferline.nvim', tag = "v3.*", requires = 'nvim-tree/nvim-web-devicons'}

  -- use("mbbill/undotree")

  -- -- use("yazeed1s/minimal.nvim")

  -- use("tomasiser/vim-code-dark")

  -- use("lukas-reineke/indent-blankline.nvim")

  -- use('wakatime/vim-wakatime')

  -- use('alvan/vim-closetag')

  -- use('tpope/vim-commentary')

  -- use('preservim/vim-markdown')

  -- -- use('TaDaa/vimade')

  -- use('tpope/vim-surround')
  
  -- use('windwp/nvim-autopairs') 

  -- use('lewis6991/impatient.nvim')

  -- use {"akinsho/toggleterm.nvim", tag = '*', config = function()
  --     require("toggleterm").setup()
  -- end}

	-- use{'christoomey/vim-tmux-navigator'}

  -- use{'vimwiki/vimwiki', tag = 'v2022.12.02'}

  -- use ('DanilaMihailov/beacon.nvim')

  -- use {                                              -- filesystem navigation
  --   'kyazdani42/nvim-tree.lua',
  --   requires = 'kyazdani42/nvim-web-devicons'        -- filesystem icons
  -- }
  
  -- use {
	  -- 'VonHeikemen/lsp-zero.nvim',
	  -- requires = {
		  -- -- LSP Support
		  -- {'neovim/nvim-lspconfig'},
		  -- {'williamboman/mason.nvim'},
		  -- {'williamboman/mason-lspconfig.nvim'},

		  -- -- Autocompletion
		  -- {'hrsh7th/nvim-cmp'},
		  -- {'hrsh7th/cmp-buffer'},
		  -- {'hrsh7th/cmp-path'},
		  -- {'saadparwaiz1/cmp_luasnip'},
		  -- {'hrsh7th/cmp-nvim-lsp'},
		  -- {'hrsh7th/cmp-nvim-lua'},

		  -- -- Snippets
		  -- {'L3MON4D3/LuaSnip'},
		  -- {'rafamadriz/friendly-snippets'},
	  -- }
  -- }

end)
