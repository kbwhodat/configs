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
  rev = "20fadc63a83680779a112ff8667a39f702818cb9";
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
  services.skhd.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true; 

  homebrew = {
    enable = false;
    # onActivation.cleanup = "uninstall";

    taps = ["benjiwolff/neovim-nightly" "koekeishiya/formulae"];
    brews = [ "helm" ];
    casks = [ "zed" "firefox" "obsidian" "vlc" "insomnia" "hyperkey" "hammerspoon" "neovim-nightly" "webcatalog" "raycast" "chromium"];
  };

  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
