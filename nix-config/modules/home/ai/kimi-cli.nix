{ config, lib, pkgs, ... }:
let cfg = config.modules.ai.kimi-cli; in {
  options.modules.ai.kimi-cli.enable =
    lib.mkEnableOption "Kimi Code CLI (MoonshotAI) — ACP-capable agent";

  config = lib.mkIf cfg.enable {
    # Nix-store binary built from the published npm tarball — see
    # pkgs/by-name/kimi-code/.  Replaces the previous split install
    # (Homebrew on darwin / `uv tool install kimi-cli' on linux): brew
    # deprecated the `kimi-cli' formula, and the PyPI package it wrapped
    # is the superseded Python CLI.
    #
    # Provides `kimi', which emacs `agent-shell' launches as `kimi acp'.
    # No bridge package needed — kimi speaks ACP natively, unlike Claude
    # Code (which needs pkgs.claude-agent-acp).
    home.packages = [ pkgs.kimi-code ];

    # Default model = K3.  ~/.kimi-code/config.toml is OWNED BY KIMI
    # (the oauth login flow generates it; `kimi provider' syncs rewrite
    # it), so nix must NOT symlink it — instead pin the single line we
    # care about on each activation.  No-op until `kimi login' has
    # created the file, and idempotent after.
    home.activation.kimiDefaultModel =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        kimiCfg="${config.home.homeDirectory}/.kimi-code/config.toml"
        if [ -f "$kimiCfg" ] && ! ${pkgs.gnugrep}/bin/grep -q '^default_model = "kimi-code/k3"$' "$kimiCfg"; then
          ${pkgs.gnused}/bin/sed -i 's|^default_model = .*|default_model = "kimi-code/k3"|' "$kimiCfg"
          echo "[kimiDefaultModel] set default_model = kimi-code/k3"
        fi
      '';
  };
}
