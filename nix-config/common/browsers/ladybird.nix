{ config, pkgs, inputs,  ... }:
{

  home.packages = with pkgs; [
    ladybird
    netsurf.browser
  ];
}
