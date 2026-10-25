# Handoff to Code: the two-way radios' faces in the radio tab (Oct 25 2026)

Approved by the director on Oct 25. He asked for the faces with "mock up the walkie talkie faces, to replace the ones in the radio tab. it will be a panel the size of the info card, not full width" and "Need to match the face to the model in game. And we need to mock up the large table top radio controls". He then picked the full drawer width for the ham sets and asked for the ManPack with the walkies. His last change was "squircle the speaker grills", and he signed off with "OK. Put together the handoff".

## Where things are
- **Mockup:** `ZeDUI/mockups/zed_twoway_v1/`.
- **Review sheets:**
  - `walkies_vs_game_2x.png` and `hams_vs_game_2x.png` show each face beside the game's own art.
  - `walkies_2x.png` and `hams_2x.png` are the faces alone.
  - `radio_tab_comp_4k.png` shows a ValuTech walkie and the Premium Technologies ham dropped into the World window's radio tab at 4K.
- **Source** (`src/`):
  - `d_walkie.py` holds the ten designs, written for `ZeDUI/tools/physpx`.
  - `walkie_sheet.py` builds the preview states and sheets.
  - `walkie_comp.py` builds the tab composite.
  - `vs_game.py` builds the side-by-sides.
- **Placement warnings:** all ten build with none.

## 1. What changes
In the Character and World windows' radio tab, a radio that is two-way (`deviceData:getIsTwoWay()`) is drawn as its own face, a physpx plate like the car radios'. The AM/FM radios (Premium Technologies, ValuTech, makeshift) keep today's chassis.

- **Walkies:** each one, the ManPack included, is a **220 x 330** panel. That is the item card's compact width.
- **Ham sets:** the three tabletop sets are **400 x 172** and fill the drawer's width.

## 2. Which radio gets which face

| Radio | Plate | Matched to |
|---|---|---|
| `Base.WalkieTalkie1` Toys-R-Mine Walkie Talkie | `walkie_toy` | model texture `WalkieTalkie_Toy`, tile `appliances_com_01_16..19` |
| `Base.WalkieTalkie2` ValuTech Walkie Talkie | `walkie_valutech` | `WalkieTalkie_ValuTech`, tile `24..27` |
| `Base.WalkieTalkie3` Premium Tech. Walkie Talkie | `walkie_premium` | `WalkieTalkie_Premium`, tile `32..35` |
| `Base.WalkieTalkie4` Tactical Walkie Talkie | `walkie_tactical` | `WalkieTalkie_Tactical`, tile `40..43` |
| `Base.WalkieTalkie5` US Army Walkie Talkie | `walkie_army` | `WalkieTalkie_USArmy`, tile `48..51` |
| `Base.WalkieTalkieMakeShift` Makeshift Walkie Talkie | `walkie_makeshift` | the toy's texture, which the game reuses: drawn as a gutted toy |
| `Base.ManPackRadio` US ARMY COMM. Manpack Radio | `walkie_manpack` | item icon `ManPack` (it has no texture of its own) |
| `Base.HamRadio1` Premium Technologies Ham Radio | `ham_civilian` | placed tile `appliances_com_01_0..3` |
| `Base.HamRadio2` US ARMY COMM. Ham Radio | `ham_army` | placed tile `8..11` |
| `Base.HamRadioMakeShift` Makeshift Ham Radio | `ham_makeshift` | placed tile `56..59` |

- **Inventory radios:** pick the plate by the item's full type.
- **Placed radios:** pick by the item the object was placed from, or by its sprite name, using the tile ranges above.

The ham faces follow the placed tiles: silver, olive, and the wooden crate. They do not follow the item icons, which look different.

## 3. Placement in the tab
- **Header:** the item's display name, as today. The browse buttons and the slot tag are unchanged.
- **Walkie panels:** drawn at whole multiples `k` (the same `k` as the plates), at the content area's left edge, just under the header. The rest of the drawer stays empty, as drawn in the composite.
- **Ham panels:** centred across the drawer.
  - The drawer measured 402 design px wide in the 4K capture, so 400 fits.
  - Check the narrowest the World and Character windows let the drawer get. If it can go under 400, tell me and I'll make a narrower ham layout. Don't scale the plate.
- **Footer:** the brand at the left (VALUTECH, PREMIUM TECHNOLOGIES and so on, as today). At the right, a new line:
  - `* 2-WAY PORTABLE` for the walkies and the ManPack;
  - `* 2-WAY BASE SET` for the hams.
  - Both are new keys: `UI_ZeD_Radio_TwoWayPortable` and `UI_ZeD_Radio_TwoWayBase`.

## 4. Pipeline
1. **Copy** `src/d_walkie.py` to `ZeDUI/tools/physpx/`.
2. **Register** the ten plates in `plates.py`. Preview states can come from `walkie_sheet.state()`. Only the makeshift ham has a variant:
   ```python
   import d_walkie as DW
   for pid, fn, uses in (("walkie_toy", DW.toy, "Base.WalkieTalkie1"), ("walkie_valutech", DW.valutech, "Base.WalkieTalkie2"),
                         ("walkie_premium", DW.premium, "Base.WalkieTalkie3"), ("walkie_tactical", DW.tactical, "Base.WalkieTalkie4"),
                         ("walkie_army", DW.army, "Base.WalkieTalkie5"), ("walkie_makeshift", DW.makeshift, "Base.WalkieTalkieMakeShift"),
                         ("walkie_manpack", DW.manpack, "Base.ManPackRadio"), ("ham_civilian", DW.ham_civ, "Base.HamRadio1"),
                         ("ham_army", DW.ham_army, "Base.HamRadio2")):
       reg(pid, fn, [], STATES[pid], TITLES[pid], uses)
   # the makeshift ham's TALK / LISTEN toggle flips with the mic
   reg("ham_makeshift", DW.ham_make, [("mic_live", "micLive", True, {"mic_live": True})], STATES["ham_makeshift"],
       "Makeshift Ham Radio", "Base.HamRadioMakeShift", base={"mic_live": False})
   ```
3. **Displays:** they carry their colours and fields on the part itself (`color`, `ghost`, `fields`), so no `post=attach_layouts` is needed.
   - The fields use the types `ZeD_Plate.radioDisplay` already draws: `text`, `seg`, `bars`, `cells`.
   - One is new: the toy's drum uses a `text` field with `align = "c"`. Check that `P.text` centres.
4. **Export and check:** run `export_phys.py`, then `platesame.py` for the ten. The new ramps (`wt_*`, `ham_*`, `crate*`, `duct`, `mp_olive`, the `lcd_*` glasses, `drum`) are baked into the pictures.

## 5. What each face reads (`st`)
| Field | Meaning |
|---|---|
| `radioOn` / `power` | on (the readout is blank while off) |
| `micLive` | the mic is live: `not deviceData:getMicIsMuted()` and on. It lights the TX lamp, and on the makeshift ham it flips the TALK toggle |
| `volF` | volume 0..1 (the ManPack's and hams' VOL pointers) |
| `tuneF` | the tuning knob's turn 0..1 (pointer) |
| `bandF` | **new**: where the frequency sits in the radio's band, `(hz - MinChannel) / (MaxChannel - MinChannel)`. The red marker on the hams' green arc follows it |
| `range` | `"RANGE n KM"` from TransmitRange (the hams' strip) |
| `display` | the readout's fields, below |

The `display` fields for the walkies, the ManPack and the civilian and army hams (`kind = "walkie"`):
- **Top line:** `chLabel` `"CH"`, then `ch`, the memory channel as two figures (`"04"`), or blank when off a memory.
- **Frequency:** `big` as `O.freqText(hz, true)` (`"146.520"`).
- **Station:** `line`, the station or memory name in capitals. It scrolls when long.
- **Power:** `batLabel` and `batt`.
  - On battery: `batLabel = "BAT"`, and `batt` is 0..4 from the charge.
  - A placed ham on grid or generator power: `batLabel = "AC"` and `batt = 0` (the bars stay dark).
- **Volume:** `volLabel` `"VOL"`, then `vol` 0..6.
- **Talk state:** `tx` is `O.word("txOk")` while the mic is live and `O.word("micOff")` while it's muted. The mockup shows "TX"; use whichever word the car ham uses, and keep it under 8 characters.

The other two kinds:
- **Toy** (`kind = "toy"`): `big` = `"121.40 MHZ"`, the frequency only.
- **Makeshift walkie and ham** (`walkiechar`, `hamchar`): `l1` = `"CH01 146.520"` (16 cells on the ham, 11 on the walkie, so the walkie line is just `"CH01 88.20"`), and `l2` = the name.

New translation keys for the glass words: `UI_ZeD_Radio_Bat` "BAT", `UI_ZeD_Radio_Vol` "VOL", `UI_ZeD_Radio_Ch` "CH", `UI_ZeD_Radio_Ac` "AC". The legends printed on the plates are baked in English, as on the car plates.

## 6. The controls (hit ids)
They are the car two-way's verbs, so `ZeD.RadioOps` should drive them.

| Hit | Does | On |
|---|---|---|
| `vol` (turn) | power and volume, the way the car two-way's VOL - PWR knob works today (press: power, turn: volume) | all |
| `tune` (turn) | the frequency, in the radio's step | all |
| `chup` / `chdn` | step through the memory channels (the radio's presets) | all but the toy |
| `mem` | store the frequency in the current memory; held (`O.HOLD_MS`) opens the naming, as on the car | all but the toy |
| `mic` | push to talk: latches the mic live, again to mute (`setMicIsMuted`) | all |
| `mute` | the car's MUTE | Tactical, US Army, ManPack, the three hams |
| `scan` | the car's SCAN | Tactical, US Army, the civilian and army hams |
| `p1`..`p6` | straight to memory 1..6 (as the car premium's presets) | army ham |
| `lamp` | **new**: the backlight for 5 s. While it's lit, the display draws at full brightness in the dark, the way the CaZio watches' LIGHT does (0817d2d2). It needs a state field (e.g. `lampLit`) that the display's night pass reads | Tactical, US Army |

Notes:
- **The walkies' two top knobs** (`vol`, `tune`) have no pointer. Their settings show on the screen (VOL bars, the frequency).
- **The side bar** is `mic` on every walkie. On the ManPack it's the handset's bar.
- **The hams' desk mic** stem bar is `mic` on the civilian and army sets. The makeshift ham's mic is wired to its TALK / LISTEN toggle, which is the `mic` hit.
- **Gamepad focus order:** reading order, top to bottom and left to right, with the turn hits taking the D-pad as the car's do.

### RadioOps on item and world radios
`ZeD_RadioOps` is written around a vehicle's radio part (`O.read(part)`, `run(mode, chr, part, ...)`). The two-way faces need the same verbs on an inventory radio and a placed one. Vanilla's `ISRadioAction` modes (ToggleOnOff, SetVolume, SetChannel, MuteMicrophone...) take any device. Generalise `run` to take the device's owner, not a part: the item, the IsoWaveSignal, or the part. Keep the flash, scan and hold timers keyed per device.

## 7. In-game checks
1. **Every radio** in the table, in the hand and placed, at 1080p (k = 1) and 4K (k = 2). Each shows its own face, and the AM/FM radios still show today's chassis.
2. **Power, volume, tuning:** off blanks the display, the VOL bars follow, and the frequency steps.
3. **Memories:**
   - CH up and down walk the presets.
   - MEM stores, and held, it names.
   - The army ham's 1 to 6 keys jump straight to a memory.
   - The toy has none.
4. **Talk:**
   - The side bar, handset or desk mic toggles the mic.
   - The TX lamp and the readout's TX / MIC OFF agree with vanilla's radio window.
   - The makeshift ham's toggle flips.
5. **Battery and grid:** a walkie's BAT bars drain. A placed ham on a generator shows AC.
6. **Hams:** the arc marker moves with the frequency, and RANGE matches TransmitRange.
7. **LAMP:** the screen lights for 5 s in the dark.
8. **Width:** the narrowest drawer still fits a ham. If not, tell me.
