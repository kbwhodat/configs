{ config, pkgs, ... }:

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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
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
    LD_LIBRARY_PATH = "${pkgs.cudatoolkit.lib}/lib:${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
  };
}
