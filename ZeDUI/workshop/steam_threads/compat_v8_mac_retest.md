# Compatibility thread v8: the Mac retest (Nov 8 2026)

The director pasted the Mac rig's retest of every mod in the thread (v7) on ZeD-GUI 0.3.0-beta8, and said "Post Mac's update now" (Nov 8 2026, choosing to edit all 15 posts). v8 = v7's bbcode (compat_v7/post00_first.txt ... post14.txt) with the changes below, nothing else.

## 1. The retest line, in every post (00 to 14)
Put it as its own paragraph directly under each post's heading line (in post 00, right after the intro paragraph that ends "Last updated Nov 2 2026."; change that date to Nov 8 2026):

🍎 Retested Nov 8 2026 on macOS (Apple M4 Pro, 1920x1080, UI scale auto), Project Zomboid 42.21, ZeD-GUI 0.3.0-beta8, single player. ✔ after a mod = on this Mac it loaded with its group (12 to 50 mods at once, ZeD-GUI last), showed no errors of its own beyond any listed here, and every Character and World tab, the pause menu and Options opened. 🚗✔ = a car from the pack was spawned and ZeD's dashboard showed with the driver seated. No mark = not retested on this Mac.

## 2. The mark on each mod line
Every mod entry ends with " ✔" (after its note, if it has one), except the ones below.

**Not retested** (end with " (not retested on this Mac: the game did not load its Workshop copy here)" instead of ✔):
- Improved Hair Menu by duckduckquack and TwisTonFire (Supported)
- Players On Map (Supported)
- +300 Points Trait
- Boots Expanded 11 for B41 and B42 by SergeantMarkIV
- Common Sense [B42.20+] (in the C part of Compatible)
- [42.20] Customizable Containers by dane
- Firearms by Hyzo
- Ladders?! B42.20 SP/MP (Unofficial)
- More Traits [Legacy, read description]
- Pack Mule by Balance
- Sandbox Options by Zky
- [HOTFIX for B42.13] Tactical Weapons
- Yaki's BarberShop
- U.S. M113 APC by Papa_Chad (vehicle packs)

**No mark at all:** Paravel's UI by Paravel (reply 13).

**Vehicle packs (reply 11):** each driven pack ends " 🚗✔". These four end " ✔ (a library or trailer pack: loaded, nothing to drive)": Autotsar Trailers B42, '59 Cadillac Miller-Meteor + ECTO-1 by KI5, Campers! by KI5, Trailers! by KI5.
- U.S. M998 Humvee by Papa_Chad: no ✔; after its note add " (loaded) Confirmed on this Mac: without Military Tool Kit the driver could not be seated."
- [B42] UH-1B Helicopter (Beta): after its note add " 🚗✔ On this Mac (with Aviation Core): seated with ZeD's dashboard."

## 3. New notes (after the ✔ on that line)
- Brita's Armor Pack B42.20+ / Standalone Armor Port & Multilingual Fixes: "✔ On this Mac: one error of its own at the main menu (a stray % in its options text, read by the game's Mod Options). Not ZeD."
- [B42] Custom Map Labels: "✔ ⚠️ beta8: one error at game start (CustomMapLabels.lua:93): it opens the game's map to read labels, ZeD opens its own map instead, so its labels are never read."
- Ellie's Tattoo Parlor V4 b41/b42: "✔ ⚠️ beta8: ZeD's new Make Up rows read the mirror rule through the game's make-up menu, and this mod's patch of it errors on ZeD's stand-in item (ETPMakeUpUIFix.lua:9), so ZeD falls back to "needs a mirror" for its make-up rows (from the code; the rows were not opened). ZeD-GUI bug, to fix."
- Project A-Life by Vice: "✔ On this Mac: its "ALIVE." logo and a notice show over ZeD's desk at the main menu."
- Random Zombies by belette: "✔ On this Mac: one error of its own at game start (randomzombies_server.lua:23). Not ZeD."
- Skullys Lowerback Dufflebags, Chest Rigs + Fannypack, Container Rebalance [42.20]: "✔ On this Mac: one error of its own at load (an item it adjusts does not exist on 42.21). Not ZeD."
- Voiced Radio and TVs: "✔ Its Init error showed on this Mac too."
- Tomb's Player Body Overhaul - Compatibility by Tomb: "✔ (with Tomb's Player Body)"
- This Is Your Life - Character Creator Overhaul [B42.21] by MysticaUmbra, and This Is Your Life [B42 Stable] WIP: "✔ (loaded with ZeD-GUI on this Mac; the error above needs the action it names, not tried here)"
- Xen's Enhanced GUI by Xen: "✔ On this Mac: its "Pick your XEG look" page covers ZeD's desk at the main menu, its theme tints ZeD's menu windows, and its radial errors at game start (XEG_Radial.lua:44); its HUD did not draw this time."

**Broken on 42.21 or 42.22 (reply 14):**
- Barricaded World - Extended Erosion: " Confirmed on this Mac."
- [B42/41] Better Clothing Info Comparison, Disassemble Container With Items, Quick Item Action, Read While Walking, Spear Traps: " ✔ (loaded with ZeD-GUI on this Mac; the error above needs the action it names, not tried here)"
- Common Sense by Braven: " Confirmed on this Mac: the world stopped loading ("Fluid not found: Alcohol")."
- Horde Night: " Confirmed on this Mac: the game closed as the save started (StackOverflowError saving its data)."
- Ladders!? by co`: " Confirmed on this Mac."
- [B42] Noir's Rifle Slings: " Confirmed on this Mac."
- Week One NPC by Slayer: " Confirmed on this Mac with Bandits NPC 3268487204 (Bandits2): in an existing save it errors every game minute (generateSchedule, and StreetsSpawn: playerIsHostile), so it looks out of step with the current Bandits. Not ZeD."

## Not in this update
Minimal Sidebar stays in "Not needed" until beta 9 is live (its Supported line is supported_minimal_sidebar.txt).
