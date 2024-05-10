{ libs, pkgs, config, inputs, ... }:

{
  home.packages = with pkgs; [          
    inputs.nil.packages.${pkgs.system}.nil
    pkgs.wget
    pkgs.curl
    pkgs.tmux
    pkgs.git
    pkgs.bat
    pkgs.pass
    pkgs.imagemagick
    pkgs.imagemagick.dev
    pkgs.luajit
    pkgs.tree
    pkgs.luarocks
    pkgs.clang
    pkgs.fzf
    pkgs.fd
    pkgs.ripgrep
    pkgs.fira-code
    pkgs.unzip
    pkgs.gzip
    pkgs.go
    pkgs.python3
    pkgs.perl
    pkgs.cargo
    pkgs.nodejs_22
    pkgs.yarn
    pkgs.php83Packages.composer
    pkgs.python311Packages.pip
    pkgs.nodePackages.neovim
    pkgs.ruby
    pkgs.php
    pkgs.tree-sitter
    pkgs.redis
    ];
}
