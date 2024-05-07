{ config, ... }:

{
	imports = [
		./starship.nix
		./zsh.nix
		./kitty.nix
		./tmux.nix
		./neovim.nix
		./dash.nix
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "firefox";
		TERMINAL = "kitty";
	};

	home.shellAliases = {

	};
}
