{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.5.7.1";
  pname = "helium";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-A+fNcW7ujbeYqOb+gxzQ0p19J14csfFyok0RVRFxo60=";
  };

  appimageContents = appimageTools.extract { inherit pname src version; };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

    extraInstallCommands = ''
          install -m 444 -D ${appimageContents}/helium.desktop $out/share/applications/helium.desktop

              install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/256x256/apps/helium.png \
      $out/share/icons/hicolor/256x256/apps/helium.png


      substituteInPlace $out/share/applications/helium.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'


    '';



  meta = {
    description = "Private, fast, and honest web browser based on Chromium";
    homepage = "https://github.com/imputnet/helium-linux";
    downloadPage = "https://github.com/imputnet/helium-linux/releases";
    license = lib.licenses.gpl3;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ onny ];
    platforms = [ "x86_64-linux" ];
  };
}
