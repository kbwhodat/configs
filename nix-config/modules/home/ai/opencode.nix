{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.opencode;
  system = pkgs.stdenv.hostPlatform.system;

  # --- opencode v2 version pin (surgical) ----------------------------
  # llm-agents lags npm, and the `claude-agent` provider needs >= 2.2.3.
  # Installed as `opencode2` next to v1 `opencode`. Bump = new version + `dist.integrity` per platform from
  #   https://registry.npmjs.org/@opencode/cli-<platform>/<ver>
  # Drop this override once llm-agents catches up.
  opencode2Version = "2.2.4";
  opencode2Sources = {
    "aarch64-darwin" = { platform = "darwin-arm64"; hash = "sha512-5osdn6iEB389vLnooBA8Y/vn7aWoKEnB8Bzf9rE5Wyo39enqN19xozXzNL564tQCqmoYzjx8OmGShgkJgtszhQ=="; };
    "aarch64-linux"  = { platform = "linux-arm64";  hash = "sha512-MGwrdyOLJ2YMhAl9k/JTpjLHp8yCqw6gqDKT0GMOgPu56oMOZSaMUUg8hJK3Fq27uGOFQLiUtA3sbhdQg3lFAA=="; };
    "x86_64-linux"   = { platform = "linux-x64";    hash = "sha512-rWbnCOP/nIN8ILAt0hcuw51sNbuX+zcImSCX7tPUCsaYgVNLcZ73whfW4lYc04ZMPhxeySooN0IvfLvnsaJfgQ=="; };
  };
  opencode2Pinned = inputs.llm-agents.packages.${system}.opencode2.overrideAttrs (_: {
    version = opencode2Version;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-${opencode2Sources.${system}.platform}/-/cli-${opencode2Sources.${system}.platform}-${opencode2Version}.tgz";
      hash = opencode2Sources.${system}.hash;
    };
  });
in {
  options.modules.ai.opencode.enable = lib.mkEnableOption "opencode TUI, vendored skills and subagent routing";

  config = lib.mkIf cfg.enable {
    home.packages = [ opencode2Pinned ];

    programs.opencode = {
      enable = true;
      package = inputs.llm-agents.packages.${system}.opencode;
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
          firecrawl = { type = "local"; command = [ "env" "FIRECRAWL_API_KEY=REDACTED_FIRECRAWL_KEY" "npx" "-y" "firecrawl-mcp" ]; enabled = true; };
          playwright = { type = "local"; command = [ "mcp-server-playwright" "--no-sandbox" ]; enabled = false; };
          sequential_thinking = { type = "local"; command = [ "mcp-server-sequential-thinking" ]; enabled = false; };
          serena = { type = "local"; command = [ "serena" "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ]; enabled = true; };
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
          claude-agent.models = {
            fable.limit.context  = 300000;
            opus.limit.context   = 200000;
            sonnet.limit.context = 200000;
          };
          openai.models = {
            gpt-6-astra.limit.context   = 300000;
            "gpt-6.1-sol".limit.context   = 200000;
            "gpt-6.1-terra".limit.context = 200000;
          };
        };
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
  };
}
