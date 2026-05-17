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
# Idempotent: focus an existing GUI frame if one is open, else create one.
# `-c -a ""' alone ALWAYS spawns a new frame — clicking the .app icon
# (or hitting the Hammerspoon hotkey) twice piled up duplicate frames.
# `my/raise-or-make-frame' is defined in config-ui.el.
exec ${config.programs.emacs.finalPackage}/bin/emacsclient \
     -n -a "" --eval "(my/raise-or-make-frame)" "$@"
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

      # ---- file-tree sidebar (SPC e) ----
      treemacs treemacs-evil treemacs-magit nerd-icons

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
      pkgs.nur.repos.kira-bruneau.emacsPackages.majutsu  # magit-style jj UI (NUR)

      # ---- workspaces / scratch ----
      persp-mode persistent-scratch

      # ---- daily-driver additions ----
      envrc            # direnv -> emacs subprocess env (LSP, compile, vterm)
      embark           # actions on minibuffer candidates (C-. / C-;)
      embark-consult   # bridges consult results into embark actions
      wgrep            # batch-edit consult-ripgrep results via embark-export
      helpful          # richer describe-* buffers (callers, refs, source)
      apheleia         # format-on-save via subprocess (ruff/prettier/shfmt/...)

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
      "/opt/homebrew/bin"                                      # Apple Silicon Homebrew (chawan, etc.)
      "/usr/local/bin"                                         # Intel Homebrew (kept for x86 fallback)
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
  # --- Stable code-signing for TCC trust across rebuilds ---------------
  # macOS TCC keys per-binary permissions on the binary's cdhash and
  # csreq.  nix produces a NEW cdhash for emacs on every rebuild, so
  # TCC keeps re-prompting "allow access to Documents" etc. on the
  # first file open after each rebuild.
  #
  # Root cause: macOS TCC tracks consent by (binary path, cdhash) for
  # non-.app binaries.  nix puts emacs at /nix/store/<hash>-emacs-*/
  # bin/emacs — that path changes every rebuild, so TCC sees a "new"
  # binary and re-prompts.
  #
  # Fix (cert-free): copy the nix emacs binary (and the wrapper script
  # that sets EMACSLOADPATH) to a STABLE path in ~/.local/bin/, and
  # point the launchd daemon at that path.  `cp` preserves the
  # ad-hoc signature nix already applied, so the cdhash is identical
  # to the source — TCC sees the same identity at a stable path.
  #
  # One-time setup: System Settings → Privacy & Security → Full Disk
  # Access → +  → choose ~/.local/bin/emacs-stable (Shift+Cmd+. to
  # show hidden dirs in the file picker).  That FDA grant persists
  # across all future rebuilds — the only time it'll re-prompt is
  # when emacs itself is upgraded to a new version (cdhash changes).
  # Point the daemon at the stable-path wrapper instead of the
  # nix-store path so the daemon's binary identity is stable across
  # rebuilds and TCC consent persists.
  launchd.agents.emacs.config.ProgramArguments = lib.mkForce [
    "/bin/sh" "-c"
    ''/bin/wait4path "$HOME/.local/bin/emacs-stable-launch" && exec "$HOME/.local/bin/emacs-stable-launch" --fg-daemon''
  ];

  # Combined TCC-stabilize + daemon-bounce activation.  Runs dead-last
  # (after every HM phase we care about) and is fully fail-soft so a
  # single broken step never aborts activation.
  #
  # Fail-soft pattern: each command is followed by `|| true`, and the
  # whole block runs inside `set +e` so HM's outer `set -eu` doesn't
  # halt on the first non-zero exit.
  # All paths baked at eval time — no runtime path discovery needed.
  # ${pkgs.emacs} = real emacs store; cp -L follows the bin/emacs -> emacs-XX.X symlink.
  # native-lisp lives at <store>/lib/emacs/<version>/native-lisp — glob picks the version dir.
  # The inner shell wrapper `.emacs-wrapped` lives in the wrapped (with-packages) derivation.
  home.activation.stabilizeEmacsAndBounce = lib.hm.dag.entryAfter [
    "writeBoundary" "linkGeneration" "setupLaunchAgents"
    "reloadSystemd" "hideStandaloneEmacsApp"
  ] ''
    set +e
    BIN="$HOME/.local/bin"
    mkdir -p "$BIN"

    /bin/cp -fL ${pkgs.emacs}/bin/emacs       "$BIN/emacs-stable"
    /bin/cp -fL ${pkgs.emacs}/bin/emacsclient "$BIN/emacsclient-stable"
    /bin/chmod u+rwx "$BIN/emacs-stable" "$BIN/emacsclient-stable"

    NATIVE_LISP=$(ls -d ${pkgs.emacs}/lib/emacs/*/native-lisp 2>/dev/null | /usr/bin/head -1)
    [ -n "$NATIVE_LISP" ] && /bin/ln -sfn "$NATIVE_LISP" "$HOME/.local/native-lisp"

    /usr/bin/sed "s|exec ${pkgs.emacs}/bin/emacs |exec $BIN/emacs-stable |g" \
      ${config.programs.emacs.finalPackage}/bin/.emacs-wrapped > "$BIN/emacs-stable-launch"
    /bin/chmod u+rwx "$BIN/emacs-stable-launch"

    # Atomic restart via kickstart -k (kill + relaunch from already-loaded
    # plist).  If the service somehow isn't loaded (orphaned state after a
    # prior failure), fall back to bootstrap.  No bootout/bootstrap race.
    PLIST="$HOME/Library/LaunchAgents/org.nix-community.home.emacs.plist"
    if [ -f "$PLIST" ]; then
      UID_NUM=$(id -u)
      SVC="gui/$UID_NUM/org.nix-community.home.emacs"
      if /bin/launchctl print "$SVC" >/dev/null 2>&1; then
        /bin/launchctl kickstart -k "$SVC" >/dev/null 2>&1
      else
        /bin/launchctl bootstrap "gui/$UID_NUM" "$PLIST" >/dev/null 2>&1
      fi
    fi
    set -e
    true
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
