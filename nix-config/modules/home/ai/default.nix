{ config, lib, ... }:
let cfg = config.modules.ai; in {
  imports = [
    ./mcp-servers.nix
    ./rtk.nix
    ./jobdrop.nix
    ./hermes.nix
    ./hermes-weather.nix
    ./hermes-rtk.nix
    ./hermes-execplan.nix
    ./hermes-skillclaw.nix
    ./hermes-workspace.nix
    ./hermes-profiles.nix
    ./claude-code.nix
    ./opencode.nix
    ./pi-coding-agent.nix
    ./no-hallucination.nix
    ./hallucination-detector.nix
  ];

  options.modules.ai.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "AI tooling umbrella (Claude Code, opencode, MCP servers, RTK, jobdrop, hermes + plugins/skills/workspace, pi, no-hallucination, hallucination-detector)";
  };

  config = lib.mkIf cfg.enable {
    modules.ai.claude-code.enable            = lib.mkDefault true;
    modules.ai.opencode.enable               = lib.mkDefault true;
    modules.ai.mcp-servers.enable            = lib.mkDefault true;
    modules.ai.rtk.enable                    = lib.mkDefault true;
    modules.ai.jobdrop.enable                = lib.mkDefault true;
    modules.ai.hermes.enable                 = lib.mkDefault false;
    modules.ai.hermes-weather.enable         = lib.mkDefault false;
    modules.ai.hermes-rtk.enable             = lib.mkDefault false;
    modules.ai.hermes-execplan.enable        = lib.mkDefault false;
    modules.ai.hermes-skillclaw.enable       = lib.mkDefault false;
    modules.ai.hermes-workspace.enable       = lib.mkDefault false;
    modules.ai.hermes-profiles.enable        = lib.mkDefault false;
    modules.ai.pi-coding-agent.enable        = lib.mkDefault true;
    modules.ai.no-hallucination.enable       = lib.mkDefault false;
    modules.ai.hallucination-detector.enable = lib.mkDefault false;

    # uv-tool installs (hermes, jobdrop, future agents) drop binaries
    # into ~/.local/bin. Make sure interactive shells can find them.
    home.sessionPath = [ "$HOME/.local/bin" ];
  };
}
