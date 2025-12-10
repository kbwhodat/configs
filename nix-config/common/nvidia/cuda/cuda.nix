{ config, pkgs, lib, ... }:

{

  # Enable CUDA support
  nixpkgs.config.cudaSupport = if config.networking.hostName == "nixos-server" then true else false;

  # nix.settings.substituters = [
  #   "https://cuda-maintainers.cachix.org"
  # ];
  #
  # nix.settings.trusted-public-keys = [
  #   "cuda-maintainers.cachix.org-1:dq3ujKPMCXU4ylr9JUG0pVa7CNfq5E="
  # ];

  # Add CUDA toolkit to system packages
  # it's only needed if I want to develop and utilize the cuda compilier and create cuda applications
  # environment.systemPackages = with pkgs; [
  #   cudaPackages_12_2.cudatoolkit
  # ];

  # Enable NVIDIA drivers
  # services.xserver.videoDrivers = [ "nvidia" ];

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
    prime.allowExternalGpu = true;
  };

  # Enable Docker with NVIDIA support
  virtualisation.docker = {
    enable = true;
    enableNvidia = false;
    rootless.enable = true;
    # extraOptions = "--experimental --default-runtime=nvidia";
  };

  # Set environment variables for CUDA
  environment.variables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    # LD_LIBRARY_PATH = lib.mkForce (lib.optionalString (builtins.getEnv "LD_LIBRARY_PATH" != "") (builtins.getEnv "LD_LIBRARY_PATH" + ":") + lib.makeLibraryPath [
    #     "${pkgs.cudatoolkit.lib}"
    #     "${pkgs.linuxPackages.nvidia_x11}"
    # ]);
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
  };
}
