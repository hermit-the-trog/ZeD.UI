"""Every machine plate and walkie at the widths the card asks for (REQUEST_design_plates_fill_20261030.md):
WIDE[pid](W=...) builds the plate at W; widths(pid) gives (today's width, the widths the game picks from -- the widest
that fits the card at the current zoom). For the 17 machine plates W is the plate's own width (336, 392, 450, 562);
for the seven walkies W is the half card's PANEL width (154, 180, 206, 257) and the face is W - 20."""
import w_ovens as WO
import w_more as WM
import w_ham as WH
import w_walkie as WW

WIDTHS = (336, 392, 450, 562)
WIDE = {**WO.WIDE, **WM.WIDE, **WH.WIDE, **WW.WIDE}


def widths(pid):
    if pid in WW.WIDE: return 220, WW.PANELS
    return 336, WIDTHS
