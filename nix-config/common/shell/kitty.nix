{ config, pkgs, ... }: {

	home.sessionVariables.KITTY_CONFIG_DIRECTORY = "${config.home.homeDirectory}/.config/kitty";

	programs.kitty = {
		enable = true;
    font = {
      name = "FiraCode Nerd Font";
      size = 13;
    };
		shellIntegration = {
			mode = "no-rc";
			enableBashIntegration = false;
			enableFishIntegration = false;
			enableZshIntegration = false;
		};
		extraConfig = ''
			# shell bash
			editor nvim
			bindkey "\e[1;3D" backward-word # ⌥←
			bindkey "\e[1;3C" forward-word # ⌥→

      bold_font        FiraCode Nerd Font Bold

      hide_window_decorations yes
      macos_show_window_title_in none
      cursor_shape block
      draw_minimal_borders yes

			disable_ligatures always
		'';
	};
}
