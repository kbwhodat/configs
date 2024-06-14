{ inputs, config, pkgs, ... }:

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
        path = "/Users/katob";
      };
    };
  };

}
