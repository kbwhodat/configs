{ pkgs, lib, config, ... }:
let
  cfg = config.modules.lsp;
  inherit (pkgs.stdenv) isDarwin;
in {
  options.modules.lsp.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Language server packages";
  };

  config = lib.mkIf cfg.enable {
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
      pyright
      ltex-ls-plus
      texlab
    ];
  };
}
