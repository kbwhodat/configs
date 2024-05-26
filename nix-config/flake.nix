{
  description = "A template that shows all standard flake outputs";

  inputs.nil.url = "github:oxalica/nil";

  inputs.home-manager.url = "github:nix-community/home-manager/release-23.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.nur.url = "github:nix-community/NUR";

  inputs.darwin.url = "github:lnl7/nix-darwin";
  inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nix-darwin.url = "github:lnl7/nix-darwin";
  inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixos-23.11";

  inputs.helix.url = "github:helix-editor/helix/master";

  inputs.nixgl.url = "github:guibou/nixGL";

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, nil, nur, nixgl, ... }:

  let
    system = "x86_64-linux";
    overlays = [
      nur.overlay
      nixgl.overlay
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
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = pkgs;
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./nixos/home;
            nixpkgs.overlays = overlays;
          }
        ];
      };
    };

    darwinConfigurations = {
      mac = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.katob = import ./darwin/home;
            nixpkgs.overlays = overlays;

            users.users."katob".name = "katob";
            users.users."katob".home = "/Users/katob";
          }
        ];
      };
    };
  };
}
