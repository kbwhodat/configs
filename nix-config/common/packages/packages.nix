{ pkgs, config, inputs, lib, ... }:

{
  home.packages = with pkgs; [
    zed-editor
    vulkan-tools
    keepassxc
    gnome-keyring
    vimgolf
    vim
    inputs.nil.packages.${pkgs.system}.nil
    nmap
    gonchill
    undetected-chromedriver
    libsixel
    wget
    lsof
    htop
    _7zz
    curl
    tmux
    git
    bat
    dig
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
    perl
    cargo
    nodejs_22
    nodePackages.peerflix
    yarn
    php83Packages.composer
    python311Packages.pip
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
    (python3.withPackages (ps: with ps; let
      blinker = ps.buildPythonPackage rec {
        pname = "blinker";
        version = "1.7.0";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/a1/13/6df5fc090ff4e5d246baf1f45fe9e5623aa8565757dfa5bd243f6a545f9e/blinker-1.7.0.tar.gz";
          sha256 = "e6820ff6fa4e4d1d8e2747c2283749c3f547e4fee112b98555cdcdae32996182";
        };

        nativeBuildInputs = [
          pkgs.python3Packages.build     # for `python -m build`
          pkgs.python3Packages.flit-core # backend for pyproject.toml
          pkgs.python3Packages.pip
          pkgs.python3Packages.wheel
        ];

        buildPhase = ''
          python -m build --wheel --no-isolation --outdir dist
        '';

        installPhase = ''
          pip install --no-deps --prefix=$out dist/*.whl
        '';
        doCheck = false;
      };

      seleniumWire = ps.buildPythonPackage rec {
        pname = "selenium-wire";
        version = "5.1.0";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/9f/00/60b39e8a1efe6919d1390f07d84a3eeba4aeae5b829f2f848344c798f783/selenium-wire-5.1.0.tar.gz";
          sha256 = "b1cd4eae44d9959381abe3bb186472520d063c658e279f98555def3d4e6dd29b";
        };

        # Ensure selenium-wire has access to blinker at runtime
        propagatedBuildInputs = [ blinker ];
        doCheck = false;
      };

      seleniumProfiles = ps.buildPythonPackage rec {
        pname = "selenium-profiles";
        version = "2.2.10";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/d1/82/99772a2f5951bd62de5e871056c374322aa951301503c065f001ea33cbbe/selenium_profiles-2.2.10.tar.gz";
          sha256 = "d2bb5c60c76c025f36bca62617875bc97dc2541cb25730e2dba50a3ddac95857";
        };
        doCheck = false;
      };

      seleniumInterceptor = ps.buildPythonPackage rec {
        pname = "selenium-interceptor";
        version = "1.0.2";
        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/f2/4a/ec8229dfd7b06363afa49a2dffb3809b080c8f9ebe710e6ae592d5f20f42/selenium_interceptor-1.0.2.tar.gz";
          sha256 = "e6410f743484e875d285da6fb9238b825ba76ae4efbbc5c6b9a3a45d2a6c4d39";
        };
        doCheck = false;
      };

      ipvanish = ps.buildPythonPackage rec {
        pname = "ipvanish";
        version = "1.2.1";
        src = pkgs.fetchFromGitHub {
          owner = "kbwhodat";
          repo = "ipvanish";
          rev = "master";
          sha256 = "66CJKEe/45hYEZaeCTsPVvU7KqyDErXfdSVL68xwyTc=";
        };
        doCheck = false;
      };

    in [
      brotli
      certifi
      h2
      hyperframe
      kaitaistruct
      pyasn1
      pyopenssl
      pyparsing
      pysocks
      selenium
      requests
      wsproto
      tqdm
      zstandard
      packaging
      setuptools
      undetected-chromedriver
      beautifultable
      beautifulsoup4
      click
      blinker
      seleniumWire
      seleniumProfiles
      seleniumInterceptor
      ipvanish
    ]))
  ];
}
