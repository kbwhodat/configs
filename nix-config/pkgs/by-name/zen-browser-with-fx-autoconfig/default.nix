{ lib, stdenvNoCC, zenleap, gnused }:

# Function that takes a zen-browser package and returns it with fx-autoconfig
zenBrowserPkg:

stdenvNoCC.mkDerivation {
  pname = "zen-browser-with-fx-autoconfig";
  version = zenBrowserPkg.version or "unknown";

  nativeBuildInputs = [ gnused ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Create output directory first
    mkdir -p $out
    
    # Copy the entire Zen Browser package structure
    cp -r ${zenBrowserPkg}/* $out/
    
    # Make everything writable so we can modify it
    chmod -R u+w $out

    # Find the browser resources directory.
    # Linux:   $out/lib/zen or $out/lib/zen-*
    # macOS:   $out/Applications/Zen Browser.app/Contents/Resources
    ZEN_DIR=""
    if [ -d "$out/Applications/Zen Browser.app/Contents/Resources" ]; then
      ZEN_DIR="$out/Applications/Zen Browser.app/Contents/Resources"
    else
      for dir in $out/lib/zen $out/lib/zen-*; do
        if [ -d "$dir" ]; then
          ZEN_DIR="$dir"
          break
        fi
      done
    fi

    # Ensure the directory exists
    if [ -n "$ZEN_DIR" ] && [ -d "$ZEN_DIR" ]; then
      # Force autoconfig prefs for Zen release builds.
      # This ensures mozilla.cfg is loaded and sandbox is disabled.
      mkdir -p "$ZEN_DIR/defaults/pref"
      cat > "$ZEN_DIR/defaults/pref/90-zenleap-autoconfig.js" <<'EOF'
pref("general.config.filename", "mozilla.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
EOF

      # Zen Browser already has autoconfig.js that loads mozilla.cfg
      # So we append the fx-autoconfig bootstrap code to mozilla.cfg
      # instead of creating a separate config.js + config-prefs.js
      if [ -f "$ZEN_DIR/mozilla.cfg" ]; then
        # Append fx-autoconfig bootstrap to existing mozilla.cfg
        cat "${zenleap}/fxautoconfig-program/config.js" >> "$ZEN_DIR/mozilla.cfg"
        echo "fx-autoconfig appended to existing mozilla.cfg in $ZEN_DIR"
      else
        # No mozilla.cfg exists, check if autoconfig.js references it
        if [ -f "$ZEN_DIR/defaults/pref/autoconfig.js" ]; then
          # Create mozilla.cfg with the fx-autoconfig bootstrap
          echo '// First line must be a comment' > "$ZEN_DIR/mozilla.cfg"
          cat "${zenleap}/fxautoconfig-program/config.js" >> "$ZEN_DIR/mozilla.cfg"
          echo "fx-autoconfig: created mozilla.cfg in $ZEN_DIR"
        else
          # No autoconfig system exists, install fx-autoconfig's own config files
          mkdir -p "$ZEN_DIR/defaults/pref"
          cp -f "${zenleap}/fxautoconfig-program/config.js" "$ZEN_DIR/config.js"
          cp -f "${zenleap}/fxautoconfig-program/defaults/pref/config-prefs.js" "$ZEN_DIR/defaults/pref/config-prefs.js"
          echo "fx-autoconfig installed to $ZEN_DIR"
        fi
      fi
    else
      echo "Warning: Could not find zen browser lib directory"
      echo "Available directories:"
      find $out -type d -maxdepth 3
      exit 1
    fi

    # Fix wrapper scripts to point to our modified package instead of the original.
    # (Mainly relevant on Linux where wrappers live in $out/bin.)
    for wrapper in $out/bin/*; do
      if [ -f "$wrapper" ] && grep -q "${zenBrowserPkg}" "$wrapper" 2>/dev/null; then
        echo "Fixing paths in wrapper: $wrapper"
        sed -i "s|${zenBrowserPkg}|$out|g" "$wrapper"
      fi
    done

    runHook postInstall
  '';

  meta = zenBrowserPkg.meta or {} // {
    description = "Zen Browser with fx-autoconfig for userscript support";
  };
}
