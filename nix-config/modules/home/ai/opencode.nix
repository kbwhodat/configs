{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.opencode;
  system = pkgs.stdenv.hostPlatform.system;

  # --- opencode v2 IS `opencode` (founder 2026-10-31) -----------------
  # v1 is gone. llm-agents ships v2 as `opencode2` (binary renamed so it can
  # coexist with its v1 `opencode` package); we take that derivation, pin the
  # version (llm-agents lags npm and the `claude-agent` provider needs
  # >= 2.2.3) and install it under the plain name `opencode`, then hand it to
  # programs.opencode as THE package.
  # Bump = new version + `dist.integrity` per platform from
  #   https://registry.npmjs.org/@opencode/cli-<platform>/<ver>
  # Drop the version/src override (keep the rename) once llm-agents catches up.
  opencodeVersion = "2.2.4";
  opencodeSources = {
    "aarch64-darwin" = { platform = "darwin-arm64"; hash = "sha512-5osdn6iEB389vLnooBA8Y/vn7aWoKEnB8Bzf9rE5Wyo39enqN19xozXzNL564tQCqmoYzjx8OmGShgkJgtszhQ=="; };
    "aarch64-linux"  = { platform = "linux-arm64";  hash = "sha512-MGwrdyOLJ2YMhAl9k/JTpjLHp8yCqw6gqDKT0GMOgPu56oMOZSaMUUg8hJK3Fq27uGOFQLiUtA3sbhdQg3lFAA=="; };
    "x86_64-linux"   = { platform = "linux-x64";    hash = "sha512-rWbnCOP/nIN8ILAt0hcuw51sNbuX+zcImSCX7tPUCsaYgVNLcZ73whfW4lYc04ZMPhxeySooN0IvfLvnsaJfgQ=="; };
  };
  opencodePinned = inputs.llm-agents.packages.${system}.opencode2.overrideAttrs (old: {
    pname = "opencode";
    version = opencodeVersion;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-${opencodeSources.${system}.platform}/-/cli-${opencodeSources.${system}.platform}-${opencodeVersion}.tgz";
      hash = opencodeSources.${system}.hash;
    };
    # Upstream's installPhase does `install bin/opencode $out/bin/opencode2`
    # + wrapProgram, and the Linux postFixup rpath-patches `.opencode2-wrapped`.
    # Rewrite both to the plain name; home-manager's programs.opencode expects
    # `bin/opencode` (lib.getExe + its extraPackages wrapper).
    installPhase = builtins.replaceStrings [ "opencode2" ] [ "opencode" ] old.installPhase;
    postFixup = builtins.replaceStrings [ ".opencode2-wrapped" ] [ ".opencode-wrapped" ] (old.postFixup or "");
    meta = old.meta // { mainProgram = "opencode"; };
  });

  # --- Gemini 4 Argon as provider `agy` (founder 2026-10-31) -------------
  # ./opencode-agy is a V2 plugin that drives Google's OFFICIAL Antigravity
  # ACP server over stdio (the server does its own Google login; we never
  # touch tokens, which is the pattern Google bans). It mirrors the built-in
  # `claude-agent` provider: OpenCode tools bridged over an in-process MCP
  # server, permissions, streaming, reasoning, effort variants, usage.
  # Source only: OpenCode injects `@opencode/plugin`/`effect` into plugins
  # and refuses a plugin-local copy, so node_modules must not be shipped.
  # One-time login after rebuild (prints a Google URL):
  #   cd ~/.config/opencode/plugins/agy && bun run bin/login.ts
  # Quota note: AI Pro meters Argon by compute; keep agents on `medium`.
  agyAcpServer = pkgs.callPackage ./opencode-agy/agy-acp-server.nix { };
  agyPlugin = lib.cleanSourceWith {
    src = ./opencode-agy;
    filter = path: _type: builtins.baseNameOf path != "node_modules";
  };
in {
  options.modules.ai.opencode.enable = lib.mkEnableOption "opencode TUI, vendored skills and subagent routing";

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = opencodePinned;
      enableMcpIntegration = true;
      context = ''
        Do not use AskUserQuestion — that tool does not exist here. To ask the user a question, use the "question" tool instead.
      '';
      commands = {
        rebuild-switch = ''
          Rebuild and switch to NixOS flake configuration defined for current machine.
          Usage: /rebuild-switch
        '';
      };
      # Reviewed ECC skills vendored under ./opencode-skills (see PROVENANCE.md
      # there). Attribute form on purpose: a whole-directory link would also
      # expose PROVENANCE.md / LICENSE.ecc, and a root-level *.md in
      # ~/.config/opencode/skills is itself read as a skill by OpenCode V2.
      skills = lib.genAttrs [
        "api-design"
        "benchmark-optimization-loop"
        "content-hash-cache-pattern"
        "contract-first"
        "data-throughput-accelerator"
        "error-handling"
        "issue-review"
        "latency-critical-systems"
        "make-interfaces-feel-better"
        "mcp-dependency-review"
        "python-patterns"
        "terminal-ops"
        # Non-ECC sources, see PROVENANCE.md for origin and commit.
        "systematic-debugging"           # obra/superpowers
        "verification-before-completion" # obra/superpowers
        "workers-best-practices"         # cloudflare/skills
        "wrangler"                       # cloudflare/skills
        "promql"                         # grafana/skills
        "dashboarding"                   # grafana/skills
        "playwright-best-practices"      # currents.dev via uzh-bf/klicker-uzh
        "postmortem-writing"             # wshobson/agents
        "k8s-namespace-troubleshooting"  # foxj77/claude-code-skills
      ] (name: ./opencode-skills + "/${name}") // {
        # Same pinned flake input claude-code.nix uses for ~/.claude/skills/bro.
        bro = "${inputs.bro-skill}/SKILL.md";
      };
      tui.keybinds = {
        messages_half_page_up = "ctrl+alt+u";
        messages_half_page_down = "ctrl+alt+d";
        messages_line_up = "ctrl+alt+y";
        messages_line_down = "ctrl+alt+e";
      };
      settings = {
        mcp = {
          context7 = { type = "remote"; url = "https://mcp.context7.com/mcp"; enabled = false; };
          mcp_nixos = { type = "local"; command = [ "mcp-nixos" ]; enabled = false; };
          terraform = { type = "local"; command = [ "terraform-mcp-server" ]; enabled = false; };
          fetch = { type = "local"; command = [ "mcp-server-fetch" ]; enabled = false; };
          # Key lives outside the repo (public GitHub): ~/.secrets/firecrawl-api-key, mode 600.
          firecrawl = { type = "local"; command = [ "sh" "-c" "FIRECRAWL_API_KEY=\"$(cat \"$HOME/.secrets/firecrawl-api-key\")\" exec npx -y firecrawl-mcp" ]; enabled = true; };
          playwright = { type = "local"; command = [ "mcp-server-playwright" "--no-sandbox" ]; enabled = false; };
          sequential_thinking = { type = "local"; command = [ "mcp-server-sequential-thinking" ]; enabled = false; };
          serena = { type = "local"; command = [ "serena" "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ]; enabled = false; }; # founder 2026-10-31: disabled (one instance per directory, slow symbol calls timed out, 1 tool call in 20 starts)
          jobdrop = { type = "local"; command = [ "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server" ]; enabled = false; };
        };
        # Compaction (founder 2026-10-30): compact the primaries at 275k
        # instead of near the 1M/400k windows. `compaction.buffer` is absolute
        # and ignored when >= a model's limit, so the ceiling is set per model
        # by declaring a smaller context limit (safe direction: the real API
        # window is larger). 300k limit - 25k buffer = compaction at 275k.
        compaction = { auto = true; keep = { tokens = 24000; }; buffer = 25000; };
        # Workers get 200k -> compaction at 175k; a subagent task that needs
        # more context should be split, not grown.
        provider = {
          # Argon plugin finds the server here first, then on PATH (home.packages).
          agy.options.serverPath = "${agyAcpServer}/bin/agy-acp-server";
          claude-agent.models = {
            # `fable` is OUR alias, not Anthropic's. On 2026-10-30 the provider's
            # own `fable` alias vanished live ("Model unavailable: claude-agent/fable")
            # and sessions pinned to it stopped. Defining the key here keeps the
            # reference stable; only `id` (the upstream model id) ever needs to
            # change. In this V1-shaped `provider` block the upstream id field is
            # `id` (V2 `providers` uses `modelID`); verified with `opencode run`.
            fable = {
              id = "claude-fable-5-1[1m]";
              name = "Fable 5.1";
              limit = { context = 300000; output = 128000; };
            };
            # Same treatment for the worker aliases: our keys, explicit upstream
            # ids, so a live alias shuffle cannot strand subagents either.
            opus = {
              id = "claude-opus-5-5";
              name = "Opus 5.5";
              limit = { context = 200000; output = 128000; };
            };
            sonnet = {
              id = "claude-sonnet-5-5";
              name = "Sonnet 5.5";
              limit = { context = 200000; output = 128000; };
            };
          };
          # RULE (bisected 2026-10-31 against /api/model): every model entry
          # needs `id` AND a full `limit` (context + output; input too where
          # the upstream model has one), otherwise OpenCode's V1->V2 config
          # migration drops the WHOLE provider block silently and the upstream
          # limits apply (fable then runs at 200k and compacts near 175k).
          # The `limit.context`-only shorthand that used to be here was being
          # thrown away for exactly that reason.
          openai.models = {
            gpt-6-astra = {
              id = "gpt-6-astra";
              limit = { context = 300000; input = 272000; output = 128000; };
            };
            "gpt-6.1-sol" = {
              id = "gpt-6.1-sol";
              limit = { context = 200000; input = 200000; output = 128000; };
            };
            "gpt-6.1-terra" = {
              id = "gpt-6.1-terra";
              limit = { context = 200000; input = 200000; output = 128000; };
            };
          };
        };
        # Kimi Code subscription over OAuth (founder 2026-10-31). OpenCode v2
        # does not load V1 plugins, and the well-known Kimi auth plugins
        # (opencode-kimi-subscription, opencode-kimi-oauth, @openprojectx/...)
        # are V1-only. opencode-kimi-v2 (soltrac) is built on the V2 SDK: it
        # registers the `kimi-for-coding-oauth` integration (device flow at
        # auth.kimi.com, auto-refresh), sends the kimi-cli fingerprint headers
        # Moonshot requires, and discovers the account's models live, so
        # k3.1-pro shows up as `kimi-for-coding-oauth/k3.1-pro`. Installed by
        # OpenCode itself (bun, ~/.cache/opencode/npm) on first start; pinned
        # like everything else here. One-time login after rebuild:
        #   opencode auth login kimi-for-coding-oauth
        # V1 key on purpose, matching the V1-shaped `provider`/`agent` blocks;
        # verified 2026-10-31 that OpenCode 2.2.4 normalises it to `plugins`.
        plugin = [ "opencode-kimi-v2@0.1.1" ];
        # Default model for new sessions comes from config, not the TUI's last
        # pick. Points at our own alias above.
        model = "claude-agent/fable";
        autoshare = false;
        autoupdate = false;
        permission = "allow";
        # Subagents (founder 2026-10-30): primaries run on astra / fable, the
        # workers run on sol, opus and sonnet and never inherit the parent's
        # model. Claude comes through the `claude-agent` provider here, so the
        # refs are claude-agent/<alias>, not anthropic/<id>.
        # Each worker is capped by model steps (V1 `maxSteps`, V2 `steps`): on
        # the last step OpenCode removes tools and asks for a text summary.
        # Raise per agent if a task genuinely needs more.
        agent = {
          general = {
            model = "openai/gpt-6.1-sol";
            maxSteps = 24;
            description = "Sol worker (strong, 24 steps). Use for complex problems: multi-step implementation, non-trivial debugging, analysis that needs real reasoning. Pick general-terra only for cheap bulk reads; general-opus only when a Claude second opinion is wanted.";
          };
          explore = { model = "claude-agent/sonnet"; maxSteps = 12; };
          perftutor = {
            mode = "primary";
            description = "Perf Tutor Agent";
            prompt = builtins.readFile ../personal/prompts/perftutor.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
            temperature = 0.25;
          };
          perfguru = {
            mode = "primary";
            description = "Perf Guru Agent";
            prompt = builtins.readFile ../personal/prompts/perfguru.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
            temperature = 0.25;
          };
          planner = {
            mode = "subagent";
            description = "Expert planning specialist for complex features and refactoring";
            prompt = builtins.readFile ../personal/prompts/planner.txt;
            tools = { read = true; bash = true; };
            model = "claude-agent/opus";
            maxSteps = 12;
          };
          general-terra = {
            mode = "subagent";
            description = "Terra worker (cheapest, 24 steps). Use for bulk reads, file audits, summarising, and simple mechanical tasks. Escalate to general (sol) as soon as the task needs judgement.";
            model = "openai/gpt-6.1-terra";
            maxSteps = 24;
          };
          # Founder proxies (founder 2026-10-31): decide in the founder's stead when
          # they are away. proxy1 (Astra) is consulted first; proxy2 (Fable) only if
          # proxy1 is unavailable. Charter: ~/.config/pagedout/coordinator/FOUNDER-PROXY.md;
          # every decision is appended to FOUNDER-PROXY-LOG.md. Read + log append only.
          proxy1 = {
            mode = "subagent";
            description = "Founder proxy 1 (Astra). Decides founder-level questions from the charter when the founder is away; logs every decision. Consult before proxy2.";
            prompt = builtins.readFile ../personal/prompts/founder-proxy.txt;
            model = "openai/gpt-6-astra";
            maxSteps = 8;
            tools = { read = true; bash = true; write = false; edit = false; };
          };
          proxy2 = {
            mode = "subagent";
            description = "Founder proxy 2 (Fable). Same charter as proxy1; use only when proxy1 is unavailable or fails to answer.";
            prompt = builtins.readFile ../personal/prompts/founder-proxy.txt;
            model = "claude-agent/fable";
            maxSteps = 8;
            tools = { read = true; bash = true; write = false; edit = false; };
          };
          # Customer reviewer (founder 2026-10-31): Kimi K3.1 Pro, chosen for its
          # human/customer-perspective judgement. Reviews learner-facing surfaces
          # (tickets, Docs, Verify text, flows, screenshots) as a real person would;
          # verdict SHIP / FIX FIRST / RETHINK. Never edits the repo or runs suites.
          # Kimi subscription usage is limited (founder): reserve for final wording
          # reviews of learner-facing text, small material, one call per surface;
          # standard k3.1-pro, not the 2x-cost highspeed variant.
          customer = {
            mode = "subagent";
            description = "Customer reviewer (Kimi K3.1 Pro). Judges tickets, Docs, Verify text, flows and screenshots from a real learner's or customer's perspective: what confuses, what feels unfair, what leaks the answer. Verdict SHIP / FIX FIRST / RETHINK. Read-only on the repo.";
            prompt = builtins.readFile ../personal/prompts/customer.txt;
            model = "kimi-for-coding-oauth/k3.1-pro";
            maxSteps = 24;
            tools = { read = true; bash = true; write = true; edit = false; };
          };
          # Same charter on Gemini 4 Argon through the `agy` provider (founder
          # 2026-10-31). AI Pro meters Argon by compute, so: medium effort
          # (the provider default), read-only, and a short brief with the
          # material already gathered; Argon judges, it does not go fetching.
          # Argon usage (founder 2026-10-31): ship-gating surfaces only, run
          # next to `customer` on every ticket, Verify text and Docs page before
          # a lab ships. When customer and the architect disagree, Argon is a
          # third input the architect must answer in writing; it does not decide.
          customer-argon = {
            mode = "subagent";
            description = "Customer reviewer (Gemini 4 Argon). Same charter as customer: judges tickets, Docs, Verify text, flows and screenshots from a real learner's or customer's perspective. Verdict SHIP / FIX FIRST / RETHINK. Run next to customer on every ship-gating surface; third input (not the decider) when customer and the architect disagree. Read-only; give it the material in the brief.";
            prompt = builtins.readFile ../personal/prompts/customer.txt;
            model = "agy/argon";
            maxSteps = 16;
            tools = { read = true; bash = false; write = false; edit = false; };
          };
          # Leak detector by attempt (founder 2026-10-31): Argon's most valuable
          # use. It gets exactly what a learner sees (packet built by a worker,
          # never hand-assembled) and tries to solve the incident. Tier 1 =
          # ticket + Docs only: naming the fault, setting or fix is a LEAK.
          # Tier 2 = + box clues: must be SOLVABLE and not TOO LOUD. Reads only
          # the packet; anything else invalidates the test.
          leak-solver = {
            mode = "subagent";
            description = "Leak detector by attempt (Gemini 4 Argon). Give it exactly the learner packet for a lab (tier 1: ticket + Docs; tier 2: + box clues) and it tries to solve the incident as a strong on-call engineer. Tier 1 verdict LEAK / CLEAN; tier 2 SOLVABLE / TOO LOUD / UNFAIR, each with the quoted line. Reads only the packet named in the brief.";
            prompt = builtins.readFile ../personal/prompts/leak-solver.txt;
            model = "agy/argon";
            maxSteps = 8;
            tools = { read = true; bash = false; write = false; edit = false; };
          };
          # Realism critique of lab designs (founder 2026-10-31): one call with
          # the architect's design document, before any build. Judges the fault
          # mechanism, customer-visible symptoms, timeline and the on-call first
          # five minutes. Verdict PLAUSIBLE / FIX FIRST / IMPLAUSIBLE.
          realism-critic = {
            mode = "subagent";
            description = "Realism critic (Gemini 4 Argon). Hand it an architect's lab design and it says what an experienced on-call engineer would find implausible: fault mechanism, how it surfaces to the customer, timeline, first five minutes, red herrings. Verdict PLAUSIBLE / FIX FIRST / IMPLAUSIBLE. One call, one document, read-only.";
            prompt = builtins.readFile ../personal/prompts/realism-critic.txt;
            model = "agy/argon";
            maxSteps = 8;
            tools = { read = true; bash = false; write = false; edit = false; };
          };
          # Single-document second opinions on Argon (coordinator proposal
          # 2026-10-31, founder accepted): Verify reason wording, red-pilot
          # postmortem, catalogue coverage, hint-ladder leak point, ranked
          # rubric fairness. One mode per call, named in the brief.
          argon-critic = {
            mode = "subagent";
            description = "Single-document critic (Gemini 4 Argon). Modes, one per call: VERIFY WORDING (does the reason name what the ticket never said), POSTMORTEM (cause + missed check of a red pilot), COVERAGE (missing incident classes, near-duplicate labs), HINT LADDER (at which hint the fault becomes nameable), RUBRIC (ranked scoring fairness). Read-only; give it the document in the brief.";
            prompt = builtins.readFile ../personal/prompts/argon-critic.txt;
            model = "agy/argon";
            maxSteps = 8;
            tools = { read = true; bash = false; write = false; edit = false; };
          };
          # Kimi worker (founder 2026-10-31): Kimi K3.1 Pro is cheaper than
          # Argon and has been precise and honest as `customer`, so it also takes
          # bounded work: field-evidence lookups for proposed labs (URL + quote),
          # small learner-text builds under a PATH SCOPE when the wording is
          # already decided, and learner-packet extraction for leak-solver.
          # Not a designer and not a judge; stops when a sentence is left open.
          kimi-worker = {
            mode = "subagent";
            description = "Kimi worker (Kimi K3.1 Pro, 16 steps). Bounded tasks with a PATH SCOPE: web lookups and field-evidence research for proposed labs (cite URL + sentence), small learner-text builds when the wording is already decided (with the pinning test), bulk reads with a question, learner-packet extraction (ticket + Docs + box clues) for leak-solver. Never invents wording; never widens scope.";
            prompt = builtins.readFile ../personal/prompts/kimi-worker.txt;
            model = "kimi-for-coding-oauth/k3.1-pro";
            maxSteps = 16;
            tools = { read = true; bash = true; write = true; edit = true; };
          };
          # Product architects (founder 2026-10-31): know the product end to end
          # (docs, rulings, ledger, code) and its direction; every product question
          # goes to them: should we build it, what it does to the learner, how it fits
          # the roadmap, the right shape, what it breaks, the builder's PATH SCOPE.
          # Two models for a second opinion. Read-only; never build; production-window
          # decisions stay with the founder/proxies and the recorded procedure.
          architect-astra = {
            mode = "subagent";
            description = "Product architect and designer (Astra). Knows the whole product and where it is going; answers every product question (should we build it, customer outcome, right shape, what it breaks, roadmap fit) and designs labs, Docs, tickets, checks and flows for the builders, with the builder PATH SCOPE. Read-only.";
            prompt = builtins.readFile ../personal/prompts/architect.txt;
            model = "openai/gpt-6-astra";
            maxSteps = 24;
            tools = { read = true; bash = true; write = true; edit = false; };
          };
          architect-fable = {
            mode = "subagent";
            description = "Product architect and designer (Fable). Same charter as architect-astra on Claude Fable; use for a second opinion or when Astra is unavailable. Read-only.";
            prompt = builtins.readFile ../personal/prompts/architect.txt;
            model = "claude-agent/fable";
            maxSteps = 24;
            tools = { read = true; bash = true; write = true; edit = false; };
          };
          general-opus = {
            mode = "subagent";
            description = "Opus worker (expensive, 24 steps). For the hardest reasoning or when a Claude second opinion on sol/astra work is wanted. Use general (sol) for ordinary complex work.";
            model = "claude-agent/opus";
            maxSteps = 24;
          };
          tdd-guide = {
            mode = "subagent";
            description = "TDD specialist enforcing test-first development with Red-Green-Refactor";
            prompt = builtins.readFile ../personal/prompts/tdd-guide.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
            model = "claude-agent/sonnet";
            maxSteps = 24;
          };
        };
      };
    };

    # Argon: official ACP server on PATH (login script + plugin fallback) and
    # the plugin source where OpenCode auto-discovers it. `force` replaces the
    # hand-made symlink used while developing the plugin.
    home.packages = [ agyAcpServer ];
    home.file.".config/opencode/plugins/agy" = {
      source = agyPlugin;
      force = true;
    };
  };
}
