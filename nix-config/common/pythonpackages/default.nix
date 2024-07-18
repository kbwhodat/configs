{ pkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; } }:

pkgs.mkShell {
  buildInputs = with pkgs.python3Packages; [
    selenium-profiles
  ];
}
