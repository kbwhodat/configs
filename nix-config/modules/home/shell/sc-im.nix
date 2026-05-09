{ config, pkgs, ...}:
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.packages = with pkgs; [
    sc-im
  ];

  home.file."${config.home.homeDirectory}/.config/sc-im/scimrc".text = ''

# Pure black background + white text everywhere
color "type=HEADINGS fg=WHITE bg=BLACK bold=0 italic=0"
color "type=HEADINGS_ODD fg=WHITE bg=BLACK bold=0 italic=0"
color "type=MODE fg=WHITE bg=BLACK bold=0 italic=0"
color "type=NUMB fg=WHITE bg=BLACK bold=0 italic=0"
color "type=STRG fg=WHITE bg=BLACK bold=0 italic=0"
color "type=DATEF fg=WHITE bg=BLACK bold=0 italic=0"
color "type=EXPRESSION fg=WHITE bg=BLACK bold=0 italic=0"
color "type=GRID_EVEN fg=WHITE bg=BLACK"
color "type=GRID_ODD  fg=WHITE bg=BLACK"
color "type=CELL_ERROR fg=WHITE bg=BLACK bold=0"
color "type=CELL_NEGATIVE fg=WHITE bg=BLACK bold=0"

# Selection/cursor: still only black & white, but reversed so you can see it
color "type=CELL_SELECTION fg=WHITE bg=BLACK bold=0 reverse=1"
color "type=CELL_SELECTION_SC fg=WHITE bg=BLACK bold=0 reverse=1"

color "type=INFO_MSG fg=WHITE bg=BLACK bold=0"
color "type=ERROR_MSG fg=WHITE bg=BLACK bold=0"
color "type=CELL_ID fg=WHITE bg=BLACK bold=0"
color "type=CELL_FORMAT fg=WHITE bg=BLACK bold=0"
color "type=CELL_CONTENT fg=WHITE bg=BLACK bold=0"
color "type=WELCOME fg=WHITE bg=BLACK bold=0"
color "type=NORMAL fg=WHITE bg=BLACK bold=0"
color "type=INPUT fg=WHITE bg=BLACK bold=0"
color "type=HELP_HIGHLIGHT fg=WHITE bg=BLACK bold=0 underline=0"

    '';


}
