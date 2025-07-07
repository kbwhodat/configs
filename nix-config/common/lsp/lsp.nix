{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jdt-language-server
    python312Packages.jedi-language-server
    gopls
    golangci-lint
    nil
    harper
    nixd
    rustc
    rust-analyzer
    ltex-ls-plus
    texlab
  ];
}
