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
    font_face = "JetBrains Mono";
    font_size = 14.5;
    line_padding_bottom = 1;
    line_padding_top = 1;
    block_caret = false;
    inverse_caret_state = false;
    caret_style = "blink";

    # Minimal UI
    highlight_line = false;
    draw_white_space = "none";
    fold_buttons = false;
    margin = 0;

    # Editing defaults
    tab_size = 2;
    translate_tabs_to_spaces = true;
    detect_indentation = true;
    trim_trailing_white_space_on_save = "all";
    ensure_newline_at_eof_on_save = true;
    default_line_ending = "unix";
    scroll_past_end = true;

    # Vintageous
    vintage_start_in_command_mode = true;
    vintageous_use_sys_clipboard = true;
    vintageous_reset_mode_when_switching_tabs = false;
    vintageous_highlighted_yank = false;
    ignored_packages = [ "Vintage" ];

    # Indexing / search
    hot_exit = true;
    remember_open_files = true;
    index_files = true;
    binary_file_patterns = [
      "*.jpg" "*.jpeg" "*.png" "*.gif" "*.ttf" "*.tga" "*.dds" "*.ico"
      "*.eot" "*.pdf" "*.swf" "*.jar" "*.zip" "*.tar.gz" "*.tar.bz2"
      "*.rar" "*.7z" "*.exe" "*.dll" "*.pdb" "*.so" "*.dylib"
    ];
    # Directories excluded from the index (binary_file_patterns only
    # matches files, so directory patterns there would be no-ops).
    index_exclude_patterns = [
      "*.log" "node_modules/*" ".git/*" "target/*" "build/*" "dist/*"
    ];
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
  # Ctrl+Q is captured by NeoVintageous so we can remap it to <C-v>
  # (blockwise-visual) below in .neovintageousrc.
  home.file."${sublimeUserDir}/NeoVintageous.sublime-settings".text = builtins.toJSON {
    vintageous_handle_keys = {
      "<C-n>" = false;
      "<C-s>" = false;
      "<C-w>" = false;
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

    " Ctrl-Q enters blockwise-visual (same as Ctrl-V in vanilla vim).
    nnoremap <C-q> <C-v>
    xnoremap <C-q> <C-v>

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

    " Ctrl-Q enters blockwise-visual (same as Ctrl-V in vanilla vim).
    nnoremap <C-q> <C-v>
    xnoremap <C-q> <C-v>

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

  # Minimap/status-bar visibility is per-window SESSION state — Sublime
  # has no preference key for either ("show_minimap" etc. are silently
  # ignored), and the plugin API is the only deterministic handle.
  # Enforce the desired chrome on startup + new windows:
  # minimap, status bar, and tab bar all hidden.
  # (Tab nav stays on SPC ;/' -> gT/gt and goto-anything.)
  home.file."${sublimeUserDir}/hide_ui.py".text = ''
import sublime
import sublime_plugin


def _apply_chrome(window):
    if window is None or not window.is_valid():
        return
    try:
        if window.is_minimap_visible():
            window.set_minimap_visible(False)
        if window.is_status_bar_visible():
            window.set_status_bar_visible(False)
        if window.get_tabs_visible():
            window.set_tabs_visible(False)
    except Exception:
        pass


class HideUiListener(sublime_plugin.EventListener):
    def on_new_window(self, window):
        _apply_chrome(window)


def plugin_loaded():
    sublime.set_timeout(lambda: [_apply_chrome(w) for w in sublime.windows()], 0)
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
