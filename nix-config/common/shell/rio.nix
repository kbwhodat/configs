{ config, pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{

	programs.rio = {
		enable = if isDarwin then true else true;
    settings = {
    fonts = {
      family = "ComicShannsMono Nerd Font Mono";
      size = if isDarwin then 14.3 else 14.0;
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
