{ config, ... }:

{
	imports = [
		# ./dash.nix
		# ./nu.nix
		# ./starship.nix
		./bash.nix
    ./zsh.nix
		./kitty.nix
		./tmux.nix
		./neovim.nix
    ./password-store.nix
    ./gpg.nix
    # ./node.nix
    # ./python.nix
    # ./scripts
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "firefox";
		TERMINAL = "kitty";
	};

	home.shellAliases = {

	};
}
