ROM = unbricked.gb

all: $(ROM)

ASM_FILES=main.asm input.asm tiles.asm dma.asm oam.asm levels.asm
SOUND_FILES=audio/hUGEDriver.asm audio/first_track.asm
SOURCE_FILES:=$(ASM_FILES) $(SOUND_FILES)
OBJECT_FILES=$(subst .asm,.o,$(SOURCE_FILES))

%.o: %.asm
	rgbasm -L -o $@ $<

%.gb: $(OBJECT_FILES)
	rgblink -o $@ $^
	rgbfix -v -p 0xFF $@

clean:
	rm -f *.o
	rm -f $(ROM)
