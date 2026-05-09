{ config, pkgs, lib, ... }:
let cfg = config.modules.gaming; in {
  options.modules.gaming.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Gaming packages (runescape clients, etc.)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      runelite
      hdos
    ];
  };
}
