-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModFolders.lua
-- ============================================================================
-- MOD FOLDERS: Zomboid/Lua/ModFolders.cfg, the file of the [B42]Mod Folders
-- mod (Workshop 3779201168), read and written in its own format. Client-side.
-- Nothing drawn here: ZeD_MainMenuModsFolders.lua draws.
--
-- The file is kept as its lines. A line ZeD does not change is written back exactly as it was
-- read (its own text), so an unchanged file round-trips byte for byte, and every line ZeD does
-- not understand stays where it was (the mod itself drops them; ZeD never does). A line ZeD
-- changes is written in the mod's own form:
--   version=2
--   next=<n>                        the number the next new folder gets (never reused)
--   folder=<id>|<1 open, 0 closed>|<name, encoded>      folder order = the order of these lines
--   member=<mod id, encoded>|<folder id>                 one mod in one folder (the last line wins)
-- Encoding (version 2): each UTF-16 unit as upper-case hex without padding, joined by commas
-- (Kahlua's string.byte gives the unit): "Cars" is 43,61,72,73. Version 1 (%-escapes) is read
-- as the mod reads it; the first change rewrites the file as version 2, as the mod does.
--
-- Every change reads the file again, applies the one change to what is there now and writes
-- it: an edit made outside the game while the screen was open is kept, never clobbered.
-- ZeD writes only when the player changes folders.
-- ============================================================================

ZeD = ZeD or {}
ZeD.ModFolders = ZeD.ModFolders or {}
local F = ZeD.ModFolders

F.FILE = F.FILE or "ModFolders.cfg"
F.MAX = 99                 -- Mod Folders' own limit (it refuses the 100th; it still reads more)
F.NAME_MAX = 48            -- typing stops here; longer names from the file stay
F.gen = F.gen or 0         -- counts every load and change (the screen's caches key on it)
F.cur = F.cur or nil       -- the file as last read or written

local EMPTY = {}
-- (Unfiled's open state, ZeD's own: read with the file, kept at the end of this file)
local uiState = nil

-- ----------------------------------------------------------------------------
-- ENCODING
-- ----------------------------------------------------------------------------
function F.encode(s)
    s = tostring(s or "")
    local out = {}
    for i = 1, #s do out[i] = string.format("%X", string.byte(s, i)) end
    return table.concat(out, ",")
end

function F.decodeV2(v)
    local out = {}
    for hex in tostring(v or ""):gmatch("([%x]+)") do
        local code = tonumber(hex, 16)
        if code then out[#out + 1] = string.char(code) end
    end
    return table.concat(out)
end

-- (the mod's own version 1 reader: %XX, and %XXXX for a code above 255)
local function v1Escaped(code)
    if code >= 48 and code <= 57 then return false end
    if code >= 65 and code <= 90 then return false end
    if code >= 97 and code <= 122 then return false end
    if code == 45 or code == 46 or code == 95 or code == 126 then return false end
    return true
end

function F.decodeV1(v)
    v = tostring(v or "")
    local out = {}
    local i = 1
    while i <= #v do
        local c = v:sub(i, i)
        if c ~= "%" then
            out[#out + 1] = c
            i = i + 1
        else
            local pairCode = tonumber(v:sub(i + 1, i + 2), 16)
            if not pairCode then
                out[#out + 1] = "%"
                i = i + 1
            else
                local quad = v:sub(i + 1, i + 4)
                local quadCode = (#quad == 4 and quad:match("^%x%x%x%x$") and tonumber(quad, 16)) or nil
                local useQuad = false
                if quadCode and quadCode > 255 then
                    if not v1Escaped(pairCode) then useQuad = true
                    else
                        local after = v:sub(i + 5, i + 5)
                        if after == "" or after == "%" then useQuad = true end
                    end
                end
                if useQuad then out[#out + 1] = string.char(quadCode); i = i + 5
                else out[#out + 1] = string.char(pairCode); i = i + 3 end
            end
        end
    end
    return table.concat(out)
end

-- ----------------------------------------------------------------------------
-- THE MODEL: the file's lines, and what they say
-- ----------------------------------------------------------------------------
-- M.lines: { raw = the line as read, k = "version" | "next" | "folder" | "member" | "other",
--            dirty = true when ZeD changed it (written in the mod's form, not raw) }
-- M.folders: the folder lines in file order { id, open, name, e = its line }
-- M.member[modId] = folder id (the last member line wins, as in the mod)

local function folderLine(e) return "folder=" .. tostring(e.id) .. "|" .. (e.open and "1" or "0") .. "|" .. F.encode(e.name) end
local function memberLine(e) return "member=" .. F.encode(e.mod) .. "|" .. tostring(e.fid) end

-- the model's lists, worked out again from its lines (after a change that adds or drops lines)
local function index(M)
    M.folders, M.byId, M.member, M.memberE = {}, {}, {}, {}
    M.versionE, M.nextE = nil, nil
    local maxId = 0
    for _, e in ipairs(M.lines) do
        if e.k == "version" and not M.versionE then M.versionE = e
        elseif e.k == "next" then M.nextE = e
        elseif e.k == "folder" then
            M.folders[#M.folders + 1] = e
            if not M.byId[e.id] then M.byId[e.id] = e end
            if e.id > maxId then maxId = e.id end
        elseif e.k == "member" then
            M.member[e.mod] = e.fid
            M.memberE[e.mod] = e
        end
    end
    local n = M.nextE and M.nextE.n or 1
    if n < 1 then n = 1 end
    if n <= maxId then n = maxId + 1 end
    M.nextId = n
end

-- lines (strings, as getFileReader's readLine gives them) to a model
function F.parse(lines)
    local M = { lines = {}, version = 1, bad = 0, exists = lines ~= nil }
    lines = lines or EMPTY
    for _, l in ipairs(lines) do
        local v = l:match("^version=(%d+)$")
        if v then M.version = tonumber(v) or 1; break end
    end
    local decode = M.version >= 2 and F.decodeV2 or F.decodeV1
    local seenVersion = false
    for _, l in ipairs(lines) do
        local e = { raw = l, k = "other" }
        local v = l:match("^version=(%d+)$")
        local nx = (not v) and l:match("^next=(%d+)$") or nil
        if v then
            -- (a second version line is kept as it is, not read)
            if not seenVersion then e.k = "version"; seenVersion = true end
        elseif nx then
            e.k, e.n = "next", tonumber(nx) or 1
        else
            local id, open, name = l:match("^folder=(%d+)|([01])|(.*)$")
            if id then
                e.k, e.id, e.open, e.name = "folder", tonumber(id), open == "1", decode(name)
            else
                local mod, fid = l:match("^member=(.-)|(%d+)$")
                if mod and fid then
                    e.k, e.mod, e.fid = "member", decode(mod), tonumber(fid)
                elseif l:match("%S") then
                    M.bad = M.bad + 1
                end
            end
        end
        M.lines[#M.lines + 1] = e
    end
    index(M)
    return M
end

-- the model to lines: each line as read unless ZeD changed it; a version 1 file is rewritten as
-- version 2 (the mod does the same on its next load)
function F.lines(M)
    local out = {}
    for i, e in ipairs(M.lines) do
        if e.dirty or (M.v2 and (e.k == "folder" or e.k == "member")) then
            if e.k == "folder" then out[i] = folderLine(e)
            elseif e.k == "member" then out[i] = memberLine(e)
            elseif e.k == "next" then out[i] = "next=" .. tostring(e.n)
            elseif e.k == "version" then out[i] = "version=2"
            else out[i] = e.raw end
        else
            out[i] = e.raw
        end
    end
    return out
end

-- ----------------------------------------------------------------------------
-- THE FILE
-- ----------------------------------------------------------------------------
-- the file's lines (nil: there is none)
function F.readLines(file)
    local r = nil
    pcall(function() r = getFileReader(file or F.FILE, false) end)
    if not r then return nil end
    local t = {}
    local ok = pcall(function()
        local l = r:readLine()
        while l ~= nil do t[#t + 1] = l; l = r:readLine() end
    end)
    pcall(function() r:close() end)
    if not ok then return nil end
    return t
end

-- The writer cuts a file the moment it opens and Lua has no rename, so the other mod's file is not
-- opened until ZeD's own spare has held the same text: a disk that cannot hold it stops there, with
-- their file as it was. (Emptied after; one left full is the text of a write that did not finish.)
local SPARE = "ZeD_modfolders_spare.txt"

-- the text in the file, in one write, and read back: n lines
local function putText(file, text, n)
    local w = nil
    pcall(function() w = getFileWriter(file, true, false) end)
    if not w then return false end
    local ok = pcall(function() w:write(text) end)
    pcall(function() w:close() end)
    if not ok then return false end
    local back = F.readLines(file)
    return back ~= nil and #back == n
end

-- writes lines, each ended by "\n" as the mod writes them; true when written
function F.writeLines(lines, file)
    local text = (#lines > 0) and (table.concat(lines, "\n") .. "\n") or ""
    if file then return putText(file, text, #lines) end
    if not putText(SPARE, text, #lines) then return false end
    if not putText(F.FILE, text, #lines) then return false end
    putText(SPARE, "", 0)
    return true
end

function F.read() return F.parse(F.readLines()) end

-- the file read afresh (the Mods page opening), so outside edits show
function F.load()
    F.cur = F.read()
    uiState = nil
    F.gen = F.gen + 1
    return F.cur
end

function F.get()
    if not F.cur then F.load() end
    return F.cur
end

-- ----------------------------------------------------------------------------
-- WHAT THE SCREEN ASKS
-- ----------------------------------------------------------------------------
function F.any() local M = F.get(); return #M.folders > 0 end
function F.folders() return F.get().folders end
function F.byId(id) return F.get().byId[id] end

-- the folder a mod is in (nil: none, or its folder is gone: it shows under Unfiled)
function F.folderOf(modId)
    local M = F.get()
    local fid = M.member[modId]
    if fid and M.byId[fid] then return fid end
    return nil
end

-- the mod ids the file puts in folder fid (installed or not)
function F.membersOf(fid)
    local M = F.get()
    local t = {}
    for _, e in ipairs(M.lines) do
        if e.k == "member" and e.fid == fid and M.memberE[e.mod] == e then t[#t + 1] = e.mod end
    end
    return t
end

local function trim(s)
    s = tostring(s or "")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
F.trim = trim

-- what is wrong with a name (nil: it can be used): a translation key and its argument
function F.nameProblem(name, exceptId, M)
    M = M or F.get()
    name = trim(name)
    if name == "" then return "UI_ZeD_Folders_NameEmpty", nil end
    local low = string.lower(name)
    for _, f in ipairs(M.folders) do
        if f.id ~= exceptId and string.lower(f.name) == low then return "UI_ZeD_Folders_NameUsed", f.name end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- CHANGES: each one reads the file again, changes what is there now, writes it
-- ----------------------------------------------------------------------------
-- the version and next lines, added at the top when the file has none
local function ensureHead(M)
    if not M.versionE then
        local e = { k = "version", raw = "version=2", dirty = true }
        table.insert(M.lines, 1, e)
        M.versionE = e
    end
    if not M.nextE then
        local at = 1
        for i, e in ipairs(M.lines) do if e == M.versionE then at = i + 1 end end
        local e = { k = "next", n = M.nextId, dirty = true }
        table.insert(M.lines, at, e)
        M.nextE = e
    end
end

-- fn(M) changes the fresh model and returns its result (false: nothing to write).
-- Returns ok (written), the result. A file that cannot be written changes nothing on screen.
function F.change(fn)
    local M = F.read()
    local okFn, res = pcall(fn, M)
    if not okFn then print("[ZeD] ModFolders change failed: " .. tostring(res)); return false, nil end
    if res == false then return false, nil end
    if M.version < 2 then
        -- (a version 1 file: every folder and member line is rewritten in version 2's encoding)
        M.v2 = true
        ensureHead(M)
        M.versionE.dirty = true
    end
    if not F.writeLines(F.lines(M)) then return false, "nowrite" end
    M.version, M.v2 = 2, nil
    F.cur = M
    F.gen = F.gen + 1
    return true, res
end

-- the place after the last line of kind k (0: none)
local function lastOf(M, k)
    local at = 0
    for i, e in ipairs(M.lines) do if e.k == k then at = i end end
    return at
end

-- lines inserted after place `at` in one pass (a move of 200 mods is one write)
local function insertAfter(M, at, list)
    if #list == 0 then return end
    local out = {}
    if at == 0 then for _, e in ipairs(list) do out[#out + 1] = e end end
    for i, e in ipairs(M.lines) do
        out[#out + 1] = e
        if i == at then for _, n in ipairs(list) do out[#out + 1] = n end end
    end
    M.lines = out
end

-- a new folder at the end of the folders, open, empty: its id, or false
function F.create(name)
    name = trim(name)
    if #name > F.NAME_MAX then name = string.sub(name, 1, F.NAME_MAX) end
    return F.change(function(M)
        if #M.folders >= F.MAX then return false end
        if F.nameProblem(name, nil, M) then return false end
        ensureHead(M)
        local id = M.nextId
        local e = { k = "folder", id = id, open = true, name = name, dirty = true }
        local at = lastOf(M, "folder")
        if at == 0 then at = lastOf(M, "next") end
        insertAfter(M, at, { e })
        M.nextE.n, M.nextE.dirty = id + 1, true
        index(M)
        return id
    end)
end

function F.rename(id, name)
    name = trim(name)
    if #name > F.NAME_MAX then name = string.sub(name, 1, F.NAME_MAX) end
    return F.change(function(M)
        local e = M.byId[id]
        if not e or F.nameProblem(name, id, M) then return false end
        if e.name == name then return false end
        e.name, e.dirty = name, true
        return id
    end)
end

-- the folder goes; its mods go to Unfiled (their member lines go, as in the mod); none turn off
function F.delete(id)
    return F.change(function(M)
        if not M.byId[id] then return false end
        local out = {}
        for _, e in ipairs(M.lines) do
            if not ((e.k == "folder" and e.id == id) or (e.k == "member" and e.fid == id)) then out[#out + 1] = e end
        end
        M.lines = out
        index(M)
        return id
    end)
end

-- open (true) or closed (false), saved as the mod saves it
function F.setOpen(id, open)
    return F.change(function(M)
        local e = M.byId[id]
        if not e or e.open == (open and true or false) then return false end
        e.open, e.dirty = open and true or false, true
        return id
    end)
end

-- every folder open or closed (Open all / Close all)
function F.setAllOpen(open)
    return F.change(function(M)
        local any = false
        for _, e in ipairs(M.folders) do
            if e.open ~= open then e.open, e.dirty, any = open, true, true end
        end
        if not any then return false end
        return true
    end)
end

-- one place up (-1) or down (1) among the folders: the two folder lines change places, every
-- other line stays where it is
function F.moveFolder(id, delta)
    return F.change(function(M)
        local k = nil
        for i, e in ipairs(M.folders) do if e.id == id then k = i end end
        if not k then return false end
        local j = k + delta
        if j < 1 or j > #M.folders then return false end
        local a, b = M.folders[k], M.folders[j]
        local ia, ib
        for i, e in ipairs(M.lines) do
            if e == a then ia = i elseif e == b then ib = i end
        end
        M.lines[ia], M.lines[ib] = b, a
        index(M)
        return id
    end)
end

-- mods into folder fid (nil: out of their folder, to Unfiled). A mod is in one folder
-- at most. Returns ok, the count moved; "gone" when the folder is gone
function F.assign(modIds, fid)
    local gone = false
    local ok, n = F.change(function(M)
        if fid and not M.byId[fid] then gone = true; return false end
        local want = {}
        for _, id in ipairs(modIds or EMPTY) do want[id] = true end
        local count = 0
        if fid == nil then
            local out = {}
            for _, e in ipairs(M.lines) do
                if e.k == "member" and want[e.mod] then
                    if M.memberE[e.mod] == e and M.byId[e.fid] then count = count + 1 end
                else out[#out + 1] = e end
            end
            if count == 0 then return false end
            M.lines = out
        else
            local new = {}
            local seen = {}
            for _, id in ipairs(modIds or EMPTY) do
                if not seen[id] then
                    seen[id] = true
                    local e = M.memberE[id]
                    if e then
                        if e.fid ~= fid then e.fid, e.dirty = fid, true; count = count + 1 end
                    else
                        new[#new + 1] = { k = "member", mod = id, fid = fid, dirty = true }
                        count = count + 1
                    end
                end
            end
            if count == 0 then return false end
            -- (new lines after the last member line, by mod id: one fixed order for what ZeD adds)
            local sort = ZeD.ModOrder and ZeD.ModOrder.sort
            if sort then sort(new, function(a, b) return a.mod < b.mod end) else table.sort(new, function(a, b) return a.mod < b.mod end) end
            local at = lastOf(M, "member")
            if at == 0 then at = lastOf(M, "folder") end
            insertAfter(M, at, new)
        end
        index(M)
        return count
    end)
    if gone then return false, "gone" end
    return ok, n
end

-- a not-installed mod's line taken out (the folder detail's remove): nothing else removes it
function F.dropMember(modId)
    return F.change(function(M)
        local out, any = {}, false
        for _, e in ipairs(M.lines) do
            if e.k == "member" and e.mod == modId then any = true else out[#out + 1] = e end
        end
        if not any then return false end
        M.lines = out
        index(M)
        return true
    end)
end

-- ----------------------------------------------------------------------------
-- UNFILED'S OPEN STATE AND THE FOLDERS' LABELS: ZeD's own (never in ModFolders.cfg, so the mod and
-- anything else that reads the file sees it as before), in Zomboid/Lua/ZeD_modfolders.txt:
--   unfiledOpen=<1 or 0>
--   label=<folder id>|<label key>     one per labelled folder (a label is one of ZeD's accent colours)
-- ----------------------------------------------------------------------------
local UI_FILE = "ZeD_modfolders.txt"

local function uiLoad()
    uiState = { unfiledOpen = true, labels = {} }
    local lines = F.readLines(UI_FILE)
    for _, l in ipairs(lines or EMPTY) do
        local v = l:match("^unfiledOpen=(%d)$")
        if v then uiState.unfiledOpen = v == "1" end
        local fid, lab = l:match("^label=([^|]+)|(%w+)$")
        if fid then uiState.labels[fid] = lab end
    end
end

-- the whole of ZeD's file, written again (labels in folder id order, so the file stays the same between writes)
local function uiWrite()
    local out = { "unfiledOpen=" .. (uiState.unfiledOpen and "1" or "0") }
    local ids = {}
    for fid in pairs(uiState.labels) do ids[#ids + 1] = fid end
    table.sort(ids)
    for _, fid in ipairs(ids) do out[#out + 1] = string.format("label=%s|%s", fid, uiState.labels[fid]) end
    F.writeLines(out, UI_FILE)
end

-- a folder's label key (nil: none)
function F.labelOf(fid)
    if fid == nil then return nil end
    if not uiState then uiLoad() end
    return uiState.labels[tostring(fid)]
end

-- sets or clears (nil) a folder's label, written at once
function F.setLabel(fid, key)
    if fid == nil then return end
    if not uiState then uiLoad() end
    uiState.labels[tostring(fid)] = key
    uiWrite()
    F.gen = F.gen + 1
end

function F.unfiledOpen()
    if not uiState then uiLoad() end
    return uiState.unfiledOpen
end

function F.setUnfiledOpen(open)
    if not uiState then uiLoad() end
    uiState.unfiledOpen = open and true or false
    uiWrite()
    F.gen = F.gen + 1
end
