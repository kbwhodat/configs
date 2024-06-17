{ pkgs, config, inputs, ... }:

{
  home.packages = with pkgs; [          
    inputs.nil.packages.${pkgs.system}.nil
    wget
    htop
    _7zz
    curl
    tmux
    git
    bat
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
    # alacritty
    perl
    cargo
    nodejs_22
    yarn
    php83Packages.composer
    python311Packages.pip
    nodePackages.neovim
    vim
    ruby
    php
    tree-sitter
    pinentry-gtk2
    zlib
    sqlite
    gh
    gnused
    gnutar
    coreutils
    pyenv
    duckdb
    jq
    yq
    sops
    ];
}
