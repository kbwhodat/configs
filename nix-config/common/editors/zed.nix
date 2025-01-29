{ pkgs, config, ... }:

{
  programs.zed-editor = {
    enable = false;
    extensions = [ "nix" "ansible" "terraform" "c" "python" "go" ];

    userSettings = {

      assistant = {
        enable = false;
      };
      vim_mode = true;
      theme = {
        mode = "system";
        dark = "The Dark Side";
      };

      ui_font_size = 16;
      buffer_font_size = 14;
      hour_format = "hour24";
      auto_update = false;
      buffer_font_family = "ComicShannsMono Nerd Font Mono";
      ui_font_family = "ComicShannsMono Nerd Font Mono"; 
      relative_line_numbers = true;
    };
  };
}
