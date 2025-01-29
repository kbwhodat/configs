{ config, pkgs, callPackage, inputs,  lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../../../common/nvidia/ollama/ollama.nix
      ../../../../common/nvidia/cuda/cuda.nix
      ../../../../common/ssh/ssh.nix
      ../../../../common/nixos-config
      ../../../../common/nixos-config/performance
      # ../../../../pkgs
    ];


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    usbutils
    displaylink
    steam
    # zulu17
    zulu11
    grobi
    linuxKernel.packages.linux_6_6.evdi
    # python3Packages.torch-bin

  ];

  environment.variables = {    
    WLR_EVDI_RENDER_DEVICE = "/dev/dri/card1";                                                                                                   
  };

  # Define the dlm.service (DisplayLink Manager)
  systemd.services.dlm = {
    enable = true;
    description = "DisplayLink Manager Service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      Restart = "always";
      RestartSec = 5;
    };
  };
  networking.hostName = "nixos-main"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.wireless.interfaces = [ "wlp0s20f3" ];

  services.logind.lidSwitchExternalPower = "ignore";

  services.xserver.videoDrivers = [ "nvidia" "displaylink" "modesetting" ];
}
