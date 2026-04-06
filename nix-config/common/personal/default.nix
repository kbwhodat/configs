{ config, ... }:
{
  imports = [
    ./personal.nix
    ./ai.nix
    ./openvpn.nix
    ./agenticseek.nix
    ./agent-zero.nix
  ];
}
