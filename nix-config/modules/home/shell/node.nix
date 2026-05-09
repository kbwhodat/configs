{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.nodejs_21
  ];
}

