# ZeD-GUI watch add-on guide

*Written Oct 16 2026, when the watches moved onto plates and the steel Timez became the mod's own item.*

## What the addon is

A separate mod that requires ZeD-GUI and adds more watches. The scope is more watches on the same controls. There are no new features and no new buttons. ZeD-GUI keeps covering vanilla's eight watches and its own steel Timez. The addon only adds watches on top of those.

Every watch, ZeD-GUI's own included, goes through the same registration. The steel Timez was built the way an addon watch will be, so the route has already been proven in game.

## What one addon watch needs

| Piece | Where it lives in the addon | Made from |
|---|---|---|
| The item, left and right wrist | `media/scripts/<Addon>_Watches.txt` | Copy the Timez block in ZeD-GUI's `media/scripts/ZeD_Watches.txt`. `ItemType = base:alarmclockclothing`; `ClothingItemExtra` points at the other wrist. |
| The wrist look | `media/clothing/clothingItems/WristWatch_<Side>_<Name>.xml` and a texture in `media/textures/` | Vanilla's square or round wrist model with your own texture. Each XML needs its own GUID, which must never change. |
| The GUID list | `media/fileGuidTable.xml` | One `<files>` entry per clothing XML. |
| The ground model | A `model` block in the script and a texture in `media/textures/WorldItems/` | Vanilla's `WorldItems/DigitalWatch` mesh, or the classic one, recoloured. |
| The inventory icon | `media/textures/Item_<Icon>.png`, 32 × 32 | Vanilla's icons are pixel art. Recolour the nearest vanilla icon. |
| The name | `media/lua/shared/Translate/EN/ItemName.json` | `"Base.WristWatch_Left_<Name>": "..."` (it merges with vanilla's file, it doesn't replace it). |
| Where it turns up | `media/lua/server/Items/<Addon>_WatchLoot.lua` | Copy ZeD-GUI's `ZeD_WatchLoot.lua` and change its `PAIRS`, e.g. join wherever the Expensive watch appears. |
| The face on screen (the plate) | The picture and its state pictures in `media/textures/<Addon>/watch/`, plus a data table | Draw it with ZeDUI/tools/physpx (`d_watches.py` / `d_timez.py` are the patterns), register it in `plates.py`, export. |
| The registration | One call in a client Lua file | Shown below. |

## The registration call

```lua
require "ZeD/ZeD_Watch"
ZeD.Watch.register {
    plate  = "addon_diver",                                   -- the plate's id (its picture's file name)
    items  = { "Base.WristWatch_Left_Diver", "Base.WristWatch_Right_Diver" },
    design = AddonWatchPlates.addon_diver,                    -- the plate's data table, from the export
    texdir = "media/textures/Addon/watch/",                   -- where its pictures are
}
```

Leaving out `design` and `texdir` means "the plate is in ZeD-GUI's own PhysPx". Only ZeD-GUI's built-in watches do that.

## What the face can do

A watch's features come from its plate, not from code. There is no feature list to declare.

| Feature | How the plate gets it |
|---|---|
| The time, seconds, day, date, PM | Display fields `time`, `sec`, `day`, `date`, `pm` |
| Thermometer (CaZio's perk) | Fields `temp` and `tempUnit` |
| Speed marks and PAUSE | Fields `speed` (bars) and `pause` |
| Alarm shown | Field `alm` / `almTime`, the lamp `alarmOn` |
| Hands | A `clock` part |
| Date window that stays while the alarm is being set | A field reading `dateWin` |
| Night | A `dark` state picture, plus `night` colours on the live parts. Every watch dims after dusk. |
| Light (Timez's perk) | A click area `light` and a `lit` state picture with `lit` colours. Lit for 3 seconds. |
| Glowing hands (the expensive one) | `night` colours that are brighter, not dimmer |

**Controls.** These are the click area ids the watch understands:

- **`speed`**: steps the game speed 1×, 2×, 3×.
- **`start`**: pauses or runs.
- **`alarm`**: turns the alarm on or off, or closes the setting if it's open.
- **`set` or `crown`**: opens or closes the alarm setting.
- **`light`**: lights the face.
- **`setdn` / `setup`**: the hour −1 / +1 while setting, with `needs = "setOpen"`. One step past 23 or before 0 is OFF.

Any other id does nothing.

**Alarm setting readout.** Digital faces use `setTitle`, `setVal` and `setHint`. Analog faces use `setText`, plus `setHint` where there's room.

## The rules the built-ins follow

- **Sizes:** digital plates are 124 × 176 and analog ones 150 × 176. The watch sits where the vanilla clock sat, drawn at whole multiples (1×, 2×).
- **Brand perks stay distinct:** CaZio has the thermometer, Timez has the light. A new brand should have its own reason to exist, not a copy of both.
- **Control positions match across a family:** SET top left, ALARM top right, SPEED bottom left, START bottom right.
- **Pixel fonts:** they have no lowercase, so brand names print in capitals unless the logo is drawn into the art.

## Checking an addon watch

- `test_watch.py` covers every registered item: picture equals the preview by day, at night, lit and while setting, plus every control. Copy its `ITEMS` list.
- `platesame.py <plate>` proves the game's Lua draws the plate exactly as the preview does.
- In game: `ZeDUI/tools/qa/zedqa_watches2.lua` wears each watch in turn and screenshots it.

## Where the pieces are in ZeD-GUI

- `42/media/lua/client/ZeD/ZeD_Watch.lua`: the registry, the readout, the controls.
- `42/media/lua/client/ZeD/ZeD_Plate.lua`: the shared plate template, including the night and lit colours.
- `42/media/lua/client/ZeD/PhysPx.lua`: ZeD-GUI's plates (generated).
- `42/media/scripts/ZeD_Watches.txt`, `clothing/`, `fileGuidTable.xml`, `lua/server/Items/ZeD_WatchLoot.lua`: the steel Timez, the working example of an added watch.
