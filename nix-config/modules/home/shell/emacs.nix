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
    extraPackages = epkgs: with epkgs; [
      # ---- core completion / minibuffer ----
      vertico orderless marginalia consult

      # ---- in-buffer completion (NEW — popup as you type) ----
      corfu cape

      # ---- GC pause elimination (NEW) ----
      gcmh

      # ---- eglot LSP performance booster (NEW) ----
      eglot-booster

      # ---- evil + leader ----
      evil evil-collection evil-surround general which-key avy

      # ---- editing utilities ----
      undo-fu undo-fu-session tempel

      # ---- ui / theme ----
      doom-themes      # bug fix: init.el (require 'doom-themes) was unmet
      minions

      # ---- languages (py/sh/json/yaml/go ts-modes are built-in to emacs 30) ----
      nix-ts-mode markdown-mode

      # ---- tree-sitter grammars (.so files) — required by ts-modes ----
      # Earlier I assumed the nix emacs wrapper bundles grammars
      # automatically; it doesn't. Without this, opening a .sh / .py /
      # .json buffer with a *-ts-mode major-mode-remap triggers a
      # dlopen failure for libtree-sitter-bash.so etc.
      treesit-grammars.with-all-grammars

      # ---- IDE (eglot is built-in; treesit grammars auto-wired by nix) ----

      # ---- one-stop-shop additions ----
      magit vterm gptel elfeed pdf-tools notdeft

      # ---- jujutsu (jj VCS) integration ----
      vc-jj           # emacs vc.el backend for jj repos (C-x v d/l/v work)
      jjdescription   # major mode for jj commit-message buffers
      pkgs.nur.repos.kira-bruneau.emacsPackages.majutsu  # magit-style jj UI (NUR)

      # ---- workspaces / scratch ----
      persp-mode persistent-scratch

      # ---- perf measurement ----
      benchmark-init
    ];
  };

  home.file."${emacsDir}/early-init.el".source = ./emacs/early-init.el;
  home.file."${emacsDir}/init.el".source       = ./emacs/init.el;
  home.file."${emacsDir}/lisp" = {
    source    = ./emacs/lisp;
    recursive = true;
  };

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

  # Override home-manager's default KeepAlive ({Crashed=true; SuccessfulExit=false;})
  # with flat `true` — daemon ALWAYS restarts, including after a manual
  # (kill-emacs).  Trade-off: SPC q cannot truly kill the daemon while logged
  # in; launchctl bootout is the only escape hatch.
  launchd.agents.emacs.config.KeepAlive = lib.mkForce true;

  # launchd starts the daemon with a minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin),
  # so emacs subprocesses (jj via majutsu, ripgrep via consult-ripgrep, eglot
  # talking to pyright/gopls/nil, vterm shells) can't find binaries that nix
  # installed under the user / system profiles.  Inject the right PATH at the
  # launchd layer so the daemon — and everything it spawns — sees them.
  launchd.agents.emacs.config.EnvironmentVariables.PATH =
    lib.concatStringsSep ":" [
      "${config.home.homeDirectory}/.local/bin"                # uv-tool installs
      "/etc/profiles/per-user/${config.home.username}/bin"     # home-manager user profile
      "/run/current-system/sw/bin"                             # nix-darwin system profile
      "/nix/var/nix/profiles/default/bin"                      # default nix profile (fallback)
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];

  # Auto-bounce the emacs daemon after every home-manager activation
  # (i.e. every `darwin-rebuild switch`).  Without this, the running
  # daemon retains its OLD environment + OLD config until the user
  # manually runs:
  #   launchctl bootout  "gui/<UID>/org.nix-community.home.emacs"
  #   launchctl bootstrap "gui/<UID>" ~/Library/LaunchAgents/org.nix-community.home.emacs.plist
  # which is exactly what this activation script does, automatically.
  home.activation.bounceEmacsDaemon = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    PLIST="$HOME/Library/LaunchAgents/org.nix-community.home.emacs.plist"
    if [ -f "$PLIST" ]; then
      UID_NUM=$(id -u)
      $DRY_RUN_CMD /bin/launchctl bootout "gui/$UID_NUM/org.nix-community.home.emacs" 2>/dev/null || true
      $DRY_RUN_CMD /bin/launchctl bootstrap "gui/$UID_NUM" "$PLIST" 2>/dev/null || true
    fi
  '';

  # home-manager auto-trampolines Emacs.app from pkgs.emacs into
  # ~/Applications/Home Manager Apps/Emacs.app, which makes it appear in
  # Spotlight / Raycast / Hammerspoon alongside our EmacsClient.app.
  # Clicking it cold-starts a standalone Emacs disconnected from the
  # daemon — slow + confusing.  Remove it after every activation so
  # only EmacsClient.app is visible to macOS launchers.
  home.activation.hideStandaloneEmacsApp = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    EMACS_APP="$HOME/Applications/Home Manager Apps/Emacs.app"
    if [ -e "$EMACS_APP" ]; then
      $DRY_RUN_CMD rm -rf "$EMACS_APP"
    fi
  '';

  # Add EmacsClient.app to home packages (shows in ~/Applications/Home Manager Apps/)
  home.packages = (lib.optionals isDarwin [ emacsClientApp ]) ++ [
    pkgs.pyright
    pkgs.bash-language-server
    pkgs.gopls
    pkgs.nil
    pkgs.ruff
    pkgs.shfmt
    pkgs.nixfmt-rfc-style
    pkgs.xapian
    pkgs.emacs-lsp-booster   # rust JSON bridge for eglot-booster
  ];

  # Daemon-only flow: typing `emacs` in any shell goes through emacsclient.
  # -a '' auto-starts the daemon if not already running. vi/vim left alone.
  home.shellAliases.emacs = "emacsclient -c -a ''";
}
