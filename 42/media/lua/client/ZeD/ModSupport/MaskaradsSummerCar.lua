-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/MaskaradsSummerCar.lua
-- ============================================================================
-- SUPPORT FOR MASKARAD'S SUMMER CAR (mod id MaskaradsSummerCar, Workshop
-- 3790160840, by Maskarad). Client. What follows about the mod was read from its
-- own code, version 0.0.1.
--
-- What the mod does: its engine components window (MSC_EngineComponentsWindow)
-- hangs off the game's mechanics window. The mod's wrap of that window's prerender
-- opens it by itself beside the game's window (calculatePlacement reads the game
-- window's getX / getY / getWidth, and slides it with setX when neither side has
-- room); the engine window closes itself in its own update when the game's window is
-- no longer really visible or shows another car. Its wrap of doPartContextMenu swaps
-- the Engine's Take engine parts and Repair engine for Inspect engine components.
-- ZeD never shows the game's mechanics window (its Vehicle tab replaces it), so with
-- ZeD on the engine window closed the moment it opened.
--
-- What ZeD does now, with nothing of the mod's or the game's wrapped:
--   the anchor   one plain table per local player that answers what the engine
--                window asks of "the mechanics window", from ZeD's World window.
--                It is really visible while the Vehicle tab shows an inspected car
--                (the window open, not rolled to its title bar, the drawer half not
--                folded). Its setX moves nothing: ZeD's window stays where the
--                player put it.
--   the poll     every frame: the mod's own auto-open steps against the anchor, then
--                the mod's own openFromMechanics; the engine window closes with the
--                tab; the pointer on it holds the World window's roll-up; a pad the
--                mod hands to the anchor goes back. A close by the player (the
--                title-bar X, Esc) lasts while the car stays inspected, as it lasts
--                beside the game's window: folding the drawer, rolling the window
--                or another tab only hide the engine window for now.
--   placement    the mod places the engine window against the World window. Where
--                the mod would slide the World window or lay its window over it,
--                the engine window takes the side with more room instead, at the
--                mod's own widths. Where neither side holds the mod's minimum, it
--                goes to the screen edge that covers less of the Vehicle tab, then
--                less of the window. It moves again only when the World window grows
--                into it and the player has not dragged it.
--   the tab      through ZeD.MechanicsTab.addExtras: the Engine's footer drops
--                Repair engine and Take engine parts for the mod's Inspect engine
--                components, and the mod's own Inspect option in the part menu is
--                pointed at the anchor, with the controller grab off (the engine
--                window has no pad handling, and the pad stays with ZeD).
--
-- Every reach into the mod is listed in S.CONTRACT, type-checked where used and
-- called through pcall. A missing piece or an error leaves today's behavior and one
-- line in console.txt per place (never ZeD.logOnce, which feeds safe mode's
-- watchdog: another mod's update must not send all of ZeD home).
--
-- Not carried over: the engine window does not follow the World window when the
-- player moves it (the mod places it once, at open, beside the game's window too).
-- Proved by ZeDUI/tools/qa/summercar_sim.lua (ZeD's side) and
-- summercar_contract_sim.lua (the mod's own file); in the game, zedqa_summercar.lua.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "MaskaradsSummerCar"

-- Is the mod switched on in this game? getActivatedMods() is a Java list of mod ids;
-- a leading backslash (a mod loaded by its folder id) is cut off before comparing.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do                           -- Java lists count from 0
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end   -- a file's top level can "return": the rest never runs

require "ZeD/MechanicsTab"

-- The mod's own numbers (file locals in its window file: WINDOW_GAP, CONTENT_PADDING,
-- MINIMUM_WIDTH); the contract sim checks them on every run.
local GAP, MARGIN, MIN_W = 10, 10, 420
local KEEP_TILES = 6        -- the mod's window closes itself past this
local SETTLE_MS  = 150      -- the World window still this long before the engine window opens
local HOLD_MS    = 500      -- ZeD's own roll-up hold
local VERB       = "mscInspect"
local TAB_STRIP_W = 36      -- the World window's action tab strip, design units (ACTION_TAB_STRIP_W there)

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local OLD = ZeD.ModSupport.MaskaradsSummerCar      -- a hot reload keeps the anchors
local S = { MOD_ID = MOD_ID }
ZeD.ModSupport.MaskaradsSummerCar = S

--- Everything this file reaches for in the mod; both sims read this list.
S.CONTRACT = {
    version    = "0.0.1",                                                  -- what this file was read against
    window     = { "openFromMechanics", "instances" },                     -- MSC.EngineComponentsWindow
    components = { "canAccessEngine", "getEngineAccessReason" },           -- MSC.EngineComponents
    signals    = { "MSC_originalDoPartContextMenu", "MSC_originalPrerender" },   -- the mod's install guards on ISVehicleMechanics
    anchor     = { "getX", "getY", "getWidth", "setX", "isReallyVisible", "vehicle", "msc_userDismissed" },
    keys       = { "UI_MSC_InspectEngineComponents", "UI_MSC_InspectEngineComponentsTooltip",
                   "UI_MSC_HoodMustBeOpen", "UI_MSC_EngineAssemblyUnavailable" },
}

-- Once per place: to console.txt and nowhere else (see the file's head)
S.noted = (OLD and OLD.noted) or {}
local function note(place, err)
    if S.noted[place] then return end
    S.noted[place] = true
    print("[ZeD] Summer Car: " .. tostring(place) .. ": " .. tostring(err))
end
S.note = note

-- ----------------------------------------------------------------------------
-- The mod's tables, asked for at each use and never kept (an unset global reads as nil)
-- ----------------------------------------------------------------------------
local function windowClass()
    local m = MSC
    local W = type(m) == "table" and m.EngineComponentsWindow or nil
    if type(W) == "table" and type(W.openFromMechanics) == "function" and type(W.instances) == "table" then return W end
    return nil
end
local function components()
    local m = MSC
    local C = type(m) == "table" and m.EngineComponents or nil
    if type(C) == "table" and type(C.canAccessEngine) == "function"
        and type(C.getEngineAccessReason) == "function" then return C end
    return nil
end
-- one of the mod's install guards on the game's mechanics window: its wrap is in place
local function signal(name)
    return type(ISVehicleMechanics) == "table" and type(ISVehicleMechanics[name]) == "function"
end
S.windowClass, S.components, S.signal = windowClass, components, signal

-- The mod's seated rule: a seated player sees no engine window unless debug, or an
-- admin or moderator on a server
local function seatedOut(p)
    if p == nil or p:getVehicle() == nil then return false end
    if isDebugEnabled and isDebugEnabled() then return false end
    if isClient and isClient() and ((isAdmin and isAdmin())
        or (getAccessLevel and getAccessLevel() == "moderator")) then return false end
    return true
end
S.seatedOut = seatedOut
local function paused()
    local ok, speed = pcall(function() return UIManager.getSpeedControls():getCurrentGameSpeed() end)
    return ok and speed == 0
end
-- the engine's access reason (nil: open to inspect), or "error" when it cannot be read
local function accessReason(v)
    local C = components()
    if not C then return "missing" end
    local ok, r = pcall(C.getEngineAccessReason, v)
    if not ok then note("getEngineAccessReason", r); return "error" end
    return r
end

-- ----------------------------------------------------------------------------
-- WHAT THE TAB SHOWS
-- ----------------------------------------------------------------------------
--- The car the Vehicle tab shows for player pn, or nil. Returns v, win, chr, gone, hv:
--- gone is true when the tab has nothing to come back to (the World window closed,
--- the character dead, the car no longer inspected); false while it is only hidden
--- for now (rolled to the title bar, the drawer folded, another tab), and then hv is
--- the car it will show again.
function S.look(pn)
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on("windows") then return nil, nil, nil, true end
    if ZeD.windowsFor and not ZeD.windowsFor(pn) then return nil, nil, nil, true end
    local WW = ZeD_WorldWindow
    local win = WW and WW.getWindow and WW.getWindow(pn)
    if not win then return nil, nil, nil, true end
    local chr = win._playerObj
    if chr == nil or chr:isDead() then return nil, win, nil, true end
    local MT = ZeD.MechanicsTab
    local s = MT and MT.getState and MT.getState(win)
    local e = s and s.vehicles and s.vehicles[s.idx]
    local v = e and e.vehicle
    if v == nil or v:getSquare() == nil or not MT.isInspected(v) then return nil, win, chr, true end
    if win.windowShaded or not win:isReallyVisible() or not WW.isTabShowing("vehicle", pn) then
        return nil, win, chr, false, v
    end
    return v, win, chr, false
end
function S.shown(pn)
    local v, win, chr = S.look(pn)
    return v, win, chr
end

-- The World window's footprint: the window, and the rod over a rolled inventory side (left of it)
local function footprint(w)
    local r = w._rolled and (w._rollW or 0) or 0
    return w:getX() - r, w:getY(), w:getWidth() + r, w:getHeight()
end
S.footprint = footprint

-- ----------------------------------------------------------------------------
-- THE ANCHOR: what the engine window asks of "the mechanics window". The mod calls
-- these from its own update and close, so each answer is guarded here: an error
-- notes once and gives the safe answer (not visible, so the mod closes its own
-- window; the last good rect).
-- ----------------------------------------------------------------------------
local STAND = (OLD and OLD.STAND) or {}
local STAND_MT = (OLD and OLD.STAND_MT) or {}
S.STAND, S.STAND_MT = STAND, STAND_MT
S.stands = (OLD and OLD.stands) or {}
S.st = (OLD and OLD.st) or {}
local function noop() end
-- (any pad method the game's focus code asks of a focus is a no-op: the poll gives the pad back)
STAND_MT.__index = function(t, k)
    local f = STAND[k]
    if f ~= nil then return f end
    if type(k) == "string" and string.sub(k, 1, 8) == "onJoypad" then return noop end
    return nil
end

local function shownSafe(self)
    local ok, v = pcall(S.shown, self.playerNum)
    if not ok then note("anchor", v); return nil end
    return v
end
function STAND:rect()
    local ok, x, y, w, h = pcall(function()
        local win = ZeD_WorldWindow.getWindow(self.playerNum)
        if not win then return nil end
        return footprint(win)
    end)
    if not ok then note("anchor rect", x)
    elseif x ~= nil then
        local r = self._last or {}
        r[1], r[2], r[3], r[4] = x, y, w, h
        self._last = r
    end
    local r = self._last
    if not r then return 0, 0, 0, 0 end
    return r[1], r[2], r[3], r[4]
end
function STAND:getX() local x = self:rect(); return x end
function STAND:getY() local _, y = self:rect(); return y end
function STAND:getWidth() local _, _, w = self:rect(); return w end
function STAND:getHeight() local _, _, _, h = self:rect(); return h end
-- the mod's slide of its anchor: recorded for the placement, never done
function STAND:setX(x) self._askedX = x end
function STAND:isReallyVisible() local v = shownSafe(self); self.vehicle = v; return v ~= nil end
function STAND:isVisible() return shownSafe(self) ~= nil end
STAND.getIsVisible = STAND.isVisible
-- (setJoypadFocus builds its debug line from this whether it prints it or not)
function STAND:toString() return "ZeD Vehicle tab (Summer Car anchor)" end
function STAND:getJoypadNavigateStartDelay() return 250 end   -- the game's default
STAND.onGainJoypadFocus, STAND.onLoseJoypadFocus = noop, noop

--- The anchor for player pn, made on first use and kept for the session.
function S.standIn(pn)
    local a = S.stands[pn]
    if not a then
        a = setmetatable({ playerNum = pn, msc_userDismissed = false }, STAND_MT)
        S.stands[pn] = a
    end
    return a
end
local function stOf(pn)
    local t = S.st[pn]
    if not t then t = {}; S.st[pn] = t end
    return t
end
S.stOf = stOf
-- the mod's own reset while its window is hidden
local function resetStand(a)
    a.msc_userDismissed, a.msc_lastVehicle, a.msc_lastCanAccess = false, nil, nil
end

--- The engine window opened against player pn's anchor, or nil.
local function anchored(pn)
    local W = windowClass()
    local e = W and W.instances[pn]
    if type(e) == "table" and e.mechanicsUI ~= nil and e.mechanicsUI == S.stands[pn] then return e end
    return nil
end
S.anchored = anchored

-- ----------------------------------------------------------------------------
-- PLACEMENT
-- ----------------------------------------------------------------------------
local function clamp(n, lo, hi) if n < lo then return lo end if n > hi then return hi end return n end
-- how much of a0..a1 the span x..x+w covers
local function cover(x, w, a0, a1)
    if a0 == nil then return 0 end
    return math.max(0, math.min(x + w, a1) - math.max(x, a0))
end
-- The side and width for the engine window when the mod found no free side. tx0..tx1
-- is the Vehicle tab (the drawer and its tab strip), or nil. With neither side wide
-- enough, the window goes to a screen edge at the mod's minimum: the edge that covers
-- less of the tab, then the side with more room (it covers less of the window).
local function freeSide(ax, aw, sw, minW, maxW, tx0, tx1)
    local L = ax - GAP - MARGIN
    local R = sw - MARGIN - (ax + aw + GAP)
    if R >= minW and R >= L then
        local width = math.min(maxW, R)
        return ax + aw + GAP, width
    elseif L >= minW then
        local width = math.min(maxW, L)
        return ax - GAP - width, width
    end
    local xl, xr = MARGIN, math.max(MARGIN, sw - MARGIN - minW)
    local tl, tr = cover(xl, minW, tx0, tx1), cover(xr, minW, tx0, tx1)
    if tr < tl or (tr == tl and R >= L) then return xr, minW end
    return xl, minW
end
S.freeSide = freeSide

-- The Vehicle tab's span on screen: the drawer and the action tab strip at the World
-- window's right edge. Nil when it cannot be read.
local function tabSpan(pn)
    local ok, x0, x1 = pcall(function()
        local win = ZeD_WorldWindow.getWindow(pn)
        if not win then return nil end
        local dw = math.floor(tonumber(win._drawerEffW) or 0)
        local strip = (ZeD.T and ZeD.T.px) and ZeD.T.px(TAB_STRIP_W) or TAB_STRIP_W
        local right = win:getX() + win:getWidth()
        return right - strip - dw, right
    end)
    if not ok then note("tab span", x0); return nil end
    return x0, x1
end
S.tabSpan = tabSpan

--- Places an engine window opened against player pn's anchor. The mod's own place
--- stands unless it asked to slide ZeD's window or lies over it; then the window takes
--- the side with more room. again: a re-place after the World window grew into it
--- (top-aligned again as well).
function S.place(eng, pn, again)
    local stand = S.standIn(pn)
    local ax, ay, aw, ah = stand:rect()
    local ex, ew = eng:getX(), eng:getWidth()
    local st = stOf(pn)
    if st.placed ~= eng then st.chosenW = ew end
    local overlaps = ex < ax + aw and ex + ew > ax
    if stand._askedX ~= nil or overlaps then
        local sw = getCore():getScreenWidth()
        local minW = tonumber(eng.minimumWidth) or MIN_W
        local tx0, tx1 = tabSpan(pn)
        local x, width = freeSide(ax, aw, sw, minW, math.max(st.chosenW or ew, minW), tx0, tx1)
        eng:setWidth(math.floor(width))   -- (width first: setX keeps a top-level panel on screen against its width)
        eng:setX(math.floor(x))
        if again then
            local sh = getCore():getScreenHeight()
            eng:setY(math.floor(clamp(ay, MARGIN, sh - eng:getHeight() - MARGIN)))
        end
    end
    st.placed = eng
    st.placedX, st.placedY, st.placedW = eng:getX(), eng:getY(), eng:getWidth()
    st.placedFoot = { ax, ay, aw, ah }
end

--- ZeD's own opens (the footer verb, the auto-open): the mod's openFromMechanics
--- against the anchor, with no pad grab, then the placement. True when it is up.
function S.open(p, part, pn)
    local W = windowClass()
    if not W then return false end
    local stand = S.standIn(pn)
    stand._askedX = nil
    local ok, err = pcall(W.openFromMechanics, p, part, stand, true)
    if not ok then note("openFromMechanics", err); S.autoOff = true; return false end
    local eng = anchored(pn)
    if eng then
        local okP, errP = pcall(S.place, eng, pn)
        if not okP then note("place", errP); stOf(pn).placed = eng end
    end
    return eng ~= nil
end

-- The mod's own update closes its window at once past six tiles, without access, or
-- with the car gone from its square: never open one it would close on its next update.
local function openable(chr, v)
    if chr == nil or v == nil then return false end
    local sq = v:getSquare()
    if sq == nil or chr:DistTo(v:getX(), v:getY()) > KEEP_TILES then return false end
    local okI, idx = pcall(function() return sq:getMovingObjects():indexOf(v) end)
    if not okI or type(idx) ~= "number" or idx < 0 then return false end
    return accessReason(v) == nil
end
S.openable = openable

-- ----------------------------------------------------------------------------
-- THE POLL
-- ----------------------------------------------------------------------------
-- The mod's auto-open, step for step (its ISVehicleMechanics:prerender wrap), against
-- the anchor. mayOpen false: only its state is kept (the tab hidden for now).
local function autoOpen(pn, v, stand, mayOpen)
    if stand.msc_lastVehicle ~= v then
        stand.msc_lastVehicle = v
        stand.msc_userDismissed = false
        stand.msc_lastCanAccess = nil
    end
    if paused() then return end
    local C = components()
    if not C then return end
    local okA, canAccess = pcall(C.canAccessEngine, v)
    if not okA then note("canAccessEngine", canAccess); return end
    if not canAccess then
        stand.msc_userDismissed = false
        stand.msc_lastCanAccess = false
        return
    end
    if stand.msc_lastCanAccess == false then stand.msc_userDismissed = false end
    stand.msc_lastCanAccess = true
    if not mayOpen or stand.msc_userDismissed or S.autoOff then return end
    if not signal("MSC_originalPrerender") then note("auto-open", "the mod's prerender wrap is gone; no auto-open"); return end
    local p = getSpecificPlayer(pn)
    if p == nil or seatedOut(p) then return end
    local engine = v:getPartById("Engine")
    if engine == nil then return end
    local W = windowClass()
    if not W then return end
    local cur = W.instances[pn]
    -- (the mod's lift or ECU view, or one for another window: left alone; ZeD's own for this car: up already)
    if cur ~= nil and (cur.mechanicsUI ~= stand or cur.vehicle == v) then return end
    if not openable(p, v) then return end
    S.open(p, engine, pn)
end
S.autoOpen = autoOpen

-- The roll-up hold: the pointer on the engine window, or a context menu up, holds the
-- World window's fold timers (ZeD's own hold: _outSince in the future)
local function menuUp(pn)
    local ok, up = pcall(function()
        local m = getPlayerContextMenu(pn)
        if m == nil then return false end
        if m:getIsVisible() then return true end
        local z = m._zedMenu
        return z ~= nil and z._ctx ~= nil and z._ctx.open == true
    end)
    return ok and up == true
end
local function hold(win, eng, pn)
    local mx, my = getMouseX(), getMouseY()
    local ex, ey = eng:getX(), eng:getY()
    local on = mx >= ex and mx < ex + eng:getWidth() and my >= ey and my < ey + eng:getHeight()
    if not (on or menuUp(pn)) then return end
    local t = getTimestampMs() + HOLD_MS
    if win._outSince == nil or win._outSince < t then win._outSince = t end
end

-- The mod's close hands the pad to its anchor (a pad attached, the anchor visible).
-- The game's own focus stack gives it back to the window before; with none, ZeD's.
local function padBack(pn, stand)
    if not getJoypadFocus or getJoypadFocus(pn) ~= stand then return end
    if setPrevFocusForPlayer then setPrevFocusForPlayer(pn) end
    local f = getJoypadFocus(pn)
    if f == stand then setJoypadFocus(pn, nil); f = nil end
    if f == nil then
        local F = ZeD.Input and ZeD.Input.Focus
        if F and F.reclaimEngineFocus then F.reclaimEngineFocus() end
    end
end
S.padBack = padBack

local function sameRect(a, x, y, w, h)
    return a ~= nil and a[1] == x and a[2] == y and a[3] == w and a[4] == h
end
local function near(a, b) return a ~= nil and b ~= nil and math.abs(a - b) < 1 end
-- the World window grew into an engine window the player has not moved: place it again
local function replace(eng, pn, st, fx, fy, fw, fh)
    if st.placed ~= eng or sameRect(st.placedFoot, fx, fy, fw, fh) then return end
    if not (near(eng:getX(), st.placedX) and near(eng:getY(), st.placedY) and near(eng:getWidth(), st.placedW)) then return end
    local ex, ey = eng:getX(), eng:getY()
    local over = ex < fx + fw and ex + eng:getWidth() > fx and ey < fy + fh and ey + eng:getHeight() > fy
    if not over then return end
    local ok, err = pcall(S.place, eng, pn, true)
    if not ok then note("place again", err) end
end

-- whether the footprint and the drawer stood still since last frame; st.stillSince counts from the last change
local function settle(st, win, t, fx, fy, fw, fh)
    local dw = win._drawerEffW or 0
    local lf = st.lastFoot
    if not (sameRect(lf, fx, fy, fw, fh) and lf[5] == dw) then
        lf = lf or {}
        lf[1], lf[2], lf[3], lf[4], lf[5] = fx, fy, fw, fh, dw
        st.lastFoot, st.stillSince = lf, t
    end
    return t - st.stillSince >= SETTLE_MS
end

--- One frame for player pn (see the file's head for the order's reasons).
function S.pollOne(pn, t)
    local v, win, chr, gone, hv = S.look(pn)
    local stand = S.standIn(pn)
    stand.vehicle = v
    local st = stOf(pn)
    local eng = anchored(pn)
    -- closing: the mod's own close test, every frame (its update runs every 100 ms)
    if eng and eng.vehicle ~= v then
        local ok, err = pcall(eng.close, eng, false)
        if not ok then note("close", err) end
        eng = anchored(pn)
    end
    padBack(pn, stand)
    if v == nil then
        st.lastFoot, st.stillSince = nil, nil
        if gone then
            resetStand(stand)
            st.placed = nil
        elseif hv then
            autoOpen(pn, hv, stand, false)   -- (hidden for now: the player's close stays; access is still followed)
        end
        stand._askedX = nil
        return
    end
    -- a window the mod's menu option opened since last frame: placed before its first draw
    if eng and eng ~= st.placed then
        local ok, err = pcall(S.place, eng, pn)
        if not ok then note("place", err); st.placed = eng end
    end
    if eng then hold(win, eng, pn) end
    local fx, fy, fw, fh = footprint(win)
    local settled = settle(st, win, t, fx, fy, fw, fh)
    if settled and eng then replace(eng, pn, st, fx, fy, fw, fh) end
    autoOpen(pn, v, stand, settled)
    padBack(pn, stand)
    stand._askedX = nil
end

--- Each frame, for each player ZeD draws windows for.
function S.poll()
    local t = getTimestampMs()
    for pn = 0, 3 do
        if ZeD.windowsFor == nil or ZeD.windowsFor(pn) then S.pollOne(pn, t) end
    end
end

--- The one start-up line: on, or which piece is missing.
function S.check()
    local W, C = windowClass(), components()
    local missing = nil
    if not W then missing = "MSC.EngineComponentsWindow"
    elseif not C then missing = "MSC.EngineComponents"
    elseif not signal("MSC_originalPrerender") then missing = "its prerender wrap"
    elseif not signal("MSC_originalDoPartContextMenu") then missing = "its part menu wrap" end
    local ver = type(MSC) == "table" and MSC.VERSION or nil
    if missing then
        print("[ZeD] Summer Car: " .. missing .. " not found (another version of the mod?); its engine window works as without ZeD's support")
    else
        print("[ZeD] Summer Car: on (the mod's " .. tostring(ver or "version not given") .. "; read against "
            .. S.CONTRACT.version .. "): its engine window opens beside the Vehicle tab")
    end
    return missing == nil
end

-- ----------------------------------------------------------------------------
-- THE TAB'S HOOKS (ZeD.MechanicsTab.addExtras)
-- ----------------------------------------------------------------------------
-- The Engine's verbs: the mod's menu wrap drops the game's two engine verbs, and the
-- tab follows; Inspect engine components when there is an engine to look at. With the
-- mod's window or its access test missing or failing, the footer stays as built: the
-- game's two verbs still work, and there would be nothing to offer in their place.
local function verbs(part, chr, list)
    if part:getId() ~= "Engine" or not signal("MSC_originalDoPartContextMenu") then return nil end
    if not (windowClass() and components()) then return nil end
    local r = accessReason(part:getVehicle())
    if r == "missing" or r == "error" then return nil end
    local out = {}
    for _, id in ipairs(list) do
        if id ~= "repairEngine" and id ~= "takeParts" then out[#out + 1] = id end
    end
    -- (no assembly, no car: nothing to inspect, so the verb is gone; the menu keeps the mod's greyed option)
    if not seatedOut(chr) and (r == nil or r == "hoodClosed") then out[#out + 1] = VERB end
    return out
end
S.verbs = verbs

local function needs(part, chr, v)
    local r = accessReason(v)
    if r == nil then
        return { ok = true, rows = { { ok = true, label = ZeD.tr("UI_ZeD_Veh_NothingNeeded"), value = "" } } }
    elseif r == "hoodClosed" then
        return { ok = false, rows = { { ok = false, label = ZeD.tr("IGUI_VehiclePartEngineDoor"), value = ZeD.tr("UI_ZeD_Veh_StClosed") } },
                 line = ZeD.tr("UI_MSC_HoodMustBeOpen"), short = "" }
    end
    return { ok = false, rows = { { ok = false, label = ZeD.tr("UI_ZeD_Veh_RightConditions"), value = "" } },
             line = ZeD.tr("UI_MSC_EngineAssemblyUnavailable"), short = "" }
end
S.needs = needs

-- The mod's Inspect option in the part menu ZeD just opened: pointed at the anchor
-- (its param2 is the hidden game window), with no pad grab (param3, isAutoOpen)
local function partMenu(part, chr, ui)
    if part == nil or part:getId() ~= "Engine" then return end
    local W = windowClass()
    local ctx = ui and ui.context
    if not (W and ctx and type(ctx.options) == "table") then return end
    local want = getText("UI_MSC_InspectEngineComponents")
    for _, o in ipairs(ctx.options) do
        if o.onSelect == W.openFromMechanics and o.param2 == ui then
            o.param2 = S.standIn(chr:getPlayerNum())
            o.param3 = true
        elseif o.name == want and o.param2 == ui then
            note("menu", "the mod's Inspect option no longer calls openFromMechanics; left as it is")
        end
    end
end
S.partMenu = partMenu

S.EXTRA = {
    verbs = verbs,
    partMenu = partMenu,
    verb = { [VERB] = {
        label = "UI_MSC_InspectEngineComponents",          -- the mod's own words
        help = "UI_MSC_InspectEngineComponentsTooltip",
        hint = "UI_MSC_InspectEngineComponentsTooltip",
        primary = true,                                    -- the Engine's only verb under the mod
        needs = needs,
        run = function(part, chr, v) if openable(chr, v) then S.open(chr, part, chr:getPlayerNum()) end end,
    } },
}
local MT = ZeD.MechanicsTab
if MT and MT.addExtras then MT.addExtras(MOD_ID, S.EXTRA) end

-- ----------------------------------------------------------------------------
-- EVENTS (a hot reload takes the old handlers out first)
-- ----------------------------------------------------------------------------
local tickEv = Events.OnTickEvenPaused or Events.OnTick
if OLD and OLD._poll and OLD._tickEv then OLD._tickEv.Remove(OLD._poll) end
if OLD and OLD._death and Events.OnPlayerDeath then Events.OnPlayerDeath.Remove(OLD._death) end
if OLD and OLD._start and Events.OnGameStart then Events.OnGameStart.Remove(OLD._start) end
S._tickEv = tickEv
S._poll = function()
    local ok, err = pcall(S.poll)
    if not ok then note("poll", err); tickEv.Remove(S._poll) end
end
tickEv.Add(S._poll)
-- a death closes the engine window at once and forgets the player's close
S._death = function(player)
    local ok, pn = pcall(function() return player:getPlayerNum() end)
    if not ok or type(pn) ~= "number" then return end
    local eng = anchored(pn)
    if eng then pcall(eng.close, eng, false) end
    if S.stands[pn] then resetStand(S.stands[pn]) end
    S.st[pn] = nil
end
if Events.OnPlayerDeath then Events.OnPlayerDeath.Add(S._death) end
S._start = function() S.check() end
if Events.OnGameStart then Events.OnGameStart.Add(S._start) end
if getPlayer and getPlayer() then S.check() end   -- (a hot reload in the game)

print("[ZeD] ModSupport/MaskaradsSummerCar: loaded")
return S
