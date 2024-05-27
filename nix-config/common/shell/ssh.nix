{ config, pkgs, ... }:

{

  programs.ssh = {
    enable = false;
    controlPersist = "60m";
  };
}
