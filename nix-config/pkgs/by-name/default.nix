self: pkgs: let
  callPackage = pkgs.lib.callPackageWith (pkgs // self);
in {
  zen-browser-bin-darwin = callPackage ./zen-browser-bin-darwin {};
  zen-browser-unwrapped = callPackage ./zen-browser-bin {};
}
