{ pkgs, ... }:

{
  imports = [
    ./firefox.nix
    ./floorp.nix
    ./chawan.nix
    ./browserpass.nix
    ./zen.nix
    ./librewolf.nix
    ./chrome.nix
    ./helium.nix
    # ./ladybird.nix
  ];
}
