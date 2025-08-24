{ config, pkgs, ... }:
{
  programs.zed-editor = {
    enable = true
    package = (zed-editor-fhs.overrideAttrs (oldAttrs: rec {
      preConfigure = ''
    export PROTOC=${pkgs.protobuf}/bin/protoc
      '' + (oldAttrs.preConfigure or "");

      postInstall = (oldAttrs.postInstall or "") + ''
    wrapProgram $out/bin/zeditor --set ZED_ALLOW_EMULATED_GPU 0
      '';
    }))
  ];

}
