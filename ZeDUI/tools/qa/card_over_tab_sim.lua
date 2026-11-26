-- ZeDUI/tools/qa/card_over_tab_sim.lua  (Nov 26 2026, Build; QA's 1280x800 stew card)
-- An item card opened over a tab (the drawer still in "tab" mode, _drawerItem set) must stay when that tab hides.
-- The Character window's fallback ("If the active tab is no longer visible") shut the drawer and lost the card:
-- a stew clicked right after Make, while the Cooking tab held on until its scan saw nothing left to cook.
-- The fallback block is cut from ZeD_CharacterWindow.lua and run on stubs.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/card_over_tab_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\]tools[/\]qa[/\]card_over_tab_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua", "rb"))
local src = f:read("*a"):gsub("\r\n", "\n"); f:close()
local a = src:find("    do\n        local activeStillVisible = false", 1, true)
check("the fallback block is found", a ~= nil)
if not a then print("card_over_tab_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local b = src:find("\n    end\n", src:find("if not activeStillVisible then", a, true), true)
local block = src:sub(a, b + 8)   -- (through the outer do's end)
local fn = assert(loadstring("local win, CHAR_TABS, isTabVisible, _switchTabForNav = ...\n" .. block))

local function run(win)
    local switched = nil
    local tabs = { { id = "loot" }, { id = "cooking" } }
    local vis = function(t) return t.id ~= "cooking" end   -- (the Cooking tab has just hidden)
    fn(win, tabs, vis, function(w, mc, id) switched = id; w._drawerOpen = false; w._drawerMode = nil; w._drawerItem = nil; w._activeTab = id end)
    return switched
end

-- a card over the vanished tab: kept, on its own
local STEW = {}
local w = { _activeTab = "cooking", _drawerMode = "tab", _drawerOpen = true, _drawerItem = STEW, _mainContent = {} }
local sw = run(w)
check("the card stays (no switch that shuts the drawer)", sw == nil, sw)
check("its item is kept", w._drawerItem == STEW)
check("the drawer stays open", w._drawerOpen == true)
check("as a card on its own (item mode)", w._drawerMode == "item", w._drawerMode)
check("the strip falls back to Loot", w._activeTab == "loot", w._activeTab)

-- a tab drawer with no card: shut, back to Loot, as before
w = { _activeTab = "cooking", _drawerMode = "tab", _drawerOpen = true, _mainContent = {} }
sw = run(w)
check("TEETH: a plain tab drawer still goes back to Loot, shut", sw == "loot" and w._drawerOpen == false, sw)

print("card_over_tab_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
