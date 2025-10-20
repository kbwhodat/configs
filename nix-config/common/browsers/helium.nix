{ pkgs, ... }: 
let
  helium = pkgs.callPackage ../../modules/helium.nix { };
  inherit (pkgs.stdenv) isDarwin;
in 
{
  home.packages = [
    (if isDarwin then
        pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
      else
        helium)
  ];
}
