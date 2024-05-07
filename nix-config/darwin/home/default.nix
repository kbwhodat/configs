{ config, pkgs, ... }:

{
	home.packages = [ pkgs.atool pkgs.httpie ];  

	home.username = "katob";
	home.homeDirectory = "Users/katob";

	programs.bash.enable = false;  
	programs.zsh.enable = true;  

	home.stateVersion = "23.11";  
}
