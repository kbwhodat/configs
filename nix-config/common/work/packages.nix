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
    jiratui
    python313Packages.uv


  ];
}
