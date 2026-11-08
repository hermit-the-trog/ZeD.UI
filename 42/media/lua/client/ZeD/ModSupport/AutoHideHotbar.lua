-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/AutoHideHotbar.lua
-- ============================================================================
-- SUPPORT FOR AUTO-HIDE HOTBAR (mod id AutoHideHotbar, Workshop 3835479468).
-- Client.
--
-- The mod hides the game's hotbar until the pointer comes near it or a hotbar
-- key (1-9) is pressed, with its own look (fade, slide, peek...), timing and
-- "keep shown while" options, all in Options > Mods > Auto-Hide Hotbar. A
-- controller player always sees the bar. It does not draw the hotbar itself:
-- for the length of each frame's drawing it moves the bar by the slide and
-- scales the alpha of every draw, then puts both back.
--
-- Under ZeD the game's hotbar is parked off-screen (Overrides/Belt.lua) and the
-- belt (ZeD_Belt.lua) shows the hotbar's slots, with the hands, the watch and
-- the Messages note on the same strip. The mod therefore hides the belt's item
-- slots only; the hands, the watch and the Messages note stay.
-- So the slots (with the strap and buckle that carry them) hide and come back
-- the way the mod hides the hotbar, and the rest of the belt stays where it is.
-- The mod publishes the call for this,
-- AutoHideHotbar.attach(element, playerNum): another panel fades and slides
-- with the hotbar and its hover counts as the hotbar's. This file attaches the
-- belt (and again after a respawn makes a new one), so every option of the mod
-- works on the slots as the mod draws them: the hotbar keys, the hover margin
-- and the edge zone measured from the belt, the hold and toggle keys, the
-- timings, the look and the motion. For the length of each frame's drawing the
-- mod moves the belt by its slide and swaps its javaObject for one that fades
-- every draw (its _ahbBusy on the belt meanwhile); then:
--   * the belt's hold hook (ZeD.Belt.addHold) keeps the belt from putting itself
--     home mid-frame (the mod puts it back after; the belt checks its home
--     between frames);
--   * the belt's split hook (ZeD.Belt.addSplit) hands the belt the real element,
--     so the strap, the buckle and the slots are drawn through the mod's fade
--     where the mod slid them, and the rest on the real element at home.
--
-- What ZeD adds through the mod's other call, AutoHideHotbar.keepShown:
--   * "The inventory is open" counts ZeD's Character and World windows (the
--     game's inventory pages are not used under ZeD);
--   * the belt stays shown while it is in use: the controller on it, a slot
--     dragged off it, and a menu open while it shows (a slot's list from a held
--     key, the menu of a hand or of another mod's box).
-- Dragging an item, a right-click on the belt, aiming and a vehicle are the
-- mod's own checks (the belt is hidden in a vehicle anyway).
--
-- What stays: the hands, the gun's rounds, the watch, the Messages note, the
-- chat key, the PvP marker and other mods' boxes (the mask's), and the hover
-- boxes and tooltip. The pointer over any of the belt shows the slots (the
-- mod's hover is the attached element's rectangle). A controller player always
-- sees them, as the mod does.
--
-- Safe mode or the belt's own switch off: the belt is not drawn, the game's
-- hotbar is back, and the mod hides that as it always does.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "AutoHideHotbar"

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

require "ZeD/ZeD_Belt"
require "ZeD/SafeMode"
pcall(require, "AutoHideHotbar/AHB_Core")   -- (the mod's file; its global is read when used, whatever the load order)

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.AutoHideHotbar = S

local OWNER = "zed"            -- the attach's owner name
local KEEP_WINDOWS = "zed_windows"
local KEEP_BELT = "zed_belt"
local TICKS = 15               -- the upkeep runs four times a second at 60 frames, as the mod's own does

S.attached = nil               -- the belt now attached
S.keep = {}                    -- what ZeD last told keepShown, per reason

-- the mod's table, or nil while it is not there (or another mod of that name)
local function ahb()
    local A = AutoHideHotbar
    if type(A) == "table" and type(A.attach) == "function" and type(A.detach) == "function" then return A end
    return nil
end
S.ahb = ahb

-- the mod's option, read through its own reader (its default when there is none)
local function opt(A, id)
    if type(A.opt) == "function" then
        local ok, v = pcall(A.opt, id)
        if ok then return v end
    end
    return nil
end

-- Is one of ZeD's inventory windows up? (the Character window holds the inventory, the World window the loot)
local function zedWindowsOpen()
    for _, cls in ipairs({ ZeD_CharacterWindow or false, ZeD_WorldWindow or false }) do
        local w = cls and cls.getWindow and cls.getWindow()
        if w and w.isVisible and w:isVisible() and not w.windowShaded then return true end
    end
    return false
end

-- Is the belt in use: the controller on it, a slot dragged off it, or a menu up while it shows (A: the mod)?
local function beltBusy(A, hud)
    if not hud then return false end
    if hud._gp then return true end
    if hud._out and hud._out.active then return true end
    local ctx = getPlayerContextMenu and getPlayerContextMenu(hud.playerNum or 0)
    if ctx and ctx.isAnyVisible and ctx:isAnyVisible() and type(A.getVisibility) == "function" then
        local ok, v = pcall(A.getVisibility, hud.playerNum or 0)
        if ok and type(v) == "number" and v > 0.5 then return true end
    end
    return false
end

local function keep(A, id, on)
    on = on and true or false
    if S.keep[id] == on then return end
    S.keep[id] = on
    pcall(A.keepShown, 0, id, on)
end

-- Attach the belt there is now (detach one that is gone), and tell the mod what keeps it shown.
function S.upkeep()
    local A = ahb()
    if not A then return end
    local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD() or nil
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on("belt") then hud = nil end
    if S.attached ~= hud then
        if S.attached then pcall(A.detach, S.attached) end
        S.attached = nil
        if hud then
            local ok, err = pcall(A.attach, hud, hud.playerNum or 0, OWNER)
            if ok then S.attached = hud
            elseif ZeD.logOnce then ZeD.logOnce("AutoHideHotbar: the belt could not be attached", err) end
        end
    end
    if type(A.keepShown) == "function" then
        keep(A, KEEP_WINDOWS, hud ~= nil and opt(A, "keepInventory") == true and zedWindowsOpen())
        keep(A, KEEP_BELT, beltBusy(A, hud))
    end
end

local tick = 0
local function onTick()
    tick = tick + 1
    if tick % TICKS ~= 1 then return end
    local ok, err = pcall(S.upkeep)
    if not ok and ZeD.logOnce then ZeD.logOnce("AutoHideHotbar: upkeep", err) end
end
S.onTick = onTick

Events.OnTick.Add(onTick)
-- the mod's slide stands for the frame it draws in (it sets _ahbBusy on the element for that long)
ZeD.Belt.addHold(MOD_ID, function(hud) return rawget(hud, "_ahbBusy") == true end)
-- ... for the slots only: the real element under the mod's fading stand-in (its proxy table keeps it as _ahbReal; with
-- no fade this frame the javaObject is the real one, only moved)
function S.split(hud)
    if rawget(hud, "_ahbBusy") ~= true then return nil end
    local j = rawget(hud, "javaObject")
    if type(j) == "table" and rawget(j, "_ahbReal") ~= nil then return rawget(j, "_ahbReal") end
    return j
end
ZeD.Belt.addSplit(MOD_ID, S.split)
Events.OnGameStart.Add(function() S.keep = {}; tick = 0 end)   -- (a belt from before is detached by the next upkeep)

print("[ZeD] ModSupport: Auto-Hide Hotbar (the belt's slots hide and show as the mod's hotbar)")
