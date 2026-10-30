import base64, io, json
from physlib import build
import preview as PV
from plates import DESIGNS
import mock_sheet as MS
import mock_narrow as MN

ORDER = [("Ranges", ["oven_green", "oven_red", "oven_grey", "oven_modern", "oven_industrial", "oven_large", "fryer"]),
         ("Microwaves", ["mw_white", "mw_chrome"]),
         ("Generators", ["gen_red", "gen_yellow", "gen_blue", "gen_old"]),
         ("Grill", ["grill_propane"]),
         ("Ham sets", ["ham_civilian", "ham_army", "ham_makeshift"])]
NOTES = {
 "oven_green": "Burners stack in pairs either side of the control centre. Clock, Minute Minder, oven dial and keys unchanged. Brand: Mass-Genfac Co. (game logo: the MG monogram), replacing the invented Hollister.",
 "oven_red": "The push-button strip already fit. MERIDIAN moves under the signal lamp, so the face keeps its original 146 px height. Brand: CGE (the game's Kentucky manufacturer, 1961-1980), replacing the invented Meridian.",
 "oven_grey": "Burners stack in pairs; touch pads 3 px narrower. 8 px taller. Brand: the Lectromax badge from the game's van livery.",
 "oven_modern": "Burners stack in pairs; the glass panel tightens to the number pad. 8 px taller.",
 "oven_industrial": "Six burners stay in one row under the rail (that's its identity); the oven dial, toggle, maker's plate and timer box drop to a second row. Brand: Knox Pack Kitchens badge (game logo), replacing the invented Ironclad.",
 "oven_large": "Same height; tighter spacing, the vent loses four louvres. Brand: Knox Pack Kitchens badge (game logo), replacing the invented Convectron.",
 "fryer": "The badge moves up to its own band beside a vent; the control box goes full width with every control at full size.",
 "mw_white": "Only the door narrows. The touch panel is untouched. Brand: the ValuTech wordmark from the game's logo.",
 "mw_chrome": "The fancy one, now 1988: smoked glass over brushed chrome, a blue-green fluorescent display (time, COOK, five power bars) and printed glass keys. Same key set as the white microwave, so the game already runs every key. The door narrows. Brand: Premium Technologies, replacing the invented Tempo.",
 "gen_red": "Still one row, same height: tighter spacing only. Brand: Lectromax, as the game names this item; badge in the flyer's dark box.",
 "gen_yellow": "One row plus a right-hand column (breakers over the fuel gauge). IDLE CONTROL and 120/240V 30A wrap to two lines; CIRCUIT BREAKERS reads BREAKERS. 10 px taller. Brand: Premium Technologies, as the game names this item.",
 "gen_blue": "Still one row, same height: tighter spacing only. Brand: ValuTech, as the game names this item; its logo in place of the invented Sundowner.",
 "gen_old": "Two rows: three meters and the fuel gauge on top; the guarded toggles, load terminals and data plate under. 50 px taller.",
 "grill_propane": "The JORGE FOREGUY badge moves to the lid; the cart's tank bay and door narrow. Brand: Hector Lopez, the name players see (Jorge Foreguy is only the internal key).",
 "ham_civilian": "The speaker shrinks; dial, display and keys keep their size. The tuning knob now turns a clear cursor disc under it: its red hairline reads the band arc, and the knob's pointer follows the same angle.",
 "ham_army": "The louvred speaker narrows; the display is 18 px narrower (the station line marquees as it does now). The tuning knob turns a clear cursor disc: its red hairline reads the band arc.",
 "ham_makeshift": "Every control keeps its size. The speaker loses its ring: the holes are drilled by hand straight into the board, two bit sizes, a grid that wanders, a couple skipped. Every label is red embossing tape from an old wheel label maker.",
}

def b64(img):
    bio = io.BytesIO(); img.save(bio, "PNG", optimize=True); return base64.b64encode(bio.getvalue()).decode()

data = {"order": ORDER, "plates": {}}
for fam, pids in ORDER:
    for pid in pids:
        D = DESIGNS[pid]
        ent = {"title": {"mw_chrome": "Chrome microwave, 1988", "grill_propane": "Propane grill (Hector Lopez), 1993"}.get(pid, D["title"]), "note": NOTES[pid]}
        for key, fn in (("today", D["fn"]), ("new", MS.MOCK[pid]), ("narrow", MN.NARROW[pid])):
            p, base, sprites = build(fn, D["variants"], **D.get("base", {}))
            if D.get("post"): D["post"](p)
            ims = [PV.render_state(base, p.parts, sprites, st) for st in D["states"]]
            ent[key] = {"w": ims[0].width, "h": ims[0].height, "img": [b64(i) for i in ims]}
        data["plates"][pid] = ent
        print(pid, ent["today"]["w"], ent["new"]["w"], ent["new"]["h"])
json.dump(data, open("/home/claude/out/plates.json", "w"))
