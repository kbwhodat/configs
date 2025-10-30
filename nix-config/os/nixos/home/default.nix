{ lib, config, pkgs, ... }:

let
  # Define the library path here
  libraryPath = lib.makeLibraryPath [
    pkgs.glibc
  ];

  ldLibraryPath = lib.makeLibraryPath [
    pkgs.gcc_multi
    pkgs.linuxPackages.nvidia_x11
    pkgs.glibc
    pkgs.glib
    pkgs.nss_latest
    pkgs.xorg.libxcb
    pkgs.nspr
    pkgs.mesa
    pkgs.libGL
  ];
in
{
	imports = [
		../../../common/linux/rofi
		../../../common/linux/calibre
		../../../common/linux/okular
		../../../common/linux/koreader
		../../../common/linux/i3
		../../../common
    ../../../common/sops
    ../../../common/personal
    ../../../common/gaming
	];

  home.username = "katob";
  home.homeDirectory = "/home/katob";

  home.stateVersion = "25.11"; # Please read the comment before changing.

  services.grobi = {
    enable = true;
    rules = [
      {
        name = "server";
        outputs_connected = [ "HDMI-2" ];
        outputs_present = [ "HDMI-2" ];
        primary = true;
        atomic = true;
      }
      {
        name = "docked";
        outputs_connected = [ "DVI-I-2-2" "DVI-I-1-1" ];
        atomic = true;
        configure_row = [ "DVI-I-2-2" "DVI-I-1-1" ];
        primary = "DVI-I-2-2";
        # execute_after = [
        #   "${pkgs.nitrogen}/bin/nitrogen --restore"
        #   "${pkgs.qtile}/bin/qtile cmd-obj -o cmd -f restart"
        #   "${pkgs.networkmanager}/bin/nmcli radio wifi off"
        # ];
      }
      {
        name = "undocked";
        outputs_disconnected = [ "DVI-I-2-2" "DVI-I-1-1" ];
        configure_single = "eDP-1";
        primary = true;
        atomic = true;
        # execute_after = [
        #   "${pkgs.nitrogen}/bin/nitrogen --restore"
        #   "${pkgs.qtile}/bin/qtile cmd-obj -o cmd -f restart"
        #   "${pkgs.networkmanager}/bin/nmcli radio wifi on"
        # ];
      }
      {
        name = "fallback";
        configure_single = "eDP-1";
      }
    ];
  };

  home.packages = with pkgs; [
    keepassxc
    alsa-utils
    xorg.xorgserver
    obsidian
    maven
    vulkan-tools
    picom
		nmap
    pciutils
    xclip
    xsel
    xdotool
    ueberzug
    pulseaudio
    autorandr
    mpv
    vlc
    openvpn
    yaegi # go interpreter
    dunst
    clang
    clang-tools
    transmission_4-qt
    tor
    tor-browser
    bluez
  ];

  
  home.enableNixpkgsReleaseCheck = false;

  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";

    LD_LIBRARY_PATH = "${pkgs.lib.optionalString (builtins.getEnv "LD_LIBRARY_PATH" != "") (builtins.getEnv "LD_LIBRARY_PATH" + ":")}${ldLibraryPath}";
    LIBRARY_PATH = "${pkgs.lib.optionalString (builtins.getEnv "LIBRARY_PATH" != "") (builtins.getEnv "LIBRARY_PATH" + ":")}${libraryPath}";
    # NIX_LDFLAGS = "${pkgs.lib.optionalString (builtins.getEnv "NIX_LDFLAGS" != "") (builtins.getEnv "NIX_LDFLAGS" + ":")}-L${libraryPath}";
    # NIX_CFLAGS_COMPILE = "${pkgs.lib.optionalString (builtins.getEnv "NIX_CFLAGS_COMPILE" != "") (builtins.getEnv "NIX_CFLAGS_COMPILE" + ":")}-I${pkgs.glibc}/include";
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.userDirs.enable = true;

  # services.pass-secret-service = {
  #   enable = true;
  #   package = pkgs.libsecret;
  # };
}
