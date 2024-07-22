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
      # name = "FiraCode Nerd Font Medium";
      #name = "Input Mono Medium Regular";
      name = "Mononoki Regular";
      size = 14.0;
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

      bold_font        Mononoki Bold
      italic_font      Mononoki Italic

      hide_window_decorations yes
      macos_show_window_title_in none
      # cursor_shape block
      draw_minimal_borders yes

			disable_ligatures always
		'';
	};
}
