# ZeD-GUI

ZeD-GUI, the Zero Day Graphic User Interface, is a mod for Project Zomboid Build 42. It replaces the inventory, the character and loot windows, the HUD and the menus. In the fiction it runs on ZNIX, a made-up platform: a custom kernel built by a paranoid do-it-yourself doomsday prepper. The look is inspired by the popular operating systems of the period, Macintosh System 6 and System 7 most of all; it is not an endorsement of Apple, Microsoft or any other brand. It works with a controller and with a mouse and keyboard.

## Where to get it

The mod is on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3824968485). That page is the only place it is published, and its pinned Bug reports discussion is where problems go. The mod id is `ZeD_UI`; the Workshop page describes what the mod does and how to start with it.

## What is in this repository

- `42/` is the mod as the game loads it: Lua, pixel art, fonts, item scripts.
- `ZeDUI/` is the workshop around it: the tools that make the art and fonts, the test scripts and their reports, the Workshop texts and gallery.
- The documents at the root are the project's working records: the current state, the map of every place the mod hooks the game, a glossary, and one specification per system. They are written for the people building the mod and use the project's own shorthand.

## For maintainers

[DEVELOPING.md](DEVELOPING.md) says what the project needs, how a change is checked in the game and how a build goes to the Workshop. Start with `STATE.md` and `HOOK_MAP.md`.

## Translating

[TRANSLATING.md](TRANSLATING.md) says which two files to translate, the length limits, how to check the result in the game and how to publish it.

## Add-ons

Add-ons are separate mods that require ZeD-GUI. [WATCH_ADDON_GUIDE.md](WATCH_ADDON_GUIDE.md) is the worked example: how a mod adds watches on the same controls.

## Licence

Source-available, not open source. Read the code, learn from it, build add-ons for it and send changes back; do not re-upload or repost the mod anywhere. The [LICENSE](LICENSE) file has the terms, and says what happens if the project is ever abandoned: a named successor takes over, or it passes to everyone under the GPL.

## Credits

Made by Hermit the Trog. The fonts are Fira Sans Condensed and Fira Mono, under the SIL Open Font License. The pixel art is the mod's own. Project Zomboid is made by The Indie Stone; ZeD-GUI is a fan-made mod and is not affiliated with The Indie Stone, Apple or Microsoft.
