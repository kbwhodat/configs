{ config, pkgs, ... }:

{
  home.packages = with pkgs; [

    terraform
    terragrunt
    sshuttle
    openconnect
    google-cloud-sdk
    ansible
    redis
    mongosh
    awscli2
    openstackclient
  ];
}
