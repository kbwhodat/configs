{ pkgs, config, ...}: 

let
	tmuxConf = builtins.readFile ./tmux.conf;
in
{

	programs.tmux = {
		enable = true;
		extraConfig = tmuxConf;
	};

}
