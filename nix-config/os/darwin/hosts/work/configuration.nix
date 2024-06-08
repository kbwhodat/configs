{
    pkgs,
    inputs,
    config,
    ...
}: 

let
myrepo = pkgs.fetchFromGitHub {
  owner = "kbwhodat";
  repo = "pass-keys";
  rev = "20fadc63a83680779a112ff8667a39f702818cb9";
  hash = "sha256-2OlQfsGJ+59y2xs6HePqoZS3mlD/5pHDRza+vtAQssw=";
};
in
{
# nix configuration
# reference: https://daiderd.com/nix-darwin/manual/index.html#sec-options

  imports =
    [ 
      inputs.sops-nix.nixosModules.sops
    ];

  environment.etc.".secrets".source = "${myrepo}";

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/etc/.secrets/keys.txt";

  sops.secrets.pass-gpg = {
    owner = config.users.users.katob.name;
  };

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
    ollama
  ];

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

  services.yabai.enable = true;
  services.skhd.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true; 

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    taps = ["benjiwolff/neovim-nightly" "koekeishiya/formulae"];
    brews = [ "helm" ];
    casks = [ "zed" "firefox" "obsidian" "vlc" "insomnia" "hyperkey" "hammerspoon" "neovim-nightly" "webcatalog" "raycast" "chromium"];
  };

  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];
  # system.stateVersion = 4;
}
