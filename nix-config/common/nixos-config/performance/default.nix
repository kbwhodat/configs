{ lib, config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sysstat
    linuxPackages_latest.perf
    bcc
    atop
  ];
}
