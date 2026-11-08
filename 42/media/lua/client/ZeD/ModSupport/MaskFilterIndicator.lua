-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/MaskFilterIndicator.lua
-- ============================================================================
-- SUPPORT FOR MASK FILTER INDICATOR (mod id MaskFilterIndicator, Workshop
-- 3832759095, by movinow). Nov 7 2026.
--
-- While a gas mask, a respirator, an improvised mask or an SCBA (oxygen tank)
-- is worn, the mod shows a strip above the game's hotbar (MaskFilterIndicatorHUD;
-- above the game's dash while driving, or anywhere with its "Free" position):
-- the mask's picture, ten blocks of filter (or oxygen) left, a pip per spare
-- filter carried or within reach, a lamp to turn an SCBA on or off, and its
-- right-click menu (take the mask off, turn the tank on or off, attach or
-- replace a filter or tank). Holding the reload key (R) and its slice on the
-- firearm wheel replace the filter too. Its options: the position, Always or
-- only when low (a quarter or less), keep the mask on while replacing, a note
-- when it runs out, and a blink while the filter is being used up.
--
-- Under ZeD the game's hotbar is parked off-screen, so the strip sat off-screen
-- with it. This file puts the same information on the belt, through the belt's
-- general hook ZeD.Belt.addBox: a box of its own after the strap, a slot's size,
-- drawn like a slot:
--   * the worn mask's picture, and the belt's ten-segment strip under it at the
--     filter (or oxygen) left, in the condition's graduated colors; an empty
--     well when no filter or tank is fitted;
--   * the spares as a count on the box's top left, where a slot shows its key;
--   * the lamp a lit light shows, while an SCBA is turned on, or while a filter
--     is being used up (the mod's blink option on): the mask is working;
--   * the hover hint: the mask's name, what is left ("64% left", or the game's
--     own "No Filter" / "No Tank") and the spares (the mod's own "No spare filter"
--     when there are none);
--   * a click, a right-click, A or X: the mod's own menu (its right-click on the
--     strip, run as it is), in ZeD's context menu; on a controller the menu opens
--     on the box and the pad comes back to the belt after.
-- The mod's "Alert (only when low)" shows the box only at a quarter or less, or
-- with nothing fitted, as the mod shows its strip. The box follows the belt: it
-- shows where the belt does. In a vehicle the belt is hidden and ZeD's dash
-- replaces the game's (where the mod put its strip), so the mask goes on the
-- dash (the director, Nov 7 2026), through the dash's general hook
-- ZeD.Dashboard.addExtra, the same reading and the same Alert option:
--   * the simple dash: one item in its Readouts row, "Gas Mask: 64% left |
--     spares: 2" (the hint's words);
--   * the pixel dashes: a small mark on the plate's top edge, left end (after
--     "Passenger" in a passenger's seat), in the edge's own ink: a mask in plate
--     pixels, ten blocks of filter left (amber at a quarter or less, red at a
--     tenth; all dark with nothing fitted) and "+2" for the spares.
-- The mod's R key and firearm wheel slice still work there. The position option
-- has no meaning under ZeD: the mask is on the belt, or on the dash.
-- The mod's strip is parked off-screen while ZeD's belt is in charge (no stray
-- panel catching clicks where a "Free" strip was), and comes back as the mod
-- left it in safe mode. The numbers are the mod's own, read through its public
-- functions every half second; ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "MaskFilterIndicator"

-- Is the mod switched on? getActivatedMods() is a Java list of mod ids; a
-- workshop id can carry a leading backslash, which is cut off before comparing.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tr"
require "ZeD/ZeD_Belt"
require "ZeD/SafeMode"
pcall(require, "ZeD/ZeD_Dashboard")      -- (the dash's hook; the file loads without it)
pcall(require, "MaskFilterIndicatorOptions")   -- (the mod's files; its globals are read when used, whatever the load order)
pcall(require, "MaskFilterIndicator")
pcall(require, "MaskFilterIndicatorHUD")

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.MaskFilterIndicator = S

local LOW = 0.25          -- the mod's "low": a quarter or less (its Alert option)
local READ_MS = 500       -- the mask, its spares and its drain are read again this often (the mod: every 30 ticks)
local PARK = -100000

-- the mod's tables, or nil while they are not there
local function mfi()
    local M = MaskFilterIndicator
    if type(M) == "table" and type(M.findWornMask) == "function" and type(M.hasDrainable) == "function" then return M end
    return nil
end
local function opts()
    local O = MaskFilterIndicatorOptions
    if type(O) == "table" then return O end
    return nil
end
-- a function of one of the mod's tables (o.m(...)), nil when it is missing or throws
local function call(o, m, ...)
    local f = o and o[m]
    if type(f) ~= "function" then return nil end
    local ok, r = pcall(f, ...)
    if ok then return r end
    return nil
end

-- Is ZeD's belt in charge of the hotbar (so the mod's strip is parked)?
function S.zedOwns()
    if not (ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()) then return false end
    return not (ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on("belt"))
end

-- ----------------------------------------------------------------------------
-- What the box shows: read at most every READ_MS (the spares scan every container in reach)
-- ----------------------------------------------------------------------------
local cache = { at = nil, p = nil, st = nil }
S.cache = cache

local function read(p)
    local M = mfi()
    if not M or M.disabled then return nil end
    local ok, mask, cfg = pcall(M.findWornMask, p)
    if not ok or not mask or type(cfg) ~= "table" then return nil end
    local okH, has = pcall(M.hasDrainable, mask, cfg)
    has = okH and has == true
    local delta = 0
    if has then
        local okD, d = pcall(mask.getUsedDelta, mask)
        delta = (okD and type(d) == "number") and math.max(0, math.min(1, d)) or 0
    end
    local O = opts()
    -- the mod's Alert option: only when low, or with nothing fitted
    if O and call(O, "getHudMode") == 2 and has and delta > LOW then return nil end
    local spares = call(M, "listSpareFilters", p, cfg)
    local nSpares = type(spares) == "table" and #spares or 0
    local tank = cfg.isTank == true
    local lit = false
    if tank then
        local okA, a = pcall(mask.isActivated, mask)
        lit = okA and a == true
    elseif O and call(O, "isShowDrainBlink") ~= false and type(MaskFilterIndicatorHUD) == "table" then
        local drain = call(MaskFilterIndicatorHUD, "getFilterDrainStrength", p, mask, cfg)
        lit = type(drain) == "number" and drain > 0
    end
    return {
        item = mask, cfg = cfg, tank = tank, has = has, delta = delta, spares = nSpares,
        meter = delta,                                       -- (no filter: the empty well)
        lit = lit,
        badge = nSpares > 0 and ("+" .. tostring(nSpares)) or nil,
        key = "mask",                                        -- (one box, always a slot's size: nothing in it moves the layout)
    }
end
S.read = read

-- B.addBox's state: the table above, or nil (no box)
function S.state(p)
    if not p then return nil end
    local now = getTimestampMs and getTimestampMs() or 0
    if cache.at == nil or cache.p ~= p or now - cache.at >= READ_MS or now < cache.at then
        local ok, st = pcall(read, p)
        cache.at, cache.p, cache.st = now, p, ok and st or nil
    end
    return cache.st
end

-- the words: the mask's name, what is left ("64% left", or the game's "No Filter" / "No Tank"), the spares
function S.words(st)
    local okN, name = pcall(st.item.getDisplayName, st.item)
    if not okN or type(name) ~= "string" then name = "" end
    local left
    if st.has then left = ZeD.tr("UI_ZeD_Belt_MaskLeft", tostring(math.floor(st.delta * 100 + 0.5)))
    else left = getText(st.tank and "Tooltip_NoTank" or "Tooltip_NoFilter") end
    local spare
    if st.spares > 0 then spare = ZeD.tr("UI_ZeD_Belt_MaskSpares", tostring(st.spares))
    else spare = getText(st.tank and "UI_MFI_NoSpareTank" or "UI_MFI_NoSpareFilter") end
    return name, left, spare
end

-- the hover hint: "Gas Mask | 64% left | spares: 2"
function S.hint(st)
    local name, left, spare = S.words(st)
    return name .. " | " .. left .. " | " .. spare
end

-- the mod's own menu (its right-click on the strip, run as it is); on a controller, anchored on the box
function S.menu(playerNum, st, x, y, pad)
    local H = MaskFilterIndicatorHUD
    if type(H) ~= "table" or type(H.onRightMouseUp) ~= "function" then return nil end
    H.onRightMouseUp({ mask = st.item, cfg = st.cfg }, 0, 0)
    local ctx = getPlayerContextMenu and getPlayerContextMenu(playerNum or 0)
    if ctx and pad then
        ctx._zedAnchorMode = "cursor"
        ctx._zedAnchorX, ctx._zedAnchorY = x, y
    end
    cache.at = nil   -- (what it does shows at once)
    return ctx
end

ZeD.Belt.addBox(MOD_ID, { state = S.state, hint = S.hint, menu = S.menu })

-- ----------------------------------------------------------------------------
-- On the dash, in a vehicle (ZeD.Dashboard.addExtra)
-- ----------------------------------------------------------------------------
-- the simple dash's readout: "Gas Mask: 64% left | spares: 2"
function S.cell(st)
    local name, left, spare = S.words(st)
    return name, left .. " | " .. spare
end

-- the plate's mark, in plate pixels, 5 tall as the edge's words: a mask (7 wide), ten blocks of 2 with a gap of 1, the
-- spares in the edge's face. The blocks lit count is rounded up, as the belt's strip: a sliver left is one block.
local GLYPH = { 1, 0, 5, 1,  0, 1, 2, 1,  3, 1, 1, 1,  5, 1, 2, 1,  0, 2, 7, 1,  1, 3, 5, 1,  2, 4, 3, 1 }
local LOW_INK, OUT_INK = "#ffb02e", "#ff3a20"   -- the dash's worn and poor lamp colors (ZeD_Dashboard D.LAMP_COLOR)
S.GLYPH = GLYPH
function S.lit(st)
    if not st.has then return 0 end
    return math.min(10, math.ceil(st.delta * 10 - 1e-9))
end
function S.mark(cv, x, y, ink, shadow, st)
    local P = ZeD.Px
    if not P then return 0 end
    local lit = S.lit(st)
    local bar = ink
    if not st.has or st.delta <= 0.1 then bar = P.color(OUT_INK)
    elseif st.delta <= LOW then bar = P.color(LOW_INK) end
    local sh = shadow and P.color(shadow) or nil
    local bx = x + 10
    if sh then
        P.rects(cv, GLYPH, sh, 1, x + 1, y + 1)
        for i = 0, lit - 1 do P.rect(cv, bx + i * 3 + 1, y + 1, 2, 5, sh) end
    end
    P.rects(cv, GLYPH, (st.has and st.delta > 0.1) and ink or bar, 1, x, y)
    for i = 0, 9 do
        if i < lit then P.rect(cv, bx + i * 3, y, 2, 5, bar)
        else P.rect(cv, bx + i * 3, y, 2, 5, ink, 0.3) end
    end
    local w = 10 + 29
    if st.spares > 0 then
        w = w + 3 + (P.text(cv, "+" .. tostring(st.spares), x + w + 3, y, ink, "35", 1, "l", nil, shadow) or 0)
    end
    return w
end

local Dash = ZeD.Dashboard
if Dash and Dash.addExtra then
    Dash.addExtra(MOD_ID, { state = function(chr) return S.state(chr) end, cell = S.cell, mark = S.mark })
end

-- ----------------------------------------------------------------------------
-- The mod's own strip: parked while the belt is in charge, its own again in safe mode
-- ----------------------------------------------------------------------------
local function park(self)
    if not self._zedParked then self._zedParked = { keep = self.keepOnScreen } end
    self.keepOnScreen = false         -- (a top-level panel is clamped onto the screen otherwise)
    if self:getX() ~= PARK then self:setX(PARK) end
    if self:getY() ~= PARK then self:setY(PARK) end
    self._posRestored = false         -- (back from safe mode, its "Free" place is read again from the character)
    self.ledRect = nil
end
local function unpark(self)
    local pk = self._zedParked
    if not pk then return end
    self._zedParked = nil
    self.keepOnScreen = pk.keep
end
S.park, S.unpark = park, unpark

local wrapped = false
function S.wrapStrip()
    local H = MaskFilterIndicatorHUD
    if wrapped or type(H) ~= "table" or type(H.render) ~= "function" then return false end
    wrapped = true
    local origRender = H.render
    S.origRender = origRender
    function H:render(...)
        if S.zedOwns() then
            local ok = pcall(park, self)
            if ok then return end
        end
        pcall(unpark, self)
        return origRender(self, ...)
    end
    return true
end
-- (the mod's files may load after this one: wrapped here when they are there, else at game start)
S.wrapStrip()
Events.OnGameStart.Add(function() S.wrapStrip(); cache.at = nil end)

print("[ZeD] ModSupport: Mask Filter Indicator (the worn mask's filter on the belt, and on the dash in a vehicle)")
