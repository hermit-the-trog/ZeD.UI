-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/MinimalSidebar.lua
-- ============================================================================
-- SUPPORT FOR MINIMAL SIDEBAR (mod id MinimalSidebar, Workshop 3642084851, by
-- Devilzcore; its options are filed as MinimalSideBar).
--
-- The mod fades the game's left-edge column (ISEquippedItem) out until the
-- pointer is near it: it replaces the column's prerender and render, steps one
-- fade a frame (the column fades at 0.10 of the gap a frame, a hand slot at
-- 0.15, both times the Animation Speed), keeps a hand slot that holds something,
-- and hands each button a hook that scales its colors. Its options are three, in
-- Options > Mods > Minimal Sidebar: Enable Mod, Show Heart on Pulse (the heart
-- button shows for a few seconds after damage even while the column is faded)
-- and Animation Speed (0.5x to 5.0x, 1.0x by default).
--
-- Under ZeD the column is hidden and the belt (ZeD_Belt.lua) is the HUD, and the
-- belt draws the hands itself, so the mod's render never runs and nothing is
-- faded. This file gives the belt the mod's fade with the mod's numbers and its
-- options, read the way the mod reads them (PZAPI.ModOptions, option by option):
--   * Enable Mod off: the belt is drawn as it is.
--   * the strap, the buckle and the hotbar slots fade out until the pointer is
--     within a margin of the belt (the mod's fifty pixels, scaled with the UI)
--     and fade back in when it is;
--   * a hand circle (and the ammo tab that comes out from under the main hand)
--     stays while it holds something and fades when the hand is empty, each on
--     its own;
--   * Animation Speed scales both fades as the mod scales them;
--   * the belt stays shown while it is in use: the controller on it, a slot
--     dragged off it, a menu open from it while it shows.
-- The watch, the Messages note, the chat key, the PvP marker and other mods' boxes
-- stay, as with Auto-Hide Hotbar. Show Heart on Pulse has nothing to show: the
-- belt has no heart button (health is the Character window's), so that option
-- does nothing under ZeD.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "MinimalSidebar"
local OPTIONS_ID = "MinimalSideBar"

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

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.MinimalSidebar = S

-- the mod's numbers
local FADE_RATE = 0.1               -- the column's fade, of the gap a frame (times the speed)
local HAND_RATE = 0.15              -- a hand slot's fade
local MARGIN = 50                   -- the pointer's reach around the column (pixels at 1x; the belt scales it)
local SPEEDS = { 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 }   -- Animation Speed's items, by index
local SPEED_DEFAULT = 2             -- its default item (1.0x)

S.state = {}                        -- per player: fade, main, off (0..1), and on (the mod is enabled)

-- the mod's options object, or nil while there is none
local function options()
    local P = PZAPI and PZAPI.ModOptions
    if type(P) ~= "table" or type(P.getOptions) ~= "function" then return nil end
    local ok, o = pcall(P.getOptions, P, OPTIONS_ID)
    if ok and type(o) == "table" and type(o.getOption) == "function" then return o end
    return nil
end

-- one option's value as the mod reads it (opt:getValue()), or the mod's own default
local function value(id, default)
    local o = options()
    if not o then return default end
    local ok, opt = pcall(o.getOption, o, id)
    if not ok or type(opt) ~= "table" or type(opt.getValue) ~= "function" then return default end
    local ok2, v = pcall(opt.getValue, opt)
    if ok2 and v ~= nil then return v end
    return default
end

function S.enabled() return value("EnableMinimalSidebar", true) ~= false end

-- Animation Speed: the item's index (the combo's value) into the speeds, 1x when it is not a number
function S.speed()
    local v = value("AnimationSpeed", SPEED_DEFAULT)
    if type(v) == "number" then return SPEEDS[v] or 1 end
    if type(v) == "string" then return tonumber(string.match(v, "[%d%.]+")) or 1 end
    return 1
end

-- the mod's own step: a value moves toward its target by a part of the gap, and lands when it is close
local function lerp(a, target, rate)
    local d = target - a
    if math.abs(d) > 0.001 then return a + d * rate end
    return target
end
S.lerp = lerp

local function stateFor(pn)
    local st = S.state[pn]
    if not st then st = { fade = 1, main = 1, off = 1, on = false }; S.state[pn] = st end
    return st
end

-- is the belt in use: the controller on it, a slot dragged off it, or a menu open while it shows
local function busy(hud, st)
    if hud._gp then return true end
    if hud._out and hud._out.active then return true end
    local ctx = getPlayerContextMenu and getPlayerContextMenu(hud.playerNum or 0)
    if ctx and ctx.isAnyVisible and ctx:isAnyVisible() and st.fade > 0.5 then return true end
    return false
end

-- is the pointer on the belt or within the margin of it
local function pointerNear(hud)
    local m = ZeD.T and ZeD.T.px and ZeD.T.px(MARGIN) or MARGIN
    local mx, my = hud:getMouseX(), hud:getMouseY()
    return mx > -m and my > -m and mx < hud:getWidth() + m and my < hud:getHeight() + m
end

-- once a frame, as the mod's prerender steps its column
function S.frame(hud)
    local pn = hud.playerNum or 0
    local st = stateFor(pn)
    if not S.enabled() then
        st.fade, st.main, st.off, st.on = 1, 1, 1, false
        return
    end
    st.on = true
    local k = S.speed()
    local rate, hand = FADE_RATE * k, HAND_RATE * k
    st.fade = lerp(st.fade, (pointerNear(hud) or busy(hud, st)) and 1 or 0, rate)
    local p = hud:player()
    st.main = lerp(st.main, (p and p:getPrimaryHandItem()) and 1 or 0, hand)
    st.off = lerp(st.off, (p and p:getSecondaryHandItem()) and 1 or 0, hand)
end

-- a part's alpha: the strap, the buckle and the slots follow the fade; a hand and the ammo tab keep what they hold
function S.alpha(hud, kind, box)
    local st = S.state[hud.playerNum or 0]
    if not st or not st.on then return nil end
    if kind == "strap" or kind == "slot" then return st.fade end
    if kind == "hand" then
        return math.max(box and box.which == "s" and st.off or st.main, st.fade)
    end
    if kind == "ammo" then return math.max(st.main, st.fade) end
    return nil
end

ZeD.Belt.addAlpha(MOD_ID, { frame = S.frame, alpha = S.alpha })

print("[ZeD] ModSupport: Minimal Sidebar (the belt fades as the mod's column does)")
