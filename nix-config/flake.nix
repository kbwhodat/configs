{
  description = "A shared Nix configuration for NixOS and macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {};
        };
      in
      {
        nixosConfigurations.my-nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nixos/configuration.nix ];
        };

        darwinConfigurations.my-mac = pkgs.darwinSystem {
          system = "x86_64-darwin";
          modules = [ ./darwin/configuration.nix ];
        };
      });
}

