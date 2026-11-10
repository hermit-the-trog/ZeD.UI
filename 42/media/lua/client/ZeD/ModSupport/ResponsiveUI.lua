-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/ResponsiveUI.lua
-- ============================================================================
-- SUPPORT FOR RESPONSIVE CONTEXT MENUS [B42] (mod id ResponsiveUI, Workshop
-- 3783387236). Client. ZeD's right-click menu, strip or list, follows the
-- mod's live rebuilds.
--
-- While a right-click menu is open the mod builds it again every quarter
-- second through the game's own builders (the inventory, empty-pane and world
-- menus), so options come and go as things change: Read once there is light,
-- Put in Container once in range. Each rebuild clears the game's menu first.
-- ZeD draws its own menu from the game's options and closes it when the game's
-- menu is cleared, so without this file ZeD's menu closed and opened again four
-- times a second: the selection went back to the first action, an open submenu
-- shut, and the controller lost its row.
--   * Through the mod's rebuild ZeD's menu stays open (Overrides/ContextMenu.lua:
--     ZeD.ContextMenu.holdOnClear); the rebuilt options then go to it
--     (ZeD.ContextMenu.refreshInPlace), which keeps its place, its open submenus
--     and its selected row, found again by name. Labels, greyed rows, warning
--     colors and balloons follow the new options.
--   * The lit outline is put back in the same tick, so the world never draws a
--     frame without it.
--   * When the mod closes the menu (what it acts on is gone), ZeD's goes too.
--   * An option the mod keeps open (option.responsiveUIKeepOpen = true) keeps
--     ZeD's menu and its open submenu after it is used, and the mod rebuilds it
--     at once, as the mod does for the game's menu.
--   * A press anywhere reaches the game's hidden menu as a press outside it, and
--     the game hid it, which ended the mod's watch on the menu. While ZeD's menu
--     is up, ZeD's menu decides (it closes itself on a press outside).
-- Safe mode: the game's menu shows, and the mod works on it as without ZeD.
-- ZeD stores nothing.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "ResponsiveUI"

-- Is the mod on? An id from getActivatedMods() can carry a leading backslash.
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

require "ISUI/ISContextMenu"
require "ZeD/SafeMode"
require "ZeD/ContextMenuRegistry"
require "ZeD/Overrides/ContextMenu"
require "ZeD/ZeD_StepAside"

ZeD.ModSupport = ZeD.ModSupport or {}
local S = { holding = nil, refreshed = nil }
ZeD.ModSupport.ResponsiveUI = S
local CM = ZeD.ContextMenu

-- the mod only adds to the game's menus: it never takes a screen
if ZeD.StepAside and ZeD.StepAside.support then ZeD.StepAside.support(MOD_ID) end

local function controller() return ResponsiveUI and ResponsiveUI.controller or nil end

-- The game's menu for a player and ZeD's open menu over it (nil when none is open).
local function heldFor(playerNum)
    local root = getPlayerContextMenu and getPlayerContextMenu(playerNum)
    local held = root and root._zedMenu
    if held and held._ctx and held._ctx.open then return root, held end
    return root, nil
end

-- ZeD's menu stays up through the clear of the one menu the mod is rebuilding.
CM.holdOnClear = function(menu) return S.holding ~= nil and S.holding == menu end

-- A keep-open option: after it runs, the menu stays when the mod is watching it, and the mod rebuilds it at
-- once (def.keepOpen is read by the menus right after onFire).
CM.decorateDef = function(def, option, vanillaMenu)
    if option.responsiveUIKeepOpen ~= true then return end
    local fire = def.onFire
    def.onFire = function(target)
        if fire then fire(target) end
        local c = controller()
        local pn = vanillaMenu and vanillaMenu.player or 0
        local session = c and c:getSession(pn)
        def.keepOpen = session ~= nil and session.context == getPlayerContextMenu(pn)
            and c:noteStickySelection(session) == true
    end
end

-- While ZeD's menu is up, a press outside the hidden game menu does not hide it: ZeD's menu takes the press.
if not ISContextMenu._zedRuiDownOutside then
    local orig = ISContextMenu.onMouseDownOutside
    ISContextMenu._zedRuiDownOutside = orig
    ISContextMenu.onMouseDownOutside = function(self, x, y)
        local held = self._zedMenu
        if held and held._ctx and held._ctx.open and not ZeD.Safe.on() then return end
        return orig(self, x, y)
    end
end

-- The mod's rebuild, its close and its refresh, each wrapped once on the mod's controller.
local function install()
    local c = controller()
    local env = c and c.environment
    if not env or env._zedWrapped then return end
    env._zedWrapped = true
    local rebuild, closeMenu = env.rebuild, env.closeMenu

    env.rebuild = function(session)
        local root, held = heldFor(session.playerNum)
        if not held or ZeD.Safe.on() then return rebuild(session) end
        S.holding = root
        local ok, ctx = pcall(rebuild, session)
        S.holding = nil
        if ok and ctx and CM.refreshInPlace(ctx, held) then
            S.refreshed = held
            return ctx
        end
        -- nothing rebuilt (the mod closes the game's menu next) or it failed: ZeD's menu goes
        if held._ctx.open then pcall(held.close, held) end
        if not ok then error(ctx, 0) end
        return ctx
    end

    env.closeMenu = function(context)
        if closeMenu then closeMenu(context) end
        local held = context and context._zedMenu
        if held and held._ctx and held._ctx.open then pcall(held.close, held) end
    end

    -- after the mod puts the game's lit option back, the row ZeD has lit is lit again in the same tick
    c._refresh = function(self, session)
        S.refreshed = nil
        ResponsiveUI.RefreshController._refresh(self, session)
        local held = S.refreshed
        S.refreshed = nil
        if held and held._ctx.open then pcall(CM.Registry.highlight, held, held._relightDef) end
    end
end

install()
if Events and Events.OnGameStart then Events.OnGameStart.Add(install) end

-- The mod's Escape on a keep-open menu (and anything else that hides the game's menu without clearing it) sets the
-- game's menu invisible directly, which ZeD never hears: ZeD's menu would stay up, stale. Each tick, a ZeD menu
-- whose game menu has gone hidden closes too (QA, Nov 9 2026: "ZeD's menu stayed open after Escape and is stale").
local function followHidden()
    if ZeD.Safe and ZeD.Safe.on() then return end
    for pn = 0, 3 do
        local root, held = heldFor(pn)
        local shown = root and ((root.getIsVisible and root:getIsVisible()) or (not root.getIsVisible and root.isVisible and root:isVisible()))
        if held and root and not shown and S.holding ~= root then
            pcall(held.close, held)
        end
    end
end
if Events and Events.OnTick and not S._followHidden then
    S._followHidden = true
    Events.OnTick.Add(followHidden)
end
