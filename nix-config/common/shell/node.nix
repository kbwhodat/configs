{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.nodejs_21
  ];

 programs.npm = {
    enable = true;
    packageManager = "npm";
    packages = [
      "neovim"
    ];
  };
}

