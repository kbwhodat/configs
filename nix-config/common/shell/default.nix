{ inputs, pkgs, config, ... }:

{
	imports = [
    ./repos.nix
    ./bash.nix
    ./blesh.nix
    ./direnv.nix
    ./kitty.nix
    ./tmux.nix
    ./neovim.nix
    ./password-store.nix
    ./gpg.nix
    ./ghostty.nix
    # ./python.nix
    # ./ghostty-hm.nix
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "zen";
		TERMINAL = "ghostty";
	};

	home.shellAliases = {

	};
}
