{ config, pkgs, lib, ... }:
let cfg = config.modules.keyboard; in {
  options.modules.keyboard.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable user-level keyboard packages";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # currently empty — placeholder for user keyboard tooling
    ];
  };
}
