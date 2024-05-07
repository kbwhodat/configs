{ pkgs, config, lib, ... }:

let 
	zshConf = builtins.readFile "${config.home.homeDirectory}/.config/zsh/zshrc";
in
{
	programs.zsh = {
		enable = true;
		extraConfig = zshConf;
		plguins = [
		{
			name = "vi-mode";
			src = pkgs.zsh-vi-mode;
			file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
		}
		]
	};
}
