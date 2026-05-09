{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.email.matcha;

  # matcha's go.mod requires `go 1.26.3` but no nixpkgs channel currently
  # ships Go 1.26.3 (stable nixpkgs is on 1.26.2, unstable on 1.26.1).
  # We patch the go.mod minimum down to 1.26 (Go is forward-compatible
  # within a major.minor for our purposes) and disable Go's toolchain
  # auto-download, which the Nix sandbox blocks anyway.
  matchaPkg =
    (inputs.matcha.packages.${pkgs.stdenv.hostPlatform.system}.default)
      .overrideAttrs (old: {
        env = (old.env or { }) // { GOTOOLCHAIN = "local"; };
        postPatch = (old.postPatch or "") + ''
          substituteInPlace go.mod \
            --replace-fail "go 1.26.3" "go 1.26"
          if grep -q '^toolchain ' go.mod; then
            sed -i '/^toolchain /d' go.mod
          fi
        '';
      });
in {
  options.modules.email.matcha.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Matcha — terminal email client (https://github.com/floatpane/matcha)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ matchaPkg ];
  };
}
