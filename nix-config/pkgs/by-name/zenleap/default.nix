{ lib, stdenvNoCC, fetchFromGitHub }:

let
  # Fetch fx-autoconfig separately
  fxAutoconfig = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "fx-autoconfig";
    rev = "master";
    sha256 = "sha256-xiCikg8c855w+PCy7Wmc3kPwIHr80pMkkK7mFQbPCs4=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "zenleap";
  version = "unstable-2026-02-26";

  src = fetchFromGitHub {
    owner = "yashas-salankimatt";
    repo = "ZenLeap";
    rev = "main";
    sha256 = "sha256-SWrT1m6WB2oSNY2lSBoC8scixAJnLjyZIa+flZ8HPQk=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # ZenLeap files
    mkdir -p $out/js $out/css
    cp JS/zenleap.uc.js $out/js/
    cp chrome.css $out/css/zenleap.css
    
    # Optional themes file
    if [ -f zenleap-themes.json ]; then
      cp zenleap-themes.json $out/
    fi

    # fx-autoconfig program files (for browser directory)
    mkdir -p $out/fxautoconfig-program/defaults/pref
    cp ${fxAutoconfig}/program/config.js $out/fxautoconfig-program/
    cp ${fxAutoconfig}/program/defaults/pref/config-prefs.js $out/fxautoconfig-program/defaults/pref/

    # fx-autoconfig profile files (for chrome/utils/)
    mkdir -p $out/fxautoconfig-profile
    cp -r ${fxAutoconfig}/profile/chrome/* $out/fxautoconfig-profile/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Vim-style keyboard navigation, tab search, and command palette for Zen Browser";
    homepage = "https://github.com/yashas-salankimatt/ZenLeap";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
