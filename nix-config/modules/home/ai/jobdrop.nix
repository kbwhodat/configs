{ config, lib, pkgs, ... }:
let cfg = config.modules.ai.jobdrop; in {
  options.modules.ai.jobdrop.enable = lib.mkEnableOption "jobdrop MCP server";

  config = lib.mkIf cfg.enable {
    home.activation.installJobdrop = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server" ]; then
        echo "[installJobdrop] installing jobdrop[mcp] via uv tool…"
        if ! PATH="${pkgs.uv}/bin:$PATH" ${pkgs.uv}/bin/uv tool install "jobdrop[mcp]"; then
          echo "[installJobdrop] WARNING: uv tool install failed — run manually: uv tool install 'jobdrop[mcp]'" >&2
        fi
      fi
    '';
  };
}
