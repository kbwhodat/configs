{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.hermes;
  sortedExtras = lib.sort lib.lessThan cfg.extraPackages;
  withArgs = lib.concatMapStringsSep " "
    (p: "--with ${lib.escapeShellArg p}") sortedExtras;
  expectedHash = builtins.hashString "sha256"
    (builtins.concatStringsSep "\n" sortedExtras);
  toolDir = "${config.home.homeDirectory}/.local/share/uv/tools/hermes-agent";
  sentinel = "${toolDir}/.nix-extras-hash";
  binPath = "${config.home.homeDirectory}/.local/bin/hermes";
in {
  options.modules.ai.hermes = {
    enable = lib.mkEnableOption ''
      Hermes Agent (Nous Research) — open-source autonomous AI agent with
      persistent memory, self-improving skills, multi-platform messaging
      gateway. Companion to Claude Code, not a replacement.

      Repo: https://github.com/NousResearch/hermes-agent
    '';

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "rtk-hermes" "git+https://github.com/owner/repo" ];
      description = ''
        Python package specs (as accepted by `uv tool install --with`) that
        will be installed into the same uv-tool venv as hermes-agent. Used
        to add Hermes plugins discovered via Python entry points
        (rtk-hermes, hermes-weather-plugin, …). Plugin modules append here.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Hermes Agent isn't on PyPI. Upstream's recommended install is a
    # curl-into-bash one-liner; we install the same project via `uv tool
    # install` against the git repo so we still get an isolated venv at
    # ~/.local/share/uv/tools/hermes-agent/ with a shim at
    # ~/.local/bin/hermes. Plugins are injected with `--with` so they
    # share the same venv (Python entry-point autodiscovery requires it).
    # Re-installs only when the extras list changes (hash sentinel).
    # Pin to Python 3.13: several of hermes-weather-plugin's transitive
    # Rust extensions (rusbie, rustplots, …) use pyo3 0.23.x, which only
    # supports up to Python 3.13. uv defaults to 3.14 otherwise.
    # PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1 is a safety belt if a
    # transitive bumps Python past 3.13 before pyo3 catches up.
    home.activation.installHermes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      EXPECTED=${lib.escapeShellArg expectedHash}
      SENTINEL=${lib.escapeShellArg sentinel}
      BIN=${lib.escapeShellArg binPath}
      CURRENT="$(cat "$SENTINEL" 2>/dev/null || echo none)"
      if [ ! -x "$BIN" ] || [ "$CURRENT" != "$EXPECTED" ]; then
        echo "[installHermes] installing hermes-agent + ${toString (lib.length sortedExtras)} plugin pkg(s) via uv tool ..."
        if PATH="${pkgs.uv}/bin:${pkgs.git}/bin:$PATH" \
           PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1 \
           ${pkgs.uv}/bin/uv tool install --reinstall --python 3.13 ${withArgs} \
           "git+https://github.com/NousResearch/hermes-agent"; then
          mkdir -p "$(dirname "$SENTINEL")"
          echo "$EXPECTED" > "$SENTINEL"
        else
          echo "[installHermes] WARNING: uv tool install failed - install manually:" >&2
          echo "  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash" >&2
        fi
      fi
    '';
  };
}
