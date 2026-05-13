{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.hermes-execplan;
  src = pkgs.fetchFromGitHub {
    owner = "tiann";
    repo = "execplan-skill";
    rev = "b4e511759b27a398f9f30c602e49c7676c2273ab";
    sha256 = "sha256-7RNwUNjFXkj7ffo9at/3xZmyz8j0l6vBs+uZP338na8=";
  };
  dest = "${config.home.homeDirectory}/.hermes/skills/execplan";
in {
  options.modules.ai.hermes-execplan.enable = lib.mkEnableOption ''
    execplan-skill (tiann) — long-running autonomous implementation
    workflow with plan-first, checkpoint-based, testable milestones and
    rollback. Drop-in skill at ~/.hermes/skills/execplan/.

    Repo: https://github.com/tiann/execplan-skill
  '';

  config = lib.mkIf (cfg.enable && config.modules.ai.hermes.enable) {
    home.activation.hermesExecplanSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DEST=${lib.escapeShellArg dest}
      SRC=${lib.escapeShellArg "${src}"}
      mkdir -p "$(dirname "$DEST")"
      if [ ! -d "$DEST" ] || [ "$(readlink "$DEST/.nix-src" 2>/dev/null)" != "$SRC" ]; then
        rm -rf "$DEST"
        cp -r "$SRC" "$DEST"
        chmod -R u+w "$DEST"
        ln -sfn "$SRC" "$DEST/.nix-src"
        echo "[hermesExecplanSkill] installed execplan skill to $DEST"
      fi
    '';
  };
}
