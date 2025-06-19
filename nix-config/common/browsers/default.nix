{ pkgs, ... }:

{
  imports = [
    # ./firefox.nix
    ./floorp.nix
    # ./browserpass.nix
    ./zen.nix
    # ./ladybird.nix
  ];
}
