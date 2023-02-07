EXPORT Level0, Level0End
EXPORT InitLevel
EXPORT wCurrentLevel, wCurrentLevelData

INCLUDE "hardware.inc"

DEF BRICKS_START EQU 33
DEF BRICKS_PER_LINE EQU 6
DEF MAX_BRICK_LINES EQU 5

SECTION "Current Level", WRAM0

wCurrentLevel: ds 1
wCurrentLevelData: ds MAX_BRICK_LINES

SECTION "Level functions", ROM0

InitLevel:
        ld a, 0
        ld [wCurrentLevel], a
        call CopyCurrentLevel
        call DrawLevel
        ret

CopyCurrentLevel:
        ld de, Level0
        ld hl, wCurrentLevelData
        ld bc, Level0End - Level0
        call Memcopy

DEF BRICK_LEFT_TILE EQU $05
DEF BRICK_RIGHT_TILE EQU $06

DrawLevel:
        ld hl, _SCRN0 + BRICKS_START
        ld c, MAX_BRICK_LINES + 1
.draw
        ld b, BRICKS_PER_LINE
        dec c
        jr nz, .draw_line
        ret
.draw_line
        ;; Draw a single line of bricks. Each brick is
        ;; made up of two tiles.
        ld a, BRICK_LEFT_TILE
        ld [hli], a
        ld a, BRICK_RIGHT_TILE
        ld [hli], a
        dec b
        jr nz, .draw_line
.next_line
        ;; Offset the RAM to jump to the next line.
        ld de, 20
        add hl, de
        jr .draw
        
SECTION "Levels", ROM0

Level0:
        dw %01010100
        dw %10101000
        dw %01010100
        dw %10101000
        dw %01010100
Level0End:
