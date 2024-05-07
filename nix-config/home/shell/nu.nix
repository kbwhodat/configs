{ config, ... }:
{

  programs.nushell = {
    enable = false;
    inherit (config.home) shellAliases; # Our shell aliases are pretty simple
  };
}
