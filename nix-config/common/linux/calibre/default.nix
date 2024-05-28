{ pkgs, configs, ... }:
{
  home.packages = with pkgs; [
    calibre
  ];
}
