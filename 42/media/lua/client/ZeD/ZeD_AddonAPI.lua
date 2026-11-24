-- ZeD-UI/42/media/lua/client/ZeD/ZeD_AddonAPI.lua
-- ============================================================================
-- ZeD's PUBLIC API FOR ADD-ONS (1.0, Nov 23 2026: "proper plugin points ready
-- for 1.0"). Client. Pure ASCII.
--
-- ZeD.API.VERSION: 1. An add-on checks it before it calls anything:
--     if ZeD and ZeD.API and (ZeD.API.VERSION or 0) >= 1 then ... end
--
-- What an add-on may call (and nothing else of ZeD's is promised to stay):
--   the plug-in points (docs/ADDON_API.md has each one with an example)
--     ZeD.EquipmentTab.addSection    a section under the Equip tab's doll and lists,
--                                    and a takeover of the Equip drawer
--     ZeD.EquipDoll.addOverlay       marks drawn in the doll's empty slots
--     ZeD.JournalTab.addPage         a page of the Journal tab
--     ZeD.JournalTab.openPage        open a Journal page by its id
--     ZeD_CharacterWindow.openTab    open the Character window on a tab
--     ZeD.DpadWheels.addSlice        a slice on the controller's Character wheel
--     ZeD.DpadWheels.openCharTab     the pair open on a Character tab, the pad in it
--     ZeD.ItemCard.addMark           a mark on the item card's mark strip
--     ZeD.ItemCard.addSection        a section in the item card's body
--     ZeD.ItemCard.addGen            a value the card's model is rebuilt on
--     ZeD.Options.addGroup / addRows / joinPreset   (shared/ZeD/AddonOptions.lua)
--     ZeD.PxIcon.addWarm / addMark   pixel icons warmed early, an icon's mark color
--     (older points: ZeD_CharacterWindow.addTab, ZeD.Belt.addBox, ZeD.GridLayout.register,
--     ZeD.ItemRules.register, ZeD.ContainerControls.addProvider, ZeD.HealthTab.addExtras,
--     ZeD.ObjectCards.register; docs/reference/HOOK_MAP.md)
--   the window helpers (below and in the host files)
--     ZeD.API.state, ZeD.API.player, ZeD.API.playerNum, ZeD.API.call
--     ZeD_CharacterWindow.drawerPanel, .cardOpen, .activeTab, .getWindow
--     ZeD.EquipmentTab.focus / setFocus / clearSelection / followY
--     ZeD.EquipDoll.slotForLoc / beltSlotFor
--   the UI kit (draw with these so an add-on looks like ZeD)
--     ZeD.Atoms, ZeD.Molecules, ZeD.Focus.mark, ZeD.Input.Focus, ZeD.Help.set,
--     ZeD.Popups, ZeD.ContextList (and the right-click rows' zedPx / zedCategory /
--     zedCheck fields), ZeD.Stations.drawSelect, ZeD.PadGlyphs, ZeD.PutBack.queuing,
--     ZeD.Safe.on, ZeD.T (tokens), ZeD.TM (text measure), ZeD.tr, ZeD.uiSound
--
-- The rules every registry keeps:
--   * idle and invisible when nothing registers: no empty section, page, slice,
--     chip, menu row or controller stop;
--   * an add-on's callback runs in pcall: an error is logged once (ZeD.logOnce,
--     which also counts toward Safe mode) and that callback's part is left out,
--     never ZeD's own drawing;
--   * the same id registered again replaces the earlier one in its place (a
--     reloaded file does not show twice);
--   * register whenever you like; Events.OnGameBoot (every file loaded) is the
--     usual place.
-- ============================================================================

ZeD = ZeD or {}
ZeD.API = ZeD.API or {}
local API = ZeD.API
API.VERSION = 1

--- Call an add-on's function fn(...) safely. where = a short tag for the log ("journal page loadouts render").
--- Returns what fn returned (two values at most), or nil when fn is not a function or it threw (logged once).
function API.call(where, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
    if ZeD.logOnce then ZeD.logOnce("add-on " .. tostring(where), a) end
    return nil
end

--- A registry: { list = the defs in order, byId = { [id] = def }, rev = goes up with every change }.
function API.registry()
    return { list = {}, byId = {}, rev = 0 }
end

--- Put def under id in reg (replacing the same id where it stands), the list kept in def.order
--- (lower first; no order: 100), equal orders in the order they came. Returns true when taken.
function API.add(reg, what, id, def)
    if type(id) ~= "string" or id == "" or type(def) ~= "table" then
        if ZeD.logOnce then ZeD.logOnce("add-on " .. tostring(what), "needs a string id and a table: left out") end
        return false
    end
    def.id = id
    def._seq = def._seq or (reg.rev + 1)
    local old = reg.byId[id]
    if old then
        def._seq = old._seq
        for i, d in ipairs(reg.list) do
            if d == old then table.remove(reg.list, i); break end
        end
    end
    reg.byId[id] = def
    -- (an insertion sort: the lists are a handful long, and table.sort is the game's recursive one)
    local o = tonumber(def.order) or 100
    local at = #reg.list + 1
    for i, d in ipairs(reg.list) do
        local od = tonumber(d.order) or 100
        if o < od or (o == od and def._seq < d._seq) then at = i; break end
    end
    table.insert(reg.list, at, def)
    reg.rev = reg.rev + 1
    return true
end

--- An add-on's own state on a window (made with init(win) the first time; init nil: an empty table).
--- It is kept on the window as win[key]: the add-on picks a key of its own ("_el", "_jl" for Loadouts);
--- ZeD never reads or writes such a key.
function API.state(win, key, init)
    if not win then return nil end
    local s = win[key]
    if s == nil then
        s = init and init(win) or {}
        win[key] = s
    end
    return s
end

--- The player a ZeD window shows (nil when none).
function API.player(win) return win and win._playerObj or nil end

--- The local player number a ZeD window is for (split-screen: never assume 0).
function API.playerNum(win)
    if ZeD.playerNumOf and win and win._playerObj then return ZeD.playerNumOf(win) end
    return (win and win.playerNum) or 0
end
