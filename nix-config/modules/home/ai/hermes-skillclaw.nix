{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.hermes-skillclaw;
  src = pkgs.fetchFromGitHub {
    owner = "AMAP-ML";
    repo = "SkillClaw";
    rev = "03f7bb436ffda8ef6bad2560921e8a3ec5f54701";
    sha256 = "sha256-wtyw0wu5uDTr5x6DfMWDR6BMtYGyE79+b/Rw+soD2lI=";
  };
  dest = "${config.home.homeDirectory}/.local/share/skillclaw";
in {
  options.modules.ai.hermes-skillclaw.enable = lib.mkEnableOption ''
    SkillClaw (AMAP-ML) — agentic skill evolution daemon that
    deduplicates, improves, and cross-pollinates skills across sessions,
    agents, and devices. After install, run manually once:
      ~/.local/share/skillclaw/.venv/bin/skillclaw setup   # choose "hermes"
      ~/.local/share/skillclaw/.venv/bin/skillclaw start --daemon

    Repo: https://github.com/AMAP-ML/SkillClaw
  '';

  config = lib.mkIf (cfg.enable && config.modules.ai.hermes.enable) {
    home.activation.installSkillClaw = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DEST=${lib.escapeShellArg dest}
      SRC=${lib.escapeShellArg "${src}"}
      if [ ! -x "$DEST/.venv/bin/skillclaw" ]; then
        echo "[installSkillClaw] installing skillclaw to $DEST ..."
        rm -rf "$DEST"
        mkdir -p "$(dirname "$DEST")"
        cp -r "$SRC" "$DEST"
        chmod -R u+w "$DEST"
        if ! ( cd "$DEST" && PATH="${pkgs.python3}/bin:${pkgs.git}/bin:$PATH" \
               bash scripts/install_skillclaw.sh ); then
          echo "[installSkillClaw] WARNING: install_skillclaw.sh failed — run manually from $DEST" >&2
          exit 0
        fi
        echo "[installSkillClaw] done. Next: $DEST/.venv/bin/skillclaw setup  (choose hermes), then 'skillclaw start --daemon'."
      fi
    '';
  };
}
