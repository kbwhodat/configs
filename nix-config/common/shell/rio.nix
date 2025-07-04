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
      size = if isDarwin then 11.3 else 11.0;
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
