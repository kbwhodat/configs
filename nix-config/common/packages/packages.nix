{ pkgs, config, inputs, lib, ... }:

{
  home.packages = with pkgs; [          
    inputs.nil.packages.${pkgs.system}.nil
    gonchill
    wget
    lsof
    htop
    yaegi # go interpreter
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
    file
    fzf
    fd
    ripgrep
    fira-code
    unzip
    gzip
    go
    # alacritty
    perl
    cargo
    nodejs_22
    yarn
    php83Packages.composer
    python311Packages.pip
    nodePackages.neovim
    nodePackages.peerflix
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
    (python3.withPackages (ps: with ps; [
      blinker
      selenium-wire
      selenium
      packaging
      setuptools
      undetected-chromedriver
      beautifultable
      beautifulsoup4
      click
      (ps.buildPythonPackage rec {
        pname = "selenium-profiles";
        version = "2.2.10";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/d1/82/99772a2f5951bd62de5e871056c374322aa951301503c065f001ea33cbbe/selenium_profiles-2.2.10.tar.gz";
          sha256 = "d2bb5c60c76c025f36bca62617875bc97dc2541cb25730e2dba50a3ddac95857";  # Correct SHA256 hash
        };
        doCheck = false;  # Optional: disable package tests if necessary
      })
      (ps.buildPythonPackage rec {
        pname = "selenium-interceptor";
        version = "1.0.2";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/f2/4a/ec8229dfd7b06363afa49a2dffb3809b080c8f9ebe710e6ae592d5f20f42/selenium_interceptor-1.0.2.tar.gz";
          sha256 = "e6410f743484e875d285da6fb9238b825ba76ae4efbbc5c6b9a3a45d2a6c4d39";  # Correct SHA256 hash
        };
        doCheck = false;  # Optional: disable package tests if necessary
      })
      (ps.buildPythonPackage rec {
        pname = "ipvanish";
        version = "1.2.1";
        src = pkgs.fetchFromGitHub {
          owner = "kbwhodat";  # Replace with your GitHub username
          repo = "ipvanish";         # Replace with your repository name
          rev = "master";        # Replace with the commit hash or branch/tag name
          sha256 = "66CJKEe/45hYEZaeCTsPVvU7KqyDErXfdSVL68xwyTc=";
        };
        doCheck = false;  # Optional: disable package tests if necessary
      })
    ]))
    ];
}
