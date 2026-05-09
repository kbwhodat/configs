{ pkgs, lib, ... }:
let
  inherit (pkgs.stdenv) isLinux;
in
{
  home.packages = lib.optionals isLinux [
    pkgs.wox
  ];
}
