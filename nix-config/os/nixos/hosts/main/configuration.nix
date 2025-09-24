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

  nixpkgs.config.packageOverrides = pkgs: {
    mplayer = pkgs.mplayer.override {
      v4lSupport = true;
    };
  };

  fonts.fontDir.enable = true;

  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards.main = {
      config = builtins.readFile ../../../../../kanata/kanata.kbd;
    };
  };

  environment.systemPackages = with pkgs; [
    usbutils
    displaylink
    # zulu17
    zulu11
    grobi
    linuxKernel.packages.linux_6_6.evdi
    # gdb
    # python3Packages.torch-bin
    protonplus
    mplayer
    v4l2-to-ndi
    gpu-screen-recorder
    obs-studio
  ];

  environment.variables = {    
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
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
