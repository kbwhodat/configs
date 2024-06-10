{ config, pkgs, ... }:

{
  home.packages = with pkgs; [

    terraform
    sshuttle
    openconnect
    google-cloud-sdk
    ansible
    redis
    mongosh


  ];
}
