{ inputs, pkgs, config, ... }:

{
	imports = [
    ./repos.nix
    ./bash.nix
    ./blesh.nix
    ./kitty.nix
    ./tmux.nix
    ./neovim.nix
    ./password-store.nix
    ./gpg.nix
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "floorp";
		TERMINAL = "kitty";
	};

	home.shellAliases = {

	};
}
