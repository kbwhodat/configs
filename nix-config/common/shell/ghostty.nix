# configuration.nix
{ lib, inputs, config, pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin;
  #githubTokenScript = pkgs.writeScriptBin "github-token" ''
  #  "${builtins.readFile "${config.home.homeDirectory}/.katotoken"}"
  #'';
  #githubToken = builtins.readFile "${githubTokenScript}/bin/github-token";
  #githubToken = builtins.readFile ./.teacup;
  #githubToken = builtins.readFile "/etc/.secrets/subkey.pub";
  url = builtins.fetchurl {
    url = "file:///etc/.secrets/token";
    sha256 = "1hr7pgvj64b34y4ia0qg9h0b57mdhcqlak7bcfpxjf4vbjgg29kl";
  };
  githubToken = builtins.readFile url;

  ghosttyOverlay =  (import (inputs.ghostty-darwin + "/overlay.nix") { inherit githubToken; });
  pkgsWithOverlay = import inputs.nixpkgs {
    inherit (pkgs) system;
    overlays = [ ghosttyOverlay ];
  };

in

{

  home.packages = 
    if isDarwin then
      with pkgsWithOverlay; [ pkgsWithOverlay.ghostty-darwin ]
    else
      with pkgs; [ inputs.ghostty.packages.x86_64-darwin.default ];

  home.file."ghostty".target = "${config.home.homeDirectory}/.config/ghostty/config";
  home.file."ghostty".source = builtins.toFile "config" ''

    font-size = 13.3

    font-family = "RobotoMono Nerd Font Mono"
    font-family-bold = "RobotoMono Nerd Font Mono Bd"
    font-family-italic = "RobotoMono Nerd Font Mono It"
    font-family-bold-italic = "RobotoMono Nerd Font Mono Bd It"

    font-thicken = true

    theme = Wez

    adjust-cursor-thickness = 50%

    window-theme = dark
    clipboard-read = allow

    command = /etc/profiles/per-user/katob/bin/bash

    shell-integration = bash
    # gtk-titlebar = true

    cursor-style = block
    cursor-style-blink = true
    background = #000000
    foreground = #ffffff

    gtk-adwaita = true
    bold-is-bright = true

    window-decoration = false
    window-padding-x = 0
    window-padding-y = 0

    cursor-style-blink = false
    shell-integration-features = cursor

    # selection-foreground =
    # selection-background =

  '';

}
