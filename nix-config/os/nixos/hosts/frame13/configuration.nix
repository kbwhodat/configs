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
    # amdenc
    pciutils
    amdgpu_top
    usbutils
    # clang
    gcc
    brightnessctl
    xorg.xev
    pavucontrol
    clinfo
    pamixer
    ffmpeg
  ];

  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    mesa.drivers
    amdvlk
  ];

  services.xserver.displayManager.sessionCommands = ''
    xrandr --output eDP --mode 2256x1504 --scale 0.85x0.85
  '';

  networking.hostName = "nixos-frame13"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlp0s20f3" ];

  services.fwupd.enable = true;
  services.upower.enable = true;

  services.xserver.videoDrivers = [ "amdgpu"  ];
}
