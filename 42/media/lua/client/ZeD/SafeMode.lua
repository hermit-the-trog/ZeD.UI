-- ZeD-UI/42/media/lua/client/ZeD/SafeMode.lua
-- ============================================================================
-- SAFE MODE (Oct 19 2026, director: if ZeD ever fails to open, a bad day is a
-- setting flip rather than a hotfix; a player is never left with no inventory)
--
-- ZeD steps aside and the game's own interface comes back:
--   * while the "Safe mode" option is On (Options > Mods > ZeD UI), until it
--     is turned Off again;
--   * for the rest of the session once the watchdog trips: a ZeD window that
--     fails to open, or one place failing on frame after frame for two seconds
--     (at least 15 frames, never a break longer than a quarter second; the
--     same for failures spread over three places or more, as when a place's
--     name keeps changing). A burst of a few frames never trips it; a failure
--     every frame does, even below 30 fps. A note says so through the game's
--     own dialog, the error goes to console.txt, and the next launch says it
--     once more (Zomboid/Lua/ZeD_safe_trip.txt).
--
--   ZeD.Safe.on()              true while safe mode holds (the option, or a trip)
--   ZeD.Safe.fault(key, err)   a failure at key that happens every frame
--                              (ZeD.logOnce and ZeD.Safe.guard call it)
--   ZeD.Safe.trip(where, err)  step aside now, for this session
--   ZeD.Safe.reset()           take a trip back (QA; the option going Off does it too)
--   ZeD.Safe.reread()          read the option now rather than within half a second
--   ZeD.Safe.register(name, { enter = fn, leave = fn })
--       a piece of ZeD that parks something of vanilla's (hides its pages,
--       replaces its methods, moves its clock) says how to hand it back
--       (leave) and how to take it over again (enter). Both may run twice.
--   ZeD.Safe.guard(panel, fn, label)
--       runs a per-frame draw hook under pcall: on a failure the stencils it
--       set are cleared, the failure counts as a fault and is logged once
-- A piece that only wraps a vanilla function asks ZeD.Safe.on() when it is
-- called and needs no registration.
--
-- When the option's saved value is there (PZAPI/ModOptions.lua): options are
-- registered at file load with their defaults, and ModOptions:load() runs only
-- when vanilla builds its options screen, which MainScreen does in
-- OnMainMenuEnter (the main menu) and again in OnGameStart (the pause menu in
-- game). Vanilla's handlers run before any mod's, so ours re-read the option
-- right after. Before the main menu (file load, OnGameBoot) it reads Off.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Safe = ZeD.Safe or {}
local S = ZeD.Safe

-- vanilla functions a hook replaced, kept so it can hand them back (the belt: ISHotbar)
S._originals = S._originals or {}

local READ_MS   = 500    -- the option is read at most this often
local FRAME_MS  = 10     -- faults at one place closer together than this are one frame
local STREAK_MS = 2000   -- a place failing this long without a break trips the watchdog
local GAP_MS    = 250    -- a pause longer than this breaks a streak
local MIN_HITS  = 15     -- frames a streak must have failed on as well
local ALL_PLACES = 3     -- places the overall streak must take in
local MAX_KEYS  = 200    -- places counted on their own (past that, only the overall streak counts)
local TRIP_FILE = "ZeD_safe_trip.txt"

-- kept on the module so a reload of this file keeps the hooks and a trip
local st = S._state or { option = false, tripped = false, applied = false, nextRead = 0, noted = false }
S._state = st
local hooks = S._hooks or {}
local order = S._order or {}
S._hooks, S._order = hooks, order

-- the watchdog's streaks: one per place, and one overall (forward-declared so
-- reset and the game start can clear them)
local streaks, nKeys, allStreak
local function clearStreaks()
    streaks, nKeys = {}, 0
    allStreak = { start = 0, hits = 0, places = {}, n = 0 }
end
clearStreaks()
local traced, nTraced = {}, 0

-- ----------------------------------------------------------------------------
-- The option
-- ----------------------------------------------------------------------------
local function readOption()
    local o = ZeD.Settings and ZeD.Settings.safeModeOption
    if not o then return false end
    local ok, v = pcall(o.getValue, o)
    return ok and v == 2
end

function S.on()
    local now = getTimestampMs()
    if now >= st.nextRead then
        st.nextRead = now + READ_MS
        local v = readOption()
        if st.option and not v then st.tripped = false end   -- the option turned Off: a trip goes with it
        st.option = v
    end
    return st.tripped or st.option
end

-- ----------------------------------------------------------------------------
-- The hooks: leave on the way into safe mode, enter on the way out
-- ----------------------------------------------------------------------------
local function runHook(name, fn, what)
    local ok, err = pcall(fn)
    if not ok then print("[ZeD] Safe mode: " .. tostring(name) .. " could not " .. what .. ": " .. tostring(err)) end
end

local function sync()
    local want = S.on()
    if want == st.applied then return end
    st.applied = want
    for i = 1, #order do
        local name = order[i]
        local h = hooks[name]
        if h then
            if want then
                if h.leave then runHook(name, h.leave, "hand back") end
            elseif h.enter then
                runHook(name, h.enter, "take over again")
            end
        end
    end
    print(want and "[ZeD] Safe mode: on, the game's own interface is back" or "[ZeD] Safe mode: off, ZeD UI is back")
end

function S.register(name, def)
    if type(name) ~= "string" or type(def) ~= "table" then return end
    if not hooks[name] then order[#order + 1] = name end
    hooks[name] = def
    -- registered while safe mode already holds: it hands back at once
    if st.applied and def.leave then runHook(name, def.leave, "hand back") end
end

function S.reread()
    st.nextRead = 0
    sync()
end

-- ----------------------------------------------------------------------------
-- The note, through the game's own dialog (Overrides/Prompts.lua keeps
-- vanilla's ISModalDialog:new as _zedOrigNew; its hook goes vanilla anyway
-- once safe mode holds)
-- ----------------------------------------------------------------------------
-- a word longer than a line (Chinese and Japanese run without spaces) breaks into pieces
local function pieces(word, width)
    if #word <= width then return { word } end
    local cut = (word:byte(1) or 0) >= 0x2E80 and math.floor(width / 2) or width
    local out = {}
    for i = 1, #word, cut do out[#out + 1] = word:sub(i, i + cut - 1) end
    return out
end

local function wrap(text, width)
    local out = {}
    for para in (text .. "\n"):gmatch("(.-)\n") do
        local line = ""
        for word in para:gmatch("%S+") do
            for _, p in ipairs(pieces(word, width)) do
                if line == "" then line = p
                elseif #line + 1 + #p <= width then line = line .. " " .. p
                else out[#out + 1] = line; line = p end
            end
        end
        out[#out + 1] = line
    end
    return table.concat(out, "\n")
end

local function showNote(text)
    local ok, err = pcall(function()
        local MD = ISModalDialog
        if not MD then return end
        local new = MD._zedOrigNew or MD.new
        local body = wrap(text, 64)
        local w, h = 420, 180
        if MD.CalcSize then w, h = MD.CalcSize(w, h, body) end
        local x = math.max(1, math.floor((getCore():getScreenWidth() - w) / 2))
        local y = math.max(1, math.floor((getCore():getScreenHeight() - h) / 2))
        local pn = getSpecificPlayer(0) and 0 or nil
        local modal = new(MD, x, y, w, h, body, false, nil, nil, pn)
        modal:initialise()
        modal:addToUIManager()
        if modal.setAlwaysOnTop then modal:setAlwaysOnTop(true) end
        if pn and JoypadState and JoypadState.players and JoypadState.players[1] then setJoypadFocus(0, modal) end
        S._note = modal
    end)
    if not ok then print("[ZeD] Safe mode: the note could not be shown: " .. tostring(err)) end
end

local function writeTripFile(text)
    local ok, err = pcall(function()
        local f = getFileWriter(TRIP_FILE, true, false)
        if f then f:write(text); f:close() end
    end)
    if not ok then print("[ZeD] Safe mode: " .. TRIP_FILE .. " could not be written: " .. tostring(err)) end
end

-- ----------------------------------------------------------------------------
-- The watchdog
-- ----------------------------------------------------------------------------
function S.trip(where, err)
    if st.tripped then return end
    st.tripped = true
    where = tostring(where or "unknown")
    print("[ZeD] Safe mode: ZeD-GUI stepped aside (" .. where .. "): " .. tostring(err or "no error message"))
    local errLine = (tostring(err or "")):gsub("[\r\n]+", " ")
    writeTripFile(where .. "\r\n" .. errLine .. "\r\n")
    sync()
    if not st.noted then
        st.noted = true
        showNote(ZeD.tr("UI_ZeD_Safe_SteppedAside") .. "\n\n" .. ZeD.tr("UI_ZeD_Safe_TrippedBody", where))
    end
end

function S.reset()
    st.tripped = false
    st.noted = false
    clearStreaks()
    sync()
end

-- One frame's fault into a streak. A pause longer than GAP_MS starts it over.
-- True when it has now run STREAK_MS or more over at least MIN_HITS frames.
local function stepStreak(s, now)
    if not s.last or now - s.last > GAP_MS then
        s.start, s.hits = now, 0
        if s.places then s.places, s.n = {}, 0 end
    end
    s.last = now
    s.hits = s.hits + 1
    return s.hits >= MIN_HITS and now - s.start >= STREAK_MS
end

-- Room for one more place: drop the ones whose streak has already broken
-- (they would start over anyway). False when every place is still failing.
local function pruneStreaks(now)
    for k, s in pairs(streaks) do
        if not s.last or now - s.last > GAP_MS then
            streaks[k] = nil
            nKeys = nKeys - 1
        end
    end
    return nKeys < MAX_KEYS
end

-- The overall streak: any place counts, once a frame; it trips only once it
-- has taken in ALL_PLACES places or more
local function stepOverall(k, now)
    local a = allStreak
    if a.last and now - a.last < FRAME_MS then
        -- a second place in the same frame: noted, not counted again
        if a.n < ALL_PLACES and not a.places[k] then a.places[k] = true; a.n = a.n + 1 end
        return false
    end
    local hit = stepStreak(a, now)
    if a.n < ALL_PLACES and not a.places[k] then a.places[k] = true; a.n = a.n + 1 end
    return hit and a.n >= ALL_PLACES
end

function S.fault(key, err)
    if st.tripped then return end
    -- in game only: the main menu has none of vanilla's in-game interface to hand back
    if not getSpecificPlayer(0) then return end
    local now = getTimestampMs()
    local k = tostring(key)
    local r = streaks[k]
    if not r and (nKeys < MAX_KEYS or pruneStreaks(now)) then
        r = { start = now, hits = 0 }
        streaks[k] = r
        nKeys = nKeys + 1
    end
    -- the same place again within the frame counts once
    if r and r.last and now - r.last < FRAME_MS then return end
    if r and stepStreak(r, now) then S.trip(k, err); return end
    if stepOverall(k, now) then S.trip("errors in several places", err) end
end

-- A per-frame draw hook, fn(panel), under pcall. A failure clears the stencils
-- it had set (ZeD_Panel and ZeD_Window count theirs in _zedStencilN; one left
-- set clips everything drawn after it), counts as a fault and logs once, with
-- the Lua stack the first time for each label. Returns true when it ran.
function S.guard(panel, fn, label)
    local n0 = panel._zedStencilN or 0
    local ok, err, trace = pcall(fn, panel)
    if ok then return true end
    local n = panel._zedStencilN or 0
    while n > n0 do
        pcall(panel.clearStencilRect, panel)
        local m = panel._zedStencilN or 0
        if m >= n then break end
        n = m
    end
    label = label or panel._zedLabel or panel.Type or "panel"
    ZeD.logOnce(label, err)
    if trace and trace ~= "" and not traced[label] and nTraced < 100 then
        traced[label] = true
        nTraced = nTraced + 1
        print("[ZeD] " .. tostring(label) .. " (Lua stack): " .. tostring(trace))
    end
    return false
end

-- ----------------------------------------------------------------------------
-- The next launch after a trip says so once (the file is emptied, not deleted:
-- an empty one counts as none)
-- ----------------------------------------------------------------------------
local function lastTimeNote()
    local where
    pcall(function()
        local r = getFileReader(TRIP_FILE, false)
        if r then
            where = r:readLine()
            r:close()
        end
    end)
    if not where or where == "" then return end
    writeTripFile("")
    -- safe mode is on: ZeD is not on again, so the note would not be true
    if S.on() then return end
    local ev = Events.OnTickEvenPaused or Events.OnTick
    local wait = 0
    local function later()
        wait = wait + 1
        if wait < 60 then return end
        ev.Remove(later)
        showNote(ZeD.tr("UI_ZeD_Safe_LastTime", where))
    end
    ev.Add(later)
end

-- ----------------------------------------------------------------------------
-- Driving it: the option is re-read and the hooks follow it every tick (paused
-- too), on the front end as well; the main menu and a game start read it at
-- once, right after vanilla has loaded the saved options
-- ----------------------------------------------------------------------------
if Events then
    if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(sync)
    elseif Events.OnTick then Events.OnTick.Add(sync) end
    if Events.OnFETick then Events.OnFETick.Add(sync) end
    if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(S.reread) end
    if Events.OnGameStart then
        Events.OnGameStart.Add(function()
            clearStreaks()
            S.reread()
            lastTimeNote()
        end)
    end
end

return S
