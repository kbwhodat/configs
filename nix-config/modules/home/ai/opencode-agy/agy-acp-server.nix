{ stdenvNoCC, fetchurl, unzip }:
stdenvNoCC.mkDerivation {
  pname = "agy-acp-server";
  version = "1.4.5";
  src = fetchurl {
    url = "https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-1.4.5-darwin-arm64.zip";
    sha256 = "886fff7767d08994ca39eb02c3d01a7532c7325a94aa33aaf52d52068733284f";
  };
  nativeBuildInputs = [ unzip ];
  dontStrip = true;
  dontPatchShebangs = true;
  dontFixup = true;
  unpackPhase = ''
    unzip "$src"
  '';
  installPhase = ''
    mkdir -p "$out/libexec/agy-acp" "$out/bin"
    install -m755 "$(find . -name agy_acp_server.par -type f -print -quit)" "$out/libexec/agy-acp/agy_acp_server.par"
    install -m755 "$(find . -name localharness_external -type f -print -quit)" "$out/libexec/agy-acp/localharness_external"
    cat > "$out/bin/agy-acp-server" <<EOF
    #!${stdenvNoCC.shell}
    cd "$out/libexec/agy-acp"
    exec "$out/libexec/agy-acp/agy_acp_server.par" "\$@"
    EOF
    chmod +x "$out/bin/agy-acp-server"
  '';
  meta.platforms = [ "aarch64-darwin" ];
}
