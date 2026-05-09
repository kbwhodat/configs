{pkgs, ...}:
{
  home.packages = with pkgs; [
    xcodes
    xcode-install
  ];
}
