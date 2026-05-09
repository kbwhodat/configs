{ config, lib, pkgs, inputs, ... }:
let cfg = config.modules.email.matcha; in {
  options.modules.email.matcha.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Matcha — terminal email client (https://github.com/floatpane/matcha)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.matcha.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
