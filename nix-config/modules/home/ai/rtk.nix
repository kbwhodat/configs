{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.rtk;
  unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
  opencodeDir = "${config.home.homeDirectory}/.config/opencode";
  claudeHookPath = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";
in {
  options.modules.ai.rtk.enable = lib.mkEnableOption "RTK CLI proxy + plugins";

  config = lib.mkIf cfg.enable {
    home.packages = [ unstable.rtk ];

    home.activation.installRtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "${opencodeDir}/plugins/rtk.ts" ]; then
        ${unstable.rtk}/bin/rtk init -g --opencode --auto-patch 2>/dev/null || true
      fi
    '';

    home.activation.installRtkClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "${claudeHookPath}" ]; then
        ${unstable.rtk}/bin/rtk init -g --hook-only --no-patch 2>/dev/null || true
      fi
    '';
  };
}
