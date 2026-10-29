-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/moodle_quarters.lua
-- ============================================================================
-- SUPPORT FOR MOODLE QUARTERS [B42] (mod id moodle_quarters, Workshop 2854030563).
--
-- The mod squares off one more quarter of each moodle's round backing per level
-- (its client MoodleQuarters.lua). To do it, it takes the game's moodle column
-- (MoodlesUI) off the screen and draws the whole stack itself on a panel of its
-- own (MoodleQuartersUI): its plates, the game's icons on top, in a fixed order
-- (the order the game lists the moodle types, not the game's shuffled one), at
-- the right edge, as high as the game's column sits. Its hover text is the game's.
--
-- ZeD only places the moodles (right edge, left edge, or a row above the belt)
-- and draws the hover note. Left alone, the mod's panel stays at the right edge
-- whatever ZeD's place, sits off screen with the game's column in the row, and
-- ZeD's note can name a different moodle (ZeD counts in the game's order). So:
--   * ZeD is told the mod draws the moodles in place of the game's column, and
--     in which order (ZeD.Moodles.setStandIn): ZeD's note then follows the mod's
--     order, and in the row ZeD draws no copy of its own;
--   * the mod's panel goes where ZeD put the moodles (ZeD.Moodles.rect), each
--     frame, in all three places;
--   * in the row, the mod's own drawing is turned on its side: each plate the mod
--     draws at "down the column" is drawn at "along the row" instead. The mod
--     still draws every plate and icon, with its own art, slide and wiggle.
-- When the mod hands the stack back to the game (its plates missing), ZeD works
-- as without it. Safe mode: the mod's panel goes back to its own place.
-- ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "moodle_quarters"

-- Is the mod on in this game? getActivatedMods() is a Java list of mod ids.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    -- Java lists count from 0, so the loop runs 0 .. size - 1
    for i = 0, list:size() - 1 do
        -- some ids come back with a leading backslash; gsub strips it
        -- (gsub returns two values; the extra one is dropped by "local id =")
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
-- "return" at the top level of a file ends the file: nothing below runs
if not modOn() then return end

require "ZeD/ZeD_Moodles"
-- Make sure the mod's file has run before this one looks at it. pcall ("protected
-- call") runs require and catches any error instead of stopping this file.
pcall(require, "MoodleQuarters")

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.moodle_quarters = S

local M = ZeD.Moodles

-- The mod's main table and its panel class are globals it makes; nil if it failed
local function MQ() return type(MoodleQuarters) == "table" and MoodleQuarters or nil end

-- Say a problem once in the console (not every frame)
local said = {}
local function warnOnce(what, err)
    if said[what] then return end
    said[what] = true
    print("[ZeD] moodle_quarters: " .. what .. ": " .. tostring(err))
end

-- The mod's panel for this player, while it is the one drawing, else nil.
-- (The mod marks a panel detachRequested when it is about to hand the stack back.)
function S.panel(playerNum)
    local mq = MQ()
    local panels = mq and mq.panels
    local panel = panels and panels[playerNum or 0]
    if panel and not panel.detachRequested then return panel end
    return nil
end

-- ---------------------------------------------------------------------------
-- The mod's drawing, followed through. These two stand in for the panel's own
-- drawTexture (ISUIElement's) for the length of one render: "self" is the panel,
-- x / y are where the mod asks for the texture, inside its panel.
-- Each also notes how far the plates reach (S.extent, for QA; numbers only, so
-- nothing new is made each frame).
-- ---------------------------------------------------------------------------
local baseDraw = nil   -- the panel's own drawTexture, kept when the wrap goes on

local function note(self, x, y)
    local s = self.size or 0
    local e = self._zedExtent
    e.n = e.n + 1
    -- math.min / math.max keep the smallest left / top and the largest right / bottom
    e.x0, e.y0 = math.min(e.x0, x), math.min(e.y0, y)
    e.x1, e.y1 = math.max(e.x1, x + s), math.max(e.y1, y + s)
end

-- Column (right / left): drawn where the mod asks
local function columnDraw(self, texture, x, y, a, r, g, b)
    note(self, x, y)
    return baseDraw(self, texture, x, y, a, r, g, b)
end

-- Row (bottom): the mod's y is how far down the column the plate is (slot x
-- (size + 10), plus its slide), its x the sideways wiggle. Along the row both
-- go across: x = y + x, and every plate sits on the row's top line (y = 0).
local function rowDraw(self, texture, x, y, a, r, g, b)
    note(self, y + x, 0)
    return baseDraw(self, texture, y + x, 0, a, r, g, b)
end

-- ---------------------------------------------------------------------------
-- The wrap: three of the panel's own methods get a ZeD step after (or around)
-- the mod's. Wrapping the class (MoodleQuartersUI) reaches every panel, old and
-- new, because a panel looks its methods up in the class.
-- ---------------------------------------------------------------------------
local wrapped = false

local function wrap()
    local UI = MoodleQuartersUI
    -- the class must exist and have the three methods this file expects
    if type(UI) ~= "table" then return false end
    if UI._zedWrapped then wrapped = true; return true end
    local origGeometry, origSlots, origRender = UI.updateGeometry, UI.updateSlots, UI.render
    if type(origGeometry) ~= "function" or type(origSlots) ~= "function" or type(origRender) ~= "function"
        or type(UI.drawTexture) ~= "function" then
        warnOnce("wrap", "the mod's panel is not as expected; ZeD leaves it alone")
        return false
    end
    baseDraw = UI.drawTexture
    -- a flag on the class itself: if the mod's file runs again it makes a new class
    -- (without the flag), and the next wrap() wraps that one
    UI._zedWrapped = true

    -- After the mod places its panel (right edge, the game's column's height):
    -- move it to where ZeD put the moodles. ("function UI:name()" is short for
    -- "UI.name = function(self)", so self is the panel.)
    function UI:updateGeometry()
        local ok, err = pcall(origGeometry, self)
        if not ok then warnOnce("updateGeometry", err) end
        local r = M.rect(self.playerNum)
        if r then
            if self:getX() ~= r.x then self:setX(r.x) end
            if self:getY() ~= r.y then self:setY(r.y) end
        end
    end

    -- After the mod sizes its panel to its column: in the row, the row's size
    -- (so the panel lies exactly over ZeD's row)
    function UI:updateSlots(moodles, tick)
        local ok, err = pcall(origSlots, self, moodles, tick)
        if not ok then warnOnce("updateSlots", err) end
        local row = self._zedRow
        if row then
            if self:getWidth() ~= row.w then self:setWidth(row.w) end
            if self:getHeight() ~= row.h then self:setHeight(row.h) end
        end
    end

    -- Around the mod's drawing: decide column or row for this frame, put the
    -- matching draw in front of the panel's own, run the mod's render, take it off.
    -- A value set on the panel itself ("self.drawTexture = ...") is found before
    -- the class's; setting it back to nil uncovers the class's again.
    function UI:render()
        local r = M.rect(self.playerNum)
        self._zedRow = (r and r.place == "bottom") and r or nil
        -- while ZeD places the moodles, the hover note is ZeD's: forget any moodle
        -- the mod last saw the pointer on (e.g. from safe mode), so it draws no text
        if r then self.mouseOverSlot = nil end
        self._zedExtent = self._zedExtent or {}
        local e = self._zedExtent
        -- a huge start for the smallest, a tiny one for the largest
        e.n, e.x0, e.y0, e.x1, e.y1 = 0, 999999, 999999, -999999, -999999
        self.drawTexture = self._zedRow and rowDraw or columnDraw
        local ok, err = pcall(origRender, self)
        self.drawTexture = nil
        if not ok then warnOnce("render", err) end
        self._zedDrawnAt = getTimestampMs()   -- (for QA: the mod's render ran)
    end

    wrapped = true
    return true
end

-- Tell ZeD the mod draws the moodles, in its own order (its MoodleQuarters.moodles:
-- { id = "ENDURANCE", icon = "Status_DifficultyBreathing" }, ... in ZeD's
-- { key, art } shape). Only while the wrap is on and the mod's panel is drawing:
-- otherwise ZeD's row would stay empty with the mod's panel out of sight.
local function standIn()
    local mq = MQ()
    if not (mq and type(mq.moodles) == "table") then return false end
    local order = {}
    for _, e in ipairs(mq.moodles) do
        if type(e) == "table" and e.id then order[#order + 1] = { e.id, e.icon } end
    end
    if #order == 0 then return false end
    M.setStandIn({
        id = MOD_ID,
        order = order,
        -- (the flag on the class: a fresh copy of the mod's class is not wrapped yet)
        drawing = function(playerNum)
            return type(MoodleQuartersUI) == "table" and MoodleQuartersUI._zedWrapped == true and S.panel(playerNum) ~= nil
        end,
    })
    return true
end

-- Set up now (the mod's file has normally run already) and again when a game
-- starts (in case it ran later, or ran again).
local function setup()
    local ok, res = pcall(wrap)
    if not ok then warnOnce("setup", res); wrapped = false; return end
    if res then
        local ok2, err = pcall(standIn)
        if not ok2 then warnOnce("standIn", err) end
    end
end
setup()
Events.OnGameStart.Add(setup)

print("[ZeD] moodle_quarters: support loaded (wrapped " .. tostring(wrapped) .. ")")
return S
