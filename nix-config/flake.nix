{
  description = "A template that shows all standard flake outputs";

  inputs.nil.url = "github:oxalica/nil";

	inputs.home-manager.url = "github:nix-community/home-manager/release-23.11";
	inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	# inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.nur.url = "github:nix-community/NUR";

	inputs.darwin.url = "github:lnl7/nix-darwin";
	inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nix-darwin.url = "github:lnl7/nix-darwin";
	inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixos-23.11";

	inputs.helix.url = "github:helix-editor/helix/master";


  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, nil, nur, ... }: {

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
			specialArgs = { inherit inputs; };
      modules = [
      	./nixos/configuration.nix


				home-manager.nixosModules.home-manager
				{
          nixpkgs.overlays = [
            nur.overlay
          ];

					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = { inherit inputs; };
					home-manager.users.katob = import ./nixos/home;
				}
      ]; 
    };

		darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
			system = "x86_64-darwin";
			specialArgs = { inherit inputs; };
			modules = [ 
				./darwin/configuration.nix 

				home-manager.darwinModules.home-manager
				{
          nixpkgs.overlays = [
            nur.overlay
          ];

					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;

          home-manager.users.katob = import ./darwin/home;
          home-manager.extraSpecialArgs = { inherit inputs; };

          users.users."katob".name = "katob";
          users.users."katob".home = "/Users/katob";
				}
			];
		};
  };
}
