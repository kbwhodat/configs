{ config, pkgs, ...}:
{
  home.packages = with pkgs; [
    koreader
  ];
}
