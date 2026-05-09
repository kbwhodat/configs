{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.claude-code;
  unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
  claudeHookPath = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";

  eccSrc = pkgs.fetchFromGitHub {
    owner = "affaan-m";
    repo = "everything-claude-code";
    rev = "main";
    sha256 = "sha256-R1LwfU8w4QJi69so+TG1BMVVH+zf9epsAmZPbw9mnYU=";
  };
  superpowersSrc = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "main";
    sha256 = "sha256-3E3rO6hR87JUfS3XV1Eaoz6SDWOftleWvN9UPNFEMjw=";
  };
in {
  options.modules.ai.claude-code.enable = lib.mkEnableOption "Claude Code with ECC + superpowers";

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = unstable.claude-code;
      marketplaces = { ecc = eccSrc; superpowers = superpowersSrc; };
      plugins = [ eccSrc superpowersSrc ];
      mcpServers = {
        context7 = { url = "https://mcp.context7.com/mcp"; disabled = true; };
        mcp_nixos = { command = "mcp-nixos"; disabled = true; };
        terraform = { command = "terraform-mcp-server"; disabled = true; };
        fetch = { command = "mcp-server-fetch"; disabled = true; };
        firecrawl = {
          command = "env";
          args = [ "FIRECRAWL_API_KEY=fc-b5db7738ea3843dd86181be770891120" "npx" "-y" "firecrawl-mcp" ];
        };
        playwright = { command = "mcp-server-playwright"; args = [ "--no-sandbox" ]; };
        sequential_thinking = { command = "mcp-server-sequential-thinking"; disabled = true; };
        serena = {
          command = "serena";
          args = [ "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ];
        };
        jcodemunch = { command = "jcodemunch"; disabled = true; };
        jobdrop = { command = "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server"; };
      };
      settings = {
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
  };
}
