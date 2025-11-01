{ configs, pkgs, ...}:
{
  home.packages = [
    (if isDarwin then
        pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
      else
    virt-manager)
  ];
}
