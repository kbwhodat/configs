{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin isLinux;
  sublimeUserDir =
    if isDarwin
    then "Library/Application Support/Sublime Text/Packages/User"
    else ".config/sublime-text/Packages/User";

  sublimePackagesDir =
    if isDarwin
    then "Library/Application Support/Sublime Text/Packages"
    else ".config/sublime-text/Packages";

  neoVintageous = pkgs.fetchFromGitHub {
    owner = "NeoVintageous";
    repo = "NeoVintageous";
    rev = "master";
    hash = "sha256-ROWa64+eRY34XxufOkyPoO2WhulUz9Xh9eod1O8yORA=";
  };
in {
  # macOS install is handled elsewhere (Homebrew cask).
  # Linux install is managed here.
  home.packages = lib.optionals isLinux [
    pkgs.sublime4
  ];

  # Keep Sublime in Vim mode and ensure the built-in Vintage package is enabled.
  home.file."${sublimeUserDir}/Preferences.sublime-settings".text = builtins.toJSON {
    theme = "Adaptive.sublime-theme";
    themed_title_bar = true;
    update_check = false;
    color_scheme = "Packages/User/PureBlack.sublime-color-scheme";
    font_size = 14.5;
    block_caret = false;
    inverse_caret_state = false;
    caret_style = "blink";
    vintage_start_in_command_mode = true;
    vintageous_use_sys_clipboard = true;
    vintageous_reset_mode_when_switching_tabs = false;
    vintageous_highlighted_yank = false;
    vintageous_enable_commentary = true;
    ignored_packages = [ "Vintage" ];
    hot_exit = true;
    remember_open_files = true;
  };

  home.file."${sublimeUserDir}/Default (OSX).sublime-keymap".text = builtins.toJSON [
    {
      keys = [ "super+n" ];
      command = "new_file";
    }
    {
      keys = [ "super+q" ];
      command = "exit";
    }
    {
      keys = [ "super+s" ];
      command = "save";
    }
    {
      keys = [ "super+shift+s" ];
      command = "prompt_save_as";
    }
    {
      keys = [ "super+w" ];
      command = "close";
    }
  ];

  home.file."${sublimeUserDir}/Default (Linux).sublime-keymap".text = builtins.toJSON [
    {
      keys = [ "ctrl+n" ];
      command = "new_file";
    }
    {
      keys = [ "ctrl+q" ];
      command = "exit";
    }
    {
      keys = [ "ctrl+s" ];
      command = "save";
    }
    {
      keys = [ "ctrl+shift+s" ];
      command = "prompt_save_as";
    }
    {
      keys = [ "ctrl+w" ];
      command = "close";
    }
  ];

  # NeoVintageous settings - pass through Ctrl+N to Sublime
  home.file."${sublimeUserDir}/NeoVintageous.sublime-settings".text = builtins.toJSON {
    vintageous_handle_keys = {
      "<C-n>" = false;
      "<C-s>" = false;
      "<C-w>" = false;
      "<C-q>" = false;
    };
  };

  # Install NeoVintageous declaratively for full Vim motions/operators
  # including surround mappings like ysiw and visual S".
  home.file."${sublimePackagesDir}/NeoVintageous" = {
    source = neoVintageous;
    recursive = true;
  };

  # Minimal NeoVintageous defaults.
  home.file.".neovintageousrc".text = ''
    let mapleader="<space>"
    set timeout
    set timeoutlen=1000
    set incsearch
    set hlsearch
    set ignorecase
    set smartcase
    set relativenumber

    nnoremap <leader>; gT
    nnoremap <leader>' gt

    " Safe app quit path via Sublime command (preserves hot_exit flow)
    nnoremap <leader>q :Exit<CR>

    " Keep : prompt responsive; normal-mode quick quit.
    nnoremap Q :Exit<CR>

  '';

  # Mirror NeoVintageous config into Sublime User package dir for reliability.
  home.file."${sublimeUserDir}/.neovintageousrc".text = ''
    let mapleader="<space>"
    set timeout
    set timeoutlen=1000
    set incsearch
    set hlsearch
    set ignorecase
    set smartcase
    set relativenumber

    nnoremap <leader>; gT
    nnoremap <leader>' gt

    " Keep : prompt responsive; normal-mode quick quit.
    nnoremap Q :Exit<CR>

  '';

  # Ex-command alias bridge for NeoVintageous: :Q -> Sublime command "q".
  # NeoVintageous maps uppercase Ex names to Sublime snake_case commands.
  home.file."${sublimeUserDir}/nv_q.py".text = ''
import sublime_plugin

class QCommand(sublime_plugin.WindowCommand):
    def run(self, **kwargs):
        self.window.run_command("exit")
  '';

  home.file."${sublimeUserDir}/PureBlack.sublime-color-scheme".text = builtins.toJSON {
    name = "PureBlack";
    globals = {
      background = "#000000";
      foreground = "#FFFFFF";
      caret = "#FFFFFF";
      block_caret = "#FFFFFF66";
      block_caret_border = "#FFFFFF66";
      block_caret_underline = "#FFFFFF";
      selection = "#6A6A6A";
      selection_foreground = "#000000";
      line_highlight = "#000000";
      inactive_selection = "#4A4A4A";
      guide = "#2A2A2A";
      active_guide = "#404040";
      stack_guide = "#404040";
    };
    rules = [
      {
        name = "Comment";
        scope = "comment";
        foreground = "#BFBFBF";
      }
    ];
  };
}
