{ config, pkgs, ... }:

{
  home.packages = with pkgs; [

    jfrog-cli
    openssl_legacy
    redis
    skopeo
    terraform
    act
    #jp
    # terragrunt
    sshuttle
    openconnect
    postman
    # bruno
    tcptraceroute
    # ansible_2_16
    util-linux
    # python311Packages.ansible
    redis
    mongosh
    awscli2
    undmg
    _7zz
    openstackclient
    wireshark
    libreoffice-bin
    slack
    # (python312Packages.bugwarrior.overrideAttrs (final: prev: {
    #   version = "develop";
    #   format = "pyproject";
    #
    #   build-system = with python312Packages; [ setuptools wheel ];
    #
    #   # Pull from GitHub instead of PyPI
    #   src = pkgs.fetchFromGitHub {
    #     owner  = "GothenburgBitFactory";
    #     repo   = "bugwarrior";
    #     rev    = "d166c3fe63bd541f72436d1d266bfdd43b76b87a";
    #     sha256 = "sha256-xpodsk4iAcZUgFsi1s1C9w3xshQtn2Vao4ZqowVst78";
    #   };
    #
    #   # Add deps required by newer develop versions
    #   propagatedBuildInputs = prev.propagatedBuildInputs ++ [
    #     python312Packages.pydantic
    #     python312Packages.setuptools 
    #     python312Packages.wheel
    #   ];
    # }))

    # (python313.withPackages (ps: with ps; let
    #   bugwarrior = ps.buildPythonPackage rec {
    #   pname = "bugwarrior";
    #   version = "develop";
    #   format = "pyproject";
    #   build-system = [ 
    #       setuptools 
    #       click
    #       dogpile-cache
    #       jinja2 
    #       lockfile 
    #       pydantic
    #       python-dateutil
    #       pytz
    #       requests
    #       taskw
    #       tomli
    #     ];
    #
    #   src = pkgs.fetchFromGitHub {
    #     owner = "GothenburgBitFactory";
    #     repo = "bugwarrior";
    #     rev = "develop";
    #     sha256 = "xpodsk4iAcZUgFsi1s1C9w3xshQtn2Vao4ZqowVst78=";
    #   };
    #   doCheck = false;
    #   };
    #
    # in [
    #     bugwarrior
    #     click
    #     dogpile-cache
    #     jinja2 
    #     lockfile 
    #     pydantic
    #     python-dateutil
    #     pytz
    #     requests
    #     tomli
    #     taskw
    #     distutils
    #     importlib-metadata
    # ]))

  ];
}
