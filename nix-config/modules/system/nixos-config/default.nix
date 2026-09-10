{ inputs, config, pkgs, lib, ... }:

let
  browserBlockPolicy = {
    # Chromium URLBlocklist: path is a prefix, no wildcards.
    URLBlocklist = [
      "https://redlib.catsarch.com/settings"
      "https://redlib.catsarch.com/search"
      "https://redlib.catsarch.com/r/?q=*"   # per-subreddit search
      "https://redlib.catsarch.com/u/"
      "https://redlib.catsarch.com/user/"
      "https://kagi.com/settings"
      "https://kagi.com/images"
      "https://kagi.com/videos"
    ];
    "3rdparty".extensions."blockjmkbacgjkknlgpkjjiijinjdanf".toOverwrite.filters = [
      "||kagi.com/api/quick_settings^"
    ];
  };
in
{
  imports =
    [
      inputs.sops-nix.nixosModules.sops
      ../nextdns-lockdown/nixos.nix
    ];

  # NextDNS lockdown: plain DNS may only leave towards NextDNS.
  modules.nextdnsLockdown.enable = true;

  services.lorri.enable = true;

  environment = {
    pathsToLink = [ "/libexec" ];

    # Block redlib settings/search/user pages and kagi settings in
    # Thorium/Chromium browsers. uBlock Origin managed filter blocks kagi's
    # hamburger-menu settings API (URLBlocklist only covers navigations).
    etc."chromium/policies/managed/redlib-block.json".text = builtins.toJSON browserBlockPolicy;
    etc."opt/chromium/policies/managed/redlib-block.json".text = builtins.toJSON browserBlockPolicy;
  };

  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://chawan-nix-flake.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "chawan-nix-flake.cachix.org-1:guW77ag6Q9K4NVJ3gh5H4jsT4QlKfYAVooSFbDXAxD4="
  ];

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
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];
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
      # pkgs.openssl.dev
    ];

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

  services.xserver.windowManager.i3.package = pkgs.i3;

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
  # Disabled - using custom script with greyscale shader instead
  # services.picom.enable = true;
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
    freetube
  ];

  programs.direnv.nix-direnv = {
    enable = true;
    package = pkgs.nix-direnv;
  };

  virtualisation.vmware.host.enable = true;
  programs.nix-ld.enable = true;

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        "45.90.28.0#66f183.dns.nextdns.io"
        "45.90.30.0#66f183.dns.nextdns.io"
      ];
      DNSOverTLS = "yes";
    };
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
      # Grafana no longer ships a default secret_key (used to encrypt
      # datasource credentials in its DB).  Point it at a host-local
      # file; the preStart below generates it once, so no manual
      # provisioning step and nothing secret in the nix store.
      security.secret_key = "$__file{/var/lib/grafana/secret_key}";
    };
  };

  # One-time secret_key generation for grafana.  Guarded by mkIf so the
  # unit isn't created on hosts where grafana is disabled.
  systemd.services.grafana.preStart =
    lib.mkIf config.services.grafana.enable (lib.mkBefore ''
      if [ ! -s /var/lib/grafana/secret_key ]; then
        umask 077
        ${pkgs.coreutils}/bin/od -An -tx1 -N32 /dev/urandom \
          | ${pkgs.coreutils}/bin/tr -d ' \n' \
          > /var/lib/grafana/secret_key
      fi
    '');

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
      "mac-studio" = {
        id = "BOVCXJY-FCRVFJS-DFJ667E-ICJHPSR-U5K7YQI-M4Q6NEW-6NTLGWB-EE2BSAE";
      };
      "mac-neo" = {
        id = "BTCSTSR-IK5SIAR-WZDNOFS-RCLFYYH-ZGPTUYU-FTWRG2L-JRFLT2E-ZBCB6AX";
      };
    };
    settings.folders = {
      "/home/katob/vault" = {
        id = "notes";
        devices = [ "mac-neo" "mac-studio" "iphone" "nixos-main" "nixos-frame13" "nixos-util" "nixos-server"];
      };
      "/home/katob/Documents" = {
        id = "documents";
        devices = [ "mac-neo" "mac-studio" "nixos-main" "nixos-frame13" "nixos-util" "nixos-server"];
      };
    };
  };
}
