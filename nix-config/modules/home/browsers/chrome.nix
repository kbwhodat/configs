{pkgs, lib, ...}:
let
  inherit (pkgs.stdenv) isDarwin;

  # ublock = pkgs.fetchzip {
  #   name = "ublock origin";
  #   url = "https://github.com/gorhill/uBlock/releases/download/1.66.5b0/uBlock0_1.66.5b0.chromium.zip";
  #   hash = "sha256-6cnogVZ+9HxQRIYze20aCWWbhaW7oplSyAOLbgMOwB8=";
  # };

in
{
  programs.chromium = {
    enable = if isDarwin then false else true;
    package = if isDarwin then 
      pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
    else
      pkgs.ungoogled-chromium;
    # commandLineArgs = [
    #   "--load-extension=${ublock}"
    #   "--load-extension=${privacybadger}"
    # ];
    extensions = [
      {
        id = "blockjmkbacgjkknlgpkjjiijinjdanf";
        crxPath = "${pkgs.fetchurl {
          url = "https://github.com/imputnet/ublock-origin-crx/releases/download/1.69.0/uBlock0_1.69.0.crx";
          sha256 = "sha256-cU7T6eHfihXmuec+jKtCCIfsdKxKjHotW5oMy3euP34=";
        }}";
        version = "1.69.0";
      }
      { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } #vimium c
      { id = "cdglnehniifkbagbbombnjghhcihifij"; } #kagi search
      { id = "egpjdkipkomnmjhjmdamaniclmdlobbo"; } #firenvim
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } #protonpass
      { id = "jchobbjgibcahbheicfocecmhocglkco"; } #neat url
      { id = "pfdeiaeaofodcolaiadjdflpejkofhpf"; } #simple adblocker - use it for camel.live
    ];
  };
}
