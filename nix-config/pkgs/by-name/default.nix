self: pkgs: let
  callPackage = pkgs.lib.callPackageWith (pkgs // self);
in {
  zen-browser-bin = callPackage ./zen-browser-bin {};
}
