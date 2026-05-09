{ config, lib, ... }:
let cfg = config.modules.personal; in {
  options.modules.personal.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Personal packages (heavy python env, mpv, openvpn, etc.)";
  };

  imports = [
    ./personal.nix
    ./openvpn.nix
  ];
}
