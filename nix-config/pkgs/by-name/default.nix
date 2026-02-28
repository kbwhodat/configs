self: pkgs: let
  callPackage = pkgs.lib.callPackageWith (pkgs // self);
in {
  zen-browser-bin-darwin = callPackage ./zen-browser-bin-darwin {};
  zen-browser-unwrapped = callPackage ./zen-browser-bin {};
  zenleap = callPackage ./zenleap {};
  wrapZenBrowserWithFxAutoconfig = callPackage ./zen-browser-with-fx-autoconfig {};
  bookokrat = callPackage ./bookokrat {};
}
