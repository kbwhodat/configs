{pkgs, config, ...}:
let
  inherit (pkgs.stdenv) isDarwin;
  # Marker file to indicate personal mac - create this file only on mac-studio
  # Work mac won't have this file, so syncthing stays disabled
  isPersonalMac = builtins.pathExists /Users/katob/.config/syncthing-keys/personal-mac;
in
{
  services.syncthing = {
    enable = isDarwin && isPersonalMac;
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
    };
    settings.folders = {
      "/Users/katob/vault" = {
        id = "notes";
        devices = [ "mac-studio" "iphone" "nixos-main" "nixos-frame13" "nixos-util"];
      };
      "/Users/katob/Documents" = {
        id = "documents";
        devices = [ "mac-studio" "nixos-main" "nixos-frame13" "nixos-util"];
      };
    };
  };
}
