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

  environment.systemPackages = with pkgs; [ 
    pinentry_mac
    yabai
    docker-client
    skhd
    iina
    colima
    lima-bin
    libiconv-darwin
  ];

  launchd.user.agents.docker = {
    serviceConfig.ProgramArguments = [ "/Users/katob/.config/nix-config/os/darwin/scripts/start_colima.sh" ];
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = false;
    serviceConfig.StandardOutPath = "/tmp/colima.out";
    serviceConfig.StandardErrorPath = "/tmp/colima.err";
  };

  services.yabai.enable = true;
  services.yabai.enableScriptingAddition = true;
  services.skhd.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true; 

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "RobotoMono"
        "ComicShannsMono"
      ];
    })
  ];

  homebrew = {
    enable = true;
    # onActivation.cleanup = "uninstall";

    taps = ["benjiwolff/neovim-nightly"];
    brews = [ "helm" "kubectl" ];
    casks = [ "google-cloud-sdk" "dbeaver-community" "tomatobar" "zed" "firefox" "obsidian" "vlc" "insomnia" "hyperkey" "hammerspoon" "neovim-nightly" "webcatalog" "raycast" "chromium"];
  };

  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
