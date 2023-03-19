EXPORT InitOAM, CopyOAM

INCLUDE "include/hardware.inc"
INCLUDE "include/constants.inc"

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

        ld hl, wShadowOAM
        ld a, 128 + 16
        ld [hli], a
        ld a, 16 + 8
        ld [hli], a
        ld a, 0
        ld [hli], a
        ld [hl], a

        ret

CopyOAM:
        ld a, HIGH(wShadowOAM)
        call OAMDMA
        
SECTION "OAM Vars", WRAM0[$C100],ALIGN[8]

wShadowOAM:
;; Main paddle
EXPORT paddle_1_oam_y, paddle_1_oam_x, paddle_1_oam_tile, paddle_1_oam_flags
paddle_1_oam_y: ds 1
paddle_1_oam_x: ds 1
paddle_1_oam_tile: ds 1
paddle_1_oam_flags: ds 1

EXPORT paddle_2_oam_y, paddle_2_oam_x, paddle_2_oam_tile, paddle_2_oam_flags
paddle_2_oam_y: ds 1
paddle_2_oam_x: ds 1
paddle_2_oam_tile: ds 1
paddle_2_oam_flags: ds 1

EXPORT paddle_3_oam_y, paddle_3_oam_x, paddle_3_oam_tile, paddle_3_oam_flags
paddle_3_oam_y: ds 1
paddle_3_oam_x: ds 1
paddle_3_oam_tile: ds 1
paddle_3_oam_flags: ds 1

EXPORT ball_oam_y, ball_oam_x, ball_oam_tile, ball_oam_flags
ball_oam_y: ds 1
ball_oam_x: ds 1
ball_oam_tile: ds 1
ball_oam_flags: ds 1

free: ds 4 * 27
        
