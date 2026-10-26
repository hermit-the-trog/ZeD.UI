-- ZeD-UI/42/media/lua/client/ZeD/TwoWayFace.lua
-- ============================================================================
-- THE TWO-WAY RADIOS' FACES — shared by the radio tab (RadioTab.lua) and full
-- view (TwoWayFull.lua). Handoff ZeDUI/HANDOFF_twoway_20261025.md, mockup
-- ZeDUI/mockups/zed_twoway_v1 (director, Oct 25 2026: "mock up the walkie
-- talkie faces, to replace the ones in the radio tab", then "faces only, no
-- antenna or mic. clicking full view will show without. full view is like the
-- watch, no window frame").
--
-- A radio whose device data is two-way (deviceData:getIsTwoWay()) is drawn as
-- its own pixel-art face, a plate in PhysPx.lua (ZeDUI/tools/physpx/d_walkie.py)
-- drawn by the shared plate template (ZeD_Plate.lua), as the car radios are:
-- five walkies, the makeshift walkie and the ManPack (200 x 360 / 200 x 280,
-- in a 220 panel), three tabletop ham sets (400 x 172). Live on each: the
-- display, the knob pointers, the TX lamp, the hams' band marker and RANGE.
--
-- The controls are the car two-way's verbs (ZeD_RadioOps), on the radio item in
-- the hands or on the back, or on the set placed in the world:
--   vol   press: power; turn (wheel, D-pad up / down): volume
--   tune  a click turns it a step (right half up, left half down), the wheel
--         and the D-pad turn it (a fast spin goes faster)
--   chup / chdn  the memory channels    mem  store; held: name the channel
--   mic   push to talk: the mic latched live, again to mute it
--   mute, scan   as on the car          p1..p6  (army ham) a memory at once
--   lamp  the display's backlight for 5 s (Tactical, US Army)
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/ZeD_RadioOps"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

ZeD = ZeD or {}
ZeD.TwoWay = ZeD.TwoWay or {}
local TW = ZeD.TwoWay
local O = ZeD.RadioOps
local P = ZeD.Px
local PL = ZeD.Plate

TW.PANEL_W = 220          -- a walkie's panel: the item card's compact width (plate px); the face sits in it, 10 either side
TW.PAD = 10               -- the space round a face (plate px)
TW.PRESS_SHADE = 0.35     -- a held key's shade

ZeD.trDefaults({
    UI_ZeD_Radio_TwoWayPortable = "* 2-WAY PORTABLE", UI_ZeD_Radio_TwoWayBase = "* 2-WAY BASE SET",
    UI_ZeD_Radio_Bat = "BAT", UI_ZeD_Radio_Ch = "CH", UI_ZeD_Radio_Ac = "AC", UI_ZeD_Radio_Vol = "VOL",
    UI_ZeD_Radio_FullView = "Full view", UI_ZeD_Radio_CloseFullView = "Close full view", UI_ZeD_RadioPrompt_Lamp = "Light",
})

-- per face: the brand the tab's footer names (the maker's mark, printed as on the set; a hand-built set has none),
-- whether it is a base set, and its display's kind (what TW.reading fills in)
TW.INFO = {
    walkie_toy       = { brand = "TOYS-R-MINE",          kind = "toy" },
    walkie_valutech  = { brand = "VALUTECH",             kind = "walkie" },
    walkie_premium   = { brand = "PREMIUM TECHNOLOGIES", kind = "walkie" },
    walkie_tactical  = { brand = "TACTICAL",             kind = "walkie" },
    walkie_army      = { brand = "US ARMY",              kind = "walkie" },
    walkie_makeshift = { brand = "",                     kind = "walkiechar" },
    walkie_manpack   = { brand = "US ARMY COMM.",        kind = "walkie" },
    ham_civilian     = { brand = "PREMIUM TECHNOLOGIES", kind = "walkie", base = true },
    ham_army         = { brand = "US ARMY COMM.",        kind = "walkie", base = true },
    ham_makeshift    = { brand = "",                     kind = "hamchar", base = true },
}

local function _inv(o, m) return o[m](o) end
local function _get(o, m, default)
    if o == nil or o[m] == nil then return default end
    local ok, v = pcall(_inv, o, m)
    if ok and v ~= nil then return v end
    return default
end
TW._get = _get
local function now() return getTimestampMs() end
local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end
TW.plateTex = plateTex

-- ---------------------------------------------------------------------------
-- WHICH FACE
-- ---------------------------------------------------------------------------
-- a radio dropped on the floor is an IsoRadio beside its world item (vanilla: modData.RadioItemID): that item
local function droppedItem(obj)
    local md = obj.hasModData and obj:hasModData() and obj:getModData() or nil
    local id = md and md.RadioItemID
    if type(id) ~= "number" then return nil end
    local sq = _get(obj, "getSquare", nil)
    local wobs = sq and _get(sq, "getWorldObjects", nil)
    if not wobs then return nil end
    for i = 0, wobs:size() - 1 do
        local it = _get(wobs:get(i), "getItem", nil)
        if it and _get(it, "getID", -1) == id then return it end
    end
    return nil
end

-- the face's plate id for a radio (an item, or a set in the world), nil when it is not a two-way radio. An item by
-- its full type; a placed set by the item it was placed from (its tile's CustomItem) or else its tile; a radio
-- dropped on the floor by its item. A modded two-way borrows the ValuTech walkie (in the hands) or the civilian ham.
function TW.plateId(dev, dd)
    local X = ZeD.PhysPx
    local tw = X and X.twoway
    if not (tw and dev) then return nil end
    dd = dd or _get(dev, "getDeviceData", nil)
    if not (dd and _get(dd, "getIsTwoWay", false)) then return nil end
    local id
    if instanceof(dev, "InventoryItem") then
        id = tw.items[_get(dev, "getFullType", "")] or "walkie_valutech"
    elseif instanceof(dev, "IsoObject") then
        local it = droppedItem(dev)
        if it then id = tw.items[_get(it, "getFullType", "")] end
        if not id then
            local props = _get(dev, "getProperties", nil)
            local ci = props and props:has("CustomItem") and props:get("CustomItem") or nil
            id = ci and tw.items[tostring(ci)]
        end
        if not id then
            local spr = _get(dev, "getSprite", nil)
            local nm = spr and _get(spr, "getName", nil)
            id = nm and tw.tiles[nm]
        end
        id = id or (it and "walkie_valutech") or "ham_civilian"
    end
    if id and not X.plates[id] then return nil end
    return id
end

-- for a radio tab entry ({ radioInstance, deviceData }): its plate id and plate
function TW.plateFor(entry)
    if not (entry and entry.radioInstance) then return nil, nil end
    local id = TW.plateId(entry.radioInstance, entry.deviceData)
    if not id then return nil, nil end
    return id, ZeD.PhysPx.plates[id]
end

-- a ham set's narrow face (mockup zed_ham_narrow_v1, approved Oct 25 2026): the same set rearranged into a walkie's
-- width, drawn where the radio tab cannot hold the wide one at the plates' whole zoom. Its controls are the wide set's.
function TW.narrowOf(pid)
    local X = ZeD.PhysPx
    local id = X and X.twoway and X.twoway.narrow and X.twoway.narrow[pid]
    if id and X.plates[id] then return id, X.plates[id] end
    return nil, nil
end
-- the wide set a face belongs to (a narrow face's own set; any other face is its own)
function TW.basePid(pid)
    local X = ZeD.PhysPx
    for wide, narrow in pairs((X and X.twoway and X.twoway.narrow) or {}) do if narrow == pid then return wide end end
    return pid
end
function TW.info(pid) return TW.INFO[TW.basePid(pid)] end

function TW.isBase(pid) local i = TW.info(pid); return i and i.base == true end
-- the space a face takes in the tab (plate px): a walkie's 220 panel, a ham set's own width
function TW.slotW(des) return math.max(des.w, TW.PANEL_W) end

-- ---------------------------------------------------------------------------
-- READ: what the face shows (nil when the radio has no device data)
-- ---------------------------------------------------------------------------
function TW.read(dev)
    local dd = _get(dev, "getDeviceData", nil)
    if not dd then return nil end
    local st = { dev = dev, dd = dd, key = O.keyOf(dev) }
    st.switchOn = _get(dd, "getIsTurnedOn", false)
    st.battery = _get(dd, "getIsBatteryPowered", false)
    st.charge = st.battery and _get(dd, "getPower", 0) or 0
    local grid = _get(dd, "canBePoweredHere", false)
    st.powered = (st.battery and st.charge > 0) or grid
    -- a set placed where the grid or a generator reaches runs on it (AC on its display); in the hands, on its battery
    st.ac = (not st.battery) or (grid and not instanceof(dev, "InventoryItem"))
    st.on = st.switchOn and st.powered
    st.channel = _get(dd, "getChannel", 0)
    st.volume = _get(dd, "getDeviceVolume", 0.5)
    st.muted = st.volume <= 0.001
    st.min = _get(dd, "getMinChannelRange", 88000)
    st.max = _get(dd, "getMaxChannelRange", 108000)
    st.presets, st.maxPresets = O.presetList(dd)
    for i, p in ipairs(st.presets) do if p.freq == st.channel then st.presetIdx = i; break end end
    st.name = O.chanName(st.channel)
    st.micMuted = _get(dd, "getMicIsMuted", false)
    st.range = _get(dd, "getTransmitRange", 0)
    st.flash, st.flashShort = O.flashOf(st.key)
    st.scanning = O._scan[st.key] ~= nil
    return st
end

local function freq2(hz) return string.format("%.2f", (hz or 0) / 1000) end

-- the display's fields (ZeD_Plate's radioDisplay), nil while the set is off (the glass stays blank)
function TW.reading(st, kind)
    if not (st and st.on) then return nil end
    local preset = st.presetIdx and st.presets[st.presetIdx]
    local nameLine = st.flash or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or (st.name and ZeD.upper(st.name))
        or (preset and preset.name and ZeD.upper(preset.name)) or ""
    if kind == "toy" then return { big = freq2(st.channel) .. " MHZ" } end
    local ch = st.presetIdx and string.format("%02d", st.presetIdx) or nil
    if kind == "walkiechar" then return { l1 = "CH" .. (ch or "--") .. " " .. freq2(st.channel), l2 = nameLine } end
    if kind == "hamchar" then return { l1 = "CH" .. (ch or "--") .. " " .. O.freqText(st.channel, true) .. " MHZ", l2 = nameLine } end
    local r = { chLabel = ZeD.tr("UI_ZeD_Radio_Ch"), ch = ch or "", big = O.freqText(st.channel, true), line = nameLine,
                volLabel = ZeD.tr("UI_ZeD_Radio_Vol"), vol = math.floor(st.volume * 6 + 0.5),
                tx = st.micMuted and O.word("micOff") or O.word("txOk") }
    if st.ac then
        r.batLabel, r.batt = ZeD.tr("UI_ZeD_Radio_Ac"), 0                -- on the grid or a generator: the bars stay dark
    else
        r.batLabel, r.batt = ZeD.tr("UI_ZeD_Radio_Bat"), math.max(0, math.min(4, math.ceil(st.charge * 4 - 0.001)))
    end
    return r
end

local function rangeText(m)
    if not (m and m > 0) then return nil end
    local km = m / 1000
    return ZeD.tr("UI_ZeD_Radio_Range", (km == math.floor(km)) and tostring(math.floor(km)) or string.format("%.1f", km))
end

-- night by the clock, as the watches reckon it (a LAMP set's glass goes dark)
local function isDark()
    local W = ZeD.Watch
    local gt = getGameTime and getGameTime()
    if not (W and W._isDark and gt) then return false end
    return W._isDark(gt:getTimeOfDay() or 12) == true
end

-- what the face's live parts read (the plate template's state)
function TW.plateState(st, pid)
    local ps = {}
    local info = TW.info(pid) or TW.INFO.walkie_valutech
    ps.radioOn, ps.power = st.on, st.on
    if TW.basePid(pid) == "ham_makeshift" then
        ps.micLive = not st.micMuted                       -- the TALK / LISTEN toggle stays where it was flipped
    else
        ps.micLive = st.on and not st.micMuted             -- the TX lamp
    end
    ps.volF = st.volume
    ps.tuneF = ((((st.channel or 0) / O.STEP) * 12) % 360) / 360          -- an endless tuning knob turns with the frequency
    ps.bandF = (st.max > st.min) and (st.channel - st.min) / (st.max - st.min) or 0
    ps.range = rangeText(st.range)
    ps.lampLit = O.lampLit(st.dev)
    ps.dark = isDark()
    ps.display = TW.reading(st, info.kind)
    return ps
end

-- ---------------------------------------------------------------------------
-- ACTIONS (vanilla's radio code through ZeD_RadioOps; chr = the character, dev = the radio)
-- ---------------------------------------------------------------------------
-- a knob turned one click (dir +1 / -1); mult = the fast-turn multiplier
function TW.turn(chr, dev, id, dir, mult)
    if id == "vol" then O.volStep(chr, dev, dir, false)
    elseif id == "tune" then O.tuneStep(chr, dev, dir, mult or 1) end
end

-- the press (a click, A, the end of a short press); dx = where a knob was clicked (< 0: its left half)
function TW.press(chr, dev, id, dx)
    local st = TW.read(dev)
    if not st then return end
    if id == "vol" then O.power(chr, dev)
    elseif id == "tune" then TW.turn(chr, dev, "tune", (dx and dx < 0) and -1 or 1)
    elseif id:match("^p%d$") then
        if st.on and not O.recall(chr, dev, tonumber(id:sub(2))) then O.flash(dev, ZeD.tr("UI_ZeD_Radio_Empty"), 900) end
    elseif id == "chup" then if st.on then O.chStep(chr, dev, 1) end
    elseif id == "chdn" then if st.on then O.chStep(chr, dev, -1) end
    elseif id == "mem" then if st.on then O.memAdd(chr, dev) end
    elseif id == "mic" then O.mic(chr, dev)
    elseif id == "mute" then O.mute(chr, dev)
    elseif id == "scan" then if st.on then O.scanToggle(chr, dev) end
    elseif id == "lamp" then O.lamp(dev); pcall(function() getSoundManager():playUISound("UIActivateButton") end) end
end

-- the second meaning (X, a hold, a right-click); owner = what the naming box answers to
function TW.secondary(chr, dev, id, owner)
    local st = TW.read(dev)
    if not st then return end
    if id:match("^p%d$") then if st.on then O.store(chr, dev, tonumber(id:sub(2))) end
    elseif id == "mem" then if st.on then TW.nameChannel(chr, dev, owner) end
    elseif id == "tune" or id == "vol" then TW.turn(chr, dev, id, -1) end
end

-- presses that act on the release (a hold does the second meaning instead)
function TW.holdable(id) return id == "mem" or id:match("^p%d$") ~= nil end

-- a held press past O.HOLD_MS does its second meaning once; hold = { id, t0, fired }
function TW.holdTick(hold, chr, dev, owner)
    if hold and not hold.fired and TW.holdable(hold.id) and now() - hold.t0 >= O.HOLD_MS then
        hold.fired = true
        TW.secondary(chr, dev, hold.id, owner)
    end
end

-- what A and X do on a control (the controller strip's words), nil = nothing
function TW.labelA(id)
    if not id or id == "tune" then return nil end
    if id == "vol" then return getText("IGUI_RadioPower") end
    if id:match("^p%d$") then return ZeD.tr("UI_ZeD_RadioPrompt_Listen") end
    local K = { chup = "UI_ZeD_RadioPrompt_ChannelUp", chdn = "UI_ZeD_RadioPrompt_ChannelDown", mem = "UI_ZeD_RadioPrompt_StoreChannel",
                mute = "UI_ZeD_RadioPrompt_Mute", scan = "UI_ZeD_RadioPrompt_Scan", lamp = "UI_ZeD_RadioPrompt_Lamp" }
    if id == "mic" then return getText("IGUI_RadioMicrophone") end
    return ZeD.tr(K[id] or "UI_ZeD_RadioPrompt_Press")
end
function TW.labelX(id)
    if not id then return nil end
    if id:match("^p%d$") then return ZeD.tr("UI_ZeD_RadioPrompt_Store") end
    if id == "mem" then return ZeD.tr("UI_ZeD_RadioPrompt_NameChannel") end
    return nil
end

-- MEM held: name the channel (stored first if it is not yet), in vanilla's text box (the ZeD prompt)
function TW.nameChannel(chr, dev, owner)
    local st = TW.read(dev)
    if not (st and chr) then return end
    local idx = st.presetIdx
    if not idx then
        idx = O.memAdd(chr, dev)
        if not idx then return end
        st = TW.read(dev)
    end
    local cur = (st and st.presets[idx] and st.presets[idx].name) or ""
    local pn = chr:getPlayerNum()
    local target = { chr = chr, dev = dev }
    local box = ISTextBox:new(0, 0, 280, 180, ZeD.tr("UI_ZeD_Radio_NameChannel", string.format("%02d", idx)), cur, target, TW.onNamed, pn, idx)
    box:initialise()
    box:addToUIManager()
    if owner and owner.yieldTop then owner:yieldTop(function() return box:isReallyVisible() end) end
    if owner then box.prevFocus = owner end
    if JoypadState.players[pn + 1] then setJoypadFocus(pn, box) end
    return box
end
function TW.onNamed(target, button, idx)
    if not (button and button.internal == "OK") then return end
    local text = button.parent and button.parent.entry and button.parent.entry:getText() or ""
    O.rename(target.chr, target.dev, idx, text)
end

-- ---------------------------------------------------------------------------
-- IN REACH: the radio is still the character's to use (in the hands or on the back; a set in the world within the
-- radio tab's reach). Full view closes when it is not.
-- ---------------------------------------------------------------------------
function TW.inReach(chr, dev)
    if not (chr and dev) then return false end
    if instanceof(dev, "InventoryItem") then
        if chr:getPrimaryHandItem() == dev or chr:getSecondaryHandItem() == dev then return true end
        return chr.getClothingItem_Back ~= nil and chr:getClothingItem_Back() == dev
    end
    local RT = ZeD.RadioTab
    if not (RT and RT.buildWorldRadios) then return false end
    for _, e in ipairs(RT.buildWorldRadios(chr)) do if e.radioInstance == dev then return true end end
    return false
end

-- ---------------------------------------------------------------------------
-- DRAWING: the face at (x, y) on a panel at zoom k, with its cues; returns this frame's controls in panel px
--   face = { dev, pid, des, focusId (the controller's), hoverId (the mouse's), pressId (a key held down) }
-- ---------------------------------------------------------------------------
function TW.drawFace(panel, x, y, k, face)
    local T = ZeD.T
    local st = TW.read(face.dev)
    if not st then return {}, nil end
    local des = face.des
    local ps = TW.plateState(st, face.pid)
    local cv = P.canvas(panel, x, y, k)
    PL.draw(cv, des, ps, { tex = plateTex, now = now() })
    local ac = T.accent
    local hits = {}
    for _, c in ipairs(PL.controls(des, ps)) do
        local knob = c.kind == "turn"
        hits[#hits + 1] = { id = c.id, kind = c.kind, knob = knob, x = x + c.x * k, y = y + c.y * k, w = c.w * k, h = c.h * k }
        if not knob and face.pressId == c.id then PL.cue(cv, c, P.BLACK, TW.PRESS_SHADE) end
        if face.focusId == c.id then PL.cue(cv, c, ac, 0.55)
        elseif face.hoverId == c.id then PL.cue(cv, c, ac, knob and 0.30 or 0.22) end
    end
    return hits, st
end

-- the control under a point (panel px), nil when none
function TW.hitAt(hits, x, y)
    for i = #(hits or {}), 1, -1 do
        local h = hits[i]
        if x >= h.x and x < h.x + h.w and y >= h.y and y < h.y + h.h then return h end
    end
    return nil
end

-- the controls in reading order (top to bottom, then left to right; rows 12 plate px apart)
function TW.readingOrder(hits, k)
    local out = {}
    for i, h in ipairs(hits or {}) do out[i] = h end
    local row = 12 * (k or 1)
    table.sort(out, function(a, b)
        local ra, rb = math.floor((a.y + a.h / 2) / row), math.floor((b.y + b.h / 2) / row)
        if ra ~= rb then return ra < rb end
        return a.x < b.x
    end)
    return out
end

-- the nearest control in a direction (centre to centre, straight lines preferred), as the car radio walks its face
function TW.nearest(hits, cur, dx, dy)
    if not cur then return nil end
    local cx, cy = cur.x + cur.w / 2, cur.y + cur.h / 2
    local best, bestScore = nil, nil
    for _, h in ipairs(hits or {}) do
        if h.id ~= cur.id then
            local hx, hy = h.x + h.w / 2, h.y + h.h / 2
            local along = (hx - cx) * dx + (hy - cy) * dy
            local across = math.abs((hx - cx) * dy) + math.abs((hy - cy) * dx)
            if along > 2 then
                local score = along + across * 2.5
                if not bestScore or score < bestScore then best, bestScore = h, score end
            end
        end
    end
    return best
end

-- the tuning knob's speed for a held D-pad or a spun wheel (a ham set's dial runs faster)
function TW.turnMult(pid, streak)
    if TW.isBase(pid) then return (streak >= 10 and 25) or (streak >= 4 and 5) or 1 end
    return (streak >= 8 and 5) or 1
end

-- ---------------------------------------------------------------------------
-- THE TAB'S FOOTER: the brand at the left (as the AM/FM chassis' bar), the set's kind at the right
-- ---------------------------------------------------------------------------
function TW.footer(panel, x, y, w, h, pid, highTier)
    local T = ZeD.T
    local tm = ZeD.TM
    local font = T.fontF1
    local ty = y + math.floor((h - tm:getFontHeight(font)) / 2)
    local info = TW.info(pid) or {}
    local tag = ZeD.tr(info.base and "UI_ZeD_Radio_TwoWayBase" or "UI_ZeD_Radio_TwoWayPortable")
    local bg, ink, dim
    if highTier then
        local pt = T.radio.pt
        bg, ink, dim = pt.brandBarBg, pt.btnText, { r = pt.btnText.r, g = pt.btnText.g, b = pt.btnText.b, a = 0.78 }
    else
        local vt = T.radio.vt
        bg, ink, dim = vt.chassisBg, vt.btnText, vt.silkScreen
    end
    panel:drawRect(x, y, w, h, bg.a or 1, bg.r, bg.g, bg.b)
    panel:drawRect(x, y, w, T.px(1), 0.55, 0, 0, 0)
    local tagW = tm:MeasureStringX(font, tag)
    local brand = info.brand or ""
    -- (a walkie's tab is narrow: the brand gives way to the set's kind, cut short as the header's name is)
    local room = w - 2 * T.px(10) - tagW - T.px(8)
    if brand ~= "" and tm:MeasureStringX(font, brand) > room then
        while #brand > 1 and tm:MeasureStringX(font, brand .. "...") > room do brand = brand:sub(1, #brand - 1) end
        brand = brand .. "..."
    end
    if brand ~= "" then
        panel:drawText(brand, x + T.px(10), ty, ink.r, ink.g, ink.b, ink.a or 1, font)
    end
    panel:drawText(tag, x + w - T.px(10) - tagW, ty, dim.r, dim.g, dim.b, dim.a or 1, font)
end

return TW
