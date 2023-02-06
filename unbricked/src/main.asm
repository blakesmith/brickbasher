INCLUDE "hardware.inc"

def SCREEN_WIDTH  equ 160 ; In pixels
def SCREEN_HEIGHT equ 144

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

SECTION "Header", ROM0[$100]
        jp Init
        ds $150 - @, 0          ; Make room for the header

Init:
        call WaitVBlank
        DisableLCD

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

        ; Clear OAM memory
        ld a, 0
        ld b, SCREEN_WIDTH
        ld hl, _OAMRAM
.clear_oam
        ld [hli], a
        dec b
        jp nz, .clear_oam
        
        ; Fill in OAM
        ld hl, _OAMRAM
        ld a, 128 + 16
        ld [hli], a
        ld a, 16 + 8
        ld [hli], a
        ld a, 0
        ld [hli], a
        ld [hl], a

        ; Copy paddle tile data
        ld de, Paddle
        ld hl, $8000
        ld bc, PaddleEnd - Paddle
        call Memcopy

        EnableLCD

        ; During the first (blank) frame, initialize the display registers
        ld a, %1100100
        ld [rBGP], a
        ld a, %11100100
        ld [rOBP0], a

Main:
        call WaitNotVBlank
        call WaitVBlank
        call ReadInput
        call MovePaddle
        jp Main

WaitNotVBlank:
        ;;  Wait until not in VBLANK
        ld a, [rLY]
        cp SCREEN_HEIGHT
        jp nc, WaitNotVBlank
        ret

WaitVBlank:
        ld a, [rLY]
        cp SCREEN_HEIGHT
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
        ld a, [_OAMRAM + 1]
        dec a
        ;;  If we're already at the end of the playfield, don't move
        cp a, 15
        ret z
        ld [_OAMRAM + 1], a
        ret

.check_right
        ld a, [wCurKeys]
        and a, PADF_RIGHT
        jr nz, .move_right
        ret z

.move_right
        ld a, [_OAMRAM + 1]
        inc a
        ;;  If we're already at the end of the playfield, don't move
        cp a, 105
        ret z
        ld [_OAMRAM + 1], a
        ret

