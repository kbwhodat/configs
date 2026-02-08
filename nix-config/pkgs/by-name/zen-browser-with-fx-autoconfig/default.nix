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

    # Drop DMG convenience symlink to /Applications (often named as a single space).
    # Keeping it leaks host /Applications into Home Manager Apps as ".../Home Manager Apps/ /...".
    if [ -d "$out/Applications" ]; then
      for entry in "$out/Applications"/*; do
        if [ -L "$entry" ] && [ "$(readlink "$entry")" = "/Applications" ]; then
          rm -f "$entry"
        fi
      done
    fi

    # Find the browser resources directory.
    # Linux:   $out/lib/zen or $out/lib/zen-*
    # macOS:   $out/Applications/*.app/Contents/Resources
    ZEN_DIR=""
    APP_DIR=""
    if [ -d "$out/Applications/Zen.app/Contents/Resources" ]; then
      APP_DIR="$out/Applications/Zen.app"
      ZEN_DIR="$APP_DIR/Contents/Resources"
    elif [ -d "$out/Applications/Zen Browser.app/Contents/Resources" ]; then
      APP_DIR="$out/Applications/Zen Browser.app"
      ZEN_DIR="$APP_DIR/Contents/Resources"
    else
      for app in "$out"/Applications/*.app; do
        if [ -d "$app/Contents/Resources" ]; then
          APP_DIR="$app"
          ZEN_DIR="$app/Contents/Resources"
          break
        fi
      done

      for dir in $out/lib/zen $out/lib/zen-*; do
        if [ -d "$dir" ]; then
          ZEN_DIR="$dir"
          break
        fi
      done
    fi

    # Ensure the directory exists
    if [ -n "$ZEN_DIR" ] && [ -d "$ZEN_DIR" ]; then
      echo "Found ZEN_DIR: $ZEN_DIR"
      
      # Create defaults/pref directory
      mkdir -p "$ZEN_DIR/defaults/pref"
      
      # Check for existing autoconfig setup
      if [ -f "$ZEN_DIR/mozilla.cfg" ]; then
        # mozilla.cfg exists - append fx-autoconfig bootstrap
        echo "Appending fx-autoconfig to existing mozilla.cfg"
        cat "${zenleap}/fxautoconfig-program/config.js" >> "$ZEN_DIR/mozilla.cfg"
        
        # Create pref file to load mozilla.cfg
        cat > "$ZEN_DIR/defaults/pref/90-zenleap-autoconfig.js" <<'EOF'
pref("general.config.filename", "mozilla.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
EOF
        
      elif [ -f "$ZEN_DIR/defaults/pref/autoconfig.js" ]; then
        # autoconfig.js exists - create mozilla.cfg and link it
        echo "Creating mozilla.cfg (autoconfig.js exists)"
        echo '// First line must be a comment' > "$ZEN_DIR/mozilla.cfg"
        cat "${zenleap}/fxautoconfig-program/config.js" >> "$ZEN_DIR/mozilla.cfg"
        
        # Ensure autoconfig.js loads mozilla.cfg
        if ! grep -q "general.config.filename" "$ZEN_DIR/defaults/pref/autoconfig.js" 2>/dev/null; then
          echo 'pref("general.config.filename", "mozilla.cfg");' >> "$ZEN_DIR/defaults/pref/autoconfig.js"
          echo 'pref("general.config.obscure_value", 0);' >> "$ZEN_DIR/defaults/pref/autoconfig.js"
          echo 'pref("general.config.sandbox_enabled", false);' >> "$ZEN_DIR/defaults/pref/autoconfig.js"
        fi
        
      else
        # No autoconfig system exists - create complete bootstrap
        echo "Creating complete autoconfig bootstrap (macOS standalone)"
        
        # Create autoconfig.js that loads mozilla.cfg
        cat > "$ZEN_DIR/defaults/pref/autoconfig.js" <<'EOF'
// Bootstrap fx-autoconfig
pref("general.config.filename", "mozilla.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
EOF
        
        # Create mozilla.cfg with fx-autoconfig bootstrap
        echo '// First line must be a comment - fx-autoconfig bootstrap' > "$ZEN_DIR/mozilla.cfg"
        cat "${zenleap}/fxautoconfig-program/config.js" >> "$ZEN_DIR/mozilla.cfg"
        
        # Add zenleap loader line with newline
        printf "\n// Load zenleap\ntry { ChromeUtils.importESModule(\"chrome://userchromejs/content/boot.sys.mjs\"); } catch(e) {}\n" >> "$ZEN_DIR/mozilla.cfg"
      fi
      
      echo "fx-autoconfig installation complete in $ZEN_DIR"
    else
      echo "Warning: Could not find zen browser lib directory"
      echo "Available directories:"
      find $out -type d -maxdepth 3
      exit 1
    fi

    # macOS: Strip original signature, modify, then re-sign ad-hoc
    # This prevents "damaged" errors while allowing fx-autoconfig injection
    if [ -n "$APP_DIR" ] && [ -d "$APP_DIR" ]; then
      if command -v codesign >/dev/null 2>&1; then
        echo "Stripping original signature from: $APP_DIR"
        codesign --remove-signature "$APP_DIR" 2>/dev/null || true
        
        echo "Re-signing app after fx-autoconfig injection: $APP_DIR"
        codesign --force --deep --sign - "$APP_DIR"
        codesign --verify --deep --strict "$APP_DIR" || true
      else
        echo "Warning: codesign not found; macOS app bundle may fail Gatekeeper validation"
      fi
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
