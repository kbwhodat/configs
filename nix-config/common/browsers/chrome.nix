{pkgs, ...}:
let
  inherit (pkgs.stdenv) isDarwin;

in
{
  programs.chromium = {
    enable = true;
    package = if isDarwin then 
      pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
    else
      pkgs.ungoogled-chromium;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } #ublock origin
      { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } #vimium c
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } #dark reader
      { id = "cdglnehniifkbagbbombnjghhcihifij"; } #kagi search
      { id = "egpjdkipkomnmjhjmdamaniclmdlobbo"; } #firenvim
      { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } #1password
      { id = "mdjildafknihdffpkfmmpnpoiajfjnjd"; } #consent-o-matic
      { id = "edibdbjcniadpccecjdfdjjppcpchdlm"; } #dontcareaboutcookies
      { id = "pfdeiaeaofodcolaiadjdflpejkofhpf"; } #simple adblocker - use it for camel.live
    ];
  };
}
