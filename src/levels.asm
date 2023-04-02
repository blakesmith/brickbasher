EXPORT Level0, Level0End
EXPORT InitLevel
EXPORT wCurrentLevel, wCurrentLevelData, wLevelTableX, wLevelTableY

INCLUDE "src/include/hardware.inc"
INCLUDE "src/include/constants.inc"

SECTION "Current Level", WRAM0

wCurrentLevel: ds 1
wCurrentLevelData: ds (MAX_BRICK_LINES * BRICKS_PER_LINE)
wLevelTableX: ds (MAX_BRICK_LINES * BRICKS_PER_LINE)
wLevelTableY: ds (MAX_BRICK_LINES * BRICKS_PER_LINE)
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
        ret

DEF WHITE_TILE EQU $00
DEF BLACK_TILE EQU $01
DEF LIGHT_GRAY_TILE EQU $08
DEF DARK_GRAY_TILE EQU $09
DEF BRICK_LEFT_TILE EQU $0A
DEF BRICK_RIGHT_TILE EQU $0B

;; Calculates the top-left x,y coordinate of each
;; brick, and fills it into lookup table memory at wLevelTableX,
;; wLevelTableY, used for collision detection. Calculations are:
;;
;; brick_x = (PIXELS_PER_TILE * ((TILES_PER_BRICK * (BRICKS_PER_LINE - b - 1)) + PADDING_TILE_LEFT))
;; brick_y = ((PADDING_TILE_TOP + (MAX_BRICK_LINES - c)) * PIXELS_PER_TILE)
;; 
;; Inputs:
;; b register = current brick count in line
;; c regester = current line number.
;;
;; Should restore the b and c registers to their initial state
;; before returning.
PopulateBrickLookupTableCoordinates:
        push hl

        ;; Calculate x cordinate first
        ;; brick_x = (PIXELS_PER_TILE * ((TILES_PER_BRICK * (BRICKS_PER_LINE - b - 1)) + PADDING_TILE_LEFT))

        ld d, b
        ld a, BRICKS_PER_LINE
        sub a, d
        push bc
        ld c, a
        ld de, TILES_PER_BRICK
        ld a, 0
        ;; tile_count = ((TILES_PER_BRICK * (BRICKS_PER_LINE - b - 1))
        call mul8

        ;; bc == output from above multiplication call.
        ;; + PADDING_TILE_LEFT
        ld a, LOW(bc)
        add a, PADDING_TILE_LEFT
        ld d, 0
        ld e, a
        ld c, PIXELS_PER_TILE
        ld a, 0
        ;; PIXELS_PER_TILE * tile_count
        call mul8

        ;; x coordinate is now in bc. These results should only
        ;; ever be 8 bit, so we should be able to safetly only
        ;; take the low bits and put them in the lookup table
        ld d, LOW(bc)

        ;; Setup to write the x value out to our lookup table
        ld a, [wCurrentBlock]

        ;; Offset into the table
        ld hl, wLevelTableX
        ld b, 0
        ld c, a
        add hl, bc
        ;; Write out the x value into the table
        ld [hl], d

        ;; Calculate y coordinate next
        ;; brick_y = ((PADDING_TILE_TOP + (MAX_BRICK_LINES - c)) * PIXELS_PER_TILE)
        pop bc
        ld a, c
        push bc
        ld c, a
        ld a, MAX_BRICK_LINES
        ;; (MAX_BRICK_LINES - c)
        sub a, c
        ;; row_count = (PADDING_TILE_TOP + (MAX_BRICK_LINES - c))
        add a, PADDING_TILE_TOP

        ld d, 0
        ld e, a
        ld c, PIXELS_PER_TILE
        ld a, 0
        ;; PIXELS_PER_TILE * row count
        call mul8

        ;; y coordinate is now in bc. These results should only
        ;; ever be 8 bit, so we should be able to safetly only
        ;; take the low bits and put them in the lookup table
        ld d, LOW(bc)

        ;; Setup to write the y value out to our lookup table
        ld a, [wCurrentBlock]

        ;; Offset into the table
        ld hl, wLevelTableY
        ld b, 0
        ld c, a
        add hl, bc
        ;; Write out the x value into the table
        ld [hl], d

        ;; Restore used registers
        pop bc
        pop hl
        ret
        
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
        ;; There is a brick to draw in this spot

        call PopulateBrickLookupTableCoordinates

        ;; draw the correct tiles
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

;; Level0:
;;         db 0,0,0,0,0,0
;;         db 0,0,0,0,0,0
;;         db 0,0,0,0,0,0
;;         db 0,0,0,0,0,0
;;         db 0,0,1,0,0,0
;; Level0End:

Level0:
        db 1,0,1,0,1,0
        db 0,1,0,1,0,1
        db 1,0,1,0,1,0
        db 0,1,0,1,0,1
        db 1,0,1,0,1,0
Level0End:
