{pkgs, config, ...}:
let
  hostname = config.networking.hostName;
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.packages = with pkgs; [
    # (if hostname == "macos-studo.local" then flutter else null)
    (if isDarwin then nil else flutter)
  ];
}
