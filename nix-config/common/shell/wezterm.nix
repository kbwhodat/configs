{ config, pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{


	programs.wezterm = {
		enable = true;
    enableZshIntegration = false;
    enableBashIntegration = false;
		extraConfig = ''

      local wezterm = require 'wezterm'
      local act = wezterm.action
      local mux = wezterm.mux

      wezterm.on('gui-startup', function(cmd)
        local tab, pane, window = mux.spawn_window(cmd or {})
        window:gui_window():maximize()
      end)

      return {
        front_end = "WebGpu",
        freetype_load_target = 'Light',
        cell_width = 1.0;

        enable_wayland = false,
        enable_kitty_graphics = true,
        cursor_blink_ease_in = 'Linear',
        cursor_blink_ease_out = 'Linear',
        cursor_thickness = "1pt",
        bold_brightens_ansi_colors = "BrightAndBold",

        keys = {
          { key = 'LeftArrow', mods = 'OPT', action = act.SendString '\x1bb' },
          { key = 'RightArrow', mods = 'OPT', action = act.SendString '\x1bf' },
        },
        color_scheme = "Monokai",
        window_decorations = "RESIZE",
        hide_tab_bar_if_only_one_tab = true,
        enable_tab_bar = false,
        font_size = ${if isDarwin then "13.5" else "13.5"},
        line_height = 1.3,
        default_prog = { "/etc/profiles/per-user/katob/bin/zsh" },
        font = wezterm.font("CommitMono Nerd Font Mono", { weight = ${if isDarwin then "Bold" else "Normal"} }),
        font_rules = {
          {
            intensity = "Bold",
            italic = false,
            font = wezterm.font("CommitMono Nerd Font Mono", { weight = "Bold", style = "Normal" }),
          },
          {
            intensity = "Bold",
            italic = true,
            font = wezterm.font("CommitMono Nerd Font Mono", { weight = "Bold", style = "Normal" }),
          },
        },
        window_background_opacity = 4.0,
        window_padding = {
          left = 0,
          right = 0,
          top = 0,
          bottom = 0,
        },
        colors = {
          foreground = '#FFFFFF',
          background = '#000000',
          cursor_fg = 'black',
          cursor_bg = 'white',
          compose_cursor = 'orange',
        },
      }
		'';
	};
}
