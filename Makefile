ROM = brickbasher.gb

all: $(ROM)

TILE_SHEETS=tiles/TileSheet.png.asm tiles/Paddle.png.asm tiles/Ball.png.asm
ASM_FILES=src/main.asm src/input.asm src/tiles.asm src/dma.asm src/oam.asm src/levels.asm
SOUND_FILES=audio/hUGEDriver.asm audio/first_track.asm
SOURCE_FILES:=$(ASM_FILES) $(SOUND_FILES) $(TILE_SHEETS)
OBJECT_FILES=$(subst .asm,.o,$(SOURCE_FILES))

%.o: %.asm
	rgbasm -L -o $@ $<

%.gb: $(OBJECT_FILES)
	rgblink -o $@ $^
	rgbfix -v -p 0xFF $@

%.png.asm: %.png
	gbtile -t rgbds -i $< -o $@

clean:
	rm -f src/*.o
	rm -f audio/*.o
	rm -f tiles/*.asm
	rm -f tiles/*.o
	rm -f $(ROM)

.PRECIOUS: tiles/TileSheet.png.asm tiles/Paddle.png.asm tiles/Ball.png.asm
