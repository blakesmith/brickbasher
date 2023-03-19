{ pkgs, stdenv, gbtile }:

stdenv.mkDerivation {
  name = "brickbasher";
  version = "0.1";
  src = ./.;

  buildInputs = [
    pkgs.rgbds
    gbtile
  ];

  buildPhase = ''
  make all
  '';

  installPhase = ''
  mkdir -p $out/share
  cp brickbasher.gb $out/share
  '';
}
