{ lib, config, pkgs, ... }:

let
  # Define the library path here
  ldLibraryPath = lib.makeLibraryPath [
    pkgs.gcc-unwrapped.lib
    pkgs.linuxPackages.nvidia_x11
  ];
in
{
	imports = [
		../../../common/linux/rofi
		../../../common/linux/calibre
		../../../common/linux/okular
		../../../common/linux/i3
		../../../common
	];

  home.username = "katob";
  home.homeDirectory = "/home/katob";


  home.stateVersion = "24.05"; # Please read the comment before changing.


  home.packages = with pkgs; [
		nmap
    pciutils
    xclip
    xsel
    xdotool
    ueberzug
    pulseaudio
    autorandr
    ungoogled-chromium
    mpv
    vlc

  ];

  home.enableNixpkgsReleaseCheck = false;


  home.sessionVariables = {
    EDITOR = "nvim";
    LD_LIBRARY_PATH = "${pkgs.lib.optionalString (builtins.getEnv "LD_LIBRARY_PATH" != "") (builtins.getEnv "LD_LIBRARY_PATH" + ":")}${ldLibraryPath}";
  };

  programs.home-manager.enable = true;
}
