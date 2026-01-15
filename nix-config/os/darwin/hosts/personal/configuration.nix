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
    # ollama
  ];

  launchd.daemons."org.pqrs.vhid-daemon" = {
    serviceConfig = {
      ProgramArguments = [ vhidDaemon ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  launchd.daemons."org.pqrs.vhid-manager" = {
    serviceConfig = {
      ProgramArguments = [ vhidManager "activate" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.daemons.kanata = {
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
    onActivation.cleanup = "uninstall";

    taps = ["FelixKratz/formulae" "nikitabobko/tap"];
    brews = [ "firefoxpwa"];
    casks = [ "karabiner-elements" "ungoogled-chromium" "freetube" "dbeaver-community" "hammerspoon" "gcloud-cli"];

  };

  nix.settings.download-buffer-size = 524288000;
  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
