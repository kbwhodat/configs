{ config, pkgs, ...}:

{
  home.packages = with pkgs; [
    runelite
    hdos
    # bolt-launcher
  ];
}
