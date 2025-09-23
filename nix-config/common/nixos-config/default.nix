{ inputs, config, pkgs, lib, ... }:

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

  services.lorri.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "katob" ];
  };

  environment = {
    etc.".secrets".source = "${myrepo}";
    pathsToLink = [ "/libexec" ];
  };


  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.trusted-users = [
		"root"
    "taskchampion"
		"katob"
		"nixos"
		"@wheel"
	];
  nix.settings.sandbox = false;

  users.users.katob = {
    isNormalUser = true;
    description = "kato";
    extraGroups = [ "taskchampion" "audio" "docker" "networkmanager" "wheel" ];
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


  # this is for the unstable nixpkg version - make sure to use this next when an upgrade happens
  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
    nerd-fonts.comic-shanns-mono
    nerd-fonts.symbols-only
    nerd-fonts.commit-mono
  ];

  fonts.fontconfig = {
    defaultFonts = {
        serif = [ "CommitMono Nerd Font Mono Propo"];
        sansSerif = [ "CommitMono Nerd Font Mono Propo"];
        monospace = [ "CommitMono Nerd Font Mono"];
    };
  };

  # Setting up env variables for image.nvim
  environment.variables.LD_LIBRARY_PATH = [ "${pkgs.imagemagick}/lib" ];
  environment.variables.PKG_CONFIG_PATH = [ "${pkgs.imagemagick.dev}/lib/pkgconfig" "${pkgs.openssl.dev}/lib/pkgconfig" ];

  services.logind.lidSwitchExternalPower = lib.mkForce "ignore";

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

  xdg.portal = {
    enable = true;
    configPackages = [ pkgs.xdg-desktop-portal-gtk ];
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.blueman.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.xserver = {

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

  networking.firewall.allowedTCPPorts = [3000 9100 9090 10222 11434 8888 8080 1714 1764 8384 22000 1716 1717 1718 1719 1720];
  networking.firewall.allowedUDPPorts = [10222 22000 21027 1716 1717 1718 1719 1720];

  #used for configuring KDE connect
  programs.kdeconnect.enable = true;

  # A window compistor for X11
  services.picom.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = true;
  # security.rtkit.enable = false;
  services.pipewire = {
    enable = false;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = false;
  };

  environment.systemPackages = with pkgs; [
    #gccgo
    zenity
    libnotify
    scrot
    libreoffice-still
    # needed for exercism
    gnumake
    exercism
    firefoxpwa
    unixtools.netstat
  ];

  programs.direnv.nix-direnv = {
    enable = true;
    package = pkgs.nix-direnv;
  };

  services.smartdns = {
    enable = true;
    bindPort = 53;
    settings = {
      speed-check-mode = "ping";
      cache-size = 4096;
      serve-expired = "yes";
      prefetch-domain = true;
    };
  };

  services.resolved = {
    enable = true;
    extraConfig = "
      nameserver 127.0.0.1
    ";
  };

  services.taskchampion-sync-server = {
    enable = true;
    host = "0.0.0.0";
    group = "users";
    allowClientIds = ["1578cf97-0993-47e3-badc-2dc56fb832e7"];
  };

  services.grafana = {
    enable = if config.networking.hostName == "nixos-main" then true else false;
    settings = {
      server = {
        http_addr = "10.0.0.20";
      };
    };
  };

  services.prometheus = {
    enable = if config.networking.hostName == "nixos-main" then true else false;
    listenAddress = "0.0.0.0";
    port = 9090;

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["10.0.0.20:9100"];
            labels = { host = "nixos-main"; };
          }
          {
            targets = ["10.0.0.31:9100"];
            labels = { host = "nixos-frame13"; };
          }
        ];

      }
    ];

    exporters = {
      process = {
        enable = true;
      };
      node = {
        enable = true;
      };
    };
  };

  services.syncthing = {
    enable = true;
    user = "katob";
    group = "users";
    openDefaultPorts = true;
    dataDir = "/home/katob";
    configDir = "/home/katob/.config/syncthing";
    key = "/home/katob/.config/syncthing-keys/key.pem";
    cert = "/home/katob/.config/syncthing-keys/cert.pem";
    settings.gui = {
      theme = "black";
    };
    settings.devices = {
      "iphone" = {
        id = "V5SVN25-M2CS2HQ-T2QIERP-HQ47OOC-YLDGWKB-EEGBAVK-4BB5JJF-VNASBA2";
      };
      "nixos-main" = {
        id = "UQAWJXF-VFHDTRI-AIEFOLH-OMVHBYD-X5MKXTN-CQJWEKV-47JOT5P-TMIXGA5";
      };
      "nixos-frame13" = {
        id = "IMNRAP7-RZNJQFO-GOZLSJN-RHWC55N-WRODY7I-SNJCDBH-MZODTPJ-W7CZRQX";
      };
      "nixos-util" = {
        id = "QZJBK62-4DPFF7J-T3PQRU6-HT4SBIY-5H7INBX-F5OMPBS-LLUONWG-KIJL5A3";
      };
    };
    settings.folders = {
      "/home/katob/vault" = {
        id = "notes";
        devices = [ "iphone" "nixos-main" "nixos-frame13" "nixos-util" ];
      };
      "/home/katob/Documents" = {
        id = "documents";
        devices = [ "nixos-main" "nixos-frame13" "nixos-util"  ];
      };
    };
  };
}
