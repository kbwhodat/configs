{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Wrapper script for dict with stemming support and clean formatting
  techdict = pkgs.writeShellScriptBin "techdict" ''
    word="$1"
    if [[ -z "$word" ]]; then
      echo "Usage: techdict <word>"
      exit 1
    fi

    format_output() {
      ${pkgs.gnused}/bin/sed \
        -e '/^[0-9]* definitions\? found/d' \
        -e 's/^[[:space:]]\{6,\}/      /'
    }

    # Try tech dictionaries first, then general English
    for db in foldoc jargon vera wn gcide; do
      result=$(${pkgs.dict}/bin/dict -h dict.org -d "$db" "$word" 2>/dev/null)
      if [[ -n "$result" && "$result" != *"No definitions found"* ]]; then
        echo "$result" | format_output
        exit 0
      fi
    done

    # Stem common suffixes and retry
    for suffix in izable ization izing ized able ible ing ed ly ness ment ity ism er est ive ively; do
      if [[ "$word" == *"$suffix" ]]; then
        stem="''${word%$suffix}"
        if [[ ''${#stem} -ge 4 ]]; then
          echo "[Stemmed: $word -> $stem]"
          echo
          for db in foldoc jargon vera wn gcide; do
            result=$(${pkgs.dict}/bin/dict -h dict.org -d "$db" "$stem" 2>/dev/null)
            if [[ -n "$result" && "$result" != *"No definitions found"* ]]; then
              echo "$result" | format_output
              exit 0
            fi
          done
        fi
      fi
    done

    echo "Nothing found for $word"
  '';
in {
  home.packages = [
    pkgs.bookokrat
    pkgs.dict
    techdict
  ];

  # On macOS, bookokrat looks for config in ~/Library/Application Support/bookokrat/
  # but we keep our config in ~/.config/bookokrat/ for consistency.
  # Create a symlink so bookokrat finds it.
  home.file."Library/Application Support/bookokrat/config.yaml" = lib.mkIf isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/bookokrat/config.yaml";
  };
}
