{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/release-22.11.tar.gz") {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.rgbds
    pkgs.sameboy
  ];
}
