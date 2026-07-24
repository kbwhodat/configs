{ lib, stdenvNoCC, fetchurl, gnutar }:

let
  version = "0.3.12";
  release = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-ee6a+2h2XSLFS43aH8XWahT0i5BW6utkDJOkEcgxOdU=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-EUc5YZqoUFFWY1j7L8PDaEDS53kgqAuNcxCxVGUIlnY=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-9UX5cWopQy8VuptSs4UFDO9XMEmnIqo0J9guZ1laJAk=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-TTR/igyIyeXHLO6NLJMpdAMaeG7l65uneIpdNTVeXtk=";
    };
  }.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system for bookokrat prebuilt binary");
in
stdenvNoCC.mkDerivation {
  pname = "bookokrat";
  inherit version;

  src = fetchurl {
    url = "https://github.com/bugzmanov/bookokrat/releases/download/v${version}/bookokrat-v${version}-${release.target}.tar.gz";
    hash = release.hash;
  };

  dontUnpack = true;
  nativeBuildInputs = [ gnutar ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    tar -xzf "$src"
    install -m755 bookokrat "$out/bin/bookokrat"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Terminal-based ebook reader";
    homepage = "https://github.com/bugzmanov/bookokrat";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "bookokrat";
  };
}
