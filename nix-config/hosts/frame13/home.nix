{ lib, config, pkgs, ... }:

let
  # Define the library path here
  libraryPath = lib.makeLibraryPath [
    pkgs.glibc
  ];

  ldLibraryPath = lib.makeLibraryPath [
    pkgs.gcc_multi
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
    ../../modules/home/sops
    ../../modules/home/shell
    ../../modules/home/vms
    ../../modules/home/packages
    ../../modules/home/browsers
    ../../modules/home/keyboard
    ../../modules/home/editors
    ../../modules/home/lsp
    ../../modules/home/neovim
    ../../modules/home/email
    ../../modules/home/personal
    ../../modules/home/ai
    ../../modules/home/linux/rofi
    ../../modules/home/linux/calibre
    ../../modules/home/linux/koreader
    ../../modules/home/linux/okular
    ../../modules/home/linux/i3
	];

  home.username = "katob";
  home.homeDirectory = "/home/katob";

  home.stateVersion = "25.11"; # Please read the comment before changing.


  home.packages = with pkgs; [
    alsa-utils
    xorg.xorgserver
    vulkan-tools
		nmap
    pciutils
    xclip
    xsel
    xdotool
    ueberzug
    pulseaudio
    yaegi # go interpreter
    dunst
    clang-tools
  ];

  home.enableNixpkgsReleaseCheck = false;

  home.sessionVariables = {
    GPUI_X11_SCALE_FACTOR = "1"; # This prevent zed from trying calculate the dpi of my system
    MOZ_DISABLE_RDD_SANDBOX = "1";
    MOZ_ACCELERATED = "false";
    MOZ_WEBRENDER = "0";
    LIBGL_ALWAYS_SOFTWARE = "1";

    # EDITOR = "nvim";
    # LD_LIBRARY_PATH = "${pkgs.lib.optionalString (builtins.getEnv "LD_LIBRARY_PATH" != "") (builtins.getEnv "LD_LIBRARY_PATH" + ":")}${ldLibraryPath}";
    # LIBRARY_PATH = "${pkgs.lib.optionalString (builtins.getEnv "LIBRARY_PATH" != "") (builtins.getEnv "LIBRARY_PATH" + ":")}${libraryPath}";
    # NIX_LDFLAGS = "${pkgs.lib.optionalString (builtins.getEnv "NIX_LDFLAGS" != "") (builtins.getEnv "NIX_LDFLAGS" + ":")}-L${libraryPath}";
    # NIX_CFLAGS_COMPILE = "${pkgs.lib.optionalString (builtins.getEnv "NIX_CFLAGS_COMPILE" != "") (builtins.getEnv "NIX_CFLAGS_COMPILE" + ":")}-I${pkgs.glibc}/include";
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.userDirs.enable = true;

}
