{ config, pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{

	programs.rio = {
		enable = true;
    settings = {
    fonts = {
      family = "ComicShannsMono Nerd Font Mono";
      size = if isDarwin then 12.8 else 14.5;
      use-drawable-chars = false;
    };
    navigation = {
      mode = "Plain";
    };
    colors = {
      background = "#000000";
    };
    blinking-cursor = false;
    window = {
      blur = false;
      decorations = "Disabled";
      };
    };
  };
}
