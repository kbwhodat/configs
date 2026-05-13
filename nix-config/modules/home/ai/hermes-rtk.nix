{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.hermes-rtk;
  configYaml = "${config.home.homeDirectory}/.hermes/config.yaml";
  pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
in {
  options.modules.ai.hermes-rtk.enable = lib.mkEnableOption ''
    rtk-hermes (ogallotti) — rewrites Hermes' shell commands through rtk
    for 60-90% LLM token savings on common dev commands (pytest, git, ls,
    grep, …). Requires the rtk binary (provided by modules.ai.rtk).

    Repo: https://github.com/ogallotti/rtk-hermes
  '';

  config = lib.mkIf (cfg.enable && config.modules.ai.hermes.enable) {
    modules.ai.hermes.extraPackages = [ "rtk-hermes" ];

    # rtk-hermes registers a Python entry point, but `hermes plugins enable`
    # is unreliable for entry-point-only plugins per the upstream README,
    # so we patch ~/.hermes/config.yaml directly. Idempotent: only adds
    # rtk-rewrite to plugins.enabled if it isn't already there.
    home.activation.hermesRtkConfig = lib.hm.dag.entryAfter [ "installHermes" ] ''
      CONFIG=${lib.escapeShellArg configYaml}
      if [ ! -f "$CONFIG" ]; then
        echo "[hermesRtkConfig] $CONFIG does not exist yet — run hermes once, then re-activate."
        exit 0
      fi
      ${pythonWithYaml}/bin/python - "$CONFIG" <<'PY'
import sys, pathlib, yaml
p = pathlib.Path(sys.argv[1])
data = yaml.safe_load(p.read_text()) or {}
plugins = data.setdefault("plugins", {})
enabled = plugins.setdefault("enabled", [])
if "rtk-rewrite" not in enabled:
    enabled.append("rtk-rewrite")
    p.write_text(yaml.safe_dump(data, sort_keys=False))
    print(f"[hermesRtkConfig] added rtk-rewrite to {p}")
else:
    print(f"[hermesRtkConfig] rtk-rewrite already present in {p}")
PY
    '';
  };
}
