{ inputs, config, pkgs, ...}:
{
  home.packages = with pkgs; [
    inputs.ghostty.packages.${pkgs.system}.default
  ];

  home.file."ghostty".target = "${config.home.homeDirectory}/.config/ghostty/config";
  home.file."ghostty".source = builtins.toFile "config" ''

    font-family = "RobotoMono Nerd Font Mono"
    font-family-bold = "RobotoMono Nerd Font Mono Bd"
    font-family-italic = "RobotoMono Nerd Font Mono It"
    font-family-bold-italic = "RobotoMono Nerd Font Mono Bd It"

    font-thicken = false

    window-theme = dark
    clipboard-read = allow

    shell-integration = none
    # gtk-titlebar = true

    cursor-style = block
    cursor-style-blink = true
    background = #000000
    foreground = #ffffff

    gtk-adwaita = true
    bold-is-bright = true

    window-decoration = false
    window-padding-x = 0
    window-padding-y = 0

    cursor-style-blink = true

    # selection-foreground =
    # selection-background =


  '';

}
