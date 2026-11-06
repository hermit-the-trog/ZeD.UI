-- ZeDUI/tools/qa/ctx_highlight_sim.lua  (Nov 6 2026): the right-click menus' highlight with no game running. The real
-- Registry.highlight (cut out of ContextMenuRegistry.lua) drives the game's own checkHighlightedOption and
-- callOptionHighlightFunction (cut out of ISContextMenu.lua), on menus that write down every call.
--   ARGS    an option's onHighlight gets (option, menu, on/off, its params), as in the game
--   MOVE    moving lets the last option go first, and a selection held still calls nothing more
--   SUB     moving into a submenu lets the parent menu's option go
--   CLOSE   a nil def lets go of what is lit, and a second close is harmless
--   ANIMAL  a row that clears highlightedOption is called every frame
--   SAFE    no onHighlight, no vanillaRef, a menu without the method, a throwing option: nothing escapes, nothing sticks
--   PAGES   hidden inventory pages are not told (nothing would put their outline out); a showing page is
-- Run from the repo root: lua51 ZeDUI/tools/qa/ctx_highlight_sim.lua ["path to ISContextMenu.lua"]
local GAME = arg and arg[1] or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISContextMenu.lua"

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end

ISContextMenu = {}
ISInventoryPage = {}
local Registry = {}
_G.Registry = Registry
local v = slurp(GAME)
assert(loadstring(cut(v, "function ISContextMenu:checkHighlightedOption(")))()
assert(loadstring(cut(v, "function ISContextMenu:callOptionHighlightFunction(")))()
local reg = slurp("42/media/lua/client/ZeD/ContextMenuRegistry.lua")
tellMenu = assert(loadstring(cut(reg, "local function tellMenu(menu, opt)"):gsub("^local function tellMenu%(menu, opt%)", "return function(menu, opt)", 1)))()
assert(loadstring(cut(reg, "function Registry.highlight(")))()
assert(loadstring(cut(reg, "function ISInventoryPage.OnObjectHighlighted(")))()

local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

local log
local function newMenu(p) return setmetatable({ player = p or 0 }, { __index = ISContextMenu }) end
local function option(name, obj)
    return { name = name, onHighlightParams = { obj },
        onHighlight = function(o, menu, on, object) log[#log + 1] = { o = o, menu = menu, on = on, object = object } end }
end
local function def(opt, menu) return { vanillaRef = opt, _vanillaMenu = menu } end
local function reset() log = {} end

-- ARGS
reset()
local m, h, a, b = newMenu(3), {}, option("a", "A"), option("b", "B")
Registry.highlight(h, def(a, m))
ok(#log == 1, "ARGS one call")
ok(log[1].o == a and log[1].menu == m and log[1].on == true and log[1].object == "A", "ARGS option, menu, on, params")

-- MOVE
reset()
for _ = 1, 5 do Registry.highlight(h, def(a, m)) end
ok(#log == 0, "MOVE held still calls nothing")
Registry.highlight(h, def(b, m))
ok(#log == 2 and log[1].o == a and log[1].on == false and log[1].object == "A", "MOVE lets the last go first")
ok(log[2] and log[2].o == b and log[2].on == true, "MOVE then lights the new")

-- SUB
reset()
local sub, c = newMenu(3), option("c", "C")
Registry.highlight(h, def(c, sub))
ok(#log == 2 and log[1].o == b and log[1].menu == m and log[1].on == false, "SUB the parent's option goes, on its menu")
ok(log[2] and log[2].o == c and log[2].menu == sub and log[2].on == true, "SUB the submenu's option lights, on its menu")
ok(m.highlightedOption == nil, "SUB the parent holds nothing")

-- CLOSE
reset()
Registry.highlight(h, nil)
ok(#log == 1 and log[1].o == c and log[1].on == false, "CLOSE lets go")
ok(sub.highlightedOption == nil and h._hlMenu == nil, "CLOSE nothing held")
Registry.highlight(h, nil)
ok(#log == 1, "CLOSE twice calls nothing more")

-- ANIMAL: the game's animal rows ask to be called every render
reset()
local an = { onHighlightParams = { "cow" } }
an.onHighlight = function(o, menu, on, animal) log[#log + 1] = { on = on }; menu.highlightedOption = nil end
for _ = 1, 4 do Registry.highlight(h, def(an, m)) end
ok(#log == 4, "ANIMAL called every frame")
Registry.highlight(h, nil)

-- SAFE
reset()
local plain = { name = "no highlight" }
Registry.highlight(h, def(plain, m))
ok(#log == 0 and m.highlightedOption == plain, "SAFE an option with none")
Registry.highlight(h, { vanillaRef = nil })
ok(h._hlMenu == nil and m.highlightedOption == nil, "SAFE a row of ZeD's own lets go")
local bare = {}
Registry.highlight(h, def(a, bare))
ok(h._hlMenu == nil and #log == 0, "SAFE a menu without the method")
local bad = { onHighlightParams = {}, onHighlight = function() error("boom") end }
local fine = pcall(Registry.highlight, h, def(bad, m))
ok(fine and h._hlMenu == m, "SAFE a throwing option stays in the pcall")
reset()
fine = pcall(Registry.highlight, h, def(a, m))
ok(fine and #log == 1 and log[1].o == a, "SAFE and the next option still lights")
Registry.highlight(h, nil)

-- PAGES
local told = 0
origObjHl = function() told = told + 1 end
local vis = { inv = false, loot = false }
getPlayerInventory = function() return { getIsVisible = function() return vis.inv end } end
getPlayerLoot = function() return { getIsVisible = function() return vis.loot end } end
ISInventoryPage.OnObjectHighlighted(0, "obj", true)
ok(told == 0, "PAGES hidden pages are not told")
vis.loot = true
ISInventoryPage.OnObjectHighlighted(0, "obj", true)
ok(told == 1, "PAGES a showing page is")
getPlayerInventory, getPlayerLoot = function() return nil end, function() return nil end
ISInventoryPage.OnObjectHighlighted(0, "obj", true)
ok(told == 1, "PAGES no pages yet")

print(string.format("ctx_highlight_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
