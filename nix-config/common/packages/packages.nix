{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zathura
    rubber
    # texliveBookPub
    rustc
    harper
    vim
    markdown-oxide
    python312Packages.jedi-language-server
    nil
    # nixd
    nmap
    wget
    lsof
    htop
    curl
    tmux
    git
    bat
    dig
    file
    fzf
    tree
    luajit
    luarocks
    fd
    ripgrep
    fira-code
    mononoki
    roboto
    roboto-mono
    roboto-serif
    hack-font
    unzip
    gzip
    fontconfig
    xdg-utils
    dbus
    go
    nix-prefetch-git
    cargo
    nodejs_22
    php83Packages.composer
    tree-sitter
    zlib
    gnused
    gnutar
    coreutils
    pyenv
    jq
    yq
    sops
    jdt-language-server
  ];
}
