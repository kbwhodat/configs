{pkgs, lib, config, ...}:
let
  inherit (pkgs.stdenv) isDarwin;
  rawHostName = builtins.readFile (pkgs.runCommand "hostname" {} ''
    ${pkgs.toybox}/bin/toybox hostname > "$out"
  '');
  hostName = lib.strings.removeSuffix "\n" rawHostName;
  isPersonalMac =
    isDarwin &&
    builtins.elem hostName [
      "mac-mini"
      "mac-studio"
      "macos-mini"
      "macos-studio"
    ];
in
{
  home.activation.syncthing-keys =
    lib.mkIf isPersonalMac ''
      if [ ! -f "/Users/katob/.config/syncthing-keys/key.pem" ] || \
         [ ! -f "/Users/katob/.config/syncthing-keys/cert.pem" ]; then
        mkdir -p /Users/katob/.config/syncthing-keys
        openssl req -x509 -newkey rsa:4096 \
          -keyout /Users/katob/.config/syncthing-keys/key.pem \
          -out /Users/katob/.config/syncthing-keys/cert.pem \
          -days 3650 -nodes -subj "/CN=Syncthing"
      fi
    '';

  services.syncthing = {
    enable = isPersonalMac;
    key = "/Users/katob/.config/syncthing-keys/key.pem";
    cert = "/Users/katob/.config/syncthing-keys/cert.pem";
    settings.gui = {
      theme = "black";
    };
    settings.devices = {
      "iphone" = {
        id = "V5SVN25-M2CS2HQ-T2QIERP-HQ47OOC-YLDGWKB-EEGBAVK-4BB5JJF-VNASBA2";
      };
      "nixos-main" = {
        id = "UQAWJXF-VFHDTRI-AIEFOLH-OMVHBYD-X5MKXTN-CQJWEKV-47JOT5P-TMIXGA5";
      };
      "nixos-frame13" = {
        id = "IMNRAP7-RZNJQFO-GOZLSJN-RHWC55N-WRODY7I-SNJCDBH-MZODTPJ-W7CZRQX";
      };
      "nixos-util" = {
        id = "QZJBK62-4DPFF7J-T3PQRU6-HT4SBIY-5H7INBX-F5OMPBS-LLUONWG-KIJL5A3";
      };
      "mac-studio" = {
        id = "BOVCXJY-FCRVFJS-DFJ667E-ICJHPSR-U5K7YQI-M4Q6NEW-6NTLGWB-EE2BSAE";
      };
      "mac-mini" = {
        id = "H7W24KI-NCXB5V3-DKB63K7-ZMJVQ6Y-AOD5C4Q-C5JQMVL-A5BMX54-4RPRAAF";
      };
    };
    settings.folders = {
      "/Users/katob/vault" = {
        id = "notes";
        devices = ["mac-mini" "mac-studio" "iphone" "nixos-main" "nixos-frame13" "nixos-util"];
      };
      "/Users/katob/Documents" = {
        id = "documents";
        devices = ["mac-mini" "mac-studio" "nixos-main" "nixos-frame13" "nixos-util"];
      };
    };
  };
}
