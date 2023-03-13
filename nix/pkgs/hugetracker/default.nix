{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/release-22.11.tar.gz") {},
  lib ? pkgs.lib,
  stdenv ? pkgs.stdenv
}:

with pkgs;

stdenv.mkDerivation rec {
  pname = "hugetracker";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "SuperDisk";
    repo = "hUGETracker";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "sha256-LLe6NinFx1Gk1C3SttSw9l1JVH8c5duqmNjF8B+WXBE=";
  };

  nativeBuildInputs = [ fpc lazarus rgbds ];

  buildInputs = [ atk cairo gdk-pixbuf glib gtk2 xorg.libX11 pango SDL2 fontconfig ];

  NIX_LDFLAGS = "--as-needed -rpath ${lib.makeLibraryPath buildInputs}";

  buildPhase = ''
    lazbuild --lazarusdir=${lazarus}/share/lazarus --pcp=./lazarus --build-mode="Production Linux" \
      src/rackctls/RackCtlsPkg.lpk \
      src/bgrabitmap/bgrabitmap/bgrabitmappack.lpk \
      src/hUGETracker.lpi
    rgbasm -E -i src/hUGEDriver -o hUGEDriver.obj src/hUGEDriver/hUGEDriver.asm
    rgbasm -i src/hUGEDriver/include -o halt.obj src/halt.asm
    rgblink -o halt.gb -n halt.sym halt.obj hUGEDriver.obj
    rgbfix -vp0xFF halt.gb
  '';

  installPhase = ''
    install -Dt $out/bin src/Release/hUGETracker
    install -m 0644 -Dt $out/bin fonts/PixeliteTTF.ttf
    install -m 0644 -Dt $out/bin halt.gb
    install -m 0644 -Dt $out/bin halt.sym
    cp -rv src/hUGEDriver $out/bin/hUGEDriver
  '';

  meta = with lib; {
    description = "The music composition suite for the Nintendo Game Boy";
    homepage = "https://nickfa.ro/index.php?title=HUGETracker";
    # In the public domain
    license = licenses.free;
    platforms = platforms.linux;
  };
}
