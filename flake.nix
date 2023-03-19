{
  description = "BrickBasher GameBoy Game";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/22.05";
    flake-utils.url = "github:numtide/flake-utils";
    gbtile.url = "github:blakesmith/gbtile";
  };

  outputs = { self, flake-utils, nixpkgs, gbtile }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        rec {
          packages.brick-basher = pkgs.callPackage ./default.nix { gbtile = gbtile.packages.${system}.gbtile; };
          defaultPackage = packages.brick-basher;
          devShells.plain = import ./shell.nix;
        }
    );
}
