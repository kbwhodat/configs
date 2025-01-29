{ config, pkgs, ... }:

{
  home.packages = with pkgs; [

    jfrog-cli
    openssl_legacy
    redis
    skopeo
    terraform
    act
    putty
    #jp
    terragrunt
    sshuttle
    openconnect
    postman
    #google-cloud-sdk
    tcptraceroute
    # ansible_2_16
    util-linux
    # python311Packages.ansible
    redis
    mongosh
    awscli2
    undmg
    _7zz
    # openstackclient
  ];
}
