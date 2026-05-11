{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.hallucination-detector;

  # bitflight-devops/hallucination-detector — Stop-hook that audits the
  # assistant's last message for speculation language ("I think",
  # "probably", "because" without evidence, fake percentages,
  # completeness overclaims like "all files checked"). Blocks completion
  # until rewritten with cited evidence.
  #
  # Pair with no-hallucination (tracker-ledger pattern) for two-layer
  # output guard: this catches speculation language, no-hallucination
  # catches claim/evidence mismatches.
  #
  # To update: change `rev`, set `sha256 = lib.fakeSha256`, rebuild —
  # nix prints the correct hash in the error.
  src = pkgs.fetchFromGitHub {
    owner = "bitflight-devops";
    repo = "hallucination-detector";
    rev = "main";
    sha256 = "sha256-BrL7QFuDiZ71Wc/FhapNEJR6EwR75w0sNVyq2i6hGhQ=";
  };

  nodeBin = "${pkgs.nodejs_22}/bin/node";
in {
  options.modules.ai.hallucination-detector.enable = lib.mkEnableOption ''
    bitflight-devops/hallucination-detector Stop hook for Claude Code.
    Audits assistant output for speculation / ungrounded causality /
    pseudo-quantification / completeness overclaims and blocks the
    response until rewritten with cited evidence.
  '';

  config = lib.mkIf cfg.enable {
    programs.claude-code.settings.hooks = {
      SessionStart = [
        {
          matcher = "startup|resume|clear";
          hooks = [
            {
              type = "command";
              command = ''${nodeBin} "${src}/scripts/hallucination-framing-session-start.cjs"'';
              timeout = 5;
            }
          ];
        }
      ];
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = ''${nodeBin} "${src}/scripts/hallucination-audit-stop.cjs"'';
              timeout = 10;
            }
          ];
        }
      ];
      SubagentStop = [
        {
          hooks = [
            {
              type = "command";
              command = ''${nodeBin} "${src}/scripts/hallucination-audit-stop.cjs"'';
              timeout = 10;
            }
          ];
        }
      ];
    };
  };
}
