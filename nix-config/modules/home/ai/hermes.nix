{ config, lib, pkgs, ... }:
let cfg = config.modules.ai.hermes; in {
  options.modules.ai.hermes.enable = lib.mkEnableOption ''
    Hermes Agent (Nous Research) — open-source autonomous AI agent with
    persistent memory, self-improving skills, multi-platform messaging
    gateway. Companion to Claude Code, not a replacement.

    Repo: https://github.com/NousResearch/hermes-agent
  '';

  config = lib.mkIf cfg.enable {
    # Hermes Agent ships on PyPI; same uv-tool pattern as jobdrop. The
    # binary lands at ~/.local/bin/hermes. Heavy deps (browser automation,
    # gateway adapters) live in an isolated venv outside the nix store.
    # To upgrade: `uv tool upgrade hermes-agent`.
    home.activation.installHermes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "${config.home.homeDirectory}/.local/bin/hermes" ]; then
        echo "[installHermes] installing hermes-agent via uv tool…"
        if ! PATH="${pkgs.uv}/bin:$PATH" ${pkgs.uv}/bin/uv tool install hermes-agent; then
          echo "[installHermes] WARNING: uv tool install failed — run manually: uv tool install hermes-agent" >&2
        fi
      fi
    '';
  };
}
