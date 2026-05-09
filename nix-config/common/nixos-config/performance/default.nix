# Migration shim. Real config in modules/system/nixos-config/performance/.
{ ... }: { imports = [ ../../../modules/system/nixos-config/performance ]; }
