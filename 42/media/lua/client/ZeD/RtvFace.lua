-- ZeD-UI/42/media/lua/client/ZeD/RtvFace.lua
-- ============================================================================
-- THE ORDINARY RADIOS', THE CD PLAYER'S AND THE TVS' FACES — the radio tab
-- (RadioTab.lua) draws them in place of the drawn chassis. Handoff
-- ZeDUI/HANDOFF_radio_tv_laundry_20261030.md, approved by the director Oct 30
-- 2026 ("Looks good. No changes. Get it ready for code").
--
-- Seven faces, plates in PhysPx.lua (ZeDUI/tools/physpx/d_rtv.py, d_rtv_make.py)
-- drawn by the shared plate template (ZeD_Plate.lua), as the walkies are:
--   radio_black, radio_red, radio_handbuilt, cd_player   the half card
--   tv_widescreen, tv_black, tv_antique                   the full card
-- picked by the item's full type (PhysPx.rtv.items). A radio or TV placed in a
-- house wears the face of the item it turns into when picked up (director, Oct
-- 30 2026): a radio dropped on the floor by its item, a placed set by its tile's
-- CustomItem, else by its tile: each item's WorldObjectSprite, the four turns of
-- a set being four tiles in a row. A radio with no face (a modded one) keeps
-- the simple card (RadioTab.drawSimple).
--
-- The controls are vanilla's radio verbs, as the car radio and the walkies use
-- them (ZeD_RadioOps: power, volume, mute, tuning, presets, play / stop at the
-- press); a battery, headphones and a CD or a tape in or out go through
-- vanilla's own timed actions in the queue (ISDeviceBatteryAction,
-- ISRadioAction AddHeadphones / RemoveHeadphones, ISDeviceMediaAction), with
-- their checks and their time:
--   power, mute, voldn / volup       as on the car     vol (turn)  the volume
--   tune (turn)  the frequency       p1..p4  press: listen; held: store
--   phones   headphones in / out     battery  batteries in / out (the CD
--            player's is the meter on its screen)
--   slot / eject / play   the disc or the tape: a list of the ones carried,
--            out, play / stop
--   chdn / chup (TVs)  the channel   channel (turn, the antique set) twelve
--            stops printed 2 to 13      volpwr (the antique set) its volume
--            knob: pull on / push off, turned for the volume
--
-- THE TV'S SCREEN (the tvScreen part, drawn here over the plate): dark while
-- the set is off; on, what the game knows about the channel picks it:
--   a tape playing, or the station on air      the picture: the station's (or
--                                               the tape's) name and the lines
--                                               the set has shown
--   just changed channel, or a frequency that is no TV channel   snow (8 a second)
--   a channel number with no station on it     the bars (stops 12 and 13)
--   the station between broadcasts             its sign-off card (two with the
--                                               game's own logo)
--   the station's broadcasts over for good     standby
-- "On air" is the station's airing broadcast (its RadioChannel); "over for good"
-- is a channel whose script has run out. Where the schedule can't be read (a
-- client in multiplayer) a line shown in the last few seconds is "on air".
-- The signal light: on air 3 (good), between broadcasts 2, standby and the bars
-- 1 (bad), snow 0 (dark).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/ZeD_RadioOps"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"
require "ZeD/TwoWayFace"
require "ZeD/ZeD_Bubbles"

ZeD = ZeD or {}
ZeD.Rtv = ZeD.Rtv or {}
local R = ZeD.Rtv
local O = ZeD.RadioOps
local P = ZeD.Px
local PL = ZeD.Plate
local TW = ZeD.TwoWay
local _get = TW._get

R.PAD = 10                -- the space round a half-card face (plate px)
R.HALF_W = 220            -- the half card (units)
R.FULL_W = 480            -- the full card (units)
R.PRESS_SHADE = 0.35      -- a held key's shade
R.SNOW_MS = 125           -- the snow's three frames, about 8 a second
R.ZAP_MS = 450            -- the snow between channels
R.HEARD_MS = 9000         -- a line shown this recently: on air (where the schedule can't be read)
R.LINES = 8               -- the lines a set keeps for its screen

ZeD.trDefaults({
    UI_ZeD_Radio_NoCds = "No CDs on you", UI_ZeD_Radio_NoTapes = "No tapes on you",
    UI_ZeD_Radio_NoBatteries = "No batteries on you", UI_ZeD_Radio_NoHeadphones = "No headphones or earbuds on you",
    UI_ZeD_Radio_CdNone = "NO DISC", UI_ZeD_Radio_Empty = "EMPTY",
})

-- per face: the display's layout (what R.reading fills in), a TV, the antique set's dial
R.INFO = {
    radio_black     = { layout = "fm" },
    radio_red       = { layout = "port" },
    radio_handbuilt = { layout = "makeshift2" },
    cd_player       = { layout = "disc" },
    tv_widescreen   = { tv = true },
    tv_black        = { tv = true },
    tv_antique      = { tv = true, dial = true },
}

local function now() return getTimestampMs() end
-- which of m steps a clock reading (ms) is on, each step ms long: 0 .. m-1. Not `math.floor(t / ms) % m`: the
-- game's Lua gets % wrong once the left side passes 2^31 (it clamps the quotient to an int), and a clock in ms
-- over 125 or 250 is far past that (the TV's snow asked for "snow_7652706499", a picture that is not there).
local function stepOf(t, ms, m)
    local n = math.floor(t / ms)
    return n - math.floor(n / m) * m
end
local function clamp01(v) if v < 0 then return 0 elseif v > 1 then return 1 end; return v end

function R.basePid(pid) return P.baseId(pid) end
function R.info(pid) return R.INFO[P.baseId(pid)] end
function R.isTv(pid) local i = R.info(pid); return i ~= nil and i.tv == true end

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

-- a placed set's tile -> the item it turns into: each item's WorldObjectSprite is the first of its four turns
-- (appliances_television_01_4..7 the black set), so a tile is read as the first of its row of four
local _spriteItem = nil
local function itemOfSprite(name)
    if type(name) ~= "string" then return nil end
    if not _spriteItem then
        _spriteItem = {}
        local sm = getScriptManager and getScriptManager()
        for ft, _ in pairs(ZeD.PhysPx.rtv.items) do
            local ok, scr = pcall(function() return sm:FindItem(ft) end)
            local spr = ok and scr and _get(scr, "getWorldObjectSprite", nil)
            if spr then _spriteItem[tostring(spr)] = ft end
        end
    end
    local head, n = name:match("^(.-)_(%d+)$")
    if not head then return _spriteItem[name] end
    n = tonumber(n)
    return _spriteItem[head .. "_" .. tostring(n - n % 4)] or _spriteItem[name]
end

-- the face's plate id for a radio (an item, or a set in the world), nil when it has none (a two-way set, a modded radio)
function R.plateId(dev, dd)
    local X = ZeD.PhysPx
    local items = X and X.rtv and X.rtv.items
    if not (items and dev) then return nil end
    dd = dd or _get(dev, "getDeviceData", nil)
    if not dd or _get(dd, "getIsTwoWay", false) then return nil end
    local id
    if instanceof(dev, "InventoryItem") then
        id = items[_get(dev, "getFullType", "")]
    elseif instanceof(dev, "IsoObject") then
        local it = droppedItem(dev)
        if it then id = items[_get(it, "getFullType", "")] end
        if not id then
            local props = _get(dev, "getProperties", nil)
            local ci = props and props:has("CustomItem") and props:get("CustomItem") or nil
            id = ci and items[tostring(ci)]
        end
        if not id then
            local spr = _get(dev, "getSprite", nil)
            local ft = itemOfSprite(spr and _get(spr, "getName", nil))
            id = ft and items[ft]
        end
    end
    if id and not X.plates[id] then return nil end
    return id
end

-- for a radio tab entry ({ radioInstance, deviceData }): its plate id and plate
function R.plateFor(entry)
    if not (entry and entry.radioInstance) then return nil, nil end
    local id = R.plateId(entry.radioInstance, entry.deviceData)
    if not id then return nil, nil end
    return id, ZeD.PhysPx.plates[id]
end

-- a radio's face for the half card (Oct 30 2026, HANDOFF_plates_fill_20261030.md): the widest of its widths whose
-- PANEL at zoom k fits the half card's room (220 units less the scrollbar); its id, plate and panel width (plate
-- px), nil when none fits (the hand-built radio at 0.75 and 1.5: no 154 face)
function R.halfFace(pid, k)
    local T = ZeD.T
    local id, pw = P.pickWidth(pid, T.px(R.HALF_W) - T.sp.scrollbarW, k)
    if not pw then return nil, nil, nil end
    return id, ZeD.PhysPx.plates[id], pw
end

-- the face to draw in the tab: a TV the widest that fits roomPx (its narrow face where the main one does not); a
-- radio its half-card face, else (no face fits the half card) the widest that fits the full card
function R.pickFace(pid, roomPx, k)
    local X = ZeD.PhysPx
    if R.isTv(pid) then
        local des, id = P.pick(pid, roomPx)
        return id, des
    end
    local id, des = R.halfFace(pid, k)
    if des then return id, des end
    local T = ZeD.T
    local fid, fw = P.pickWidth(pid, T.px(R.FULL_W) - T.sp.scrollbarW, k)
    if fw then return fid, X.plates[fid] end
    return pid, X.plates[pid]
end

-- the width (screen px) the tab wants for a face (the window makes it the half card or the full card): a radio its
-- panel at zoom k where one fits the half card, else the full card; a TV its plate (its narrow face where that is
-- wider than limit)
function R.wantW(pid, des, k, limit)
    local T = ZeD.T
    local sb = T.sp.scrollbarW
    if R.isTv(pid) then
        local X = ZeD.PhysPx
        local wide = des.w * k + sb
        local nid = X.narrow and X.narrow[pid]
        if limit and wide > limit and nid and X.plates[nid] then return X.plates[nid].w * k + sb end
        return wide
    end
    local _, _, pw = R.halfFace(pid, k)
    if pw then return pw * k + sb end
    return T.px(R.FULL_W)
end

-- the space a face takes in the tab (plate px): a radio its panel (the face and 10 either side), a TV its own width
function R.slotW(des)
    if des.fill and des.fill >= des.w then return des.fill end
    if R.isTv(des.base or des.plate) then return des.w end
    return des.w + 2 * R.PAD
end

-- ---------------------------------------------------------------------------
-- THE TV'S CHANNELS: twelve stops numbered 2 to 13 (the antique set's dial prints them); the first ten are the
-- game's ten channels in frequency order (PhysPx.offair.channels; vanilla's RadioData.xml puts them on 200, 201,
-- 203..210), the last two tune nothing (211, 212: no station there)
-- ---------------------------------------------------------------------------
R.TV_FREQ = { triple_n = 200, wbln = 201, life = 203, turbo = 204, paws = 205, kpa = 206, mvc = 207, nst = 208, bmc = 209, gbc = 210 }
local _stops = nil
function R.stops()
    if _stops then return _stops end
    _stops = {}
    local chans = (ZeD.PhysPx.offair and ZeD.PhysPx.offair.channels) or {}
    for i, c in ipairs(chans) do
        _stops[#_stops + 1] = { i = i, id = c.id, number = c.number, freq = R.TV_FREQ[c.id] or (199 + i) }
    end
    local last = _stops[#_stops]
    for _ = #_stops + 1, 12 do
        local n = #_stops + 1
        _stops[n] = { i = n, number = n + 1, freq = 200 + n - 1 }
    end
    _stops[11].freq, _stops[12].freq = (last and last.freq or 210) + 1, (last and last.freq or 210) + 2
    return _stops
end
function R.stopOf(freq)
    for _, s in ipairs(R.stops()) do if s.freq == freq then return s end end
    return nil
end

-- the station's RadioChannel (nil where the schedule can't be read)
local function scriptChannel(freq)
    local zr = getZomboidRadio and getZomboidRadio()
    local sm = zr and _get(zr, "getScriptManager", nil)
    local list = sm and _get(sm, "getChannelsList", nil)
    if not list then return nil end
    for i = 0, list:size() - 1 do
        local c = list:get(i)
        if _get(c, "GetFrequency", -1) == freq then return c end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- WHAT A SET HAS SHOWN (vanilla's OnDeviceText: the line and, last, the device that showed it), per set
-- ---------------------------------------------------------------------------
R._heard = R._heard or {}      -- key -> { lines, ms, mode }
R._clock = R._clock or {}      -- key -> { ms, t (running since), media, lines (heard since play) }
R._zap = R._zap or {}          -- key -> { ch, t } the channel last seen and when it changed

local function isStatic(line)
    local ok, v = pcall(function() return ZomboidRadio.isStaticSound(line) end)
    return ok and v == true
end
function R.onDeviceText(_guid, _codes, _x, _y, _z, line, dev)
    if not dev or type(line) ~= "string" or line == "" or isStatic(line) then return end
    local key = O.keyOf(dev)
    local B = ZeD.Bubbles
    local s = (B and B.clean) and B.clean(line) or line
    if s == "" then return end
    local h = R._heard[key]
    if not h then h = { lines = {} }; R._heard[key] = h end
    h.ms = now()
    local L = h.lines
    L[#L + 1] = s
    if #L > R.LINES then table.remove(L, 1) end
    h.wrapW = nil
    local c = R._clock[key]
    if c and c.t then c.lines = (c.lines or 0) + 1 end
end
if Events and Events.OnDeviceText and not R._hooked then
    R._hooked = true
    Events.OnDeviceText.Add(function(...) pcall(R.onDeviceText, ...) end)
end

-- the lines for the screen: a set's own, forgotten when it changes channel or starts or stops a tape
local function heardFor(st)
    local h = R._heard[st.key]
    local mode = st.playing and "tape" or st.channel
    if h and h.mode ~= mode then h.lines, h.wrapW, h.ms = {}, nil, nil end
    if h then h.mode = mode end
    return h
end

-- the disc's or the tape's clock (ms): it runs while the media plays, holds when stopped, starts over on play
-- (vanilla's StartPlayMedia plays from the top) and goes with the media
local function clockOf(st)
    local key = st.key
    if not st.hasMedia then R._clock[key] = nil; return 0, 0 end
    local mi = _get(st.dd, "getMediaIndex", -1)
    local c = R._clock[key]
    if not c or c.media ~= mi then c = { ms = 0, media = mi, lines = 0 }; R._clock[key] = c end
    local t = now()
    if st.playing and st.on then
        if not c.t then c.t, c.ms, c.lines = t, 0, 0 end
        return t - c.t, c.lines
    end
    if c.t then c.ms = t - c.t; c.t = nil end
    return c.ms, c.lines
end

-- ---------------------------------------------------------------------------
-- READ: what the face shows (nil when the radio has no device data)
-- ---------------------------------------------------------------------------
function R.read(dev)
    local dd = _get(dev, "getDeviceData", nil)
    if not dd then return nil end
    local st = { dev = dev, dd = dd, key = O.keyOf(dev) }
    st.switchOn = _get(dd, "getIsTurnedOn", false)
    st.battery = _get(dd, "getIsBatteryPowered", false)
    st.hasBattery = st.battery and _get(dd, "getHasBattery", false)
    st.charge = st.hasBattery and _get(dd, "getPower", 0) or 0
    st.grid = _get(dd, "canBePoweredHere", false)
    st.powered = (st.battery and st.charge > 0) or st.grid
    st.on = st.switchOn and st.powered
    st.channel = _get(dd, "getChannel", 0)
    st.volume = _get(dd, "getDeviceVolume", 0.5)
    st.muted = st.volume <= 0.001
    st.min = _get(dd, "getMinChannelRange", 88000)
    st.max = _get(dd, "getMaxChannelRange", 108000)
    st.presets = O.presetList(dd)
    for i, p in ipairs(st.presets) do if p.freq == st.channel then st.presetIdx = i; break end end
    st.name = O.chanName(st.channel)
    st.signal = _get(dd, "isReceivingSignal", false)
    st.phones = _get(dd, "getHeadphoneType", -1) >= 0
    st.mediaType = _get(dd, "getMediaType", -1)
    st.hasMedia = st.mediaType >= 0 and _get(dd, "hasMedia", false)
    st.playing = st.hasMedia and _get(dd, "isPlayingMedia", false)
    if st.hasMedia then
        local md = _get(dd, "getMediaData", nil)
        if md then
            local t, sub = _get(md, "getTitleEN", nil), _get(md, "getSubtitleEN", nil)
            st.mediaTitle = t and (tostring(t) .. (sub and (" - " .. tostring(sub)) or "")) or (sub and tostring(sub)) or nil
            st.mediaLines = _get(md, "getLineCount", 0)
        end
    end
    st.clockMs, st.clockLines = clockOf(st)
    st.flash, st.flashShort = O.flashOf(st.key)
    st.scanning = O._scan[st.key] ~= nil
    return st
end

-- the TV's channel as the screen shows it (see the header): "picture", "snow", "bars", "signoff", "standby", and the
-- stop the channel is on (nil off the dial)
function R.air(st)
    local t = now()
    local z = R._zap[st.key]
    local stop = R.stopOf(st.channel)
    if not z then R._zap[st.key] = { ch = st.channel, t = 0 }               -- first seen: no snow
    elseif z.ch ~= st.channel then z.ch, z.t = st.channel, t; return "snow", stop
    elseif t - z.t < R.ZAP_MS then return "snow", stop end
    if not st.name then return stop and "bars" or "snow", stop end
    local id = stop and stop.id
    local ch = scriptChannel(st.channel)
    if ch then
        if _get(ch, "getAiringBroadcast", nil) then return "picture", stop end
        if not _get(ch, "getCurrentScript", nil) or not id then return "standby", stop end
        return "signoff", stop
    end
    local h = R._heard[st.key]
    if h and h.ms and t - h.ms < R.HEARD_MS then return "picture", stop end
    return id and "signoff" or "standby", stop
end
local SIGNAL = { picture = 3, signoff = 2, standby = 1, bars = 1, snow = 0 }

local function elapsed(ms)
    local s = math.floor((ms or 0) / 1000)
    return string.format("%d:%02d", math.floor(s / 60) % 100, s % 60)
end
local function hms(ms)
    local s = math.floor((ms or 0) / 1000)
    return string.format("%d:%02d:%02d", math.floor(s / 3600) % 10, math.floor(s / 60) % 60, s % 60)
end

-- the plate's own facts, kept on the plate: its screen, its tape slot, the progress line's length, and whether its
-- power is the volume knob's push / pull (the antique set: two areas on one place)
local function factsOf(des)
    local c = des._rtv
    if c then return c end
    c = {}
    for _, p in ipairs(des.parts or {}) do
        if p.t == "tvScreen" then c.screen = p
        elseif p.t == "slotTape" then c.tape = p
        elseif p.t == "radioDisplay" then
            for _, f in ipairs(p.fields or {}) do if f.src == "progress" then c.progN = f.n end end
        end
    end
    local pw, vol = nil, nil
    for _, h in ipairs(des.hits or {}) do
        if h.id == "power" then pw = h elseif h.id == "vol" then vol = h end
    end
    c.volPower = (pw and vol and pw.x == vol.x and pw.y == vol.y and pw.w == vol.w and pw.h == vol.h) and true or false
    des._rtv = c
    return c
end
R.factsOf = factsOf

-- the display's fields for a radio's layout (ZeD_Plate's radioDisplay), nil while the set is off
function R.reading(st, layout, des)
    if not (st and st.on) then return nil end
    local t = now()
    local freq = O.freqText(st.channel, false)
    local blinkOff = st.flash and stepOf(t, 250, 2) == 1
    local preset = (st.flash and (blinkOff and "" or (st.flashShort or ""))) or ((st.presetIdx and st.presetIdx <= 4) and ("P" .. st.presetIdx)) or ""
    local line = st.flash or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or (st.name and ZeD.upper(st.name)) or ""
    if layout == "makeshift2" then
        local sig = st.signal and "||||" or ""
        local l1 = "FM " .. freq .. " MHZ"
        l1 = l1 .. string.rep(" ", math.max(1, 21 - #l1 - #sig)) .. sig
        return { l1 = l1, l2 = line }
    end
    local title = ZeD.upper(st.mediaTitle or O.word("disc"))
    if layout == "disc" then
        local bt = st.hasBattery and math.max(0, math.min(3, math.ceil(st.charge * 3 - 0.001))) or 0
        return { track = st.hasMedia and "01" or "--", time = st.hasMedia and elapsed(st.clockMs) or "-:--", batt = bt,
                 line = (st.muted and O.word("mute")) or (st.hasMedia and title) or ZeD.tr("UI_ZeD_Radio_CdNone") }
    end
    if layout == "port" and st.playing then
        local n = factsOf(des).progN or 30
        local f = (st.mediaLines and st.mediaLines > 0) and clamp01((st.clockLines or 0) / st.mediaLines) or 0
        return { band = "CD", big = elapsed(st.clockMs), preset = "", line = (st.muted and O.word("mute")) or title,
                 progress = math.floor(f * n + 0.5) }
    end
    return { band = "FM", big = freq, preset = preset, line = line, progress = 0 }
end

-- what the face's live parts read (the plate template's state)
function R.plateState(st, pid, des)
    local ps = {}
    local info = R.info(pid) or {}
    ps.radioOn, ps.power = st.on, st.on
    ps.switchOn = st.switchOn
    ps.phonesIn = st.phones
    ps.hasMedia = st.hasMedia
    ps.volF = st.volume
    ps.tuneF = ((((st.channel or 0) / O.STEP) * 12) % 360) / 360          -- an endless tuning knob turns with the frequency
    ps.freqF = clamp01(((st.channel or 0) - 88000) / 20000)               -- the ValuTech's dial: 88 to 108
    ps.batt = st.hasBattery and math.max(0, math.min(4, math.ceil(st.charge * 4 - 0.001))) or 0
    if info.tv then
        local air, stop = R.air(st)
        st.air = air
        ps.noPower = not st.grid
        ps.chIdx = stop and (stop.i - 1) or 0
        local sig = st.on and SIGNAL[air] or 0
        ps.sigBad, ps.sigFair, ps.sigGood = sig == 1, sig == 2, sig >= 3
        if st.on then
            ps.display = { ch = stop and string.format("%02d", stop.number) or "--", playing = st.playing,
                           counter = st.hasMedia and hms(st.clockMs) or "" }
        end
    else
        ps.display = R.reading(st, info.layout, des)
    end
    return ps
end

-- ---------------------------------------------------------------------------
-- THE SCREEN AND THE TAPE (parts the plate template leaves to the organism)
-- ---------------------------------------------------------------------------
local BG, INK, DIM = P.color("#0c1218"), P.color("#e6ecef"), P.color("#8ea2ae")
local _insets = {}
-- each row's inset from the side for a round corner of radius r
local function insets(r)
    local t = _insets[r]
    if t then return t end
    t = {}
    for i = 0, r - 1 do
        local dy = r - i - 0.5
        t[i + 1] = math.ceil(r - math.sqrt(math.max(0, r * r - dy * dy)))
    end
    _insets[r] = t
    return t
end
local function roundRect(cv, x, y, w, h, r, c)
    r = math.min(r or 0, math.floor(h / 2), math.floor(w / 2))
    local ins = insets(r)
    for i = 1, r do
        local d = ins[i]
        P.rect(cv, x + d, y + i - 1, w - 2 * d, 1, c)
        P.rect(cv, x + d, y + h - i, w - 2 * d, 1, c)
    end
    P.rect(cv, x, y + r, w, h - 2 * r, c)
end

-- an off-air screen's texture for this face (PhysPx.offair.sets: one set per face at its screen's size)
local function screenTex(des, name)
    local c = des._rtvTex
    if not c then c = {}; des._rtvTex = c end
    local t = c[name]
    if t == nil then
        local X = ZeD.PhysPx
        local set = X.offair and X.offair.sets and X.offair.sets[des.plate]
        t = set and P.tex(X.texdir .. set .. name .. ".png") or false
        c[name] = t
    end
    return t or nil
end

-- the channel's own logo on its sign-off card (the game's file), fitted to its box keeping its shape, tinted
local _logo, _logoTint = {}, {}
local function drawLogo(cv, sp, id, tube)
    local L = ZeD.PhysPx.offair.logos and ZeD.PhysPx.offair.logos[id]
    if not L then return end
    local tex = _logo[id]
    if tex == nil then tex = getTexture(L.file) or false; _logo[id] = tex end
    if not tex then return end
    local tw, th = _get(tex, "getWidth", 0), _get(tex, "getHeight", 0)
    if tw <= 0 or th <= 0 then return end
    local bx, by, bw, bh = sp.x + L.box[1] * sp.w, sp.y + L.box[2] * sp.h, L.box[3] * sp.w, L.box[4] * sp.h
    local s = math.min(bw / tw, bh / th)
    local m = tube
    if not m then
        m = _logoTint[id]
        if not m then m = { r = L.tint[1], g = L.tint[2], b = L.tint[3] }; _logoTint[id] = m end
    end
    P.imageTint(cv, tex, bx + (bw - tw * s) / 2, by + (bh - th * s) / 2, tw * s, th * s, m)
end

-- the picture: the station's (or the tape's) name, then the lines it has shown, the newest at the foot
local function drawPicture(cv, sp, st, tube)
    local function ink(c) return tube and P.mulColor(c, tube) or c end
    roundRect(cv, sp.x, sp.y, sp.w, sp.h, sp.r or 0, ink(BG))
    local pad = 8
    local head = st.playing and st.mediaTitle or st.name
    if head and head ~= "" then
        local s, f, sc = P.fit(ZeD.upper(head), "35", 1, sp.w - 2 * pad)
        P.text(cv, s, sp.x + pad, sp.y + pad, ink(DIM), f, sc)
    end
    local h = heardFor(st)
    if not (h and #h.lines > 0) then return end
    local maxw = sp.w - 2 * pad
    if h.wrapW ~= maxw then                    -- wrapped again only when the lines or the screen change
        local out = {}
        for _, l in ipairs(h.lines) do
            local ls = ZeD.Bubbles.wrap(l, maxw)
            for _, x in ipairs(ls) do out[#out + 1] = x end
        end
        h.wrapped, h.wrapW = out, maxw
    end
    local W = h.wrapped
    local rows = math.max(1, math.floor((sp.h - 2 * pad - 8) / 9))
    local first = math.max(1, #W - rows + 1)
    local y = sp.y + sp.h - pad - 7 - (#W - first) * 9
    for i = first, #W do
        P.text(cv, W[i], sp.x + pad, y, ink(INK), "57")
        y = y + 9
    end
end

-- the screen while the set is on (off, the plate's own dark tube shows)
local function drawScreen(cv, des, sp, st)
    local tube = sp.tint and P.color(sp.tint) or nil
    local air = st.air
    if st.playing or air == "picture" then drawPicture(cv, sp, st, tube); return end
    local name, id = air, nil
    if air == "snow" then name = "snow_" .. tostring(stepOf(now(), R.SNOW_MS, 3))
    elseif air == "signoff" then
        local stop = R.stopOf(st.channel)
        id = stop and stop.id
        name = id and ("signoff_" .. id) or "standby"
    end
    local tex = screenTex(des, name)
    if tex then P.image(cv, tex, sp.x, sp.y, sp.w, sp.h) else roundRect(cv, sp.x, sp.y, sp.w, sp.h, sp.r or 0, BG) end
    if id then drawLogo(cv, sp, id, tube) end
end

local function drawExtras(cv, des, st)
    local f = factsOf(des)
    if f.tape and st.hasMedia then P.rect(cv, f.tape.x, f.tape.y, f.tape.w, 1, P.color(f.tape.color)) end
    if f.screen and st.on then drawScreen(cv, des, f.screen, st) end
end

-- ---------------------------------------------------------------------------
-- DRAWING: the face at (x, y) on a panel at zoom k, with its cues; returns this frame's controls in panel px
--   face = { dev, pid, des, focusId (the controller's), hoverId (the mouse's), pressId (a key held down) }
-- The antique set's power and volume share the knob: one control, "volpwr" (pressed: power; turned: volume).
-- ---------------------------------------------------------------------------
function R.drawFace(panel, x, y, k, face)
    local T = ZeD.T
    local st = R.read(face.dev)
    if not st then return {}, nil end
    local des = face.des
    local ps = R.plateState(st, face.pid, des)
    local cv = P.canvas(panel, x, y, k)
    PL.draw(cv, des, ps, { tex = TW.plateTex, now = now() })
    drawExtras(cv, des, st)
    local shared = factsOf(des).volPower
    local ac = T.accent
    local hits = {}
    for _, c in ipairs(PL.controls(des, ps)) do
        if not (shared and c.id == "power") then
            if shared and c.id == "vol" then c.id = "volpwr" end
            local knob = c.kind == "turn"
            hits[#hits + 1] = { id = c.id, kind = c.kind, knob = knob, x = x + c.x * k, y = y + c.y * k, w = c.w * k, h = c.h * k }
            if not knob and face.pressId == c.id then PL.cue(cv, c, P.BLACK, R.PRESS_SHADE) end
            if face.focusId == c.id then
                if knob then PL.cue(cv, c, ac, 0.55) else PL.markKey(panel, c, x, y, k, nil) end
            elseif face.hoverId == c.id then
                if knob then PL.cue(cv, c, ac, 0.30) else PL.hoverKey(cv, c) end
            end
        end
    end
    return hits, st
end

-- the controls in the order the controller meets them: power first (where focus lands), then reading order
function R.focusOrder(hits, k)
    local out = TW.readingOrder(hits, k)
    for i, h in ipairs(out) do
        if h.id == "power" or h.id == "volpwr" then table.remove(out, i); table.insert(out, 1, h); break end
    end
    return out
end
R.hitAt = TW.hitAt

-- ---------------------------------------------------------------------------
-- ACTIONS (chr = the character, dev = the radio; at = { x, y } on the screen, where a list opens)
-- ---------------------------------------------------------------------------
-- vanilla's battery and media actions name the device by its item id (in the inventory) or its square
local function param(chr, dev)
    local kind = instanceof(dev, "InventoryItem") and "InventoryItem" or "IsoObject"
    local ok, v = pcall(function() return ISDeviceBatteryAction:getDeviceDataParameter(chr, dev, kind) end)
    return ok and v or nil
end
local function queue(a, dev)
    if not a.deviceData then a.deviceData = dev:getDeviceData() end      -- (a square holding two sets answers for one)
    ISTimedActionQueue.add(a)
    return true
end
local function battery(chr, dev, isRemove, item)
    if not (ISDeviceBatteryAction and ISTimedActionQueue and chr and dev) then return false end
    if item then pcall(ISInventoryPaneContextMenu.transferIfNeeded, chr, item) end
    return queue(ISDeviceBatteryAction:new(chr, isRemove, item, param(chr, dev)), dev)
end
local function media(chr, dev, isRemove, item)
    if not (ISDeviceMediaAction and ISDeviceBatteryAction and ISTimedActionQueue and chr and dev) then return false end
    if item then pcall(ISInventoryPaneContextMenu.transferIfNeeded, chr, item) end
    return queue(ISDeviceMediaAction:new(chr, isRemove, item, param(chr, dev)), dev)
end
R.queueBattery, R.queueMedia = battery, media

-- a list over the control (the discs carried), or one line saying there is nothing; the controller's focus goes
-- into it and back to where it was when it closes
local function listMenu(chr, at, items, emptyKey, onPick, target)
    local pn = chr:getPlayerNum()
    local context = ISContextMenu.get(pn, at and at.x or getMouseX(), at and at.y or getMouseY())
    for _, it in ipairs(items) do
        local o = context:addOption(it:getDisplayName(), target, onPick, it)
        o.itemForTexture = it
    end
    if #items == 0 then
        local o = context:addOption(ZeD.tr(emptyKey))
        o.notAvailable = true
    end
    local jd = JoypadState.players[pn + 1]
    if jd then
        context.origin = jd.focus
        context.mouseOver = 1
        setJoypadFocus(pn, context)
    end
    return context
end
R._listMenu = listMenu

local function onPickMedia(t, item) media(t.chr, t.dev, false, item) end
local function onPickNothing() end

-- the slot (and the eject key with nothing in): out with the disc or the tape, else the list of those carried
function R.mediaKey(chr, dev, st, at)
    if st.hasMedia then return media(chr, dev, true, nil) end
    local list = O.cds(chr, dev)
    listMenu(chr, at, list, st.mediaType == 1 and "UI_ZeD_Radio_NoTapes" or "UI_ZeD_Radio_NoCds", onPickMedia, { chr = chr, dev = dev })
    return true
end

-- the battery: out when one is in, else the fullest one carried (vanilla's choice)
function R.batteryKey(chr, dev, st, at)
    if not st.battery then return false end
    if st.hasBattery then return battery(chr, dev, true, nil) end
    local best, most = nil, 0
    local list = chr:getInventory():getAllTypeRecurse("Base.Battery")
    for i = 0, (list and list:size() or 0) - 1 do
        local b = list:get(i)
        local u = _get(b, "getCurrentUsesFloat", 0)
        if u > most then best, most = b, u end
    end
    if best then return battery(chr, dev, false, best) end
    listMenu(chr, at, {}, "UI_ZeD_Radio_NoBatteries", onPickNothing, nil)
    return false
end

-- the headphone jack: the plug out, else the first headphones or earbuds carried in (vanilla's controller choice)
function R.phonesKey(chr, dev, st, at)
    if not (ISRadioAction and ISTimedActionQueue) then return false end
    if st.phones then ISTimedActionQueue.add(ISRadioAction:new("RemoveHeadphones", chr, dev)); return true end
    local inv = chr:getInventory()
    local found = nil
    for _, ft in ipairs({ "Base.Headphones", "Base.Earbuds" }) do
        local l = inv:FindAll(ft)
        if l and l:size() > 0 then found = l:get(0); break end
    end
    if found then ISTimedActionQueue.add(ISRadioAction:new("AddHeadphones", chr, dev, found)); return true end
    listMenu(chr, at, {}, "UI_ZeD_Radio_NoHeadphones", onPickNothing, nil)
    return false
end

-- the TV's channel a stop up or down (dir), round the twelve; the antique's dial a stop, stopping at its ends
function R.chStep(chr, dev, st, dir, wrap)
    if not st.on then return false end
    local stops = R.stops()
    local s = R.stopOf(st.channel)
    local i
    if wrap then
        -- (wrap: down on the first stop goes to the last, up on the last to the first; director, Oct 30 2026, punch
        -- list 23. Kahlua's % keeps a negative dividend's sign, so -1 % n is -1 here: add n before taking it)
        local n = #stops
        i = s and (((s.i - 1 + dir + n) % n) + 1) or (dir > 0 and 1 or n)
    else
        i = math.max(1, math.min(#stops, (s and s.i or 1) + dir))
        if s and i == s.i then return false end
    end
    return O.setChannel(chr, dev, stops[i].freq)
end

-- a knob turned one click (dir +1 / -1); mult = the fast-turn multiplier
function R.turn(chr, dev, id, dir, mult)
    if id == "vol" or id == "volpwr" then O.volStep(chr, dev, dir, false)
    elseif id == "tune" then O.tuneStep(chr, dev, dir, mult or 1)
    elseif id == "channel" then local st = R.read(dev); if st then R.chStep(chr, dev, st, dir, false) end end
end

-- the press (a click, A, the end of a short press); dx = where a knob was clicked (< 0: its left half)
function R.press(chr, dev, id, dx, at)
    local st = R.read(dev)
    if not (st and id) then return end
    if id == "power" or id == "volpwr" then O.power(chr, dev)
    elseif id == "vol" or id == "tune" or id == "channel" then R.turn(chr, dev, id, (dx and dx < 0) and -1 or 1)
    elseif id == "mute" then O.mute(chr, dev)
    elseif id == "voldn" then O.volStep(chr, dev, -1, false)
    elseif id == "volup" then O.volStep(chr, dev, 1, false)
    elseif id:match("^p%d$") then
        if st.on and not O.recall(chr, dev, tonumber(id:sub(2))) then O.flash(dev, ZeD.tr("UI_ZeD_Radio_Empty"), 900) end
    elseif id == "chup" then R.chStep(chr, dev, st, 1, true)
    elseif id == "chdn" then R.chStep(chr, dev, st, -1, true)
    elseif id == "phones" then R.phonesKey(chr, dev, st, at)
    elseif id == "battery" then R.batteryKey(chr, dev, st, at)
    elseif id == "slot" or id == "eject" then R.mediaKey(chr, dev, st, at)
    elseif id == "play" then O.playStop(chr, dev) end
end

-- the second meaning (X, a hold, a right-click)
function R.secondary(chr, dev, id)
    local st = R.read(dev)
    if not (st and id) then return end
    if id:match("^p%d$") then if st.on then O.store(chr, dev, tonumber(id:sub(2))) end
    elseif id == "tune" or id == "vol" or id == "volpwr" or id == "channel" then R.turn(chr, dev, id, -1) end
end

-- presets act on the release (a hold stores instead); a key that may open a list acts on the release too, or the
-- release would close the list it opened
function R.holdable(id) return id:match("^p%d$") ~= nil end
local ON_RELEASE = { slot = true, eject = true, phones = true, battery = true }
function R.onRelease(id) return R.holdable(id) or ON_RELEASE[id] == true end

-- a held press past O.HOLD_MS does its second meaning once; hold = { id, t0, fired }
function R.holdTick(hold, chr, dev)
    if hold and not hold.fired and R.holdable(hold.id) and now() - hold.t0 >= O.HOLD_MS then
        hold.fired = true
        R.secondary(chr, dev, hold.id)
    end
end

-- the tuning knob's speed for a held D-pad or a spun wheel
function R.turnMult(pid, streak)
    return (streak >= 8 and 5) or 1
end

return R
