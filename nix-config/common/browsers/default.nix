{ pkgs, ... }:

{
  imports = [
    # ./firefox.nix
    ./floorp.nix
    # ./browserpass.nix
    ./zen.nix
    ./librewolf.nix
    # ./ladybird.nix
  ];
}
