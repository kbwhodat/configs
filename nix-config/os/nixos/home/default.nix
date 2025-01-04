{ lib, config, pkgs, ... }:

let
  # Define the library path here
  libraryPath = lib.makeLibraryPath [
    pkgs.glibc
  ];

  ldLibraryPath = lib.makeLibraryPath [
    pkgs.gcc_multi
    pkgs.linuxPackages.nvidia_x11
    # pkgs.glibc
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
		../../../common/linux/i3
		../../../common
    ../../../common/sops
	];

  home.username = "katob";
  home.homeDirectory = "/home/katob";

  home.stateVersion = "24.11"; # Please read the comment before changing.


  home.packages = with pkgs; [
		nmap
    pciutils
    xclip
    xsel
    xdotool
    ueberzug
    pulseaudio
    autorandr
    chromium
    mpv
    vlc
    openvpn
    yaegi
    dunst
    tomato-c
    clang-tools
    transmission_4-qt
    tor
    tor-browser
  ];

  home.enableNixpkgsReleaseCheck = false;


  home.sessionVariables = {
    EDITOR = "nvim";
    LD_LIBRARY_PATH = "${pkgs.lib.optionalString (builtins.getEnv "LD_LIBRARY_PATH" != "") (builtins.getEnv "LD_LIBRARY_PATH" + ":")}${ldLibraryPath}";
    LIBRARY_PATH = "${pkgs.lib.optionalString (builtins.getEnv "LIBRARY_PATH" != "") (builtins.getEnv "LIBRARY_PATH" + ":")}${libraryPath}";
    NIX_LDFLAGS = "${pkgs.lib.optionalString (builtins.getEnv "NIX_LDFLAGS" != "") (builtins.getEnv "NIX_LDFLAGS" + ":")}-L${libraryPath}";
    NIX_CFLAGS_COMPILE = "${pkgs.lib.optionalString (builtins.getEnv "NIX_CFLAGS_COMPILE" != "") (builtins.getEnv "NIX_CFLAGS_COMPILE" + ":")}-I${pkgs.glibc}/include";
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.userDirs.enable = true;

  # services.pass-secret-service = {
  #   enable = true;
  #   package = pkgs.libsecret;
  # };
}
