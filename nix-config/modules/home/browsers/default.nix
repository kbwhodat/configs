{ config, lib, pkgs, ... }:
let cfg = config.modules.browsers; in {
  options.modules.browsers.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Browsers bundle (firefox/floorp/zen/librewolf/chrome/etc.)";
  };

  # Per-browser gate for PERSONAL browsers, referenced from the
  # bare-config sub-files.  Default true = personal hosts unchanged;
  # profiles/home/work.nix flips it off so work never receives them.
  options.modules.browsers.zen.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Zen browser (personal — off on work hosts)";
  };

  imports = [
    ./firefox.nix
    ./floorp.nix
    ./chawan.nix
    ./zen.nix
    ./librewolf.nix
    ./chrome.nix
    # ./helium.nix
    ./thorium.nix
    # ./ladybird.nix
  ];
}
