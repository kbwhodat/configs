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

  services.nix-daemon.enable = true; # auto upgrade nix package and daemon service
    system = {
      defaults = {
        menuExtraClock.Show24Hour = true;
      };
    };

  security.pam.enableSudoTouchIdAuth = true;

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
    lima-bin
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
  services.skhd.enable = true;
  services.lorri.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # fonts.packages = with pkgs; [
  #   pkgs.nerd-fonts.roboto-mono
  #   pkgs.nerd-fonts.comic-shanns-mono
  # ];

  fonts.packages = with pkgs; [
   (nerdfonts.override {
     fonts = [
       "RobotoMono"
       "ComicShannsMono"
     ];
   })
  ];
  #fonts.fontconfig = {
  #  defaultFonts = {
  #      serif = [ "RobotoMono Nerd Font Propo"];
  #      sansSerif = [ "RobotoMono Nerd Font Propo"];
  #      monospace = [ "RobotoMono Nerd Font"];
  #  };
  #};

  homebrew = {
    enable = true;
    # onActivation.cleanup = "uninstall";

    taps = ["homebrew/services" "FelixKratz/formulae" "benjiwolff/neovim-nightly" "nikitabobko/tap"];
    brews = [ "helm" "kubectl"];
    casks = [ "sketchybar" "aerospace" "google-cloud-sdk" "dbeaver-community" "firefox" "obsidian" "vlc" "insomnia" "hyperkey" "hammerspoon" "neovim-nightly" "webcatalog" "raycast" "chromium"];
  };

  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
