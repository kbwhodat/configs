{ inputs, config, pkgs, ... }:

{
	imports = [
		../../../../../common
	];

  home.username = "katob";
  home.homeDirectory = "/Users/katob";
	manual.html.enable = false;
	manual.manpages.enable = false;
	manual.json.enable = false;
  home.enableNixpkgsReleaseCheck = false;


  home.stateVersion = "24.05"; 

  home.sessionVariables = {
    EDITOR = "nvim";
  };


  programs.home-manager.enable = true;
}
