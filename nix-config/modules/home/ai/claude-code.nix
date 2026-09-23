{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.claude-code;
  unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };

  # --- claude-code version pin (surgical) ----------------------------
  # nixpkgs-unstable pins claude-code, but bumping the whole `unstable`
  # input would also move emacs 31 + everything else we've stabilized.
  # Instead override just the prebuilt-binary `src` to a newer release.
  # Upstream ships one native binary per platform under
  #   https://downloads.claude.ai/claude-code-releases/<ver>/<key>/claude
  # with checksums in that version's manifest.json (fetch to update):
  #   curl -s .../<ver>/manifest.json
  # Bump = new version string + the four hex sha256s from that manifest.
  # NOTE: this pin is why `nix flake update` never moves claude-code —
  # the version is hardcoded here, not taken from the `unstable` input.
  # Bumping requires editing the two bindings below.
  claudeCodeVersion = "2.1.280";  # 2026-09-22 (npm `latest`); min version for Opus 5.5
  claudeCodeChecksums = {
    "darwin-arm64" = "387a5c5dcdbb815085edf0baf79591f9d8894efe922bceaf3d75b1b08055229d";
    "darwin-x64"   = "c1d32d87630482250633208ab77855429b24010ae3086a7ff7539b57b93168d4";
    "linux-arm64"  = "92f2b4fd05d0bdcf7b9a0d4e0ecef4a1e4b368b290cd8fd07cff9a50013f45a2";
    "linux-x64"    = "1e08503dbdf3c2cb0d706d32f3408277388d1c76ef108673e8fe42c1b322925b";
  };
  platformKey = "${pkgs.stdenv.hostPlatform.node.platform}-${pkgs.stdenv.hostPlatform.node.arch}";
  claudeCodePinned = unstable.claude-code.overrideAttrs (_: {
    version = claudeCodeVersion;
    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${claudeCodeVersion}/${platformKey}/claude";
      sha256 = claudeCodeChecksums.${platformKey};
    };
  });

  claudeHookPath = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";

  # Plugin/skill source trees come from flake inputs (see flake.nix).
  # `flake.lock` pins them, so a push to upstream `main` no longer
  # invalidates a hard-coded sha256 here. Bump deliberately via
  # `nix flake update --update-input <name>`.
  eccSrc              = inputs.everything-claude-code;
  wshobsonAgentsSrc   = inputs.wshobson-agents;
  # Matt Pocock's skill collection — surfaced as a symlinked dir
  # under ~/.claude/skills/mattpocock so Claude Code can pick them up.
  mattpocockSkillsSrc = inputs.mattpocock-skills;
  # obra/superpowers — we only want the `systematic-debugging` skill,
  # not the whole plugin. Symlinked as a single user skill.
  superpowersSrc      = inputs.superpowers;
  # luchasarie/bro-skill — `/bro` re-explains the last reply plainly.
  broSkillSrc         = inputs.bro-skill;
in {
  options.modules.ai.claude-code.enable = lib.mkEnableOption "Claude Code with ECC";

  config = lib.mkIf cfg.enable {
    # Global ~/.claude/CLAUDE.md — auto-loaded at every Claude Code
    # session start. Behavior + preferences, not project facts.
    home.file.".claude/CLAUDE.md".text = ''
# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
    '';

    # Claude Code rewrites this file at runtime, replacing the store symlink.
    # Without force, every rebuild fails because the .backup already exists.
    home.file.".claude/plugins/known_marketplaces.json".force = true;

    programs.claude-code = {
      enable = true;
      package = claudeCodePinned;
      # All MCPs except `jobdrop` are shipped by the `claude-code-home-manager`
      # plugin under its own namespace (mcp__plugin_claude-code-home-manager_*).
      # User-level entries here were duplicate dead code (not loaded into
      # ~/.claude.json anyway). Only `jobdrop` is unique to this machine
      # (installed via uv-tool to ~/.local/bin/).
      marketplaces = {
        ecc = eccSrc;
        wshobson-agents = wshobsonAgentsSrc;
      };
      plugins = [
        eccSrc
        "${wshobsonAgentsSrc}/plugins/quantitative-trading"
      ];
      mcpServers = {
        jobdrop = { command = "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server"; };
      };
      settings = {
        # Default model for new sessions. settings.json is a read-only
        # store symlink, so /model "save as default" can never persist —
        # this is the only place it sticks.
        # "opus" is an ALIAS resolving to the latest Opus tier (currently
        # Opus 5.5, `claude-opus-5-5`) — more robust than a dated ID and
        # tracks forward on server-side model releases. Note the CLI still
        # gates which models it will offer, so a new tier also needs the
        # version pin above bumped (Opus 5.5 requires >= 2.1.280).
        model = "opus";
        # Don't silently switch models when a safety classifier flags a
        # message — surface it instead. Key extracted from the CLI binary
        # (v2.1.177): ic("switchModelsOnFlag", true); undocumented in the
        # public settings reference as of Jul 2026.
        switchModelsOnFlag = false;

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
        # Claude Code's shell tool is named "Bash" regardless of the
        # user's actual shell — "Zsh(...)" rules match no tool and just
        # emit "matches no known tool" warnings on every invocation.
        permissions = {
          allow = [ "WebFetch" "Read" "Grep" "Bash" ];
          deny = [ "Bash(sudo*)" ];
          # ask = [
          #   "Bash(rm*)" "Bash(rmdir*)" "Bash(unlink*)" "Bash(mv*)"
          # ];
        };
      };
    };

    # Surface mattpocock/skills under ~/.claude/skills/mattpocock.
    # Out-of-store symlink: upstream updates after a flake-input bump
    # appear without a full home-manager activation re-run.
    home.file.".claude/skills/mattpocock" = {
      source = config.lib.file.mkOutOfStoreSymlink "${mattpocockSkillsSrc}/skills";
    };

    # Just the `systematic-debugging` skill from obra/superpowers — not
    # the rest of the plugin's skills/commands/hooks.
    home.file.".claude/skills/systematic-debugging" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${superpowersSrc}/skills/systematic-debugging";
    };

    home.file.".claude/skills/bro/SKILL.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${broSkillSrc}/SKILL.md";
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
