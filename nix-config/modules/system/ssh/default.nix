{ config, pkgs, lib, ... }:
let cfg = config.modules.ssh; in {
  options.modules.ssh.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable OpenSSH server with hardened defaults";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh.forwardX11 = true;
    services.openssh.enable = true;
    services.openssh.settings.X11Forwarding = true;
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.PermitRootLogin = "no";
  };
}
