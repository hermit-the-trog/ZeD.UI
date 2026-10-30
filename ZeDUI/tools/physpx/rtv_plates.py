"""The radios, the CD player, the TVs (REQUEST_design_radio_tv_faces_20261030.md) and the laundry machines (director,
Oct 30 2026: "Washer and dryer I trust you. Do those so we can ship that too.") laid over the plate registry, the way
plates_336 lays the 336 machine plates over it, and over the fill tables of w_plates, so export_fill's export carries
them at every width. Importing this registers:

  half card (the panel width is the key, the face is 20 px narrower; today's is 180):
    radio_black       Base.RadioBlack       ValuTech Radio
    radio_red         Base.RadioRed         Premium Technologies Radio (CD)
    radio_handbuilt   Base.RadioMakeShift   the makeshift radio, a hand-wired board (the car makeshift set keeps
                                            radio_makeshift); 180 / 206 / 257 only, its circuit needs a 160 px board
    cd_player         Base.CDplayer         the CD player
  full card (the plate's width is the key; 336 is the base face, `<pid>_n` the 200 px narrow face):
    tv_widescreen     Base.TvWideScreen     Premium Technologies Television (VHS)
    tv_black          Base.TvBlack          ValuTech Television (VHS)
    tv_antique        Base.TvAntique        Antique Television (black and white)
    washer            IsoClothingWasher     Premium Technologies washer
    dryer             IsoClothingDryer      Premium Technologies dryer
    washer_dryer      IsoCombinationWasherDryer   ValuTech washer-dryer

ITEMS / CLASSES are what export_rtv.py writes for Code to pick a face by: the radio or TV item (a placed set: the item
it turns into when picked up), the laundry machine's object class."""
import plates_336 as P336        # noqa: F401  (the 336 machine plates and the narrow table first)
from plates import DESIGNS, reg
import w_plates as WP
import d_rtv as R
import d_rtv_make as MK
import d_laundry as L

HALF = (154, 180, 206, 257)
FULL = (336, 392, 450, 562)
NW = 200


def at(fn, W0, **fixed):
    return lambda **kw: fn(**{"W": W0, **fixed, **kw})


def st_cd(on):
    s = R.state_port(on, batt=3)
    if on: s["display"] = {"track": "03", "time": "3:42", "batt": 2, "line": "KENTUCKY RAIN"}
    s["hasMedia"] = on
    return s


def st_make(on):
    s = R.state_port(on, batt=1)
    if on: s["display"] = {"l1": "FM 93.2MHZ |||", "l2": "EMERGENCY BROADCAST"}
    return s


def st_black(on):
    s = R.state_port(on, freq="101.6", name="Knox Talk Radio", preset=3, batt=2)
    s["freqF"] = (101.6 - 88) / 20
    return s


def st_ant(on):
    s = R.state_tv(on, ch=4, signal=3)
    s.update(chIdx=2, volF=0.55 if on else 0.0)
    return s


CLOTHES = [("clothes", "hasItems", True, {"clothes": True})]
SWITCH = [("switch_on", "switchOn", True, {"switch_on": True})]

#        pid                fn                card    variants  base                 states                                     title                              uses
SPECS = [("radio_black",     R.radio_black,     "half", [],       {},                  [st_black(False), st_black(True)],         "ValuTech Radio",                  "Base.RadioBlack"),
         ("radio_red",       R.radio_red,       "half", [],       {},                  [R.state_port(False), R.state_port(True, freq="98.4", name="Knox Talk Radio", preset=2)],
          "Premium Technologies Radio", "Base.RadioRed"),
         ("radio_handbuilt", MK.radio_make,     "half", SWITCH,   {"switch_on": False}, [st_make(False), st_make(True)],          "Makeshift Radio (hand-wired)",    "Base.RadioMakeShift"),
         ("cd_player",       R.cd_player,       "half", [],       {},                  [st_cd(False), st_cd(True)],               "CD Player",                       "Base.CDplayer"),
         ("tv_widescreen",   R.tv_wide,         "full", [],       {},                  [R.state_tv(False, power=False), R.state_tv(True, ch=8, signal=4, tape=True)],
          "Premium Technologies Television", "Base.TvWideScreen"),
         ("tv_black",        R.tv_black,        "full", [],       {},                  [R.state_tv(False, power=False), R.state_tv(True, ch=3, signal=2)],
          "ValuTech Television", "Base.TvBlack"),
         ("tv_antique",      R.tv_antique,      "full", [],       {},                  [st_ant(False), st_ant(True)],             "Antique Television",              "Base.TvAntique"),
         ("washer",          L.washer,          "full", CLOTHES,  {},                  [L.state("washer", powered=False), L.state("washer", running=True, water=4, items=True, phase="phWash")],
          "Premium Technologies washer", "IsoClothingWasher"),
         ("dryer",           L.dryer,           "full", CLOTHES,  {},                  [L.state("dryer", powered=False), L.state("dryer", running=True, items=True, phase="phDry")],
          "Premium Technologies dryer", "IsoClothingDryer"),
         ("washer_dryer",    L.combo,           "full", CLOTHES,  {},                  [L.state("combo", water=0), L.state("combo", running=True, water=3, items=True, phase="phRinse")],
          "ValuTech washer-dryer", "IsoCombinationWasherDryer")]

# where a width's circuit does not fit: the face is left out of the pick table (the card falls back as for the walkies)
SKIP = {"radio_handbuilt": (154,)}
POST = {"radio_black": R.attach, "radio_red": R.attach, "radio_handbuilt": R.attach, "cd_player": R.attach,
        "tv_widescreen": R.attach, "tv_black": R.attach, "tv_antique": R.attach}

ITEMS = {"Base.RadioBlack": "radio_black", "Base.RadioRed": "radio_red", "Base.RadioMakeShift": "radio_handbuilt",
         "Base.CDplayer": "cd_player", "Base.TvWideScreen": "tv_widescreen", "Base.TvBlack": "tv_black",
         "Base.TvAntique": "tv_antique"}
CLASSES = {"IsoClothingWasher": "washer", "IsoClothingDryer": "dryer", "IsoCombinationWasherDryer": "washer_dryer"}
TVS = ("tv_widescreen", "tv_black", "tv_antique")
NARROW = {}
FN = {}

for pid, fn, card, variants, base, states, title, uses in SPECS:
    W0 = 180 if card == "half" else 336
    FN[pid] = fn
    reg(pid, at(fn, W0), variants, states, title, uses, base=base, post=POST.get(pid))
    WP.WIDE[pid] = fn
    if card == "full":
        nid = pid + "_n"
        reg(nid, at(fn, NW), variants, states, title + " (narrow)", uses + " (narrow)", base=base, post=POST.get(pid))
        NARROW[pid] = nid
        P336.NARROW[pid] = nid

_widths0 = WP.widths


def widths(pid):
    for spec in SPECS:
        if spec[0] == pid:
            ws = HALF if spec[2] == "half" else FULL
            return (180 if spec[2] == "half" else 336), tuple(w for w in ws if w not in SKIP.get(pid, ()))
    return _widths0(pid)


WP.widths = widths
