# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, callPackage, inputs,  lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../../../common/ssh/ssh.nix
      ../../../../common/nixos-config
    ];


  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";

  networking.hostName = "nixos-util"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlp3s0" ];

  services.logind.lidSwitchExternalPower = "suspend-then-hibernate";
  services.logind.lidSwitch = "suspend-then-hibernate";

  systemd.sleep.extraConfig = "AllowSuspendThenHibernate=yes\nSuspendState=suspend\nHibernateState=hibernate\nHibernateDelaySec=60s";

#  services.autosuspend = {
#    enable = true;
#    settings = {
#      enable = true;
#      interval = 30;
#      idle_time = 60;
#      lock_file = "/var/lock/autosuspend.lock";
#    };
#
#    checks = {
#      Ping = {
#        enabled = false;
#      };
#
#      RemoteUsers = {
#        class = "Users";
#        name = ".*";
#        terminal = ".*";
#        host = "[0-9].*";
#      };
#    };
#  };

}
