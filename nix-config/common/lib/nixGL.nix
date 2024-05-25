{ config, pkgs, lib, ... }:
{
  options = {
    nixGLPrefix = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Prepended wrapper for OpenGL applications.
      '';
    };

    nixgl = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      default = import ../lib/nixgl-wrapper.nix { inherit pkgs config; };
      readOnly = true;
    };
  };
}
