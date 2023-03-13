{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/release-22.11.tar.gz") {} }:

let
  hugetracker = pkgs.callPackage ./nix/pkgs/hugetracker {};
in

pkgs.mkShell {
  buildInputs = [
    pkgs.rgbds
    pkgs.vbam
    hugetracker
  ];
}
