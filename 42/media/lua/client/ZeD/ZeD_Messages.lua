-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Messages.lua
-- ============================================================================
-- MESSAGES: other mods' notes and errors, kept in one window (MESSAGES_SPEC.md;
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

M.sources = M.sources or {}    -- name -> { name, kind = "mods" | "err" | "halo", items = { ... }, at = sequence }
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
    return S and S.messagesCatchOn and S.messagesCatchOn() or false
end
local function toastOn()
    local S = ZeD.Settings
    return S and S.messagesToastOn and S.messagesToastOn() or false
end

local function loadPopups()
    M.popups = {}
    local ok, r = pcall(function() return getFileReader(FILE, false) end)
    if not (ok and r) then return end
    pcall(function()
        local l = r:readLine()
        while l do
            local name = l:match("^popup=(.+)$")
            if name then M.popups[name] = true end
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
end
-- (Lua here can neither rename nor delete a file, so no swap: all the words are ready before the file is opened, and a
-- failed write costs this list and no more)
local function savePopups()
    local names = {}
    for n in pairs(M.popups or {}) do names[#names + 1] = n end
    table.sort(names)
    local lines = { "ZeD-UI Messages: the mods whose notes still show as pop-ups\n" }
    for _, n in ipairs(names) do lines[#lines + 1] = "popup=" .. n .. "\n" end
    local ok, w = pcall(function() return getFileWriter(FILE, true, false) end)
    if not (ok and w) then return end
    pcall(function() w:write(table.concat(lines)) end)
    pcall(function() w:close() end)
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
local INVITE_NOTES_MAX = 10      -- invitation notes on the belt
local TICKET_NOTES_MAX = 10      -- "a ticket came in" notes, for staff

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
-- the sources, mods first (newest first), then errors (newest first), then the notes over your head
function M.list()
    local mods, errs, halos = {}, {}, {}
    for _, s in pairs(M.sources) do
        if #s.items > 0 then
            if s.kind == "err" then errs[#errs + 1] = s
            elseif s.kind == "halo" then halos[#halos + 1] = s
            else mods[#mods + 1] = s end
        end
    end
    local by = function(a, b) return (a.at or 0) > (b.at or 0) end
    table.sort(mods, by); table.sort(errs, by)
    return mods, errs, halos
end

-- ---------------------------------------------------------------------------
-- tickets (ZeDUI/MP_SERVER_PART_DESIGN.md, B7): a note when an admin answers. One item per ticket: a fresh answer on it
-- marks it unread again, and the list the server repeats at each hello (who is nil) adds nothing to it. Only an answer
-- makes a note; status changes appear in the ticket list.
-- ---------------------------------------------------------------------------
function M.ticket(id, who)
    local name = getText("UI_userpanel_tickets")
    local text = who and ZeD.tr("UI_ZeD_Tk_NoteAnswered", id, who) or ZeD.tr("UI_ZeD_Tk_NoteAway", id)
    local s = M.sources[name]
    for _, it in ipairs(s and s.items or {}) do
        if it.k == "ticket" and it.id == id then
            if not who then return it end
            it.text, it.read = text, false
            it.when = when()
            toast("warn", ZeD.tr("UI_ZeD_Tk_ToastHead"), name, text)
            bump()
            return it
        end
    end
    local it = M.add(name, "mods", { k = "ticket", id = id, text = text })
    toast("warn", ZeD.tr("UI_ZeD_Tk_ToastHead"), name, text)
    return it
end

-- a word from the admin tools. bans: it is about a ban, and its Open goes to the Bans card
function M.adminNote(text, bans)
    local name = ZeD.tr("UI_ZeD_Adm_NoteHead")
    local it = M.add(name, "mods", { k = "adminnote", text = text, bans = bans })
    toast("warn", name, name, text)
    return it
end

-- notes any player can cause: the oldest of this kind goes past its cap, and only that kind
local function capKind(name, k, max)
    local items = M.sources[name].items
    local n = 0
    for _, x in ipairs(items) do
        if x.k == k then n = n + 1 end
    end
    for i = #items, 1, -1 do
        if n <= max then break end
        if items[i].k == k then
            table.remove(items, i)
            n = n - 1
        end
    end
end

-- in place of the game's two invitation modals (ZeD_Claims.lua): the invitation itself waits in the Server tab
function M.invite(text)
    local name = ZeD.tr("UI_ZeD_Char_TabServer")
    local it = M.add(name, "mods", { k = "invite", text = text })
    capKind(name, "invite", INVITE_NOTES_MAX)
    toast("warn", ZeD.tr("UI_ZeD_Cl_ToastHead"), name, text)
    return it
end

-- controllers (the director, Nov 7 2026, vanilla windows B12 and B13; Overrides/Controllers.lua): a controller plugged
-- in, with the game's join choices as its buttons, or a player's controller unplugged. One note per controller or
-- player (id): the newest replaces the one before it; never more than PAD_NOTES_MAX. buttons: { label, run } each,
-- pressed on the note's card (ZeD_MessagesWindow); run returns true when it did what it says.
local PAD_NOTES_MAX = 8
function M.pad(id, head, text, buttons)
    local name = ZeD.tr("UI_ZeD_Pad_Source")
    local s = M.sources[name]
    if s then
        for i = #s.items, 1, -1 do
            if s.items[i].k == "pad" and s.items[i].pad == id then table.remove(s.items, i) end
        end
    end
    local it = M.add(name, "mods", { k = "pad", pad = id, head = head, text = text, padButtons = buttons })
    capKind(name, "pad", PAD_NOTES_MAX)
    toast("warn", head, name, text)
    return it
end

-- for staff, in place of the game's modal: a ticket came in
function M.ticketNew()
    local name = getText("UI_userpanel_tickets")
    local text = ZeD.tr("UI_ZeD_Tk_NoteNew")
    local it = M.add(name, "mods", { k = "ticketnew", text = text })
    capKind(name, "ticketnew", TICKET_NOTES_MAX)
    toast("warn", ZeD.tr("UI_ZeD_Tk_ToastHead"), name, text)
    return it
end

-- ---------------------------------------------------------------------------
-- the notes over your head (the director, Nov 4 2026: "a running log", so a note you missed can be read later;
-- ZeD_HaloText.lua). One source, newest first, already read (they never raise the unread count or a toast), the
-- oldest dropped past HALO_KEEP. The same line again on top counts up instead of adding a card. An XP line adds to
-- the one on top for the same skill (sum = true, with amount and its key).
-- ---------------------------------------------------------------------------
local HALO_KEEP = 100
function M.halo(text, tone, sum)
    text = tostring(text or "")
    if text == "" then return end
    local name = ZeD.tr("UI_ZeD_Msg_OverHead")
    local s = M.sources[name]
    if not s then
        s = { name = name, kind = "halo", items = {} }
        M.sources[name] = s
    end
    local top = s.items[1]
    if sum and top and top.sumKey == sum.key then
        top.amount = (top.amount or 0) + (sum.amount or 0)
        top.text = ZeD.tr("UI_ZeD_Halo_XP", sum.label, string.format("%.1f", top.amount))
        top.when = when()
        bump()
        return top
    end
    if (not sum) and top and top.text == text and top.tone == tone and not top.sumKey then
        top.n = (top.n or 1) + 1
        top.when = when()
        bump()
        return top
    end
    local it = { k = "halo", text = text, tone = tone, read = true, when = when() }
    if sum then it.sumKey, it.amount = sum.key, sum.amount or 0 end
    table.insert(s.items, 1, it)
    while #s.items > HALO_KEEP do table.remove(s.items) end
    M.seq = M.seq + 1
    s.at = M.seq
    bump()
    return it
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
local errSeen = 0          -- the game's entry count when last read (KahluaThread.errorCount: one per entry added)
local lastErr = nil
local pending = nil        -- the next error's head and Lua stack, read before its exception entry (see readErrors)
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
    item.whens = item.whens or {}
    item.whens[#item.texts] = when()   -- (each kept error's own time, for its card and its copy)
    if #item.texts > KEEP_ERRORS then table.remove(item.texts, 1); table.remove(item.whens, 1) end
    for _, t in ipairs(M.toasts) do if t.source == name and t.kind == "crit" then t.text = ZeD.tr("UI_ZeD_Msg_ToastErrors", item.count) end end
    bump()
end

-- The game keeps its last 40 entries (KahluaThread.m_errors_list: at 40 it drops the oldest as it
-- adds one) and counts every entry it adds, so the new entries are the count's rise, read from the
-- list's end (Oct 25 2026: the list's own size was used, and once it was full no new error was filed).
function M.readErrors()
    if not (getLuaDebuggerErrorCount and getLuaDebuggerErrors) then return end
    local n = safe(getLuaDebuggerErrorCount) or 0
    if n == errSeen then return end
    local new = n - errSeen
    errSeen = n
    local list = safe(getLuaDebuggerErrors)
    local size = list and list:size() or 0
    local from = (new > 0) and math.max(0, size - new) or size
    for i = from, size - 1 do
        local s = tostring(list:get(i) or "")
        if M.qaLog then print("[ZeD] Messages: error entry " .. tostring(i) .. ": " .. string.sub(string.gsub(s, "\n", " / "), 1, 160)) end
        -- One error is written as: a separator line with the message ("------..." then "attempted index: ..."),
        -- then "dumping Lua stack trace" with the Lua stack, then the exception entry, then (in -debug) the Java
        -- stack. The separator opens the next error, so its head and stack wait in `pending` and go in front of that
        -- error's exception; only what follows an exception belongs to it (punch list 66, QA Nov 2 2026: the older
        -- error's copy carried the next one's head).
        if string.find(s, "Exception", 1, true) then
            fileError(pending and (pending .. "\n" .. s) or s)
            pending = nil
        elseif string.find(s, "^%s*%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-") then
            pending = s
        elseif pending then
            pending = pending .. "\n" .. s
        elseif lastErr and #lastErr.texts > 0 then
            local t = lastErr.texts
            t[#t] = t[#t] .. "\n" .. s
        end
    end
end

-- ---------------------------------------------------------------------------
-- BUG REPORTS (the director, Nov 2 2026, punch list 66: "no digging through files or the console"). Every copied
-- report starts with the same header, so a paste into a Workshop thread or a paste site says what ran:
-- ZeD-GUI's version, the game's build, then the mods that are on, one per line.
-- ---------------------------------------------------------------------------
function M.reportHeader()
    local zv = safe(function() local mi = getModInfoByID("ZeD_UI"); return mi and mi:getModVersion() end)
    local gv = safe(function() return tostring(getCore():getVersion()) end)
    local out = { "ZeD-GUI " .. tostring(zv or "?") .. " | Project Zomboid " .. tostring(gv or "?") }
    local mods = safe(getActivatedMods)
    local n = mods and mods:size() or 0
    out[#out + 1] = "Mods on (" .. n .. "):"
    for i = 0, n - 1 do
        local id = tostring(mods:get(i))
        local mi = safe(getModInfoByID, id)
        local nm = mi and safe(function() return mi:getName() end)
        local ver = mi and safe(function() return mi:getModVersion() end)
        out[#out + 1] = "  " .. ((nm and nm ~= id) and (nm .. " (" .. id .. ")") or id) .. ((ver and ver ~= "") and (" " .. ver) or "")
    end
    out[#out + 1] = ""
    return table.concat(out, "\n")
end

-- one source's errors, every kept one in full ("errors" is how many came; the newest 12 are kept)
local function sourceBlock(name, it)
    local out = { name .. ": " .. it.count .. " errors, the newest " .. #it.texts .. " in full", "" }
    for i, t in ipairs(it.texts) do
        out[#out + 1] = "--- " .. tostring((it.whens and it.whens[i]) or "") .. " ---"
        out[#out + 1] = t
        out[#out + 1] = ""
    end
    return table.concat(out, "\n")
end

-- the bug report text for an error source: the header, then its kept errors in full
function M.report(name)
    local s = M.sources[name]
    local it = s and s.items[1]
    if not it or it.k ~= "err" then return "" end
    return M.reportHeader() .. "\n" .. sourceBlock(name, it)
end

-- one kept error of a source (i: its place in the kept list), with the header
function M.reportOne(name, i)
    local s = M.sources[name]
    local it = s and s.items[1]
    local t = it and it.k == "err" and it.texts[i]
    if not t then return "" end
    return M.reportHeader() .. "\n" .. name .. ": " .. tostring((it.whens and it.whens[i]) or "") .. "\n" .. t .. "\n"
end

-- every error source's report in one text, and how many errors it holds
function M.reportAll()
    local names = {}
    for name, s in pairs(M.sources) do
        if s.kind == "err" and s.items[1] and s.items[1].k == "err" then names[#names + 1] = name end
    end
    table.sort(names)
    local parts, n = { M.reportHeader() }, 0
    for _, name in ipairs(names) do
        local it = M.sources[name].items[1]
        n = n + it.count
        parts[#parts + 1] = sourceBlock(name, it)
    end
    if n == 0 then parts[#parts + 1] = "No errors were caught this session." end
    return table.concat(parts, "\n"), n
end

-- The ZeD wheel's Bug report: every error, with the header, onto the clipboard, then a note saying so
function M.copyBugReport(pn)
    local text, n = M.reportAll()
    local ok = pcall(function() Clipboard.setClipboard(text) end)
    local msg
    if not ok then msg = ZeD.tr("UI_ZeD_Msg_BugReportFailed")
    elseif n == 0 then msg = ZeD.tr("UI_ZeD_Msg_BugReportNone")
    else msg = ZeD.tr("UI_ZeD_Msg_BugReportCopied", n) end
    print("[ZeD] Bug report: " .. tostring(n) .. " errors copied to the clipboard (" .. tostring(ok) .. ")")
    local modal = ISModalDialog:new(0, 0, 380, 160, msg, false, nil, nil, pn)
    modal:initialise()
    modal:addToUIManager()
    if pn and JoypadState and JoypadState.players[pn + 1] then setJoypadFocus(pn, modal) end
    return n
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
end)
Events.OnRenderTick.Add(frame)

-- open the window (the belt's note, a toast, the ZeD wheel)
function M.open(name)
    if ZeD.MessagesWindow and ZeD.MessagesWindow.open then ZeD.MessagesWindow.open(0, name) end
end
