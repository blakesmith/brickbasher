ROM = unbricked.gb

all: $(ROM)

SOURCE_FILES=main.asm input.asm tiles.asm dma.asm oam.asm
OBJECT_FILES=$(subst .asm,.o,$(SOURCE_FILES))

%.o: %.asm
	rgbasm -L -o $@ $<

%.gb: $(OBJECT_FILES)
	rgblink -o $@ $^
	rgbfix -v -p 0xFF $@

clean:
	rm -f *.o
	rm $(ROM)
