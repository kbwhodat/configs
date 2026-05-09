{ config, lib, ... }:
let cfg = config.modules.editors; in {
  options.modules.editors.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Editors bundle (zed, neovim, helix, sublime)";
  };

  imports = [
    ./zed.nix
    ./neovim.nix
    ./helix.nix
    ./sublime.nix
  ];
}
