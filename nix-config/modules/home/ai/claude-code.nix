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
  claudeCodeVersion = "2.1.310";  # 2026-10-23 (npm `latest`); offers Sonnet 5.5 / Haiku 5.5
  claudeCodeChecksums = {
    "darwin-arm64" = "ffb64331bc0ee1b69efb7c2c428bd3ab516bc31b75bf60886b356c97c1c25ffd";
    "darwin-x64"   = "28fdbed5a84ef7d4205b5751c7f021e79151c4e319c4a401e48fe6aae86bbb39";
    "linux-arm64"  = "9c64d9a7442436b65fcd7cc02c1aa0051bb5a7041e7788576ed3b5f29c447d54";
    "linux-x64"    = "b73676430af12f97316a798b8371f81d640f90a58bdcb8f3ce56a835bb47df56";
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
  # luchasarie/bro-skill — `/bro` re-explains the last reply plainly.
  broSkillSrc         = inputs.bro-skill;
  # anthropics/claude-plugins-official — Anthropic's marketplace; we take
  # `frontend-design` (distinctive, production-grade UI; avoids the generic
  # AI look). Skills are inherited by subagents, so lab-site builders get it.
  officialPluginsSrc  = inputs.claude-plugins-official;
in {
  options.modules.ai.claude-code.enable = lib.mkEnableOption "Claude Code (declarative plugins, skills and settings)";

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
        claude-plugins-official = officialPluginsSrc;
      };
      plugins = [
        "${officialPluginsSrc}/plugins/frontend-design"
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



    home.file.".claude/skills/bro/SKILL.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${broSkillSrc}/SKILL.md";
    };

    # Site builder for lab customer sites (founder 2026-10-24): Sonnet 5.5
    # at xhigh effort with the frontend-design skill preloaded (kept on Sonnet
    # 2026-10-25: measured cheap; the budget lever is agent length). Spawn with
    # subagent_type "site-builder". The coordinator's brief supplies the
    # storyline, the page contract and the posting rules; Astra keeps the
    # final UI judgement.
    home.file.".claude/agents/site-builder.md".text = ''
      ---
      name: site-builder
      description: Builds a lab's customer-facing site (HTML, CSS, images) from a storyline design doc and page contract, with distinctive, production-grade visual design. Use for Paged Out lab sites and frontend labs.
      model: sonnet
      effort: xhigh
      skills:
        - frontend-design
      ---
      You build the customer-facing site of one lab from the brief you are given.
      Invoke the frontend-design skill before writing any HTML or CSS and follow it.
      Rules: the site is unique to its storyline (no templates); real business content
      (menu, prices, names) as static copy; only the outcome line is live and truthful;
      no mechanism, cause or repair words anywhere on the site; controls and state copy
      four words or fewer; theme tokens for light and dark; 44 px targets; reduced motion;
      no horizontal overflow at 360/390/1366; assets lazy-loaded only for that lab.
      Never edit the founder's checkout; work in the worktree and branch the brief names;
      every commit ends with "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>".
    '';

  };
}
