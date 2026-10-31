-- ZeD-UI/42/media/lua/client/ZeD/ZeD_RadioOps.lua
-- ============================================================================
-- THE CAR RADIO'S WORKINGS — shared by the radio up close (ZeD_CarRadio.lua)
-- and the dash's head unit (ZeD_Dashboard.lua), so both drive the same radio
-- the same way. Mockup ZeDUI/mockups/zed_car_radio_v1.html (director, Oct 15
-- 2026: "love it, build it, yes match the dash to the radio").
--
-- A car's Radio part holds one of vanilla's six radio items; each has a face
-- (the kind). Every change goes through vanilla's own radio action code
-- (ISRadioAction's isValid / perform for power, volume, mute, tuning, the
-- microphone, play / stop; ISDeviceMediaAction through the action queue for a
-- CD in or out), so sounds, rules and multiplayer stay vanilla's. Presets are
-- vanilla's own device presets (the list the Device Options window edits).
--
-- Also here: the display drawing (each kind's glass, full size and small),
-- the short-lived things both surfaces show (STORE flashes, SCAN, the CD's
-- elapsed time).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"

ZeD = ZeD or {}
ZeD.RadioOps = ZeD.RadioOps or {}
local O = ZeD.RadioOps

-- The words a radio's glass spells (SCAN, MUTE...) are keys in Translate/<LANG>/UI.json, read through ZeD.tr at the
-- moment they draw. The hardware's own marks stay as printed: FM, CD, MHz, CH, TX, P1..P6.
local WORDS = { scan = "UI_ZeD_Radio_Scan", mute = "UI_ZeD_Radio_Mute", micOff = "UI_ZeD_Radio_MicOff", txOk = "UI_ZeD_Radio_TxOk",
                disc = "UI_ZeD_Radio_CompactDisc", mic = "UI_ZeD_Radio_Mic" }
ZeD.trDefaults({
    UI_ZeD_Radio_Scan = "SCAN", UI_ZeD_Radio_Mute = "MUTE", UI_ZeD_Radio_MicOff = "MIC OFF", UI_ZeD_Radio_TxOk = "TX OK",
    UI_ZeD_Radio_CompactDisc = "COMPACT DISC", UI_ZeD_Radio_Mic = "MIC", UI_ZeD_Radio_Empty = "EMPTY",
    UI_ZeD_Radio_Store = "STORE %1", UI_ZeD_Radio_ChStored = "CH %1 STORED", UI_ZeD_Radio_MemFull = "MEMORY FULL",
    UI_ZeD_Radio_ChCleared = "CH %1 CLEARED", UI_ZeD_Radio_Range = "RANGE %1 KM",
})
-- (a clock in ms over a step: which of m steps it is on, 0 .. m-1. Not `math.floor(t / ms) % m`: the game's Lua gets
-- % wrong once the left side passes 2^31, and a clock in ms divided by a few hundred is far past it; Oct 31 2026)
local function clockStep(t, ms, m)
    local n = math.floor(t / ms)
    return n - math.floor(n / m) * m
end

-- the word for a glass: O.word("scan"), "mute", "micOff", "txOk", "disc", "mic"
function O.word(w) return ZeD.tr(WORDS[w]) end

O.HOLD_MS = 600          -- a press held this long stores (presets) or names (MEM)
O.STEP = 200             -- one tuning step, in kHz (vanilla's channels sit on 200 kHz steps)
O.SCAN_DWELL_MS = 5000   -- SCAN stays this long on each station

-- vanilla's radio items -> faces (template_radio / template_radio_HAM)
O.KIND_BY_ITEM = {
    ["Base.RadioRed"] = "premium", ["Base.RadioBlack"] = "valutech", ["Base.RadioMakeShift"] = "makeshift",
    ["Base.HamRadio1"] = "ham", ["Base.HamRadio2"] = "army", ["Base.HamRadioMakeShift"] = "hammake",
}
O.HAM = { ham = true, army = true, hammake = true }

local function _safe(fn, default) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return default end
-- the same for one method call with no arguments, without making a closure each time (these are read every frame;
-- Oct 22 2026, the drawing-cost work): o:m(), its value or the default when it fails or gives nil
local function _inv(o, m) return o[m](o) end
local function _get(o, m, default)
    if o == nil then return default end
    local ok, v = pcall(_inv, o, m)
    if ok and v ~= nil then return v end
    return default
end
local function now() return getTimestampMs() end
local function clamp(v, lo, hi) if v < lo then return lo end; if v > hi then return hi end; return v end

-- the face for a fitted radio item; modded radios borrow the nearest face
function O.kindOf(item, dd)
    if not item then return nil end
    local ft = _get(item, "getFullType", "")
    if O.KIND_BY_ITEM[ft] then return O.KIND_BY_ITEM[ft] end
    if dd and _get(dd, "getIsTwoWay", false) then return "ham" end
    if dd and _get(dd, "getMediaType", -1) >= 0 then return "premium" end
    return "valutech"
end

-- a radio's key for the short-lived state below. The radio is its owner, whatever holds the device data: a car's
-- Radio part, a radio item in the hands (the two-way walkies), or a set placed in the world (IsoWaveSignal); the
-- verbs below take any of them (ISRadioAction does: it asks the owner for getDeviceData).
local function keyOf(part)
    -- no part (the vehicle is gone): a key that no radio holds
    if not part then return "none" end
    if instanceof(part, "VehiclePart") then
        return _safe(function() return tostring(part:getVehicle():getId()) .. ":" .. tostring(part:getId()) end, tostring(part))
    end
    if instanceof(part, "InventoryItem") then return "item:" .. tostring(_get(part, "getID", 0)) end
    if instanceof(part, "IsoObject") then
        -- (a set just taken away has no square: its place can no longer be read)
        local sq = part:getSquare()
        if not sq then return tostring(part) end
        return string.format("w:%d,%d,%d", sq:getX(), sq:getY(), sq:getZ())
    end
    return tostring(part)
end
O.keyOf = keyOf

-- vanilla's station name for a frequency (nil when vanilla has none)
function O.chanName(hz)
    local zr = getZomboidRadio and getZomboidRadio()
    if not (zr and zr.getChannelName and hz) then return nil end
    local n = _safe(function() return zr:getChannelName(hz) end, nil)
    if n and n ~= "" and not tostring(n):upper():find("UNKNOWN") then return tostring(n) end
    return nil
end

-- "101.2" on an FM set, "098.400" on a two-way set
function O.freqText(hz, ham)
    hz = hz or 0
    if ham then local t = string.format("%.3f", hz / 1000); return string.rep("0", 7 - #t) .. t end   -- padded by hand (Kahlua's format)
    return string.format("%.1f", hz / 1000)
end

-- ---------------------------------------------------------------------------
-- short-lived state (per radio): flashes, scan, the CD clock, the volume before MUTE
-- ---------------------------------------------------------------------------
O._flash, O._scan, O._cd, O._lastVol = O._flash or {}, O._scan or {}, O._cd or {}, O._lastVol or {}

-- short = what a small glass shows in place of the text ("P3" for "STORE 3"); nil = the text itself
function O.flash(part, text, ms, short) O._flash[keyOf(part)] = { text = text, short = short, untilMs = now() + (ms or 1400) } end
local function flashOf(key)
    local f = O._flash[key]
    if f and now() < f.untilMs then return f.text, f.short or f.text end
    O._flash[key] = nil
    return nil
end
O.flashOf = flashOf

-- a two-way set's LAMP: the display's backlight for LAMP_MS after a press (per radio)
O.LAMP_MS = 5000
O._lamp = O._lamp or {}
function O.lamp(part) O._lamp[keyOf(part)] = now() + O.LAMP_MS end
function O.lampLit(part)
    local k = keyOf(part)
    local t = O._lamp[k]
    if t and now() < t then return true end
    O._lamp[k] = nil
    return false
end

-- ---------------------------------------------------------------------------
-- READ: everything the faces show, in one table (nil when no radio is fitted)
-- ---------------------------------------------------------------------------
function O.presetList(dd)
    local out = {}
    local pc = _get(dd, "getDevicePresets", nil)
    local l = pc and _get(pc, "getPresets", nil)
    if l then
        for i = 0, l:size() - 1 do
            local p = l:get(i)
            out[#out + 1] = { name = tostring(_get(p, "getName", "")), freq = _get(p, "getFrequency", 0) }
        end
    end
    return out, (pc and _get(pc, "getMaxPresets", 10)) or 10
end

function O.read(part)
    if not part then return nil end
    local item = _get(part, "getInventoryItem", nil)
    local dd = item and _get(part, "getDeviceData", nil)
    if not dd then return nil end
    local st = { part = part, dd = dd, item = item, key = keyOf(part) }
    st.kind = O.kindOf(item, dd)
    st.ham = O.HAM[st.kind] == true
    st.switchOn = _get(dd, "getIsTurnedOn", false)
    local batt = _get(dd, "getIsBatteryPowered", false)
    st.powered = (batt and _get(dd, "getPower", 0) > 0) or _get(dd, "canBePoweredHere", false)
    st.on = st.switchOn and st.powered
    st.channel = _get(dd, "getChannel", 0)
    st.volume = _get(dd, "getDeviceVolume", 0.5)
    st.muted = st.volume <= 0.001
    st.min = _get(dd, "getMinChannelRange", 88000)
    st.max = _get(dd, "getMaxChannelRange", 108000)
    st.presets, st.maxPresets = O.presetList(dd)
    for i, p in ipairs(st.presets) do if p.freq == st.channel then st.presetIdx = i; break end end
    st.name = O.chanName(st.channel)
    st.signal = _get(dd, "isReceivingSignal", false)
    st.twoWay = _get(dd, "getIsTwoWay", false)
    st.micMuted = _get(dd, "getMicIsMuted", false)
    st.range = _get(dd, "getTransmitRange", 0)
    st.mediaType = _get(dd, "getMediaType", -1)
    st.hasMedia = st.mediaType >= 0 and _get(dd, "hasMedia", false)
    st.playing = st.hasMedia and _get(dd, "isPlayingMedia", false)
    if st.hasMedia then
        local md = _get(dd, "getMediaData", nil)
        if md then
            local t, sub = _get(md, "getTitleEN", nil), _get(md, "getSubtitleEN", nil)
            st.mediaTitle = t and (tostring(t) .. (sub and (" - " .. tostring(sub)) or "")) or (sub and tostring(sub)) or nil
        end
    end
    -- the CD's clock: counted from when it was first seen playing
    if st.playing and st.on then
        local c = O._cd[st.key]
        if not c then c = now(); O._cd[st.key] = c end
        st.cdMs = now() - c
    else
        O._cd[st.key] = nil
    end
    st.flash, st.flashShort = flashOf(st.key)
    st.scanning = O._scan[st.key] ~= nil
    return st
end

-- the radio a character can reach (vanilla: front seats only), with its part
function O.reachable(chr)
    local v = chr and chr:getVehicle()
    if not v then return nil end
    local seat = _safe(function() return v:getSeat(chr) end, 9)
    if seat > 1 then return nil end
    local part = _safe(function() return v:getPartById("Radio") end, nil)
    if part and _get(part, "getInventoryItem", nil) and _get(part, "getDeviceData", nil) then return part end
    return nil
end

-- ---------------------------------------------------------------------------
-- ACTIONS — vanilla's radio action code, run on the press
-- ---------------------------------------------------------------------------
-- ISRadioAction's own isValid<mode> / perform<mode> (the work its timed action
-- does, with its sounds), run at once: a radio's buttons answer on the press.
local function run(mode, chr, part, arg)
    if not (ISRadioAction and chr and part) then return false end
    local a = ISRadioAction:new(mode, chr, part, arg)
    if not a.deviceData then return false end
    local ok, valid = pcall(function() local f = a["isValid" .. mode]; return (not f) or f(a) end)
    if not (ok and valid) then return false end
    local f = a["perform" .. mode]
    if not f then return false end
    local done, err = pcall(f, a)
    if not done then print("[ZeD] RadioOps: " .. mode .. " failed: " .. tostring(err)); return false end
    return true
end
O.run = run

local function stopScan(part)
    if not part then return end   -- the vehicle is gone: nothing is scanning
    O._scan[keyOf(part)] = nil
end
O.stopScan = stopScan

function O.power(chr, part) stopScan(part); return run("ToggleOnOff", chr, part) end

-- dir +1 / -1 a tenth; wrap = the dash's one-button volume (past full it starts over)
function O.volStep(chr, part, dir, wrap)
    if not part then return false end
    local dd = part:getDeviceData(); if not dd then return false end
    local cur = _get(dd, "getDeviceVolume", 0.5)
    local nv = math.floor((cur + 0.1 * dir) * 10 + 0.5) / 10
    if wrap then if nv > 1.001 then nv = 0 elseif nv < 0 then nv = 1 end else nv = clamp(nv, 0, 1) end
    return run("SetVolume", chr, part, nv)
end

function O.mute(chr, part)
    if not part then return false end
    local dd = part:getDeviceData(); if not dd then return false end
    local cur = _get(dd, "getDeviceVolume", 0.5)
    if cur > 0.001 then
        O._lastVol[keyOf(part)] = cur
        return run("MuteVolume", chr, part)
    end
    return run("UnMuteVolume", chr, part, O._lastVol[keyOf(part)] or 0.5)
end

local function setChannel(chr, part, hz) return run("SetChannel", chr, part, hz) end
O.setChannel = setChannel

-- one click of TUNE / the DIAL (mult: the fast-turn multiplier); the band wraps
function O.tuneStep(chr, part, dir, mult)
    if not part then return false end
    stopScan(part)
    local dd = part:getDeviceData(); if not dd then return false end
    local lo, hi = _get(dd, "getMinChannelRange", 88000), _get(dd, "getMaxChannelRange", 108000)
    local cur = _get(dd, "getChannel", lo)
    local nv = math.floor((cur + dir * O.STEP * (mult or 1)) / O.STEP + 0.5) * O.STEP
    if nv > hi then nv = lo elseif nv < lo then nv = hi end
    return setChannel(chr, part, nv)
end

-- the next frequency vanilla has a station on (FM sets)
function O.nextStation(dd, dir)
    local lo, hi = _get(dd, "getMinChannelRange", 88000), _get(dd, "getMaxChannelRange", 108000)
    local cur = _get(dd, "getChannel", lo)
    local n = math.floor((hi - lo) / O.STEP) + 1
    for _ = 1, math.min(n, 6000) do
        cur = cur + dir * O.STEP
        if cur > hi then cur = lo elseif cur < lo then cur = hi end
        if O.chanName(cur) then return cur end
    end
    return nil
end

function O.seek(chr, part, dir)
    if not part then return false end
    stopScan(part)
    local hz = O.nextStation(part:getDeviceData(), dir or 1)
    if hz then return setChannel(chr, part, hz) end
    return false
end

-- SCAN: on to the next station, a few seconds on each, until pressed again
function O.scanToggle(chr, part)
    if not part then return false end
    local k = keyOf(part)
    if O._scan[k] then O._scan[k] = nil; return true end
    local hz = O.nextStation(part:getDeviceData(), 1)
    if not hz or not setChannel(chr, part, hz) then return false end
    O._scan[k] = { chr = chr, part = part, nextMs = now() + O.SCAN_DWELL_MS, veh = instanceof(part, "VehiclePart") }
    return true
end

local function scanTick()
    local t = nil
    for k, sc in pairs(O._scan) do
        t = t or now()
        local dd = _get(sc.part, "getDeviceData", nil)
        -- a car's radio scans while the character is in the car; a walkie or a placed set while it is on
        local alive = dd and sc.chr and ((not sc.veh) or sc.chr:getVehicle()) and _get(dd, "getIsTurnedOn", false)
        if not alive then O._scan[k] = nil
        elseif t >= sc.nextMs then
            local hz = O.nextStation(dd, 1)
            if hz then setChannel(sc.chr, sc.part, hz) end
            sc.nextMs = t + O.SCAN_DWELL_MS
        end
    end
end
if Events and Events.OnTick then Events.OnTick.Add(scanTick) end

-- presets: vanilla's own list (the first six are the buttons on an FM set)
local function presetsOf(part)
    if not part then return nil, nil, nil end   -- the vehicle is gone
    local dd = part:getDeviceData()
    local pc = dd and _get(dd, "getDevicePresets", nil)
    local l = pc and _get(pc, "getPresets", nil)
    return dd, pc, l
end

local function storedName(hz, ham)
    return O.chanName(hz) or (O.freqText(hz, ham) .. " MHz")
end

function O.recall(chr, part, i)
    stopScan(part)
    local _, _, l = presetsOf(part)
    if not l or i < 1 or i > l:size() then return false end
    return setChannel(chr, part, l:get(i - 1):getFrequency())
end

-- store the station on button i (past the list's end it goes on the next free
-- button); returns the button it went on
function O.store(chr, part, i)
    stopScan(part)
    local dd, pc, l = presetsOf(part)
    if not l then return nil end
    local hz = _get(dd, "getChannel", nil); if not hz then return nil end
    local n = l:size()
    local idx = math.min(i, n + 1)
    local name = storedName(hz, _get(dd, "getIsTwoWay", false))
    if idx <= n then
        local p = l:get(idx - 1)
        p:setName(name); p:setFrequency(hz)
    else
        if n >= _get(pc, "getMaxPresets", 10) then return nil end
        l:add(PresetEntry.new(name, hz))
    end
    pcall(function() dd:transmitPresets() end)
    pcall(function() getSoundManager():playUISound("VehicleRadioButton") end)
    O.flash(part, ZeD.tr("UI_ZeD_Radio_Store", idx), 1400, "P" .. idx)
    return idx
end

-- two-way sets: CH up / down through every stored channel
function O.chStep(chr, part, dir)
    stopScan(part)
    local dd, _, l = presetsOf(part)
    if not l or l:size() == 0 then return false end
    local n = l:size()
    local cur = _get(dd, "getChannel", 0)
    local at = nil
    for i = 0, n - 1 do if l:get(i):getFrequency() == cur then at = i + 1; break end end
    local nxt
    if at then nxt = ((at - 1 + dir) % n) + 1 else nxt = dir > 0 and 1 or n end
    return setChannel(chr, part, l:get(nxt - 1):getFrequency())
end

-- MEM: the station joins the stored channels (once); returns its channel number
function O.memAdd(chr, part)
    local dd, pc, l = presetsOf(part)
    if not l then return nil end
    local hz = _get(dd, "getChannel", nil); if not hz then return nil end
    for i = 0, l:size() - 1 do if l:get(i):getFrequency() == hz then O.flash(part, ZeD.tr("UI_ZeD_Radio_ChStored", string.format("%02d", i + 1)), 1400); return i + 1 end end
    if l:size() >= _get(pc, "getMaxPresets", 10) then O.flash(part, ZeD.tr("UI_ZeD_Radio_MemFull"), 1600); return nil end
    l:add(PresetEntry.new(storedName(hz, true), hz))
    pcall(function() dd:transmitPresets() end)
    pcall(function() getSoundManager():playUISound("VehicleRadioButton") end)
    O.flash(part, ZeD.tr("UI_ZeD_Radio_ChStored", string.format("%02d", l:size())), 1400)
    return l:size()
end

-- name channel idx; an empty name forgets the channel
function O.rename(chr, part, idx, name)
    local dd, _, l = presetsOf(part)
    if not l or idx < 1 or idx > l:size() then return false end
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        l:remove(l:get(idx - 1))   -- by the entry, as vanilla does (an index would be read as an Object)
        O.flash(part, ZeD.tr("UI_ZeD_Radio_ChCleared", string.format("%02d", idx)), 1400)
    else
        l:get(idx - 1):setName(name)
    end
    pcall(function() dd:transmitPresets() end)
    return true
end

function O.mic(chr, part)
    if not part then return false end
    local dd = part:getDeviceData(); if not dd then return false end
    return run("MuteMicrophone", chr, part, not _get(dd, "getMicIsMuted", false))
end

function O.playStop(chr, part) stopScan(part); return run("TogglePlayMedia", chr, part) end

-- the CDs the character carries (and in the bags they wear) that this radio plays
function O.cds(chr, part)
    local dd = part and part:getDeviceData()
    local mt = dd and _get(dd, "getMediaType", -1) or -1
    local out = {}
    if mt < 0 or not chr then return out end
    local seen = {}
    local function scan(container, depth)
        local items = container and _get(container, "getItems", nil)
        if not items then return end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if _safe(function() return it:isRecordedMedia() and it:getMediaType() == mt end, false) and not seen[it] then
                seen[it] = true; out[#out + 1] = it
            end
            if depth < 2 and instanceof(it, "InventoryContainer") then scan(_get(it, "getInventory", nil), depth + 1) end
        end
    end
    scan(chr:getInventory(), 0)
    return out
end

-- a CD in / out: vanilla's action through the queue (it takes a moment, like vanilla)
local function mediaAction(chr, part, isRemove, item)
    if not (chr and part) then return false end
    if not (ISDeviceMediaAction and ISDeviceBatteryAction) then return false end
    local param = _safe(function() return ISDeviceBatteryAction:getDeviceDataParameter(chr, part, "VehiclePart") end, nil)
    local a = ISDeviceMediaAction:new(chr, isRemove, item, param)
    if not a.deviceData then a.deviceData = part:getDeviceData() end   -- the square under the car may not answer for its radio
    ISTimedActionQueue.add(a)
    return true
end
function O.insert(chr, part, item)
    stopScan(part)
    if not item then return false end
    pcall(ISInventoryPaneContextMenu.transferIfNeeded, chr, item)
    return mediaAction(chr, part, false, item)
end
function O.eject(chr, part)
    if not part then return false end
    local dd = part:getDeviceData()
    if not (dd and _get(dd, "hasMedia", false)) then return false end
    return mediaAction(chr, part, true, nil)
end

-- ---------------------------------------------------------------------------
-- THE DISPLAYS — each kind's glass, drawn live over the baked face.
-- (x, y, w, h) is the glass in the panel's px; u = px per design unit;
-- full = the radio up close (else the dash's small face).
-- ---------------------------------------------------------------------------
local COL = {
    vfd = { 0.384, 0.902, 1.0 }, amber = { 1.0, 0.698, 0.180 }, char = { 0.122, 0.165, 0.047 },
    lcd = { 0.086, 0.098, 0.059 }, led = { 1.0, 0.227, 0.141 },
}
local GLOWS = { vfd = true, amber = true, led = true }
O.DISPLAY_KIND = { premium = "vfd", valutech = "amber", makeshift = "char", ham = "lcd", army = "led", hammake = "char" }

local function fonts()
    local F = ZeD.Font and ZeD.Font.sdf
    return F and F.sec, F and F.stat
end

-- text with its em `px` tall and its top at y; sp = extra px between characters
-- (mono faces); glow = the soft halo of a lit tube. Returns the drawn width.
local function dtext(p, f, str, x, y, px, c, a, align, sp, glow)
    local X = ZeD.Text
    if not (X and f) or str == nil or str == "" then return 0 end
    str = tostring(str)
    local z = X.zoomFor(f, px)
    local yy = y - (X.height(f, z) - px) / 2
    local uf = X.uifont(f)
    sp = sp or 0
    local cw = X.width(f, "0", z)
    local n = #str
    local w = (sp == 0) and X.width(f, str, z) or (n * cw + (n - 1) * sp)
    if align == "r" then x = x - w elseif align == "c" then x = x - w / 2 end
    local function put(dx, dy, alpha)
        if sp == 0 then
            p:drawTextZoomed(str, math.floor(x + dx), math.floor(yy + dy), z, c[1], c[2], c[3], alpha, uf)
        else
            for i = 1, n do
                local ch = str:sub(i, i)
                if ch ~= " " then p:drawTextZoomed(ch, math.floor(x + (i - 1) * (cw + sp) + dx), math.floor(yy + dy), z, c[1], c[2], c[3], alpha, uf) end
            end
        end
    end
    if glow then
        local g = math.max(1, math.floor(px / 14 + 0.5))
        put(-g, 0, a * 0.22); put(g, 0, a * 0.22); put(0, -g, a * 0.22); put(0, g, a * 0.22)
    end
    put(0, 0, a)
    return w
end
O.dtext = dtext

-- how many mono characters of em px (and spacing sp) fit in w px
local function charsFit(f, px, sp, w)
    local X = ZeD.Text
    local cw = X.width(f, "0", X.zoomFor(f, px))
    return math.max(1, math.floor((w + sp) / (cw + sp)))
end

-- a line that marches left a character at a time when it is too long (1993 LCDs did)
local function marquee(str, n)
    str = tostring(str or "")
    if #str <= n then return str end
    local loop = str .. "   "
    local k = clockStep(now(), 320, #loop)
    local s = (loop .. loop):sub(k + 1, k + n)
    return s
end
O.marquee = marquee

local function blinkOn(period) return clockStep(now(), period or 500, 2) == 0 end

local function triangle(p, x, y, size, c, a)
    for i = 0, size - 1 do
        local hh = math.floor((size - i) * 0.6)
        p:drawRect(math.floor(x + i), math.floor(y + size * 0.6 - hh), 1, math.max(1, hh * 2), a, c[1], c[2], c[3])
    end
end

local function bars(p, x, yBottom, u, lit, c)
    for i = 1, 5 do
        local bh = (4 + i * 3) * u
        p:drawRect(math.floor(x + (i - 1) * 6 * u), math.floor(yBottom - bh), math.max(1, math.floor(4 * u)), math.floor(bh), i <= lit and 1 or 0.16, c[1], c[2], c[3])
    end
end

local function elapsed(ms)
    local s = math.floor((ms or 0) / 1000)
    return string.format("%d:%02d", math.floor(s / 60) % 100, s % 60)
end

-- FM sets: premium (VFD), valutech (amber), makeshift (16 x 2 characters)
local function drawFM(p, kind, x, y, w, h, u, st, full)
    local B = fonts()
    local dk = O.DISPLAY_KIND[kind]
    local c = COL[dk]
    local glow = GLOWS[dk]
    local function T(str, ux, uy, upx, align, usp, f) return dtext(p, f or B, str, x + ux * u, y + uy * u, upx * u, c, 1, align, (usp or 0) * u, glow) end
    local freq = O.freqText(st.channel, false)
    local cd = kind == "premium" and st.playing
    if dk == "char" then
        local px = full and 12 or math.min(9, (h / u - 6) / 2)
        local sp = full and 1 or 0.5
        local n = charsFit(B, px * u, sp * u, w - 8 * u)
        local sig = st.signal and "||||" or ""
        local l1 = "FM" .. string.rep(" ", math.max(1, 6 - #freq)) .. freq .. "MHz"
        l1 = l1 .. string.rep(" ", math.max(1, n - #l1 - #sig)) .. sig
        local l2 = st.flash or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or (st.name and ZeD.upper(st.name)) or ""
        local top = full and 5 or 3
        T(l1:sub(1, n), 4, top, px, "l", sp)
        T(marquee(l2, n), 4, top + px + (full and 3 or 2), px, "l", sp)
        return
    end
    if kind == "valutech" then
        if full then
            if not (st.flash and not blinkOn(250)) then T(freq, 120, 4, 24, "r", 1) end
            T("FM", 142, 8, 9, "r")
            local tag = st.flash and st.flashShort or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or (st.presetIdx and st.presetIdx <= 6 and ("P" .. st.presetIdx)) or nil
            if tag and (not st.flash or blinkOn(250)) then T(tag, 8, 8, 9, "l") end
        else
            local big = math.min(16, math.floor(h / u * 0.62))
            T(freq, w / u - 30, (h / u - big) / 2, big, "r", 1)
            T("FM", w / u - 6, (h / u - 7) / 2, 7, "r")
            local tag = st.flash and st.flashShort or (st.muted and O.word("mute")) or (st.presetIdx and st.presetIdx <= 6 and ("P" .. st.presetIdx)) or nil
            if tag then T(tag, 6, (h / u - 7) / 2, 7, "l") end
        end
        return
    end
    -- premium
    if full then
        local tag2 = st.flash or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or nil
        if cd then
            T("CD", 10, 8, 9, "l", 1)
            triangle(p, x + 36 * u, y + 9 * u, math.floor(16 * u), c, 1)
            T(elapsed(st.cdMs), 140, 6, 28, "r", 2)
            T(marquee(ZeD.upper(st.mediaTitle or O.word("disc")), charsFit(B, 11 * u, 2 * u, 270 * u)), 10, 38, 11, "l", 2)
        else
            T("FM", 10, 8, 9, "l", 1)
            T(freq, 140, 6, 28, "r", 2)
            T("MHz", 148, 18, 9, "l", 1)
            if st.presetIdx and st.presetIdx <= 6 then T("P" .. st.presetIdx, 148, 8, 9, "l", 1) end
            if st.hasMedia then T("CD", 222, 8, 9, "r", 1) end
            bars(p, x + 252 * u, y + 28 * u, u, st.signal and 4 or 0, c)
            local nm = ZeD.upper(st.name or "")
            T(marquee(nm, charsFit(B, 11 * u, 2 * u, 270 * u)), 10, 38, 11, "l", 2)
        end
        if tag2 and (not (st.flash or st.scanning) or blinkOn(300)) then T(tag2, 222, 20, 9, "r", 1) end
    else
        local hU = h / u
        local two = hU >= 26
        local big = two and math.min(15, math.floor(hU * 0.5)) or math.min(14, math.floor(hU * 0.66))
        local top = two and 3 or (hU - big) / 2
        if cd then
            T("CD", 5, top + 1, 7, "l")
            T(elapsed(st.cdMs), 92, top, big, "r", 1)
        else
            T("FM", 5, top + 1, 7, "l")
            T(freq, 92, top, big, "r", 1)
            T("MHz", 95, top + big - 7, 6, "l")
        end
        local tag = st.flash and st.flashShort or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or nil
        if tag then T(tag, w / u - 5, top + 1, 7, "r")
        elseif not cd then bars(p, x + (w / u - 34) * u, y + (top + big) * u, u * 0.62, st.signal and 4 or 0, c) end
        if two then
            local line = cd and (st.mediaTitle or O.word("disc")) or (st.name or "")
            T(marquee(ZeD.upper(line), charsFit(B, 7 * u, 1 * u, w - 10 * u)), 5, hU - 10, 7, "l", 1)
        end
    end
end

-- two-way sets: ham (grey LCD), army (red LEDs), hammake (16 x 2 characters)
local function drawHam(p, kind, x, y, w, h, u, st, full)
    local B = fonts()
    local dk = O.DISPLAY_KIND[kind]
    local c = COL[dk]
    local glow = GLOWS[dk]
    local function T(str, ux, uy, upx, align, usp, f) return dtext(p, f or B, str, x + ux * u, y + uy * u, upx * u, c, 1, align, (usp or 0) * u, glow) end
    local freq = O.freqText(st.channel, true)
    local ch = st.presetIdx and string.format("%02d", st.presetIdx) or "--"
    local tx = st.micMuted and O.word("micOff") or O.word("txOk")
    local nameLine = st.flash or (st.muted and O.word("mute")) or (st.name and ZeD.upper(st.name)) or (st.presetIdx and st.presets[st.presetIdx] and ZeD.upper(st.presets[st.presetIdx].name)) or ""
    if dk == "char" then
        local px = full and 13 or math.min(9, (h / u - 6) / 2)
        local sp = full and 1.5 or 0.5
        local n = charsFit(B, px * u, sp * u, w - 8 * u)
        local top = full and 4 or 3
        T(("CH" .. ch .. " " .. freq .. " MHz"):sub(1, n), 4, top, px, "l", sp)
        T(marquee(nameLine, n), 4, top + px + (full and 3 or 2), px, "l", sp)
        return
    end
    if full and kind == "ham" then
        T("CH", 8, 6, 9, "l")
        T(ch, 8, 18, 16, "l")
        T(freq, 46, 5, 30, "l", 1)
        T("MHz", 242, 8, 9, "r")
        T(tx, 242, 22, 9, "r")
        T(marquee(nameLine, charsFit(B, 10 * u, 1 * u, 234 * u)), 8, 48, 10, "l", 1)
    elseif full then   -- army
        T("CH", 8, 5, 8, "l")
        T(ch, 8, 15, 16, "l")
        T(freq, 52, 4, 26, "l", 1)
        T("MHz", 242, 6, 8, "r")
        T(tx, 242, 17, 8, "r")
        T(marquee(nameLine, charsFit(B, 9 * u, 1 * u, 234 * u)), 8, 33, 9, "l", 1)
    else
        local hU = h / u
        local two = hU >= 26
        local big = two and math.min(14, math.floor(hU * 0.48)) or math.min(13, math.floor(hU * 0.62))
        local top = two and 3 or (hU - big) / 2
        T("CH" .. ch, 5, top + 1, 7, "l")
        T(freq, 112, top, big, "r", 0.5)
        T(st.micMuted and O.word("micOff") or "TX", w / u - 5, top + 1, 6, "r")
        if two then T(marquee(nameLine, charsFit(B, 7 * u, 1 * u, w - 10 * u)), 5, hU - 10, 7, "l", 1) end
    end
end

-- ---------------------------------------------------------------------------
-- THE READING for the radio up close (director, Oct 16 2026: the faces in pixel
-- art): what each face's display shows now, field by field, for the shared
-- plate template's radioDisplay part (ZeD_Plate.lua) to draw in pixel figures.
-- The same content as drawFM / drawHam below, blinking already applied; nil
-- when the set is off (the template darkens a liquid-crystal glass).
--   FM sets   band "FM" / "CD", big (the frequency, or the CD's time), unit,
--             preset "P2", cdTag "CD" (a disc in), tag (STORE n / SCAN /
--             MUTE), bars (signal 0 .. 4), line (the station, the CD's title)
--   ValuTech  big, band, tag
--   two-way   chLabel "CH", ch "02", big "146.520", unit, tx "TX OK" /
--             "MIC OFF", line (the channel's name, a flash, MUTE)
--   makeshift l1 / l2: the 16 x 2 character glass's two lines
-- ---------------------------------------------------------------------------
function O.displayReading(st, t)
    if not (st and st.on) then return nil end
    t = t or now()
    local function blink(period) return clockStep(t, period, 2) == 0 end
    local kind = st.kind
    if O.HAM[kind] then
        local freq = O.freqText(st.channel, true)
        local ch = st.presetIdx and string.format("%02d", st.presetIdx) or "--"
        local preset = st.presetIdx and st.presets and st.presets[st.presetIdx]
        local nameLine = st.flash or (st.muted and O.word("mute")) or (st.name and ZeD.upper(st.name))
            or (preset and preset.name and ZeD.upper(preset.name)) or ""
        if kind == "hammake" then
            return { l1 = "CH" .. ch .. " " .. freq .. " MHz", l2 = nameLine }
        end
        return { chLabel = "CH", ch = ch, big = freq, unit = "MHz", tx = st.micMuted and O.word("micOff") or O.word("txOk"), line = nameLine }
    end
    local freq = O.freqText(st.channel, false)
    if kind == "makeshift" then
        local sig = st.signal and "||||" or ""
        local l1 = "FM" .. string.rep(" ", math.max(1, 6 - #freq)) .. freq .. "MHz"
        l1 = l1 .. string.rep(" ", math.max(1, 17 - #l1 - #sig)) .. sig
        return { l1 = l1, l2 = st.flash or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or (st.name and ZeD.upper(st.name)) or "" }
    end
    if kind == "valutech" then
        local off = st.flash and not blink(250)                -- a STORE flash blinks the whole readout
        local tag = (st.flash and st.flashShort) or (st.scanning and O.word("scan")) or (st.muted and O.word("mute"))
            or (st.presetIdx and st.presetIdx <= 6 and ("P" .. st.presetIdx)) or ""
        return { big = off and "" or freq, band = "FM", tag = off and "" or tag }
    end
    -- the Premium Technologies CD receiver
    local cd = st.playing
    local tag = st.flash or (st.scanning and O.word("scan")) or (st.muted and O.word("mute")) or ""
    if (st.flash or st.scanning) and not blink(300) then tag = "" end    -- a flash and SCAN blink, MUTE holds
    if cd then
        return { band = "CD", cd = true, big = elapsed(st.cdMs), unit = "", preset = "", cdTag = "", tag = tag, bars = 0,
                 line = ZeD.upper(st.mediaTitle or O.word("disc")) }
    end
    return { band = "FM", big = freq, unit = "MHz", preset = (st.presetIdx and st.presetIdx <= 6) and ("P" .. st.presetIdx) or "",
             cdTag = st.hasMedia and "CD" or "", tag = tag, bars = st.signal and 4 or 0, line = ZeD.upper(st.name or "") }
end

-- the whole glass: unlit when off (an LCD's backlight out), else the kind's readout
function O.drawDisplay(p, kind, x, y, w, h, u, st, full)
    local dk = O.DISPLAY_KIND[kind] or "vfd"
    if not (st and st.on) then
        if dk == "char" or dk == "lcd" then p:drawRect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), 0.45, 0, 0, 0) end
        return
    end
    if O.HAM[kind] then drawHam(p, kind, x, y, w, h, u, st, full) else drawFM(p, kind, x, y, w, h, u, st, full) end
end

-- the handwritten names on the ValuTech's masking tape ("AEBS" -> "Aebs", like the mockup)
function O.tapeName(name)
    name = tostring(name or "")
    local head = name:match("^(.-)%s+%-%s+") or name
    local words = {}
    for wd in head:gmatch("%S+") do words[#words + 1] = wd end
    local s
    if #words >= 3 then
        s = ""
        for _, wd in ipairs(words) do s = s .. wd:sub(1, 1) end
    else
        s = words[1] or ""
    end
    s = s:gsub(" MHz$", "")
    return (ZeD.upper(s:sub(1, 1)) .. s:sub(2):lower()):sub(1, 9)
end

return O
