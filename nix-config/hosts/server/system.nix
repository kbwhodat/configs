{ config, pkgs, callPackage, inputs,  lib, ... }:

{
  imports =
    [ 
      ./hardware.nix
      ../../modules/system/nvidia/ollama/ollama.nix
      ../../modules/system/nvidia/cuda/cuda.nix
      ../../modules/system/ssh
      ../../modules/system/nixos-config
      ../../modules/system/nixos-config/performance
      # ../../../../pkgs
    ];

  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards.keychron = {
      config = builtins.readFile ../../../kanata/kanata.kbd;
    };
  };

  # more modern way of enabling bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fonts.fontDir.enable = true;

  networking.hostName = "nixos-server"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlan0" ];

	programs.zsh.enable = true;

  services.xserver.videoDrivers = [ "nvidia" "modesetting" ];
}
