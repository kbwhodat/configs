{ config, lib, pkgs, ... }:
let
  cfg = config.modules.ai.no-hallucination;

  # AlethiaQuizForge/no-hallucination — 11 hooks + 4 skills that enforce
  # verification discipline via the tracker-ledger-guard pattern:
  # PostToolUse trackers silently log what the agent actually did,
  # Stop hooks cross-reference natural-language claims against that
  # ledger. Grounded in arxiv 2507.11473.
  #
  # To update: change `rev` to a newer commit, set `sha256 = lib.fakeSha256`,
  # rebuild — nix prints the correct hash in the error.
  src = pkgs.fetchFromGitHub {
    owner = "AlethiaQuizForge";
    repo = "no-hallucination";
    rev = "main";
    sha256 = "sha256-hXzjpizdMOvvctQr1OagIXBIcy64P3hC4gkFCTj2MUM=";
  };

  hookCmd = name: "bash ${src}/hooks/${name}";
in {
  options.modules.ai.no-hallucination.enable = lib.mkEnableOption ''
    AlethiaQuizForge/no-hallucination hook bundle for Claude Code.
    Installs PreToolUse / PostToolUse / Stop / Compact hooks that
    block hallucinated completion claims by reconciling them against
    a silent evidence ledger.
  '';

  config = lib.mkIf cfg.enable {
    # Shared ledger location — all guard hooks read/write here.
    home.sessionVariables.GUARD_HOOKS_DIR = "$HOME/.claude/guard-hooks";

    # Surface the skills (orient/ship/build/orient-full) as auto-loadable
    # Claude Code skills. Each skill dir contains its own SKILL.md.
    home.file = {
      ".claude/skills/no-hallucination-orient".source = "${src}/skills/orient";
      ".claude/skills/no-hallucination-orient-full".source = "${src}/skills/orient-full";
      ".claude/skills/no-hallucination-ship".source = "${src}/skills/ship";
      ".claude/skills/no-hallucination-build".source = "${src}/skills/build";
    };

    programs.claude-code.settings.hooks = {
      PreToolUse = [
        {
          matcher = "Write|Edit";
          hooks = [ { type = "command"; command = hookCmd "build-gate.sh"; } ];
        }
      ];
      PostToolUse = [
        {
          matcher = "Write|Edit";
          hooks = [
            { type = "command"; command = hookCmd "edit-timestamp.sh"; }
            { type = "command"; command = hookCmd "track-deliverable.sh"; }
          ];
        }
        {
          matcher = "Grep|Glob";
          hooks = [ { type = "command"; command = hookCmd "search-tracker.sh"; } ];
        }
        {
          matcher = "Bash";
          hooks = [
            { type = "command"; command = hookCmd "verify-tracker.sh"; }
            { type = "command"; command = hookCmd "search-tracker.sh"; }
          ];
        }
      ];
      Stop = [
        {
          hooks = [
            { type = "command"; command = hookCmd "verify-guard.sh"; }
            { type = "command"; command = hookCmd "proof-guard.sh"; }
            { type = "command"; command = hookCmd "claim-guard.sh"; }
            { type = "command"; command = hookCmd "deliverable-guard.sh"; }
          ];
        }
      ];
      PreCompact = [
        {
          hooks = [ { type = "command"; command = hookCmd "pre-compact.sh"; } ];
        }
      ];
      PostCompact = [
        {
          hooks = [ { type = "command"; command = hookCmd "post-compact.sh"; } ];
        }
      ];
    };
  };
}
