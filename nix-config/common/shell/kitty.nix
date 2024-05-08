{ config, ... }: {

	home.sessionVariables.KITTY_CONFIG_DIRECTORY = "${config.home.homeDirectory}/.config/kitty";

	programs.kitty = {
		enable = true;
		shellIntegrationInit = zsh;
		theme = "FiraCode Nerd Font Medium";
		extraConfig = ''
			shell zsh
			editor nvim
			bindkey "\e[1;3D" backward-word # ⌥←
			bindkey "\e[1;3C" forward-word # ⌥→
		'';
	};
}
