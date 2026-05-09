{ config, pkgs, ... }:

{
  # Include Python and its package manager, pip
  home.packages = with pkgs; [
    python3
    python3.pkgs.pip
  ];

  # Configure Python packages globally for the user
  # programs.python = {
  #   enable = true;
  #   packageManager = "pip";  # Use pip as the package manager

  #   # Specify Python packages to be installed globally
  #   packages = p: [
  #     p.neovim  # Example package, you can add more as needed
  #     p.torch
  #     p.ansible
  #   ];
  # };
}
