-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/ImmersiveMoodles.lua
-- ============================================================================
-- SUPPORT FOR IMMERSIVE MOODLES (mod id ImmersiveMoodles, Workshop 3830422267,
-- by Krovenox). Client.
--
-- The mod replaces the game's moodles with an animated column of its own (IMHud): its
-- own icons and frames per level, level bars beside each tile, its own hover text, at
-- the right or left edge (its "HudLeft" option), starting below the game's clock. It
-- hides the game's moodle column by parking it off screen every frame
-- (IM_Main.lua hideVanilla). Unless its "Show Immersive HUD" option is off: then it
-- leaves the game's moodles alone and only draws its screen effects.
--
-- ZeD places the game's column every frame too (ZeD_Moodles.lua), so without this file
-- the two fought: the game's column came back where ZeD puts it, with ZeD's hover note,
-- and every moodle showed twice.
--
-- While the mod's HUD is drawing for a player, ZeD leaves the moodles to it
-- (ZeD.Moodles.setStandIn with whole = true): ZeD places nothing, draws no row and no
-- note, and the game's column stays where the mod parked it. The mod's own options
-- decide the side and the top. One thing ZeD adds: the mod steps below the game's
-- clock, which ZeD's watch hides and draws in its place, so on the right its column's
-- top is kept below ZeD's corner watch (its "Moodle top offset" read as at least that).
-- With the mod's HUD off, ZeD works as without it. Safe mode: ZeD leaves the mod alone.
-- ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "ImmersiveMoodles"

-- Is the mod on in this game? getActivatedMods() is a Java list of mod ids.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        -- some ids come back with a leading backslash; gsub strips it
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/ZeD_Moodles"
-- the mod's options table first (IM.opt), caught if it fails. (Not its main file: that one
-- adds its event handlers when it runs, and the game runs it anyway.)
pcall(require, "ImmersiveMoodles/IM_Config")

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.ImmersiveMoodles = S

local M = ZeD.Moodles

-- The mod's table, a global it makes; nil if it failed to load
local function IM() return type(ImmersiveMoodles) == "table" and ImmersiveMoodles or nil end

local said = {}
local function warnOnce(what, err)
    if said[what] then return end
    said[what] = true
    print("[ZeD] ImmersiveMoodles: " .. what .. ": " .. tostring(err))
end

-- True while the mod's HUD draws the moodles for this player: its HUD is on (decided
-- when the player is made: hudOff false) and it made a HUD panel for the player (its
-- elements list is { effects, hud } then, { effects } with the HUD off)
function S.drawing(playerNum)
    local im = IM()
    if not im or im.hudOff ~= false then return false end
    if ZeD.Safe and ZeD.Safe.on("moodles") then return false end
    local els = type(im.elements) == "table" and im.elements[playerNum or 0]
    return type(els) == "table" and els[2] ~= nil
end

-- The lowest the mod's column may start on the right, in pixels from the top of the
-- screen: under ZeD's corner watch (only the corner watch; a belt watch popped open sits
-- wherever it was dragged), as ZeD's own right column does. nil when there is none.
local function underWatch()
    local w = ZeD.Watch and ZeD.Watch.getInstance and ZeD.Watch.getInstance() or nil
    if not (w and w:getIsVisible() and w:getHeight() > 0 and not w._belt) then return nil end
    return math.floor(w:getY() + w:getHeight() - getPlayerScreenTop(0) + ZeD.T.px(10))
end

-- The mod reads its options through its own IM.opt(name, default) each frame. Wrapped:
-- "HudOffsetY" (the first moodle's distance from the top) is at least the watch's
-- clearance while the column is on the right. The player's own setting wins when lower
-- on the screen. Everything else passes through untouched.
local wrapped = false
local function wrap()
    local im = IM()
    if not (im and type(im.opt) == "function") then return false end
    if im._zedWrapped then wrapped = true; return true end
    local baseOpt = im.opt
    im.opt = function(name, def)
        local v = baseOpt(name, def)
        if name == "HudOffsetY" and S.drawing(0) then
            local ok, side = pcall(baseOpt, "HudSide", 1)
            if ok and side ~= 2 then
                local ok2, minTop = pcall(underWatch)
                if ok2 and minTop and (tonumber(v) or 0) < minTop then return minTop end
            end
        end
        return v
    end
    im._zedWrapped = true
    wrapped = true
    return true
end

-- Tell ZeD the mod draws the moodles in whole (ZeD places nothing and draws no note)
local function standIn()
    M.setStandIn({ id = MOD_ID, whole = true, drawing = S.drawing })
end

local function setup()
    local ok, res = pcall(wrap)
    if not ok then warnOnce("wrap", res) end
    local ok2, err = pcall(standIn)
    if not ok2 then warnOnce("standIn", err) end
end
setup()
Events.OnGameStart.Add(setup)

print("[ZeD] ImmersiveMoodles: support loaded (wrapped " .. tostring(wrapped) .. ")")
return S
