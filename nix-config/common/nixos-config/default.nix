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
    extraGroups = [ "libvirtd" "taskchampion" "audio" "docker" "networkmanager" "wheel" ];
    ignoreShellProgramCheck = true;
		shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3SkLoVy10CCXlTHH91GPTHfW9U7Ix9VHPb0q2A24TE main"
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNEmrMVBS9omF7tSAORWRZ2f9RyBuwCNCVBgPGMYgjn utility"
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILuQLHoHdOry21yHqwszBboRaO/vhbXmpdseDW4oyZs6 server"
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpnblcmFWCeTXQ7sBD1x4im0l7joHwzmM1JXCd/ce0Q frame13"
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
        serif = [ "ComicShannsMono Nerd Font Mono Propo"];
        sansSerif = [ "ComicShannsMono Nerd Font Mono Propo"];
        monospace = [ "ComicShannsMono Nerd Font Mono"];
    };
  };

  # Setting up env variables for image.nvim
  environment.variables.LD_LIBRARY_PATH = [ "${pkgs.imagemagick}/lib" ];
  environment.sessionVariables.PKG_CONFIG_PATH =
    lib.makeSearchPath "lib/pkgconfig" [
      pkgs.imagemagick.dev
      pkgs.openssl.dev
    ];

  services.logind.lidSwitchExternalPower = lib.mkForce "ignore";

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.nameservers = ["127.0.0.1"];

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
      # --- Performance & caching ---
      speed-check-mode = "ping,tcp:80";
      cache-size = 4096;
      serve-expired = "yes";
      prefetch-domain = true;

      server = [
        # verisign us
        "64.6.64.6 -group family"
        # opendns us
        "208.67.222.222 -group family"
        # neustar ulstra dns
        "156.154.70.1 -group family"
        # quad9
        "9.9.9.10 -group family"

        # germany
        # "84.200.69.80 -group family"
        # "116.203.32.217 -group family"
        # "88.198.92.222 -group family"
        "159.69.114.157 -group family"
        # uk
        "217.169.20.23 -group family"
        # "194.168.8.123 -group family"
        # "194.168.4.123 -group family"
        # "195.27.1.1 -group family"
        # "194.145.240.6 -group family"

        # sweden
        "95.215.19.53 -group family"
        # "88.80.161.132 -group family"

        # spain
        "74.82.42.42 -group family"
        # "84.236.142.130 -group family"
        # "195.219.98.4 -group family"
        # "92.43.224.1 -group family"
        # "80.67.98.226 -group family"

        # dubai
        "94.206.40.206 -group family"
        # "5.32.55.10 -group family"
        # "94.200.80.94 -group family"

        # singapore
        "165.21.13.90 -group family"

        # south africa
        "154.0.172.204 -group family"
        # "196.21.186.253 -group family"
        # "41.185.21.252 -group family"

        # Ghana
        "212.96.1.70 -group family"

        # Kenya
        "41.139.202.86 -group family"
        # "197.248.0.34 -group family"
        # "197.232.21.96 -group family"
        # "41.72.216.234 -group family"

        # Uganda
        "81.199.137.188 -group family"

        # Egypt
        "41.33.166.19 -group family"
        # "193.227.29.32 -group family"
        # "193.227.29.241 -group family"

        # alidns china
        "223.5.5.5 -group family"
        # "114.114.114.114 -group family"
        # "211.136.20.203 -group family"
        # dnspod asia mainland
        "119.29.29.29 -group family"
        # gmo japan
        "202.248.37.74 -group family"
        # jpix japan
        "202.248.20.133 -group family"

        # hong kong
        "210.0.255.251 -group family"
        # "210.0.128.250 -group family"
        # "210.0.128.241 -group family"

        # brasil
        "200.221.11.100 -group family"

        # argentina
        "168.205.92.166 -group family"
        # "200.89.142.74 -group family"
        # "45.65.225.220 -group family"

        # uruguay
        "190.64.72.234 -group family"
        # "179.27.64.34 -group family"
        # "201.217.129.253 -group family"
        # "200.40.48.254 -group family"

        # aussie broadband melberne
        "139.130.4.4 -group family"


      ];

      # --- Default group ---
      bind = "127.0.0.1:53 -group family";
    };
  };

  services.resolved = {
    enable = false;
    # extraConfig = ''
    #   [Resolve]
    #   DNS=1.1.1.1
    #   FallbackDNS=
    #   DNSSEC=allow-downgrade
    #   Domains=~.
    # '';
    extraConfig = "
      nameserver 127.0.0.l
    ";
  };

  services.taskchampion-sync-server = {
    enable = if config.networking.hostName == "nixos-main" then true else false;
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

  services.postgresql = {
    enable = if config.networking.hostName == "nixos-server" then true else false;
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
          {
            targets = ["10.0.0.122:9100"];
            labels = { host = "nixos-server"; };
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

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";
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
    extraFlags = [ "--allow-newer-config" ];
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
      "nixos-server" = {
        id = "SHP6VHK-GAS77UE-YTPE4XN-VJREHJA-62GGVJ5-CFWYAAJ-WWHUSSL-EWABPQ6";
      };
    };
    settings.folders = {
      "/home/katob/vault" = {
        id = "notes";
        devices = [ "iphone" "nixos-main" "nixos-frame13" "nixos-util" "nixos-server"];
      };
      "/home/katob/Documents" = {
        id = "documents";
        devices = [ "nixos-main" "nixos-frame13" "nixos-util" "nixos-server"];
      };
    };
  };
}
