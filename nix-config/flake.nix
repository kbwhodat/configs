{
  description = "A template that shows all standard flake outputs";

  inputs.nil.url = "github:oxalica/nil";

  inputs.home-manager.url = "github:nix-community/home-manager/release-24.05";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.nur.url = "github:nix-community/NUR";

  inputs.darwin.url = "github:lnl7/nix-darwin";
  inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixgl.url = "github:guibou/nixGL";
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  inputs.firefox-darwin.url = "github:kbwhodat/nixpkgs-firefox-darwin/9fcc5a8f8e7b31f1b6782423841d72cb0ed07581";

  outputs = inputs@{ self, nixpkgs, home-manager, darwin, nil, nur, nixgl, sops-nix, firefox-darwin,  ... }:

  let
    system = "x86_64-linux";
    overlays = [
      nur.overlay
      firefox-darwin.overlay
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

      mac-work = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./os/darwin/hosts/work/configuration.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./os/darwin/home;
            nixpkgs.overlays = overlays;
            home-manager.backupFileExtension = "backup";

            users.users."katob".name = "katob";
            users.users."katob".home = "/Users/katob";
          }
        ];
      };

      mac-personal = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./os/darwin/hosts/personal/configuration.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./os/darwin/home;
            nixpkgs.overlays = overlays;
            home-manager.backupFileExtension = "backup";

            users.users."katob".name = "katob";
            users.users."katob".home = "/Users/katob";
          }
        ];
      };
    };
  };
}
