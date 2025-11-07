{ configs, pkgs, ...}:
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.packages = with pkgs; [
    (if isDarwin then
        pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
      else
    virt-manager)
  ];
}
