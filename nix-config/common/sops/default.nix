{ lib, inputs, config, pkgs, ... }:

let
inherit (pkgs.stdenv) isDarwin;
keysLocation = "/etc/.secrets";
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/etc/.secrets/keys.txt";

    secrets = {
      pass-gpg = {
        path = "${config.home.homeDirectory}/.funentry";
      };
    };
  };
}


