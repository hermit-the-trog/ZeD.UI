-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModPicks.lua
-- ============================================================================
-- FILE PICKS: SETTLING A CONFLICT FILE BY FILE (director, Oct 24 2026: "is there
-- a way to override file conflicts when load order alone won't solve it. like if
-- you want some files replaced by another mod, but want it to not win on other
-- files?"; mockup zed_mods_settings_picks_v1, approved)
--
-- When two mods ship the same Lua file, the one later in the load order runs
-- and the other copy never loads (KB Q263). ZeD comes with a helper mod,
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
-- The copies are rebuilt when the Mods screen opens and when picks change, so a
-- picked mod's update reaches its copy (the next reload runs it).
--
-- The list: Zomboid/Lua/ZeD_picks.txt ("pick=<path>|<mod id>", "held=<path>").
-- ============================================================================
ZeD = ZeD or {}
ZeD.ModPicks = ZeD.ModPicks or {}
local P = ZeD.ModPicks
P.HELPER = "ZeD_Picks"
local FILE = "ZeD_picks.txt"
local STUB = "-- ZeD picks: no mod that is on ships this file, so this copy does nothing."

local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end

-- ----------------------------------------------------------------------------
-- the list
-- ----------------------------------------------------------------------------
local picks, held = nil, nil
local function load()
    picks, held = {}, {}
    local r = safe(function() return getFileReader(FILE, false) end)
    if not r then return end
    local l = safe(function() return r:readLine() end)
    while l do
        local path, id = l:match("^pick=(.-)|(.+)$")
        if path then picks[path] = id; held[path] = true end
        local h = l:match("^held=(.+)$")
        if h then held[h] = true end
        l = safe(function() return r:readLine() end)
    end
    pcall(function() r:close() end)
end
local function save()
    local w = safe(function() return getFileWriter(FILE, true, false) end)
    if not w then return end
    w:write("ZeD-UI file picks (the Mods screen): pick=<path>|<mod id>; held=<path> (a copy the helper keeps)\n")
    local paths = {}
    for p in pairs(held) do paths[#paths + 1] = p end
    table.sort(paths)
    for _, p in ipairs(paths) do
        if picks[p] then w:write("pick=" .. p .. "|" .. picks[p] .. "\n") else w:write("held=" .. p .. "\n") end
    end
    w:close()
end

function P.picks() if not picks then load() end; return picks end
function P.pickOf(path) if not picks then load() end; return picks[path] end

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
-- order: the mod ids that are (or will be, after the reload) on, in load order
function P.sync(order)
    if not P.helper() then return 0 end
    if not picks then load() end
    local on = {}
    for _, id in ipairs(order or {}) do on[id] = true end
    local wrote = 0
    for path in pairs(held) do
        local want = nil
        local from = picks[path]
        if from and on[from] then want = P.lines(from, path, true) end
        if not want then
            for i = #(order or {}), 1, -1 do
                local id = order[i]
                if id ~= P.HELPER then
                    local l = P.lines(id, path, true)
                    if l then want = l; break end
                end
            end
        end
        local text = want and joined(want) or STUB
        local cur = P.lines(P.HELPER, path, true)
        if not cur or joined(cur) ~= text then
            local w = safe(function() return getModFileWriter(P.HELPER, path, true, false) end)
            if w then
                pcall(function() w:write(text .. "\n"); w:close() end)
                texts[P.HELPER .. "|" .. path] = nil
                wrote = wrote + 1
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
    return n
end
