{ config, lib, pkgs, ... }:
let cfg = config.modules.ai.hermes; in {
  options.modules.ai.hermes.enable = lib.mkEnableOption ''
    Hermes Agent (Nous Research) — open-source autonomous AI agent with
    persistent memory, self-improving skills, multi-platform messaging
    gateway. Companion to Claude Code, not a replacement.

    Repo: https://github.com/NousResearch/hermes-agent
  '';

  config = lib.mkIf cfg.enable {
    # Hermes Agent isn't on PyPI. Upstream's recommended install is a
    # curl-into-bash one-liner; we install the same project via `uv tool
    # install` against the git repo so we still get an isolated venv at
    # ~/.local/share/uv/tools/hermes-agent/ with a shim at
    # ~/.local/bin/hermes. Same pattern as jobdrop.
    # To upgrade: `uv tool upgrade hermes-agent`
    # (or reinstall: `uv tool install --reinstall git+https://github.com/NousResearch/hermes-agent`).
    home.activation.installHermes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "${config.home.homeDirectory}/.local/bin/hermes" ]; then
        echo "[installHermes] installing hermes-agent via uv tool (git source)…"
        if ! PATH="${pkgs.uv}/bin:$PATH" ${pkgs.uv}/bin/uv tool install \
            "git+https://github.com/NousResearch/hermes-agent"; then
          echo "[installHermes] WARNING: uv tool install failed — install manually:" >&2
          echo "  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash" >&2
        fi
      fi
    '';
  };
}
