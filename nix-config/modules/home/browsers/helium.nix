{ pkgs, ... }: 
let
  # helium = pkgs.callPackage ../../modules/helium.nix { };
  inherit (pkgs.stdenv) isDarwin;
in 
{
  home.packages = [
    (if isDarwin then
        pkgs.nur.repos.forkprince.helium-nightly
      else
        pkgs.nur.repos.forkprince.helium-nightly)
  ];
}
