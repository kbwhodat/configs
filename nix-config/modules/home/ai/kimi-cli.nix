{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.kimi-cli;
  inherit (pkgs.stdenv) isDarwin;
in {
  options.modules.ai.kimi-cli.enable =
    lib.mkEnableOption "Kimi Code CLI (MoonshotAI/kimi-cli) — ACP-capable agent";

  config = lib.mkIf cfg.enable {
    # On Darwin: install via Homebrew formula `kimi-cli' (added to
    # `homebrew.brews' in hosts/_shared/darwin-personal-system.nix —
    # bottled, no source build).
    # On Linux: fall back to `uv tool install kimi-cli' since there's
    # no equivalent system-package source there.
    home.activation.installKimiCli =
      lib.mkIf (!isDarwin)
        (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ ! -x "${config.home.homeDirectory}/.local/bin/kimi" ]; then
            echo "[installKimiCli] installing kimi-cli via uv tool…"
            if ! PATH="${pkgs.uv}/bin:$PATH" ${pkgs.uv}/bin/uv tool install --python 3.13 kimi-cli; then
              echo "[installKimiCli] WARNING: uv tool install failed — run manually: uv tool install --python 3.13 kimi-cli" >&2
            fi
          fi
        '');
  };
}
