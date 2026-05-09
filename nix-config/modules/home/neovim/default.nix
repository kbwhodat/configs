{ pkgs, lib, config, ... }:
let cfg = config.modules.neovim; in {
  options.modules.neovim.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Neovim runtime dependencies (image, pkg-config)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      pkg-config
      imagemagick
      imagemagick.dev
    ];
  };
}
