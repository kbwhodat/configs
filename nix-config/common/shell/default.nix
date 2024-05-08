{ config, ... }:

{
	imports = [
		# ./dash.nix
		# ./nu.nix
		# ./starship.nix
		./zsh.nix
		./kitty.nix
		./tmux.nix
		./neovim.nix
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "firefox";
		TERMINAL = "kitty";
	};

	home.shellAliases = {

	};
}
