{ config, lib, ... }:
let cfg = config.modules.email; in {
  imports = [
    ./matcha.nix
  ];

  options.modules.email.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Email clients umbrella (currently: matcha)";
  };

  # Sub-modules under ./*.nix are gated by their own enable flags.
  # Nothing else lives at the umbrella level right now.
}
