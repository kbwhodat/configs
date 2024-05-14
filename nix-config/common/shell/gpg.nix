{ config, pkgs, ... }:

let
inherit (pkgs.stdenv) isDarwin;

in
{

  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [
    {
      text = ''
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        mDMEZHbekxYJKwYBBAHaRw8BAQdAnOTNVsyuAhCd2CBPK+br0hlIFtt57C4kRuTJ
        BjOti5e0H2tpeWluZ2kgPGthdG9ieUBwcm90b25tYWlsLmNvbT6IkwQTFgoAOwIb
        AwULCQgHAgIiAgYVCgkICwIEFgIDAQIeBwIXgBYhBL5XGeyblDvEPpH/JLbPy/+d
        Q4ohBQJkdt75AAoJELbPy/+dQ4ohuKoBAI/cwcZT9NhyWRFFEDp3Qicemsx8Rr0E
        aoRr6YeSCeEFAP9gsBm+6ACKHWAbj+uB+sU9IQc9gTGrQRIu0n9lF5cLBLg4BGR2
        3pMSCisGAQQBl1UBBQEBB0CZANFWlAHW+YitvTZ5v+VM4yvrUarg5sc40qqQ8CHY
        QgMBCAeIfgQYFgoAJhYhBL5XGeyblDvEPpH/JLbPy/+dQ4ohBQJkdt6TAhsMBQkD
        wmcAAAoJELbPy/+dQ4ohRR0A/iSCqtBE0Ty0Eq7CTqj9cJCkUR+KSQ54WW6fiWUx
        P3k7AP47Hqj3tui0Z7NIp1jlC9nR8dbkaKD7lhKbsIqvMh3tDw==
        =WZSg
        -----END PGP PUBLIC KEY BLOCK-----
        '';
      trust = "ultimate";
    }
    ];
    settings = {
      use-agent = false;
    };
  };

  services.gpg-agent = {
    enable = 
      if !isDarwin then
        true
      else
        false;

    # enableSshSupport = true;
    # sshKeys = [ "BE5719EC9B943BC43E91FF24B6CFCBFF9D438A21" ];
    extraConfig = ''
      pinentry-program ${pkgs.pinentry-gtk2}/bin/pinentry
    '';
    # pinentryPackage = pkgs.pinentry-gtk2;
    enableBashIntegration = true;
    maxCacheTtl = 86400; 
  };

  # services.dbus.packages = [ pkgs.gcr ];
}
