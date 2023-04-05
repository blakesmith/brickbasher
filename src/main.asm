INCLUDE "src/include/hardware.inc"
INCLUDE "src/include/constants.inc"

EXPORT Memcopy, WinGame

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
        ld a, %11011000
        ld [rBGP], a
        ld a, %11100100
        ld [rOBP0], a
ENDM

MACRO BounceBallLeft
        ld a, [wBallMoveState]
        xor a, BALL_MOVE_RIGHT
        ld [wBallMoveState], a
ENDM

MACRO BounceBallRight
        ld a, [wBallMoveState]
        or a, BALL_MOVE_RIGHT
        ld [wBallMoveState], a
ENDM

MACRO BounceBallDown
        ld a, [wBallMoveState]
        xor a, BALL_MOVE_UP
        ld [wBallMoveState], a
ENDM

MACRO BounceBallUp
        ld a, [wBallMoveState]
        or a, BALL_MOVE_UP
        ld [wBallMoveState], a
ENDM

SECTION "Timer overflow interrupt", ROM0[$0050]
    nop
    jp isr_wrapper

isr_wrapper:
    push af
    push hl
    push bc
    push de
    call hUGE_dosound
    pop de
    pop bc
    pop hl
    pop af
    reti


SECTION "Working Variables", WRAM0

DEF BALL_MOVE_RIGHT EQU 1 << 1
DEF BALL_MOVE_UP    EQU 1 << 2

wLives: ds 1
wPaddleX: ds 1
wFrameTick: ds 1
 
;; Whether the ball is moving BALL_MOVE_LEFT, BALL_MOVE_RIGHT, BALL_MOVE_UP or BALL_MOVE_DOWN
;; Note that a ball can be moving along the X axis (BALL_MOVE_LEFT, BALL_MOVE_RIGHT) and the
;; Y axis (BALL_MOVE_UP, BALL_MOVE_DOWN) at the same time.
wBallMoveState: ds 1

;; If the ball is moving on the X axis, how many pixels velocity is it moving per frame?
wBallVelocityX: ds 1
;; If the ball is moving on the Y axis, how many pixels velocity is it moving per frame?
wBallVelocityY: ds 1

SECTION "Header", ROM0[$100]
        jp Init
        ds $150 - @, 0          ; Make room for the header

Init:
        call WaitVBlank
        DisableLCD
        call InitTileData
        call InitOAM
        call CopyDMARoutine
        call SetFirstLevel
        call InitLevel
        call InitLives
        call UpdateLives
        call InitGameObjects
        call InitAudio
        EnableLCD
        InitDisplayRegisters

        ;; Initialize frame tick
        ld a, 0
        ld [wFrameTick], a
        jp Main

InitTileData:
        ; Copy tile data
        ld de, TileSheet
        ld hl, $9000
        ld bc, TileSheet_end - TileSheet
        call Memcopy

        ; Copy the tilemap
        ld de, Tilemap
        ld hl, $9800
        ld bc, TilemapEnd - Tilemap
        call Memcopy

        ; Copy paddle tile data
        ld de, Paddle
        ld hl, $8000
        ld bc, Paddle_end - Paddle
        call Memcopy

        ld de, Ball
        ld hl, $8030
        ld bc, Ball_end - Ball
        call Memcopy

        ret

Main:
        call WaitVBlank
        call TickFrame
        call ReadInput
        call BallWallCollisions
        call BallPaddleCollisions
        call BallBrickCollisions
        call MoveBall
        call MovePaddle
        call DrawObjects
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

TickFrame:
        ld hl, wFrameTick
        inc [hl]
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

InitAudio:
        ;; Turn audio on
        ld a, $80
        ld [rAUDENA], a
        ld a, $FF
        ld [rAUDTERM], a
        ld a, $77
        ld [rAUDVOL], a

        ;; Start playing audio track
        ld hl, first_track
        call hUGE_init
        ret

InitLives:
        ld a, LIVES_PER_GAME
        ld [wLives], a
        ret

WinGame:
        ;; TODO: Implement!
        jp WinGame

GameOver:
        ;; TODO: Implement!
        jp GameOver

InitGameObjects:
        ;; Setup paddle sprites
        ld a, 0
        ld [paddle_1_oam_tile], a
        ld a, 1
        ld [paddle_2_oam_tile], a
        ld a, 2
        ld [paddle_3_oam_tile], a

        ld a, PADDLE_Y
        ld [paddle_1_oam_y], a
        ld [paddle_2_oam_y], a
        ld [paddle_3_oam_y], a

        ld a, 0
        ld [paddle_1_oam_flags], a
        ld [paddle_2_oam_flags], a
        ld [paddle_3_oam_flags], a

        ld [paddle_1_oam_x], a
        ld [paddle_2_oam_x], a
        ld [paddle_3_oam_x], a

        ;; Setup ball sprite
        ld a, 0
        ld [ball_oam_flags], a
        ld a, 3
        ld [ball_oam_tile], a
        
        ;; Center the paddle to start
        ld a, PLAYFIELD_X_MIDDLE
        ld [wPaddleX], a

        ;; Init initial ball position
        ld a, PLAYFIELD_X_MIDDLE
        ld [ball_oam_x], a
        ld a, PLAYFIELD_Y_MIDDLE
        ld [ball_oam_y], a

        ;; Initial ball state
        ld a, BALL_MOVE_RIGHT
        ld [wBallMoveState], a
        ld a, 1
        ld [wBallVelocityX], a
        ld [wBallVelocityY], a

        ret

;; Check to see if the ball hits the far right or left of the paddle (PADDLE_EDGE_DISTANCE), using some constant pixel distance.
;; The ball should only accelerate if it's moving in the direction of the edge it hits.
;;
;; For example: If the ball is moving rightward, it should only accelerate if it hits the right side of the paddle.
;; If the ball is moving leftward, it should only accelerate if it hits the left side of the paddle.
;; Input registers:
;; d: The pixel distance from the left of the paddle. 0x0 == more towards the left of the paddle.
;; e: The overflow distance from the right of the paddle. 0xFF == more towards the right of the paddle.
ToggleBallXVelocity:
        ld a, [wBallMoveState]
        and a, BALL_MOVE_RIGHT
        jr nz, .check_right_edge_hit
        jr z, .check_left_edge_hit
.check_right_edge_hit
        ld a, $FF - PADDLE_EDGE_DISTANCE
        sub a, e
        jr c, .increase_velocity
        jr nc, .decrease_velocity
 .check_left_edge_hit
        ld a, PADDLE_EDGE_DISTANCE
        sub a, d
        jr nc, .increase_velocity
        jr c, .decrease_velocity
.decrease_velocity
        ld a, 1
        ld [wBallVelocityX], a
        ret
.increase_velocity
        ld a, 2
        ld [wBallVelocityX], a
        ret

MoveBall:
.check_right
        ld a, [wBallMoveState]
        and a, BALL_MOVE_RIGHT
        jr nz, .move_right
        jr z, .move_left
.check_up
        ld a, [wBallMoveState]
        and a, BALL_MOVE_UP
        jr nz, .move_up
        jr z, .move_down
.done
        ret
.move_right
        ld a, [wBallVelocityX]
        ld b, a
        ld a, [ball_oam_x]
        add a, b
        ld [ball_oam_x], a
        jp .check_up
.move_left
        ld a, [wBallVelocityX]
        ld b, a
        ld a, [ball_oam_x]
        sub a, b
        ld [ball_oam_x], a
        jp .check_up
.move_up
        ld a, [wBallVelocityY]
        ld b, a
        ld a, [ball_oam_y]
        sub a, b
        ld [ball_oam_y], a
        jp .done
.move_down
        ld a, [wBallVelocityY]
        ld b, a
        ld a, [ball_oam_y]
        add a, b
        ld [ball_oam_y], a
        jp .done

BallDead:
        ld a, [wLives]
        dec a
        jp z, GameOver

        ld [wLives], a
        call InitGameObjects
        call UpdateLives

        ret

BallWallCollisions:
.check_right
        ld a, [ball_oam_x]
        cp a, PLAYFIELD_X_END
        jr z, .bounce_left
.check_left
        ld a, [ball_oam_x]
        cp a, PLAYFIELD_X_START
        jr z, .bounce_right
.check_top
        ld a, [ball_oam_y]
        cp a, PLAYFIELD_Y_TOP
        jr z, .bounce_bottom
.check_bottom
        ld a, [ball_oam_y]
        cp a, PLAYFIELD_Y_BOTTOM
        jp z, BallDead
.done
        ret

.bounce_left
        BounceBallLeft
        jp .check_left
.bounce_right
        BounceBallRight
        jp .check_top
.bounce_bottom
        BounceBallDown
        jp .check_bottom

BallPaddleCollisions:
        ;; Check y position, cheaper to return early on this one
        ld a, [ball_oam_y]
        cp a, PADDLE_Y - 4
        ret nz

        ;; Check ball x position is greater than the left side of the paddle
        ;; Note that wPaddleX is the center point of the left most paddle sprite.
        ld a, [wPaddleX]
        sub a, 3 ; While the midpoint for a single sprite would be 4 pixels, the sprite stops one pixel before, so 3
        ld b, a
        ld a, [ball_oam_x]
        sub a, b
        ld d, a
        ret c

        ;; And check the ball x position is less than the right side of the paddle
        ld a, [wPaddleX]
        add a, 19 ; Since we're starting from the left most paddle sprite, add 16 (2 sprites), plus another 3 pixels to get to the end of the right most sprite
        ld b, a
        ld a, [ball_oam_x]
        sub a, b
        ld e, a
        ret nc

        ;; Collision: Bounce the ball
        BounceBallUp

        call ToggleBallXVelocity

        ret


;; Inputs: b register - The current index of the brick into the level that's been collided with
DamageBrick:
        ;; Decrement the 'health' of the brick by one
        ld hl, wCurrentLevelData
        ld d, 0
        ld e, b
        add hl, de
        ld a, [hl]
        dec a
        ld [hl], a

        ;; The brick has gotten to 0 health, destroy it.
        ld d, 0
        cp a, d
        jr z, .brick_destroyed

        ;; The brick is damaged
        ld d, 1
        cp a, d
        jr z, .brick_damaged

.update_tile
        ;; Adjust the brick tile in the tilemap to reflect
        ;; the current health.
        ld hl, LevelTileTable
        ld d, 0
        ld e, b
        add hl, de
        ld a, [hl]
        ld d, 0
        ld e, a
        ld hl, _SCRN0 + BRICKS_START
        add hl, de
        pop de
        ld a, d
        ld [hli], a
        ld a, e
        ld [hl], a

        ret

.brick_destroyed
        ld d, WHITE_TILE
        ld e, WHITE_TILE
        push de
        push bc
        call CheckLevelClear
        pop bc
        jp .update_tile
.brick_damaged
        ld d, BRICK_LEFT_DAMAGED
        ld e, BRICK_RIGHT_DAMAGED
        push de
        jp .update_tile

;; Once collision has happened, remove the brick from the level
;; Inputs: b register - The current index of the brick into the level that's been collided with
BrickCollide:
        ;; Remove the tile from the current level
        call DamageBrick

        ld hl, wLevelTableY
        ld d, 0
        ld e, b
        add hl, de
        ld c, [hl]

        ;; See if we hit the bottom bounding box
        ld a, c
        inc a
        add a, (PIXELS_PER_TILE - (PIXELS_PER_TILE / 2))
        ld d, a
        ld a, [ball_oam_y]
        cp a, d
        jr z, .bounce_down

        ;; See if we hit the top bounding box
        ld a, c
        sub a, (PIXELS_PER_TILE - (PIXELS_PER_TILE / 4))
        ld d, a
        ld a, [ball_oam_y]
        cp a, d
        jr z, .bounce_up

        ld hl, wLevelTableX
        ld d, 0
        ld e, b
        add hl, de
        ld c, [hl]

        ;; See if we hit the left bounding box
        ld a, c
        add a, PIXELS_PER_TILE / 4
        ld d, a
        ld a, [ball_oam_x]
        cp a, d
        jr z, .bounce_left

        ;; See if we hit the right bounding box
        ld a, c
        add a, (PIXELS_PER_TILE * TILES_PER_BRICK) + (PIXELS_PER_TILE / 4) + 2
        ld d, a
        ld a, [ball_oam_x]
        cp a, d
        jr z, .bounce_right

        ret

.bounce_down
        ;; Change the ball direction. Down
        BounceBallDown
        ret

.bounce_up
        ;; Change the ball direction. Up
        BounceBallUp
        ret

.bounce_left
        BounceBallLeft
        ret

.bounce_right
        BounceBallRight
        ret

;; Check if we've cleared the level
CheckLevelClear:
        ld b, 0
.level_loop
        ld a, b
        cp a, (BRICKS_PER_LINE * MAX_BRICK_LINES)
        jr z, .level_clear

        ld hl, wCurrentLevelData
        ld d, 0
        ld e, b
        add hl, de
        ld a, [hl]
        ld d, a
        ld a, 0
        ;; Check if there's currently a brick at the current position
        cp a, d
        ret c
        inc b
        jp .level_loop
.level_clear
        ld a, [wCurrentLevel]
        inc a
        ld [wCurrentLevel], a
        call InitLevel
        call InitGameObjects
        ret

BallBrickCollisions:
        ld b, 0
.level_loop
        ld a, b
        cp a, (BRICKS_PER_LINE * MAX_BRICK_LINES)
        ret nc

        ld hl, wCurrentLevelData
        ld d, 0
        ld e, b
        add hl, de
        ld a, [hl]
        ld d, 0
        ;; Check if there's currently a brick at the current position
        cp a, d
        ;; There's no brick at the current position.
        ;; Skip to the next brick.
        jr z, .next

        ;; There's a brick at the current position, check for collisions!
        ;; 
        ;; Lookup the X coordinate of the top-left corner of the brick
        ld hl, wLevelTableX
        ld d, 0
        ld e, b
        add hl, de
        ld c, [hl]

        ;; Compare the x position of the ball against the current brick
        ;; Make sure the ball is between the x coordinates of the brick
        ;; if (ball_x > table_x && ball_x < (table_x + 16)) { goto check_y; }
        ld a, c
        add a, (PIXELS_PER_TILE / 4)
        ld c, a
        ld a, [ball_oam_x]
        cp a, c
        jr c, .next

        ld a, c
        add a, (PIXELS_PER_TILE * TILES_PER_BRICK) + (PIXELS_PER_TILE / 4) + 2
        ld c, a
        ld a, [ball_oam_x]
        cp a, c
        jr nc, .next

        ;; Lookup the Y coordinate of the top-left corner of the brick
        ld hl, wLevelTableY
        ld d, 0
        ld e, b
        add hl, de
        ld d, [hl]

        ld a, d
        sub a, (PIXELS_PER_TILE - (PIXELS_PER_TILE / 4))
        ld c, a
        ld a, [ball_oam_y]
        cp a, c
        jr c, .next

        ld a, d
        add a, (PIXELS_PER_TILE - (PIXELS_PER_TILE / 4))
        ld c, a
        ld a, [ball_oam_y]
        cp a, c
        jr nc, .next

        ;; Collision with a brick happened at this point.
        call BrickCollide

        ret
.next
        inc b
        jp .level_loop

MovePaddle:
.check_left
        ld a, [wCurKeys]
        and a, PADF_LEFT
        jr nz, .move_left
        jr z, .check_right
.move_left
        ld a, [wPaddleX]
        dec a
        ;;  If we're already at the end of the playfield, don't move
        cp a, PLAYFIELD_X_START
        ret z
        ld [wPaddleX], a
        ret

.check_right
        ld a, [wCurKeys]
        and a, PADF_RIGHT
        jr nz, .move_right
        ret z

.move_right
        ld a, [wPaddleX]
        inc a
        ;;  If we're already at the end of the playfield (offset by paddle width), don't move
        cp a, PLAYFIELD_X_END - 18
        ret z
        ld [wPaddleX], a
        ret

DrawObjects:
        ld a, [wPaddleX]
        ld [paddle_1_oam_x], a
        add a, 8
        ld [paddle_2_oam_x], a
        add a, 8
        ld [paddle_3_oam_x], a
        ret

UpdateLives:
        ld a, [wLives]
        ld b, LIVES_TILE_START
        add a, b
        ld hl, _SCRN0 + LIVES_TILEMAP_POS
        ld [hl], a
        ret
