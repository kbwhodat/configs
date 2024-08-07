{ config, pkgs, inputs, ... }: 
# let
#   nixgl = pkgs.nixgl;
# in
{

	home.sessionVariables.KITTY_CONFIG_DIRECTORY = "${config.home.homeDirectory}/.config/kitty";

	programs.kitty = {
		enable = true;
    # package = pkgs.writeShellScriptBin "kitty" ''
    #   exec ${nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.kitty}/bin/kitty "$@"
    # '';
    font = {
      name = "RobotoMono Nerd Font Mono Medium Regular";
      size = 13.0;
    };
		shellIntegration = {
			mode = "no-rc";
			enableBashIntegration = false;
			enableFishIntegration = false;
			enableZshIntegration = false;
		};
		extraConfig = ''
			shell /run/current-system/sw/bin/bash
			editor nvim
			bindkey "\e[1;3D" backward-word # ⌥←
			bindkey "\e[1;3C" forward-word # ⌥→

      bold_font        RobotoMono Nerd Font Mono Bold
      italic_font      RobotoMono Nerd Font Mono Italic

      allow_remote_control yes

      hide_window_decorations yes
      macos_show_window_title_in none
      # cursor_shape block
      draw_minimal_borders yes

			disable_ligatures always
		'';
	};
}
