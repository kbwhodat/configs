{
  description = "A template that shows all standard flake outputs";

  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  # Using Lix -- which essentially a nix upgrade with extra features and optimizations
  # inputs.lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
  # inputs.lix-module.inputs.nixpkgs.follows = "nixpkgs";

  #inputs.nil.url = "github:oxalica/nil";

  #inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur.inputs.nixpkgs.follows = "nixpkgs";

  inputs.darwin.url = "github:lnl7/nix-darwin";
  inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";

  inputs.firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin/main";
  inputs.zen-browser.url = "github:kbwhodat/zen-browser-flake";
  inputs.zen-browser.inputs.nixpkgs.follows = "nixpkgs";

  inputs.undetected-chromedriver.url = "github:kbwhodat/undetected-chromedriver/8b0bd1e599c8367040eb5578f9c191846945f838";

  inputs.gonchill.url = "github:kbwhodat/gonchill?ref=1.0.9";

  outputs = inputs@{ self, nixpkgs, nixos-hardware, home-manager, darwin, undetected-chromedriver, nur, firefox-darwin, sops-nix, gonchill, zen-browser, ... }:

    let
      system = "x86_64-linux";

      overlays = [
        nur.overlays.default
        gonchill.overlay
        firefox-darwin.overlay
        undetected-chromedriver.overlay
        (import ./pkgs/overlay.nix)
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

        frame16 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./os/nixos/hosts/frame16/configuration.nix
            inputs.nixos-hardware.nixosModules.framework-16-7040-amd
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

        frame13 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./os/nixos/hosts/frame13/configuration.nix
            nixos-hardware.nixosModules.framework-13-7040-amd
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.katob = import ./os/nixos/hosts/frame13/home;
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
