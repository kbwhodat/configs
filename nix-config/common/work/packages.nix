{ config, pkgs, ... }:

{
  home.packages = with pkgs; [

    terraform
    putty
    #jp
    terragrunt
    sshuttle
    openconnect
    google-cloud-sdk
    ansible
    python311Packages.ansible
    redis
    mongosh
    awscli2
    openstackclient
  ];
}
