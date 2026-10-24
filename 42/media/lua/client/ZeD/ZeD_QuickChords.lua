-- ZeD-UI/42/media/lua/client/ZeD/ZeD_QuickChords.lua
-- ============================================================================
-- QUICK ACTIONS ON BUMPER CHORDS (director, Oct 24 2026: "settings for
-- gamepad chords for quick actions. Bumpers + A, B, X, Y, L3, R3 -- 12 quick
-- action assignments possible"; QUICK_CHORDS_SPEC.md; mockup
-- ZeDUI/mockups/zed_quick_chords_v1.html, approved Oct 24 2026)
--
-- In the world (no window has the pad, no wheel is open, not paused), hold LB
-- or RB and press A, B, X, Y, L3 or R3: the action assigned to that chord
-- runs. The button pressed with a bumper does only the chord: it never reaches
-- the game's prompts (JoypadControllerData:onPressButtonNoFocus) or the
-- windows' Y (FocusManager). A bumper on its own still does nothing in the
-- world; LB + RB stays the zoom (BumperChord).
--
-- An action is any slice of the four D-pad wheels (ZeD_DpadWheels), found
-- again by its path: the wheel, then each level's place or key, e.g.
-- "character:3" (Eat), "character:3:Base.CannedCorn" (Eat > Canned Corn),
-- "character:8:1" (Use > Smoke). A slice that opens a list of things you
-- carry (marked best in ZeD_DpadWheels: Weapons, Eat, Drink, Medicine, Smoke,
-- Read) does its best pick at once: its own pick, else the first one the list
-- offers that can be done (the wheels' order: food spoiling soonest first,
-- water first ...). A slice that opens a wheel of places (Tabs, Map, View),
-- or one the game fills (Vehicle, Animal, a gesture group), opens that wheel.
-- One that can't run now does nothing, and the character says why over their
-- head (the game's HaloTextHelper), with the wheel's reason.
--
-- The twelve are kept in Zomboid/Lua/ZeD_chords.txt: "LB+A=<path>|<words>",
-- the words being the wheel's crumb at the time (tab separated), for the
-- setup page at the main menu where no wheel can be built. "LB+A=" is a
-- chord cleared on purpose. A chord the file does not name has its default.
-- ============================================================================

require "ISUI/Gamepad/JoyPadSetup"
require "ZeD/Tr"
require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.QuickChords = ZeD.QuickChords or {}
local Q = ZeD.QuickChords

Q.BUMPERS = { "LB", "RB" }
Q.FACES = { "A", "B", "X", "Y", "L3", "R3" }
Q.CHORDS = {}
for _, b in ipairs(Q.BUMPERS) do for _, f in ipairs(Q.FACES) do Q.CHORDS[#Q.CHORDS + 1] = b .. "+" .. f end end

local WHEEL_OF = { character = "left", world = "right", social = "up", now = "down" }
local WHEEL_TITLE = { character = "UI_ZeD_Wheel_Character", world = "UI_ZeD_Wheel_World", social = "UI_ZeD_Wheel_Social", now = "UI_ZeD_Wheel_HereNow" }
Q.WHEELS = { "character", "world", "social", "now" }

local function word(key)
    if key:sub(1, 7) == "UI_ZeD_" then return ZeD.tr(key) end
    return getText(key)
end

-- the starting layout (the mockup's, approved Oct 24 2026), with the words as keys
Q.DEFAULTS = {
    ["LB+A"]  = { "character:3",   { "UI_ZeD_Wheel_Character", "ContextMenu_Eat" } },
    ["LB+B"]  = { "character:4",   { "UI_ZeD_Wheel_Character", "ContextMenu_Drink" } },
    ["LB+X"]  = { "now:8",         { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_Light" } },
    ["LB+Y"]  = { "character:8:1", { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Use", "ContextMenu_Smoke" } },
    ["LB+L3"] = { "now:1:1",       { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_Sit", "ContextMenu_SitGround" } },
    ["LB+R3"] = { "social:5",      { "UI_ZeD_Wheel_Social", "IGUI_Emote_Shout" } },
    ["RB+A"]  = { "character:5",   { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Medicine" } },
    ["RB+B"]  = { "character:2",   { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Weapons" } },
    ["RB+X"]  = { "character:8:2", { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Use", "ContextMenu_Read" } },
    ["RB+Y"]  = { "world:2:1",     { "UI_ZeD_Wheel_World", "UI_ZeD_Wheel_Map", "IGUI_WorldMap_Toggle" } },
    ["RB+L3"] = { "now:3",         { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_AutoWalk" } },
    ["RB+R3"] = { "now:2",         { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_Crouch" } },
}

-- ---------------------------------------------------------------------------
-- the twelve, kept in Zomboid/Lua/ZeD_chords.txt
-- ---------------------------------------------------------------------------
local FILE = "ZeD_chords.txt"
local store = nil   -- chord -> { path = string|nil, words = { ... } }  (nil path = cleared)

local function load()
    store = {}
    local r = getFileReader(FILE, false)
    if not r then return end
    local line = r:readLine()
    while line do
        local chord, rest = line:match("^([LR]B%+[ABXYLR3]+)=(.*)$")
        if chord then
            local path, words = rest:match("^([^|]*)|?(.*)$")
            local w = {}
            for s in (words or ""):gmatch("[^\t]+") do w[#w + 1] = s end
            store[chord] = { path = (path and path ~= "") and path or nil, words = w }
        end
        line = r:readLine()
    end
    r:close()
end

local function save()
    local w = getFileWriter(FILE, true, false)
    if not w then return end
    w:write("ZeD-UI quick action chords: chord=wheel path|the wheel's words (an empty path is a chord cleared on purpose)\n")
    for _, c in ipairs(Q.CHORDS) do
        local s = store[c]
        if s then w:write(c .. "=" .. (s.path or "") .. "|" .. table.concat(s.words or {}, "\t") .. "\n") end
    end
    w:close()
end

-- the chord's path (nil = nothing) and its words, for showing
function Q.get(chord)
    if not store then load() end
    local s = store[chord]
    if s then return s.path, s.words end
    local d = Q.DEFAULTS[chord]
    if not d then return nil, {} end
    local w = {}
    for i, k in ipairs(d[2]) do w[i] = word(k) end
    return d[1], w
end

function Q.set(chord, path, words)
    if not store then load() end
    local w = {}
    for i, s in ipairs(words or {}) do w[i] = tostring(s):gsub("[\t\r\n|]", " ") end
    store[chord] = { path = path, words = w }
    save()
end
function Q.clear(chord) Q.set(chord, nil, {}) end
-- the chord as it starts (no line of its own in the file)
function Q.isDefault(chord)
    if not store then load() end
    return store[chord] == nil
end
function Q.defaultName(chord)
    local d = Q.DEFAULTS[chord]
    return d and word(d[2][#d[2]]) or ZeD.tr("UI_ZeD_Chord_None")
end
function Q.reload() store = nil end   -- (the file is read again on the next look)
function Q.reset(chord)
    if not store then load() end
    store[chord] = nil
    save()
end

-- the first chord that runs this path (nil = none)
function Q.chordFor(path)
    if not path then return nil end
    for _, c in ipairs(Q.CHORDS) do if Q.get(c) == path then return c end end
    return nil
end

-- a slice's name without the wheel's count ("Canned Corn  x3")
function Q.cleanName(s) return (tostring(s or ""):gsub("%s+x%d+$", "")) end

-- ---------------------------------------------------------------------------
-- finding the action again, and doing it
-- ---------------------------------------------------------------------------
local function safe(fn, ...) local ok, v = pcall(fn, ...); if ok then return v end; return nil end

local function find(list, seg)
    for _, e in ipairs(list or {}) do if e.key ~= nil and tostring(e.key) == seg then return e end end
    local i = tonumber(seg)
    return i and list and list[i] or nil
end

-- the entry a path names, with the chain of entries above it; nil + why when it is gone
function Q.resolve(p, pn, path)
    local D = ZeD.DpadWheels
    if not (D and D.B and path) then return nil end
    local segs = {}
    for s in path:gmatch("[^:]+") do segs[#segs + 1] = s end
    local wheel = segs[1]
    if not (wheel and D.B[wheel]) then return nil end
    local list = safe(D.B[wheel], p, pn) or {}
    local chain, e = {}, nil
    for i = 2, #segs do
        if e then
            if e.off then return nil, e.off, chain end   -- (a list that can't open: its reason)
            if not e.sub then return nil, nil, chain end
            list = safe(e.sub, p, pn) or {}
        end
        e = find(list, segs[i])
        if not e then return nil, nil, chain end
        chain[#chain + 1] = e
    end
    return e, nil, chain, wheel
end

-- a list's best pick: its own pick, else the first slice that can be done (into a list inside, twice at most)
local function bestOf(e, p, pn, depth)
    if e.pick then
        local b = safe(e.pick, p, pn)
        if b then return b end
    end
    for _, x in ipairs(e.sub and (safe(e.sub, p, pn) or {}) or {}) do
        if not x.off then
            if x.run then return x end
            if x.sub and depth < 2 then local b = bestOf(x, p, pn, depth + 1); if b then return b end end
        end
    end
    return nil
end

local function say(p, text) if text and text ~= "" and HaloTextHelper then pcall(HaloTextHelper.addBadText, p, text) end end

-- a slice the game fills itself: that wheel, open, as the D-pad would show it
local function openFilled(p, pn, wheel, chain)
    local D = ZeD.DpadWheels
    if not (D and D.open and WHEEL_OF[wheel]) then return end
    D.open(WHEEL_OF[wheel], { player = pn })
    for _, e in ipairs(chain) do
        if D.state[pn] then D.enter(pn, e) end
    end
end

-- runs the chord; true when it did something
function Q.run(p, chord)
    local pn = p:getPlayerNum()
    local path, words = Q.get(chord)
    if not path then return false end
    local e, why, chain, wheel = Q.resolve(p, pn, path)
    if not e then
        say(p, why or ZeD.tr("UI_ZeD_Chord_Gone", words[#words] or "?"))
        return false
    end
    if e.off then say(p, e.off); return false end
    -- a wheel the game fills, or a wheel of places (Map, Tabs, View): that wheel, open
    if e.fill or (e.sub and not e.run and not (e.best or e.pick)) then openFilled(p, pn, wheel, chain); return true end
    local act = e
    if not e.run and (e.sub or e.pick) then
        act = bestOf(e, p, pn, 0)
        if not act then say(p, ZeD.tr("UI_ZeD_Wheel_NotNow")); return false end
    end
    if not act.run then return false end
    local ok, err = pcall(act.run, p, pn)
    if not ok then print("[ZeD] QuickChords: " .. chord .. " (" .. path .. "): " .. tostring(err)) end
    return ok
end

-- ---------------------------------------------------------------------------
-- the actions a chord can take, for the setup page's list: per wheel, each
-- slice that does something, a list slice as its best pick then the slices
-- in it (one level in; a list inside a list as its best pick), a wheel the
-- game fills as "opens its wheel"
-- ---------------------------------------------------------------------------
function Q.catalog(p, pn)
    local D = ZeD.DpadWheels
    local out = {}
    if not (D and D.B and p) then return out end
    local CH = " \226\128\186 "
    for _, wheel in ipairs(Q.WHEELS) do
        local title = ZeD.tr(WHEEL_TITLE[wheel])
        local acts = {}
        local function add(path, words, how)
            local w = {}
            for i = 2, #words do w[#w + 1] = words[i] end
            local text = table.concat(w, CH)
            if how then text = text .. ": " .. how end
            acts[#acts + 1] = { path = path, words = words, text = text }
        end
        local function how(e) return (e.best or e.pick) and ZeD.tr("UI_ZeD_Chord_BestPick") or ZeD.tr("UI_ZeD_Chord_OpensWheel") end
        for i, e in ipairs(safe(D.B[wheel], p, pn) or {}) do
            local name = Q.cleanName(e.name)
            local path = wheel .. ":" .. i
            if e.fill then add(path, { title, name }, ZeD.tr("UI_ZeD_Chord_OpensWheel"))
            elseif e.run then add(path, { title, name })
            elseif e.sub then
                add(path, { title, name }, how(e))
                -- the slices inside: where some carry a key (the things you carry, tabs, Hands free), only those,
                -- since the rest come and go (a wound's treatments); a fixed wheel (Map, Sit, Use) all of them
                local list = safe(e.sub, p, pn) or {}
                local keyed = false
                for _, x in ipairs(list) do if x.key ~= nil then keyed = true; break end end
                for j, x in ipairs(list) do
                    if x.key ~= nil or not keyed then
                        local xn = Q.cleanName(x.name)
                        local xp = path .. ":" .. tostring(x.key or j)
                        if x.fill then add(xp, { title, name, xn }, ZeD.tr("UI_ZeD_Chord_OpensWheel"))
                        elseif x.run then add(xp, { title, name, xn })
                        elseif x.sub then add(xp, { title, name, xn }, how(x)) end
                    end
                end
            end
        end
        out[#out + 1] = { id = wheel, title = title, actions = acts }
    end
    return out
end

-- ---------------------------------------------------------------------------
-- the pad: a bumper held and one of the six pressed, in the world
-- ---------------------------------------------------------------------------
local FACE_OF = {}
local consumed = {}   -- button -> true, until it is let go (its release is swallowed too)

local function bumperHeld(jid)
    if Q.qaBumper then return Q.qaBumper end   -- QA: a held bumper without a pad (zedqa_quick_chords.lua)
    local lb = JoypadButton.LeftBump:isDown(jid)
    local rb = JoypadButton.RightBump:isDown(jid)
    if lb and rb then return nil end   -- (both: the zoom's)
    return lb and "LB" or (rb and "RB") or nil
end

local function paused()
    local sc = UIManager.getSpeedControls()
    return sc ~= nil and sc:getCurrentGameSpeed() == 0
end

-- the press, before the game's prompts see it; true = it was a chord
function Q.onPress(joypadData, button)
    if ZeD.Safe.on() then return false end
    local face = FACE_OF[button]
    if not (face and joypadData and joypadData.player and joypadData.id) then return false end
    local bump = bumperHeld(joypadData.id)
    if not bump then return false end
    local p = getSpecificPlayer(joypadData.player)
    if not p or p:isDead() or paused() then return false end
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.getFocusedWindow and F.getFocusedWindow() then return false end
    consumed[button] = true
    local chord = bump .. "+" .. face
    local ok, err = pcall(Q.run, p, chord)
    if not ok then print("[ZeD] QuickChords: " .. chord .. ": " .. tostring(err)) end
    Q.lastChord = chord   -- (QA)
    return true
end

local function apply()
    if not JoypadControllerData or JoypadControllerData._zedChords then return end
    JoypadControllerData._zedChords = true
    FACE_OF = { [Joypad.AButton] = "A", [Joypad.BButton] = "B", [Joypad.XButton] = "X", [Joypad.YButton] = "Y",
                [Joypad.LStickButton] = "L3", [Joypad.RStickButton] = "R3" }
    local origPress = JoypadControllerData.onPressButtonNoFocus
    function JoypadControllerData:onPressButtonNoFocus(button)
        local ok, took = pcall(Q.onPress, self.joypad, button)
        if ok and took then return end
        return origPress(self, button)
    end
    local origRelease = JoypadControllerData.onReleaseButton
    function JoypadControllerData:onReleaseButton(button)
        if consumed[button] then
            consumed[button] = nil
            local jd = self.joypad
            if not (jd and jd.focus) then return end   -- (in the world: the release of a chord's button is the chord's too)
        end
        return origRelease(self, button)
    end
    print("[ZeD] QuickChords: a bumper held with A, B, X, Y, L3 or R3 runs a quick action")
end
Q._apply = apply

Events.OnGameBoot.Add(apply)
apply()
