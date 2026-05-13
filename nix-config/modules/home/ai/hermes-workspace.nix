{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.hermes-workspace;
  src = pkgs.fetchFromGitHub {
    owner = "outsourc-e";
    repo = "hermes-workspace";
    rev = "372b18a8e4e3fa7947ff3cf5651865560daca0a1";
    sha256 = "sha256-heOtoz637s4ifWVUDMQzgRSou6p8b5AT7kaTLxYWQCo=";
  };
  dest = "${config.home.homeDirectory}/.local/share/hermes-workspace";
in {
  options.modules.ai.hermes-workspace.enable = lib.mkEnableOption ''
    Hermes Workspace (outsourc-e) — native web workspace GUI for Hermes
    Agent: chat, terminal, memory browser, skills, MCP, dashboard.
    Runs on localhost ports 3000 (workspace), 8642 (gateway),
    9119 (dashboard). After install, launch manually:
      hermes gateway run                            # terminal 1
      hermes dashboard                              # terminal 2
      cd ~/.local/share/hermes-workspace && pnpm dev   # terminal 3

    Repo: https://github.com/outsourc-e/hermes-workspace
  '';

  config = lib.mkIf (cfg.enable && config.modules.ai.hermes.enable) {
    home.packages = [ pkgs.nodejs_22 pkgs.pnpm ];

    home.activation.installHermesWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DEST=${lib.escapeShellArg dest}
      SRC=${lib.escapeShellArg "${src}"}
      if [ ! -d "$DEST/node_modules" ]; then
        echo "[installHermesWorkspace] installing hermes-workspace to $DEST ..."
        rm -rf "$DEST"
        mkdir -p "$(dirname "$DEST")"
        cp -r "$SRC" "$DEST"
        chmod -R u+w "$DEST"
        [ -f "$DEST/.env" ] || [ ! -f "$DEST/.env.example" ] || cp "$DEST/.env.example" "$DEST/.env"
        if ! ( cd "$DEST" && PATH="${pkgs.nodejs_22}/bin:${pkgs.pnpm}/bin:$PATH" pnpm install ); then
          echo "[installHermesWorkspace] WARNING: pnpm install failed — run manually from $DEST" >&2
          exit 0
        fi
        echo "[installHermesWorkspace] done. Launch with: cd $DEST && pnpm dev"
      fi
    '';
  };
}
