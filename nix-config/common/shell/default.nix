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
    ./password-store.nix
    ./gpg.nix
    ./wezterm.nix
    ./alacritty.nix
    ./sc-im.nix
    ./syncthing.nix
    ./flutter.nix
    ./bookokrat.nix
    # ./openclaw.nix
    # ./ghostty.nix
    # ./python.nix
    # ./ghostty-hm.nix
	];

	home.sessionVariables = {

		# EDITOR = "nvim";
		BROWSER = "zen";
		TERMINAL = "wezterm";
	};

	home.shellAliases = {

	};
}
