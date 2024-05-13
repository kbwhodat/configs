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
			shell bash
			editor nvim
			bindkey "\e[1;3D" backward-word # ⌥←
			bindkey "\e[1;3C" forward-word # ⌥→

			disable_ligatures always
		'';
	};
}
