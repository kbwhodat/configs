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
      with pkgs; [ inputs.ghostty.packages.x86_64-linux.default ];

  home.file."ghostty".target = "${config.home.homeDirectory}/.config/ghostty/config";
  home.file."ghostty".source = builtins.toFile "config" ''

    font-size = ${if isDarwin then "13.3" else "13.0"}

    #font-family = "RobotoMono Nerd Font Mono"
    #font-family-bold = "RobotoMono Nerd Font Mono Bd"
    font-family = "ComicShannsMono Nerd Font Mono"
    font-family-bold = "ComicShannsMono Nerd Font Mono Bold"
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

    cursor-color = #ffffff

    #gtk-adwaita = ${if isDarwin then "false" else "true"}
    bold-is-bright = false

    window-decoration = false
    window-padding-x = 0
    window-padding-y = 0

    cursor-style-blink = true
    shell-integration-features = cursor

    # selection-foreground =
    # selection-background =

  '';

}
