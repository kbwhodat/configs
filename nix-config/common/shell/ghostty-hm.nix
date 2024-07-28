{ inputs, config, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      background = "#ffffff";
      palette = [
        "0=#ffffff"
          "1=#a60000"
          "2=#006800"
          "3=#6f5500"
          "4=#0031a9"
          "5=#721045"
          "6=#005e8b"
          "7=#000000"
          "8=#f2f2f2"
          "9=#d00000"
          "10=#008900"
          "11=#808000"
          "12=#0000ff"
          "13=#dd22dd"
          "14=#008899"
          "15=#595959"
          "16=#884900"
          "17=#7f0000"
      ];
      selection-foreground = "#000000";
      selection-background = "#dfa0f0";
      window-vsync = false;
    };
  };
}
