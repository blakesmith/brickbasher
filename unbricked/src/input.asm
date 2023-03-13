EXPORT wCurKeys, wNewKeys, ReadInput        

INCLUDE "include/hardware.inc"
        
SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Input", ROM0

ReadInput:
        ;;  Poll buttons
        ld a, P1F_GET_BTN
        call .onenibble
        ld b, a

        ;;  Poll dpad
        ld a, P1F_GET_DPAD
        call .onenibble
        swap a
        xor a, b
        ld b, a

        ;;  Release
        ld a, P1F_GET_NONE
        ldh [rP1], a

        ;; Combine keys input
        ld a, [wCurKeys]
        xor a, b                ; A = keys changed state
        and a, b                ; A = keys that changed to pressed
        ld [wNewKeys], a
        ld a, b
        ld [wCurKeys], a
        ret

.onenibble
        ldh [rP1], a               ; Switch the player one matrix on
        call .knownret          ; Burn 10 cycles
        ldh a, [rP1]
        ldh a, [rP1]
        ldh a, [rP1]            ; Key matrix has settled
        or a, $F0               ; A7-4 = 1, A3-0 = unpressed keys
.knownret
        ret

