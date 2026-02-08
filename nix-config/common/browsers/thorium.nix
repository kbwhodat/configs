{ config, inputs, lib, pkgs, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  thoriumExtensions = [
    { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } #vimium c
    { id = "cdglnehniifkbagbbombnjghhcihifij"; } #kagi search
    { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } #protonpass
    { id = "jchobbjgibcahbheicfocecmhocglkco"; } #neat url
    { id = "pfdeiaeaofodcolaiadjdflpejkofhpf"; } #simple adblocker - use it for camel.live
  ];

  thoriumConfigDirs =
    if isLinux then [
      "${config.xdg.configHome}/thorium"
      "${config.xdg.configHome}/Thorium"
      "${config.xdg.configHome}/chromium"
    ] else if isDarwin then [
      "${config.home.homeDirectory}/Library/Application Support/Thorium"
    ] else [ ];

  mkExtensionEntry = configDir: ext:
    lib.nameValuePair "${configDir}/External Extensions/${ext.id}.json" {
      text = builtins.toJSON (
        if ext ? crxPath
        then {
          external_crx = toString ext.crxPath;
          external_version = ext.version;
        }
        else {
          external_update_url = "https://clients2.google.com/service/update2/crx";
        }
      );
    };

  extensionFiles =
    lib.listToAttrs
      (lib.concatMap
        (configDir: builtins.map (mkExtensionEntry configDir) thoriumExtensions)
        thoriumConfigDirs);

in {
  home.packages = [
    inputs.thorium-browser.packages.${pkgs.system}.default
  ];

  xdg.desktopEntries = lib.mkIf isLinux {
    thorium-browser = {
      name = "Thorium Browser";
      genericName = "Web Browser";
      exec = "thorium-browser %U";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
    };
  };

  home.file = lib.mkIf (thoriumConfigDirs != [ ]) extensionFiles;
}
