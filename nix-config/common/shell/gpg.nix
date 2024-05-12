{ config, pkgs, ... }:

{

  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [ { source = ./keys/pass.pub; trust = 5; } ];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [ "BE5719EC9B943BC43E91FF24B6CFCBFF9D438A21" ];
    pinentryPackage = pkgs.pinentry-gtk2;
  };
}
