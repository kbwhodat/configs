{ inputs, pkgs, config, ... }:

{
	imports = [
    ./emacs.nix
    ./jujutsu.nix
    ./repos.nix
    ./bash.nix
    ./zsh.nix
    ./blesh.nix
    ./direnv.nix
    ./kitty.nix
    ./rio.nix
    ./tmux.nix
    ./neovim.nix
    ./password-store.nix
    ./gpg.nix
    ./wezterm.nix
    ./alacritty.nix
    # ./ghostty.nix
    # ./python.nix
    # ./ghostty-hm.nix
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "firefox";
		TERMINAL = "wezterm";
	};

	home.shellAliases = {

	};
}
