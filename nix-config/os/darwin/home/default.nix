{ inputs, config, pkgs, ... }:

{
	imports = [
    ../../../common/sops
		../../../common
    ../../../common/work
    ../../../pkgs
	];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "katob";
  home.homeDirectory = "/Users/katob";
	manual.html.enable = false;
	manual.manpages.enable = false;
	manual.json.enable = false;
  home.enableNixpkgsReleaseCheck = false;

  home.stateVersion = "25.05"; # Please read the comment before changing.

  #home.file."/Users/katob/.katotoken".source = config.sops.secrets."github-token".path;
  home.sessionVariables = {
    # EDITOR = "nvim";
  };

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
        nix-direnv.enable = true;
    };

    bash.enable = true; # see note on other shells below
  };

  programs.home-manager.enable = true;
}
