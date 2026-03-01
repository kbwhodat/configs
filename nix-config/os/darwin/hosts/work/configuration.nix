{
    pkgs,
    inputs,
    config,
    ...
}:

let
myrepo = builtins.fetchGit {
  url = "https://github.com/kbwhodat/pass-keys.git";
  ref = "main";
  rev = "10fb8bcdaff679ee2a12d26f89ec4bba7909f64b";
};
in
{
  environment.etc.".secrets".source = "${myrepo}";

  system.primaryUser = "katob";

  nix.enable = true; # auto upgrade nix package and daemon service
    system = {
      defaults = {
        menuExtraClock.Show24Hour = true;
        # Disable press-and-hold accent menu for Sublime Text (enable key repeat)
        CustomUserPreferences."com.sublimetext.4".ApplePressAndHoldEnabled = false;
        # Disable macOS screenshot shortcuts (Cmd+Shift+3/4/5) - used by Aerospace
        # Disable Spotlight shortcut (Cmd+Space) - used by Raycast
        CustomUserPreferences."com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "28" = { enabled = false; };  # Cmd+Shift+3 screenshot to file
            "29" = { enabled = false; };  # Cmd+Ctrl+Shift+3 screenshot to clipboard
            "30" = { enabled = false; };  # Cmd+Shift+4 selection to file
            "31" = { enabled = false; };  # Cmd+Ctrl+Shift+4 selection to clipboard
            "64" = { enabled = false; };  # Cmd+Space Spotlight search
            "65" = { enabled = false; };  # Cmd+Option+Space Finder search
            "184" = { enabled = false; }; # Cmd+Shift+5 screenshot/recording options
          };
        };
      };
    };

  security.pam.services.sudo_local.touchIdAuth = true;

  # ids.uids.nixbld = 301;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment.systemPackages = with pkgs; [
    pinentry_mac
    # yabai
    docker-client
    # skhd
    iina
    colima
    lima
    darwin.libiconv
    python313
  ];

  launchd.user.agents.kanata = {
    serviceConfig.ProgramArguments = [
      "${pkgs.kanata}/bin/kanata"
      "-c"
      "/Users/katob/.config/kanata/kanata.kbd"
    ];
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = false;
    serviceConfig.StandardOutPath = "/tmp/kanata.out";
    serviceConfig.StandardErrorPath = "/tmp/kanata.err";
  };

  launchd.user.agents.docker = {
    serviceConfig.ProgramArguments = [ "/Users/katob/.config/nix-config/os/darwin/scripts/start_colima.sh" ];
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = false;
    serviceConfig.StandardOutPath = "/tmp/colima.out";
    serviceConfig.StandardErrorPath = "/tmp/colima.err";
  };

  services.yabai.enable = false;
  services.yabai.enableScriptingAddition = true;
  services.skhd.enable = false;
  services.lorri.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts.roboto-mono
    pkgs.nerd-fonts.comic-shanns-mono
    pkgs.nerd-fonts.symbols-only
    nerd-fonts.commit-mono
  ];

  homebrew = {
    enable = true;
    # onActivation.cleanup = "uninstall";

    taps = ["homebrew/services" "FelixKratz/formulae" "nikitabobko/tap"];
    brews = [ "opencode" "kanata" "firefoxpwa" "colima" "terragrunt" "helm" "kubectl"];
    casks = [ "freetube" "mitmproxy" "helium-browser" "karabiner-elements" "clocker" "aerospace" "zed" "dbeaver-community" "obsidian" "vlc" "hammerspoon" "raycast" "ungoogled-chromium" "gcloud-cli"];
  };

  nix.settings.download-buffer-size = 524288000;
  nix.settings.ssl-cert-file = "/etc/nix/cache-nixos-org.pem";
  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
