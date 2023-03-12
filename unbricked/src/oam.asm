EXPORT paddle_sprites
EXPORT InitOAM, CopyOAM

INCLUDE "hardware.inc"
INCLUDE "constants.inc"

SECTION "OAM Functions", ROM0
InitOAM:
        ; Clear OAM memory
        ld a, 0
        ld b, SCRN_X
        ld hl, wShadowOAM
.clear_oam
        ld [hli], a
        dec b
        jp nz, .clear_oam
        
        ; Fill in OAM
        ld hl, wShadowOAM
        ld a, 128 + 16
        ld [hli], a
        ld a, 16 + 8
        ld [hli], a
        ld a, 0
        ld [hli], a
        ld [hl], a

        ;; Initialize game's OAM data
        call InitGameObjects
        ret

InitGameObjects:
        ld a, PLAYFIELD_X_MIDDLE
        ld [paddle_oam_x], a
        ret

CopyOAM:
        ld a, HIGH(wShadowOAM)
        call OAMDMA
        
SECTION "OAM Vars", WRAM0[$C100],ALIGN[8]

wShadowOAM:
;; Main paddle
EXPORT paddle_oam_y, paddle_oam_x, paddle_oam_tile, paddle_oam_flags
paddle_oam_y: ds 1
paddle_oam_x: ds 1
paddle_oam_tile: ds 1
paddle_oam_flags: ds 1

ball_oam_y: ds 1
ball_oam_x: ds 1
ball_oam_tile: ds 1
ball_oam_flags: ds 1

free: ds 4 * 35
        
