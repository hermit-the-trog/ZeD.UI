# QA 169: Animals quick actions, round three rerun (Nov 12 2026)

Against main with 296cfbc7 (round three: runs, full-bucket stop) and 8ac9609d (milk and shear alert). Game 42.22.2, -nosteam, ZeD-QA save.
Scripts zedqa_animals_quick (aq) and zedqa_animals_quick_more (aq2) per setup, after zedqa_animals_restore (ares) alone.
Reports in `qa/regression/`: r3_restore.md, r3_4k.md, r3_deck.md, r3_de.md. The runner marks a script with FAIL lines of its own as WARN.

| Setup | aq | aq2 |
|---|---|---|
| Restore (4K) | ares 1/1 pass | |
| 4K fullscreen, 1.75x | 46 pass, 6 FAIL | 28 pass, 1 FAIL |
| Steam Deck 1280x800 windowed, Auto | 50 pass, 2 FAIL | 28 pass, 1 FAIL |
| German (DE), 4K | 44 pass, 8 FAIL | 28 pass, 1 FAIL |

No ERR lines and no Lua errors in any run. All three report 2 WARN (0 FAIL by the runner's own scale, 0 timeout).

## FAIL lines, verbatim

4K aq:
- ZEDQA aq FAIL X ticked the ram
- ZEDQA aq FAIL the band offers Shear (1) for the ticked ram
- ZEDQA aq FAIL Shear started a run
- ZEDQA aq FAIL during the run the band offers Stop
- ZEDQA aq FAIL the ram is shorn | 4.606845855712891
- ZEDQA aq FAIL the alert rows are stops with A

4K aq2:
- ZEDQA aq2 FAIL e it ended because the player was moved off | done

Deck aq:
- ZEDQA aq FAIL the run ended Done 1 of 1 | Stopped after 0 of 1.
- ZEDQA aq FAIL the ram is shorn | 5

Deck aq2:
- ZEDQA aq2 FAIL e it ended because the player was moved off | done

German aq:
- ZEDQA aq FAIL far: walked up and milked | 6.00 -> 6.00
- ZEDQA aq FAIL X ticked the ram
- ZEDQA aq FAIL the band offers Shear (1) for the ticked ram
- ZEDQA aq FAIL Shear started a run
- ZEDQA aq FAIL during the run the band offers Stop
- ZEDQA aq FAIL the run ended Done 1 of 1 | Gestoppt nach 0 von 1.
- ZEDQA aq FAIL the ram is shorn | 4.67657470703125
- ZEDQA aq FAIL the alert rows are stops with A

German aq2:
- ZEDQA aq2 FAIL e it ended because the player was moved off | done

## Round-three fixes

- Milk and shear alert (8ac9609d): confirmed in all three setups. Passing lines: "ZEDQA aq PASS with 3 L in her, the cow has a milk alert",
  "ZEDQA aq PASS with 5 wool on him, the ram has a shear alert", "ZEDQA aq PASS milked dry: no milk alert | 0",
  "ZEDQA aq PASS shorn: no shear alert | 0.5".
- Full-bucket stop ("Bucket full: milked 1 of 2"): **not covered by these in-game scripts.** Neither aq nor aq2 asserts it (only
  animals_quick_sim.lua checks it); no run printed a "Bucket full" line. Not confirmed in game. aq2's two-cow run (d) now passes:
  "PASS d the run ended Done 2 of 2" and "PASS d never two milkings queued at once" (round two failed both: "Stopped after 1 of 2").
- Round-two failures now passing: "the cow gave milk" (4K, Deck), "a milking run is going", "A on All milkable: the focus lands on Clear" (4K, Deck),
  German "All hungry ... Rename" band row.

## Odd on screen

- The Lua console window (ZeD's) is open at the bottom left in every capture, at 4K and Deck, covering part of the scene; at the Deck size
  (1280x800) it covers a quarter of the screen. It comes from the saved window positions, not from the scripts.
- In the German 4K capture of the ram step the roster shows only the milk cow; the ram row is not in view, so "X ticked the ram" ticks a cow
  ("1 ausgewaehlt: nichts zu melken oder scheren"). This explains the ram FAIL group (script row choice, not the band).

## Settings after

options.ini restored to its backup (fullScreen=true, 3840x2160, fontSize=2, language=EN); ModOptions.ini identical to its backup;
zedqa.autoload 0; lock free; game closed. ZeD-QA restored by the restore script (Bucket and SheepShears reported present: "already carries 1 Base.Bucket",
"already carries 1 Base.SheepShears"), and aq/aq2 clean up after themselves.
