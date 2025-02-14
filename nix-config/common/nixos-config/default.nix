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


  system.stateVersion = "24.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.trusted-users = [
		"root"
		"katob"
		"nixos"
		"@wheel"
	];

	# networking.wireless.networks = {
	# 	"results will vary" = {
      # extraConfig = ''
            # key_mgmt=WPA-PSK
            # psk=54047fa690627b6ef2e1176f21df83b09ce25d2c6a2dcc4eac5f8bac228f7c9a
      # '';
	# 	};
  # };

  users.users.katob = {
    isNormalUser = true;
    description = "kato";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
		shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3SkLoVy10CCXlTHH91GPTHfW9U7Ix9VHPb0q2A24TE main"
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNEmrMVBS9omF7tSAORWRZ2f9RyBuwCNCVBgPGMYgjn utility"
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILuQLHoHdOry21yHqwszBboRaO/vhbXmpdseDW4oyZs6 server"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.input-fonts.acceptLicense = true;

  # fonts.packages = with pkgs; [
  #   (nerdfonts.override { fonts = ["RobotoMono" "ComicShannsMono"]; })
  # ];

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts.roboto-mono
    pkgs.nerd-fonts.comic-shanns-mono
  ];

  fonts.fontconfig = {
    defaultFonts = {
        serif = [ "RobotoMono Nerd Font Propo"];
        sansSerif = [ "RobotoMono Nerd Font Propo"];
        monospace = [ "RobotoMono Nerd Font"];
    };
  };

  # Setting up env variables for image.nvim
  # environment.variables.LD_LIBRARY_PATH = [ "${pkgs.imagemagick}/lib" ];
  environment.variables.PKG_CONFIG_PATH = [ "${pkgs.imagemagick.dev}/lib/pkgconfig" ];

  services.logind.lidSwitchExternalPower = "ignore";

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # networking.wireless.iwd.enable = true;

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
  programs.turbovnc.ensureHeadlessSoftwareOpenGL = false;
  hardware.nvidia.forceFullCompositionPipeline = false;
  # hardware.opengl.enable = true;
  # hardware.opengl.driSupport = true;
  # hardware.opengl.driSupport32Bit = true;
  # hardware.graphics.enable = true;
  # hardware.opengl.driSupport = true;
  # hardware.graphics.enable32Bit = true;

	hardware.graphics = {
		enable = true;
		enable32Bit = true;
	};


  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  services = {
    displayManager = {
      defaultSession = "none+i3";
    };
  };

  services.xserver = {

    desktopManager = {
      plasma5.enable = false;
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

  # I set this to do getting to many open files from os.pipe when attempting to setup ipvanish
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "soft"; value = "100000"; }
    { domain = "*"; item = "nofile"; type = "hard"; value = "200000"; }
  ];

  networking.firewall.allowedTCPPorts = [11434 8888 8080 1714 1764 8384 22000];
  networking.firewall.allowedUDPPorts = [22000 21027];

  #used for configuring KDE connect
  programs.kdeconnect.enable = true;

  # A window compistor for X11
  services.picom.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = false;
  };

  services.syncthing = {
    enable = true;
    user = "katob";
    openDefaultPorts = true;
    settings.gui = {
      theme = "black";
    };
    dataDir = "/home/katob/.config/syncthing";
    settings.devices = {
      "iphone" = {
        id = "V5SVN25-M2CS2HQ-T2QIERP-HQ47OOC-YLDGWKB-EEGBAVK-4BB5JJF-VNASBA2";
      };
      "nixos-main" = {
        id = "7JQTNQL-BAGUNWN-7SFZ3IC-7MA5VNX-3P65FPU-YOQ325K-VFVG76O-AGP2XAJ";
      };
      "nixos-frame16" = {
        id = "35VEAHW-73R2GDD-7WA4MDA-S5XGNQI-YKJFE7S-4433VRJ-SS74LJA-BUDSRAD";
      };
    };
    settings.folders = {
      "/home/katob/vault" = {
        id = "notes";
        devices = [ "iphone" "nixos-main" "nixos-frame16" ];
      };
    };
  };


}
