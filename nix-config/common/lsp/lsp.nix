{ pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.packages = with pkgs; [
    jdt-language-server
    python312Packages.jedi-language-server
    (if isDarwin then angular-language-server else nil)
    gopls
    golangci-lint
    nil
    harper
    nixd
    rustc
    # rust-analyzer
    ltex-ls-plus
    texlab
  ];
}
