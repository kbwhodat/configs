{ pkgs, ... }:

{
  imports = [
    ./firefox.nix
    ./floorp.nix
    ./browserpass.nix
    ./zen.nix
    ./zen-browser.nix
  ];
}
