{ config, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  programs.zed-editor = {
    # On macOS, use Homebrew cask instead (much faster, pre-built binary)
    enable = if isDarwin then true else true;
    package = if isDarwin then 
      pkgs.zed-editor
    else
      (pkgs.zed-editor-fhs.overrideAttrs (oldAttrs: rec {
        preConfigure = ''
    export PROTOC=${pkgs.protobuf}/bin/protoc
        '' + (oldAttrs.preConfigure or "");

        postInstall = (oldAttrs.postInstall or "") + ''
    wrapProgram $out/bin/zeditor --set ZED_ALLOW_EMULATED_GPU 0
        '';
      }));
  };
}
