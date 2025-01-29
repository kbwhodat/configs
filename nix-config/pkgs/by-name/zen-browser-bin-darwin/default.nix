{
  stdenv,
  pkgs,
  fetchurl,
  lib,
  policies ? { },
  nativeMessagingHosts ? [],
  ...
}:
let
  zen-browser = builtins.fromJSON (builtins.readFile ./zen-browser.json);
  isPoliciesEnabled = builtins.length (builtins.attrNames policies) > 0;
  policiesJson = builtins.toJSON { inherit policies; };
in
stdenv.mkDerivation rec {
  pname = "zen-browser-bin-darwin";
  version = zen-browser.version;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [
    pkgs._7zz
    pkgs.undmg
  ]++ nativeMessagingHosts;
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  unpackPhase = ''
    runHook preUnpack

    undmg $src || 7zz x -snld $src

    runHook postUnpack
  '';

  installPhase =
    ''
      runHook preInstall

      mkdir -p "$out/Applications/${sourceRoot}"
      cp -R . "$out/Applications/${sourceRoot}"

      runHook postInstall
    ''

    + (
      if isPoliciesEnabled then
        ''
          mkdir -p "$out/Applications/Zen Browser.app/Contents/Resources/distribution"
          echo '${policiesJson}' > "$out/Applications/Zen Browser.app/Contents/Resources/distribution/policies.json"

          runHook postInstall
        ''
      else
        "runHook postInstall"
    );

  postFixup =
  ''
      wrapProgram "$out/Applications/Zen Browser.app/Contents/MacOS/zen" --add-flags "--ProfileManager %u"
  '';

  src = fetchurl {
    name = "Zen Browser-${version}.dmg";
    inherit (zen-browser) url sha256;
  };
  meta = {
    description = "";
    homepage = "";
    platforms = lib.platforms.darwin;
  };
}
