{ config, pkgs, ... }:
{
  home.package = with pkgs; [
    libsForQt5.okular
  ];
}
