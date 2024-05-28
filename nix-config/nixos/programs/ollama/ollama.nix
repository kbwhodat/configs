{ pkgs, config, ... }:

{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };
}
