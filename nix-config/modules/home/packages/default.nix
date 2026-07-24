{ pkgs, lib, config, ... }:
let cfg = config.modules.packages; in {
  options.modules.packages.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Cross-platform user CLI packages";
  };

  options.modules.packages.personalTools.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Personal-flavored tools split from the base set so work hosts can
      exclude them: nmap (network scanner — corp security flag),
      newsboat (personal RSS), taskwarrior (personal task sync).
      Off via profiles/home/work.nix.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        kanata glow zathura vim markdown-oxide wget lsof htop
        curl git bat dig file fzf tree luajit luarocks fd dict ripgrep roboto
        roboto-serif hack-font unzip gzip fontconfig xdg-utils dbus go
        nix-prefetch-git rustup nodejs_22 tree-sitter zlib gnused gnutar coreutils
        pyenv jq yq sops sqlite gh
      ]
      ++ lib.optionals cfg.personalTools.enable [
        nmap newsboat taskwarrior3 taskwarrior-tui
      ];
  };
}
