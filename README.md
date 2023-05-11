# Brickbasher Game Boy Game

![Brickbasher screenshot
ready
screen](https://raw.github.com/blakesmith/brickbasher/master/media/brickbasher_ready.png)

![Brickbasher screenshot playing screen](https://raw.github.com/blakesmith/brickbasher/master/media/brickbasher_playing.png)

This is a mostly complete Game Boy game, written entirely in Game Boy
specific 6502 assembly. It's based on the [gbdev.io
tutorial](https://gbdev.io/gb-asm-tutorial/part2/getting-started.html)
game called "unbricked". That tutorial basically stops at moving the
paddle around, and is very incomplete, omitting all the hard parts:

- Ball movement and bouncing.
- Collision detection with bricks.
- Populating brick locations based on level input.
- Game over / dead states
- Sound / music.
- Generating tiles from source tilemaps

... And much more.

## Building

You can build the ROM with the [Nix Package
manager](https://nixos.org/download.html).

1. Install Nix.
2. Enable flake support `echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf`

3. Build brickbasher. From within this directory:

```
nix build
```

The ROM will be in `./result/share/brickbasher.gb`.

There is also a "dev shell" with all the tools for development. Enable
it with:

```
nix develop
```

And then you can build brickbasher with plain old `make`:

```
make clean all
```

## License

MIT.
