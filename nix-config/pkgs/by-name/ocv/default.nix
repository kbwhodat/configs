{ lib, stdenv, stdenvNoCC, fetchurl, autoPatchelfHook }:
let
  ocvRelease = "v1.14.25-ocv.3.28";
  ocvAssets = {
    "aarch64-darwin" = { asset = "ocv-darwin-arm64"; sha256 = "d81f5a159dffc5126aa861385ed105adf7420f1e299ca32529c4a33d06d448a8"; };
    "x86_64-darwin"  = { asset = "ocv-darwin-x64";   sha256 = "72a78491aaa621f6ef47d09a6a8f9d322e69a5dab505250246a4354b00d8cb1a"; };
    "aarch64-linux"  = { asset = "ocv-linux-arm64";  sha256 = "b3f6bbe99d6fb9c5a74c76f6489dea8636e3b8c07826956469c2580494eb56d0"; };
    "x86_64-linux"   = { asset = "ocv-linux-x64";    sha256 = "338c89d95bada61965fed79099360ce853b8875522805c0bbe19f20beff152e7"; };
  };
  a = ocvAssets.${stdenv.hostPlatform.system}
    or (throw "ocv: unsupported system ${stdenv.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "ocv";
  version = lib.removePrefix "v" ocvRelease;
  src = fetchurl {
    url = "https://github.com/leohenon/opencode-vim/releases/download/${ocvRelease}/${a.asset}";
    sha256 = a.sha256;
  };
  dontUnpack = true;
  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];
  installPhase = ''
    mkdir -p $out/bin
    install -m755 $src $out/bin/opencode
  '';
  meta = with lib; {
    description = "Prebuilt opencode-vim binary";
    mainProgram = "opencode";
    platforms = lib.attrNames ocvAssets;
  };
}
