-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Messages.lua
-- ============================================================================
-- MESSAGES — other mods' notes and errors, kept in one window (MESSAGES_SPEC.md;
-- director, Oct 24 2026: "notification center works for me"; mockup
-- ZeDUI/mockups/zed_messages_v1.html)
--
-- The store. A note (one OK button) that another mod opens with the game's own
-- dialog classes is caught here instead of covering the game: ZeD's prompt for
-- it (Overrides/Prompts.lua) is filed, never shown, and the Messages window
-- (ZeD_MessagesWindow.lua) presses its buttons, which still run the mod's
-- callback. A question still asks at once; its answer is copied here. The game's
-- own error list is read every two seconds and filed per mod. A toast says
-- what came (ZeD_MessagesWindow.lua draws it); the belt shows a paper note with
-- the count while anything is kept (ZeD_Belt.lua).
--
-- Who opened a pop-up: the nearest Lua file on the call stack that belongs to
-- another mod (the game's call-frame functions; the mod folder in its path).
-- The game itself and ZeD are never caught. Only in game, never in safe mode.
-- ============================================================================

require "ZeD/Tr"
ZeD = ZeD or {}
ZeD.Messages = ZeD.Messages or {}
local M = ZeD.Messages

M.sources = M.sources or {}    -- name -> { name, kind = "mods" | "err", items = { ... }, at = sequence }
M.toasts = M.toasts or {}      -- { kind = "warn" | "crit", head, text, source, untilMs }
M.seq = M.seq or 0             -- bumps on every change (the window and the belt re-read)
M.popups = M.popups or nil     -- mod name -> true: that mod's notes show as pop-ups (Zomboid/Lua/ZeD_messages.txt)

local FILE = "ZeD_messages.txt"
local TOAST_MS = 6000
local KEEP_ERRORS = 12          -- full error texts kept per mod (for the bug report); every one is counted

local function now() return getTimestampMs and getTimestampMs() or 0 end
local function bump() M.seq = M.seq + 1 end
local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end

-- ---------------------------------------------------------------------------
-- settings (Settings.lua: Messages) and the per-mod pop-up list
-- ---------------------------------------------------------------------------
local function catchOn()
    local S = ZeD.Settings
    if ZeD.Safe and ZeD.Safe.on() then return false end
    return not (S and S.messagesCatchOn) or S.messagesCatchOn()
end
local function toastOn()
    local S = ZeD.Settings
    return not (S and S.messagesToastOn) or S.messagesToastOn()
end

local function loadPopups()
    M.popups = {}
    local r = getFileReader(FILE, false)
    if not r then return end
    local l = r:readLine()
    while l do
        local name = l:match("^popup=(.+)$")
        if name then M.popups[name] = true end
        l = r:readLine()
    end
    r:close()
end
local function savePopups()
    local w = getFileWriter(FILE, true, false)
    if not w then return end
    w:write("ZeD-UI Messages: the mods whose notes still show as pop-ups\n")
    local names = {}
    for n in pairs(M.popups or {}) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do w:write("popup=" .. n .. "\n") end
    w:close()
end
function M.popupsFor(name)
    if not M.popups then loadPopups() end
    return M.popups[name] == true
end
function M.setPopups(name, on)
    if not M.popups then loadPopups() end
    M.popups[name] = on and true or nil
    savePopups()
    bump()
end

-- ---------------------------------------------------------------------------
-- who opened it: the mod folder on the call stack
-- ---------------------------------------------------------------------------
local function norm(p) return ("/" .. tostring(p or "")):gsub("\\", "/"):lower() end
local function rootOf(path)
    local p = norm(path)
    local a, b = p:find("/mods/[^/]+/")
    return a and p:sub(1, b) or nil
end
local roots, zedRoot = nil, nil
local function readRoots()
    roots = {}
    local list = safe(function() return getActivatedMods() end)
    for i = 0, (list and list:size() or 0) - 1 do
        local id = list:get(i)
        local mi = safe(function() return getModInfoByID(id) end)
        local dir = mi and safe(function() return mi:getDir() end)
        local root = dir and rootOf(tostring(dir) .. "/")
        if root then
            local name = safe(function() return mi:getName() end) or tostring(id)
            roots[root] = tostring(name)
            if tostring(id) == "ZeD_UI" then zedRoot = root end
        end
    end
end

-- the name of the other mod whose code is calling, or nil (the game, ZeD)
function M.caller()
    if M.qaSource then return M.qaSource end   -- QA: zedqa_messages.lua names a test source
    if not (getCurrentCoroutine and getCallframeTop and getCoroutineCallframeStack and getFilenameOfCallframe) then return nil end
    if not roots then readRoots() end
    local co = getCurrentCoroutine()
    if not co then return nil end
    local top = getCallframeTop(co) or 0
    for i = top - 1, 0, -1 do
        local cf = getCoroutineCallframeStack(co, i)
        local f = cf and safe(getFilenameOfCallframe, cf)
        local root = f and rootOf(f)
        if root and root ~= zedRoot then
            return roots[root] or (root:match("/mods/([^/]+)/$") or root)
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- the store
-- ---------------------------------------------------------------------------
local function source(name, kind)
    local s = M.sources[name]
    if not s then
        s = { name = name, kind = kind, items = {} }
        M.sources[name] = s
    end
    M.seq = M.seq + 1
    s.at = M.seq
    return s
end

local startedAt = nil
local function when()
    local gt = getGameTime and getGameTime()
    local t = ""
    if gt then
        local day = math.floor((safe(function() return gt:getWorldAgeHours() end) or 0) / 24) + 1
        local tod = safe(function() return gt:getTimeOfDay() end) or 0
        t = ZeD.tr("UI_ZeD_Msg_When", day, string.format("%d:%02d", math.floor(tod), math.floor((tod % 1) * 60)))
    end
    if startedAt and now() - startedAt < 60000 then t = t .. " | " .. ZeD.tr("UI_ZeD_Msg_AtStart") end
    return t
end

local function toast(kind, head, name, text)
    if not toastOn() then return end
    local t = { kind = kind, head = head, source = name, text = text, untilMs = now() + TOAST_MS }
    for i = #M.toasts, 1, -1 do if M.toasts[i].source == name and M.toasts[i].head == head then table.remove(M.toasts, i) end end
    M.toasts[#M.toasts + 1] = t
    while #M.toasts > 3 do table.remove(M.toasts, 1) end
end

function M.add(name, kind, item)
    local s = source(name, kind == "err" and "err" or "mods")
    item.read = false
    item.when = item.when or when()
    table.insert(s.items, 1, item)
    bump()
    return item
end

function M.unread()
    local n, err = 0, false
    for _, s in pairs(M.sources) do
        for _, it in ipairs(s.items) do
            if not it.read then n = n + 1; if s.kind == "err" then err = true end end
        end
    end
    return n, err
end
function M.count()
    local n = 0
    for _, s in pairs(M.sources) do n = n + #s.items end
    return n
end
-- the sources, mods first (newest first), then errors (newest first)
function M.list()
    local mods, errs = {}, {}
    for _, s in pairs(M.sources) do
        if #s.items > 0 then if s.kind == "err" then errs[#errs + 1] = s else mods[#mods + 1] = s end end
    end
    local by = function(a, b) return (a.at or 0) > (b.at or 0) end
    table.sort(mods, by); table.sort(errs, by)
    return mods, errs
end
function M.markRead(name)
    local s = M.sources[name]
    if not s then return end
    for _, it in ipairs(s.items) do it.read = true end
    bump()
end
function M.markAllRead()
    for _, s in pairs(M.sources) do for _, it in ipairs(s.items) do it.read = true end end
    bump()
end
function M.clear(name)
    local s = M.sources[name]
    if not s then return end
    -- a caught note nobody answered is answered OK as it leaves (the mod's callback runs once)
    for _, it in ipairs(s.items) do if it.prompt and not it.done then M.press(it, 1) end end
    M.sources[name] = nil
    bump()
end

-- ---------------------------------------------------------------------------
-- notes and questions (ZeD_Prompt calls these)
-- ---------------------------------------------------------------------------
local function promptText(p)
    return tostring(p.text or (p.chatText and p.chatText.text) or "")
end

-- would a note from this mod be kept now? (in game, the setting on, not one of its pop-up mods)
function M.wouldKeep(name)
    if not name or not getPlayer() or not catchOn() then return false end
    return not M.popupsFor(name)
end

-- a prompt about to show: catch it? (notes from another mod, in game, the setting on)
function M.wantsNote(p)
    if not p or not p._zedSource then return false end
    if not (p.kind == "note" or (p.kind == "rich" and not p.yesno)) then return false end
    return M.wouldKeep(p._zedSource)
end

local speedWatch = nil
local lastSpeed = 1   -- the game's speed when it last ran (frame() keeps it)
function M.catchNote(p)
    local name = p._zedSource
    local buttons = {}
    for _, b in ipairs(p:answers() or {}) do if b then buttons[#buttons + 1] = b end end
    M.add(name, "mods", { k = "note", prompt = p, rich = p.kind == "rich", text = promptText(p), buttons = buttons })
    toast("warn", ZeD.tr("UI_ZeD_Msg_ToastMod"), name, ZeD.tr("UI_ZeD_Msg_ToastNote"))
    -- a mod that pauses the game to show its note (Horse Mod does, right after addToUIManager):
    -- the note is kept, so the game runs on. Every kept note watches again (with several
    -- notes at game start, a later one's mod pauses after the first pause was undone)
    speedWatch = { speed = lastSpeed, frames = 3 }
    print("[ZeD] Messages: a note from " .. tostring(name) .. " kept in Messages")
end

-- an answered question from another mod: a copy, with its answer
function M.answered(p, button)
    if not (p and p._zedSource) or p._zedCaught then return end
    if p.kind == "note" or (p.kind == "rich" and not p.yesno) then return end
    if not getPlayer() then return end
    local it = M.add(p._zedSource, "mods", { k = "ask", text = promptText(p), rich = p.kind == "rich", answer = tostring(button and button.title or "") })
    it.read = true   -- (answered on screen: nothing new to read)
end

-- press a caught note's button (the Messages window): the prompt's own button, the mod's callback
function M.press(item, i)
    if not item or item.done or not item.prompt then return end
    local b = item.buttons and item.buttons[i or 1]
    if not b then return end
    item.done = true
    item.answer = tostring(b.title or "")
    local ok, err = pcall(function() item.prompt:press(b) end)
    if not ok then print("[ZeD] Messages: " .. tostring(err)) end
    bump()
end

-- ---------------------------------------------------------------------------
-- errors: the game's own list, filed by the mod named in each
-- ---------------------------------------------------------------------------
local errSeen = 0          -- the game's error count when last read
local listSeen = 0         -- the entries of its list already read
local lastErr = nil
-- one error is several entries in the game's list (a separator, the dump's head, the
-- exception "java.lang.RuntimeException: ...", its stack dumps): the exception counts and
-- opens a record, the others are added to the record before them
local function fileError(s)
    -- (up to the closing "))": a mod name may hold a bracket of its own, "Ladders!? (v0.0.13)")
    local name = s:match("%(%(MOD:(.-%)*)%)%)") or ZeD.tr("UI_ZeD_Msg_TheGame")
    local src = M.sources[name]
    local item = src and src.kind == "err" and src.items[1]
    if not item then
        item = M.add(name, "err", { k = "err", count = 0, firsts = {}, texts = {} })
        toast("crit", ZeD.tr("UI_ZeD_Msg_ToastError"), name, "")
    end
    lastErr = item
    item.count = item.count + 1
    item.read = false
    local first = s:match("([^\n]*Exception[^\n]*)") or s:match("([^\n]+)") or s
    first = first:gsub("^%s+", ""):sub(1, 200)
    local known = false
    for _, f in ipairs(item.firsts) do if f == first then known = true; break end end
    if not known and #item.firsts < 5 then item.firsts[#item.firsts + 1] = first end
    item.texts[#item.texts + 1] = s
    if #item.texts > KEEP_ERRORS then table.remove(item.texts, 1) end
    for _, t in ipairs(M.toasts) do if t.source == name and t.kind == "crit" then t.text = ZeD.tr("UI_ZeD_Msg_ToastErrors", item.count) end end
    bump()
end

function M.readErrors()
    if not (getLuaDebuggerErrorCount and getLuaDebuggerErrors) then return end
    local n = safe(getLuaDebuggerErrorCount) or 0
    if n == errSeen then return end
    errSeen = n
    local list = safe(getLuaDebuggerErrors)
    local size = list and list:size() or 0
    if size < listSeen then listSeen = 0 end   -- (the game started a new list)
    for i = listSeen, size - 1 do
        local s = tostring(list:get(i) or "")
        if M.qaLog then print("[ZeD] Messages: error entry " .. tostring(i) .. ": " .. string.sub(string.gsub(s, "\n", " / "), 1, 160)) end
        if string.find(s, "Exception", 1, true) then fileError(s)
        elseif lastErr and #lastErr.texts > 0 then
            local t = lastErr.texts
            t[#t] = t[#t] .. "\n" .. s
        end
    end
    listSeen = size
end

-- the bug report text for an error source: what ZeD knows, then the kept errors in full
function M.report(name)
    local s = M.sources[name]
    local it = s and s.items[1]
    if not it or it.k ~= "err" then return "" end
    local out = { name .. ": " .. it.count .. " errors (ZeD-GUI Messages)", "" }
    for _, t in ipairs(it.texts) do out[#out + 1] = t; out[#out + 1] = "" end
    return table.concat(out, "\n")
end

-- ---------------------------------------------------------------------------
-- the clock: errors every two seconds, toasts expire, a paused game runs on
-- (on the drawn frame: the game's tick stops while it is paused)
-- ---------------------------------------------------------------------------
local nextErr = 0
local function frame()
    local t = now()
    if t >= nextErr then
        nextErr = t + 2000
        local okE, errE = pcall(M.readErrors)
        if not okE then ZeD.logOnce("messages: reading the errors", errE) end
    end
    for i = #M.toasts, 1, -1 do if M.toasts[i].untilMs <= t then table.remove(M.toasts, i) end end
    local spNow = safe(function() return getGameSpeed() end)
    if spNow and spNow > 0 then lastSpeed = spNow end
    if speedWatch then
        speedWatch.frames = speedWatch.frames - 1
        if speedWatch.frames <= 0 then
            local sp = safe(function() return getGameSpeed() end)
            local menu = MainScreen and MainScreen.instance and MainScreen.instance:isVisible()
            if sp == 0 and not menu then
                pcall(function() setGameSpeed(speedWatch.speed) end)
                print("[ZeD] Messages: a mod paused the game for its note; the note is in Messages, the game runs on")
            end
            speedWatch = nil
        end
    end
end

Events.OnGameStart.Add(function()
    startedAt = now()
    roots = nil
    -- (errors from before the game started are left to the game's own log)
    errSeen = safe(getLuaDebuggerErrorCount) or 0
    local list = safe(getLuaDebuggerErrors)
    listSeen = list and list:size() or 0
end)
Events.OnRenderTick.Add(frame)

-- open the window (the belt's note, a toast, the ZeD wheel)
function M.open(name)
    if ZeD.MessagesWindow and ZeD.MessagesWindow.open then ZeD.MessagesWindow.open(0, name) end
end
