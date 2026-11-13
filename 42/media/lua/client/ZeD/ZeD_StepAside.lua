-- ZeD-UI/42/media/lua/client/ZeD/ZeD_StepAside.lua
-- ============================================================================
-- STEPPING ASIDE FOR A MOD THAT TAKES A SCREEN - client logic, no window of
-- its own. It is automatic: nothing is asked, and a note in Messages names
-- the mod and the screen and says how to turn ZeD's back on (ZeD setup). The
-- Workshop page promises ZeD steps aside for mods loaded after it.
--
-- After every mod has loaded (a game's start, once the game's windows are
-- built), each ZeD screen with a ZeD setup switch (Settings.lua screenOptions)
-- is checked. When a mod (before or after ZeD in the load order, either one
-- counts) has replaced the game's own version of that screen, the screen is
-- handed back to the game (and so to that mod) through its switch, the rest of
-- ZeD kept; a note says so in Messages.
--
-- What counts as replaced (strict: a player must not lose a ZeD screen for
-- nothing):
--   * a page of the game's Character Info window (Info, Skills, Health,
--     Protection, Temperature) now holds a view that is not the game's class
--     or one derived from it (Wounds Overhaul's examination in Health's place)
--   * EVERY core function of the screen's main class (CORE below: its
--     createChildren with its render and prerender, not one helper) is now a
--     function from that one mod's files that never calls the one it replaced.
--     The file is read (getFilenameOfClosure, getModFileReader): a body that
--     calls a saved copy of the old function (local orig = X.f ... orig(self),
--     hooks.render(self), MyMod.vanilla.render(self)) wraps it and does not
--     count, nor anything this file cannot read or is unsure of (no copy kept
--     under a name it can see, a definition it cannot find, a hook library).
--   Less than that (one copied and edited function, which is how most mods add
--   a tab or a button) hands nothing back and says nothing to the player: one
--   line goes to console.txt ("[ZeD] Step aside: partial ...") for testing.
-- What never counts: the game's own files (in no mod's folder), ZeD's, a
-- mod ZeD supports (ModSupport: SUPPORTED below), and a mod that only adds
-- (context menu options, buttons, tabs under new names, wrapped functions).
--
-- The hand-back is the screen's own ZeD setup switch, ticked (the game's own) and
-- saved, so ZeD setup shows it with "Taken by <mod>" under it. Unticking it is
-- taking the screen back: that holds for as long as that same mod is the one
-- taking it, whatever other mods come and go (Zomboid/Lua/ZeD_step_aside.txt).
-- A mod that has gone gives its screen back to ZeD the same way.
--
--   ZeD.StepAside.check()          detect and apply now (the game start does it)
--   ZeD.StepAside.detect()         { [screen] = { id, name, why } }, nothing applied
--   ZeD.StepAside.underFor(screen) "Taken by <mod>" for ZeD setup, or nil
--   ZeD.StepAside.support(modId)   a ModSupport file's mod never triggers
-- ============================================================================

require "ZeD/Tr"
require "ZeD/SafeMode"

-- Kahlua has no next(); whether a table has any entry.
local function hasAny(t) if type(t) ~= "table" then return false end for _ in pairs(t) do return true end return false end
ZeD = ZeD or {}
ZeD.StepAside = ZeD.StepAside or {}
local SA = ZeD.StepAside

local FILE = "ZeD_step_aside.txt"
local ZED_ID = "ZeD_UI"

-- mods ZeD supports (ModSupport/*.lua, their MOD_ID); they never trigger a hand-back
SA.SUPPORTED = SA.SUPPORTED or {}
for _, id in ipairs({
    "AutoHideHotbar", "BB_WhereAmI", "BLTAnnotations", "BetterItemTransfer", "BetterModExperience", "Clear_SkillSheet",
    "ContainerCapacityIndicator", "DRAW_ON_MAP", "EvolvingTraitsWorld", "ExpRecovery", "ImmersiveMoodles",
    "ImmersiveSearching", "ItemConditionRestored", "KADropnLoot", "MapSymbolSizeSlider", "MaskFilterIndicator",
    "MaskaradsSummerCar", "POM", "SPNCC", "SkillRecoveryJournal", "ThisIsYourLife", "VIF_DualRender_B42",
    "WoundExpansion", "moodle_quarters", "nm_nested_containers", "traitsAsSkills",
}) do SA.SUPPORTED[id] = true end
function SA.support(id) if id then SA.SUPPORTED[tostring(id):gsub("^\\", "")] = true end end

-- each screen's main class and its core functions: a whole-screen takeover replaces ALL of them (only screens with
-- a ZeD setup switch: their names are SafeMode's and Settings.lua's). The watch and the moodles are the game's Java:
-- no Lua to replace.
SA.CORE = {
    windows = { "ISInventoryPage", { "createChildren", "prerender", "render" } },
    belt = { "ISHotbar", { "render", "update", "refresh" } },
    charinfo = { "ISCharacterInfoWindow", { "createChildren", "render" } },
    dashboard = { "ISVehicleDashboard", { "createChildren", "prerender", "render" } },
    wheels = { "ISRadialMenu", { "new", "instantiate" } },   -- (the wheel itself is the game's Java)
}
SA.ORDER = { "windows", "belt", "charinfo", "dashboard", "wheels" }

-- (every function in CORE is one the game's own media/lua defines, checked against 42.21's files: a mod giving a
-- class a function the game never had stops nothing of the game's. The list is fixed rather than read as ZeD
-- loads, since a mod loaded before ZeD has already replaced them by then.)

-- the Character Info window's own pages: the game's name key -> its class (read when checked)
local PAGES = {
    { "IGUI_XP_Info", "ISCharacterScreen" },
    { "IGUI_XP_Skills", "ISCharacterInfo" },
    { "IGUI_XP_Health", "ISHealthPanel" },
    { "IGUI_XP_Protection", "ISCharacterProtection" },
    { "IGUI_XP_ClothingIns", "ISClothingInsPanel" },
}

local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end
local function bare(id) return (tostring(id or ""):gsub("^\\", "")) end

-- ---------------------------------------------------------------------------
-- the mods: id, name, folder, place in the load order
-- ---------------------------------------------------------------------------
local function slash(p) return (tostring(p or ""):gsub("\\", "/")) end

local function readMods()
    local mods, zedAt = {}, nil
    local list = safe(function() return getActivatedMods() end)
    local n = list and safe(function() return list:size() end) or 0
    for i = 0, n - 1 do
        local raw = list:get(i)
        local id = bare(raw)
        local mi = safe(function() return getModInfoByID(raw) end)
        local dir = mi and safe(function() return mi:getDir() end)
        local m = {
            id = id, raw = raw, at = i,
            name = tostring(mi and safe(function() return mi:getName() end) or id),
            dir = dir and slash(dir):lower():gsub("/+$", "") or nil,
            key = mi and safe(function() return mi:getId() end) or raw,
        }
        mods[#mods + 1] = m
        if id == ZED_ID then zedAt = i end
    end
    return mods, zedAt
end

-- the mod a file belongs to (the longest folder that holds it), or nil (the game's own files)
local function ownerOf(mods, path)
    local p = slash(path):lower()
    local best
    for _, m in ipairs(mods) do
        if m.dir and p:sub(1, #m.dir + 1) == m.dir .. "/" and (not best or #m.dir > #best.dir) then best = m end
    end
    if best then return best end
    -- (a path given another way: the folder under mods/ by name)
    local folder = p:match("/mods/([^/]+)/")
    if not folder then return nil end
    for _, m in ipairs(mods) do
        if m.dir and m.dir:match("([^/]+)$") == folder then return m end
    end
    return nil
end

-- the file a Lua function was written in (a Java function has none)
local function fileOf(fn)
    if type(fn) ~= "function" then return nil end
    if instanceof and not safe(instanceof, fn, "LuaClosure") then return nil end
    if not getFilenameOfClosure then return nil end
    return safe(getFilenameOfClosure, fn)
end

-- ---------------------------------------------------------------------------
-- reading a mod's file: does the new function call the one it replaced?
-- ---------------------------------------------------------------------------
local fileCache = {}
local function readModFile(m, path)
    local p = slash(path)
    -- (the "/media/" after the mod's own folder: a Steam library can sit in a folder called Media,
    -- "D:/Media/SteamLibrary/...", or under /run/media/ on a Steam Deck). The search starts after the
    -- mod's folder when the path begins with it, else after the folder under mods/ that ownerOf matched
    -- by name (the path given another way: the mod's folder length means nothing in it)
    local lp = p:lower()
    local from = 1
    if m.dir and lp:sub(1, #m.dir + 1) == m.dir .. "/" then
        from = #m.dir + 1
    else
        local folder = m.dir and m.dir:match("([^/]+)$")
        if folder then
            local _, e = lp:find("/mods/" .. folder .. "/", 1, true)
            if e then from = e end
        end
    end
    local at = lp:find("/media/", from, true)
    if not at then return nil end
    local rel = p:sub(at + 1)
    local ck = tostring(m.key) .. "|" .. rel
    if fileCache[ck] ~= nil then return fileCache[ck] or nil end
    local lines = {}
    local ok = pcall(function()
        local r = getModFileReader(m.key, rel, false)
        if not r then error("no file") end
        local l = r:readLine()
        while l do lines[#lines + 1] = l; l = r:readLine() end
        r:close()
    end)
    if not ok or #lines == 0 then fileCache[ck] = false; return nil end
    fileCache[ck] = lines
    return lines
end

-- comments and string contents blanked (newlines kept), so "end" in a string does not count
local function blank(src)
    local out, i, n = {}, 1, #src
    while i <= n do
        local c = src:sub(i, i)
        if c == "-" and src:sub(i, i + 1) == "--" then
            local eq = src:match("^%[(=*)%[", i + 2)
            local stop
            if eq then
                local _, e = src:find("]" .. eq .. "]", i + 4 + #eq, true)
                stop = e or n
            else
                stop = (src:find("\n", i, true) or (n + 1)) - 1
            end
            out[#out + 1] = (src:sub(i, stop):gsub("[^\n]", " "))
            i = stop + 1
        elseif c == "[" and src:match("^%[=*%[", i) then
            local eq = src:match("^%[(=*)%[", i)
            local _, e = src:find("]" .. eq .. "]", i + 2 + #eq, true)
            e = e or n
            out[#out + 1] = (src:sub(i, e):gsub("[^\n]", " "))
            i = e + 1
        elseif c == '"' or c == "'" then
            local j = i + 1
            while j <= n do
                local d = src:sub(j, j)
                if d == "\\" then j = j + 2
                elseif d == c or d == "\n" then break
                else j = j + 1 end
            end
            out[#out + 1] = c .. string.rep(" ", math.max(0, math.min(j, n) - i - 1)) .. c
            i = j + 1
        else
            local j = src:find("[%-%[\"']", i) or (n + 1)
            if j == i then j = i + 1 end
            out[#out + 1] = src:sub(i, j - 1)
            i = j
        end
    end
    return table.concat(out)
end

local function esc(s) return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")) end
local function wordAt(s, i) local c = s:sub(i, i); return c ~= "" and c:find("[%w_]") ~= nil end

-- the next place pat matches at init or after with no letter, digit or underscore (or, with dot, ".") just
-- before it, and none just after its end when tight is set (Kahlua has no %f)
local function findWord(s, pat, init, dot, tight)
    local i = init or 1
    while true do
        local a, b = s:find(pat, i)
        if not a then return nil end
        local pc = s:sub(a - 1, a - 1)
        local okBefore = a == 1 or not (pc:find("[%w_]") or (dot and pc == "."))
        if okBefore and not (tight and wordAt(s, b + 1)) then return a, b end
        i = a + 1
    end
end

-- the body of cls.method's definition that starts at (or just before) line `first`: from its "function" keyword to
-- its "end". Only a "function" keyword that belongs to the definition itself (function Cls:method( or
-- Cls.method = function), so an inline function in its first statement is never taken for it; none found: nil
local function bodyAt(text, lineStarts, first, cls, method)
    local from = lineStarts[math.max(1, first - 3)] or 1
    local to = lineStarts[first + 2] or (#text + 1)
    local ref = esc(cls) .. "%s*[%.:]%s*" .. esc(method)
    local kw
    local s = from
    while true do
        local a, b = findWord(text, ref, s, true, true)
        if not a or a >= to then break end
        s = b + 1
        local pre = text:sub(math.max(1, a - 30), a - 1)
        local fa = pre:find("function%s+$")
        if fa then
            kw = a - #pre + fa - 1
        else
            local x, y = text:find("^%s*=%s*function", b + 1)
            if x then kw = y - 7 end
        end
    end
    if not kw then return nil end
    local depth, pos = 0, kw
    while true do
        local a, b, w = text:find("([%a_][%w_]*)", pos)
        if not a then return nil end
        if w == "function" or w == "if" or w == "do" or w == "repeat" then depth = depth + 1
        elseif w == "end" or w == "until" then
            depth = depth - 1
            if depth == 0 then return text:sub(kw, b) end
        end
        pos = b + 1
    end
end

-- true: it calls through (or this cannot tell); false: it never calls the function it replaced
local function callsThrough(lines, first, cls, method)
    -- (a file read once is blanked once: kept on its lines)
    if not lines._text then
        lines._raw = table.concat(lines, "\n")
        lines._text = blank(lines._raw)
        local starts, p = { 1 }, 1
        while true do
            local a = lines._text:find("\n", p, true)
            if not a then break end
            starts[#starts + 1] = a + 1
            p = a + 1
        end
        lines._starts = starts
    end
    local raw, text, starts = lines._raw, lines._text, lines._starts
    local body = bodyAt(text, starts, first or 1, cls, method)
    if not body then return true end   -- (a hook library, a definition this reading cannot find: unsure)
    -- a dynamic name (Class[name] = ...) or a helper this reading cannot follow: unsure
    if findWord(raw, esc(cls) .. "%s*%[", 1, true) then return true end
    -- the names a copy of the old function was kept under: X = Class.method
    local names = {}
    local ref = esc(cls) .. "%s*[%.:]%s*" .. esc(method)
    local s = 1
    while true do
        local a, b = findWord(text, ref, s, true, true)
        if not a then break end
        s = b + 1
        local before = text:sub(math.max(1, a - 200), a - 1)
        local after = text:sub(b + 1, b + 40)
        local written = after:find("^%s*=[^=]") or after:find("^%s*%(") or before:find("function%s*$")
        if not written then
            local lhs = before:match("([%a_][%w_%.]*)%s*=%s*$")
            if lhs then names[#names + 1] = lhs
            else return true end   -- read some other way (passed on, compared, a list of two): unsure
        end
    end
    for _, nm in ipairs(names) do
        -- (called as it was kept, or by its last part after a dot: hooks.render(self) for render = X.render)
        local last = nm:match("([%a_][%w_]*)$")
        if findWord(body, esc(nm) .. "%s*%(", 1, false) or body:find("pcall%s*%(%s*" .. esc(nm) .. "%s*[,%)]")
            or (last and body:find("%." .. esc(last) .. "%s*%(")) then return true end
    end
    -- a helper's wrapper: the old function came in by another name
    for w in body:gmatch("([%a_][%w_]*)%s*%(") do
        local lw = w:lower()
        if lw:find("orig") or lw:find("^old") or lw:find("prev") or lw:find("super") or lw:find("^base") or lw:find("wrapped")
            or lw:find("vanilla") or lw == "og" or lw:find("^og_") or lw:find("_og$") or lw:find("default")
            or lw == "_" .. method:lower() then
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- detection
-- ---------------------------------------------------------------------------
-- the mod behind a function, when it counts: any mod, before or after ZeD in the load order, not supported, not ZeD.
-- The game's own files sit in no mod's folder, so they never count.
local function counts(mods, zedAt, path)
    if not path or not zedAt then return nil end
    local m = ownerOf(mods, path)
    if not m or m.id == ZED_ID or SA.SUPPORTED[m.id] then return nil end
    return m
end

-- true when cls.method is now a function from a counted mod that never calls the one it replaced; also the mod
local function replacedBy(cls, method, mods, zedAt)
    local c = _G[cls]
    if type(c) ~= "table" then return false end
    local fn = rawget(c, method)
    local path = fileOf(fn)
    local m = counts(mods, zedAt, path)
    if not m then return false end
    local lines = readModFile(m, path)
    local first = getFirstLineOfClosure and safe(getFirstLineOfClosure, fn) or nil
    if lines and first and not callsThrough(lines, first, cls, method) then return true, m end
    return false
end
-- (the test sim's way in to the reading of one function, step_aside_sim.lua)
function SA._replaced(cls, method)
    local mods, zedAt = readMods()
    return (replacedBy(cls, method, mods, zedAt))
end

-- the screen's main class with EVERY core function replaced by one mod: that mod; fewer: nil, and a line in console.txt
SA.partial = SA.partial or {}
local function checkFunctions(screen, mods, zedAt)
    local core = SA.CORE[screen]
    if not core then return nil end
    local owner, n, hit = nil, 0, {}
    for _, method in ipairs(core[2]) do
        local r, m = replacedBy(core[1], method, mods, zedAt)
        if r then
            n = n + 1
            hit[#hit + 1] = method
            if owner and owner ~= m then owner = false elseif owner == nil then owner = m end
        end
    end
    if n == #core[2] and owner then return owner, core[1] .. ":" .. table.concat(hit, "+") end
    if n > 0 then
        local line = "[ZeD] Step aside: partial, " .. core[1] .. ":" .. table.concat(hit, "+") .. " replaced by "
            .. tostring(owner and owner.id or "more than one mod") .. "; " .. screen .. " kept as ZeD's"
        SA.partial[screen] = line
        print(line)
    end
    return nil
end

-- the first function of the view's own class (and up its parents) that a counted mod wrote
local function viewOwner(view, mods, zedAt)
    local mt, hops = getmetatable(view), 0
    while type(mt) == "table" and hops < 6 do
        for _, v in pairs(mt) do
            if type(v) == "function" then
                local m = counts(mods, zedAt, fileOf(v))
                if m then return m end
            end
        end
        mt, hops = getmetatable(mt), hops + 1
    end
    return nil
end

local function isA(view, cls)
    local mt, hops = getmetatable(view), 0
    while type(mt) == "table" and hops < 12 do
        if mt == cls then return true end
        mt, hops = getmetatable(mt), hops + 1
    end
    return false
end

-- a page of the game's Character Info window holding another mod's view under the game's own name
local function checkPages(mods, zedAt)
    if not getPlayerInfoPanel then return nil end
    for n = 0, 3 do
        local w = safe(getPlayerInfoPanel, n)
        local list = w and w.panel and w.panel.viewList
        if type(list) == "table" then
            for _, pg in ipairs(PAGES) do
                local name = getText(pg[1])
                local cls = _G[pg[2]]
                for _, v in ipairs(list) do
                    if v.name == name and type(v.view) == "table" and type(cls) == "table" and not isA(v.view, cls) then
                        local m = viewOwner(v.view, mods, zedAt)
                        if m then return m, pg[1] end
                    end
                end
            end
        end
    end
    return nil
end

function SA.detect()
    local mods, zedAt = readMods()
    fileCache = {}
    local found = {}
    if not zedAt then return found, mods end
    for _, screen in ipairs(SA.ORDER) do
        local m, why
        if screen == "charinfo" then m, why = checkPages(mods, zedAt) end
        if not m then m, why = checkFunctions(screen, mods, zedAt) end
        if m then found[screen] = { id = m.id, name = m.name, why = why } end
    end
    return found, mods
end

-- ---------------------------------------------------------------------------
-- the record: the mod set, the screens handed back (by whom), the screens taken back
-- ---------------------------------------------------------------------------
local rec = nil
local function signature(mods)
    local ids = {}
    for _, m in ipairs(mods) do ids[#ids + 1] = m.id end
    return table.concat(ids, ",")
end

local function load()
    rec = { mods = nil, set = {}, kept = {} }
    local r = safe(function() return getFileReader(FILE, false) end)
    if not r then return rec end
    pcall(function()
        local l = r:readLine()
        while l do
            local k, v = l:match("^(%a+)=(.*)$")
            if k == "mods" then rec.mods = v
            elseif k == "set" then
                local sc, id, name = v:match("^([^|]+)|([^|]*)|(.*)$")
                if sc then rec.set[sc] = { id = id, name = name } end
            elseif k == "kept" then
                local sc, id = v:match("^([^|]+)|(.*)$")
                if sc then rec.kept[sc] = id end
            end
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
    return rec
end
local function save()
    local lines = { "ZeD-GUI: screens handed back to a mod that took them (set), and taken back by the player (kept)\r\n" }
    lines[#lines + 1] = "mods=" .. tostring(rec.mods or "") .. "\r\n"
    for _, sc in ipairs(SA.ORDER) do
        local s = rec.set[sc]
        if s then lines[#lines + 1] = "set=" .. sc .. "|" .. tostring(s.id) .. "|" .. tostring(s.name) .. "\r\n" end
        if rec.kept[sc] then lines[#lines + 1] = "kept=" .. sc .. "|" .. tostring(rec.kept[sc]) .. "\r\n" end
    end
    local w = safe(function() return getFileWriter(FILE, true, false) end)
    if not w then return end
    pcall(function() w:write(table.concat(lines)) end)
    pcall(function() w:close() end)
end
function SA.record() return rec or load() end
function SA.reload() return load() end

-- ---------------------------------------------------------------------------
-- the switches (Settings.lua: item 1 Off, ZeD's; item 2 On, the game's own)
-- ---------------------------------------------------------------------------
local function option(screen)
    local so = ZeD.Settings and ZeD.Settings.screenOptions
    return so and so[screen]
end
local function isOn(screen)
    local o = option(screen)
    if not o then return nil end
    return safe(o.getValue, o) == 2
end
local function setOn(screen, on)
    local o = option(screen)
    if not o then return false end
    pcall(o.setValue, o, on and 2 or 1)
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.save then pcall(PZAPI.ModOptions.save, PZAPI.ModOptions) end
    if ZeD.Safe.reread then ZeD.Safe.reread() end
    return true
end

local SCREEN_WORD = {
    windows = "UI_ZeD_StepAside_Windows", belt = "UI_ZeD_StepAside_Belt", charinfo = "UI_ZeD_StepAside_CharInfo",
    dashboard = "UI_ZeD_StepAside_Dashboard", wheels = "UI_ZeD_StepAside_Wheels",
}

local function notify(screen, name)
    local M = ZeD.Messages
    local text = ZeD.tr("UI_ZeD_StepAside_Note", name, ZeD.tr(SCREEN_WORD[screen]))
    print("[ZeD] Step aside: " .. tostring(name) .. " took " .. screen .. "; handed back to the game")
    if M and M.notice then pcall(M.notice, ZeD.tr("UI_ZeD_StepAside_Head"), text) end
    SA.lastNote = text
end

-- the player unticked a screen ZeD had handed back: ZeD's again, while that same mod is the one taking it
local function noteTakenBack()
    local changed = false
    for sc, s in pairs(rec.set) do
        if isOn(sc) == false then
            rec.kept[sc] = s.id
            rec.set[sc] = nil
            changed = true
            print("[ZeD] Step aside: " .. sc .. " taken back from " .. tostring(s.id) .. " by the player")
        end
    end
    return changed
end

function SA.check()
    if not rec then load() end
    local found, mods = SA.detect()
    noteTakenBack()
    rec.mods = signature(mods)
    for sc, s in pairs(rec.set) do
        local f = found[sc]
        -- a screen whose mod no longer takes it is ZeD's again
        if not (f and f.id == s.id) then
            if isOn(sc) then setOn(sc, false) end
            rec.set[sc] = nil
        end
    end
    -- a take-back holds while that same mod is the one taking the screen (other mods coming and going change nothing)
    for sc, id in pairs(rec.kept) do
        if not (found[sc] and found[sc].id == id) then rec.kept[sc] = nil end
    end
    SA.found = found
    for _, sc in ipairs(SA.ORDER) do
        local f = found[sc]
        if f and rec.kept[sc] ~= f.id and not rec.set[sc] and isOn(sc) == false then
            if setOn(sc, true) then
                rec.set[sc] = { id = f.id, name = f.name }
                notify(sc, f.name)
            end
        end
    end
    save()
    return found
end

--- ZeD setup's line under a screen's switch while a mod has it ("Taken by <mod>"), else nil
function SA.underFor(screen)
    if not rec then load() end
    local s = rec.set[screen]
    if s and isOn(screen) ~= false then return ZeD.tr("UI_ZeD_StepAside_Under", s.name) end
    return nil
end

-- ---------------------------------------------------------------------------
-- when: a game's start, once the game's windows are built (the Character Info
-- window is made for the player a few ticks in); then a look every second for a
-- switch the player unticked
-- ---------------------------------------------------------------------------
local wait, poll = 0, 0
local function tick()
    if wait > 0 then
        wait = wait - 1
        local ready = getPlayerInfoPanel and safe(getPlayerInfoPanel, 0)
        if wait == 0 or (ready and wait < 270) then
            wait = 0
            pcall(SA.check)
        end
        return
    end
    poll = poll + 1
    if poll < 60 then return end
    poll = 0
    if rec and hasAny(rec.set) and noteTakenBack() then save() end
end
if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(function() wait = 300 end) end
    if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(tick)
    elseif Events.OnTick then Events.OnTick.Add(tick) end
    -- (the main menu: ZeD setup's lines read the record as it is on disk)
    if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(function() load() end) end
end

return SA
