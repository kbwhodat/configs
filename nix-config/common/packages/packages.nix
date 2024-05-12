{ pkgs, config, inputs, ... }:

{
  home.packages = with pkgs; [          
    inputs.nil.packages.${pkgs.system}.nil
    mongosh
    wget
    htop
    curl
    tmux
    git
    bat
    # pass
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
    # gnupg
    pinentry-gtk2
    # bash
    # gcr
    # pinentry-curses
    google-cloud-sdk
    browserpass
    ansible
    sqlite
    terraform
    duckdb
    jq
    yq
    ];
}