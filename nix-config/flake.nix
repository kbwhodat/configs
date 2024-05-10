{
  description = "A template that shows all standard flake outputs";

  inputs.nil.url = "github:oxalica/nil";

	inputs.home-manager.url = "github:nix-community/home-manager/release-23.11";
	inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	# inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

	inputs.darwin.url = "github:lnl7/nix-darwin";
	inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nix-darwin.url = "github:lnl7/nix-darwin";
	inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixos-20.09";

	inputs.helix.url = "github:helix-editor/helix/master";

  # The master branch of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgsGitHub.url = "github:NixOS/nixpkgs";

  # The nixos-20.09 branch of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgsGitHubBranch.url = "github:NixOS/nixpkgs/nixos-20.09";

  # A specific revision of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgsGitHubRevision.url = "github:NixOS/nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";

  # A git repository.
  inputs.gitRepo.url = "git+https://github.com/NixOS/patchelf";

  # A specific branch of a Git repository.
  inputs.gitRepoBranch.url = "git+https://github.com/NixOS/patchelf?ref=master";

  # A specific revision of a Git repository.
  inputs.gitRepoRev.url = "git+https://github.com/NixOS/patchelf?ref=master&rev=f34751b88bd07d7f44f5cd3200fb4122bf916c7e";

  # A tarball flake
  inputs.tarFlake.url = "https://github.com/NixOS/patchelf/archive/master.tar.gz";


  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, nil, ... }: {

    nixosConfigurations.my-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
			specialArgs = { inherit inputs; };
      modules = [
      	./nixos/configuration.nix

				home-manager.nixosModules.home-manager
				{
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = { inherit inputs; };
					home-manager.users.katob = import ./nixos/home;
				}
      ]; 
    };

		darwinConfigurations.my-mac = nix-darwin.lib.darwinSystem {
			system = "x86_64-darwin";
			specialArgs = { inherit inputs; };
			modules = [ 
				./darwin/configuration.nix 

				home-manager.darwinModules.home-manager
				{
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = { inherit inputs; };
					home-manager.users.katob = import ./darwin/home;
					users.users.katob.home = "/Users/katob";
				}
			];
		};
  };
}
