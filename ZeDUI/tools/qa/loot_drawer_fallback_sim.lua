-- ZeDUI/tools/qa/loot_drawer_fallback_sim.lua (Nov 11 2026, punch list 156): the Loot view never shows a tab drawer.
-- Cuts lootDrawerFallback out of ZeD_WorldWindow.lua and checks each case, then that the placeholder is gone and
-- the two callers (a context tab hiding while open, a restored state) are wired. Run from the repo root: lua5.1 <this>
local f = assert(io.open("42/media/lua/client/ZeD/ZeD_WorldWindow.lua")); local src = f:read("*a"); f:close()
local a = src:find("local function lootDrawerFallback", 1, true); assert(a, "no lootDrawerFallback")
local b = src:find("\nend\n", a, true)
local fn = assert(loadstring(src:sub(a, b + 4) .. "\nreturn lootDrawerFallback"))()
local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. m) end end
local function w(t) t._activeTab = t._activeTab or "loot"; return t end
local x = w{ _drawerMode = "tab", _drawerOpen = true }; fn(x)
ok(x._drawerMode == nil and x._drawerOpen == false, "loot, tab mode, nothing in it: folds")
x = w{ _drawerMode = "tab", _drawerOpen = true, _mcSelected = { 1 } }; fn(x)
ok(x._drawerMode == nil and x._drawerOpen == true, "loot with extra columns: stays open for them")
x = w{ _drawerMode = "tab", _drawerOpen = true, _drawerItem = {} }; fn(x)
ok(x._drawerMode == "item" and x._drawerOpen == true, "an item card: item mode")
x = w{ _drawerMode = "tab", _drawerOpen = true, _drawerObject = {}, _tabUnder = "x" }; fn(x)
ok(x._drawerMode == "object" and x._drawerOpen == true and x._tabUnder == nil, "an object card: object mode")
x = w{ _activeTab = "craft", _drawerMode = "tab", _drawerOpen = true }; fn(x)
ok(x._drawerMode == "tab" and x._drawerOpen == true, "another tab: untouched")
x = w{ _drawerMode = "item", _drawerOpen = true, _drawerItem = {} }; fn(x)
ok(x._drawerMode == "item", "loot already in item mode: untouched")
ok(not src:find("renderPlaceholder", 1, true), "the placeholder card is gone")
ok(not src:find("UI_ZeD_World_ComingSoon", 1, true), "Coming soon is drawn nowhere")
ok(src:find('win._activeTab = "loot"; lootDrawerFallback(win)', 1, true) ~= nil, "a hidden tab falls back to Loot and folds")
ok(src:find('ws.drawerOpen and win._activeTab ~= "loot"', 1, true) ~= nil, "a restored Loot view opens no tab drawer")
-- the Character window's twin (QA's Mac shoot, Nov 11: "Tab content - placeholder" through the gallery)
local fc = assert(io.open("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")); local csrc = fc:read("*a"); fc:close()
local ca = csrc:find("local function lootDrawerFallback", 1, true); ok(ca ~= nil, "Character window: lootDrawerFallback")
if ca then
    local cb = csrc:find("\nend\n", ca, true)
    local cfn = assert(loadstring(csrc:sub(ca, cb + 4) .. "\nreturn lootDrawerFallback"))()
    local y = w{ _drawerMode = "tab", _drawerOpen = true }; cfn(y)
    ok(y._drawerMode == nil and y._drawerOpen == false, "Character: loot in tab mode, nothing in it: folds")
    y = w{ _drawerMode = "tab", _drawerOpen = true, _drawerItem = {} }; cfn(y)
    ok(y._drawerMode == "item" and y._drawerOpen == true, "Character: an item card stays")
    y = w{ _drawerMode = "tab", _drawerOpen = true, _mcSelected = { 1 } }; cfn(y)
    ok(y._drawerOpen == true and y._drawerMode == nil, "Character: columns keep it open")
end
ok(not csrc:find("placeholder\", pad, secY)", 1, true) and not csrc:find("Tab content \\226\\128\\148 placeholder", 1, true), "Character: the English placeholder line is gone")
ok(csrc:find('cs.drawerOpen and win._activeTab ~= "loot"', 1, true) ~= nil, "Character: a restored Loot view opens no tab drawer")
print(string.format("loot_drawer_fallback_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
