{ pkgs, config, inputs, ... }:

{
  home.packages = with pkgs; [          
    wget
    curl
    tmux
    git
    bat
    pass
    imagemagick
    imagemagick.dev
    luajit
    tree
    luarocks
    clang
    fzf
    fd
    ripgrep
    fira-code
    unzip
    gzip
    go
    python3
    perl
    cargo
    nodejs_22
    yarn
    php83Packages.composer
    python311Packages.pip
    nodePackages.neovim
    ruby
    php
    tree-sitter
    redis
    tridactyl-native
    ];
}
