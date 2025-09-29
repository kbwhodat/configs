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
          url = "https://github.com/imputnet/ublock-origin-crx/releases/download/1.66.4/uBlock0_1.66.4.crx";
          # use correct sha256
          sha256 = "sha256-woCbtM0vOmud38XhZcunSiAM2AymkVIfc9mL9atavO8=";
        }}";
        version = "1.66.4";
      }
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } #privacy badger
      { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } #vimium c
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } #dark reader
      { id = "cdglnehniifkbagbbombnjghhcihifij"; } #kagi search
      { id = "egpjdkipkomnmjhjmdamaniclmdlobbo"; } #firenvim
      { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } #1password
      { id = "mdjildafknihdffpkfmmpnpoiajfjnjd"; } #consent-o-matic
      { id = "edibdbjcniadpccecjdfdjjppcpchdlm"; } #dontcareaboutcookies
      { id = "pfdeiaeaofodcolaiadjdflpejkofhpf"; } #simple adblocker - use it for camel.live
      { id = "nomnklagbgmgghhjidfhnoelnjfndfpd"; } #canvas blocker
    ];
  };
}
