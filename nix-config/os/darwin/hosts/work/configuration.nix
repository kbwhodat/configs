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
    libiconv-darwin
    python311
  ];

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

  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards.keychron = {
      config = builtins.readFile ../../../../../kanata/kanata.kbd;
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts.roboto-mono
    pkgs.nerd-fonts.comic-shanns-mono
    pkgs.nerd-fonts.symbols-only
  ];

  # fonts.packages = with pkgs; [
  #  (nerdfonts.override {
  #    fonts = [
  #      "RobotoMono"
  #      "ComicShannsMono"
  #    ];
  #  })
  # ];
  #fonts.fontconfig = {
  #  defaultFonts = {
  #      serif = [ "RobotoMono Nerd Font Propo"];
  #      sansSerif = [ "RobotoMono Nerd Font Propo"];
  #      monospace = [ "RobotoMono Nerd Font"];
  #  };
  #};

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    taps = ["homebrew/services" "FelixKratz/formulae" "nikitabobko/tap"];
    brews = [ "firefoxpwa" "colima" "terragrunt" "helm" "kubectl"];
    casks = [ "aerospace" "dbeaver-community" "firefox" "obsidian" "vlc" "hyperkey" "hammerspoon" "webcatalog" "raycast" "chromium" "gcloud-cli"];
  };

  nix.settings.download-buffer-size = 524288000;
  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
