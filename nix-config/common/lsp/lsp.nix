{ pkgs, ... }:

{
  home.packages = with pkgs; [
    #nixd
    rustc
    rust-analyzer
  ];
}
