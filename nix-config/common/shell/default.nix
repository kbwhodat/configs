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
    ./ghostty.nix
    # ./ghostty-hm.nix
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "floorp";
		TERMINAL = "ghostty";
	};

	home.shellAliases = {

	};
}
