{ config, pkgs, ...}:
{
  programs.mbsync = {
    enable = true;
    extraConfig = "
      SyncState *
      MaxMessages 500
      ";
  };
}
