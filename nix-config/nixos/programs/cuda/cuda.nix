{ config, pkgs, lib, ... }:

{
  # Enable CUDA support
  nixpkgs.config.cudaSupport = true;

  # Add CUDA toolkit to system packages
  environment.systemPackages = with pkgs; [
    cudaPackages_12_2.cudatoolkit
  ];

  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    package = pkgs.linuxPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaPersistenced = true;
    prime.offload.enable = false;
    prime.offload.enableOffloadCmd = false;
    prime.sync.enable = true;
    prime.intelBusId = "PCI:0:2:0";
    prime.nvidiaBusId = "PCI:1:0:0";
  };

  # Enable Docker with NVIDIA support
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    extraOptions = "--experimental --default-runtime=nvidia";
  };

  # Set environment variables for CUDA
  environment.variables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    LD_LIBRARY_PATH = lib.mkForce "${pkgs.cudatoolkit.lib}/lib:${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
  };
}