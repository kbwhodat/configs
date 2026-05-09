{ config, pkgs, lib, ... }:
let
  cfg = config.modules.vms;
  inherit (pkgs.stdenv) isDarwin;
in {
  options.modules.vms.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "VM management tooling (virt-manager on Linux)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (if isDarwin then
        pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
       else
        virt-manager)
    ];
  };
}
