{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.claude-code;
  unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
  claudeHookPath = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";

  # Plugin/skill source trees come from flake inputs (see flake.nix).
  # `flake.lock` pins them, so a push to upstream `main` no longer
  # invalidates a hard-coded sha256 here. Bump deliberately via
  # `nix flake update --update-input <name>`.
  eccSrc              = inputs.everything-claude-code;
  superpowersSrc      = inputs.superpowers;
  wshobsonAgentsSrc   = inputs.wshobson-agents;
  # Matt Pocock's skill collection — surfaced as a symlinked dir
  # under ~/.claude/skills/mattpocock so Claude Code (and our gptel
  # `M-x my/gptel-load-skill') can pick them up.
  mattpocockSkillsSrc = inputs.mattpocock-skills;
in {
  options.modules.ai.claude-code.enable = lib.mkEnableOption "Claude Code with ECC + superpowers";

  config = lib.mkIf cfg.enable {
    # Global ~/.claude/CLAUDE.md — auto-loaded at every Claude Code
    # session start. Behavior + preferences, not project facts.
    home.file.".claude/CLAUDE.md".text = ''
      # Global Claude Preferences

      ## Hard rules (non-negotiable)

      - **No fabrication.** Never generate synthetic data, mock APIs, fake test results, or placeholder values that look real. If real data is unavailable, say so. If you must create example data, label it `EXAMPLE` / `SYNTHETIC` in every file and every reference.
      - **No "should work" claims.** Don't say a fix is done, tests pass, or a build works unless you ran it AND showed the output. "Probably", "should", "I think" require evidence.
      - **"I don't know" is acceptable.** When uncertain, say so. Never invent a function name, CLI flag, file path, or library that you haven't verified.
      - **MUST search before guessing.** For any factual question that can be verified — library API, current version, deprecation, recent event, comparative claim — you MUST query WebSearch / Context7 / `web_search_exa` BEFORE answering. NEVER answer from training memory for time-sensitive or version-specific facts. See "When uncertain" below.
      - **Quote my instruction verbatim** when you're about to do something non-trivial. (You have a gateguard hook that enforces this — work with it, not around it.)
      - **Match existing conventions.** Find the nearest sibling file and copy its pattern before inventing something new.

      ## Communication

      - Terse. No preamble. No "Great question!", "Certainly!", "Of course!".
      - Skip explanations of what you did — I read diffs.
      - One-sentence acknowledgement, then the work. End-of-turn = 1-2 sentence summary, what changed and what's next.
      - When asked a yes/no, answer yes/no first.
      - Don't restate my question back to me.

      ## Verification before completion

      - After non-trivial code change: run the relevant test/typecheck/build and show output. If you can't run it, say so explicitly.
      - After config change: eval / show effective state.
      - Never report "fixed" without before/after evidence.
      - For UI/frontend: open it in a browser and use the feature. Type checks ≠ feature correctness.

      ## Anti-bullshit specifics

      - No sycophancy. No filler. No "I hope this helps". No "Let me know if".
      - Don't recommend from training memory without verifying it exists in the current environment.
      - For library/API recommendations: check that the version installed actually has the function/method you're citing.
      - Disagreement is fine. If I'm wrong, say so with evidence. Don't bend to my framing.

      ## When uncertain — search, don't guess

      **MUST** reach for tools in order (cheapest first) — not as a suggestion:

      1. **Repo state** — Grep / Read / `git log` for codebase facts. Always first.
      2. **Context7 MCP** — library/framework API questions ("does X support Y?", current signatures, version-specific behavior).
      3. **WebSearch + `web_search_exa`** — current events, recent versions, comparative questions, anything past your training cutoff.
      4. **WebFetch + `web_fetch_exa`** — full content of specific URLs you've identified.

      Triggers to search instead of answering:
      - Library version / capability / deprecation questions
      - Anything time-sensitive ("latest", "current", "as of YYYY")
      - When you catch yourself typing "I think", "probably", "should be" — that's the cue to search instead.

      After searching: cite the source (URL or `file:line`). If no source answers, say "I don't know" — don't synthesize.

      ## Code defaults

      - Minimal diffs. Don't refactor unrelated code.
      - No half-finished implementations, no TODOs left behind.
      - Don't add error handling, fallbacks, or validation for scenarios that can't happen.
      - No defensive try/except wrappers around internal calls. Validate at system boundaries only.
      - Default to writing no comments. WHY-comments only when the reason is non-obvious.
      - No backwards-compat shims for code that hasn't shipped.

      ## Investigation discipline

      Gateguard will enforce these before edits — pre-comply rather than fight it:

      - Before editing: list importers (Grep), list public functions affected.
      - Before creating new file: confirm no existing file serves the same purpose (Glob).
      - Before destructive bash: list affected files/data + a one-line rollback.

      ## Sessions / context

      - One goal per session. When scope shifts, start a new session.
      - For anything beyond a one-file change: `/superpowers:brainstorm` → `/superpowers:write-plan` → `/superpowers:execute-plan`. Plans live on disk, not in context.
      - Compact at phase boundaries, not when context is already full.
      - When you discover a recurring correction, write it to MEMORY.md so future sessions don't repeat it.

      ## Tooling on this machine (already installed)

      You operate inside a stack — use it, don't reinvent:

      - **superpowers** (obra) — brainstorming, write-plan, execute-plan, TDD, systematic-debugging, verification-before-completion. Use the slash commands.
      - **everything-claude-code** — gateguard (active), search-first, silent-failure-hunter, code-review, eval-harness.
      - **no-hallucination** (AlethiaQuizForge) — tracker-ledger-guard hooks active. verify-guard, proof-guard, claim-guard, deliverable-guard run on every Stop.

      ## Memory system

      When you save something for future sessions:

      - **user**: facts about me (role, preferences, knowledge)
      - **feedback**: corrections + the WHY behind them
      - **project**: ongoing work, decisions, deadlines
      - **reference**: external systems / URLs / dashboards

      Lead each entry with the rule/fact, then `Why:`, then `How to apply:`. No backstory.
    '';

    programs.claude-code = {
      enable = true;
      package = unstable.claude-code;
      # All MCPs except `jobdrop` are shipped by the `claude-code-home-manager`
      # plugin under its own namespace (mcp__plugin_claude-code-home-manager_*).
      # User-level entries here were duplicate dead code (not loaded into
      # ~/.claude.json anyway). Only `jobdrop` is unique to this machine
      # (installed via uv-tool to ~/.local/bin/).
      marketplaces = {
        ecc = eccSrc;
        superpowers = superpowersSrc;
        wshobson-agents = wshobsonAgentsSrc;
      };
      plugins = [
        eccSrc
        superpowersSrc
        "${wshobsonAgentsSrc}/plugins/quantitative-trading"
        "${wshobsonAgentsSrc}/plugins/python-development"
        "${wshobsonAgentsSrc}/plugins/data-engineering"
        "${wshobsonAgentsSrc}/plugins/machine-learning-ops"
      ];
      mcpServers = {
        jobdrop = { command = "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server"; disabled = true; };
      };
      settings = {
        # Disable specific MCP servers from any installed plugin's
        # `.mcp.json` without disabling the whole plugin. Heavy or
        # redundant servers disabled by default; re-enable per-session
        # via /mcp toggle.
        #   - github                                      (~28 tools, ~14K tokens — gh CLI is enough)
        #   - playwright                                  (~21 tools, ~10K tokens — only for UI/browser work)
        #   - sequential-thinking / sequential_thinking   (~1 tool — modern Claude thinks natively)
        #   - memory                                      (~9 tools, ~5K tokens — file-based memory in CLAUDE.md handles this)
        disabledMcpjsonServers = [
          "github"
          "playwright"
          "sequential-thinking"
          "sequential_thinking"
          "memory"
        ];

        hooks.PreToolUse = [
          {
            matcher = "Bash";
            hooks = [ { type = "command"; command = claudeHookPath; } ];
          }
        ];
        permissions = {
          allow = [ "WebFetch" "Read" "Grep" "Bash" "Zsh" ];
          deny = [ "Bash(sudo*)" "Zsh(sudo*)" ];
          ask = [
            "Bash(rm*)" "Bash(rmdir*)" "Bash(unlink*)" "Bash(mv*)"
            "Zsh(rm*)" "Zsh(rmdir*)" "Zsh(unlink*)" "Zsh(mv*)"
          ];
        };
      };
    };

    # Surface mattpocock/skills under ~/.claude/skills/mattpocock.
    # Out-of-store symlink: upstream updates after a flake-input bump
    # appear without a full home-manager activation re-run.
    home.file.".claude/skills/mattpocock" = {
      source = config.lib.file.mkOutOfStoreSymlink "${mattpocockSkillsSrc}/skills";
    };

    # Kill the slowness: ECC plugin runs 30+ hooks across PreToolUse,
    # PostToolUse and Stop events. `ECC_HOOK_PROFILE=minimal` skips
    # every hook whose declared profiles don't include "minimal" —
    # which is all the reminder/observe/governance/quality-gate ones.
    #
    # `ECC_DISABLED_HOOKS` is an explicit kill-list for IDs that are
    # tagged "minimal" but still annoying — currently both GateGuard
    # variants ("Fact-Forcing Gate" interruptions before edits/bash).
    #
    # `ECC_GATEGUARD=off` is the belt-and-suspenders fallback the
    # gate's own recovery message documents.
    home.sessionVariables = {
      ECC_HOOK_PROFILE = "minimal";
      ECC_DISABLED_HOOKS = "pre:edit-write:gateguard-fact-force,pre:bash:gateguard-fact-force";
      ECC_GATEGUARD = "off";
    };
  };
}
