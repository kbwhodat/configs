{ inputs, config, pkgs, ... }:

let
# myrepo = pkgs.fetchFromGitHub {
#   owner = "kbwhodat";
#   repo = "pass-keys";
#   rev = "20fadc63a83680779a112ff8667a39f702818cb9";
# };
myrepo = builtins.fetchGit {
  url = "https://github.com/kbwhodat/pass-keys.git";
  ref = "main";
  rev = "20fadc63a83680779a112ff8667a39f702818cb9";
};
in
{
  imports =
    [ 
      inputs.sops-nix.nixosModules.sops
    ];


  environment = {
    etc.".secrets".source = "${myrepo}";
    pathsToLink = [ "/libexec" ];
  };

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/etc/.secrets/keys.txt";

    secrets.pass-gpg = {
      owner = config.users.users.katob.name;
    };
  };

  system.stateVersion = "unstable"; 


  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.trusted-users = [
		"root"
		"katob"
		"nixos"
		"@wheel"
	];

	networking.wireless.networks = {
		"results will vary" = {
      extraConfig = ''
            key_mgmt=WPA-PSK
            psk=54047fa690627b6ef2e1176f21df83b09ce25d2c6a2dcc4eac5f8bac228f7c9a
      '';
		};
  };

  users.users.katob = {
    isNormalUser = true;
    description = "kato";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
		shell = pkgs.bash;
    openssh.authorizedKeys.keys = [ 
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3SkLoVy10CCXlTHH91GPTHfW9U7Ix9VHPb0q2A24TE main"   
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNEmrMVBS9omF7tSAORWRZ2f9RyBuwCNCVBgPGMYgjn utility"
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];
  # Setting up env variables for image.nvim
  # environment.variables.LD_LIBRARY_PATH = [ "${pkgs.imagemagick}/lib" ];
  environment.variables.PKG_CONFIG_PATH = [ "${pkgs.imagemagick.dev}/lib/pkgconfig" ];

  services.logind.lidSwitchExternalPower = "ignore";

  networking.networkmanager.enable = false;

  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  services.xserver = {

    desktopManager = {
      plasma5.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
    };


    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
      ];
    };
  };
  
  services.xserver.windowManager.i3.package = pkgs.i3-gaps;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };



}
