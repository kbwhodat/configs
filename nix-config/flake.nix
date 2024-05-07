{
  description = "A template that shows all standard flake outputs";

  # Inputs
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-inputs

  # The flake in the current directory.
  # inputs.currentDir.url = ".";

  # A flake in some other directory.
  # inputs.otherDir.url = "/home/alice/src/patchelf";

  # A flake in some absolute path
  # inputs.otherDir.url = "path:/home/alice/src/patchelf";

  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

	inputs.helix.url = "github:helix-editor/helix/master";

  # The nixpkgs entry in the flake registry.
  inputs.nixpkgsRegistry.url = "nixpkgs";

  # The nixpkgs entry in the flake registry, overriding it to use a specific Git revision.
  inputs.nixpkgsRegistryOverride.url = "nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";

  # The master branch of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgsGitHub.url = "github:NixOS/nixpkgs";

  # The nixos-20.09 branch of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgsGitHubBranch.url = "github:NixOS/nixpkgs/nixos-20.09";

  # A specific revision of the NixOS/nixpkgs repository on GitHub.
  inputs.nixpkgsGitHubRevision.url = "github:NixOS/nixpkgs/a3a3dda3bacf61e8a39258a0ed9c924eeca8e293";

  # A flake in a subdirectory of a GitHub repository.
  inputs.nixpkgsGitHubDir.url = "github:edolstra/nix-warez?dir=blender";

  # A git repository.
  inputs.gitRepo.url = "git+https://github.com/NixOS/patchelf";

  # A specific branch of a Git repository.
  inputs.gitRepoBranch.url = "git+https://github.com/NixOS/patchelf?ref=master";

  # A specific revision of a Git repository.
  inputs.gitRepoRev.url = "git+https://github.com/NixOS/patchelf?ref=master&rev=f34751b88bd07d7f44f5cd3200fb4122bf916c7e";

  # A tarball flake
  inputs.tarFlake.url = "https://github.com/NixOS/patchelf/archive/master.tar.gz";

  # A GitHub repository.
  inputs.import-cargo = {
    type = "github";
    owner = "edolstra";
    repo = "import-cargo";
  };

  # Inputs as attrsets.
  # An indirection through the flake registry.
  inputs.nixpkgsIndirect = {
    type = "indirect";
    id = "nixpkgs";
  };

  # Non-flake inputs. These provide a variable of type path.
  inputs.grcov = {
    type = "github";
    owner = "mozilla";
    repo = "grcov";
    flake = false;
  };

  # Transitive inputs can be overridden from a flake.nix file. For example, the following overrides the nixpkgs input of the nixops input:
  inputs.nixops.inputs.nixpkgs = {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
  };

  # It is also possible to "inherit" an input from another input. This is useful to minimize
  # flake dependencies. For example, the following sets the nixpkgs input of the top-level flake
  # to be equal to the nixpkgs input of the nixops input of the top-level flake:
  inputs.nixpkgs.url = "nixpkgs";
  inputs.nixpkgs.follows = "nixops/nixpkgs";

  # The value of the follows attribute is a sequence of input names denoting the path
  # of inputs to be followed from the root flake. Overrides and follows can be combined, e.g.
  inputs.nixops.url = "nixops";
  inputs.dwarffs.url = "dwarffs";
  inputs.dwarffs.inputs.nixpkgs.follows = "nixpkgs";

  # For more information about well-known outputs checked by `nix flake check`:
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake-check.html#evaluation-checks

  # These examples all use "x86_64-linux" as the system.
  # Please see the c-hello template for an example of how to handle multiple systems.

  inputs.c-hello.url = "github:NixOS/templates?dir=c-hello";
  inputs.rust-web-server.url = "github:NixOS/templates?dir=rust-web-server";
  inputs.nix-bundle.url = "github:NixOS/bundlers";


  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {

    nixosConfigurations.my-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
			specialArgs = { inherit inputs; };
      modules = [
      	./nixos/configuration.nix

				home-manager.nixosModules.home-manager
				{
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;

					home-manager.users.katob = import ./home.nix;
				}
      ]; 
    };

		darwinConfigurations.my-mac = nixpkgs.lib.darwinSystem {
			system = "x86_64-darwin";
			modules = [ ./darwin/configuration.nix ];
		};
  };
}
