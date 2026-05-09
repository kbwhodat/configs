# Migration shim. Real config in modules/system/nixos-config/.
{ ... }: { imports = [ ../../modules/system/nixos-config ]; }
