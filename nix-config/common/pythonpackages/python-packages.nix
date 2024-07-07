{ pkgs }:

{
  selenium-profiles = pkgs.python3Packages.buildPythonPackage rec {
    pname = "selenium-profiles";
    version = "2.2.10";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/d1/82/99772a2f5951bd62de5e871056c374322aa951301503c065f001ea33cbbe/selenium_profiles-2.2.10.tar.gz";
      sha256 = "d2bb5c60c76c025f36bca62617875bc97dc2541cb25730e2dba50a3ddac95857";  # You need to provide the correct SHA256 hash
    };
    propagatedBuildInputs = with pkgs.python3Packages; [
      selenium 
    ];
    doCheck = false;
  };
}
