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
    python312
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
    # enable = true;
    # onActivation.cleanup = "uninstall";

    taps = ["homebrew/services" "FelixKratz/formulae" "nikitabobko/tap"];
    brews = [ "kanata" "firefoxpwa" "colima" "terragrunt" "helm" "kubectl"];
    casks = [ "karabiner-elements" "clocker" "aerospace" "zed" "dbeaver-community" "obsidian" "vlc" "hammerspoon" "raycast" "ungoogled-chromium" "gcloud-cli"];
  };

  nix.settings.download-buffer-size = 524288000;
  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];

  system.stateVersion = 4;
}
