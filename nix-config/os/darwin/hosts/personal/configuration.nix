{
    pkgs,
    ...
}: 
let
  kanataCfg = "/Users/katob/.config/kanata/kanata.kbd";

  # Karabiner DriverKit VirtualHIDDevice locations (from the installer pkg)
  vhidDaemon =
    "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/" +
    "Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";

  vhidManager =
    "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/" +
    "Karabiner-VirtualHIDDevice-Manager";
in
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

  # launchd.daemons."org.pqrs.vhid-daemon" = {
  #   serviceConfig = {
  #     ProgramArguments = [ vhidDaemon ];
  #     RunAtLoad = false;
  #     KeepAlive = false;
  #   };
  # };
  #
  # launchd.daemons."org.pqrs.vhid-manager" = {
  #   serviceConfig = {
  #     ProgramArguments = [ vhidManager "activate" ];
  #     RunAtLoad = false;
  #     KeepAlive = false;
  #   };
  # };

  environment.etc."sudoers.d/kanata".text = ''
    katob ALL=(root) NOPASSWD: ${pkgs.kanata}/bin/kanata
  '';

  launchd.daemons.kanata = {
    serviceConfig.ProgramArguments = [
      "/usr/bin/sudo"
        "-n"
        "${pkgs.kanata}/bin/kanata"
        "-c"
        "/Users/katob/.config/kanata/kanata.kbd"
    ];
    serviceConfig.RunAtLoad = false;
    serviceConfig.KeepAlive = false;
    serviceConfig.StandardOutPath = "/tmp/kanata.out";
    serviceConfig.StandardErrorPath = "/tmp/kanata.err";
  };

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

  nixpkgs.config.allowUnfree = true;
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

  nix.settings.download-buffer-size = 524288000;
  nix.settings.allowed-users = ["root" "katob"];

  # Increase system ulimits using native nix-darwin options
  # Setting NumberOfFiles/NumberOfProcesses on a system daemon sets kern.maxfiles/kern.maxproc
  launchd.daemons.sysctl-limits = {
    script = "while true; do sleep 86400; done";
    serviceConfig = {
      Label = "org.nixos.sysctl-limits";
      RunAtLoad = true;
      KeepAlive = true;
      SoftResourceLimits = {
        NumberOfFiles = 524288;
        NumberOfProcesses = 2048;
      };
      HardResourceLimits = {
        NumberOfFiles = 524288;
        NumberOfProcesses = 2048;
      };
    };
  };
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
