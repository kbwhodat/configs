{ config, ...}: {

	home.sessionVariables.STARSHIP_CONFIG = "${config.home.homeDirectory}/.config/starship.toml";

	programs.starship = {
		enable = true;
	};

}
