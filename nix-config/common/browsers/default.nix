{ pkgs, ... }:

{
  imports = [
    # ./firefox.nix
    ./floorp.nix
    # ./browserpass.nix
    ./zen.nix
    ./librewolf.nix
    ./chrome.nix
    # ./ladybird.nix
  ];
}
