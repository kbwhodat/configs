{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.mcp-servers;
  system = pkgs.stdenv.hostPlatform.system;
in {
  options.modules.ai.mcp-servers.enable = lib.mkEnableOption "MCP server packages";

  config = lib.mkIf cfg.enable {
    home.packages =
      (with inputs.mcp-servers-nix.packages.${system}; [
        context7-mcp
        mcp-server-fetch
        mcp-server-sequential-thinking
        serena
      ])
      ++ (with pkgs; [
        mcp-nixos
        terraform-mcp-server
        playwright-mcp
      ]);
  };
}
