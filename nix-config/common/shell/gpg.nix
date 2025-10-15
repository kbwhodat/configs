{ config, pkgs, lib, ... }:

let
inherit (pkgs.stdenv) isDarwin;
keysLocation = "/etc/.secrets";
in
{
  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [
    {
      text = ''
      -----BEGIN PGP PUBLIC KEY BLOCK-----

      mDMEaO1rLhYJKwYBBAHaRw8BAQdA7CKocUYhZdCH1ALT3UOMGGH5bJezkFIxHX/7
      uAU5i460L2thdG8gKGZvciBtdXR0IHdpemFyZCkgPGRuc19pc3N1ZUB0dXRhbWFp
      bC5jb20+iI4EExYKADYWIQQG32rUW8qKENeZfNwiYXkmCeXQlQUCaO1rLgIbAwQL
      CQgHBBUKCQgFFgIDAQACHgECF4AACgkQImF5Jgnl0JWkqQEAo3UDVoYMxG0MANsz
      4L0HYwsa/7HhIMkMZ+89t6iJHOUA/jsR/PrWNPeJyI4PdzpVMaXZDpASNxofSIxP
      g7h6s8YJuDgEaO1rLhIKKwYBBAGXVQEFAQEHQE4psI6gF7EKWpZ2vMqR1UeaUgO0
      aMSlIcYzMgYelhB0AwEIB4h4BBgWCgAgFiEEBt9q1FvKihDXmXzcImF5Jgnl0JUF
      Amjtay4CGwwACgkQImF5Jgnl0JXQxAEA4ei8Pmyg+dRzKdfadXYwwJckUSl5gCJU
      rU/gcNE3eRABAPeVuQsHj/oVbvRP4yzAIfBV+l0ufOZecUtJHTFsiY8O
      =nbJH
      -----END PGP PUBLIC KEY BLOCK-----
        '';
      trust = "ultimate";
    }
    ];
    settings = {
      no-greeting = true;
      use-agent = true;
    };
  };

  services.gpg-agent = {
    enable =
      if isDarwin then
        false
      else
        true;
    pinentryPackage = pkgs.pinentry-gtk2;
    enableExtraSocket = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    maxCacheTtl = 86400; 
    extraConfig = ''
      allow-loopback-pinentry
      '';
  };

  # home.activation.importGpgKeys = lib.mkForce (lib.hm.dag.entryAfter [ "writeBoundary" "installPackages" "linkGeneration" "onFilesChange" "setupLaunchAgents" "sops-nix" ] ''
  #
  #     run sleep 1
  #     run cat ${config.home.homeDirectory}/.funentry | ${pkgs.gnupg}/bin/gpg --import ${keysLocation}/subkey
  #     run rm ${config.home.homeDirectory}/.funentry
  #   '');


}
