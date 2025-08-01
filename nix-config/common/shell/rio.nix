{ config, pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{

	programs.rio = {
		enable = true;
    settings = {
    cursor = {
        shape = "beam";
        blinking = true;
      };
    fonts.regular = {
      family = "ComicShannsMono Nerd Font Mono";
      size = if isDarwin then 12.8 else 14.8;
      weight = 900;
    };
    colors = {
      background = "#000000";
    };
    editor = {
        program = "vim";
      };
    blinking-cursor = true;
    window = {
      blur = false;
      # decorations = "Disabled";
      };
    };
  };
}
