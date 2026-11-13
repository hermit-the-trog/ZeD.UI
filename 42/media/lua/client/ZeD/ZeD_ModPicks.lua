-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModPicks.lua
-- ============================================================================
-- FILE PICKS: SETTLING A CONFLICT FILE BY FILE, for when load order alone will
-- not do — one mod should win some files but not others. Client-side; the list
-- and the helper's copies (the Mods screen draws the picker).
--
-- When two mods ship the same Lua file, the one later in the load order runs
-- and the other copy never loads. ZeD comes with a helper mod,
-- ZeD picks (mod id ZeD_Picks, empty), kept last in the load order. For every
-- file you pick, ZeD writes the picked mod's copy into the helper; the helper
-- loads last, so its copy is the one the game runs, and load order still decides
-- every file you did not pick.
--
-- The game lets a mod write text only (getModFileWriter, into a mod's common
-- folder), so this is for code files; pictures, models and sounds stay load
-- order only. It is single player only: a server checks that everyone's code
-- matches its own.
--
-- A copy can never be deleted from Lua, so the helper keeps every path it was
-- ever given ("held") and each is rewritten to what should run:
--   * the picked mod's copy, while that mod is on;
--   * else the copy load order would pick (the last mod that is on and ships it),
--     so an undone pick changes nothing;
--   * else a line that does nothing (no mod that is on ships the file).
-- The copies are rebuilt when the Mods screen opens, when picks change, on
-- Accept, and on the main menu's first frame after the game loads the player's
-- own list (at launch, and on the way back from a game). A copy is frozen text,
-- so a mod Steam updated, or took away, would otherwise run its old text from
-- the helper beside its new files: when a copy changes there while the helper
-- is loaded, a reload puts it in place before Continue can run the old one.
--
-- FILES SWITCHED OFF (the Files tab) ride the same helper: a file off is a held
-- path whose copy is a line that does nothing, written while the copy that would
-- run is that mod's own (it is on and still ships the file, and no pick or later
-- mod's copy runs in its place). Another mod that ships the same path keeps its
-- copy: the switch is one mod's copy only. Switched back on, the path falls to
-- load order again (the mod's own copy), so nothing changes. ZeD-GUI's own files
-- and the helper's are never switched off: the Mods screen runs on the first,
-- and the second are the copies themselves. The game makes the last mod to ship
-- a path the one whose copy runs (ZomboidFileSystem.loadMod overwrites
-- activeFileMap; LuaManager.LoadDirBase runs each path once from it), which is
-- why a copy in the helper, loaded last, stands in for the mod's own.
--
-- The list: Zomboid/Lua/ZeD_picks.txt ("pick=<path>|<mod id>", "held=<path>",
-- "off=<path>|<mod id>"). A path can be picked and switched off at once; it then
-- has both lines.
-- ============================================================================
ZeD = ZeD or {}
ZeD.ModPicks = ZeD.ModPicks or {}
local P = ZeD.ModPicks
P.HELPER = "ZeD_Picks"
local ZED_ID = "ZeD_UI"
local FILE = "ZeD_picks.txt"
-- the reason the main menu's reload gives OnResetLua (its own, so it is never taken for a load from the player's list)
local RELOAD_WHY = "ZeDPicksRefreshed"
local STUB = "-- ZeD picks: no mod that is on ships this file, so this copy does nothing."
local OFF_STUB = "-- ZeD picks: this file is switched off in the Mods screen (Files tab). The mod's own copy is untouched."

local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end

-- ----------------------------------------------------------------------------
-- the list
-- ----------------------------------------------------------------------------
local picks, held, offs = nil, nil, nil
local function load()
    picks, held, offs = {}, {}, {}
    local r = safe(function() return getFileReader(FILE, false) end)
    if not r then return end
    local l = safe(function() return r:readLine() end)
    while l do
        local path, id = l:match("^pick=(.-)|(.+)$")
        if path then picks[path] = id; held[path] = true end
        local h = l:match("^held=(.+)$")
        if h then held[h] = true end
        local op, oid = l:match("^off=(.-)|(.+)$")
        if op then offs[op] = oid; held[op] = true end
        l = safe(function() return r:readLine() end)
    end
    pcall(function() r:close() end)
end
local function save()
    local w = safe(function() return getFileWriter(FILE, true, false) end)
    if not w then return end
    w:write("ZeD-UI file picks (the Mods screen): pick=<path>|<mod id>; held=<path> (a copy the helper keeps); off=<path>|<mod id> (switched off)\n")
    local paths = {}
    for p in pairs(held) do paths[#paths + 1] = p end
    table.sort(paths)
    for _, p in ipairs(paths) do
        -- (a pick and a switch-off on one path are both kept: one line each, so the next load has both)
        if picks[p] then w:write("pick=" .. p .. "|" .. picks[p] .. "\n") end
        if offs[p] then w:write("off=" .. p .. "|" .. offs[p] .. "\n") end
        if not (picks[p] or offs[p]) then w:write("held=" .. p .. "\n") end
    end
    w:close()
end

function P.picks() if not picks then load() end; return picks end

-- ----------------------------------------------------------------------------
-- files switched off (the Files tab)
-- ----------------------------------------------------------------------------
--- The mod a path is switched off for, or nil.
function P.offOf(path) if not picks then load() end; return offs[path] end
--- path -> mod id, every file switched off.
function P.offs() if not picks then load() end; return offs end

--- Can this mod's files be switched off? Never ZeD-GUI's (the Mods screen runs on them: one off
--- could leave no way back) or the helper's (its files are the copies themselves).
function P.mayOff(modId) return modId ~= nil and modId ~= ZED_ID and modId ~= P.HELPER end

--- Switch these paths of modId off (off = true) or back on, and keep the list. A path the
--- helper never held before is held from now on (a copy can never be deleted from Lua).
--- A mod whose files may not be switched off (P.mayOff) is only ever switched back on.
--- A path another mod holds switched off is taken over only when modId's copy is the one that
--- runs (P.runsFrom on order, the mods on in load order; the game's list when nil): a shadowed
--- copy switched off must not hand the path back to the mod whose copy does run.
function P.setOff(modId, paths, off, order)
    if not picks then load() end
    if off and not P.mayOff(modId) then return end
    for _, path in ipairs(paths) do
        if off then
            local holder = offs[path]
            if not holder or holder == modId or P.runsFrom(path, order) == modId then
                offs[path] = modId; held[path] = true
            end
        elseif offs[path] == modId then offs[path] = nil end
    end
    save()
end

--- The paths switched off for modId, sorted.
function P.offFor(modId)
    if not picks then load() end
    local out = {}
    for path, id in pairs(offs) do if id == modId then out[#out + 1] = path end end
    table.sort(out)
    return out
end
function P.pickOf(path) if not picks then load() end; return picks[path] end

--- How many paths the helper changes now: a pick, a switch-off, or both on one path counted once.
function P.changedCount()
    if not picks then load() end
    local n = 0
    for _ in pairs(picks) do n = n + 1 end
    for path in pairs(offs) do if not picks[path] then n = n + 1 end end
    return n
end

-- the helper mod, when it is installed
function P.helper() return safe(getModInfoByID, P.HELPER) end

-- set the picks for these paths (draft: path -> mod id, or nil for load order) and keep them
function P.commit(paths, draft)
    if not picks then load() end
    for _, path in ipairs(paths) do
        local id = draft[path]
        picks[path] = id
        if id then held[path] = true end
    end
    save()
end

-- how many of these paths are picked, and from which mod (the first one met)
function P.countIn(paths)
    if not picks then load() end
    local n, from = 0, nil
    for _, path in ipairs(paths) do
        if picks[path] then n = n + 1; from = from or picks[path] end
    end
    return n, from
end

-- ----------------------------------------------------------------------------
-- reading copies
-- ----------------------------------------------------------------------------
local texts = {}   -- "id|path" -> lines (false: none)

function P.lines(modId, path, fresh)
    local k = tostring(modId) .. "|" .. tostring(path)
    if not fresh and texts[k] ~= nil then return texts[k] or nil end
    local lines = ZeD.ModSettings and ZeD.ModSettings.readLines(modId, path) or nil
    texts[k] = lines or false
    return lines
end

function P.reset() texts = {} end

local function joined(lines) return table.concat(lines or {}, "\n") end

-- the same text in both copies (line endings aside)
function P.same(a, b, path)
    local la, lb = P.lines(a, path), P.lines(b, path)
    if not (la and lb) or #la ~= #lb then return false end
    for i = 1, #la do if la[i] ~= lb[i] then return false end end
    return true
end

-- lines in one copy that the other lacks, both ways (counted as a bag: order aside)
function P.diffCount(la, lb)
    local bag = {}
    for _, l in ipairs(lb or {}) do bag[l] = (bag[l] or 0) + 1 end
    local onlyA = 0
    for _, l in ipairs(la or {}) do
        if (bag[l] or 0) > 0 then bag[l] = bag[l] - 1 else onlyA = onlyA + 1 end
    end
    local onlyB = 0
    for _, n in pairs(bag) do onlyB = onlyB + n end
    return onlyA + onlyB
end

-- the changed stretches of both copies, a line of context around each and "..." between:
-- { { n, text, changed } or { gap = true } ... }, at most max lines a side
function P.excerpt(la, lb, max)
    la, lb = la or {}, lb or {}
    max = max or 12
    local function bagOf(t) local b = {}; for _, l in ipairs(t) do b[l] = (b[l] or 0) + 1 end; return b end
    local function side(t, otherBag)
        -- a line is changed when the other copy has fewer of it (counted, so repeated lines pair up)
        local left, changed = {}, {}
        for k, v in pairs(otherBag) do left[k] = v end
        for i, l in ipairs(t) do
            if (left[l] or 0) > 0 then left[l] = left[l] - 1 else changed[i] = true end
        end
        local keep = {}
        for i in pairs(changed) do for k = i - 1, i + 1 do if k >= 1 and k <= #t then keep[k] = true end end end
        local out, last = {}, 0
        for i = 1, #t do
            if keep[i] then
                if #out >= max then out[#out + 1] = { gap = true }; return out end
                if last > 0 and i > last + 1 then out[#out + 1] = { gap = true } end
                out[#out + 1] = { n = i, text = t[i], changed = changed[i] == true }
                last = i
            end
        end
        if last > 0 and last < #t then out[#out + 1] = { gap = true } end
        return out
    end
    return side(la, bagOf(lb)), side(lb, bagOf(la))
end

-- ----------------------------------------------------------------------------
-- the helper's copies
-- ----------------------------------------------------------------------------
local orderOf   -- (the game's list of mods on, in load order: below)

-- the copy that runs without a switch: the pick while its mod is on and ships the file, else load
-- order's (the last mod that is on and ships it). Returns its lines and the mod it comes from.
local function runCopy(path, order, on, fresh)
    local from = picks[path]
    if from and on[from] then
        local l = P.lines(from, path, fresh)
        if l then return l, from end
    end
    for i = #order, 1, -1 do
        local id = order[i]
        if id ~= P.HELPER then
            local l = P.lines(id, path, fresh)
            if l then return l, id end
        end
    end
    return nil, nil
end

--- The mod whose copy of this path runs without a switch (order: the mods on, in load order; the
--- game's list when nil), or nil when no mod that is on ships it.
function P.runsFrom(path, order)
    if not picks then load() end
    order = order or orderOf()
    local on = {}
    for _, id in ipairs(order) do on[id] = true end
    local _, runId = runCopy(path, order, on, false)
    return runId
end

-- order: the mod ids that are (or will be, after the reload) on, in load order. Returns how many copies
-- changed (a write counts once the copy reads back as written, so one that did not take asks no reload).
function P.sync(order)
    if not P.helper() then return 0 end
    if not picks then load() end
    order = order or {}
    local on = {}
    for _, id in ipairs(order) do on[id] = true end
    local wrote = 0
    for path in pairs(held) do
        -- the copy that runs without a switch (runCopy); runId is the mod it comes from
        local want, runId = runCopy(path, order, on, true)
        -- switched off: the do-nothing line, only while the copy that would run is that mod's own. A pick
        -- of another copy, or a mod later in the order that ships the same path, runs as it would (the
        -- switch is one mod's copy, not every mod's). Never a path the game has too, whose own copy it
        -- would replace (ZeD_ModFiles.isGameFile), never a file of ZeD-GUI or the helper (P.mayOff).
        local text = nil
        local offId = offs[path]
        if offId and offId == runId and P.mayOff(offId)
                and not (ZeD.ModFiles and ZeD.ModFiles.isGameFile and ZeD.ModFiles.isGameFile(path)) then
            text = OFF_STUB
        end
        text = text or (want and joined(want)) or STUB
        local cur = P.lines(P.HELPER, path, true)
        if not cur or joined(cur) ~= text then
            local w = safe(function() return getModFileWriter(P.HELPER, path, true, false) end)
            if w then
                pcall(function() w:write(text .. "\n"); w:close() end)
                texts[P.HELPER .. "|" .. path] = nil
                local now = P.lines(P.HELPER, path, true)
                if now and joined(now) == text then wrote = wrote + 1 end
            end
        end
    end
    return wrote
end

-- the helper holds a copy of anything now (it must then stay on, and last)
function P.holdsAny()
    if not picks then load() end
    for _ in pairs(held) do return true end   -- (Kahlua has no next)
    return false
end

-- the paths with a pick whose mod is on (what the helper changes)
function P.activeCount(order)
    if not picks then load() end
    local on, n = {}, 0
    for _, id in ipairs(order or {}) do on[id] = true end
    for _, id in pairs(picks) do if on[id] then n = n + 1 end end
    for _, id in pairs(offs) do if on[id] then n = n + 1 end end
    return n
end

-- ----------------------------------------------------------------------------
-- at the main menu: the copies made afresh before a game can start
-- ----------------------------------------------------------------------------
-- The game loads the player's own list ("default") at launch and on the way back from a game,
-- and neither fires OnResetLua. Every other load is a reset that says why in OnResetLua, right
-- after OnMainMenuEnter: a save's, a new game's or a server's list, Accept, Options, or this
-- file's own reload. Those are left alone, so a game that is starting is never reset under it,
-- and this reload never runs twice. The check waits for the menu's first frame, when OnResetLua
-- has had its turn.

-- the game's list of mods on, in load order (getActivatedMods)
orderOf = function()
    local order = {}
    local l = safe(getActivatedMods)
    for i = 0, (l and l:size() or 0) - 1 do order[#order + 1] = l:get(i) end
    return order
end

--- The copies rebuilt for the list the game loaded; when one changed while the helper is loaded,
--- the game's deferred reload is asked for (Core.DelayResetLua: the main menu's update runs it
--- after the frame's Lua events; a reset from inside an event handler closed the game). Not on a
--- QA autoload launch, which continues a save by itself a moment later. Returns how many copies
--- changed and whether the reload was asked for.
function P.refreshLoaded()
    if not P.helper() then return 0, false end
    local order, loaded = orderOf(), false
    for _, id in ipairs(order) do if id == P.HELPER then loaded = true end end
    if not loaded then return 0, false end
    local wrote = 0
    pcall(function() wrote = P.sync(order) end)
    if wrote == 0 or ZeD.QAAutoload then return wrote, false end
    local asked = pcall(function() getCore():DelayResetLua("default", RELOAD_WHY) end)
    return wrote, asked
end

local fromReset = false     -- (this Lua load came from a reset: OnResetLua fired)
local function atMenu()
    Events.OnFETick.Remove(atMenu)
    if not fromReset then P.refreshLoaded() end
end
if Events and Events.OnResetLua and Events.OnMainMenuEnter and Events.OnFETick then
    Events.OnResetLua.Add(function() fromReset = true end)
    Events.OnMainMenuEnter.Add(function()
        Events.OnFETick.Remove(atMenu)
        Events.OnFETick.Add(atMenu)
    end)
end
