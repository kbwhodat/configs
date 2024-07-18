self: super: {
  python3Packages = super.python3Packages // {
    selenium-profiles = self.python3Packages.callPackage ./python-packages.nix { };
  };
}
