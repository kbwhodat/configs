# Migration shim. Real config in modules/system/nvidia/cuda/cuda.nix.
{ ... }: { imports = [ ../../../modules/system/nvidia/cuda/cuda.nix ]; }
