{
    pkgs,
    ...
}: {
# nix configuration
# reference: https://daiderd.com/nix-darwin/manual/index.html#sec-options


  services.nix-daemon.enable = true; # auto upgrade nix package and daemon service
    system = {
      defaults = {
        menuExtraClock.Show24Hour = true;
      };
    };

  security.pam.enableSudoTouchIdAuth = true;

  environment.systemPackages = with pkgs; [ 
    pinentry_mac
    # yabai
    docker-client
    # skhd
    iina
    colima
    lima
    libiconv-darwin
    ollama
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

  launchd.user.agents.ollama = {
    serviceConfig.ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
    serviceConfig.KeepAlive = true;
    serviceConfig.RunAtLoad = true;
  };

  services.yabai.enable = false;
  services.yabai.enableScriptingAddition = false;
  services.skhd.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true; 

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts.roboto-mono
    pkgs.nerd-fonts.comic-shanns-mono
    pkgs.nerd-fonts.symbols-only
    nerd-fonts.commit-mono
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    taps = ["homebrew/services" "FelixKratz/formulae" "nikitabobko/tap"];
    brews = [ "kanata" "firefoxpwa" "colima"];
    casks = [ "karabiner-elements" "clocker" "aerospace" "dbeaver-community" "obsidian" "vlc" "hyperkey" "hammerspoon" "webcatalog" "raycast" "ungoogled-chromium" "gcloud-cli"];
  };

  nix.settings.download-buffer-size = 524288000;
  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
