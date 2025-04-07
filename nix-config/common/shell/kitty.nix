{ config, pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{

	home.sessionVariables.KITTY_CONFIG_DIRECTORY = "${config.home.homeDirectory}/.config/kitty";

	programs.kitty = {
		enable = true;
    # package = pkgs.writeShellScriptBin "kitty" ''
    #   exec ${nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.kitty}/bin/kitty "$@"
    # '';
    font = {
      name = "ComicShannsMono Nerd Font Mono";
      size = if isDarwin then 13.3 else 13.0;
    };
		shellIntegration = {
			mode = "no-rc";
			enableBashIntegration = false;
			enableFishIntegration = false;
			enableZshIntegration = false;
		};
		extraConfig = ''
			shell /etc/profiles/per-user/katob/bin/zsh
			editor nvim
			bindkey "\e[1;3D" backward-word # ⌥←
			bindkey "\e[1;3C" forward-word # ⌥→

      bold_font        ComicShannsMono Nerd Font Mono Bold
      italic_font      RobotoMono Nerd Font Mono Italic

      allow_remote_control yes

      hide_window_decorations yes
      macos_show_window_title_in none
      # cursor_shape block
      draw_minimal_borders yes

      #macos_thicken_font 0.40

			disable_ligatures always

      background #000000
      foreground #f0f0f0
		'';
	};
}
