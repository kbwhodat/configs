{ config, lib, pkgs, ... }:
let cfg = config.modules.linux; in {
  options.modules.linux.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Linux-only home tooling (i3, rofi, tradingview)";
  };

  imports = [
    ./i3
    ./rofi
    ./tradingview
  ];
}
