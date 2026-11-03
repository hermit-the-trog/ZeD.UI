-- ZeD-UI/42/media/lua/client/ZeD/PlainFace.lua
-- ============================================================================
-- THE PLAIN DEVICE CARD — the Simple form of the radio tab's faces (ZeD setup's
-- Devices row, Full or Simple: ZeD.Settings.devicesSimple). The rules the
-- director approved, Nov 2 2026 (ZeDUI/SIMPLE_VERSIONS_PROPOSAL.md):
--   1. it does everything its face does and shows everything it shows; only the
--      art goes
--   2. it is built from ZeD's own plain parts (labels and values, the segmented
--      bars, buttons, steppers, on/off switches) and matches ZeD's cards in every
--      theme and accent
--   3. one layout: a readout block across the top (the value that matters most
--      in large text), rows of label | value | control in the face's own order,
--      then the footer band
--   4. the controller walks it in the face's order: top to bottom, then the
--      footer; A presses, B backs out
--
-- ZeD.PlainFace.wrap(drv) wraps a face driver (ZeD.Rtv, RtvFace.lua: the
-- ordinary radios, the CD player, the TVs; ZeD.TwoWay, TwoWayFace.lua: the
-- walkies, the ManPack, the ham sets) in a driver with the same interface the
-- radio tab uses. Its drawFace draws the plain card and returns hits carrying
-- the face's own control ids; press, holdable, onRelease, holdTick, secondary
-- and turnMult forward to the real driver, so nothing about how a radio works
-- is copied here. What each card shows comes from the real face's plate: its
-- controls (PhysPx hits) in the face's order, each turned into a plain row.
--
-- The plain controls, and the face's control each one works:
--   power    switch   the power key (a walkie's VOL knob pressed, the antique
--                     set's pull knob: "vol" / "volpwr")
--   vol      stepper  VOL- / VOL+ keys, or the volume knob turned
--   tune     stepper  the tuning knob (the wheel and a held D-pad run faster)
--   channel  stepper  CH- / CH+ (a TV's channel, a two-way set's memory) or the
--                     antique set's channel dial
--   mute, mic, scan   switches;  p1..p6  the preset keys (held: store)
--   play, phones, battery, media (the slot / eject)   buttons on their rows
--   mem (held: name), lamp   the footer band's buttons
-- A stepper is one control: a click on its left half lowers, on its right half
-- raises; the wheel turns it; on the controller left / right turn it and up /
-- down move on (the card is a column).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_RadioOps"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"
require "ZeD/TwoWayFace"
require "ZeD/RtvFace"

ZeD = ZeD or {}
ZeD.PlainFace = ZeD.PlainFace or {}
local PF = ZeD.PlainFace
local O = ZeD.RadioOps
local PL = ZeD.Plate

PF.HALF_W = 220           -- the half card (units): every plain card but a TV's
PF.FULL_W = 480           -- the full card (units): a TV's, for what's on its screen
PF.TV_LINES = 5           -- the lines a TV's card keeps for its screen
PF.BIG_PX = 26            -- the readout's large text (design units)

local DASH = "--"

-- (hoisted: the helpers below call each other; Kahlua closures capture free names when they are made)
local controlsFor, ctlOf, ctxOf, layout

-- ---------------------------------------------------------------------------
-- WHAT THE ROWS READ: value(ctx) -> text, status colour, share (0..1, drawn as a fill bar)
-- ctx = { st (the driver's read), base, pid, dev, tw, tv, air, stop }
-- ---------------------------------------------------------------------------
local V = {}
function V.power(x)
    local st, T = x.st, ZeD.T
    if st.on then return ZeD.tr("UI_On"), T.positive end
    if not st.powered then return ZeD.tr("UI_ZeD_Plain_NoPower"), T.warning end   -- (no charge, no grid: the TV's lamp)
    return ZeD.tr("UI_Off"), nil
end
function V.volume(x) return ZeD.Atoms.pctText(x.st.volume or 0) end
local function freqOf(x)
    local hz = x.st.channel or 0
    if x.tw then return string.format("%.3f", hz / 1000) end
    return O.freqText(hz, false)
end
function V.freq(x)
    if not x.st.on then return DASH end
    return ZeD.tr("UI_ZeD_Plain_MHz", freqOf(x))
end
function V.channel(x)
    local st = x.st
    if not st.on then return DASH end
    if x.tv then
        local s = x.stop
        return s and string.format("%02d", s.number) or DASH
    end
    local i = st.presetIdx
    if not i then return DASH end
    local p = st.presets and st.presets[i]
    local nm = p and p.name ~= "" and p.name or nil
    if nm then return ZeD.tr("UI_ZeD_Plain_ChannelName", string.format("%02d", i), nm) end
    return string.format("%02d", i)
end
function V.signal(x)
    local st, T = x.st, ZeD.T
    if not st.on then return DASH end
    local n
    if x.tv then n = (ZeD.Rtv.SIGNAL and ZeD.Rtv.SIGNAL[x.air or "snow"]) or 0
    else n = st.signal and 3 or 0 end
    if n >= 3 then return ZeD.tr("UI_ZeD_Plain_SigGood"), T.positive end
    if n == 2 then return ZeD.tr("UI_ZeD_Plain_SigFair"), T.warning end
    if n == 1 then return ZeD.tr("UI_ZeD_Plain_SigPoor"), T.danger end
    return ZeD.tr("UI_ZeD_Plain_SigNone"), nil
end
function V.range(x)
    local m = x.st.range
    if not (m and m > 0) then return DASH end
    local km = m / 1000
    return ZeD.tr("UI_ZeD_Plain_Km", (km == math.floor(km)) and tostring(math.floor(km)) or string.format("%.1f", km))
end
function V.presets(x)
    local st = x.st
    local i = st.on and st.presetIdx
    if i and x.keyN and i <= x.keyN then return tostring(i) end
    return DASH
end
function V.battery(x)
    local st = x.st
    if x.tw then
        if st.ac then return ZeD.tr("UI_ZeD_Plain_AcPower") end
        return nil, nil, st.charge or 0
    end
    if not st.battery then return ZeD.tr("UI_ZeD_Plain_AcPower") end
    if not st.hasBattery then return ZeD.tr("UI_ZeD_Plain_NoBattery") end
    return nil, nil, st.charge or 0
end
function V.phones(x)
    return ZeD.tr(x.st.phones and "UI_ZeD_Plain_PhonesIn" or "UI_ZeD_Plain_PhonesOut")
end
function V.media(x)
    local st = x.st
    if not st.hasMedia then return ZeD.tr("UI_ZeD_Plain_Empty") end
    return st.mediaTitle or ZeD.tr(st.mediaType == 1 and "UI_ZeD_Plain_Tape" or "UI_ZeD_Plain_Disc")
end
function V.play(x)
    local st, T = x.st, ZeD.T
    if not st.hasMedia then return DASH end
    local word = ZeD.tr(st.playing and "UI_ZeD_Plain_Playing" or "UI_ZeD_Plain_Stopped")
    if x.tv and ZeD.Rtv.hms then word = ZeD.tr("UI_ZeD_Plain_PlayClock", word, ZeD.Rtv.hms(st.clockMs)) end
    return word, st.playing and T.positive or nil
end

-- the switches' state, the buttons' words
local ON = {
    power = function(x) return x.st.switchOn == true end,
    mute = function(x) return x.st.muted == true end,
    mic = function(x) return not x.st.micMuted end,
    scan = function(x) return x.st.scanning == true end,
}
local WORD = {
    play = function(x) return ZeD.tr(x.st.playing and "IGUI_media_stop" or "IGUI_media_play") end,
    phones = function(x) return ZeD.tr(x.st.phones and "UI_ZeD_Plain_Unplug" or "UI_ZeD_Plain_PlugIn") end,
    battery = function(x) return ZeD.tr(x.st.hasBattery and "UI_ZeD_Plain_Remove" or "UI_ZeD_Plain_Insert") end,
    media = function(x) return ZeD.tr(x.st.hasMedia and "UI_ZeD_RadioPrompt_Eject" or "UI_ZeD_Plain_Insert") end,
    mem = function() return ZeD.tr("UI_ZeD_RadioPrompt_StoreChannel") end,
    lamp = function() return ZeD.tr("UI_ZeD_RadioPrompt_Lamp") end,
}

-- ---------------------------------------------------------------------------
-- THE CONTROLS: one plain control per face control, in the face's order
--   { id, kind = "switch" | "stepper" | "button" | "keys" | "read", label (a key), real (the face's control it
--     presses), knob (the face's knob it turns), dn / up (the face's keys a step down / up presses), keys (the preset
--     keys' ids), foot (a footer band button), val, on, word }
-- ---------------------------------------------------------------------------
local C_VOL_KNOB = { id = "vol", kind = "stepper", label = "IGUI_RadioVolume", knob = "vol", val = V.volume }
local C_VOL_KEYS = { id = "vol", kind = "stepper", label = "IGUI_RadioVolume", dn = "voldn", up = "volup", val = V.volume }
local C_TUNE = { id = "tune", kind = "stepper", label = "IGUI_RadioFrequency", knob = "tune", val = V.freq }
local C_CH_KNOB = { id = "channel", kind = "stepper", label = "IGUI_RadioChannel", knob = "channel", val = V.channel }
local C_CH_KEYS = { id = "channel", kind = "stepper", label = "IGUI_RadioChannel", dn = "chdn", up = "chup", val = V.channel }
local C_SIGNAL = { id = "signal", kind = "read", label = "IGUI_RadioSignal", val = V.signal }
local C_RANGE = { id = "range", kind = "read", label = "IGUI_RadioStrength", val = V.range }
local C_BATT_READ = { id = "batt", kind = "read", label = "IGUI_VehiclePartBattery", val = V.battery }
local C_MUTE = { id = "mute", kind = "switch", label = "UI_ZeD_RadioPrompt_Mute", real = "mute", on = ON.mute }
local C_MIC = { id = "mic", kind = "switch", label = "IGUI_RadioMicrophone", real = "mic", on = ON.mic }
local C_SCAN = { id = "scan", kind = "switch", label = "UI_ZeD_RadioPrompt_Scan", real = "scan", on = ON.scan }
local C_PLAY = { id = "play", kind = "button", label = "UI_ZeD_Plain_Playback", real = "play", val = V.play, word = WORD.play }
local C_PHONES = { id = "phones", kind = "button", label = "UI_ZeD_Plain_Headphones", real = "phones", val = V.phones, word = WORD.phones }
local C_BATTERY = { id = "battery", kind = "button", label = "IGUI_VehiclePartBattery", real = "battery", val = V.battery, word = WORD.battery }
local C_MEM = { id = "mem", kind = "button", foot = true, real = "mem", word = WORD.mem }
local C_LAMP = { id = "lamp", kind = "button", foot = true, real = "lamp", word = WORD.lamp,
    sel = function(x) return O.lampLit(x.dev) == true end }

local function add(out, c)
    if out.byId[c.id] then return end
    out.list[#out.list + 1] = c
    out.byId[c.id] = c
end

local function powerCtl(real)
    return { id = "power", kind = "switch", label = "IGUI_RadioPower", real = real, on = ON.power, val = V.power }
end

-- the preset keys the face has, in number order
local function presetsCtl(have)
    local keys = {}
    for i = 1, 9 do if have["p" .. i] then keys[#keys + 1] = "p" .. i end end
    return { id = "presets", kind = "keys", label = "UI_ZeD_Plain_Presets", keys = keys, val = V.presets }
end

-- the disc or tape slot (the slot and the eject key do the same: in, else the list of those carried)
local function mediaCtl(real)
    return { id = "media", kind = "button", real = real, val = V.media, word = WORD.media,
             labelOf = function(x) return ZeD.tr(x.st.mediaType == 1 and "UI_ZeD_Plain_Tape" or "UI_ZeD_Plain_Disc") end }
end

-- one face control -> its plain row (a control the row already holds adds nothing)
local function place(out, id, isTw, tv, shared, have)
    if id == "power" or id == "volpwr" or (id == "vol" and (isTw or shared)) then
        if not out.byId.power then add(out, powerCtl((isTw and "vol") or (shared and "volpwr") or "power")) end
        if isTw or shared then add(out, C_VOL_KNOB) end
    elseif id == "vol" then add(out, C_VOL_KNOB)
    elseif id == "voldn" or id == "volup" then add(out, C_VOL_KEYS)
    elseif id == "tune" then
        add(out, C_TUNE)
        if not isTw then add(out, C_SIGNAL) end
    elseif id == "channel" then add(out, C_CH_KNOB); add(out, C_SIGNAL)
    elseif id == "chdn" or id == "chup" then
        add(out, C_CH_KEYS)
        if tv then add(out, C_SIGNAL) end
    elseif id == "mute" then add(out, C_MUTE)
    elseif id:match("^p%d$") then add(out, presetsCtl(have))
    elseif id == "mem" then add(out, C_MEM)
    elseif id == "mic" then add(out, C_MIC); add(out, C_RANGE)
    elseif id == "scan" then add(out, C_SCAN)
    elseif id == "lamp" then add(out, C_LAMP)
    elseif id == "slot" or id == "eject" then add(out, mediaCtl(id))
    elseif id == "play" then add(out, C_PLAY)
    elseif id == "phones" then add(out, C_PHONES)
    elseif id == "battery" then add(out, C_BATTERY) end
end

-- a face's plain controls (per plate id, kept): { list, byId, tw, tv, keyN }
local _ctl = {}
controlsFor = function(base, pid)
    local key = tostring(pid)
    local out = _ctl[key]
    if out then return out end
    out = { list = {}, byId = {} }
    local X = ZeD.PhysPx
    local des = X and X.plates and X.plates[pid]
    if not des then return out end
    local TW, R = ZeD.TwoWay, ZeD.Rtv
    local isTw = base == TW
    local tv = (not isTw) and R.isTv(pid) or false
    local shared = (not isTw) and R.factsOf(des).volPower or false
    local hits = PL.controls(des, {})
    local order = isTw and TW.readingOrder(hits, 1) or R.focusOrder(hits, 1)
    local have = {}
    for _, h in ipairs(hits) do have[h.id] = true end
    for _, h in ipairs(order) do place(out, h.id, isTw, tv, shared, have) end
    -- a two-way set's battery is read on its glass (BAT / AC), never pressed
    if isTw then add(out, C_BATT_READ) end
    out.tw, out.tv = isTw, tv
    out.keyN = out.byId.presets and #out.byId.presets.keys or 0
    _ctl[key] = out
    return out
end
PF.controlsFor = function(base, pid) return controlsFor(base, pid) end

-- the plain control behind an id for this radio (the preset keys are their own: p1..p9)
ctlOf = function(base, dev, id)
    if not (dev and id) then return nil end
    local pid = base.plateId and base.plateId(dev) or nil
    if not pid then return nil end
    local C = controlsFor(base, pid)
    local c = C.byId[id]
    if c then return c end
    if id:match("^p%d$") and C.byId.presets then return { id = id, kind = "button", real = id } end
    return nil
end

-- this frame's reading of a radio
ctxOf = function(base, dev, pid)
    local st = base.read(dev)
    if not st then return nil end
    local C = controlsFor(base, pid)
    local x = { st = st, base = base, pid = pid, dev = dev, tw = C.tw, tv = C.tv, C = C, keyN = C.keyN }
    if C.tv then x.air, x.stop = ZeD.Rtv.air(st) end
    return x
end

-- ---------------------------------------------------------------------------
-- THE READOUT: a small label, the value in large text, a line under it
-- ---------------------------------------------------------------------------
local function tvWord(x)
    local st = x.st
    if not st.on then return ZeD.tr("UI_ZeD_Plain_TvDark") end
    local a = x.air
    if a == "snow" then return ZeD.tr("UI_ZeD_Plain_TvSnow") end
    if a == "bars" then return ZeD.tr("UI_ZeD_Plain_TvBars") end
    if a == "signoff" then return ZeD.tr("UI_ZeD_Plain_TvSignOff") end
    if a == "standby" then return ZeD.tr("UI_ZeD_Plain_TvStandby") end
    return nil
end

-- label, big, unit, line, live (false: the big value drawn dim), progress (0..1: a fill bar under the line; nil: none)
local function readoutOf(x)
    local st, R = x.st, ZeD.Rtv
    local on = st.on
    if x.tv then
        if on and st.playing then
            return ZeD.tr("UI_ZeD_Plain_Tape"), R.hms(st.clockMs), nil, st.mediaTitle or "", true
        end
        local s = x.stop
        return ZeD.tr("IGUI_RadioChannel"), (on and s) and string.format("%02d", s.number) or DASH, nil,
            on and (st.name or tvWord(x) or "") or ZeD.tr("UI_Off"), on
    end
    if not on then
        local lbl = (not x.tw and R.info(x.pid) and R.info(x.pid).layout == "disc") and ZeD.tr("UI_ZeD_Plain_TrackN", DASH)
            or ZeD.tr("IGUI_RadioFrequency")
        return lbl, DASH, nil, (V.power(x)), false
    end
    if not x.tw and R.info(x.pid) and R.info(x.pid).layout == "disc" then
        local line = st.hasMedia and (st.mediaTitle or ZeD.tr("UI_ZeD_Plain_Disc")) or ZeD.tr("UI_ZeD_Plain_NoDisc")
        return ZeD.tr("UI_ZeD_Plain_TrackN", st.hasMedia and "01" or DASH), st.hasMedia and R.elapsed(st.clockMs) or "-:--", nil,
            st.flash or line, true
    end
    if not x.tw and st.playing then
        -- (the red radio's glass draws how far through the disc it is: its progress line)
        local prog = nil
        if R.info(x.pid) and R.info(x.pid).layout == "port" then
            prog = (st.mediaLines and st.mediaLines > 0) and math.max(0, math.min(1, (st.clockLines or 0) / st.mediaLines)) or 0
        end
        return ZeD.tr("UI_ZeD_Plain_Time"), R.elapsed(st.clockMs), nil, st.flash or st.mediaTitle or "", true, prog
    end
    local preset = st.presetIdx and st.presets and st.presets[st.presetIdx]
    local pname = preset and preset.name ~= "" and preset.name or nil
    return ZeD.tr("IGUI_RadioFrequency"), freqOf(x), ZeD.tr("UI_ZeD_Plain_MHzUnit"),
        st.flash or st.name or pname or ZeD.tr("UI_ZeD_Radio_UnknownFreq"), true
end

local function bigText(panel, text, x, y, c)
    local OC = ZeD.ObjectCards
    if OC and OC.ui and OC.ui.big then return OC.ui.big(panel, text, x, y, PF.BIG_PX, c) or 0 end
    panel:drawText(text, x, y, c.r, c.g, c.b, c.a or 1, ZeD.T.fontF4)
    return ZeD.TM:MeasureStringX(ZeD.T.fontF4, text)
end

local function readout(panel, x0, y, w, x, draw)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local pad = T.px(10)
    local f1, f2 = T.fontF1, T.fontF2
    local y0 = y
    y = y + T.px(8)
    local label, big, unit, line, live, prog = readoutOf(x)
    local h1, h2, hb = tm:getFontHeight(f1), tm:getFontHeight(f2), T.px(PF.BIG_PX)
    if draw then
        local ac, tc, dc = T.accent, T.text, T.textDim
        panel:drawText(A.textCase(label), x0 + pad, y, ac.r, ac.g, ac.b, 1, f1)
        local bw = bigText(panel, big, x0 + pad, y + h1 + T.px(2), live and tc or dc)
        if unit then
            panel:drawText(unit, x0 + pad + bw + T.px(6), y + h1 + T.px(2) + hb - h1, dc.r, dc.g, dc.b, dc.a or 1, f1)
        end
        local s = A.truncateText(line or "", f2, w - 2 * pad)
        panel:drawText(s, x0 + pad, y + h1 + T.px(2) + hb + T.px(4), tc.r, tc.g, tc.b, tc.a or 1, f2)
        if prog then A.drawFillBar(panel, x0 + pad, y + h1 + T.px(2) + hb + T.px(4) + h2 + T.px(4), w - 2 * pad, prog, false, nil, T.fillBarH) end
    end
    y = y + h1 + T.px(2) + hb + T.px(4) + h2 + T.px(8)
    if prog then y = y + T.fillBarH + T.px(4) end
    return y - y0
end

-- a TV's screen: what it has shown (the newest at the foot), else what the screen is showing in place of a picture
local _wrapC = {}
local function tvLines(x, w)
    local st = x.st
    if not (st.on and (st.playing or x.air == "picture")) then return nil end
    local lines = ZeD.Rtv.heardLines and ZeD.Rtv.heardLines(st)
    if not (lines and #lines > 0) then return nil end
    local c = _wrapC[st.key]
    local last = lines[#lines]
    if not (c and c.w == w and c.n == #lines and c.last == last) then
        local out = {}
        for _, l in ipairs(lines) do
            for _, s in ipairs(ZeD.Atoms.wrapText(l, ZeD.T.fontF2, w)) do out[#out + 1] = s end
        end
        c = { w = w, n = #lines, last = last, out = out }
        _wrapC[st.key] = c
    end
    return c.out
end

local function tvScreen(panel, x0, y, w, x, draw)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local pad = T.px(10)
    local f1, f2 = T.fontF1, T.fontF2
    local lh = tm:getFontHeight(f2)
    local h = tm:getFontHeight(f1) + T.px(4) + PF.TV_LINES * lh + T.px(8)
    if not draw then return h end
    local ac, tc, dc = T.accent, T.text, T.textDim
    panel:drawText(A.textCase(ZeD.tr("UI_ZeD_Plain_OnScreen")), x0 + pad, y, ac.r, ac.g, ac.b, 1, f1)
    local ty = y + tm:getFontHeight(f1) + T.px(4)
    local lines = tvLines(x, w - 2 * pad)
    if lines then
        local first = math.max(1, #lines - PF.TV_LINES + 1)
        local ly = ty + (PF.TV_LINES - (#lines - first + 1)) * lh
        for i = first, #lines do
            panel:drawText(lines[i], x0 + pad, ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
            ly = ly + lh
        end
    else
        local word = tvWord(x)
        if word then panel:drawText(A.truncateText(word, f2, w - 2 * pad), x0 + pad, ty, dc.r, dc.g, dc.b, dc.a or 1, f2) end
    end
    return h
end

-- ---------------------------------------------------------------------------
-- THE CONTROLS' PARTS (the library's push buttons; a switch is Off and On side by side, the current one selected;
-- a stepper is - and + side by side; the preset keys numbered)
-- ---------------------------------------------------------------------------
local _sel = { fill = { r = 0, g = 0, b = 0, a = 0 } }
local _onFocus = { fill = nil, text = nil }
local _bo = {}
local function selColors(onFocus)
    local T = ZeD.T
    local ac = T.accent
    local f = _sel.fill
    f.r, f.g, f.b, f.a = ac.r, ac.g, ac.b, T.selectionA
    _sel.text = onFocus and T.textOnFocus or nil
    return _sel
end
local function focusColors()
    _onFocus.text = ZeD.T.textOnFocus
    return _onFocus
end

local function segW()
    local T, tm = ZeD.T, ZeD.TM
    local f = T.fontF3
    local a = tm:MeasureStringX(f, ZeD.btnCase(ZeD.tr("UI_Off")))
    local b = tm:MeasureStringX(f, ZeD.btnCase(ZeD.tr("UI_On")))
    return math.max(a, b, T.px(14)) + 2 * T.px(8)
end
local function keyW() return ZeD.T.buttonH + ZeD.T.px(2) end
local function gapW() return ZeD.T.px(4) end

-- a control's width
local function ctlW(c, x)
    if c.kind == "switch" then return 2 * segW() + ZeD.T.px(2) end
    if c.kind == "stepper" then return 2 * keyW() + gapW() end
    if c.kind == "keys" then local n = #c.keys; return n * keyW() + (n - 1) * gapW() end
    if c.kind == "button" then return ZeD.Molecules.buttonW(c.word(x)) end
    return 0
end

-- one push button; state = { hover, focus (opts), pressed, selected, disabled }
local function key(panel, bx, by, bw, bh, text, hover, focusOpts, pressed, selected)
    local o = _bo
    o.hover, o.focus, o.disabled, o.help, o.win = hover, focusOpts, nil, nil, nil
    ZeD.Molecules.drawButton(panel, bx, by, bw, bh, text, "default", pressed, selected and selColors(false) or nil, o)
end

-- the controller's mark over a control made of parts; true when the parts' words take the focus ink
local function markAll(panel, cx, cy, cw, ch, focusOpts)
    if not focusOpts then return false end
    return ZeD.Focus.mark(panel, cx, cy, cw, ch, focusOpts) == true
end

local function drawSwitch(panel, cx, cy, ch, c, x, face, fo)
    local T = ZeD.T
    local sw = segW()
    local on = c.on(x)
    local hov = face.hoverId == c.id
    local ink = markAll(panel, cx, cy, 2 * sw + T.px(2), ch, fo)
    for i = 1, 2 do
        local isOn = i == 2
        local sel = on == isOn
        local colors = sel and selColors(ink) or (ink and focusColors() or nil)
        local o = _bo
        o.hover, o.focus, o.disabled, o.help, o.win = hov and not sel, nil, nil, nil, nil
        ZeD.Molecules.drawButton(panel, cx + (i - 1) * (sw + T.px(2)), cy, sw, ch, ZeD.tr(isOn and "UI_On" or "UI_Off"), "default",
            face.pressId == c.id and sel, colors, o)
    end
end

local function drawStepper(panel, panelMx, cx, cy, ch, c, face, fo)
    local kw, gap = keyW(), gapW()
    local hov = face.hoverId == c.id
    local ink = markAll(panel, cx, cy, 2 * kw + gap, ch, fo)
    local colors = ink and focusColors() or nil
    local leftHalf = panelMx < cx + kw + math.floor(gap / 2)
    local o = _bo
    o.focus, o.disabled, o.help, o.win = nil, nil, nil, nil
    o.hover = hov and leftHalf
    ZeD.Molecules.drawButton(panel, cx, cy, kw, ch, "-", "default", false, colors, o)
    o.hover = hov and not leftHalf
    ZeD.Molecules.drawButton(panel, cx + kw + gap, cy, kw, ch, "+", "default", false, colors, o)
end

-- ---------------------------------------------------------------------------
-- A ROW: label | value | control (the control on a line of its own when the three do not fit)
-- ---------------------------------------------------------------------------
local function rowH() local T = ZeD.T; return math.max(T.px(24), T.buttonH + T.px(6)) end

local function valueW(text, share)
    local T = ZeD.T
    if share then return ZeD.Atoms.rowBarW() end
    if not text or text == "" then return 0 end
    return ZeD.TM:MeasureStringX(T.fontF2, text) + T.px(10)
end

local function drawValue(panel, vx, vy, vw, lh, text, dot, share, label)
    local T, A = ZeD.T, ZeD.Atoms
    if share then
        local bh = T.fillBarH
        A.drawFillBar(panel, vx + vw - A.rowBarW(), vy + math.floor((lh - bh) / 2), A.rowBarW(), share, true, nil, bh, label)
        return
    end
    if not text or text == "" or vw <= 0 then return end
    local f2 = T.fontF2
    local s = A.truncateText(text, f2, vw - (dot and T.px(10) or 0))
    local sw = ZeD.TM:MeasureStringX(f2, s)
    local ty = vy + math.floor((lh - ZeD.TM:getFontHeight(f2)) / 2)
    A.drawTextRight(panel, s, vx + vw, ty, f2, T.text)
    if dot then A.drawStatusDot(panel, vx + vw - sw - T.px(10), vy + math.floor((lh - T.px(6)) / 2), dot, T.px(6)) end
end

-- the control's parts and its hits (hit = one per focus stop: a switch, a stepper, a button, each preset key)
local function drawControl(panel, cx, cy, ch, c, x, face, hits, fo)
    local cw = ctlW(c, x)
    if c.kind == "switch" then
        drawSwitch(panel, cx, cy, ch, c, x, face, face.focusId == c.id and fo or nil)
        hits[#hits + 1] = { id = c.id, kind = "press", knob = false, x = cx, y = cy, w = cw, h = ch }
    elseif c.kind == "stepper" then
        drawStepper(panel, panel:getMouseX(), cx, cy, ch, c, face, face.focusId == c.id and fo or nil)
        hits[#hits + 1] = { id = c.id, kind = "turn", knob = true, stepper = true, x = cx, y = cy, w = cw, h = ch }
    elseif c.kind == "keys" then
        local kw, gap = keyW(), gapW()
        local cur = x.st.on and x.st.presetIdx or nil
        for i, kid in ipairs(c.keys) do
            local kx = cx + (i - 1) * (kw + gap)
            key(panel, kx, cy, kw, ch, tostring(tonumber(kid:sub(2)) or i), face.hoverId == kid,
                face.focusId == kid and fo or nil, face.pressId == kid, cur == i)
            hits[#hits + 1] = { id = kid, kind = "press", knob = false, x = kx, y = cy, w = kw, h = ch }
        end
    elseif c.kind == "button" then
        key(panel, cx, cy, cw, ch, c.word(x), face.hoverId == c.id, face.focusId == c.id and fo or nil,
            face.pressId == c.id, c.sel and c.sel(x) or false)
        hits[#hits + 1] = { id = c.id, kind = "press", knob = false, x = cx, y = cy, w = cw, h = ch }
    end
end

local function row(panel, x0, y, w, c, x, face, hits, draw, fo)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local pad, gap = T.px(10), T.px(8)
    local lh = rowH()
    local inner = w - 2 * pad
    local label = A.textCase(c.labelOf and c.labelOf(x) or ZeD.tr(c.label))
    local text, dot, share = nil, nil, nil
    if c.val then text, dot, share = c.val(x) end
    local cw = ctlW(c, x)
    local lw = tm:MeasureStringX(T.fontF1, label)
    local vw = valueW(text, share)
    local two = cw > 0 and (lw + gap + vw + gap + cw > inner)
    local h = two and (lh + lh) or lh
    if not draw then return h end
    local ac = T.accent
    local lx = x0 + pad
    panel:drawText(label, lx, y + math.floor((lh - tm:getFontHeight(T.fontF1)) / 2), ac.r, ac.g, ac.b, 1, T.fontF1)
    local right = x0 + w - pad
    local bh = T.buttonH
    if two then
        drawValue(panel, lx + lw + gap, y, right - (lx + lw + gap), lh, text, dot, share, label)
        drawControl(panel, right - cw, y + lh + math.floor((lh - bh) / 2), bh, c, x, face, hits, fo)
    else
        local vRight = (cw > 0) and (right - cw - gap) or right
        drawValue(panel, lx + lw + gap, y, vRight - (lx + lw + gap), lh, text, dot, share, label)
        if cw > 0 then drawControl(panel, right - cw, y + math.floor((lh - bh) / 2), bh, c, x, face, hits, fo) end
    end
    A.drawDividerH(panel, lx, y + h - T.line(T.borderW), inner)
    return h
end

-- ---------------------------------------------------------------------------
-- THE FOOTER BAND: the power's state at the left, the face's actions at the right (MEM, the light); more buttons
-- than one band holds go on bands of their own above it
-- ---------------------------------------------------------------------------
local _bandSpec = { buttons = {}, status = { text = "", color = nil } }
local _bandPool = {}
local function footButtons(x)
    local out = {}
    for _, c in ipairs(x.C.list) do if c.foot then out[#out + 1] = c end end
    return out
end

local function bandLines(foot, x, w)
    local T, M = ZeD.T, ZeD.Molecules
    local room = w - 2 * T.px(8)
    local lines, cur, used = {}, {}, 0
    for _, c in ipairs(foot) do
        local bw = M.buttonW(c.word(x))
        local need = (#cur > 0) and (used + T.px(8) + bw) or bw
        if #cur > 0 and need > room then
            lines[#lines + 1] = cur
            cur, used = {}, bw
        else
            used = need
        end
        cur[#cur + 1] = c
    end
    lines[#lines + 1] = cur
    return lines
end

local function band(panel, x0, y, w, x, face, hits, draw, fo)
    local M = ZeD.Molecules
    local foot = footButtons(x)
    local lines = bandLines(foot, x, w)
    local H = M.bandH()
    if not draw then return H * #lines end
    local spec = _bandSpec
    for li, line in ipairs(lines) do
        local btns = spec.buttons
        for i = #btns, 1, -1 do btns[i] = nil end
        for i, c in ipairs(line) do
            local b = _bandPool[i]
            if not b then b = {}; _bandPool[i] = b end
            b.label, b.id, b.variant = c.word(x), c.id, nil
            b.hover = face.hoverId == c.id
            b.focus = (face.focusId == c.id) and fo or nil
            b.pressed = face.pressId == c.id
            b.disabled, b.help, b.minW, b.w = nil, nil, nil, nil
            btns[i] = b
        end
        local last = li == #lines
        if last then
            local text, dot = V.power(x)
            spec.status.text, spec.status.color = text, dot or ZeD.T.textDim
        else
            spec.status.text, spec.status.color = "", nil
        end
        spec.noLine = li > 1
        spec.win = face.win
        local _, rects = M.drawBand(panel, x0, y, w, spec)
        for i, r in ipairs(rects.buttons or {}) do
            hits[#hits + 1] = { id = line[i].id, kind = "press", knob = false, x = r.x, y = r.y, w = r.w, h = r.h }
        end
        y = y + H
    end
    return H * #lines
end

-- ---------------------------------------------------------------------------
-- THE CARD: readout, (a TV's screen,) rows, band. draw = false measures it. Returns its height and the hits.
-- ---------------------------------------------------------------------------
local _fo = {}
layout = function(panel, x0, y0, w, x, face, draw)
    local T = ZeD.T
    local hits = {}
    local fo = nil
    if draw then _fo.win = face.win; fo = _fo end
    local y = y0
    y = y + readout(panel, x0, y, w, x, draw)
    if draw then ZeD.Atoms.drawDividerH(panel, x0, y, w, true) end
    y = y + T.line(T.borderW)
    if x.tv then y = y + T.px(8) + tvScreen(panel, x0, y + T.px(8), w, x, draw) end
    for _, c in ipairs(x.C.list) do
        if not c.foot then y = y + row(panel, x0, y, w, c, x, face, hits, draw, fo) end
    end
    local bh = band(panel, x0, y, w, x, face, hits, false, fo)
    local by = math.max(y + T.px(8), y0 + (face.minH or 0) - bh)
    if draw then band(panel, x0, by, w, x, face, hits, true, fo) end
    return by + bh - y0, hits
end

-- ---------------------------------------------------------------------------
-- THE DRIVER
-- ---------------------------------------------------------------------------
-- the card's size for the radio tab: { plain, w (screen px, the card it wants), h (measured as it draws) }
local _des = {}
function PF.des(base, pid)
    local key = tostring(pid)
    local d = _des[key]
    if not d then d = { plain = true, pid = pid, h = 0 }; _des[key] = d end
    local T = ZeD.T
    local tv = base == ZeD.Rtv and ZeD.Rtv.isTv(pid)
    d.w = T.px(tv and PF.FULL_W or PF.HALF_W)
    return d
end

-- the card's height at width w for a radio (screen px); minH: the room it fills (its band at the foot)
function PF.height(base, dev, pid, w)
    local x = ctxOf(base, dev, pid)
    if not x then return 0 end
    local h = layout(nil, 0, 0, w, x, { minH = 0 }, false)
    return h
end

-- the card at (x, y), w wide: returns this frame's hits (panel px) and the read state
--   face = { dev, pid, des, w, minH, focusId, hoverId, pressId, win }
function PF.draw(base, panel, x0, y0, face)
    local x = ctxOf(base, face.dev, face.pid)
    if not x then return {}, nil end
    local h, hits = layout(panel, x0, y0, face.w or face.des.w, x, face, true)
    face.des.h = h
    return hits, x.st
end

-- the press (a click, A); dx: where a stepper was clicked from its middle (< 0: its - half), nil from the controller
function PF.press(base, chr, dev, id, dx, at)
    local c = ctlOf(base, dev, id)
    if not c then return end
    if c.kind == "stepper" then
        if dx then PF.turn(base, chr, dev, id, dx < 0 and -1 or 1, 1) end
        return
    end
    if c.real then base.press(chr, dev, c.real, nil, at) end
end

-- a stepper turned one step (dir +1 / -1): the face's knob turned, or its key a step that way pressed
function PF.turn(base, chr, dev, id, dir, mult)
    local c = ctlOf(base, dev, id)
    if not (c and c.kind == "stepper") then return end
    if c.knob then base.turn(chr, dev, c.knob, dir, mult)
    else base.press(chr, dev, dir > 0 and c.up or c.dn) end
end

-- the second meaning (X, a hold, a right-click): the preset keys store, MEM names; a stepper steps down (as a knob)
function PF.secondary(base, chr, dev, id, owner)
    local c = ctlOf(base, dev, id)
    if not c then return end
    if c.kind == "stepper" then PF.turn(base, chr, dev, id, -1, 1); return end
    if c.real and base.holdable(c.real) then base.secondary(chr, dev, c.real, owner) end
end

-- the driver for a face driver (one per driver, kept: the radio tab compares them)
local _wraps = {}
function PF.wrap(base)
    if not base then return nil end
    local W = _wraps[base]
    if W then return W end
    W = { plain = true, base = base, PAD = 0, footer = nil }
    W.drawFace = function(panel, x, y, k, face) return PF.draw(base, panel, x, y, face) end
    W.height = function(dev, pid, w) return PF.height(base, dev, pid, w) end
    W.hitAt = ZeD.TwoWay.hitAt
    W.press = function(chr, dev, id, dx, at) PF.press(base, chr, dev, id, dx, at) end
    W.turn = function(chr, dev, id, dir, mult) PF.turn(base, chr, dev, id, dir, mult) end
    W.secondary = function(chr, dev, id, owner) PF.secondary(base, chr, dev, id, owner) end
    -- (the preset keys and MEM keep their ids, so the face's own rules answer for them)
    W.holdable = function(id) return base.holdable(id) end
    W.onRelease = function(id)
        if id == "media" or id == "battery" or id == "phones" then return true end   -- (a list may open: on the release)
        if base.onRelease then return base.onRelease(id) end
        return base.holdable(id)
    end
    W.holdTick = function(hold, chr, dev, owner) return base.holdTick(hold, chr, dev, owner) end
    W.turnMult = function(pid, streak) return base.turnMult(pid, streak) end
    W.focusOrder = function(hits) return hits end           -- (drawn in the order the controller walks them)
    W.readingOrder = W.focusOrder
    W.isBase = function(pid) return base.isBase and base.isBase(pid) or false end
    W.wantW = function(pid, des) return des.w end
    W.slotW = function(des) return des.w end
    _wraps[base] = W
    return W
end

return PF
