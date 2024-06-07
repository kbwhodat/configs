# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, callPackage, inputs,  lib, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../../../common/nvidia/ollama/ollama.nix
      ../../../../common/nvidia/cuda/cuda.nix
      ../../../../common/ssh/ssh.nix
    ];


  # more modern way of enabling bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-server"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlo1" ];
	networking.wireless.networks = {
		"results will vary" = {
			psk = "wasswa123";
		};
	};

	programs.zsh.enable = true;

}
