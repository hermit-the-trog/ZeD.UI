# In-game check: Wounds Overhaul support (Nov 7 2026)

What changed, in plain words:
- With Wounds Overhaul on, ZeD's Health tab no longer names a wound the mod wants examined first. Such a part shows its pain and any care already given (bandage, stitches, splint, poultice) and the mod's line "Something is wrong here."
- The part's menu (right-click on the body or an injury row, A on the controller) holds **Examine** and the mod's gray line. Examine runs the mod's own examination: the character stands and looks, First Aid trains, the time follows the First Aid level.
- Once the part is examined, the wounds are named and the same menu is the game's treatments with all of the mod's own (press on the wound, tourniquet, antiseptic, packing, the stitching window and the rest).
- With the mod off nothing changes.

The mod is the SteamCMD copy `C:\steamcmd\steamapps\workshop\content\108600\3775026731\mods\WoundsOverhaul`. `ZeDUI/tools/qa/batch_woundsov.ps1` copies it into `Zomboid\mods` for its runs and removes it after; for the hand check below copy it the same way (and remove it after), ZeD last. QA save `Saves/Sandbox/ZeD-QA`, at the drag strip, the mod's sandbox page at its defaults (strictest examination, treatment needs it, the neck exempt).

Before the game: `lua51 ZeDUI/tools/qa/woundsov_sim.lua` reads `63 checks, 0 failed` (it loads the mod's own Lua from the SteamCMD copy).

**God mode off.** The prelude turns god mode on, and god mode heals a wound at once, so the part never needs examining (QA's note in `COMPAT_WOUNDS_OVERHAUL_20261107.md`). After the prelude, in the debug Lua console:

```
getPlayer():setGodMod(false); getPlayer():setInvincible(true)
```

Wounds, from the same console (left forearm: a cut that bleeds; right hand: a scratch, then a bandage on it from the game's menu once examined; neck: a deep wound; head: a fracture):

```
local bd = getPlayer():getBodyDamage()
local fa = bd:getBodyPart(BodyPartType.ForeArm_L); fa:setCut(true); fa:setCutTime(20); fa:setBleedingTime(10)
local h = bd:getBodyPart(BodyPartType.Hand_R); h:setScratched(true, true); h:setScratchTime(15)
local n = bd:getBodyPart(BodyPartType.Neck); n:setDeepWounded(true); n:setDeepWoundTime(15)
```

Run it at 4K (3840x2160, UI scale 1.75), then once at Deck size (1280x800, Auto, Large text) for the menu and the tab's fit. Each part once with the mouse and once with the pad.

## 1. The tab before the look

Open the Character window, Health tab, figure open.

| Step | Should show |
|---|---|
| The injury list | Left Forearm: its pain tag and "Something is wrong here." No "Cut", no "Bleeding". Right Hand: "Something is wrong here.", no "Scratch". Neck: "Deep wound" (the mod never holds the neck back). |
| Mouse over the left forearm on the figure (pad: D-pad onto it) | The right column: health, the pain tag, then a square in the mod's amber with "Something is wrong here." No wound named. |
| The moodles | Bleeding still shows in the game's moodle column (the game's, not the tab's). |

## 2. Examine

| Step | Should show |
|---|---|
| Right-click the left forearm on the figure | A menu at the pointer: **Examine**, then "Something is wrong here." grayed. No Bandage, no Stitch, no treatment. |
| Click Examine | The character looks at the arm (a timed action with its bar, about 12 s at First Aid 0, shorter with skill). The mod's First Aid XP comes in. |
| Right-click again and Examine again while the bar runs | Nothing is added to the queue (the mod refuses a second look at the same part). |
| Walk while it runs | It stops (below First Aid 4, as the mod has it). Examine again and let it finish. |
| Pad: D-pad onto the right hand on the figure, A | The same menu, the pad on Examine. A runs it; B shuts the menu as the treatment menu does today. |
| Pad: an injury row in the list, A | The same menu for that part. |

## 3. After the look: treatment

| Step | Should show |
|---|---|
| The left forearm, after the bar | The list and the right column name the cut and the bleeding; "Something is wrong here." is gone. |
| Right-click the left forearm | The game's treatment menu with the mod's lines in it: Bandage (with a bandage or rag in the inventory), Disinfect (with disinfectant), "Press on the wound", "Tie a tourniquet above it" (grayed without a belt, rope or strip of cloth). No Examine. |
| Bandage it from the menu | The bandage goes on; the row shows "Bandaged". The words stay named (one look lasts while the wound does). |
| A deep wound on an examined part (console: `fa:setDeepWounded(true); fa:setDeepWoundTime(15)`), with a needle and thread | "Stitch" in the menu. Pick it: the mod's suture window opens over ZeD and takes the mouse (press on the mark, drag across, release). Finish or walk away; ZeD's windows take the mouse again after. |
| The head (console: `bd:getBodyPart(BodyPartType.Head):setFractureTime(30)`), examined, nothing else on it | Right-click opens no menu at all: the mod offers nothing for a skull fracture alone (its own rule, also on its own panel). |
| Pad: A on the examined forearm | The treatment menu, the pad on it. |

## 4. Healed, then hurt again

| Step | Should show |
|---|---|
| Heal the left forearm (console: `fa:setCut(false); fa:setCutTime(0); fa:setBleedingTime(0); fa:setBandaged(false, 0)`), wait a second with the Health tab open | The forearm leaves the list. |
| Cut it again (`fa:setCut(true); fa:setCutTime(20)`) | "Something is wrong here." again, and Examine in the menu: the old look went with the old wound (the mod's rule). |

## 5. The mod's settings

| Step | Should show |
|---|---|
| Sandbox (Wounds Overhaul page): examination requirement to its "name everything" setting, a new cut | The cut is named at once; the menu is the game's treatments with the mod's; no Examine. |
| The middle setting | Same as above in ZeD's tab (the mod's "held back" rule only holds on the strictest setting); the mod's own panel names only the injuries the character saw happen. |
| "Treatment needs examination" off (strictest setting) | Nothing held back in ZeD's tab, no Examine. |

## 6. With the mod off

Remove the mod, same wounds. The tab names every wound as before this change; right-click opens the game's treatment menu as before; no Examine anywhere.

## Logs

`console.txt`: no `[ZeD] woundsov` line and no Lua error. `Zomboid/Lua/Wounds_debug.log` (the mod's log), with its DebugLog sandbox option on: "examined part 2 (...)" after the forearm's look.

## Not covered by this support (by design)

- The mod's own findings (sepsis stages, an open fracture, a burn's degree, a closure's quality) are not listed by ZeD's tab. Its moodles and its own windows (suture, ointment, debridement) still show.
- After one look, a later wound on the same part is named at once in ZeD's tab (the mod's rule for other health screens); the mod's own panel would ask for a second look.
- Examining another player (the mod's patient panel) is the game's Character Info route, not ZeD's tab.
