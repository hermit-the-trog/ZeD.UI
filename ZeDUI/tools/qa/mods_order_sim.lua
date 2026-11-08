-- ZeDUI/tools/qa/mods_order_sim.lua  (Nov 7 2026, Build): the Mods screen's load-order writes and ZeD picks, with no game
-- running. The real ZeD_MainMenuMods.lua runs on Lua 5.1 against the game's own ModSelectorModel.lua (vanilla's
-- correctAndSaveModOrder and forceActivateMods, read from the install) and a stub of ActiveMods.
--   * punch list 97: every order write goes through ZeD_MMMods:saveOrder, which leaves out a mod the list names but
--     that is not installed (vanilla's correctAndSaveModOrder indexes each id's record and threw: Undo changes, Load after)
--   * review Nov 7 2026 #4: ZeD-GUI off then on in one visit brings ZeD picks back (picks require ZeD-GUI)
--   * the director, Nov 7 2026 (known issue): every way ZeD-GUI goes off (row, folder or separator box, Turn all
--     off, No mods) and every way it comes back (row, box, Turn all on, a mod that needs it) brings picks back
-- What it can't show: the band and the note on screen (zedqa_mods_*.lua, in the game).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mods_order_sim.lua [path to the game's ModSelectorModel.lua]
-- It prints FAIL lines and a last line "mods_order_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mods_order_sim%.lua$", "")
local VANILLA = arg and arg[1] or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
-- a Java ArrayList as the game hands it to Lua (0-based get)
local function jarr(t)
    t = t or {}
    return {
        size = function() return #t end,
        get = function(_, i) return t[i + 1] end,
        clear = function() for i = #t, 1, -1 do t[i] = nil end end,
        add = function(_, v) t[#t + 1] = v end,
        _t = t,
    }
end

-- ActiveMods: the list of mod ids that are on, in load order
local function newActive(ids)
    local a = { list = jarr(ids) }
    function a:getMods() return self.list end
    function a:isModActive(id) for _, x in ipairs(self.list._t) do if x == id then return true end end return false end
    function a:setModActive(id, on)
        local t = self.list._t
        if on then if not self:isModActive(id) then t[#t + 1] = id end
        else for i = #t, 1, -1 do if t[i] == id then table.remove(t, i) end end end
    end
    return a
end
local active
ActiveMods = { getById = function() return active end, requiresResetLua = function() return false end }
MapGroups = { new = function() return {} end }
getActivatedMods = function() return jarr({ "ZeD_UI", "Gone_Mod", "ZeD_Picks" }) end
getText = function(k) return k end
require = noop
Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })

ModSelector = {}
local vf = io.open(VANILLA, "rb")
if not vf then print("mods_order_sim: the game's ModSelectorModel.lua is not at " .. VANILLA); os.exit(1) end
local vsrc = vf:read("*a"); vf:close()
assert(loadstring(vsrc, "@ModSelectorModel.lua"))()

local said = {}
ZeD = {
    MainMenu = { U = {}, ui = {}, clickSound = noop, hoverSound = noop, now = function() return 0 end },
    ModScan = { modName = function(id) return id end, dirtyCounts = noop, updatedLoaded = function() return {} end },
    ModOrder = {},
    ModPicks = { HELPER = "ZeD_Picks", reset = noop, sync = function() return 0 end },
    ModSettings = { reset = noop }, ModSafety = { reset = noop }, ModFolders = nil,
    tr = function(k, ...) local p = { k } for _, v in ipairs({ ... }) do p[#p + 1] = tostring(v) end return table.concat(p, "|") end,
    T = { px = function(v) return v end },
}
ZeD_MMWindow = { derive = function(self, name) local c = {}; c.__index = c; return setmetatable(c, { __index = self }) end }

assert(loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuMods.lua"))()

-- mod records as vanilla builds them; "Gone_Mod" is listed as on but not installed (no record)
local function modInfo(id, req)
    return {
        getId = function() return id end, getName = function() return id end,
        getRequire = function() return req and jarr(req) or nil end,
        getIncompatible = function() return nil end, isAvailable = function() return true end,
        getLoadAfter = function() return nil end, getLoadBefore = function() return nil end,
    }
end
local function setup(onIds)
    active = newActive(onIds)
    local m = ModSelector.Model:new({ updateView = noop })
    for _, spec in ipairs({ { "ZeD_UI" }, { "ZeD_Picks", { "ZeD_UI" } }, { "Other" }, { "Needs_Other", { "Other" } }, { "Needs_ZeD", { "ZeD_UI" } } }) do
        local id = spec[1]
        local d = { modId = id, modInfo = modInfo(id, spec[2]), name = id }
        d.defaultActive = active:isModActive(id)
        m.mods[id] = d
        m.sortedMods[#m.sortedMods + 1] = d
    end
    m:refreshMods()
    ModSelector.instance = { model = m }
    local s = setmetatable({}, { __index = ZeD_MMMods })
    s.problem = function() return nil end
    s.problemRun = function() return nil end
    s.dirty = noop
    s.say = function(_, t) said[#said + 1] = t end
    s.find = { getInternalText = function() return "" end, setText = noop, isFocused = function() return false end }
    s.field = { setVisible = noop }
    return m, s
end
local function onList() return table.concat(active:getMods()._t, ",") end

-- ---------------------------------------------------------------------------
section("vanilla throws on an uninstalled id (why the helper exists)")
do
    local m = setup({ "ZeD_UI", "Gone_Mod" })
    local ok = pcall(function() m:correctAndSaveModOrder({ "ZeD_UI", "Gone_Mod" }) end)
    check("vanilla correctAndSaveModOrder throws with Gone_Mod listed", not ok)
end

section("saveOrder leaves out what is not installed")
do
    local m, s = setup({ "ZeD_UI", "Gone_Mod", "Other" })
    local ok, err = pcall(function() s:saveOrder({ "Other", "Gone_Mod", "ZeD_UI" }) end)
    check("saveOrder does not throw", ok, err)
    check("saveOrder keeps the installed ones in order", onList() == "Other,ZeD_UI", onList())
    -- (a requirement still comes first, vanilla's own rule)
    setup({ "ZeD_UI", "ZeD_Picks" })
    ZeD_MMMods.saveOrder(s, { "ZeD_Picks", "Gone_Mod" })
    check("saveOrder: vanilla still puts a requirement first", onList() == "ZeD_UI,ZeD_Picks", onList())
end

section("Undo changes and Load after with an uninstalled mod listed (beta 6 threw)")
do
    local m, s = setup({ "ZeD_UI", "Gone_Mod", "ZeD_Picks", "Other" })
    local ok, err = pcall(function() s:revert() end)
    check("revert does not throw", ok, err)
    m, s = setup({ "ZeD_UI", "Gone_Mod", "Other" })
    ok, err = pcall(function() s:loadAfter("ZeD_UI", "Other") end)
    check("loadAfter does not throw", ok, err)
    check("loadAfter puts ZeD_UI after Other", onList() == "Other,ZeD_UI", onList())
end

section("ZeD-GUI off then on brings ZeD picks back")
do
    local m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    check("ZeD-GUI off takes picks off (vanilla's cascade)", not m.mods.ZeD_Picks.isActive)
    s:toggle(m.mods.ZeD_UI)
    check("ZeD-GUI back on: picks back on", m.mods.ZeD_Picks.isActive and active:isModActive("ZeD_Picks"))
    check("the note names picks", tostring(said[#said]):find("UI_ZeD_Mods_AlsoOn|ZeD_Picks", 1, true) ~= nil, said[#said])
    check("nothing pending: the set is the one the screen opened with", not s:changed())
end

section("picks the player turned off stay off")
do
    local m, s = setup({ "ZeD_UI", "ZeD_Picks" })
    s:onShow()
    s:toggle(m.mods.ZeD_Picks)
    s:toggle(m.mods.ZeD_UI)
    s:toggle(m.mods.ZeD_UI)
    check("picks off first, then ZeD-GUI off and on: picks stay off", not m.mods.ZeD_Picks.isActive)
    -- picks went off with ZeD-GUI, then the player turned picks on and off again: their call stands
    m, s = setup({ "ZeD_UI", "ZeD_Picks" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    s:toggle(m.mods.ZeD_Picks)        -- (turning picks on brings ZeD-GUI with it)
    s:toggle(m.mods.ZeD_Picks)
    s:toggle(m.mods.ZeD_UI)
    s:toggle(m.mods.ZeD_UI)
    check("picks set by hand after the cascade: ZeD-GUI off and on leaves them off", not m.mods.ZeD_Picks.isActive)
    -- another visit: the memory goes with the screen
    m, s = setup({ "ZeD_UI", "ZeD_Picks" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    check("a new visit forgets which mod took picks off", not m.mods.ZeD_Picks.isActive)
    -- a set the player kept, put back exactly (here a profile with ZeD-GUI on and picks off): it stands
    m, s = setup({ "ZeD_UI", "ZeD_Picks" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    s:applyOnSet({ ZeD_UI = true }, true)
    check("the kept set put ZeD-GUI on and left picks off", m.mods.ZeD_UI.isActive and not m.mods.ZeD_Picks.isActive)
    check("the kept set dropped the memory", s._picksOffWith == nil, tostring(s._picksOffWith))
    s:toggle(m.mods.ZeD_UI)
    s:toggle(m.mods.ZeD_UI)
    check("after a kept set, ZeD-GUI off and on leaves picks off", not m.mods.ZeD_Picks.isActive)
    -- Undo changes back to a set the screen opened with both off
    m, s = setup({ "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_Picks)         -- (brings ZeD-GUI with it)
    s:toggle(m.mods.ZeD_UI)            -- (takes picks off with it: remembered)
    s:revert()
    check("Undo changes forgets which mod took picks off", s._picksOffWith == nil, tostring(s._picksOffWith))
    s:toggle(m.mods.ZeD_UI)
    check("Undo changes, then ZeD-GUI on: picks stay off", m.mods.ZeD_UI.isActive and not m.mods.ZeD_Picks.isActive)
    -- a saved profile with both off: the profile's own picks stand
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:applyOnSet({ Other = true }, true)   -- (loadProfile's own step, after it forgot the memory)
    s._picksOffWith = nil
    s:toggle(m.mods.ZeD_UI)
    check("a saved profile with both off, then ZeD-GUI on: picks stay off", m.mods.ZeD_UI.isActive and not m.mods.ZeD_Picks.isActive)
    -- other mods keep vanilla's rule: a dependant stays off
    m, s = setup({ "Other", "Needs_Other" })
    s:onShow()
    s:toggle(m.mods.Other)
    s:toggle(m.mods.Other)
    check("another mod's dependant stays off (vanilla)", not m.mods.Needs_Other.isActive)
end

section("every way ZeD-GUI comes back on brings picks (the director, Nov 7 2026)")
do
    -- Turn all on (straight to the batch)
    local m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    s:modsOnBatch({ "ZeD_UI" })
    check("row off, a batch on: picks back on", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive and active:isModActive("ZeD_Picks"))
    check("the memory is spent", s._picksOffWith == nil, tostring(s._picksOffWith))
    -- a mod that needs ZeD-GUI brings ZeD-GUI back, and picks with it
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    s:toggle(m.mods.Needs_ZeD)
    check("ZeD-GUI back as a requirement: picks back on", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive)
    check("the note names picks with ZeD-GUI", tostring(said[#said]):find("ZeD_Picks", 1, true) ~= nil, said[#said])
    -- Turn all off, then ZeD-GUI on by its row
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:setAll(false)
    check("Turn all off: everything off", onList() == "", onList())
    check("Turn all off remembers picks went with ZeD-GUI", s._picksOffWith == "ZeD_UI", tostring(s._picksOffWith))
    s:toggle(m.mods.ZeD_UI)
    check("Turn all off, then ZeD-GUI on: picks back on", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive)
    check("only ZeD-GUI and picks came on", onList() == "ZeD_UI,ZeD_Picks", onList())
    -- ZeD-GUI off by its row, then Turn all off, then ZeD-GUI on: the memory holds through
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    s:setAll(false)
    s:toggle(m.mods.ZeD_UI)
    check("row off, Turn all off, ZeD-GUI on: picks back on", m.mods.ZeD_Picks.isActive)
    -- Turn all off with picks already off by the player: nothing to bring back
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_Picks)
    s:setAll(false)
    s:toggle(m.mods.ZeD_UI)
    check("picks off by hand, Turn all off, ZeD-GUI on: picks stay off", not m.mods.ZeD_Picks.isActive)
    -- the "No mods" profile is Turn all off
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s.profileDiff = function() return { off = {} } end   -- (the profile pane's own parts: not under test here)
    s.leaveProfiles = noop
    s:loadProfile({})                  -- (the "No mods" profile: no name)
    s:toggle(m.mods.ZeD_UI)
    check("No mods, then ZeD-GUI on: picks back on", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive)
    -- Turn all off then Turn all on: all on
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:setAll(false)
    s:setAll(true)
    check("Turn all off then on: picks on", m.mods.ZeD_Picks.isActive and s._picksOffWith == nil)
    -- the Load order page: Back sets the earlier set again (nothing changes) and keeps the memory
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    s:applyOnSet({ Other = true }, true)
    check("a set change that changes nothing keeps the memory", s._picksOffWith == "ZeD_UI", tostring(s._picksOffWith))
    s:toggle(m.mods.ZeD_UI)
    check("after Back, ZeD-GUI back on: picks back on", m.mods.ZeD_Picks.isActive)
    -- a separator box on the Load order page turns ZeD-GUI back on (picks with it), then Back puts
    -- both off again and the memory with them. The steps are leaveOrder's own: sepMatchActive
    -- (applyOnSet) then restorePicksOffWith
    m, s = setup({ "ZeD_UI", "ZeD_Picks", "Other" })
    s:onShow()
    s:toggle(m.mods.ZeD_UI)
    local kept = s._picksOffWith       -- (enterOrder's _oPicksOffWith0)
    s:modsOnBatch({ "ZeD_UI" })        -- (the separator box)
    check("the separator box brought picks back", m.mods.ZeD_Picks.isActive and s._picksOffWith == nil, tostring(s._picksOffWith))
    s:applyOnSet({ Other = true }, true)
    s:restorePicksOffWith(kept)
    check("Back puts the memory back with the set", s._picksOffWith == "ZeD_UI", tostring(s._picksOffWith))
    s:toggle(m.mods.ZeD_UI)
    check("after Back, ZeD-GUI on: picks back on", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive)
    -- a memory put back while ZeD-GUI is on does not hold (it is checked, not acted on)
    m, s = setup({ "ZeD_UI", "Other" })
    s:onShow()
    s:restorePicksOffWith("ZeD_UI")
    check("a memory put back with ZeD-GUI on is dropped, picks left off", s._picksOffWith == nil and not m.mods.ZeD_Picks.isActive, tostring(s._picksOffWith))
    -- the wiring: leaveOrder (Back) and orderUndo call restorePicksOffWith, enterOrder and
    -- orderSnap keep the memory (ZeD_MainMenuModsOrder.lua is not loaded here: read its source)
    do
        local h = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuModsOrder.lua", "rb")
        local src = h and h:read("*a") or ""
        if h then h:close() end
        local _, nRestore = src:gsub("self:restorePicksOffWith%(", "")
        check("Back and Undo on the Load order page put the memory back", nRestore == 2, nRestore)
        check("the Load order page keeps the memory it opened with", src:find("self._oPicksOffWith0 = self._picksOffWith", 1, true) ~= nil)
        check("each Load order Undo step keeps its memory", src:find("picksOffWith = self._picksOffWith", 1, true) ~= nil)
    end
end

section("folder and separator boxes (the real ZeD_MainMenuModsFolders.lua and ZeD_MainMenuModsSeps.lua)")
do
    -- folders: f1 holds ZeD-GUI (and Other), f2 holds picks too when asked
    local member = {}
    ZeD.ModFolders = {
        load = noop, readLines = function() return {} end,
        byId = function(id) return ({ f1 = { id = "f1", name = "UI" }, f2 = { id = "f2", name = "Both" } })[id] end,
        folderOf = function(mid) return member[mid] end,
    }
    ZeD.ModOrder = ZeD.ModOrder or {}
    local okF, errF = pcall(function() assert(loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuModsFolders.lua"))() end)
    check("the folders file loads", okF, errF)
    local okS, errS = pcall(function() assert(loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuModsSeps.lua"))() end)
    check("the separators file loads", okS, errS)
    local function boxSetup(on)
        local m, s = setup(on)
        s:onShow()
        s.sepReconcile = noop          -- (the Load order page's layout: not under test here)
        s.oOffHere = {}
        return m, s
    end
    if okF then
        member = { ZeD_UI = "f1", Other = "f1" }
        -- the folder's box off takes ZeD-GUI off (picks with it), on again brings both
        local m, s = boxSetup({ "ZeD_UI", "ZeD_Picks", "Other" })
        s:folderBox("f1")
        check("folder box off: ZeD-GUI and picks off", not m.mods.ZeD_UI.isActive and not m.mods.ZeD_Picks.isActive)
        check("folder box off remembers picks went with ZeD-GUI", s._picksOffWith == "ZeD_UI", tostring(s._picksOffWith))
        s:folderBox("f1")
        check("folder box on: picks back on", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive)
        -- the folder's box off, then ZeD-GUI's own row on
        m, s = boxSetup({ "ZeD_UI", "ZeD_Picks", "Other" })
        s:folderBox("f1")
        s:toggle(m.mods.ZeD_UI)
        check("folder box off, ZeD-GUI row on: picks back on", m.mods.ZeD_Picks.isActive)
        -- ZeD-GUI's row off, then the folder's box on
        m, s = boxSetup({ "ZeD_UI", "ZeD_Picks" })
        s:toggle(m.mods.ZeD_UI)
        s:folderBox("f1")
        check("ZeD-GUI row off, folder box on: picks back on", m.mods.ZeD_UI.isActive and m.mods.Other.isActive and m.mods.ZeD_Picks.isActive)
        -- both in one folder: off and on together
        member = { ZeD_UI = "f2", ZeD_Picks = "f2" }
        m, s = boxSetup({ "ZeD_UI", "ZeD_Picks" })
        s:folderBox("f2")
        s:folderBox("f2")
        check("a folder with both: off and on brings both", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive)
        -- picks off by hand first: the folder's box off and on leaves them off
        member = { ZeD_UI = "f1", Other = "f1" }
        m, s = boxSetup({ "ZeD_UI", "ZeD_Picks", "Other" })
        s:toggle(m.mods.ZeD_Picks)
        s:folderBox("f1")
        s:folderBox("f1")
        check("picks off by hand, folder box off and on: picks stay off", m.mods.ZeD_UI.isActive and not m.mods.ZeD_Picks.isActive)
    end
    if okS then
        local m, s = boxSetup({ "ZeD_UI", "ZeD_Picks", "Other" })
        s:sepTurn({ "ZeD_UI" }, false)
        check("separator off: ZeD-GUI and picks off", not m.mods.ZeD_UI.isActive and not m.mods.ZeD_Picks.isActive)
        check("separator off remembers picks went with ZeD-GUI", s._picksOffWith == "ZeD_UI", tostring(s._picksOffWith))
        s:sepTurn({ "ZeD_UI" }, true)
        check("separator on: picks back on", m.mods.ZeD_UI.isActive and m.mods.ZeD_Picks.isActive)
        m, s = boxSetup({ "ZeD_UI", "ZeD_Picks", "Other" })
        s:sepTurn({ "ZeD_UI", "Other" }, false)
        s:toggle(m.mods.ZeD_UI)
        check("separator off, ZeD-GUI row on: picks back on", m.mods.ZeD_Picks.isActive)
    end
end

section("every order write goes through saveOrder")
do
    -- the one call allowed is the helper's own: inside "function ZeD_MMMods:saveOrder(" in ZeD_MainMenuMods.lua, up to
    -- the function's closing "end" at the start of a line. Any other call, in any form, fails, whatever its argument
    local direct, inHelper, helperCalls, helperSeen = {}, false, 0, false
    for _, f in ipairs({ "ZeD_MainMenuMods.lua", "ZeD_MainMenuModsOrder.lua", "ZeD_MainMenuModsPanes.lua", "ZeD_MainMenuModsSeps.lua", "ZeD_MainMenuModsFolders.lua" }) do
        local h = io.open(ROOT .. "42/media/lua/client/ZeD/" .. f, "rb")
        check("the order file is there: " .. f, h ~= nil)
        if h then
            local n = 0
            for line in h:lines() do
                n = n + 1
                line = line:gsub("\r$", "")
                local code = line:gsub("%-%-.*$", "")       -- (a comment may name the call)
                if f == "ZeD_MainMenuMods.lua" and code:match("^function%s+ZeD_MMMods:saveOrder%s*%(") then
                    inHelper, helperSeen = true, true
                elseif inHelper and code:match("^end%f[%W]") then
                    inHelper = false
                end
                if code:find("correctAndSaveModOrder%s*%(") then
                    if inHelper then helperCalls = helperCalls + 1 else direct[#direct + 1] = f .. ":" .. n end
                end
            end
            h:close()
        end
    end
    check("the saveOrder helper is where the guard looks", helperSeen)
    check("the helper makes the one call", helperCalls == 1, helperCalls)
    check("no direct correctAndSaveModOrder outside saveOrder", #direct == 0, table.concat(direct, ", "))
end

print("mods_order_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
