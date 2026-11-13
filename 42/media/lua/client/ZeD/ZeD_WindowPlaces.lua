-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WindowPlaces.lua
-- ============================================================================
-- SAVED WINDOW POSITIONS - client module behind two rows of the window menu:
-- "Save position" and "Go to saved position" (ZeD_WindowMenu.lua).
--
-- Each window keeps one saved place of its own, the Character and the World
-- windows apart. A place is about the screen, not the character, so it lives
-- in one file under Zomboid/Lua (ZeD_window_places.txt) and every save and
-- character on this computer shares it. Nothing opens a window there by
-- itself: the per-character layout (modData ZeD_WinState) still decides where
-- a window opens; the saved place is used only when the player asks for it.
--
-- Before touching it: sizes are kept in design units (screen px / T.scale),
-- so a place survives a UI scale change, and every restore is clamped onto
-- the screen it lands on. The Character and World windows go back through
-- their own restore (applyState), the one a fresh open uses, so the drawers,
-- the right-edge anchor and the controller's stops stay in step. A window that
-- centers itself every frame (the survival guide, Messages) places through
-- ZeD_Window:placeSelf, which keeps the place this module gives it.
-- ============================================================================

require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.WindowPlaces = ZeD.WindowPlaces or {}
local P = ZeD.WindowPlaces

P.FILE = "ZeD_window_places.txt"
P.places = P.places or nil   -- id -> { x, y, w, h, and for the pair: anchorRightEdge, activeTab, drawerMode, drawerOpen }

-- what a pair window's place holds besides x, y, w and h (its accent is a look, not a place: never kept here)
local PAIR_FIELDS = { "anchorRightEdge", "activeTab", "drawerMode", "drawerOpen" }

-- ---------------------------------------------------------------------------
-- which window: a name that is the same in every session
-- ---------------------------------------------------------------------------
local function clean(s) return (string.gsub(tostring(s), "[^%w_%.%-]", "")) end

--- The window's id in the file: "char" / "world" for the pair; otherwise the window's own
--- zedPosKey, its ZeD label, or its class (with its kind where one class makes several windows,
--- as the pause window and the prompts); a plain ZeD window with none of those goes by its title.
--- A window docked to another (a form card on its drawer: win.zedDocked) has none: its box places it.
function P.keyOf(win)
    if not win or win.zedDocked then return nil end
    local pk = win.pairKey and win:pairKey() or nil
    if pk then return pk end
    local k = win.zedPosKey or win._zedLabel
    if not k then
        local ty = win.Type
        if ty and ty ~= "ZeD_Window" then
            k = ty
            if type(win.kind) == "string" then k = k .. "." .. win.kind end
        elseif win.title and win.title ~= "" then
            k = "title." .. win.title
        end
    end
    if not k then return nil end
    k = clean(k)
    return k ~= "" and k or nil
end

-- ---------------------------------------------------------------------------
-- the file: a line per window, "id|x=..|y=..|w=..|h=..|..."
-- ---------------------------------------------------------------------------
local function num(v) return math.floor(v * 100 + 0.5) / 100 end

local function parseLine(l)
    local id, rest = l:match("^([%w_%.%-]+)|(.*)$")
    if not id then return nil end
    local rec = {}
    for k, v in rest:gmatch("([%w_]+)=([^|]*)") do
        local n = tonumber(v)
        if v == "true" then rec[k] = true
        elseif v == "false" then rec[k] = false
        elseif n then rec[k] = n
        elseif v ~= "" then rec[k] = v end
    end
    if type(rec.x) ~= "number" or type(rec.y) ~= "number" then return nil end
    return id, rec
end

--- Read the file again (on first use; the sims call it after a write).
function P.load()
    P.places = {}
    local ok, r = pcall(function() return getFileReader(P.FILE, false) end)
    if not (ok and r) then return P.places end
    pcall(function()
        local l = r:readLine()
        while l do
            local id, rec = parseLine(l)
            if id then P.places[id] = rec end
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
    return P.places
end

local function places() return P.places or P.load() end

-- (all the words are ready before the file is opened: the game's Lua can neither rename nor delete a file, so a
-- failed write costs this file and nothing more)
local function write()
    local ids = {}
    for id in pairs(P.places or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    local lines = { "ZeD-UI: saved window positions (the window menu's Save position), design units\n" }
    for _, id in ipairs(ids) do
        local rec = P.places[id]
        local parts = { id }
        local keys = {}
        for k in pairs(rec) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local v = rec[k]
            if type(v) == "number" then v = tostring(num(v)) else v = clean(v) end
            parts[#parts + 1] = k .. "=" .. v
        end
        lines[#lines + 1] = table.concat(parts, "|") .. "\n"
    end
    local ok, w = pcall(function() return getFileWriter(P.FILE, true, false) end)
    if not (ok and w) then return false end
    local okW = pcall(function() for _, l in ipairs(lines) do w:write(l) end end)
    pcall(function() w:close() end)
    return okW
end
--- Write the file as P.places stands (the QA script puts the player's own places back with it).
P.flush = write

-- ---------------------------------------------------------------------------
-- save and go
-- ---------------------------------------------------------------------------
local function pairClass(k)
    if k == "char" then return ZeD_CharacterWindow end
    if k == "world" then return ZeD_WorldWindow end
    return nil
end

--- The window's place now, in design units; nil when it has no id.
function P.capture(win)
    local k = P.keyOf(win)
    if not k then return nil end
    local CW = pairClass(k)
    if CW and CW.stateOf then
        local st = CW.stateOf(win)
        local rec = { x = st.x, y = st.y, w = st.w, h = st.h }
        for _, f in ipairs(PAIR_FIELDS) do rec[f] = st[f] end
        return k, rec
    end
    local sc = (ZeD.T and ZeD.T.scale) or 1
    local h = (win.windowShaded and win.preShadeHeight) or win:getHeight()   -- (rolled up: the unrolled height)
    return k, { x = win:getX() / sc, y = win:getY() / sc, w = win:getWidth() / sc, h = h / sc }
end

--- True when this window has a saved place.
function P.has(win)
    local k = P.keyOf(win)
    return k ~= nil and places()[k] ~= nil
end

--- "Save position": keep the window's place in the file, and say so in a Messages bubble.
function P.save(win)
    local k, rec = P.capture(win)
    if not k then return false end
    places()[k] = rec
    local ok = write()
    local M = ZeD.Messages
    if M and M.notice then
        local pn = (ZeD.playerNumOf and ZeD.playerNumOf(win)) or win.playerNum or 0
        pcall(M.notice, ZeD.tr("UI_ZeD_WinMenu_SavedHead"),
            ZeD.tr("UI_ZeD_WinMenu_SavedText", ZeD.tr("UI_ZeD_WinMenu_GoSaved")), { key = "winpos", pn = pn })
    end
    return ok
end

local function clamp(v, lo, hi) if v < lo then return lo end if v > hi then return hi end return v end

-- a window outside the pair: the steps "Reset this window" takes, to the kept place, clamped onto this screen
-- (the screen the window lives on, ZeD.screenOf: sl, st its left and top)
local function goPlain(win, rec)
    local T = ZeD.T
    local sw, sh, sl, st = ZeD.screenOf(win)
    if win.windowShaded then win:setWindowShaded(false) end
    local w, h = win:getWidth(), win:getHeight()
    if win.resizable and rec.w and rec.h then
        w = math.max(win.minimumWidth or 0, math.min(T.px(rec.w), sw))
        h = math.max(win.minimumHeight or 0, math.min(T.px(rec.h), sh))
        win:setWidth(w)
        win:setHeight(h)
    end
    win:setX(clamp(T.px(rec.x), sl, math.max(sl, sl + sw - w)))
    win:setY(clamp(T.px(rec.y), st, math.max(st, st + sh - h)))
end

-- the Character or World window: as "Reset this window" starts (a rolled side down, a folded half forgotten, the
-- Loot columns closed, the drawers shut at once, the inventory shown and the cap's push dropped), then the window's
-- own restore, then the controller's stops
local function goPair(win, k, rec, CW)
    local T = ZeD.T
    if win._rolled and ZeD.Curtain and ZeD.Curtain.finishUnroll then ZeD.Curtain.finishUnroll(win) end
    if win._halves and ZeD.Halves and ZeD.Halves.forgetFold then ZeD.Halves.forgetFold(win) end
    if win.windowShaded then win:setWindowShaded(false) end
    -- (a place is kept without columns: left open, a place saved on a tab opened its card beside them, past the cap)
    if CW.closeColumns then CW.closeColumns(win) end
    win.minimumWidth = T.minWinW or 0   -- (an open drawer's minimum would hold the window wide through setWidth)
    -- the half-screen cap measured on this screen (the restore caps the width by it; one kept from a bigger
    -- screen let the window back at that screen's width)
    win._maxWinW = math.floor(ZeD.screenOf(win) * 0.5)
    win._drawerCapPush, win._drawerCapLost, win._preDrawerW = 0, 0, nil
    win._drawerOpen, win._drawerEffW, win._prevEffW, win._drawerMode = false, 0, 0, nil
    -- (the restore gives the window its width with the inventory in it: a list hidden from a tab shows again, and
    -- the flag says so, or the window took the shown list for hidden)
    win._invDrawerOpen = true
    local cs = {}
    for f, v in pairs(rec) do cs[f] = v end
    local accent = win._accentKey   -- (the restore would take the option's accent when the place has none)
    CW.applyState(win, cs)
    win._accentKey = accent
    -- (the World window grows right: its anchor is its right edge, as the reset sets it)
    if k == "world" then win._anchorRightEdge = win:getX() + win:getWidth() end
    win._lastSetX = win:getX()
    if CW.syncRing then CW.syncRing(win) end
end

--- "Go to saved position": the window back to its kept place. False when nothing is kept for it.
function P.goTo(win)
    local k = P.keyOf(win)
    local rec = k and places()[k]
    if not rec then return false end
    local CW = pairClass(k)
    if CW then
        if not CW.applyState then return false end
        goPair(win, k, rec, CW)
    else
        goPlain(win, rec)
    end
    return true
end
