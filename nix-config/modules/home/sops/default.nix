{ pkgs, inputs, config, lib, ... }:
let
  cfg = config.modules.sops;
  inherit (pkgs.stdenv) isDarwin;
in {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.modules.sops.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable sops-nix home-manager secret loading";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/etc/.secrets/keys.txt";

      secrets = {
        taskchamp-pass = { };
        pass-gpg = {
          path = "${config.home.homeDirectory}/.funentry";
        };
      };
    };

    home.activation.writeTaskrc = if isDarwin then "" else lib.mkForce (lib.hm.dag.entryAfter [ "writeBoundary" "installPackages" "linkGeneration" "onFilesChange" "setupLaunchAgents" "sops-nix" ] ''
      secret=$(cat ${config.sops.secrets.taskchamp-pass.path})
      mkdir -p "$HOME/.config/task"
      cat > "$HOME/.config/task/taskrc" <<EOF
# Taskwarrior config
sync.server.url=http://174.163.19.205:10222
sync.server.client_id=1578cf97-0993-47e3-badc-2dc56fb832e7
sync.encryption_secret=$secret
EOF
    '');
  };
}
