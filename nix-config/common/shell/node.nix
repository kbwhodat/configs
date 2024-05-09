{ pkgs, config, ...}: 

{
  environment.systemPackages = [
    pkgs.nodejs_21;
  ];
}
