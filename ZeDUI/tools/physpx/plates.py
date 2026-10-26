"""The registry: every plate, its state variants, its preview states, and which of the game's tiles or items use it."""
import d_ovens as O

DESIGNS = {}


def reg(pid, fn, variants, states, title, uses, base=None, post=None):
    DESIGNS[pid] = dict(fn=fn, variants=variants, states=states, title=title, uses=uses, base=base or {}, post=post)


reg("oven_green", O.green_range, [("keys_on", "switched", True, {"on": True}), ("dial_c", "celsius", True, {"units": "C"})],
    [O.state(0, 0, False, 7, 40), O.state(200, 35, True, 6, 10, celsius=True)], "Green range, 1956", "appliances_cooking_01_0..3")
reg("oven_red", O.red_range, [("dial_c", "celsius", True, {"units": "C"})],
    [O.state(0, 0, False), O.state(150, 20, True, celsius=True)], "Red range, 1962", "appliances_cooking_01_8..11")
reg("oven_grey", O.grey_range, [],
    [O.state(0, 0, False, vfdText="10:08", unitF=False), O.state(200, 25, True, vfdText="24:12", timerOn=True)],
    "Grey range, 1985", "appliances_cooking_01_4..7")
reg("oven_modern", O.modern_range, [],
    [O.state(0, 0, False, vfdText="10:08"), O.state(200, 0, True, vfdText="400", unitF=True)],
    "Modern range, 1992", "appliances_cooking_01_12..15")
reg("oven_industrial", O.industrial_range, [("toggle_on", "switched", True, {"on": True}), ("dial_c", "celsius", True, {"units": "C"})],
    [O.state(0, 0, False), O.state(200, 45, True, celsius=True)], "Industrial range, 1980", "appliances_cooking_01_20..23")
reg("oven_large", O.convection_oven, [("toggle_on", "switched", True, {"on": True}), ("dial_c", "celsius", True, {"units": "C"})],
    [O.state(0, 0, False), O.state(150, 60, True)], "Large modern oven", "appliances_cooking_01_40..43, 48..51")
reg("fryer", O.fryer, [("rocker_on", "switched", True, {"on": True}), ("dial_c", "celsius", True, {"units": "C"})],
    [O.state(0, 0, False), O.state(200, 10, True)], "Fryers Club fryer", "appliances_cooking_01_52..55")
import d_micro as M
reg("mw_white", M.white, [("mw_lit", "cooking", True, {"cooking": True})],
    [M.state("10:08", 4, False), M.state("0:47", 2, True)], "White touchpad microwave, 1990", "appliances_cooking_01_24..27")
reg("mw_chrome", M.chrome, [("mw_lit", "cooking", True, {"cooking": True})],
    [M.state(power_i=4, cooking=False, minutes=0), M.state(power_i=1, cooking=True, minutes=12)], "Chrome microwave, 1979",
    "appliances_cooking_01_28..31")
import d_gen as G
GEN_VARIANTS = [("run", "running", True, {"running": True}), ("cord", "connected", True, {"connected": True})]
reg("gen_red", G.red, GEN_VARIANTS, [G.state(False, False, 0.35), G.state(True, True, 0.8)], "Red generator, 1988",
    "Base.Generator (appliances_misc_01_0..3)")
reg("gen_yellow", G.yellow, GEN_VARIANTS[1:], [G.state(False, False, 0.6), G.state(True, True, 0.45, load=0.4)], "Yellow contractor's generator",
    "Base.Generator_Yellow (appliances_misc_01_8..11)")
reg("gen_blue", G.blue, GEN_VARIANTS[1:], [G.state(False, False, 0.2), G.state(True, True, 0.7, condition=0.2)], "Blue compact generator, 1991",
    "Base.Generator_Blue (appliances_misc_01_12..15)")
reg("gen_old", G.old, GEN_VARIANTS, [G.state(False, False, 0.5), G.state(True, True, 0.9, load=0.35)], "Old military generator, 1960s",
    "Base.Generator_Old (appliances_misc_01_4..7)")
import d_grill as GR
reg("grill_propane", GR.jorge, [("tank_in", "tank", True, {"tank": True})],
    [GR.state(False, False), GR.state(True, True, 0.65)], "Propane grill (Jorge Foreguy), 1993", "appliances_cooking_01_36..39, 44..47")
import d_props as PR


def _radio(kind, **kw):
    on = kw.pop("on", True)
    reading = PR.display_reading(kind, on=on, **{k: v for k, v in kw.items() if k in ("freq", "name", "preset", "signal", "cd", "elapsed",
                                                                                       "title", "tag", "ch", "tx", "has_media")})
    s = PR.radio_state(kind, on=on, freq=kw.get("freq", "98.4"), name=kw.get("name", ""), preset=kw.get("preset"),
                       volume=kw.get("volume", 0.6), muted=False, mic_muted=kw.get("mic_muted", False), switch_on=on,
                       has_media=kw.get("has_media", False))
    s.update(display=reading, tuneF=kw.get("tune", 0.3), range=kw.get("range"), tapeNames=kw.get("tape"))
    return s


reg("radio_premium", PR.premium, [], [_radio("premium", on=False, volume=0.0),
    _radio("premium", freq="98.4", name="Knox Talk Radio", preset=2, has_media=True)], "Premium Technologies CD receiver",
    "Base.RadioRed", post=PR.attach_layouts)
reg("radio_valutech", PR.valutech, [], [_radio("valutech", on=False, volume=0.0, tape=["Knox", "Wkv", "Lbmw", "", "", ""]),
    _radio("valutech", freq="101.6", preset=3, tape=["Knox", "Wkv", "Lbmw", "", "", ""])], "ValuTech radio", "Base.RadioBlack",
    post=PR.attach_layouts)
import d_makeshift as DM
reg("radio_makeshift", DM.makeshift, [("switch_on", "switchOn", True, {"switch_on": True})],
    [_radio("makeshift", on=False, volume=0.1), _radio("makeshift", freq="93.2", name="Emergency Broadcast")], "makeshift radio",
    "Base.RadioMakeShift", base={"switch_on": False}, post=PR.attach_layouts)
reg("radio_ham", PR.ham, [], [_radio("ham", on=False, volume=0.0, range="RANGE 12 KM"),
    _radio("ham", freq="146.520", name="Sheriff dispatch", ch=2, range="RANGE 12 KM")], "Premium Technologies two-way", "Base.HamRadio1",
    post=PR.attach_layouts)
reg("radio_army", PR.army, [], [_radio("army", on=False, volume=0.0, range="RANGE 25 KM"),
    _radio("army", freq="245.600", name="Base camp", ch=4, tx="MIC OFF", mic_muted=True, range="RANGE 25 KM")], "US Army two-way",
    "Base.HamRadio2", post=PR.attach_layouts)
# the makeshift two-way's talk/listen switch sits latched in while the microphone is live (micLive), on or off
reg("radio_hammake", DM.twoway, [("switch_on", "switchOn", True, {"switch_on": True}), ("mic_live", "micLive", True, {"mic_live": True})],
    [_radio("hammake", on=False, volume=0.1, range="RANGE 8 KM", mic_muted=True),
     _radio("hammake", freq="146.520", name="Farm", ch=1, range="RANGE 8 KM")],
    "makeshift two-way", "Base.HamRadioMakeShift", base={"switch_on": False, "mic_live": False}, post=PR.attach_layouts)
reg("siren", PR.siren, [], [dict(lightsMode=0, sirenMode=0, lightsOn=False, sirenOn=False),
    dict(lightsMode=2, sirenMode=2, lightsOn=True, sirenOn=True)], "siren controller", "police dashes")
import d_speedkeys as SK
# no watch worn: a boom box's tape deck keys set the game speed (the key for the speed sits down)
reg("speed_keys", SK.speed_keys, [(f"speed{i}", f"speed{i}", True, {"pressed": i}) for i in range(4)],
    [SK.state(0), SK.state(1), SK.state(3)], "no-watch speed keys", "ZeD_Watch (no watch worn)")
import d_timez as TZ
# the watches (director, Oct 16 2026): CaZio, Timez and the expensive one, each with its dark picture (and a Timez its
# lit one); the readout, the hands, the alarm's lamp and the set areas live
_WATCH_TITLES = {"digital_black": "CaZio digital, black", "digital_gold": "CaZio digital, gold", "timez_red": "Timez Triathlon, red",
                 "timez_steel": "Timez Triathlon, steel", "classic_black": "CaZio classic, black", "classic_gold": "CaZio classic, gold",
                 "timez_easy": "Timez Easy Reader", "timez_camper": "Timez Camper", "expensive": "Rollex"}
_WATCH_USES = {"digital_black": "WristWatch_*_DigitalBlack", "digital_gold": "WristWatch_*_DigitalDress",
               "timez_red": "WristWatch_*_DigitalRed", "timez_steel": "WristWatch_*_DigitalTimez (ZeD-UI item)",
               "classic_black": "WristWatch_*_ClassicBlack", "classic_gold": "WristWatch_*_ClassicGold",
               "timez_easy": "WristWatch_*_ClassicBrown", "timez_camper": "WristWatch_*_ClassicMilitary",
               "expensive": "WristWatch_*_Expensive"}


def _watch_states(name):
    dig = name.startswith("digital") or name in TZ.TDIGITAL
    t = {} if name.startswith("digital") else {"temp": None}
    sts = [TZ.DW.state(digital_=dig, **t), TZ.DW.state(digital_=dig, alarm=True, speed=3, pm=True, **t),
           TZ.DW.state(digital_=dig, speed=0, dark=True, hour=23, minute=41, **t),
           TZ.DW.state(digital_=dig, alarm=True, set_open=True, alarm_hour=7, **t),
           TZ.DW.state(digital_=dig, alarm=False, set_open=True, **t)]
    if name.startswith("timez_"):
        sts.append(TZ.DW.state(digital_=dig, alarm=True, dark=True, lit=True, hour=4, minute=12, **t))
    if name.startswith("digital_") or name.startswith("classic_"):
        sts.append(TZ.DW.state(digital_=dig, bulb=True, **t))
        sts.append(TZ.DW.state(digital_=dig, alarm=True, dark=True, bulb=True, hour=4, minute=12, **t))
    return sts


for _w in TZ.ALL:
    reg(_w, TZ.design(_w), TZ.variants(_w), _watch_states(_w), _WATCH_TITLES[_w], _WATCH_USES[_w])
import d_walkie as DW
# the two-way radios in the radio tab (director, Oct 25 2026: faces only, full view like the watch): five walkies, the
# makeshift walkie and the ManPack, the three tabletop ham sets; the makeshift ham's TALK / LISTEN toggle flips with the mic
_TW_USES = {"walkie_toy": "Base.WalkieTalkie1", "walkie_valutech": "Base.WalkieTalkie2", "walkie_premium": "Base.WalkieTalkie3",
            "walkie_tactical": "Base.WalkieTalkie4", "walkie_army": "Base.WalkieTalkie5", "walkie_makeshift": "Base.WalkieTalkieMakeShift",
            "walkie_manpack": "Base.ManPackRadio", "ham_civilian": "Base.HamRadio1", "ham_army": "Base.HamRadio2",
            "ham_makeshift": "Base.HamRadioMakeShift",
            # the ham sets' narrow faces, for a radio tab too narrow for the wide ones (mockup zed_ham_narrow_v1)
            "ham_civilian_n": "Base.HamRadio1 (narrow)", "ham_army_n": "Base.HamRadio2 (narrow)",
            "ham_makeshift_n": "Base.HamRadioMakeShift (narrow)"}


def _tw_states(pid):
    fn, kind, kw = DW.MODELS[pid]
    return [DW.state(kind, False), DW.state(kind, True, **kw)]


_TW_TITLES = {"walkie_toy": "Toys-R-Mine Walkie Talkie", "walkie_valutech": "ValuTech Walkie Talkie",
              "walkie_premium": "Premium Tech. Walkie Talkie", "walkie_tactical": "Tactical Walkie Talkie",
              "walkie_army": "US Army Walkie Talkie", "walkie_makeshift": "Makeshift Walkie Talkie",
              "walkie_manpack": "US ARMY COMM. Manpack Radio", "ham_civilian": "Premium Technologies Ham Radio",
              "ham_army": "US ARMY COMM. Ham Radio", "ham_makeshift": "Makeshift Ham Radio",
              "ham_civilian_n": "Premium Technologies Ham Radio (narrow)", "ham_army_n": "US ARMY COMM. Ham Radio (narrow)",
              "ham_makeshift_n": "Makeshift Ham Radio (narrow)"}
for _pid, _uses in _TW_USES.items():
    _fn = DW.MODELS[_pid][0]
    if _pid in ("ham_makeshift", "ham_makeshift_n"):
        reg(_pid, _fn, [("mic_live", "micLive", True, {"mic_live": True})], _tw_states(_pid), _TW_TITLES[_pid], _uses,
            base={"mic_live": False})
    else:
        reg(_pid, _fn, [], _tw_states(_pid), _TW_TITLES[_pid], _uses)
