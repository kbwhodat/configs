{ inputs, pkgs, config, ... }:

{
	imports = [
    ./repos.nix
      ./bash.nix
      ./zsh.nix
      ./blesh.nix
      ./kitty.nix
      ./tmux.nix
      #./zellij.nix
      ./neovim.nix
      ./password-store.nix
      ./gpg.nix
	];

	home.sessionVariables = {

		EDITOR = "nvim";
		BROWSER = "firefox";
		TERMINAL = "kitty";
	};

	home.shellAliases = {

	};
}
