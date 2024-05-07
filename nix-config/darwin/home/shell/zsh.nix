{ pkgs, config, lib, ... }:

let 
	zshConf = builtins.readFile ./zshrc;
in
{
	programs.zsh = {
		enable = true;
		dotDir = ".config/zsh";
		plugins = [
		{
			name = "vi-mode";
			src = pkgs.zsh-vi-mode;
			file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
		}
		];
	};
}
