{ pkgs, config, ...}: 

let
	tmuxConf = builtins.readFile "${config.home.homeDirectory}/.config/tmux/tmux.conf";
in
{

	programs.tmux = {
		enable = true;
		extraConfig = tmuxConf;
	};

}
