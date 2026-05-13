{ stdenv, lib, fetchurl }:

let
  version = "3.5.21";
  baseUrl = "https://github.com/yvgude/lean-ctx/releases/download/v${version}";

  sources = {
    "aarch64-darwin" = {
      url = "${baseUrl}/lean-ctx-aarch64-apple-darwin.tar.gz";
      sha256 = "ca253a88267b35960d1fa968990df1a52704d104da3a783d1ecb1e4ecd23a45e";
    };
    "x86_64-darwin" = {
      url = "${baseUrl}/lean-ctx-x86_64-apple-darwin.tar.gz";
      sha256 = "3a3343084d7ff1efb8e61715dd461348ac8b88e6d49a0745e538b477b87b36d3";
    };
    "aarch64-linux" = {
      url = "${baseUrl}/lean-ctx-aarch64-unknown-linux-musl.tar.gz";
      sha256 = "39734dc005f20a9ac8acee3d24979566006543fdb1203ec03933b3f70804d235";
    };
    "x86_64-linux" = {
      url = "${baseUrl}/lean-ctx-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "48f1f4851410629618c586f1b1cf500135d4a1c56ba973ae849932c697f7c223";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "lean-ctx: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "lean-ctx";
  inherit version;

  src = fetchurl { inherit (source) url sha256; };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 lean-ctx $out/bin/lean-ctx
    runHook postInstall
  '';

  meta = with lib; {
    description = "Token-saving compression CLI for AI coding agents";
    homepage = "https://leanctx.com";
    license = with licenses; [ asl20 mit ];
    mainProgram = "lean-ctx";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
  };
}
