{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/release-22.11.tar.gz") {},
  gbtile
}:

let
  hugetracker = pkgs.callPackage ./nix/pkgs/hugetracker {};
in

pkgs.mkShell {
  buildInputs = [
    pkgs.mednafen
    pkgs.rgbds
    pkgs.vbam
    hugetracker
  ];
}
