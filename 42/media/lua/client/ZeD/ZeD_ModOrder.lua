-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModOrder.lua
-- ============================================================================
-- THE LOAD ORDER'S RULES, WITHOUT THE SCREEN (ZeDUI/MODS_LOAD_ORDER_SPEC.md, punch list 41;
-- director, Oct 31 2026: "I want the mod manager to really shine")
--
--   * the profile file (Zomboid/Lua/ZeD_modprofiles.txt): each profile's order and dates, now
--     with its pins and rules, and the lists' own pins and rules under "[@list ...]" sections
--     (spec 7). The writer keeps every line it does not know (spec 7.4): later stages' keys
--     (separators) and other tools' lines survive a save.
--   * each mod's needs and wishes read from the game once (readInfo), not per row per frame
--   * laying out the order (spec 4): requirements, ZeD picks last, the pinned blocks, your
--     rules, then the player's own place; Auto sorts by the mods' own wishes first
--   * the order check (red / yellow / green per row), run once per change by the screen
--   * the picker's questions: what must load before / after a mod (requirements, your rules)
--
-- Nothing here draws. The Mods screen (ZeD_MainMenuModsOrder.lua) holds a working copy of the
-- list's pins and rules ("lo": { first = { ids }, last = { ids }, rules = { { id, how, other } } })
-- until Done.
-- ============================================================================
ZeD = ZeD or {}
ZeD.ModOrder = ZeD.ModOrder or {}
local O = ZeD.ModOrder

-- QA counters (zedqa_mods_order.lua): how often the whole-list passes ran
O.stats = O.stats or { checks = 0, layouts = 0, infos = 0, views = 0 }

local EMPTY = {}
local MAX_DEPTH = 64

local function helperId() return (ZeD.ModPicks and ZeD.ModPicks.HELPER) or "ZeD_Picks" end
O.helperId = helperId

-- a Java ArrayList (or nil) as a Lua array
local function jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end
    return t
end

-- ----------------------------------------------------------------------------
-- THE PROFILE FILE
-- ----------------------------------------------------------------------------
local FILE = "ZeD_modprofiles.txt"
local HEADER = "ZeD-UI mod profiles: the load order and dates kept with each mod-list preset"
-- name -> { order, first, last, rules, saved, used, keep = { lines it does not know } }
local Store = { loaded = false, t = {}, pre = {} }

local function splitIds(v)
    local t = {}
    for id in tostring(v or ""):gmatch("[^;]+") do t[#t + 1] = id end
    return t
end

-- (gen counts the file's changes: a screen keeps what it read from it until gen moves)
O.gen = O.gen or 0

function O.load()
    O.gen = O.gen + 1
    Store.t, Store.pre, Store.loaded = {}, {}, true
    local r = getFileReader(FILE, false)
    if not r then return end
    local cur
    local line = r:readLine()
    while line do
        local name = line:match("^%[(.+)%]$")
        if name then
            cur = { order = {}, first = {}, last = {}, rules = {}, keep = {} }
            Store.t[name] = cur
        elseif cur then
            local k, v = line:match("^(%a+)=(.*)$")
            if k == "order" or k == "first" or k == "last" then
                cur[k] = splitIds(v)
            elseif k == "rule" then
                local a, how, b = v:match("^([^|]+)|(%a+)|(.+)$")
                if a and (how == "after" or how == "before") then cur.rules[#cur.rules + 1] = { id = a, how = how, other = b }
                else cur.keep[#cur.keep + 1] = line end
            elseif k == "saved" or k == "used" then
                cur[k] = v
            elseif line ~= "" then
                cur.keep[#cur.keep + 1] = line      -- (spec 7.4: a line it does not know stays)
            end
        elseif line ~= "" and line ~= HEADER then
            Store.pre[#Store.pre + 1] = line
        end
        line = r:readLine()
    end
    r:close()
end

local function isList(name) return tostring(name):sub(1, 1) == "@" end

local function holdsNothing(e)
    return #(e.order or EMPTY) == 0 and #(e.first or EMPTY) == 0 and #(e.last or EMPTY) == 0 and #(e.rules or EMPTY) == 0
        and #(e.keep or EMPTY) == 0 and (e.saved or "") == "" and (e.used or "") == ""
end

function O.save()
    if not Store.loaded then O.load() end
    O.gen = O.gen + 1
    local w = getFileWriter(FILE, true, false)
    if not w then return end
    w:write(HEADER .. "\n")
    for _, l in ipairs(Store.pre) do w:write(l .. "\n") end
    local names = {}
    for n in pairs(Store.t) do names[#names + 1] = n end
    O.sort(names)
    for _, n in ipairs(names) do
        local e = Store.t[n]
        -- (a list's section with nothing in it is not written; a profile's always is)
        if not (isList(n) and holdsNothing(e)) then
            w:write("[" .. n .. "]\n")
            if e.order and #e.order > 0 then w:write("order=" .. table.concat(e.order, ";") .. "\n") end
            if e.first and #e.first > 0 then w:write("first=" .. table.concat(e.first, ";") .. "\n") end
            if e.last and #e.last > 0 then w:write("last=" .. table.concat(e.last, ";") .. "\n") end
            for _, r in ipairs(e.rules or EMPTY) do w:write("rule=" .. r.id .. "|" .. r.how .. "|" .. r.other .. "\n") end
            if e.saved and e.saved ~= "" then w:write("saved=" .. e.saved .. "\n") end
            if e.used and e.used ~= "" then w:write("used=" .. e.used .. "\n") end
            for _, l in ipairs(e.keep or EMPTY) do w:write(l .. "\n") end
        end
    end
    w:close()
end

-- the file's sections (name -> entry); profiles and lists alike
function O.entries()
    if not Store.loaded then O.load() end
    return Store.t
end

function O.entry(name, create)
    if not name then return nil end
    local t = O.entries()
    local e = t[name]
    if not e and create then e = { order = {}, first = {}, last = {}, rules = {}, keep = {} }; t[name] = e end
    return e
end

-- ----------------------------------------------------------------------------
-- PINS AND RULES ("lo")
-- ----------------------------------------------------------------------------
-- the list being edited (spec 7.2): its own section, a name no profile can take
function O.listKey(m)
    if not m then return "@list main menu" end
    if m.isServerSettingsMods then
        local n
        pcall(function() n = ServerSettingsScreen.instance.pageEdit.settings:getName() end)
        return "@list server " .. tostring(n or "settings")
    end
    if m.loadGameFolder then return "@list save " .. tostring(m.loadGameFolder) end
    if m.isNewGame then return "@list new game" end
    return "@list main menu"
end

function O.copyLo(src)
    local lo = { first = {}, last = {}, rules = {} }
    if not src then return lo end
    for _, id in ipairs(src.first or EMPTY) do lo.first[#lo.first + 1] = id end
    for _, id in ipairs(src.last or EMPTY) do lo.last[#lo.last + 1] = id end
    for _, r in ipairs(src.rules or EMPTY) do lo.rules[#lo.rules + 1] = { id = r.id, how = r.how, other = r.other } end
    return lo
end

function O.isEmpty(lo) return not lo or (#lo.first == 0 and #lo.last == 0 and #lo.rules == 0) end

-- a section's pins and rules, as a working copy
function O.getLo(name) return O.copyLo(O.entry(name)) end

-- keeps a working copy under a section (profile or list); save = write the file now
function O.putLo(name, lo, save)
    local e = O.entry(name, true)
    local c = O.copyLo(lo)
    e.first, e.last, e.rules = c.first, c.last, c.rules
    O.gen = O.gen + 1
    if save then O.save() end
end

-- "first" | "last" | nil
function O.pinOf(lo, id)
    if not lo then return nil end
    for _, p in ipairs(lo.first or EMPTY) do if p == id then return "first" end end
    for _, p in ipairs(lo.last or EMPTY) do if p == id then return "last" end end
    return nil
end

local function dropFrom(t, id)
    for i = #t, 1, -1 do if t[i] == id then table.remove(t, i) end end
end

function O.setPin(lo, id, which)
    dropFrom(lo.first, id); dropFrom(lo.last, id)
    if which == "first" then lo.first[#lo.first + 1] = id elseif which == "last" then lo.last[#lo.last + 1] = id end
end

-- a rule for id (spec 3.4: a second rule on the same pair replaces the first, whoever owns it)
function O.addRule(lo, id, how, other)
    for i = #lo.rules, 1, -1 do
        local r = lo.rules[i]
        if (r.id == id and r.other == other) or (r.id == other and r.other == id) then table.remove(lo.rules, i) end
    end
    lo.rules[#lo.rules + 1] = { id = id, how = how, other = other }
end

function O.rulesOf(lo, id)
    local t = {}
    for i, r in ipairs(lo and lo.rules or EMPTY) do if r.id == id then t[#t + 1] = { r = r, k = i } end end
    return t
end

function O.removeRule(lo, r)
    for i = #lo.rules, 1, -1 do if lo.rules[i] == r then table.remove(lo.rules, i) end end
end

function O.removeRulesOf(lo, id)
    for i = #lo.rules, 1, -1 do if lo.rules[i].id == id then table.remove(lo.rules, i) end end
end

-- ----------------------------------------------------------------------------
-- WHAT THE GAME SAYS OF EACH MOD (read once per page, spec 5.2)
-- ----------------------------------------------------------------------------
function O.readInfo(m, ids)
    O.stats.infos = O.stats.infos + 1
    local I = {}
    for _, id in ipairs(ids) do
        local d = m and m.mods and m.mods[id]
        local e = { name = tostring(id), req = EMPTY, after = EMPTY, before = EMPTY, installed = d ~= nil }
        local wid = ""
        if d then
            e.name = tostring(d.name or id)
            local mi = d.modInfo
            pcall(function() e.req = jlist(mi:getRequire()) end)
            pcall(function() e.after = jlist(mi:getLoadAfter()) end)
            pcall(function() e.before = jlist(mi:getLoadBefore()) end)
            pcall(function() wid = tostring(mi:getWorkshopID() or "") end)
        end
        -- Find's text (spec 5.3): name, id and Workshop number, lower case, made once
        e.hay = string.lower(e.name .. " " .. tostring(id) .. " " .. wid)
        I[id] = e
    end
    return I
end

-- a mod's name: from the page's info, else the game's records, else its id
function O.nameOf(m, I, id)
    local e = I and I[id]
    if e then return e.name end
    local d = m and m.mods and m.mods[id]
    return d and tostring(d.name or id) or tostring(id)
end

-- ----------------------------------------------------------------------------
-- A SORT FOR LONG LISTS. The game's table.sort is a quicksort that pivots on the first item: a
-- list already in order recurses once per item, and 1,500 mod ids overflow Kahlua's stack.
-- This one merges runs bottom-up (no recursion) and keeps equal items in their order.
-- ----------------------------------------------------------------------------
local function lessThan(a, b) return a < b end
function O.sort(t, lt)
    local n = #t
    if n < 2 then return t end
    lt = lt or lessThan
    local src, dst = t, {}
    local width = 1
    while width < n do
        local i = 1
        while i <= n do
            local mid = math.min(i + width, n + 1)
            local hi = math.min(i + 2 * width, n + 1)
            local a, b, k = i, mid, i
            while a < mid and b < hi do
                if lt(src[b], src[a]) then dst[k] = src[b]; b = b + 1 else dst[k] = src[a]; a = a + 1 end
                k = k + 1
            end
            while a < mid do dst[k] = src[a]; a = a + 1; k = k + 1 end
            while b < hi do dst[k] = src[b]; b = b + 1; k = k + 1 end
            i = i + 2 * width
        end
        src, dst = dst, src
        width = width * 2
    end
    if src ~= t then for i = 1, n do t[i] = src[i] end end
    return t
end

-- ----------------------------------------------------------------------------
-- AUTO: vanilla's ModLoadOrderPanel:autoSort (by mod id, each mod's load-after and needs
-- pulled in before it, its load-before after it), on the page's info; the ids it cannot
-- place (not installed) stay at the end in their order
-- ----------------------------------------------------------------------------
local function indexOf(t, v) for i, x in ipairs(t) do if x == v then return i end end; return #t end

function O.ruleOrder(I, ids)
    local base = {}
    for _, id in ipairs(ids) do if I[id] and I[id].installed then base[#base + 1] = id end end
    O.sort(base)
    local auto, added = {}, {}
    for _, id in ipairs(base) do
        local e = I[id]
        local temp = {}
        for _, a in ipairs(e.after) do if not added[a] then temp[#temp + 1] = a; added[a] = true end end
        for _, r in ipairs(e.req) do if not added[r] then temp[#temp + 1] = r; added[r] = true end end
        temp[#temp + 1] = id
        local mIndex = #temp
        for _, b in ipairs(e.before) do if not added[b] then temp[#temp + 1] = b; added[b] = true end end
        if added[id] then
            local index = indexOf(auto, id)
            for j = mIndex + 1, #temp do table.insert(auto, index + 1, temp[j]) end
            for j = 1, mIndex - 1 do table.insert(auto, index, temp[j]) end
        else
            for j = 1, #temp do auto[#auto + 1] = temp[j] end
            added[id] = true
        end
    end
    local inList = {}
    for _, id in ipairs(ids) do inList[id] = true end
    local out, seen = {}, {}
    for _, id in ipairs(auto) do if inList[id] and not seen[id] then out[#out + 1] = id; seen[id] = true end end
    for _, id in ipairs(ids) do if not seen[id] then out[#out + 1] = id; seen[id] = true end end
    return out
end

-- ----------------------------------------------------------------------------
-- A RULE MADE KEPT: id goes just after (or before) other, inside one block. What must move
-- with it moves with it: for "after", the mods between that need id (they stay under it);
-- for "before", the mods between that id needs (they stay over it). Returns true when it moved.
-- ----------------------------------------------------------------------------
function O.place(order, I, id, how, other)
    local i, j
    for k, x in ipairs(order) do
        if x == id then i = k elseif x == other then j = k end
    end
    if not (i and j) then return false end
    if how == "after" then
        if i > j then return false end
        local group, need, rest = { id }, { [id] = true }, {}
        for k = i + 1, j do
            local x = order[k]
            local dep = false
            if x ~= other then
                for _, r in ipairs(I[x] and I[x].req or EMPTY) do if need[r] then dep = true; break end end
            end
            if dep then group[#group + 1] = x; need[x] = true else rest[#rest + 1] = x end
        end
        local k = i
        for _, x in ipairs(rest) do order[k] = x; k = k + 1 end
        for _, x in ipairs(group) do order[k] = x; k = k + 1 end
    else
        if i < j then return false end
        local needs = {}
        for _, r in ipairs(I[id] and I[id].req or EMPTY) do needs[r] = true end
        local group, rest = {}, {}
        for k = i - 1, j, -1 do
            local x = order[k]
            if needs[x] and x ~= other then
                table.insert(group, 1, x)
                for _, r in ipairs(I[x] and I[x].req or EMPTY) do needs[r] = true end
            else
                table.insert(rest, 1, x)
            end
        end
        local k = j
        for _, x in ipairs(group) do order[k] = x; k = k + 1 end
        order[k] = id; k = k + 1
        for _, x in ipairs(rest) do order[k] = x; k = k + 1 end
    end
    return true
end

-- ----------------------------------------------------------------------------
-- LAYING OUT (spec 4): requirements, ZeD picks last, the pins (with what they carry), your
-- rules, then the player's own place. auto = sort by the mods' own wishes first (inside each
-- block; the pins' order then follows the block). Returns the new order, each mod's block
-- (1 load first, 2 the rest, 3 load last, 4 ZeD picks) and the carried mods.
-- ----------------------------------------------------------------------------
local function firstBlock(order, I, lo, on, helper)
    local F, inF, pinF = {}, {}, {}
    for _, p in ipairs(lo.first) do if on[p] and p ~= helper then pinF[p] = true end end
    local function add(id, depth)
        if inF[id] or not on[id] or id == helper or depth > MAX_DEPTH then return end
        inF[id] = true            -- (marked first: a loop of needs cannot recurse forever)
        for _, r in ipairs(I[id] and I[id].req or EMPTY) do add(r, depth + 1) end
        F[#F + 1] = id
    end
    for _, p in ipairs(lo.first) do if pinF[p] then add(p, 0) end end
    return F, inF, pinF
end

local function lastBlock(order, I, lo, on, helper, inF)
    local inL, pinL, pins = {}, {}, {}
    for _, p in ipairs(lo.last) do
        if on[p] and p ~= helper and not inF[p] and not inL[p] then inL[p] = true; pinL[p] = true; pins[#pins + 1] = p end
    end
    -- every mod that needs one of them loads after it: it comes into the block (carried)
    local grew, guard = #pins > 0, 0
    while grew and guard < MAX_DEPTH do
        grew, guard = false, guard + 1
        for _, id in ipairs(order) do
            if not inL[id] and not inF[id] and id ~= helper then
                for _, r in ipairs(I[id] and I[id].req or EMPTY) do
                    if inL[r] then inL[id] = true; grew = true; break end
                end
            end
        end
    end
    local L, placed = {}, {}
    local function add(id, depth)
        if placed[id] or not inL[id] or depth > MAX_DEPTH then return end
        placed[id] = true
        for _, r in ipairs(I[id] and I[id].req or EMPTY) do add(r, depth + 1) end
        L[#L + 1] = id
    end
    for _, p in ipairs(pins) do add(p, 0) end
    for _, id in ipairs(order) do if inL[id] then add(id, 0) end end
    return L, inL, pinL
end

-- after Auto sorted a block, its pins keep the block's order (the pins not on keep theirs, after)
local function pinsFollow(pins, block, isPin)
    local out, seen = {}, {}
    for _, id in ipairs(block) do if isPin[id] then out[#out + 1] = id; seen[id] = true end end
    for _, id in ipairs(pins) do if not seen[id] then out[#out + 1] = id end end
    return out
end

function O.layout(order, I, lo, auto)
    O.stats.layouts = O.stats.layouts + 1
    lo = lo or O.copyLo(nil)
    local on = {}
    for _, id in ipairs(order) do on[id] = true end
    local helper = helperId()
    local hasHelper = on[helper] == true
    local F, inF, pinF = firstBlock(order, I, lo, on, helper)
    local L, inL, pinL = lastBlock(order, I, lo, on, helper, inF)
    local M = {}
    for _, id in ipairs(order) do if not inF[id] and not inL[id] and id ~= helper then M[#M + 1] = id end end
    if auto then
        M = O.ruleOrder(I, M)
        if #F > 1 then F = O.ruleOrder(I, F); lo.first = pinsFollow(lo.first, F, pinF) end
        if #L > 1 then L = O.ruleOrder(I, L); lo.last = pinsFollow(lo.last, L, pinL) end
    end
    local out, zone, carried = {}, {}, {}
    for _, id in ipairs(F) do out[#out + 1] = id; zone[id] = 1; if not pinF[id] then carried[id] = true end end
    for _, id in ipairs(M) do out[#out + 1] = id; zone[id] = 2 end
    for _, id in ipairs(L) do out[#out + 1] = id; zone[id] = 3; if not pinL[id] then carried[id] = true end end
    if hasHelper then out[#out + 1] = helper; zone[helper] = 4 end
    -- your rules, oldest first, inside a block (a rule across blocks is kept or not by the blocks)
    for _ = 1, 2 do
        for _, r in ipairs(lo.rules) do
            local za, zb = zone[r.id], zone[r.other]
            if za and za == zb and za ~= 4 then O.place(out, I, r.id, r.how, r.other) end
        end
    end
    return out, zone, carried
end

-- ----------------------------------------------------------------------------
-- THE ORDER CHECK (spec 3.6, 2.6): per row "ok" | "soft" (a wish, a rule or a pin not kept) |
-- "bad" (a mod it needs loads later or is not in the list). A wish your pin or your rule
-- overrides is not yellow. One pass over the list per change.
-- ----------------------------------------------------------------------------
local function pairKeys(lo)
    local pair = {}
    for _, r in ipairs(lo and lo.rules or EMPTY) do
        local a = pair[r.id]; if not a then a = {}; pair[r.id] = a end; a[r.other] = true
        local b = pair[r.other]; if not b then b = {}; pair[r.other] = b end; b[r.id] = true
    end
    return pair
end

local function overridden(pair, zone, a, b)
    if (zone[a] or 2) ~= (zone[b] or 2) then return "pin" end
    local p = pair[a]
    if p and p[b] then return "rule" end
    return nil
end
O.overridden = overridden
O.pairKeys = pairKeys

function O.check(order, I, lo, zone)
    O.stats.checks = O.stats.checks + 1
    zone = zone or EMPTY
    local idx = {}
    for i, id in ipairs(order) do idx[id] = i end
    local pair = pairKeys(lo)
    local ruleBy, pinL = {}, {}
    for _, r in ipairs(lo and lo.rules or EMPTY) do
        local t = ruleBy[r.id]; if not t then t = {}; ruleBy[r.id] = t end
        t[#t + 1] = r
    end
    for _, p in ipairs(lo and lo.last or EMPTY) do pinL[p] = true end
    local st, nBad, nSoft, firstBad = {}, 0, 0, nil
    for i, id in ipairs(order) do
        local e = I and I[id]
        local s = "ok"
        if e then
            for _, r in ipairs(e.req) do
                local j = idx[r]
                if not j or j > i then s = "bad"; break end
            end
            if s == "ok" then
                for _, a in ipairs(e.after) do
                    local j = idx[a]
                    if j and j > i and not overridden(pair, zone, id, a) then s = "soft"; break end
                end
            end
            if s == "ok" then
                for _, b in ipairs(e.before) do
                    local j = idx[b]
                    if j and j < i and not overridden(pair, zone, id, b) then s = "soft"; break end
                end
            end
            if s == "ok" then
                for _, r in ipairs(ruleBy[id] or EMPTY) do
                    local j = idx[r.other]
                    if j and ((r.how == "after" and j > i) or (r.how == "before" and j < i)) then s = "soft"; break end
                end
            end
            if s == "ok" and pinL[id] and zone[id] ~= 3 then s = "soft" end
        end
        st[i] = s
        if s == "bad" then nBad = nBad + 1; if not firstBad then firstBad = i end
        elseif s == "soft" then nSoft = nSoft + 1 end
    end
    return { st = st, idx = idx, nBad = nBad, nSoft = nSoft, firstBad = firstBad }
end

-- a rule kept in this order? (nil: it does nothing: the other mod is off or not installed)
function O.ruleKept(idx, r)
    local i, j = idx[r.id], idx[r.other]
    if not (i and j) then return nil end
    if r.how == "after" then return i > j end
    return i < j
end

-- ----------------------------------------------------------------------------
-- THE PICKER'S QUESTIONS: every mod that must load before x (back = true) or after it,
-- by requirements alone (reqOnly) or by requirements and your rules. Once per picker.
-- ----------------------------------------------------------------------------
function O.reach(I, lo, x, back, reqOnly)
    -- edges a -> b: a loads before b
    local succ, pred = {}, {}
    local function edge(a, b)
        local s = succ[a]; if not s then s = {}; succ[a] = s end; s[#s + 1] = b
        local p = pred[b]; if not p then p = {}; pred[b] = p end; p[#p + 1] = a
    end
    for id, e in pairs(I) do for _, r in ipairs(e.req) do edge(r, id) end end
    if not reqOnly then
        for _, r in ipairs(lo and lo.rules or EMPTY) do
            if r.how == "after" then edge(r.other, r.id) else edge(r.id, r.other) end
        end
    end
    local nb = back and pred or succ
    local seen, queue, head = {}, { x }, 1
    while head <= #queue do
        local cur = queue[head]
        head = head + 1
        for _, y in ipairs(nb[cur] or EMPTY) do
            if not seen[y] and y ~= x then seen[y] = true; queue[#queue + 1] = y end
        end
    end
    return seen
end
