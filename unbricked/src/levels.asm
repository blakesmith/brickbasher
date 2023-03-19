EXPORT Level0, Level0End
EXPORT InitLevel
EXPORT wCurrentLevel, wCurrentLevelData

INCLUDE "include/hardware.inc"

DEF BRICKS_START EQU 33
DEF BRICKS_PER_LINE EQU 6
DEF MAX_BRICK_LINES EQU 5

SECTION "Current Level", WRAM0

wCurrentLevel: ds 1
wCurrentLevelData: ds MAX_BRICK_LINES
wCurrentBlock: ds 1

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

DEF WHITE_TILE EQU $00
DEF BLACK_TILE EQU $01
DEF LIGHT_GRAY_TILE EQU $08
DEF DARK_GRAY_TILE EQU $09
DEF BRICK_LEFT_TILE EQU $0A
DEF BRICK_RIGHT_TILE EQU $0B

DrawLevel:
        ;; Initialize current block counter
        ld a, 0
        ld [wCurrentBlock], a
        ;; Brick drawing position
        ld hl, _SCRN0 + BRICKS_START
        ;; Setup line counter
        ld c, MAX_BRICK_LINES + 1
.draw
        ld b, BRICKS_PER_LINE
        dec c
        jr nz, .check_brick
        ret
.check_brick
        ;; Load the current block from active level data
        push hl
        ld a, [wCurrentBlock]
        ld hl, wCurrentLevelData
        ld d, 0
        ld e, a
        add hl, de
        ld a, [hl]
        ld d, 1
        cp d
        pop hl
        jr z, .draw_brick
.skip_brick
        ;; There's no brick in this spot, skip drawing it!
        ld a, [wCurrentBlock]
        inc a
        ld [wCurrentBlock], a
        inc hl
        inc hl
        dec b
        jr nz, .check_brick
        jr z, .next_line
.draw_brick
        ;; There is a brick to draw in this spot, draw the correct tiles
        ld a, [wCurrentBlock]
        inc a
        ld [wCurrentBlock], a
        ld a, BRICK_LEFT_TILE
        ld [hli], a
        ld a, BRICK_RIGHT_TILE
        ld [hli], a
        dec b
        jr nz, .check_brick
.next_line
        ;; Offset the RAM to jump to the next line.
        ld de, 20
        add hl, de
        jr .draw
        
SECTION "Levels", ROM0

Level0:
        db 1,0,1,0,1,0
        db 0,1,0,1,0,1
        db 1,0,1,0,1,0
        db 0,1,0,1,0,1
        db 1,0,1,0,1,0
Level0End:
