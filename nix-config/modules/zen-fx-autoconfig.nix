# NixOS module that provides a Zen Browser package with fx-autoconfig included
# Uses symlinkJoin to overlay fx-autoconfig files onto the Zen Browser package
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zen-fx-autoconfig;
  
  # Create a new package that combines Zen Browser with fx-autoconfig
  zenBrowserWithFxAutoconfig = pkgs.stdenvNoCC.mkDerivation {
    pname = "zen-browser-with-fx-autoconfig";
    version = cfg.zenBrowserPackage.version or "unknown";
    
    dontUnpack = true;
    dontBuild = true;
    
    installPhase = ''
      runHook preInstall
      
      # Copy the entire Zen Browser package
      cp -rs ${cfg.zenBrowserPackage}/* $out/
      
      # Make the necessary directories writable so we can add files
      chmod -R u+w $out
      
      # Find the actual browser directory (where zen binary lives)
      ZEN_BIN="$out/bin/zen"
      if [ -L "$ZEN_BIN" ]; then
        ZEN_REAL=$(readlink -f "$ZEN_BIN")
        ZEN_DIR=$(dirname "$ZEN_REAL")
      else
        ZEN_DIR="$out/lib/zen" 
      fi
      
      # Install fx-autoconfig files
      mkdir -p "$ZEN_DIR/defaults/pref"
      cp -f "${cfg.fxAutoconfigPackage}/fxautoconfig-program/config.js" "$ZEN_DIR/config.js"
      cp -f "${cfg.fxAutoconfigPackage}/fxautoconfig-program/defaults/pref/config-prefs.js" "$ZEN_DIR/defaults/pref/config-prefs.js"
      
      runHook postInstall
    '';
    
    meta = cfg.zenBrowserPackage.meta or {};
  };
in {
  options.programs.zen-fx-autoconfig = {
    enable = mkEnableOption "fx-autoconfig for Zen Browser";

    fxAutoconfigPackage = mkOption {
      type = types.package;
      default = pkgs.zenleap;
      description = "Package containing fx-autoconfig files (should have fxautoconfig-program directory)";
    };

    zenBrowserPackage = mkOption {
      type = types.package;
      description = "The Zen Browser package to install fx-autoconfig into";
    };
    
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = zenBrowserWithFxAutoconfig;
      description = "The final Zen Browser package with fx-autoconfig included";
    };
  };

  config = mkIf cfg.enable {
    # Make the wrapped package available system-wide
    environment.systemPackages = [ cfg.finalPackage ];
  };
}
