{ config, pkgs, ... }:

{

  programs.ssh = {
    enable = true;
    controlPersist = "60m";
    forwardX11 = true;
  };
}
