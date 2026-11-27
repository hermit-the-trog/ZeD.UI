-- ZeDUI/tools/qa/rd_fixes_sim.lua  (QA's radio map, Nov 27 2026): the Radio tab's fixes, with no game running. The
-- real ZeD_RadioOps.lua, TwoWayFace.lua, RtvFace.lua, PlainFace.lua and RadioTab.lua run on Lua 5.1 stubs: a fake
-- device data, inventory and timed-action queue stand in for the game.
--   B1   a walkie's battery goes in and out: the plain card has a Battery button (not a reading only), TW.press
--        "battery" queues the game's battery action (the fullest one carried; out when one is in), and the fill's
--        Battery row under the two-way face presses it
--   B2a  a walkie takes headphones: the plain card's Headphones row and the fill's Headphones row (it presses)
--   B2b  a TV takes none: no phones control on its face or plain card, no fill row, the key refuses
--   B6   the CD player (NoTransmit): no Channels rows, no Heard rows, no frequency range in the fill
--   B7   the pop-out's reach: a walkie in a bag he carries is in reach; one on the floor is not
--   B8   the pad on a two-way face lands on VOL, the face's controls before the header and the tabs
--   B11  the empty line: the Character window says "on you", the World window "in range"; every UI.json has the key
--   B14  Lite's card has Add, Edit and Delete for the stored channels (not on a TV or the CD player); they store,
--        name and forget the channel the set is tuned to
--   R35, R37, R39  a second walkie with the same face, and a face drawn after the tab's first build, bring new pad
--        stops: LAMP lights the walkie shown, MEM held names its channel 01, MIC is a stop
-- Run from the repo root: lua51 ZeDUI/tools/qa/rd_fixes_sim.lua
-- It prints FAIL lines and a last line "rd_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]rd_fixes_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end
local function ident(s) return s end

-- ---------------------------------------------------------------------------
-- STUBS: the game
-- ---------------------------------------------------------------------------
local now = 100000
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
require = noop
getTimestampMs = function() return now end
getText = function(k, a) return a ~= nil and (k .. ":" .. tostring(a)) or k end
isMouseButtonDown = function() return false end
getMouseX, getMouseY = function() return 0 end, function() return 0 end
JoypadState = { players = {} }
instanceof = function(o, cls) return type(o) == "table" and o._cls ~= nil and o._cls[cls] == true end

-- a Java list
local function List(t)
    local l = { items = t or {} }
    function l:size() return #self.items end
    function l:get(i) return self.items[i + 1] end
    function l:add(x) self.items[#self.items + 1] = x end
    function l:remove(x)
        for i, v in ipairs(self.items) do if v == x then table.remove(self.items, i); return true end end
        return false
    end
    return l
end
PresetEntry = { new = function(name, f)
    local p = { n = name, f = f }
    function p:getName() return self.n end
    function p:getFrequency() return self.f end
    function p:setName(s) self.n = s end
    function p:setFrequency(v) self.f = v end
    return p
end }

-- the timed actions queued
local queued = {}
ISTimedActionQueue = { add = function(a) queued[#queued + 1] = a end }
ISDeviceBatteryAction = {
    new = function(_, chr, isRemove, item, param) return { kind = "battery", isRemove = isRemove, item = item } end,
    getDeviceDataParameter = function() return "param" end,
}
ISDeviceMediaAction = { new = function() return { kind = "media" } end }
ISRadioAction = { new = function(_, mode, chr, dev, arg) return { kind = "radio", mode = mode, item = arg } end }
ISInventoryPaneContextMenu = { transferIfNeeded = noop }
local menus = 0
ISContextMenu = { get = function()
    menus = menus + 1
    return { addOption = function() return {} end }
end }
local boxes = {}
ISTextBox = { new = function(_, x, y, w, h, title, cur, target, fn, pn, idx)
    local b = { title = title, target = target, fn = fn, idx = idx }
    function b:initialise() end
    function b:addToUIManager() end
    function b:isReallyVisible() return true end
    boxes[#boxes + 1] = b
    return b
end }

-- a device: o = { tw, tv, portable, noTx, battery (false: mains), hasBattery, power, on, ch, phones }
local function makeDD(o)
    local presets = List()
    local pc = { getPresets = function() return presets end, getMaxPresets = function() return 10 end }
    local dd = { o = o, presets = presets }
    function dd:getIsTwoWay() return o.tw == true end
    function dd:getIsTelevision() return o.tv == true end
    function dd:getIsPortable() return o.portable == true end
    function dd:isNoTransmit() return o.noTx == true end
    function dd:getIsBatteryPowered() return o.battery ~= false end
    function dd:getHasBattery() return o.hasBattery == true end
    function dd:getPower() return o.hasBattery and (o.power or 0) or 0 end
    function dd:getIsTurnedOn() return o.on == true end
    function dd:getChannel() return o.ch or 98000 end
    function dd:getDeviceVolume() return 0.5 end
    function dd:getMinChannelRange() return 88000 end
    function dd:getMaxChannelRange() return 108000 end
    function dd:getHeadphoneType() return o.phones and 1 or -1 end
    function dd:getMediaType() return o.media or -1 end
    function dd:hasMedia() return false end
    function dd:isPlayingMedia() return false end
    function dd:getDevicePresets() return pc end
    function dd:getMicIsMuted() return false end
    function dd:getTransmitRange() return 1000 end
    function dd:transmitPresets() end
    function dd:canBePoweredHere() return false end
    function dd:isReceivingSignal() return false end
    function dd:getDeviceName() return o.name or "Radio" end
    function dd:getIsHighTier() return false end
    return dd
end
local nextId = 1
local function makeItem(fullType, o, container)
    local dd = makeDD(o)
    nextId = nextId + 1
    local it = { _cls = { InventoryItem = true, Radio = true }, _dd = dd, _ft = fullType, _id = nextId, _c = container }
    function it:getDeviceData() return self._dd end
    function it:getFullType() return self._ft end
    function it:getID() return self._id end
    function it:getContainer() return self._c end
    function it:getOutermostContainer()
        local c = self._c
        while c and c._in do c = c._in end
        return c
    end
    return it
end
local function battery(uses)
    return { _ft = "Base.Battery", getCurrentUsesFloat = function() return uses end, getDisplayName = function() return "Battery" end }
end

-- the character, his inventory and a bag in it
local inv = { _items = {} }
function inv:getAllTypeRecurse(ft) local out = {} for _, i in ipairs(self._items) do if i._ft == ft then out[#out + 1] = i end end return List(out) end
function inv:FindAll(ft) return self:getAllTypeRecurse(ft) end
function inv:getCountTypeRecurse(ft) return self:getAllTypeRecurse(ft):size() end
function inv:isInCharacterInventory() return true end
local bag = { _in = inv }
function bag:isInCharacterInventory() return true end
local floor = {}
function floor:isInCharacterInventory() return false end
local CHR = { _cls = { IsoPlayer = true } }
function CHR:getInventory() return inv end
function CHR:getPrimaryHandItem() return self._p end
function CHR:getSecondaryHandItem() return nil end
function CHR:getClothingItem_Back() return nil end
function CHR:getPlayerNum() return 0 end

-- ---------------------------------------------------------------------------
-- STUBS: ZeD's parts the radio files lean on
-- ---------------------------------------------------------------------------
local LITE = false
local C = { r = 1, g = 1, b = 1, a = 1 }
ZeD = {}
ZeD.tr = function(k, a, b) if a ~= nil then return k .. ":" .. tostring(a) .. (b ~= nil and (":" .. tostring(b)) or "") end return k end
ZeD.trDefaults = noop
ZeD.uiSound = noop
ZeD.upper = string.upper
ZeD.btnCase = ident
ZeD.Settings = { lite = function() return LITE end, devicesSimple = function() return false end }
ZeD.T = { px = ident, line = ident, borderW = 1, fontF1 = "f1", fontF2 = "f2", fontF3 = "f3", fontF4 = "f4", buttonH = 20,
    fillBarH = 4, hair = 1, stripH = 30, tabH = 20, selectionA = 0.3,
    sp = { scrollbarW = 10, sm = 4, tabGap = 2, tabPadX = 6 },
    text = C, textDim = C, accent = C, positive = C, warning = C, danger = C, textOnFocus = C, hover = C }
ZeD.TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 7 end, getFontHeight = function() return 10 end }
ZeD.Atoms = setmetatable({ textCase = ident, truncateText = ident, rowBarW = function() return 40 end,
    pctText = function(v) return tostring(v) end, radioSize = function() return 10 end, statusColor = function() return C end,
    wrapText = function(s) return { s } end, mouseIn = function() return false end }, { __index = function() return noop end })
ZeD.Molecules = setmetatable({ buttonW = function(s) return #tostring(s) * 7 + 10 end, bandH = function() return 24 end,
    drawBand = function(panel, x, y, w, spec)
        local r = { buttons = {} }
        for i in ipairs(spec.buttons) do r.buttons[i] = { x = x + i * 50, y = y, w = 40, h = 20 } end
        return 24, r
    end }, { __index = function() return noop end })
ZeD.Focus = { mark = function() return false end }
ZeD.Input = {}
ZeD.Px = { color = function() return {} end, baseId = function(pid) return (tostring(pid):gsub("@%d+$", "")) end,
    k = function() return 1 end, canvas = function() return {} end, tex = noop }
-- each plate's controls, as PL.controls hands them (fresh tables, panel px at k = 1)
local PLATES = {
    walkie_valutech = { w = 200, h = 360, ids = { { "tune", "turn", 100, 10 }, { "vol", "turn", 20, 60 }, { "chdn", "press", 20, 120 },
        { "mem", "press", 70, 120 }, { "chup", "press", 120, 120 }, { "mic", "press", 20, 200 } } },
    radio_black = { w = 336, h = 120, ids = { { "power", "press", 10, 10 }, { "tune", "turn", 60, 10 }, { "p1", "press", 10, 60 },
        { "voldn", "press", 60, 60 }, { "volup", "press", 90, 60 }, { "phones", "press", 120, 60 }, { "battery", "press", 150, 60 } } },
    tv_black = { w = 400, h = 300, ids = { { "power", "press", 10, 10 }, { "chdn", "press", 60, 10 }, { "chup", "press", 90, 10 },
        { "voldn", "press", 120, 10 }, { "volup", "press", 150, 10 }, { "phones", "press", 180, 10 } } },
    cd_player = { w = 200, h = 200, ids = { { "power", "press", 10, 10 }, { "voldn", "press", 60, 10 }, { "volup", "press", 90, 10 },
        { "phones", "press", 120, 10 }, { "battery", "press", 150, 10 }, { "play", "press", 10, 60 } } },
}
ZeD.PhysPx = { plates = {}, texdir = "",
    twoway = { items = { ["Base.WalkieTalkie2"] = "walkie_valutech" }, tiles = {}, narrow = {} },
    rtv = { items = { ["Base.RadioBlack"] = "radio_black", ["Base.TvBlack"] = "tv_black", ["Base.CDplayer"] = "cd_player" } } }
for id, p in pairs(PLATES) do ZeD.PhysPx.plates[id] = { w = p.w, h = p.h, plate = id, _ids = p.ids } end
ZeD.Plate = setmetatable({ controls = function(des)
    local out = {}
    for _, c in ipairs(des._ids or {}) do out[#out + 1] = { id = c[1], kind = c[2], x = c[3], y = c[4], w = 20, h = 20 } end
    return out
end }, { __index = function() return noop end })

local function load(f)
    local ok, err = pcall(dofile, Z .. f)
    check(f .. " loads", ok, err)
end
load("ZeD_RadioOps.lua")
load("TwoWayFace.lua")
load("RtvFace.lua")
load("PlainFace.lua")
load("RadioTab.lua")
local TW, R, PF, RT, O = ZeD.TwoWay, ZeD.Rtv, ZeD.PlainFace, ZeD.RadioTab, ZeD.RadioOps

local panel = setmetatable({ getMouseX = function() return -1 end, getMouseY = function() return -1 end },
    { __index = function() return noop end })
local function plainHits(base, dev, pid)
    local ok, hits = pcall(PF.draw, base, panel, 0, 0, { dev = dev, pid = pid, des = PF.des(base, pid), w = 220 })
    if not ok then return nil, hits end
    local ids = {}
    for _, h in ipairs(hits or {}) do ids[h.id] = true end
    return ids
end
-- the fill's rows for a device under a face (drv: the face's driver), by block
local function fillRows(dev, drv)
    local got = {}
    ZeD.TabFill = { block = function(p, w, key, block, x, y, ww, label, count, rows)
        got[block] = rows
        return (rows and #rows > 0) and 10 or 0
    end }
    local win = { _playerObj = CHR }
    local ok, err = pcall(RT.renderFill, nil, win, { dev = dev, drv = drv }, 0, 0, 300)
    if not ok then return nil, err end
    return got
end
local function rowById(rows, id) for _, r in ipairs(rows or {}) do if r.id == id then return r end end return nil end

-- ---------------------------------------------------------------------------
-- B1: a walkie's battery in and out
-- ---------------------------------------------------------------------------
local walkie = makeItem("Base.WalkieTalkie2", { tw = true, portable = true, hasBattery = true, power = 0, on = false })
CHR._p = walkie
local Cw = PF.controlsFor(TW, "walkie_valutech")
check("B1: the walkie's plain card has a Battery button", Cw.byId.battery ~= nil and Cw.byId.battery.kind == "button",
    Cw.byId.battery and Cw.byId.battery.kind or (Cw.byId.batt and "a reading only" or "none"))
local ids, e = plainHits(TW, walkie, "walkie_valutech")
check("B1: ... drawn as a control (a stop and a click)", ids and ids.battery == true, e)
queued = {}
TW.press(CHR, walkie, "battery")
check("B1: TW.press battery with one in takes it out (the game's battery action)",
    #queued == 1 and queued[1].kind == "battery" and queued[1].isRemove == true, #queued)
walkie._dd.o.hasBattery = false
inv._items = { battery(0.2), battery(0.8), battery(0) }
queued = {}
TW.press(CHR, walkie, "battery")
check("B1: with none in, the fullest one carried goes in (RWMPower.addBattery's choice)",
    #queued == 1 and queued[1].isRemove == false and queued[1].item == inv._items[2], #queued)
inv._items = {}
queued, menus = {}, 0
TW.press(CHR, walkie, "battery")
check("B1: with none carried, nothing is queued and a list says so", #queued == 0 and menus == 1, #queued .. "/" .. menus)
local f = fillRows(walkie, TW)
local bRow = f and rowById(f.power, "fill:radio:batt")
check("B1: the fill's Battery row under the two-way face presses", bRow ~= nil and bRow.fn ~= nil)
inv._items = { battery(0.5) }
queued = {}
if bRow and bRow.fn then bRow.fn() end
check("B1: ... and its press queues the battery in", #queued == 1 and queued[1].kind == "battery", #queued)
local fp = fillRows(walkie, PF.wrap(TW))
local bp = fp and rowById(fp.power, "fill:radio:batt")
check("B1: under the plain card the row stays a reading (the card has the button)", bp ~= nil and bp.fn == nil)

-- ---------------------------------------------------------------------------
-- B2: headphones where the game takes them
-- ---------------------------------------------------------------------------
check("B2a: the walkie's plain card has a Headphones row", Cw.byId.phones ~= nil)
check("B2a: ... drawn as a control", ids and ids.phones == true)
local hRow = f and rowById(f.power, "fill:radio:phones")
check("B2a: the fill has a Headphones row for a walkie", hRow ~= nil)
check("B2a: ... and it presses under the two-way face", hRow ~= nil and hRow.fn ~= nil)
inv._items = { { _ft = "Base.Earbuds" } }
queued = {}
if hRow and hRow.fn then hRow.fn() end
check("B2a: ... plugging the earbuds in", #queued == 1 and queued[1].mode == "AddHeadphones", #queued)

local tv = makeItem("Base.TvBlack", { tv = true, portable = false, battery = false, on = true })
local tvIds, te = plainHits(R, tv, "tv_black")
check("B2b: a TV's plain card has no headphone control", tvIds ~= nil and tvIds.phones == nil, te)
queued = {}
local st = R.read(tv)
check("B2b: the phones key refuses on a TV", R.phonesKey(CHR, tv, st, nil) == false and #queued == 0, #queued)
local ft = fillRows(tv, R)
check("B2b: the fill has no Headphones row for a TV", ft ~= nil and rowById(ft.power, "fill:radio:phones") == nil)
local okD, dHits = pcall(R.drawFace, panel, 0, 0, 1, { dev = tv, pid = "tv_black", des = ZeD.PhysPx.plates.tv_black })
local tvFaceHasPhones = false
for _, h in ipairs(okD and dHits or {}) do if h.id == "phones" then tvFaceHasPhones = true end end
check("B2b: the TV's face has no phones control", okD and not tvFaceHasPhones, okD and "" or dHits)
tv._dd.o.phones = true
local tvIds2 = plainHits(R, tv, "tv_black")
check("B2b: a pair already in a TV can still come out", tvIds2 ~= nil and tvIds2.phones == true)
tv._dd.o.phones = false
local radio = makeItem("Base.RadioBlack", { portable = true, hasBattery = true, power = 0.5, on = true })
local rIds = plainHits(R, radio, "radio_black")
check("B2b: an ordinary portable radio keeps its headphones", rIds ~= nil and rIds.phones == true)

-- ---------------------------------------------------------------------------
-- B6: the CD player shows no channels, nothing heard and no band
-- ---------------------------------------------------------------------------
local cd = makeItem("Base.CDplayer", { portable = true, noTx = true, hasBattery = true, power = 0.5, on = true, media = 0 })
cd._dd.presets:add(PresetEntry.new("Kitsch", 98000))
local fc = fillRows(cd, R)
check("B6: the CD player's fill reads", fc ~= nil)
check("B6: ... no Channels rows", fc and #(fc.channels or {}) == 0, fc and #(fc.channels or {}))
check("B6: ... no Heard rows", fc and #(fc.heard or {}) == 0, fc and #(fc.heard or {}))
check("B6: ... no frequency range", fc and rowById(fc.power, "fill:radio:range") == nil)
radio._dd.presets:add(PresetEntry.new("NNR", 98000))
local fr = fillRows(radio, R)
check("B6: an ordinary radio keeps its Channels, Heard and range",
    fr and #fr.channels == 1 and #fr.heard >= 1 and rowById(fr.power, "fill:radio:range") ~= nil)

-- ---------------------------------------------------------------------------
-- B7: the pop-out's reach
-- ---------------------------------------------------------------------------
local inBag = makeItem("Base.WalkieTalkie2", { tw = true, portable = true }, bag)
CHR._p = nil
check("B7: a walkie in a bag he carries is in reach", TW.inReach(CHR, inBag) == true)
check("B7: ... so the ordinary radios' reach agrees", R.inReach(CHR, inBag) == true)
local onFloor = makeItem("Base.WalkieTalkie2", { tw = true, portable = true }, floor)
check("B7: one on the floor is not", TW.inReach(CHR, onFloor) == false)
CHR._p = walkie
check("B7: one in his hand still is", TW.inReach(CHR, walkie) == true)

-- ---------------------------------------------------------------------------
-- B8: the pad lands on VOL
-- ---------------------------------------------------------------------------
local hits = {}
for _, c in ipairs(PLATES.walkie_valutech.ids) do hits[#hits + 1] = { id = c[1], knob = c[2] == "turn", x = c[3], y = c[4] + 40, w = 20, h = 20 } end
ZeD.TabFill = { focusables = function() return {} end }
local win8 = { _playerObj = CHR, _radios = { { radioInstance = walkie } }, _radioIdx = 1,
    _radioTw = { dev = walkie, hits = hits, k = 1, drv = TW }, _radioTabZones = { { x = 0, y = 0, w = 60, h = 20, idx = 1 } },
    _radioFullZone = { x = 200, y = 0, w = 20, h = 20 } }
local els = RT.buildFocusables(win8)
check("B8: the first stop on a two-way face is VOL", els[1] and els[1].id == "radio:tw:vol", els[1] and els[1].id)
local seen = {}
for i, el in ipairs(els) do seen[el.id] = i end
check("B8: the tabs and the full view button come after the face's controls",
    seen["radio:tab:1"] and seen["radio:full"] and seen["radio:tw:mic"] and seen["radio:tab:1"] > seen["radio:tw:mic"]
    and seen["radio:full"] > seen["radio:tw:mic"])
check("B8: the seed is VOL", win8._gpFocusedRadioCtl == "radio:tw:vol", win8._gpFocusedRadioCtl)

-- ---------------------------------------------------------------------------
-- B11: the empty line's words
-- ---------------------------------------------------------------------------
local charWin, worldWin = { _playerObj = CHR }, { _playerObj = CHR }
ZeD_CharacterWindow = { getInstance = function() return charWin end }
check("B11: the Character window's empty line says on you",
    RT.emptyKey ~= nil and RT.emptyKey(charWin) == "UI_ZeD_Radio_NoneOnYou", RT.emptyKey and RT.emptyKey(charWin))
check("B11: the World window's says in range", RT.emptyKey ~= nil and RT.emptyKey(worldWin) == "UI_ZeD_Radio_None")
do
    local langs = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
        "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
    local miss = {}
    for _, l in ipairs(langs) do
        local fh = io.open(ROOT .. "42/media/lua/shared/Translate/" .. l .. "/UI.json", "rb")
        local s = fh and fh:read("*a") or ""
        if fh then fh:close() end
        if not s:find('"UI_ZeD_Radio_NoneOnYou": "', 1, true) then miss[#miss + 1] = l end
    end
    check("B11: every UI.json has UI_ZeD_Radio_NoneOnYou", #miss == 0, table.concat(miss, ","))
end

-- ---------------------------------------------------------------------------
-- B14: Lite's Add, Edit and Delete
-- ---------------------------------------------------------------------------
LITE = true
local Lw = PF.controlsFor(TW, "walkie_valutech")
check("B14: Lite's walkie card has Add, Edit and Delete", Lw.byId.chadd and Lw.byId.chedit and Lw.byId.chdel and true or false)
check("B14: ... and still no MEM key", Lw.byId.mem == nil)
local Lr = PF.controlsFor(R, "radio_black")
check("B14: Lite's radio card has them too", Lr.byId.chadd and Lr.byId.chedit and Lr.byId.chdel and true or false)
local Lt = PF.controlsFor(R, "tv_black")
check("B14: a TV's has none (the game's TV window has no Add)", Lt.byId.chadd == nil)
local cdIds = plainHits(R, cd, "cd_player")
check("B14: the CD player's card shows none (NoTransmit)", cdIds ~= nil and cdIds.chadd == nil)
local rlIds = plainHits(R, radio, "radio_black")
check("B14: the radio's card draws them as stops", rlIds ~= nil and rlIds.chadd and rlIds.chedit and rlIds.chdel and true or false)
local W = PF.wrap(R)
check("B14: the three act on the release (Edit's box)", W.onRelease("chadd") and W.onRelease("chedit") and W.onRelease("chdel"))
-- a walkie on, tuned to 146.000: Add stores it, Edit names it, Delete forgets it
walkie._dd.o.on, walkie._dd.o.hasBattery, walkie._dd.o.power, walkie._dd.o.ch = true, true, 0.9, 146000
local pl = walkie._dd.presets
PF.press(TW, CHR, walkie, "chadd")
check("B14: Add stores the channel tuned to", pl:size() == 1 and pl:get(0):getFrequency() == 146000, pl:size())
PF.press(TW, CHR, walkie, "chadd")
check("B14: ... once", pl:size() == 1, pl:size())
boxes = {}
PF.press(TW, CHR, walkie, "chedit")
check("B14: Edit opens the naming box on that channel", #boxes == 1 and boxes[1].idx == 1, #boxes)
if boxes[1] then
    boxes[1].fn(boxes[1].target, { internal = "OK", parent = { entry = { getText = function() return "Base camp" end } } }, boxes[1].idx)
end
check("B14: ... and OK names it", pl:size() == 1 and pl:get(0):getName() == "Base camp", pl:get(0) and pl:get(0):getName())
PF.press(TW, CHR, walkie, "chdel")
check("B14: Delete forgets it", pl:size() == 0, pl:size())
walkie._dd.o.on = false
PF.press(TW, CHR, walkie, "chadd")
check("B14: off, Add does nothing (the game greys it)", pl:size() == 0, pl:size())
LITE = false

-- B9 / R21 (QA, Nov 27 2026): the power key turning a playing set off stops its disc at once, as the game's radio
-- window does on its next update (RWMMedia.lua:161-163)
do
    local st = { on = true, playing = true, stopped = 0 }
    local dd = {}
    function dd:getIsTurnedOn() return st.on end
    function dd:isPlayingMedia() return st.playing end
    function dd:StopPlayMedia() st.playing = false; st.stopped = st.stopped + 1 end
    local part = { getDeviceData = function() return dd end }
    local saveRA, savePH = ISRadioAction, O.poweredHere
    ISRadioAction = { new = function() return { deviceData = dd, isValidToggleOnOff = function() return true end,
                                                performToggleOnOff = function() st.on = not st.on end } end }
    O.poweredHere = function() return true end
    local ok = O.power(CHR, part)
    check("B9: power off stops the playing disc at once", ok == true and st.on == false and st.playing == false and st.stopped == 1)
    st.on, st.playing, st.stopped = false, false, 0
    O.power(CHR, part)
    check("B9: power on stops nothing", st.on == true and st.stopped == 0)
    ISRadioAction, O.poweredHere = saveRA, savePH
end

-- R35, R37 and R39 (QA, Nov 27 2026): the windows keep the last stops while a new list has the same count, ends and
-- last place (their _lastTabContentSnapshot); refresh() below is that check, as the Character window runs it. A
-- second walkie with the same face, or the face drawn after the tab's first build, must still bring new stops.
do
    local function refresh(w)
        local els = RT.buildFocusables(w)
        local s, n = w._lastTabContentSnapshot, #els
        local dirty = (s == nil) or s.tab ~= "radio" or s.n ~= n
        if not dirty and n > 0 then
            dirty = s.firstId ~= els[1].id or s.lastId ~= els[n].id or s.lastY ~= els[n].y or s.lastH ~= els[n].h
        end
        if dirty then
            w._lastTabContentSnapshot = { tab = "radio", n = n, firstId = els[1] and els[1].id, lastId = els[n] and els[n].id,
                lastY = els[n] and els[n].y, lastH = els[n] and els[n].h }
            w.ring = els
        end
    end
    local function ringEl(w, id) for _, e in ipairs(w.ring or {}) do if e.id == id then return e end end return nil end
    local function faceHits()
        local hs = {}
        for _, c in ipairs(PLATES.walkie_valutech.ids) do hs[#hs + 1] = { id = c[1], knob = c[2] == "turn", x = c[3], y = c[4] + 40, w = 20, h = 20 } end
        hs[#hs + 1] = { id = "lamp", knob = false, x = 120, y = 240, w = 20, h = 20 }
        return hs
    end
    local function show(w, dev)
        w._radios = { { radioInstance = dev } }
        w._radioTw = { dev = dev, hits = faceHits(), k = 1, drv = TW }
    end
    ZeD.TabFill = { focusables = function() return {} end }
    local a = makeItem("Base.WalkieTalkie2", { tw = true, portable = true, hasBattery = true, power = 0.9, on = true, ch = 146800 })
    local b = makeItem("Base.WalkieTalkie2", { tw = true, portable = true, hasBattery = true, power = 0.9, on = true, ch = 146520 })
    a._dd.presets:add(PresetEntry.new("146.520 MHz", 146520)); a._dd.presets:add(PresetEntry.new("146.800 MHz", 146800))
    b._dd.presets:add(PresetEntry.new("Base", 146520))
    local w = { _playerObj = CHR, _radioIdx = 1, _radioTabZones = { { x = 0, y = 0, w = 60, h = 20, idx = 1 } } }
    show(w, a)
    refresh(w)
    -- R39: the next walkie, the same face: A on its LAMP lights its own glass
    show(w, b)
    refresh(w)
    local lampEl = ringEl(w, "radio:tw:lamp")
    O._lamp = {}
    if lampEl and lampEl.onActivate then lampEl.onActivate(w, lampEl) end
    check("R39: A on LAMP lights the shown walkie's lamp (not the one shown before)", O.lampLit(b) == true and O.lampLit(a) == false,
        "shown " .. tostring(O.lampLit(b)) .. ", the one before " .. tostring(O.lampLit(a)))
    -- R35: A held on MEM names the tuned channel, 01, on the shown walkie
    boxes = {}
    local memEl = ringEl(w, "radio:tw:mem")
    if memEl and memEl.onHoldActivate then memEl.onHoldActivate(w, memEl) end
    check("R35: A held on MEM opens one naming box, for the shown walkie's channel 01",
        #boxes == 1 and boxes[1].idx == 1 and boxes[1].target.dev == b, #boxes .. " box(es), channel " .. tostring(boxes[1] and boxes[1].idx))
    if boxes[1] then
        boxes[1].fn(boxes[1].target, { internal = "OK", parent = { entry = { getText = function() return "" end } } }, boxes[1].idx)
    end
    check("R35: ... an empty name forgets that channel, the other walkie keeps its two",
        b._dd.presets:size() == 0 and a._dd.presets:size() == 2, b._dd.presets:size() .. " / " .. a._dd.presets:size())
    -- R37: the tab's first build on a new walkie (no face drawn yet: the tabs alone), then the face draws
    local c = makeItem("Base.WalkieTalkie2", { tw = true, portable = true, hasBattery = true, power = 0.9, on = true })
    w._radios, w._radioTw = { { radioInstance = c } }, nil
    w.ring = RT.buildFocusables(w)   -- as the window's tab switch sets them, its record untouched
    check("R37: before the face draws, the tabs alone", #w.ring == 1 and w.ring[1].id == "radio:tab:1", #w.ring)
    show(w, c)
    refresh(w)
    check("R37: once the face draws its controls are the stops, VOL first, MIC among them",
        w.ring[1] and w.ring[1].id == "radio:tw:vol" and ringEl(w, "radio:tw:mic") ~= nil, w.ring[1] and w.ring[1].id)
end

print("rd_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
