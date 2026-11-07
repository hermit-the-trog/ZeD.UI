-- ZeDUI/tools/qa/mods_order_sim.lua  (Nov 7 2026, Build): the Mods screen's load-order writes and ZeD picks, with no game
-- running. The real ZeD_MainMenuMods.lua runs on Lua 5.1 against the game's own ModSelectorModel.lua (vanilla's
-- correctAndSaveModOrder and forceActivateMods, read from the install) and a stub of ActiveMods.
--   * punch list 97: every order write goes through ZeD_MMMods:saveOrder, which leaves out a mod the list names but
--     that is not installed (vanilla's correctAndSaveModOrder indexes each id's record and threw: Undo changes, Load after)
--   * review Nov 7 2026 #4: ZeD-GUI off then on in one visit brings ZeD picks back (picks require ZeD-GUI)
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
    for _, spec in ipairs({ { "ZeD_UI" }, { "ZeD_Picks", { "ZeD_UI" } }, { "Other" }, { "Needs_Other", { "Other" } } }) do
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
    -- other mods keep vanilla's rule: a dependant stays off
    m, s = setup({ "Other", "Needs_Other" })
    s:onShow()
    s:toggle(m.mods.Other)
    s:toggle(m.mods.Other)
    check("another mod's dependant stays off (vanilla)", not m.mods.Needs_Other.isActive)
end

section("every order write goes through saveOrder")
do
    local direct = {}
    for _, f in ipairs({ "ZeD_MainMenuMods.lua", "ZeD_MainMenuModsOrder.lua", "ZeD_MainMenuModsPanes.lua", "ZeD_MainMenuModsSeps.lua", "ZeD_MainMenuModsFolders.lua" }) do
        local h = io.open(ROOT .. "42/media/lua/client/ZeD/" .. f, "rb")
        if h then
            local n = 0
            for line in h:lines() do
                n = n + 1
                -- (the one call allowed is the helper's own: m:correctAndSaveModOrder(out))
                if line:find(":correctAndSaveModOrder(", 1, true) and not line:find("correctAndSaveModOrder(out)", 1, true) and not line:match("^%s*%-%-") then
                    direct[#direct + 1] = f .. ":" .. n
                end
            end
            h:close()
        end
    end
    check("no direct correctAndSaveModOrder outside saveOrder", #direct == 0, table.concat(direct, ", "))
end

print("mods_order_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
