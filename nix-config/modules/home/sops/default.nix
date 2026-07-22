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
      # Age key provisioned MANUALLY once per machine (sops-nix's
      # standard location) — previously delivered by an eval-time
      # `builtins.fetchGit` of the private pass-keys repo, which broke
      # CI eval (no credentials on runners) and put key material in the
      # world-readable nix store.  Migration on hosts that had it:
      #   mkdir -p ~/.config/sops/age && cp /etc/.secrets/keys.txt ~/.config/sops/age/keys.txt
      # (run BEFORE the rebuild that removes /etc/.secrets)
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

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
