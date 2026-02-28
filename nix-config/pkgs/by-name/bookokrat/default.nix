{ lib, stdenvNoCC, fetchurl, gnutar }:

let
  version = "0.3.6";

  release = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-JSn164JPJ+AYcfpVGiuntxlx1SwwxNUzxZ7JxKNebYM=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-S6tRXirmTIeovW1ClBnC7xJ8Ew3Gb5K7U+VC60rZFrU=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-MuBq1AkArT/g0db8RRPwQXZlTGAsYr225RolYj1YnNs=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-NSHjQuE4sIBNCenPOFZUtubOuAlU/nZJNVMdmFSefCU=";
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
