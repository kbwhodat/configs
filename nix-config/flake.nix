{
  description = "A template that shows all standard flake outputs";

  # Using Lix -- which essentially a nix upgrade with extra features and optimizations
  inputs.lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
  inputs.lix-module.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nil.url = "github:oxalica/nil";

  inputs.home-manager.url = "github:nix-community/home-manager/release-24.05";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs?ref=24.05";

  inputs.nur.url = "github:nix-community/NUR";

  inputs.darwin.url = "github:lnl7/nix-darwin";
  inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";

  # inputs.sops-nix.url = "github:Mic92/sops-nix";

  inputs.firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin/main";
  inputs.undetected-chromedriver.url = "github:kbwhodat/undetected-chromedriver/4c72090322eadeb7afaaebd287ad1d617c4733c2";

  inputs.gonchill.url = "github:kbwhodat/gonchill?ref=1.0.7";

  outputs = inputs@{ self, nixpkgs, home-manager, darwin, undetected-chromedriver, nil, nur, firefox-darwin, sops-nix, lix-module, gonchill,  ... }:

    let
      system = "x86_64-linux";
      overlays = [
        nur.overlay
        gonchill.overlay
        firefox-darwin.overlay
        undetected-chromedriver.overlay
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
            lix-module.nixosModules.default
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
            lix-module.nixosModules.default
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
            lix-module.nixosModules.default
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
