-- ZeDUI/tools/qa/worn_last_sim.lua  (the director, Nov 23 2026): with the "Worn and held" list setting on (KISS #11),
-- the worn and held things come AFTER everything else in the player's own list, as the game's sorts put equipped things
-- last ("you want to access the things that are in your pockets before the things that you're wearing").
-- Checks the source of InventoryRenderer.lua's buildItemModel:
--   GROUPED  Sort by Category: the worn group is moved to the end of the category order, not the front
--   FLAT     the other sorts: the rest is emitted first, the worn rows after it
--   GAME     the game's own sorts put equipped things last (ISInventoryPane itemSortBy*, read when the game is here)
-- What it can't show: the list on screen (QA's lv_items with the setting on).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/worn_last_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]worn_last_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return (s:gsub("\r\n", "\n"))
end

local src = readFile(ROOT .. "42/media/lua/client/ZeD/InventoryRenderer.lua") or ""
check("InventoryRenderer.lua is read", #src > 0)

-- GROUPED
check("GROUPED the worn group goes to the end of the category order",
    src:find("catOrder[#catOrder + 1] = ZeD.InventoryRenderer.WORN_KEY", 1, true) ~= nil)
check("GROUPED no longer put first", not src:find("table.insert(catOrder, 1, ZeD.InventoryRenderer.WORN_KEY)", 1, true))

-- FLAT
local a = src:find("sortItems(all, sortCol, sortAsc)\n        emitStacks(all)", 1, true)
local w = src:find("sortItems(wornRows, sortCol, sortAsc)\n            emitStacks(wornRows)", 1, true)
check("FLAT both parts found", a ~= nil and w ~= nil)
check("FLAT the rest first, the worn rows after", a ~= nil and w ~= nil and a < w, tostring(a) .. " / " .. tostring(w))

-- GAME (the game's own pane, if this machine has it)
local game = readFile("E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISInventoryPane.lua")
if game then
    check("GAME the game's name sort puts equipped things last",
        game:find("ISInventoryPane.itemSortByNameInc = function(a,b)\n    if a.equipped and not b.equipped then return false end", 1, true) ~= nil
        or game:find("ISInventoryPane.itemSortByNameInc = function(a,b)\r\n    if a.equipped and not b.equipped then return false end", 1, true) ~= nil)
end

print("worn_last_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
