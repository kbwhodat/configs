{ pkgs, ... }:

{
  imports = [
    ./firefox.nix
    ./browserpass.nix
  ];
}
