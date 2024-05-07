{ config, ... }: {

	home.sessionVariables.KITTY_CONFIG_DIRECTORY = "${config.home.homeDirectory}/.config/kitty";

	programs.kitty = {
		enable = true;
	};
}
