{ config, pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{


	programs.wezterm = {
		enable = true;
		extraConfig = ''

      local wezterm = require 'wezterm'
      local act = wezterm.action
      local mux = wezterm.mux

      wezterm.on('gui-startup', function(cmd)
        local tab, pane, window = mux.spawn_window(cmd or {})
        window:gui_window():maximize()
      end)

      return {
        -- front_end = "OpenGL",
        enable_wayland = false,
        enable_kitty_graphics = true,
        cursor_blink_ease_in = 'Linear',
        cursor_blink_ease_out = 'Linear',
        keys = {
          { key = 'LeftArrow', mods = 'OPT', action = act.SendString '\x1bb' },
          { key = 'RightArrow', mods = 'OPT', action = act.SendString '\x1bf' },
        },
        color_scheme = "Alabaster",
        window_decorations = "NONE",
        hide_tab_bar_if_only_one_tab = true,
        enable_tab_bar = false,
        font_size = 13.0,
        default_prog = { "/etc/profiles/per-user/katob/bin/zsh" },
        font = wezterm.font("CommitMono Nerd Font Mono"),
        font_rules = {
          {
            intensity = "Bold",
            italic = false,
            font = wezterm.font("CommitMono Nerd Font Mono", { weight = "Bold", stretch = "Normal", style = "Normal" }),
          },
          {
            intensity = "Bold",
            italic = true,
            font = wezterm.font("CommitMono Nerd Font Mono", { weight = "Bold", stretch = "Normal", style = "Italic" }),
          },
        },
        window_background_opacity = 3.0,
        window_padding = {
          left = 0,
          right = 0,
          top = 0,
          bottom = 0,
        },
        colors = {
          foreground = 'white',
          background = 'black',
          cursor_fg = 'black',
          cursor_bg = 'white',
          compose_cursor = 'orange',
          tab_bar = {
            background = '#0b0022',
            active_tab = {
              bg_color = '#2b2042',
              fg_color = '#c0c0c0',

              intensity = 'Normal',

              underline = 'None',
              italic = false,

              strikethrough = false,
            },

            inactive_tab = {
              bg_color = '#1b1032',
              fg_color = '#808080',
            },

            inactive_tab_hover = {
              bg_color = '#3b3052',
              fg_color = '#909090',
              italic = true,
            },

            new_tab = {
              bg_color = '#1b1032',
              fg_color = '#808080',
            },

            new_tab_hover = {
              bg_color = '#3b3052',
              fg_color = '#909090',
              italic = true,
            },
          },
        },
      }
		'';
	};
}
