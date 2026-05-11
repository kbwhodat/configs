{ config, ... }:

{
  # npm derives its global prefix from the node binary's path, which on
  # Nix points at the read-only store — so `npm install -g` fails with
  # EACCES. Pin the prefix to ~/.local (already on PATH via the AI
  # umbrella) so global installs land somewhere writable. npm reads
  # ~/.npmrc unconditionally, including from subprocesses (e.g. Pi's
  # `pi install npm:...`) where session env vars may not propagate.
  # Node itself comes from modules/home/packages/default.nix.
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.local
  '';
}

