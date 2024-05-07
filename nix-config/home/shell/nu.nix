{ config, ... }:
{

  programs.nushell = {
    enable = true;
    inherit (config.home) shellAliases; # Our shell aliases are pretty simple
  };
}
