{ config, pkgs, callPackage, inputs,  lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../../../common/ssh/ssh.nix
      ../../../../common/nixos-config
      # ../../../../pkgs
    ];


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    usbutils
    steam
    clang
    zulu11
    brightnessctl
    xorg.xev
    # python3Packages.torch-bin

  ];

  networking.hostName = "nixos-frame16"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlp0s20f3" ];

  services.xserver.videoDrivers = [ "amdgpu"  ];
}
