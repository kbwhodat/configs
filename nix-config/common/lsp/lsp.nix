{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gopls
    golangci-lint
    nixd
    rustc
    rust-analyzer
    ltex-ls-plus
    texlab
  ];
}
