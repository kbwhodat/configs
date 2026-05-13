{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.hermes-profiles;
  pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
  profilesDir = "${config.home.homeDirectory}/.hermes/profiles";
  dirsJson = builtins.toJSON cfg.externalSkillDirs;
in {
  options.modules.ai.hermes-profiles = {
    enable = lib.mkEnableOption ''
      Per-profile config invariants for hermes. Walks
      ~/.hermes/profiles/*/config.yaml on every activation and ensures
      each profile's skills.external_dirs contains the configured
      directories, so globally-installed skills (execplan, etc.) are
      visible inside every profile (wxny-builder, wxny-verifier, ...).
    '';

    externalSkillDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "${config.home.homeDirectory}/.hermes/skills" ];
      example = [ "$HOME/.hermes/skills" "$HOME/src/team-skills" ];
      description = ''
        Absolute paths to merge into each profile's
        skills.external_dirs list. Hermes will load any SKILL.md it
        finds under these directories for every profile that has them
        in its config.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && config.modules.ai.hermes.enable) {
    home.activation.hermesProfilesExternalDirs =
      lib.hm.dag.entryAfter [ "installHermes" "hermesExecplanSkill" ] ''
        PROFILES=${lib.escapeShellArg profilesDir}
        if [ ! -d "$PROFILES" ]; then
          echo "[hermesProfilesExternalDirs] $PROFILES does not exist yet - no profiles to update."
          exit 0
        fi
        ${pythonWithYaml}/bin/python - "$PROFILES" ${lib.escapeShellArg dirsJson} <<'PY'
import sys, json, pathlib, yaml
profiles_dir = pathlib.Path(sys.argv[1])
desired = json.loads(sys.argv[2])
changed = 0
for cfg_path in sorted(profiles_dir.glob("*/config.yaml")):
    data = yaml.safe_load(cfg_path.read_text()) or {}
    sk = data.setdefault("skills", {})
    ed = sk.setdefault("external_dirs", [])
    added = [d for d in desired if d not in ed]
    if not added:
        continue
    ed.extend(added)
    cfg_path.write_text(yaml.safe_dump(data, sort_keys=False))
    print(f"[hermesProfilesExternalDirs] {cfg_path.parent.name}: added {added}")
    changed += 1
if changed == 0:
    print("[hermesProfilesExternalDirs] all profiles already current")
PY
      '';
  };
}
