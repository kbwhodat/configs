{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenv) isDarwin;
  
  # pick ONE: classic (~/.emacs.d) or XDG (~/.config/emacs)
  useXDG = false;

  emacsDir = if useXDG then "${config.home.homeDirectory}/.config/emacs"
                        else "${config.home.homeDirectory}/.emacs.d";

  # EmacsClient.app wrapper for Raycast on macOS
  emacsClientApp = pkgs.stdenv.mkDerivation {
    pname = "EmacsClient";
    version = "1.0";
    
    dontUnpack = true;
    
    nativeBuildInputs = [ pkgs.imagemagick ];
    
    installPhase = ''
      mkdir -p "$out/Applications/EmacsClient.app/Contents/MacOS"
      mkdir -p "$out/Applications/EmacsClient.app/Contents/Resources"
      
      # Create the executable script
      cat > "$out/Applications/EmacsClient.app/Contents/MacOS/EmacsClient" << 'EOF'
#!/bin/bash
# Connect to emacs daemon, start one if not running
${config.programs.emacs.finalPackage}/bin/emacsclient -c -a "" "$@" &
EOF
      chmod +x "$out/Applications/EmacsClient.app/Contents/MacOS/EmacsClient"
      
      # Create Info.plist
      cat > "$out/Applications/EmacsClient.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>EmacsClient</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>org.gnu.EmacsClient</string>
    <key>CFBundleName</key>
    <string>EmacsClient</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
EOF

      # Copy Emacs icon if available, otherwise create a placeholder
      if [ -f "${config.programs.emacs.finalPackage}/Applications/Emacs.app/Contents/Resources/Emacs.icns" ]; then
        cp "${config.programs.emacs.finalPackage}/Applications/Emacs.app/Contents/Resources/Emacs.icns" \
           "$out/Applications/EmacsClient.app/Contents/Resources/AppIcon.icns"
      fi
    '';
  };

in {

  programs.emacs = {
    enable = true;
    package = pkgs.emacs; 
    extraPackages = epkgs: [
      epkgs.evil
      epkgs.evil-collection
      epkgs.which-key
      epkgs.general
      epkgs.persistent-scratch

      epkgs.evil-surround         
      epkgs.evil-markdown         
      epkgs.markup         
      epkgs.evil-nerd-commenter  
      epkgs.evil-exchange       
      epkgs.evil-matchit       
      epkgs.evil-args         
      epkgs.evil-easymotion  
      epkgs.avy             
      epkgs.evil-anzu      
      epkgs.undo-fu epkgs.undo-fu-session
      epkgs.deft
      epkgs.persp-mode
      epkgs.minions

      epkgs.vertico
      epkgs.orderless
      epkgs.marginalia
      epkgs.ewal-doom-themes
      epkgs.consult
      epkgs.ripgrep               
      epkgs.project              
    ];
  };

  home.file."${emacsDir}/early-init.el".source = ./doom/early-init.el;
  home.file."${emacsDir}/init.el".source = ./doom/init.el;

  home.file."${emacsDir}/themes/doom-alabaster-theme".source = 
    pkgs.fetchFromGitHub {
      owner = "kbwhodat";
      repo = "doom-alabaster-theme";
      rev = "master";           # or a pinned commit hash if you prefer
      sha256 = "sha256-FrREa0leAqOqC50hAH1uY8VMy+CMmsSjwPN9KJ5cuPo=";
    };

  # Run Emacs as a daemon - fixes slow startup due to unsigned binary on macOS
  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = false;
  };

  # Add EmacsClient.app to home packages (shows in ~/Applications/Home Manager Apps/)
  home.packages = lib.optionals isDarwin [ emacsClientApp ];
}
