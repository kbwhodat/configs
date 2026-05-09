{ config, lib, ... }:
let cfg = config.modules.ai; in {
  imports = [
    ./mcp-servers.nix
    ./rtk.nix
    ./jobdrop.nix
    ./hermes.nix
    ./claude-code.nix
    ./opencode.nix
  ];

  options.modules.ai.enable = lib.mkEnableOption "AI tooling umbrella";

  config = lib.mkIf cfg.enable {
    modules.ai.claude-code.enable = lib.mkDefault true;
    modules.ai.opencode.enable    = lib.mkDefault true;
    modules.ai.mcp-servers.enable = lib.mkDefault true;
    modules.ai.rtk.enable         = lib.mkDefault true;
    modules.ai.jobdrop.enable     = lib.mkDefault true;
    modules.ai.hermes.enable      = lib.mkDefault true;
  };
}
