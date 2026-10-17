"""The car radios and the siren controller up close, outside the game: the real ZeD_RadioOps, ZeD_CarRadio and
ZeD_SirenController over a mocked radio (vanilla's DeviceData and ISRadioAction) and a lightbar. Each face draws, its
display reads what the radio does, its controls do vanilla's calls; pictures of each for review.
usage: python test_props.py"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import orgtest as OT          # noqa: E402

PANEL = r'''
local function derive(base, name) local c = {}; c.__index = c; c.Type = name; setmetatable(c, { __index = base }); c.derive = derive; return c end
ISPanel = { derive = derive }
ISPanel.__index = ISPanel
function ISPanel:new(x, y, w, h) return setmetatable({ x = x, y = y, width = w, height = h, visible = true }, ISPanel) end
function ISPanel:drawRect(x, y, w, h, a, r, g, b) py_rect(x, y, w, h, a, r, g, b) end
function ISPanel:drawRectBorder(x, y, w, h, a, r, g, b) py_rect(x, y, w, 1, a, r, g, b); py_rect(x, y + h - 1, w, 1, a, r, g, b) end
function ISPanel:drawTextureScaled(t, x, y, w, h, a) py_tex(t.path, x, y, w, h, a) end
function ISPanel:drawTextureScaledAspect(t, x, y, w, h, a) py_tex(t.path, x, y, w, h, a) end
function ISPanel:drawText(s, x, y, r, g, b, a, f) py_text(tostring(s), x, y, r, g, b, a, f or "F2", 1) end
function ISPanel:drawTextZoomed(s, x, y, z, r, g, b, a, f) py_text(tostring(s), x, y, r, g, b, a, f or "F2", z) end
function ISPanel:initialise() end
function ISPanel:instantiate() end
function ISPanel:setVisible(v) self.visible = v end
function ISPanel:isReallyVisible() return self.visible end
function ISPanel:addToUIManager() end
function ISPanel:removeFromUIManager() end
function ISPanel:setAlwaysOnTop() end
function ISPanel:getAbsoluteX() return self.x end
function ISPanel:getAbsoluteY() return self.y end
function ISPanel:getMouseX() return MOUSE_X or -1 end
function ISPanel:getMouseY() return MOUSE_Y or -1 end
function ISPanel:setWidth(v) self.width = v end
function ISPanel:setHeight(v) self.height = v end
function ISPanel:setX(v) self.x = v end
function ISPanel:setY(v) self.y = v end
function ISPanel:update() end
JoypadState = { players = {} }
Joypad = { AButton = 1, BButton = 2, XButton = 3 }
setJoypadFocus = function() end
getPlayerScreenLeft = function() return 0 end
getPlayerScreenTop = function() return 0 end
getPlayerScreenWidth = function() return 1920 end
getPlayerScreenHeight = function() return 1080 end
getTextOrNull = function() return nil end
getText = function(k) return k end
ISContextMenu = { get = function() return { addOption = function() return {} end, isReallyVisible = function() return true end, getX = function() return 0 end } end }
ISTextBox = { new = function() return { initialise = function() end, addToUIManager = function() end, isReallyVisible = function() return false end } end }
function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end

-- a radio fitted in a car, as vanilla's DeviceData answers
function make_radio(itemType, o)
    local dd = { on = o.on, volume = o.volume or 0.6, channel = o.channel or 98400, min = o.min or 88000, max = o.max or 108000,
                 twoWay = o.twoWay, micMuted = false, range = o.range or 0, mediaType = o.mediaType or -1, media = o.media or false,
                 playing = false, presets = o.presets or {} }
    function dd:getIsTurnedOn() return self.on end
    function dd:getIsBatteryPowered() return false end
    function dd:getPower() return 1 end
    function dd:canBePoweredHere() return true end
    function dd:getChannel() return self.channel end
    function dd:getDeviceVolume() return self.volume end
    function dd:getMinChannelRange() return self.min end
    function dd:getMaxChannelRange() return self.max end
    function dd:getDevicePresets()
        local d = self
        return { getMaxPresets = function() return 10 end, getPresets = function()
            local l = {}
            for _, p in ipairs(d.presets) do l[#l + 1] = { getName = function() return p[1] end, getFrequency = function() return p[2] end } end
            return jlist(l)
        end }
    end
    function dd:isReceivingSignal() return true end
    function dd:getIsTwoWay() return self.twoWay end
    function dd:getMicIsMuted() return self.micMuted end
    function dd:getTransmitRange() return self.range end
    function dd:getMediaType() return self.mediaType end
    function dd:hasMedia() return self.media end
    function dd:isPlayingMedia() return self.playing end
    function dd:getMediaData() return nil end
    local item = { getFullType = function() return itemType end }
    local veh = { getId = function() return 7 end, getSeat = function() return 0 end }
    local part = { getInventoryItem = function() return item end, getDeviceData = function() return dd end, getVehicle = function() return veh end, getId = function() return "Radio" end }
    veh.getPartById = function(_, id) if id == "Radio" then return part end end
    local chr = { getVehicle = function() return veh end, getPlayerNum = function() return 0 end }
    return part, dd, chr, veh
end
ISRadioAction = {}
function ISRadioAction:new(mode, chr, part, arg)
    local dd = part:getDeviceData()
    local a = { deviceData = dd }
    a.performToggleOnOff = function() dd.on = not dd.on; py_log("radio power " .. tostring(dd.on)) end
    a.performSetVolume = function() dd.volume = arg; py_log("radio volume " .. tostring(arg)) end
    a.performMuteVolume = function() dd.volume = 0 end
    a.performUnMuteVolume = function() dd.volume = arg end
    a.performSetChannel = function() dd.channel = arg; py_log("radio channel " .. tostring(arg)) end
    a.performMuteMicrophone = function() dd.micMuted = arg end
    a.performTogglePlayMedia = function() dd.playing = not dd.playing end
    return a
end
getZomboidRadio = function() return { getChannelName = function(_, hz)
    if hz == 98400 then return "Knox Talk Radio" end
    if hz == 101200 then return "LBMW - Kentucky Radio" end
    return nil end } end

-- a police car's lightbar
function make_lightbar_car()
    local v = { lights = 0, siren = 0 }
    function v:hasLightbar() return true end
    function v:getLightbarLightsMode() return self.lights end
    function v:getLightbarSirenMode() return self.siren end
    local chr = { getVehicle = function() return v end, getPlayerNum = function() return 0 end }
    CLIENT_COMMAND = function(p, module, command, args)
        if command == "setLightbarLightsMode" then v.lights = args.mode elseif command == "setLightbarSirenMode" then v.siren = args.mode end
    end
    return chr, v
end
'''

KINDS = {"premium": "Base.RadioRed", "valutech": "Base.RadioBlack", "makeshift": "Base.RadioMakeShift", "ham": "Base.HamRadio1",
         "army": "Base.HamRadio2", "hammake": "Base.HamRadioMakeShift"}

FAILS = []


def check(what, got, want):
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + f"{what}: {got!r}" + ("" if ok else f" (want {want!r})"))
    if not ok: FAILS.append(what)


def world():
    o = OT.Org([], w=520, h=200)
    o.lua(PANEL)
    for f in ("ZeD_CarRadio.lua", "ZeD_SirenController.lua"):
        o.L.execute(open(os.path.join(OT.SRC, f), "rb").read())
    return o


def draw(o, prop, w=520, h=200):
    o.new_paint(w, h)
    prop.prerender(prop)


def centre(prop, id_):
    for h in prop._hits.values():
        if h.id == id_: return h.x + h.w * 0.5, h.y + h.h * 0.5, h
    raise KeyError(id_)


def press(o, prop, id_, side=0):
    x, y, h = centre(prop, id_)
    if side: x = h.x + h.w * (0.75 if side > 0 else 0.25)
    prop.onMouseDown(prop, x, y)
    o.ms(100)
    prop.onMouseUp(prop, x, y)
    draw(o, prop)


def radios():
    for kind, item in KINDS.items():
        o = world()
        ham = kind in ("ham", "army", "hammake")
        opts = dict(on=False, channel=146600 if ham else 98400, min=10000 if ham else 88000, max=500000 if ham else 108000, twoWay=ham,
                    range=12000 if ham else 0, mediaType=0 if kind == "premium" else -1,
                    presets=[["Knox Talk Radio", 98400], ["LBMW - Kentucky Radio", 101200]] if not ham else [["Sheriff dispatch", 146600]])
        part, dd, chr, veh = o.g.make_radio(item, o.L.table_from({k: (o.L.table_from([o.L.table_from(p) for p in v]) if k == "presets" else v)
                                                                  for k, v in opts.items()}))
        R = o.g.ZeD.CarRadio
        R.toggle(chr, part)
        prop = R.props[0]
        draw(o, prop)
        check(f"{kind} face", sorted(p.split("/")[-1] for p in o.paint.cache if "physpx" in p)[0], f"radio_{kind}.png")
        check(f"{kind} size at 1x", (prop.width, prop.height), {"premium": (480, 150), "valutech": (440, 122), "makeshift": (440, 128),
                                                                "ham": (500, 140), "army": (500, 150), "hammake": (500, 138)}[kind])
        ids = sorted(h.id for h in prop._hits.values())
        print("   controls", ids)
        pwr = "pwr" if kind in ("makeshift", "hammake") else "vol"
        press(o, prop, pwr)
        check(f"{kind} power on", bool(dd.on), True)
        rd = o.g.ZeD.RadioOps.displayReading(o.g.ZeD.RadioOps.read(part), 0)
        if kind == "premium":
            check("premium reading", (rd.band, rd.big, rd.unit, rd.preset, rd.line, rd.bars), ("FM", "98.4", "MHz", "P1", "KNOX TALK RADIO", 4))
        elif kind == "valutech":
            check("valutech reading", (rd.big, rd.band, rd.tag), ("98.4", "FM", "P1"))
        elif kind == "makeshift":
            check("makeshift reading", (rd.l1, rd.l2), ("FM  98.4MHz  ||||", "KNOX TALK RADIO"))
        elif kind == "hammake":
            check("hammake reading", (rd.l1, rd.l2), ("CH01 146.600 MHz", "SHERIFF DISPATCH"))
        else:
            check(f"{kind} reading", (rd.ch, rd.big, rd.tx, rd.line), ("01", "146.600", "TX OK", "SHERIFF DISPATCH"))
        ch0 = dd.channel
        press(o, prop, "tune", +1)
        check(f"{kind} tune up a step", dd.channel - ch0, 200)
        prop.onMouseWheel(prop, -1) if False else None
        o.g.MOUSE_X, o.g.MOUSE_Y = centre(prop, "tune")[:2]
        prop.onMouseWheel(prop, 1)
        check(f"{kind} the wheel tunes back down", dd.channel, ch0)
        if kind not in ("makeshift", "hammake"):
            o.g.MOUSE_X, o.g.MOUSE_Y = centre(prop, "vol")[:2]
            prop.onMouseWheel(prop, -1)
            check(f"{kind} the wheel turns the volume up", round(dd.volume, 2), 0.7)
        def latched():                     # the makeshift two-way's talk/listen switch: is its latched-in picture drawn?
            return any(p.endswith("radio_hammake_mic_live.png") for p in o.paint.cache)
        if kind == "hammake":
            draw(o, prop)
            check("hammake talk/listen switch latched in while the mic is live", latched(), True)
        if ham:
            press(o, prop, "mic")
            check(f"{kind} MIC mutes the microphone", bool(dd.micMuted), True)
        if kind == "hammake":
            check("hammake MIC lets the talk/listen switch out", latched(), False)
            press(o, prop, pwr)
            check("hammake the switch stays out with the set off", (bool(dd.on), latched()), (False, False))
            press(o, prop, pwr); press(o, prop, "mic")
            check("hammake MIC latches it back in", (bool(dd.on), bool(dd.micMuted), latched()), (True, False, True))
            press(o, prop, "mic")
        if kind == "premium":
            dd.media = True; draw(o, prop)
        # the cues: hover on a knob (a ring), a key held
        o.g.MOUSE_X, o.g.MOUSE_Y = centre(prop, "tune")[:2]
        prop._hover = "tune"
        key = [h.id for h in prop._hits.values() if h.id not in ("vol", "tune", "slot")][0]
        prop._press = o.L.table_from({"id": key, "t0": 0, "fired": True})
        draw(o, prop)
        o.paint.image().save(os.path.join(HERE, "out", f"org_radio_{kind}.png"))
        prop._press = None; prop._hover = None
        press(o, prop, pwr)
        check(f"{kind} power off", bool(dd.on), False)
        draw(o, prop)
        o.paint.image().save(os.path.join(HERE, "out", f"org_radio_{kind}_off.png"))


def siren():
    o = world()
    chr, v = o.g.make_lightbar_car()
    S = o.g.ZeD.Siren
    S.toggle(chr)
    prop = S.props[0]
    o.new_paint(440, 150); prop.prerender(prop)
    check("siren size", (prop.width, prop.height), (440, 150))
    check("siren controls", sorted(h.id for h in prop._hits.values()),
          sorted([f"lights:{i}" for i in range(4)] + ["lights:knob"] + [f"siren:{i}" for i in range(4)] + ["siren:knob"]))
    x, y, _ = centre(prop, "lights:2"); prop.onMouseDown(prop, x, y)
    check("siren click LIGHTS 2", v.lights, 2)
    x, y, _ = centre(prop, "siren:knob"); prop.onMouseDown(prop, x, y)
    check("siren knob steps", v.siren, 1)
    o.g.MOUSE_X, o.g.MOUSE_Y = x, y
    prop.onMouseWheel(prop, -1); prop.onMouseWheel(prop, -1)
    check("siren wheel turns it up", v.siren, 3)
    prop.onMouseWheel(prop, -1)
    check("siren stops at the end", v.siren, 3)
    prop.joyfocus = True
    prop.onJoypadDirRight(prop)
    prop.onJoypadDirDown(prop)
    check("siren pad: right picks SIREN, down turns it", v.siren, 2)
    o.new_paint(440, 170); prop.prerender(prop)
    o.paint.image().save(os.path.join(HERE, "out", "org_siren.png"))
    log = [l for l in o.log if "sound" in l]
    check("siren vanilla sounds", any("VehicleSetSiren" in l for l in log) and any("VehicleSetLights" in l for l in log), True)


if __name__ == "__main__":
    radios()
    siren()
    print(f"{len(FAILS)} failed", FAILS)
    sys.exit(1 if FAILS else 0)
