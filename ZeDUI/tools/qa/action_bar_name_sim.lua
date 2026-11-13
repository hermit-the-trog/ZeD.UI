-- ZeDUI/tools/qa/action_bar_name_sim.lua  (Nov 10 2026, Build; punch list 146, the action bar's item name)
-- QA's Mac recheck on 20a8807: during an eight-item move the bar over the character kept the first item's name
-- ("MOVING 2/8 APPLE" while the book moved, "MOVING 8/8 APPLE" while the knife did). B42's transfer merges the
-- transfers queued after it into one action whose item changes at each step, and the bar kept the name per action.
-- With no game running, AB.itemName (cut out of the real ZeD_ActionBar.lua) runs on stub actions. It checks:
--   the name follows the action's item when it changes; it is kept (not read again) while the item stays; an action
--   with no item names nothing.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/action_bar_name_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]action_bar_name_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_ActionBar.lua", "rb"); local src = f:read("*a"):gsub("\r\n", "\n"); f:close()
local fa = src:find("local ITEM_FIELDS", 1, true)
local fb = src:find("\n", src:find("}", fa, true), true)
local na = src:find("function AB.itemName(action)", 1, true)
local nb = src:find("\nend\n", na, true)
check("the pieces are found", fa and fb and na and nb)
if not (fa and fb and na and nb) then print("action_bar_name_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local reads = 0
instanceof = function(o, cls) return type(o) == "table" and o._item == true and cls == "InventoryItem" end
local function item(name) return { _item = true, getDisplayName = function() reads = reads + 1; return name end } end
local AB = { clean = function(s) return string.upper(s) end }
local chunk = "local AB = ...\n" .. src:sub(fa, fb) .. src:sub(na, nb + 4)
local fn = assert(loadstring(chunk))
fn(AB)
local apple, book, knife = item("Apple"), item("Book"), item("Knife")
local act = { item = apple }
check("the first step names its item", AB.itemName(act) == "APPLE", AB.itemName(act))
local r0 = reads
AB.itemName(act); AB.itemName(act)
check("kept while the item stays (not read again)", reads == r0, reads - r0)
act.item = book
check("the next step names its own item", AB.itemName(act) == "BOOK", AB.itemName(act))
act.item = knife
check("and the last", AB.itemName(act) == "KNIFE", AB.itemName(act))
check("an action with no item names nothing", AB.itemName({}) == "")
print("action_bar_name_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
