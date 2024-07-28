{ inputs, config, ...}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    #inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/etc/.secrets/keys.txt";

    secrets = {
      #github-token = {
      #  path = "${config.home.homeDirectory}/.teacupp";
      #};
      pass-gpg = {
        path = "${config.home.homeDirectory}/.funentry";
      };
    };
  };
}


