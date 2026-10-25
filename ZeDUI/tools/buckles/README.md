# Profession buckles

One belt buckle per stable profession, for the belt HUD (`ZeD_Belt.lua`). Approved by the director, Oct 15 2026.
See `previews/buckles_sheet_4x.png` and `previews/buckles_on_belt_2x.png`.

## The art

`42/media/textures/ZeD/buckles/buckle_<id>.png`: 25 files, 58 x 40, transparent background.

- One texel per design unit, the same pixel density as the vanilla item icons in the belt boxes.
- `<id>` is what `getDescriptor():getCharacterProfession():getName()` returns: `farmer`, `policeofficer`, `fireofficer`, and so on.
- The 1 px outline and a 1 px contact shadow (alpha 90, right and bottom edges) sit inside the 58 x 40.

## Wiring it in (next code session)

1. `ZeD_Belt.lua`: set `BUCKLE_W` from 38 to 58. `BUCKLE_H` stays 40. The layout already flows from `px(BUCKLE_W)`.
2. `_drawBuckle`: draw the player's buckle instead of the brass frame.
   - Take the id from `getCharacterProfession():getName()` and strip any `namespace:` prefix. A nil or unknown id (modded professions) uses `unemployed`, the plain KENTUCKY plate.
   - Load with `Texture.getSharedTexture(path, 3)`, nearest filtering, the same as the main menu desk (quirk Q205). Cache by id, including misses.
   - Draw at the largest whole multiple of 58 x 40 that fits, `k = math.max(1, math.floor(ZeD.T.scale))`, centred in `self._buckle`, so pixels stay square. Filling the box exactly is the alternative, but it softens at in-between scales. That's the director's call.
   - Keep the old brass frame as the fallback when a texture fails to load.
3. Check pass: a `QABridge` suite that gives the player each of the 25 professions in turn and captures the belt. Put the contact sheet in `ZeDUI/qa/`.

## Regenerating

Needs Python 3 with numpy, scipy and Pillow.

```
python gen_buckles.py --to ../../../42/media/textures/ZeD/buckles     # all 25, straight into the mod
python gen_buckles.py --to out farmer chef                            # just some
python sheet.py ../../../42/media/textures/ZeD/buckles                # rebuild previews/
```

- `PLATES` in `gen_buckles.py` sets each profession's metal and plate shape.
- Each emblem is a function.
- The electrician's fist is drawn pixel by pixel in `FIST`.
- `engine.py` holds the metal ramps (sampled from vanilla's medals, coins and badges), the plate shapes, the ribbon and the lighting.
- The belt preview shows vanilla icons in the slots if you first run `pz_unpack.py` on `media/texturepacks/UI2.pack`. Without them the slots render empty.

## Decisions

- **Size:** 58 x 40, the director's pick. The words are part of the design.
- **Burglar:** a stolen gold CHAMP buckle.
- **Unemployed:** the plain KENTUCKY plate. Neither it nor the burglar points to a job, on purpose.
- **Spiffo's:** won, reading BEST FLIPPER and SPIFFOS '91.
- **Metals:**
  - Pewter: farmer, ranger, nurse.
  - Brass: police, unemployed, fire, repairman, veteran.
  - Gold: burglar.
  - Gold plate: doctor, burger flipper.
  - Silver plate: security, chef, tailor, rancher, fitness (a thin frame round a black enamel sign).
  - Steel: construction, engineer, metalworker.
  - Bronze: angler.
  - Copper: carpenter, electrician.
  - Black iron with brass ribbons: lumberjack, mechanic, smither.
- **Round 2 (Oct 25 2026), five redrawn:**
  - **Veteran:** the heraldic eagle of the game's veteran seal. The wings are raised and built feather by feather, the head is white, and the breast shield has a blue chief and red and white pales. There's an olive branch and arrows.
  - **Fitness:** the Body Chisel Gym & Fitness sign: BODY over CHISEL in heavy cream letters (`BOLD`), a red line through each word, the chisel stroke into the B, GYM&FITNESS under it. The spaces are dropped because the full line is 48 px and the field is 49.
  - **Carpenter:** a bench plane: an iron body, a steel frog, a brass depth wheel, and the knob and tote in the plate's copper.
  - **Tailor:** an old black sewing machine with gold trim, drawn at 86% (`tailor(k)`) so it reads at 1x.
  - **Doctor:** a winged caduceus between serif M and D (`SERIF_M`, `SERIF_D`), with no ribbon.
  - **New enamels in `engine.py`:** `blue` and `white`, and an `&` in the 3x5 font.
- **Legibility:** blind-read twice with the words cropped. Everything that failed was redrawn.
