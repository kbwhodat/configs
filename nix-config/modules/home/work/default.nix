{ config, pkgs, lib, ... }:
let cfg = config.modules.work; in {
  options.modules.work.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Work-specific packages (only enabled on mac-work)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      jfrog-cli openssl_legacy redis skopeo terraform act sshuttle openconnect
      postman tcptraceroute util-linux mongosh awscli2 undmg _7zz openstackclient
      wireshark libreoffice-bin slack jiratui python313Packages.uv
    ];
  };
}
