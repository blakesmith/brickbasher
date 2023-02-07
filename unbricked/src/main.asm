INCLUDE "hardware.inc"

MACRO DisableLCD
        ; Turn the LCD off
        ld a, 0
        ld [rLCDC], a
ENDM

MACRO EnableLCD
        ; Turn the LCD on
        ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
        ld [rLCDC], a
ENDM

MACRO InitDisplayRegisters
        ; During the first (blank) frame, initialize the display registers
        ld a, %1100100
        ld [rBGP], a
        ld a, %11100100
        ld [rOBP0], a
ENDM

SECTION "Header", ROM0[$100]
        jp Init
        ds $150 - @, 0          ; Make room for the header

Init:
        call WaitVBlank
        DisableLCD
        call InitTileData
        call InitOAM
        call CopyDMARoutine
        call InitLevel
        EnableLCD
        InitDisplayRegisters
        jp Main

InitTileData:
        ; Copy tile data
        ld de, Tiles
        ld hl, $9000
        ld bc, TilesEnd - Tiles
        call Memcopy

        ; Copy the tilemap
        ld de, Tilemap
        ld hl, $9800
        ld bc, TilemapEnd - Tilemap
        call Memcopy

        ; Copy paddle tile data
        ld de, Paddle
        ld hl, $8000
        ld bc, PaddleEnd - Paddle
        call Memcopy

        ret

DEF BRICKS_START EQU 33
DEF BRICKS_PER_LINE EQU 6
DEF MAX_LINES EQU 3
DEF BRICK_LEFT_TILE EQU $05
DEF BRICK_RIGHT_TILE EQU $06
InitLevel:
        ld hl, _SCRN0 + BRICKS_START
        ld c, MAX_LINES + 1
.draw
        ld b, BRICKS_PER_LINE
        dec c
        ld a, 0
        cp c
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
        ld a, 0
        cp b
        jr nz, .draw_line
        jr .next_line
.next_line
        ;; Offset the RAM to jump to the next line.
        ld de, 20
        add hl, de
        jr .draw

Main:
        call WaitVBlank
        call ReadInput
        call MovePaddle
        call CopyOAM
        jp Main

WaitNotVBlank:
        ;;  Wait until not in VBLANK
        ld a, [rLY]
        cp SCRN_Y
        jp nc, WaitNotVBlank
        ret

WaitVBlank:
        ld a, [rLY]
        cp SCRN_Y
        jp c, WaitVBlank
        ret

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
        ld a, [de]
        ld [hli], a
        inc de
        dec bc
        ld a, b
        or a, c
        jp nz, Memcopy
        ret

MovePaddle:
.check_left
        ld a, [wCurKeys]
        and a, PADF_LEFT
        jr nz, .move_left
        jr z, .check_right
.move_left
        ld a, [paddle_oam_x]
        dec a
        ;;  If we're already at the end of the playfield, don't move
        cp a, 15
        ret z
        ld [paddle_oam_x], a
        ret

.check_right
        ld a, [wCurKeys]
        and a, PADF_RIGHT
        jr nz, .move_right
        ret z

.move_right
        ld a, [paddle_oam_x]
        inc a
        ;;  If we're already at the end of the playfield, don't move
        cp a, 105
        ret z
        ld [paddle_oam_x], a
        ret

