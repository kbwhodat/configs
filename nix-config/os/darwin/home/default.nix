{ inputs, config, lib, pkgs, ... }:

{
	imports = [
    ../../../common/sops
	../../../common
    ../../../pkgs
    ../../../common/personal
    ../../../common/macos
	];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "katob";
  home.homeDirectory = "/Users/katob";
  manual.html.enable = false;
  manual.manpages.enable = false;
  manual.json.enable = false;
  home.enableNixpkgsReleaseCheck = false;

  home.stateVersion = "25.11"; # Please read the comment before changing.

  #home.file."/Users/katob/.katotoken".source = config.sops.secrets."github-token".path;
  home.sessionVariables = {
    # EDITOR = "nvim";
  };

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
        nix-direnv.enable = true;
    };

    bash.enable = true; # see note on other shells below
  };

  programs.home-manager.enable = true;

  targets.darwin.copyApps.enable = true;
  targets.darwin.copyApps.enableChecks = false;

  home.activation.repairZenProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Zen profile repair on macOS:
    # Home Manager writes INI files as read-only symlinks, but Zen/Firefox-style
    # profile selection expects writable install/profile metadata.
    zen_dir="$HOME/Library/Application Support/zen"
    profiles_dir="$zen_dir/Profiles"
    main_profile="$profiles_dir/main"
    profiles_ini="$zen_dir/profiles.ini"
    installs_ini="$zen_dir/installs.ini"

    mkdir -p "$main_profile"

    if [ -L "$profiles_ini" ]; then
      rm -f "$profiles_ini"
    fi

    cat > "$profiles_ini" <<'EOF'
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=main
IsRelative=1
Path=Profiles/main
Default=1
EOF

    # Remove stale Install0 mapping and let Zen write install-hash mapping.
    rm -f "$installs_ini"

    # Cleanup old malformed Home Manager Apps entry created from DMG convenience
    # symlink named as a single space (" ") that points to /Applications.
    hm_apps="$HOME/Applications/Home Manager Apps"
    if [ -e "$hm_apps/ " ]; then
      rm -rf "$hm_apps/ "
    fi
  '';
}
