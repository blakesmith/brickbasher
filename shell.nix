{ pkgs, gbtile }:

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
