# Darwin-specific overlays to avoid building heavy packages from source
self: super: {
  # Stub out gdb on Darwin - it takes hours to build and is rarely needed
  # If you actually need gdb, comment this out
  gdb = super.runCommand "gdb-stub" { } ''
    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/gdb
    echo 'echo "gdb is not installed. Remove the stub in pkgs/darwin-overlay.nix to build it."' >> $out/bin/gdb
    chmod +x $out/bin/gdb
  '';
}
