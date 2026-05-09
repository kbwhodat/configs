{ config, lib, pkgs, ... }:
let cfg = config.modules.browsers; in {
  options.modules.browsers.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Browsers bundle (firefox/floorp/zen/librewolf/chrome/etc.)";
  };

  imports = [
    ./firefox.nix
    ./floorp.nix
    ./chawan.nix
    ./browserpass.nix
    ./zen.nix
    ./librewolf.nix
    ./chrome.nix
    # ./helium.nix
    ./thorium.nix
    # ./ladybird.nix
  ];
}
