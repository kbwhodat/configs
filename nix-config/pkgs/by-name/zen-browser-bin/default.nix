{
  pkgs,
  stdenv,
  lib,
  fetchzip,
  makeDesktopItem,
  autoPatchelfHook,
  wrapGAppsHook3,
  copyDesktopItems,
  gtk3,
  alsa-lib,
  dbus-glib,
  xorg,
  pciutils,
  libva,
  ffmpeg,
  pipewire,
  libglvnd,

  # Adding this so I can use add-ons like browserpass and trydactyl
  nativeMessagingHosts ? []
}:

let
  desktopItem = makeDesktopItem {
    name = "zen-browser";
    desktopName = "Zen Browser";
    genericName = "Web Browser";
    categories = ["Network" "WebBrowser"];
    keywords = [
      "internet"
      "www"
      "browser"
      "web"
      "explorer"
    ];
    exec = "zen %u";
    icon = "zen";
    mimeTypes = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
    startupWMClass = "zen-alpha";
    terminal = false;
    actions = {
      new-window = {
        name = "New Window";
        exec = "zen --new-window %u";
      };
      new-private-window = {
        name = "New Private Window";
        exec = "zen --private-window %u";
      };
      profile-manager-window = {
        name = "Profile Manager";
        exec = "zen --ProfileManager %u";
      };
    };
  };
  inherit (pkgs.stdenv) isDarwin;
  version = "1.0.2-b.5";

# Darwin vs. Linux URLs
  darwinUrl  = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.macos-x86_64.dmg";
  linuxUrl   = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.bz2";
  hash       = "sha256-sS9phyr97WawxB2AZAwcXkvO3xAmv8k4C8b8Qw364PY=";
in
stdenv.mkDerivation rec {
  pname = "zen-browser-bin";


  src = if isDarwin then
    pkgs.fetchurl {
      name = "";
      url = darwinUrl;
      hash = hash;
    }
  else
    fetchzip {
      name = "";
      url = linuxUrl;
      hash = hash;
    };

  desktopItems = if isDarwin then
    ''''
  else
    [
      desktopItem
    ];

  nativeBuildInputs = if isDarwin then
    ''''
  else
    [
      autoPatchelfHook
        wrapGAppsHook3
        copyDesktopItems
    ];

  buildInputs = [
    pkgs._7zz
    gtk3
    alsa-lib
    dbus-glib
    xorg.libXtst
  ] ++ nativeMessagingHosts;

  unpackPhase = if isDarwin then ''
    runHook preUnpack
    7zz x "$src" -o"$sourceRoot"
    runHook postUnpack
  ''
  else
  '''';

  installPhase = if isDarwin then ''
    preInstall

    mkdir -p $out/Applications
    cp -r 'Zen Browser.app' "$out/Applications/"

    runHook postInstall
  ''

  else

  ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r $src $out/lib/zen/

    mkdir -p $out/bin
    ln -s $out/lib/zen/zen $out/bin/zen

    for n in {16,32,48,64,128}; do
      size=$n"x"$n
      mkdir -p $out/share/icons/hicolor/$size/apps
      file="default"$n".png"
      cp $out/lib/zen/browser/chrome/icons/default/$file $out/share/icons/hicolor/$size/apps/zen.png
    done

    runHook postInstall
  '';

  preFixup = if isDarwin then
  ''''
  else
  ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        pciutils
        pipewire
        libva
        libglvnd
        ffmpeg
      ]}"
    )
    gappsWrapperArgs+=(--set MOZ_LEGACY_PROFILES 1)
    wrapGApp $out/lib/zen/zen
  '';

  meta = with lib; {
    license = licenses.mpl20;
    maintainers = with maintainers; [ mordrag ];
    description = "Experience tranquillity while browsing the web without people tracking you!";
    platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "zen";
  };
}
