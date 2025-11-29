{ pkgs, ...}:
{
  programs.helix = {
    enable = true;
    defaultEditor = false;
    package = pkgs.evil-helix;
    settings = {
      theme = "alabaster-dark";
      editor = {
        line-number = "relative";
        lsp.display-messages = true;        
        mouse = false;
        statusline = {
          mode.normal = "N";
          mode.insert = "I";
          mode.select = "V";
        };
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
      };
      keys.normal = {
        esc = [ "collapse_selection" "keep_primary_selection" ];
      };
      keys.normal." " = {
        ";" = "goto_previous_buffer";
        "'" = "goto_next_buffer";
        d = ":buffer-close";
        space = "file_picker";
        w = ":w";
        q = ":q";
      };
    };
    themes = {
      alabaster-dark =
        let
          white = "#ffffff";

          bg = "#000000";
          bg_darker = "#111111";
          bg_ui = "#000000";
          bg_menu = "#000000";
          bg_error = "#3a0000";
          bg_hint = "#1a1a1a";

          fg = "#e5e5e5";
          fg_light = "#8a8a8a";

          status_bar_bg = "#000000";
          status_bar_fg = "#d7d7d7";

          definitions = "#7ba2ff";   # functions
          constants = "#cc8bc9";     # constants
          punctuation = "#aaaaaa";

          inact_status_bar_bg = "#1b1b1b";
          inact_status_bar_fg = "#555555";

          comment = "#696969";
          string = "#7bc96f";
          selected = "#264f78";

          cursor = "#cccccc";

          red = "#ff6b5a";
          green = "#3acb3a";
          indent = "#444444";
          orange = "#f0ad4e";
          gray = "#999999";
        in {
          "ui.background" = { bg = bg; };
          "ui.text" = fg;
          "ui.text.focus" = { bg = selected; };
          "ui.linenr" = { fg = fg_light; };
          "ui.linenr.selected" = { bg = bg; fg = fg; };
          "ui.selection" = { bg = selected; };
          "ui.cursorline" = { bg = bg_ui; };

          "ui.statusline" = { fg = status_bar_fg; bg = status_bar_bg; };
          "ui.statusline.inactive" = {
            fg = inact_status_bar_fg;
            bg = inact_status_bar_bg;
          };

          "ui.virtual" = indent;
          "ui.virtual.ruler" = { bg = bg_ui; };
          "ui.virtual.jump-label" = {
            fg = fg;
            bg = orange;
            modifiers = [ "bold" ];
          };

          "ui.cursor.match" = { bg = bg_darker; };
          "ui.cursor" = { bg = cursor; fg = white; };
          "ui.debug" = { fg = orange; };
          "ui.highlight.frameline" = { bg = "#803333"; };

          "ui.help" = { fg = fg; bg = bg; };
          "ui.popup" = { fg = fg; bg = bg_ui; };
          "ui.menu" = { fg = fg; bg = bg_menu; };
          "ui.menu.selected" = { bg = selected; };
          "ui.window" = { bg = bg_ui; };

          "ui.bufferline" = { fg = fg; bg = bg; };
          "ui.bufferline.active" = { fg = fg; bg = bg; };

          # Syntax groups
          "string" = string;
          "comment" = comment;
          "function" = definitions;
          "constant" = constants;
          "punctuation" = punctuation;

          # Diagnostics
          "error" = { fg = red; bg = bg_error; };
          "warning" = { fg = orange; };
          "hint" = { fg = gray; bg = bg_hint; };

          "diagnostic.error" = {
            fg = red;
            bg = bg_error;
            underline = { style = "curl"; };
            modifiers = [ ];
          };

          "diagnostic.warning" = {
            bg = orange;
            fg = fg;
            modifiers = [ "bold" ];
          };

          "diagnostic.hint" = {
            fg = gray;
            modifiers = [ "bold" ];
          };

          "diagnostic.unnecessary" = {
            modifiers = [ "dim" ];
          };

          "diagnostic.deprecated" = {
            modifiers = [ "crossed_out" ];
          };

          # Diff colors
          "diff.plus" = { fg = green; };
          "diff.delta" = { fg = bg_ui; };
          "diff.minus" = { fg = red; };
        };
    };
  };
}
