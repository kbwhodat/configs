{ config, pkgs, ... }:

{
  # imports = [ ../modules/ollama-module.nix ];
  
  services.ollama = {
    enable = true;
    logFile = "/tmp/ollama.log";  # Ensure the log file path is complete with a filename
    listenAddress = "127.0.0.1:11434";  # Optional, if you want to override the default
    acceleration = "cuda";  # Optional, set to "rocm" or "cuda" if needed
    package = pkgs.ollama;  # Assuming pkgs.ollama is your package, replace if different
  };
}
