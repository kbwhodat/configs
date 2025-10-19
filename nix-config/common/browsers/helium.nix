{ pkgs, ... }: 
let
  helium = pkgs.callPackage ../../modules/helium.nix { };
in 
{
  home.packages = [
    helium
  ];
}
