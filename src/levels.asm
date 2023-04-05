EXPORT Level0, Level0End

EXPORT LevelTileTable, LevelTileTableEnd
EXPORT InitLevel, SetFirstLevel
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

SetFirstLevel:
        ld a, 0
        ld [wCurrentLevel], a
        ret

InitLevel:
        call CopyCurrentLevel
        call DrawLevel
        ret

CopyCurrentLevel:
        ld d, 0
        ld a, [wCurrentLevel]
        ld e, a
        ld c, 2
        ld a, 0
        call mul8

        ld hl, LevelArray
        add hl, bc

        ;; If we're at the end of the level array: You win!
        ld de, LevelArrayEnd
        ld a, h
        cp a, d
        jr nz, .do_load
        ld a, l
        cp a, e
        jp z, WinGame

.do_load
        ld a, [hl]
        ld e, a
        inc hl
        ld a, [hl]
        ld d, a
        ld hl, wCurrentLevelData
        ld bc, LEVEL_SIZE
        call Memcopy
        ret

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
        ld d, 0
        cp a, d
        pop hl
        jp nz, .draw_brick
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


SECTION "LevelTileTable", ROM0

;; This maps from a brick index, to its tile position added to the screen offset.
;; This is used so we can quickly remove a brick from the tilemap when it needs to
;; be destroyed.
LevelTileTable:
        db 0, 2, 4, 6, 8, 10
        db 32, 34, 36, 38, 40, 42
        db 64, 66, 68, 70, 72, 74
        db 96, 98, 100, 102, 104, 106
        db 128, 130, 132, 134, 136, 138
LevelTileTableEnd:

        
SECTION "Levels", ROM0[$1300]

;; Level0:
;;         db 0,0,0,0,0,0
;;         db 0,0,0,0,0,0
;;         db 0,0,0,0,0,0
;;         db 0,0,0,0,0,0
;;         db 0,0,2,0,0,0

;; Level0:
;;         db 2,0,2,0,2,0
;;         db 0,2,0,2,0,2
;;         db 2,0,2,0,2,0
;;         db 0,2,0,2,0,2
;;         db 2,0,2,0,2,0

Level0:
        db 2,2,2,2,2,2
        db 2,2,2,2,2,2
        db 2,2,2,2,2,2
        db 2,2,2,2,2,2
        db 2,2,2,2,2,2

Level1:
        db 2,0,0,0,0,0
        db 2,2,0,0,0,0
        db 2,2,2,0,0,0
        db 2,2,2,2,0,0
        db 2,2,2,2,2,0

;; Ordered list of levels. Once we get to the end of this list,
;; you win the game.
LevelArray:
        dw Level0,
        dw Level1,
LevelArrayEnd:
