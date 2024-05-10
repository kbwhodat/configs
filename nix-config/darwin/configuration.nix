{
    pkgs,
    inputs,
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
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    taps = [];
    brews = [];
    casks = [ "firefox" ];
  };

  nix.settings.allowed-users = ["root" "katob"];
  nix.settings.trusted-users = ["root" "katob"];
  system.stateVersion = 4;
}
