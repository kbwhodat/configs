{ inputs, config, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    installVimSyntax = true;
    settings = {
      theme = "Wez";
      font-size = 13.3;
      selection-foreground = "#000000";
      selection-background = "#dfa0f0";
      window-vsync = false;

      font-family-bold = "ComicShannsMono Nerd Font Mono Bold";
      font-family-italic = "RobotoMono Nerd Font Mono It";
      font-family-bold-italic = "RobotoMono Nerd Font Mono Bd It";

      adjust-cursor-thickness = "50%";

      window-theme = "dark";
      clipboard-read = "allow";

      # command = "/etc/profiles/per-user/katob/bin/bash";
      command = "/etc/profiles/per-user/katob/bin/zsh";

      shell-integration = "bash";

      cursor-style = "block";
      cursor-style-blink = "true";
      background = "#000000";
      foreground = "#ffffff";

      cursor-color = "#ffffff";

      gtk-adwaita = true;
      bold-is-bright = true;

      window-decoration = false;
      window-padding-x = 0;
      window-padding-y = 0;

      shell-integration-features = "cursor";
    };
  };
}
