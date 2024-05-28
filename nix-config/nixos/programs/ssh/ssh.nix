{ config, pkgs, ... }
:{
  programs.ssh.forwardX11 = true;
  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";
}

