{ inputs, lib, pkgs, ...}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  rawHostName = builtins.readFile (pkgs.runCommand "hostname" {} ''
    ${pkgs.toybox}/bin/toybox hostname > "$out"
  '');
  hostName = lib.strings.removeSuffix "\n" rawHostName;
  isPersonalMac =
    isDarwin &&
    builtins.elem hostName [
      "mac-mini"
      "macos-mini"
    ];

  unstable = import inputs.unstable {
    system = pkgs.system;
    config = pkgs.config;
  };

  openclaw = pkgs.callPackage ../../pkgs/by-name/openclaw {
    inherit (unstable) rolldown;
  };
in
{
  home.packages = lib.optionals isPersonalMac [
    openclaw
  ];
}
