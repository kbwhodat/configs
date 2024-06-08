{ config, pkgs, callPackage, inputs,  lib, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../../../common/nvidia/ollama/ollama.nix
      ../../../../common/nvidia/cuda/cuda.nix
      ../../../../common/ssh/ssh.nix
      ../../../../common/nixos-config
    ];


  # more modern way of enabling bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-server"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlo1" ];

	programs.zsh.enable = true;

}
