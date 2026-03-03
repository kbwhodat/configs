{
    pkgs,
    inputs,
    config,
    ...
}: 
{
# nix configuration
# reference: https://daiderd.com/nix-darwin/manual/index.html#sec-options

  system.primaryUser = "katob";

  nix.enable = false;

  #services.nix-daemon.enable = true; # auto upgrade nix package and daemon service
    system = {
      defaults = {
        NSGlobalDomain.AppleICUForce24HourTime = true;
        menuExtraClock.Show24Hour = true;
        # Disable press-and-hold accent menu for Sublime Text (enable key repeat)
        CustomUserPreferences."com.sublimetext.4".ApplePressAndHoldEnabled = false;
        # Disable macOS screenshot shortcuts (Cmd+Shift+3/4) - used by Aerospace
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
    cocoapods
    # ollama
  ];

  launchd.user.agents.docker = {
    serviceConfig.ProgramArguments = [ "/Users/katob/.config/nix-config/os/darwin/scripts/start_colima.sh" ];
    serviceConfig.RunAtLoad = false;
    serviceConfig.KeepAlive = false;
    serviceConfig.StandardOutPath = "/tmp/colima.out";
    serviceConfig.StandardErrorPath = "/tmp/colima.err";
  };

#  launchd.user.agents.ollama = {
#    serviceConfig.ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
#    serviceConfig.KeepAlive = true;
#    serviceConfig.RunAtLoad = true;
#  };

  services.yabai.enable = false;
  services.yabai.enableScriptingAddition = false;
  services.skhd.enable = false;
  services.lorri.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupportedSystem = true; 

  # networking.dns = [ "208.67.222.123" ];
  networking.hostName = "macos-studio";

  services.nextdns = {
    enable = true;
    arguments = [
      "-config"
      "66f183"
    ];
  };

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts.roboto-mono
    pkgs.nerd-fonts.comic-shanns-mono
    pkgs.nerd-fonts.symbols-only
    nerd-fonts.commit-mono
  ];

  homebrew = {
    enable = true;
    onActivation.upgrade = true;
    onActivation.autoUpdate = true;
    onActivation.cleanup = "zap";

    taps = ["FelixKratz/formulae" "nikitabobko/tap"];
    brews = [ "firefoxpwa"];
    casks = [ "sublime-text" "ipvanish-vpn" "flutter" "karabiner-elements" "ungoogled-chromium" "freetube" "dbeaver-community" "hammerspoon" "gcloud-cli"];
  };

  nix.settings = {
    download-buffer-size = 524288000;
    allowed-users = ["root" "katob"];
    trusted-users = ["root" "katob"];
    
    # Performance optimizations
    max-jobs = "auto";
    cores = 0;
    http-connections = 50;
    max-substitution-jobs = 16;
    
    # Additional caches for faster binary fetches
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://chawan-nix-flake.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "chawan-nix-flake.cachix.org-1:guW77ag6Q9K4NVJ3gh5H4jsT4QlKfYAVooSFbDXAxD4="
    ];
  };

  # Increase system-wide file descriptor and process limits
  launchd.daemons.limit-maxfiles = {
    serviceConfig = {
      Label = "org.nixos.limit-maxfiles";
      ProgramArguments = [
        "launchctl"
        "limit"
        "maxfiles"
        "524288"
        "524288"
      ];
      RunAtLoad = true;
    };
  };

  launchd.daemons.limit-maxproc = {
    serviceConfig = {
      Label = "org.nixos.limit-maxproc";
      ProgramArguments = [
        "launchctl"
        "limit"
        "maxproc"
        "2048"
        "2048"
      ];
      RunAtLoad = true;
    };
  };

  system.stateVersion = 4;
}
