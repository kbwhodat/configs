{ config, pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{

	programs.rio = {
		enable = if isDarwin then true else true;
    settings = {
    cursor = {
        shape = "beam";
        blinking = true;
      };
    fonts.regular = {
      family = "ComicShannsMono Nerd Font Mono";
      size = if isDarwin then 14.3 else 14.0;
    };
    navigation = {
      mode = "Plain";
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
