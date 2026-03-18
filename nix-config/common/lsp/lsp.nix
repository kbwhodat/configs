{ pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.packages = with pkgs; [
    jdt-language-server
    python313Packages.jedi-language-server
    (if isDarwin then angular-language-server else nil)
    gopls
    golangci-lint
    nil
    harper
    nixd
    rustc
    # rust-analyzer
    pyright
    ltex-ls-plus
    texlab
  ];
}
