{ pkgs, lib, config, ... }:
let cfg = config.modules.packages; in {
  options.modules.packages.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Cross-platform user CLI packages";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kanata glow zathura taskwarrior-tui vim markdown-oxide nmap wget lsof htop
      curl git bat dig file fzf tree luajit luarocks fd dict ripgrep roboto
      roboto-serif hack-font unzip gzip fontconfig xdg-utils dbus go
      nix-prefetch-git rustup nodejs_22 tree-sitter zlib gnused gnutar coreutils
      pyenv jq yq sops taskwarrior3 sqlite newsboat gh
    ];
  };
}
