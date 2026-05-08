{ inputs, overlays }:
let
  # Resolve a profile name into the file that exists at the given layer
  # ("system" or "home"), or null if no file exists. Used by the factories
  # below. Profiles are not yet populated in Step 1, but the signature is
  # in place so Step 3 doesn't need to change the factory.
  profilePath = layer: name:
    let p = ../profiles + "/${layer}/${name}.nix";
    in if builtins.pathExists p then p else null;

  resolveProfiles = layer: profiles:
    builtins.filter (p: p != null) (map (profilePath layer) profiles);

  mkHost = {
    hostname,
    system,
    profiles ? [],
    extraModules ? [],
    homePath ? ../hosts + "/${hostname}/home.nix",
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        (../hosts + "/${hostname}/system.nix")
        inputs.home-manager.nixosModules.home-manager
        {
          networking.hostName = hostname;
          nixpkgs.overlays = overlays;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs hostname; };
            users.katob.imports = [ homePath ] ++ resolveProfiles "home" profiles;
            backupFileExtension = "backup";
          };
        }
      ] ++ resolveProfiles "system" profiles
        ++ extraModules;
    };

  mkDarwin = {
    hostname,
    system,
    profiles ? [],
    extraModules ? [],
    systemPath ? ../hosts + "/${hostname}/system.nix",
    homePath ? ../hosts + "/${hostname}/home.nix",
  }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        systemPath
        inputs.home-manager.darwinModules.home-manager
        {
          nixpkgs.overlays = overlays;
          users.users.katob = { name = "katob"; home = "/Users/katob"; };
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs hostname; };
            users.katob.imports = [ homePath ] ++ resolveProfiles "home" profiles;
            backupFileExtension = "backup";
          };
        }
      ] ++ resolveProfiles "system" profiles
        ++ extraModules;
    };
in {
  inherit mkHost mkDarwin;
}
