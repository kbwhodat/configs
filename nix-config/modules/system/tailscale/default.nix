{ config, pkgs, lib, ... }:
let cfg = config.modules.tailscale; in {
  options.modules.tailscale.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Tailscale mesh VPN daemon";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    environment.systemPackages = [ pkgs.tailscale ];
  };
}
