{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zathura
    rubber
    # texliveBookPub
		#texliveFull
    taskwarrior3
    taskwarrior-tui
    vim
    markdown-oxide
    # (zed-editor-fhs.overrideAttrs (oldAttrs: rec {
    #   preConfigure = ''
    # export PROTOC=${pkgs.protobuf}/bin/protoc
    #   '' + (oldAttrs.preConfigure or "");
    #
    #   postInstall = (oldAttrs.postInstall or "") + ''
    # wrapProgram $out/bin/zeditor --set ZED_ALLOW_EMULATED_GPU 0
    #   '';
    # }))
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
  ];
}
