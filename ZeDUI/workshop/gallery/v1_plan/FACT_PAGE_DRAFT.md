# Pitch picture 5, "Before you install": draft for the director to correct (Nov 17 2026)

Drafted by Build from the repo: mod.info, the beta 19 Workshop description, the translation folders and the code.
Nothing here is final until the director corrects it. The page is printed manual text, dry; ZeD setup is on the
facing page.

## The page as printed

**Before You Install**

**The game.** ZeD-GUI runs on Project Zomboid Build 42, version 42.17 or later. It has been tested on 42.21 and
42.22, at 4K, at 1080p and on the Steam Deck.

**Single player and multiplayer.** ZeD-GUI works in both. On a server, every player needs it; its mod ID is
`ZeD_UI`. The server's own checks still apply to everything ZeD-GUI does.

**Adding it to a save.** ZeD-GUI can be added to a game in progress. Turn it on in *Mods*, after any other interface
mods, then quit and start the game again so that its fonts load.

**Removing it from a save.** ZeD-GUI can be removed at any time. It adds one item to the game, a digital watch, which
leaves with the mod. Nothing else in the save depends on it.

**Turning parts off.** *Safe mode* in *ZeD setup* gives back the game's own screens, all of them or one at a time.
Gadgets can be drawn as the real thing or as plain cards.

**Other mods.** Context menu options, container buttons, items and recipes added by other mods appear in ZeD-GUI's
windows. Buttons that a mod adds inside the game's own inventory window do not. ZeD-GUI replaces the whole interface,
so with another full interface overhaul, use one or the other.

**Controllers.** Everything works on a controller, with button prompts drawn for Xbox, PlayStation, Steam Deck and
Nintendo pads. Keyboard and mouse work alongside.

**Languages.** English, with machine-drafted translations into 27 more languages: Arabic, Catalan, Chinese
(Simplified and Traditional), Czech, Danish, Dutch, Finnish, French, German, Hungarian, Indonesian, Italian,
Japanese, Korean, Norwegian, Polish, Portuguese (Portugal and Brazil), Romanian, Russian, Spanish (Spain, Chile and
Mexico), Thai, Turkish and Ukrainian. Corrections are welcome.

## Where each fact comes from

| Fact | Source |
|---|---|
| 42.17 or later | `42/mod.info`: `versionMin=42.17.0` |
| Tested on 42.21 and 42.22, 4K, 1080p, Deck | beta 19 Workshop description, "Before you subscribe" |
| Every player needs it; mod ID `ZeD_UI` | beta 19 description; `mod.info` `id=ZeD_UI` |
| Server checks still apply | `ZeD_Claims.lua`: safehouse and faction acts go through the game's own calls, which its server checks |
| After other interface mods; restart for fonts | beta 19 description, "Getting started" |
| Remove any time; one item, the digital watch | beta 19 description, "It won't break your game" |
| Safe mode, all or one screen at a time | beta 19 description; `SafeMode.lua` |
| Real thing or plain cards | beta 19 description, "Your look" (the Immersive or Simple setting) |
| Other mods: what shows and what doesn't | beta 19 description, "Your mods still work" |
| One overhaul or the other | the director, Nov 8 (NeatUI and Xen's Enhanced GUI: "pick the UI overhaul that looks the way you want it to") |
| Pad prompts for four families | beta 19 description, "What you get" |
| 27 machine-drafted languages | `42/media/lua/shared/Translate/`: 28 folders with a `UI.json`, English included |

## For the director to settle

1. **Which builds to name.** `mod.info` allows 42.17 and up, but testing has been on 42.21 and 42.22 only. Print
   "42.17 or later", or only the tested builds?
2. **New saves.** The beta says "use a new game or a copy of a save". The draft drops that for 1.0. Keep a line
   like it?
3. **Is 1.0 a new Workshop item?** The beta says "the final release will be a separate item". If so, the page should
   say how to move from the beta item (for example: unsubscribe from the beta first).
4. **Mods that replace a whole screen.** On Nov 7 you asked that ZeD give a screen back automatically when a later
   mod replaces it, with a Messages note. Build could not confirm from the code today that this shipped. If it did,
   the page can say so; if not, it stays out.
5. **Other overhauls by name.** The draft says "another full interface overhaul" without naming NeatUI or Xen's.
   Name them, or leave it general?
6. **The 27 languages.** All 27 are listed. Print the full list, or "27 other languages" with the list in ZeD setup?
