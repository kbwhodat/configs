{
  description = "A template that shows all standard flake outputs";

  inputs.nil.url = "github:oxalica/nil";

  inputs.home-manager.url = "github:nix-community/home-manager/release-24.05";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.nur.url = "github:nix-community/NUR";

  inputs.nix-darwin.url = "github:lnl7/nix-darwin";
  inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixos-23.11";

  inputs.nixgl.url = "github:guibou/nixGL";
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, nil, nur, nixgl, sops-nix, ... }:

  let
    system = "x86_64-linux";
    overlays = [
      nur.overlay
      # nixgl.overlay
    ];

    pkgs = import nixpkgs {
      inherit system;
      overlays = overlays;
      config = {
        allowUnfree = true;
      };
    };
  in {
    homeConfigurations = {
      linux = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [ 
          ./linux/home.nix 
        ];
      };
    };

    nixosConfigurations = {
      util = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./os/nixos/hosts/util/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./os/nixos/home;
            home-manager.backupFileExtension = "backup";
            nixpkgs.overlays = overlays;
          }
        ];
      };

      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./os/nixos/hosts/server/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./os/nixos/home;
            home-manager.backupFileExtension = "backup";
            nixpkgs.overlays = overlays;
          }
        ];
      };

      main = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./os/nixos/hosts/main/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./os/nixos/home;
            home-manager.backupFileExtension = "backup";
            nixpkgs.overlays = overlays;
          }
        ];
      };
    };

    darwinConfigurations = {

      mac-work = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./os/darwin/hosts/work/configuration.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./os/darwin/hosts/work/home;
            nixpkgs.overlays = overlays;

            users.users."katob".name = "katob";
            users.users."katob".home = "/Users/katob";
          }
        ];
      };

      mac-personal = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./os/darwin/hosts/personal/configuration.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./os/darwin/hosts/personal/home;
            nixpkgs.overlays = overlays;

            users.users."katob".name = "katob";
            users.users."katob".home = "/Users/katob";
          }
        ];
      };
    };
  };
}
