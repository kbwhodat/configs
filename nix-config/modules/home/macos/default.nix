{ config, lib, ... }:
let cfg = config.modules.macos; in {
  options.modules.macos.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "macOS-specific home-manager modules (aerospace, hammerspoon, xcode)";
  };

  imports = [
    # ./raycast.nix
    ./aerospace.nix
    # ./karabiner.nix
    # ./colima.nix
    ./hidutil.nix
    ./xcode.nix
    ./hammerspoon.nix
  ];
}
