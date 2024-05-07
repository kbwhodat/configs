{ config, ... }:

{
	imports = [
		./starship.nix
		./zsh.nix
		./kitty.nix
		./tmux.nix
		./neovim.nix
	];

	home.sessionVariable = {

		EDITOR = "nvim";
		BROWSER = "firefox";
		TERMINAL = "kitty";
	};

	home.shellAliases = {

	};
}
