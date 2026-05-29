{ lib, stdenvNoCC, fetchurl, gnutar }:

let
  version = "0.3.11";

  release = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-PJUbNHGoxMstqmZmg01KToAlHJDfKdUnULpAld59AjQ=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-2yywG2AFBbGHg6nfd7dalb7WqtSLMnbzxOyPrJgEz84=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-yUBTHstOzrDWux0RlxQeAkn51tJzjfHY7olINjTosqc=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-8yqxqq8ne7/Sd+l3KHjwc1F7r1t2S/zyQxzwa8nsCoY=";
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
