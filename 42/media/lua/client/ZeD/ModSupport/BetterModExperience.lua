-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/BetterModExperience.lua
-- ============================================================================
-- SUPPORT FOR BETTER MOD EXPERIENCE (mod id BetterModExperience, Workshop
-- 3834902827, by coldfeudal). Client.
--
-- What the mod does, file by file:
--   * BME_Sorting / BME_ModMenus: the active mod list is sorted by the game's
--     own auto sort (ModLoadOrderPanel:autoSort, or whichever sorter another
--     mod put in its place) every time a list is accepted (it wraps
--     ModSelector.Model.acceptChanges), but not on a Back that changed nothing.
--     Before a game starts (New Game's Play, Load's Play and the main menu's
--     Continue, a hosted server's Start) it checks the list: a duplicate, a mod
--     not installed, a missing requirement, a wrong order or two incompatible
--     mods hold the start back, with the reason drawn in red over the button
--     and the button off. It also marks the game's "mods changed" pop-up seen.
--   * BME_CollapsibleOptions: on Options > Mods each mod's section folds (all
--     shut to begin with), its heading drawn with the mod's icon and an arrow.
--   * BME_ModOptionsPersistence, BME_NoOpReset, BME_LocalServerMods: fixes
--     under the screens (ModOptions.ini records, no Lua reset for a list that
--     only got sorted, local mods in Mod Load Order Sorter's server list).
--
-- With ZeD on: the fixes under the screens, the sort on Accept and the pop-up
-- work as they are (ZeD's Mods screen accepts through the game's model). What
-- did not show, and what this file does about it:
--   * Options > Mods: ZeD reads the game's options page to draw its own. The
--     mod moves the controls of shut sections up over the next ones, so ZeD's
--     page came out jumbled. This file reads the page with every control back
--     where the game put it, and gives each mod's heading a fold of ZeD's own
--     (the head that folds, as the Looks screen's details), shut or open as the
--     mod keeps it (opening one in ZeD opens it in the game's page too). Find
--     still searches every section. The mod's icons are not drawn.
--   * Load, Continue: the mod held a start back in silence (its red line is on
--     the game's Load screen, which ZeD replaces). ZeD's Load screen now gives
--     the mod's reason with the save's other notes (a red square), and Play is
--     off, as the mod has it.
--   * New Game: Next with a list the mod would hold back opens ZeD's note
--     (centered, the main menu's controller on its OK) with the mod's reasons,
--     and the game does not start.
--   * Host: the mod's first reason is the band's problem line; Start is off.
--   * the Mods screen: the band's line for pending changes adds that the mod
--     sorts the load order on Accept; Back (and Discard changes) with the order
--     as it was when the screen opened does not sort, as the mod's own Back.
-- ZeD stores nothing; every call into the mod is in pcall.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "BetterModExperience"

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

require "ZeD/Tr"
require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuOptions"
require "ZeD/ZeD_MainMenuMods"
require "ZeD/ZeD_MainMenuHost"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.BetterModExperience = S

local MM = ZeD.MainMenu

-- the mod's sorting table (BetterModExperience.Sorting), or nil
local function sorting()
    local B = BetterModExperience
    if type(B) == "table" and type(B.Sorting) == "table" and type(B.Sorting.preview) == "function" then return B.Sorting end
    return nil
end
S.sorting = sorting

-- the mod's name as the game lists it
function S.modName()
    local name = nil
    pcall(function() name = getModInfoByID(MOD_ID):getName() end)
    return name or "Better Mod Experience"
end

-- An ActiveMods' ids as a Lua list (the mod's read), or nil.
function S.idsOf(active)
    local B = sorting()
    if not (B and active) then return nil end
    local ok, ids = pcall(function() return B.read(active:getMods()) end)
    return ok and ids or nil
end

-- What the mod would hold a start back for (its preview, kept per owner and list), or nil.
function S.errors(owner, ids, force)
    local B = sorting()
    if not (B and owner and ids) then return nil end
    local ok, plan = pcall(B.preview, owner, ids, force)
    if not ok or type(plan) ~= "table" then return nil end
    if type(plan.errors) == "table" and #plan.errors > 0 then return plan.errors end
    return nil
end

-- one line of the mod's words, its rich-text tags and line breaks out
function S.plain(s)
    s = tostring(s or ""):gsub("<[^>]+>", ""):gsub("[\r\n]+", " ")
    return s
end

-- ---------------------------------------------------------------------------
-- OPTIONS > MODS: the page read whole, each mod's heading a fold
-- ---------------------------------------------------------------------------

-- the options panel the mod folded (its panel.bmeGroups): the page's view or a child of it
local function bmePanel(view)
    if type(view) ~= "table" then return nil end
    if type(view.bmeGroups) == "table" then return view end
    local ok, kids = pcall(function() return view:getChildren() end)
    if ok and kids then
        for _, c in pairs(kids) do
            if type(c) == "table" and type(c.bmeGroups) == "table" then return c end
        end
    end
    return nil
end
S.bmePanel = bmePanel

-- Mark the rows of the mod's sections: each row gets its section (r.bmeGroup); the
-- heading's row a fold (onFold, count). The heading is the last of its heading entries
-- (the mod's label, a Medium label: ZeD's header row).
function S.annotate(rows, groups)
    local of, head = {}, {}
    for _, g in ipairs(groups) do
        for _, e in ipairs(g.heading or {}) do if e.ui then of[e.ui] = g end end
        for _, e in ipairs(g.body or {}) do if e.ui then of[e.ui] = g end end
        local last = g.heading and g.heading[#g.heading]
        if last and last.ui then head[last.ui] = g end
    end
    local cur = nil
    for _, r in ipairs(rows) do
        local el = r.control or r.el
        local g = el and of[el]
        if g and r.kind == "header" and head[el] then
            local label = el
            r.bmeGroup, r.bmeHead = g, true
            r.count = 0
            r.shut = not g.open
            -- the mod's own toggle (it opens or shuts the section on the game's page too)
            r.onFold = function()
                if type(label.forceClick) == "function" then pcall(label.forceClick, label) end
            end
            cur = r
        elseif g then
            r.bmeGroup = g
            if cur and cur.bmeGroup == g and r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then
                cur.count = cur.count + 1
            end
        end
    end
    return rows
end

local origRows = MM.optionRows
function MM.optionRows(page)
    local panel = page and bmePanel(page.view)
    if not panel then return origRows(page) end
    -- read with every control where the game first put it (the mod moves shut sections' controls
    -- up over the next ones); put back as the mod had them right after
    local saved = {}
    for _, g in ipairs(panel.bmeGroups) do
        for _, list in ipairs({ g.heading or {}, g.body or {} }) do
            for _, e in ipairs(list) do
                if e.ui and type(e.y) == "number" and e.ui.getY and e.ui.setY then
                    saved[#saved + 1] = { e.ui, e.ui:getY() }
                    e.ui:setY(e.y)
                end
            end
        end
    end
    local ok, rows = pcall(origRows, page)
    for i = #saved, 1, -1 do saved[i][1]:setY(saved[i][2]) end
    if not ok then error(rows, 0) end
    return S.annotate(rows, panel.bmeGroups)
end

-- The rows drawn on the Mods page: a shut section shows its heading only (Find shows every match).
function S.visibleRows(rows)
    local any = false
    for _, r in ipairs(rows) do if r.bmeGroup then any = true; break end end
    if not any then return rows end
    local out = {}
    for _, r in ipairs(rows) do
        local g = r.bmeGroup
        if not g then
            out[#out + 1] = r
        elseif r.bmeHead then
            r.shut = not g.open
            -- the help band's words for the head (it reads a control's tooltip, as the Looks screen's fold)
            if r._tipShut ~= r.shut then
                r._tipShut = r.shut
                r.control = { tooltip = ZeD.tr(r.shut and "UI_ZeD_ETW_HelpCatShow" or "UI_ZeD_ETW_HelpCatHide", tostring(r.text or "")) }
            end
            out[#out + 1] = r
        elseif g.open then
            out[#out + 1] = r
        end
    end
    return out
end

if ZeD_MMOptions and ZeD_MMOptions.drawRows then
    local origDraw = ZeD_MMOptions.drawRows
    function ZeD_MMOptions:drawRows(x, y, w, h, rows, page, finding)
        if not finding and page and page.raw == "mods" and rows then rows = S.visibleRows(rows) end
        return origDraw(self, x, y, w, h, rows, page, finding)
    end
end

-- ---------------------------------------------------------------------------
-- LOAD (and the main menu's Continue, which lands on Load when held back)
-- ---------------------------------------------------------------------------
if ZeD_MMLoad and ZeD_MMLoad.whyNot then
    local origWhy = ZeD_MMLoad.whyNot
    function ZeD_MMLoad:whyNot(s)
        local why = origWhy(self, s)
        if why or not s then return why end
        local active = s.activeMods
        if not active and ActiveMods then pcall(function() active = ActiveMods.getById("default") end) end
        local errs = S.errors(self, S.idsOf(active))
        if errs then return S.plain(errs[1]) end
        return nil
    end
end

-- ---------------------------------------------------------------------------
-- NEW GAME
-- ---------------------------------------------------------------------------

-- The mod's reasons in ZeD's note (one OK), centered on the screen; the main menu's
-- controller holds it and gets the menu back on OK, as the About Mods note does
-- (Overrides/Prompts.lua hookNag). Safe mode, or a note ZeD cannot build: the game's own
-- (ISModalDialog, which ZeD's hook leaves vanilla's then). Returns the note, or nil.
S.NOTE_W, S.NOTE_H = 350, 150
function S.tell(errs)
    local lines = {}
    for i, e in ipairs(errs) do
        if i > 6 then break end
        lines[#lines + 1] = S.plain(e)
    end
    local text = ZeD.tr("UI_ZeD_BME_NotStarted", S.modName()) .. "\n" .. table.concat(lines, "\n")
    local ok, o = pcall(function()
        local core = getCore()
        local w, h = S.NOTE_W, S.NOTE_H
        local x, y = math.floor((core:getScreenWidth() - w) / 2), math.floor((core:getScreenHeight() - h) / 2)
        local d = nil
        local P = ZeD.Prompt
        if P and P.question and ZeD_Prompt and not (ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()) then
            local okP, p = pcall(P.question, x, y, w, h, text, false, nil, nil, nil)
            if okP and p then d = p else print("[ZeD] Better Mod Experience: the game's note: " .. tostring(p)) end
        end
        -- (no player at the main menu: nil, so the note gives the focus back to the menu's controller)
        d = d or ISModalDialog:new(x, y, w, h, text, false, nil, nil, nil)
        d:initialise()
        d:addToUIManager()
        local jd = JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
        if jd then
            d.prevFocus = jd.focus
            jd.focus = d
            updateJoypadFocus(jd)
        end
        return d
    end)
    if not ok then print("[ZeD] Better Mod Experience: note failed: " .. tostring(o)); return nil end
    return o
end

if ZeD_MMNewGame and ZeD_MMNewGame.next then
    local origNext = ZeD_MMNewGame.next
    function ZeD_MMNewGame:next()
        local items = self.items and self:items() or {}
        local d = items[self.sel]
        if d and not (self.isChallengesItem and self:isChallengesItem(d)) and not d.arrowButton and ActiveMods then
            local active = nil
            pcall(function() active = ActiveMods.getById("currentGame") end)
            local errs = S.errors(self, S.idsOf(active), true)
            if errs then
                if MM.clickSound then MM.clickSound() end
                S.tell(errs)
                return
            end
        end
        return origNext(self)
    end
end

-- ---------------------------------------------------------------------------
-- HOST
-- ---------------------------------------------------------------------------

-- the hosted server's mod ids (its settings' Mods line), kept a few seconds per server name
local _srv = { name = nil, at = -1e9, ids = nil }
function S.serverIds()
    local name = CoopConnection and CoopConnection.servername
    if not name then return nil end
    local now = MM.now and MM.now() or 0
    if _srv.name == name and now - _srv.at < 3000 then return _srv.ids end
    local ids = nil
    pcall(function()
        local settings = ServerSettings.new(name)
        if settings:loadFiles() then
            local value = settings:getServerOptions():getOptionByName("Mods"):getValue()
            ids = {}
            for id in tostring(value or ""):gmatch("[^;]+") do ids[#ids + 1] = id end
        end
    end)
    _srv.name, _srv.at, _srv.ids = name, now, ids
    return ids
end

if ZeD_MMHost and ZeD_MMHost.problem then
    local origProblem = ZeD_MMHost.problem
    function ZeD_MMHost:problem()
        local p = origProblem(self)
        if p then return p end
        local errs = S.errors(self, S.serverIds())
        if errs then return S.plain(errs[1]) end
        return nil
    end
end

-- ---------------------------------------------------------------------------
-- THE MODS SCREEN
-- ---------------------------------------------------------------------------
local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end

if ZeD_MMMods then
    -- the pending line says the mod sorts on Accept
    if ZeD_MMMods.pendingNow then
        local origPending = ZeD_MMMods.pendingNow
        function ZeD_MMMods:pendingNow()
            local text, restart = origPending(self)
            if text and sorting() then text = text .. " " .. ZeD.tr("UI_ZeD_BME_SortsOnAccept", S.modName()) end
            return text, restart
        end
    end

    -- Back (and Discard changes) with the order as it was when the screen opened: no sort,
    -- as the mod's own Back (its bmeSkipAutoSort, read by its acceptChanges)
    local function asBack(fnName)
        local orig = ZeD_MMMods[fnName]
        if not orig then return end
        ZeD_MMMods[fnName] = function(self, ...)
            self._bmeBack = true
            local ok, a, b = pcall(orig, self, ...)
            self._bmeBack = nil
            if not ok then error(a, 0) end
            return a, b
        end
    end
    asBack("back")
    asBack("discard")

    if ZeD_MMMods.accept then
        local origAccept = ZeD_MMMods.accept
        function ZeD_MMMods:accept(...)
            local m, B = model(), sorting()
            local same = false
            if self._bmeBack and m and B and m.bmeEntryOrder then
                pcall(function() same = B.same(m.bmeEntryOrder, B.read(m:getActiveMods():getMods())) end)
            end
            if not same then return origAccept(self, ...) end
            local prev = m.bmeSkipAutoSort
            m.bmeSkipAutoSort = true
            local ok, err = pcall(origAccept, self, ...)
            m.bmeSkipAutoSort = prev
            if not ok then error(err, 0) end
        end
    end
end
