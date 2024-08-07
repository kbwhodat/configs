{ inputs, config, pkgs, ... }:

{
	imports = [
    ../../../common/sops
		../../../common
    ../../../common/work
	];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "katob";
  home.homeDirectory = "/Users/katob";
	manual.html.enable = false;
	manual.manpages.enable = false;
	manual.json.enable = false;
  home.enableNixpkgsReleaseCheck = false;

  home.stateVersion = "24.05"; # Please read the comment before changing.

  #home.file."/Users/katob/.katotoken".source = config.sops.secrets."github-token".path;
  home.sessionVariables = {
    EDITOR = "nvim";
  };


  programs.home-manager.enable = true;
}
