EXPORT CopyDMARoutine, OAMDMA

INCLUDE "include/hardware.inc"        

SECTION "OAM DMA routine", ROM0
CopyDMARoutine:
  ld  hl, DMARoutine
  ld  b, DMARoutineEnd - DMARoutine; Number of bytes to copy
  ld  c, LOW(OAMDMA); Low byte of the destination address
.copy
  ld  a, [hli]
  ldh [c], a
  inc c
  dec b
  jr  nz, .copy
  ret

DMARoutine:
  ldh [rDMA], a
  
  ld  a, 40
.wait
  dec a
  jr  nz, .wait
  ret
DMARoutineEnd:


SECTION "OAM DMA", HRAM
OAMDMA:
  ds DMARoutineEnd - DMARoutine; Reserve space to copy the routine to
