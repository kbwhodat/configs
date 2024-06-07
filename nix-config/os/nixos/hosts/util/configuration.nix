# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, callPackage, inputs,  lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../../../common/ssh/ssh.nix
    ];


  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";


  networking.hostName = "nixos-util"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlan0" ];
	networking.wireless.networks = {
		"results will vary" = {
			psk = "wasswa123";
		};
  };

}
