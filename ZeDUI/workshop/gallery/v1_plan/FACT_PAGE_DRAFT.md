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
windows. Buttons that a mod adds inside the game's own inventory window do not. A mod loaded after ZeD-GUI that
replaces a whole screen of the game keeps that screen, and a note in *Messages* says which; *ZeD setup* turns
ZeD-GUI's own screen back on. (This sentence prints only once Build confirms the hand-back works; see item 4.)

**Controllers.** Everything works on a controller, with button prompts drawn for Xbox, PlayStation, Steam Deck and
Nintendo pads. Keyboard and mouse work alongside.

**Languages.** English, with machine-drafted translations into 27 more, each named here in its own language:
Bahasa Indonesia, Català, Čeština, Dansk, Deutsch, Español (Argentina), Español (Chile), Español (España), Español
(México), Français, Italiano, Magyar, Nederlands, Norsk, Polski, Português (Brasil), Português (Portugal), Română,
Suomi, Türkçe, Русский, Українська, ไทย, 日本語, 简体中文, 繁體中文, 한국어. Corrections are welcome.

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
| 27 machine-drafted languages | `42/media/lua/shared/Translate/`: 28 folders with a `UI.json`, English included. The game's AR folder is Argentine Spanish, not Arabic (its text: "soga", "untable"). |

## The director's answers (Nov 17 2026)

1. **Builds:** "42.17 or later." The tested builds stay named after it.
2. **Saves:** it can be added to a current save at any time ("It's interface after all"). The beta's "use a new game
   or a copy of a save" stays off the page.
3. **A new Workshop item:** not addressed on this page; the book is being readied for 1.0.
4. **Screen hand-back:** "Yes, please check if it works. And if it doesn't, make it work." Build is on it; the
   sentence under *Other mods* prints once it is confirmed.
5. **Other overhauls:** not addressed ("They're doing something different than what we're doing anyway"), so the
   one-or-the-other sentence is gone.
6. **Languages:** all 27 printed by name, each in its own language.

## For Build when the page is set

The list needs fonts with Cyrillic, Thai, Japanese, Chinese (both scripts) and Korean glyphs. The mod already ships
Noto Sans SC; check the page's other scripts render before it goes up.
