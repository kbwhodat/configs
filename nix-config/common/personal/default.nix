{ config, ... }:
{
  imports = [
    ./personal.nix
    ./ai.nix
    ./openvpn.nix
  ];
}
