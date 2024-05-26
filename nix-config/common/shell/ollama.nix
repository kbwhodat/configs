{ config, pkgs, ... }:

{
  imports = [ ../modules/ollama-module.nix ];
  services.ollama = {
    enable = true;
    logFile = "/tmp/";
  };
}
