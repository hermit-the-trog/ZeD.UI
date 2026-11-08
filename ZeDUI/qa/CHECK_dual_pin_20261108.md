# In-game check: dual pinning, the Character and World windows (Build, Nov 8 2026)

What changed (punch list 112, the director's rulings): each half of the Character and World windows rolls up and pins on its own. The inventory side and the tab drawer side each roll 2 s after the pointer leaves that half, or at once on aim, unless that half is pinned. Each window has two pins now, one at each end of its title bar:

- **Character window:** the drawer's pin right after the close box (over the tabs), the inventory's pin where the window's single pin was (left of the window box).
- **World window:** the containers' pin right after the close box (over the containers), the drawer's pin where the single pin was (left of the window box).
- **A rolled inventory side** rolls under its rod, as the roll box has always done; its pin moves onto the rod (the Character rod's right end, the World rod after its close box).
- **A rolled drawer side** folds in, as a second press of its tab does; it opens again on the same tab.
- **Both halves rolled:** the whole window rolls to its title bar, as before.
- A rolled half comes back when the pointer is over its part of the title bar (the inventory's: its rod). A side rolled by hand with the roll box stays rolled until its tab on the rod is pressed.

Code: `ZeD/WindowHalves.lua` (new), `ZeD/Organisms.lua` (the title bar's pins, the window's roll hands over to the halves), `ZeD/WindowCurtain.lua` (the pin on the rod), `ZeD/ZeD_CharacterWindow.lua` and `ZeD/ZeD_WorldWindow.lua` (attach, the saved tab), `ZeD/Input/FocusManager.lua` (the pad's aiming escape and Y / bumpers). Sim: `lua51 ZeDUI/tools/qa/dual_pin_sim.lua` (87 checks, 0 failed at commit). Script: `ZeDUI/tools/qa/zedqa_dual_pin.lua` (the real mouse, as zedqa_autocollapse). Not run in game yet.

## Setup

- QA save (Saves/Sandbox/ZeD-QA), ZEDQA_NOSTEAM=1, the drag strip home. Check `Lua/zedqa.lock` first; never start the game while it runs.
- Run each block twice: at 4K fullscreen (1.75x) and at Deck size (1280x800, Auto scale, Normal and Large text). Mouse first, then the controller.
- A character with an older save (one pin per window) is worth one start: see 5.1.

## 1. The pins

| # | How | What should show |
|---|---|---|
| 1.1 | Open both windows. Character on Health, World on Maps. | Two pin boxes in each title bar, same look as the old pin. Character: one after the close box, one left of the window box. World: the same places. The title moves right to make room for the left pin; nothing overlaps (check the Deck and Large text). |
| 1.2 | Point at each pin. | The help line names that half: "Pin the inventory side open..." or "Pin the tab drawer open...". Pinned, it reads Unpin. |
| 1.3 | Click each pin, one at a time. | Only that pin lights in the accent. Click again: it dims. |
| 1.4 | With a lot of stats in the Character title bar (weight, title pins), look at the right end. | Stats stop short of the right pin, as before. |

## 2. Each half on its own (mouse)

| # | How | What should show |
|---|---|---|
| 2.1 | Nothing pinned. Character on Health. Rest the pointer on the drawer (the Health page) for 3 s. | The inventory side rolls up under its rod; the drawer stays open. |
| 2.2 | Point at the rod's title. | The inventory comes back down. |
| 2.3 | Rest the pointer on the inventory list for 3 s. | The drawer folds in (the window narrows from the left); the list does not move. |
| 2.4 | Point at the title bar above the tabs. | The drawer opens again, on Health. |
| 2.5 | Move the pointer off both windows for 3 s. | Each window rolls to its title bar, full width, as before. |
| 2.6 | Point at the drawer's part of a rolled title bar. | The window comes down with the drawer open and the inventory rolled under its rod. Point at the rod: the inventory comes down. |
| 2.7 | Roll the window up again, then point at the inventory's part of the bar. | The window comes down with the inventory open and the drawer folded. |
| 2.8 | On Loot (no drawer), move off for 3 s. | The whole window rolls up; any part of its bar brings it down. |
| 2.9 | Press the roll box (the up triangle after the title). Then point at the rod. | Rolled by hand, it stays rolled with the pointer on the rod. Its tab on the rod brings it down. |
| 2.10 | Hold the mouse button (drag the map, move a window) for more than 2 s away from a half. | Nothing rolls while the button is held. |

## 3. Pinned halves and aim (mouse)

| # | How | What should show |
|---|---|---|
| 3.1 | **The director's example.** World on Maps with only its drawer pinned. Character unpinned. Move off both windows for 3 s. | The World containers roll under their rod, the map stays open; the Character window rolls up whole. |
| 3.2 | From 3.1, rest the pointer on the map for 10 s. | The map stays open. |
| 3.3 | From 3.1, aim (right mouse held) with the pointer off the windows, then sweep the aim across the rolled bars. | The map stays open; nothing that is pinned moves; a rolled half does not come down while you aim across its bar. |
| 3.4 | Character: pin the inventory only. Aim with the pointer off the window. | The drawer folds at once; the inventory stays exactly as it is. |
| 3.5 | Character: pin the drawer only. Aim. | The inventory rolls under its rod at once; the drawer stays open. |
| 3.6 | Both pins on. Aim, move away, wait. | Nothing moves. |
| 3.7 | With the inventory rolled under its rod, click the pin on the rod. | It lights, and the inventory comes back down (pinning brings a rolled half back, as the old pin did). |
| 3.8 | Pinned or not: click the open tab, then click Loot. | Each still folds the drawer in, as before. |
| 3.9 | Drop an item on a rolled side's rod tab. | It still lands in that side's container. |

## 4. Controller

| # | How | What should show |
|---|---|---|
| 4.1 | Y to open both. In the Character window press Up from the top of the tab strip, then from the top of the container strip (the column of bags at the right). | Up from the tabs lands on the drawer's pin; Up from the container strip lands on the inventory's pin (each pin sits above its strip). The hand mark (or your highlight setting) shows on the pin. Up from the list itself stays in the list. |
| 4.2 | On a pin, press Left / Right. | Focus moves between the two pins along the title bar. Down goes back to the strip or list below. |
| 4.3 | A on a pin. | The pin toggles; the prompt reads Pin or Unpin; focus stays on the pin. |
| 4.4 | Pin the World drawer on Maps only. Flick the right stick (aim). | The World containers roll under their rod, the map stays open; the Character window rolls up whole (unless pinned). |
| 4.5 | Then Y (or LB / RB). | Everything that rolled by itself comes back down. |
| 4.6 | Same in the World window: Up from its container strip (left) and from its tab strip (right). | The containers' pin and the drawer's pin. With the containers rolled, the containers' pin is on the rod and still a stop, beside the rod's tab (Left from the tab). |
| 4.7 | With a controller in use, leave the windows alone for 10 s. | Nothing rolls by itself (the game keeps its pages open for a controller). |

## 5. Saved pins

| # | How | What should show |
|---|---|---|
| 5.1 | A character saved before this build with a window pinned. Load it. | That window has both its pins on. An unpinned window has both off. |
| 5.2 | Pin the Character drawer only and the World containers only. Save and quit, load again. | The same two pins are on. |
| 5.3 | Let the Character drawer fold by itself, then close the window (Tab) and open it again. | It opens on the tab it had (Health), not on Loot. |

Report anything that overlaps in the title bar on the Deck at Large text first: two pins there is the tightest fit.
