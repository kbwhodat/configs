{ inputs, pkgs, config, ... }:

{
	imports = [
		# ./dash.nix
		# ./nu.nix
		# ./starship.nix
		./bash.nix
    ./zsh.nix
    ./blesh.nix
		./kitty.nix
		./tmux.nix
    # ./ollama.nix
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
