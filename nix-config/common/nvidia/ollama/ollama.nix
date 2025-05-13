{ pkgs, config, ... }:

{
  services.ollama = {
    enable = false;
    acceleration = "cuda";
    # listenAddress = "0.0.0.0:11434";
    host = "0.0.0.0";
    port = 11434;
  };

}
