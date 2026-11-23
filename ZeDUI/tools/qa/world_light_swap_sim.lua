-- ZeDUI/tools/qa/world_light_swap_sim.lua  (QA #44, Nov 22 2026): the container on show is lit in the world, and only
-- it. QA's vk3_win saw crate A stay lit after a plain click on crate B's picture showed B alone. The cause: the game's
-- own loot page, hidden by ZeD, is still updated by the engine and its updateContainerHighlight lit the crate it had
-- picked (A) every 100 ms. This sim runs the real swap path (ZeD_WorldWindow._showAlone, _lightShown each frame) beside
-- the game's real page code (ISInventoryPage:updateContainerHighlight, read from the game when it is installed here,
-- else the copy below), with stand-in crates that record every highlight and outline call.
--   CONTROL  without ZeD's page wrap: A stays lit after the swap (the fault, reproduced)
--   SWAP     with it, outline option on and off: B lit (outlined only with the option on), A dark (highlight, outline
--            and attached outline all off), the hidden page lights nothing more
--   SHOWN    a page on show (safe mode) still lights as the game's
-- Run from the repo root: lua51 ZeDUI/tools/qa/world_light_swap_sim.lua

local function slurp(p) local f = io.open(p, "rb"); if not f then return nil end local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end
local ZD = "42/media/lua/client/ZeD/"
local GAME = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISInventoryPage.lua"
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

-- ---------------------------------------------------------------- the game's stand-ins
local OUTLINE = true
local col = { getR = function() return 1 end, getG = function() return 1 end, getB = function() return 1 end }
getCore = function() return { getOptionDoContainerOutline = function() return OUTLINE end,
    getObjectHighlitedColor = function() return col end, getWorldItemHighlightColor = function() return col end } end
instanceof = function() return false end
getPlayerContextMenu = function() return { getIsVisible = function() return false end } end
local SAFE = false
ZeD = { Safe = { on = function() return SAFE end }, windowsFor = function(pn) return pn == 0 end }

local calls = {}
local function crate(name)
    local o = { name = name, hl = false, ol = false, att = false }
    local function log(what, v) calls[#calls + 1] = name .. " " .. what .. " " .. tostring(v) end
    function o:setHighlighted(_, v) self.hl = v; log("setHighlighted", v) end
    function o:setOutlineHighlight(_, v) self.ol = v; log("setOutlineHighlight", v) end
    function o:setOutlineHlAttached(_, v) self.att = v; log("setOutlineHlAttached", v) end
    function o:setOutlineHighlightCol() end
    function o:setHighlightColor() end
    return o
end
local function inv(o) return { getParent = function() return o end, getContainingItem = function() return nil end } end

-- ---------------------------------------------------------------- the game's page code (real when installed)
ObjectsHighlightedElsewhere = { {}, {}, {}, {} }
ISInventoryPage = {}
local game = slurp(GAME)
if game and game:find("function ISInventoryPage:updateContainerHighlight()", 1, true) then
    assert(loadstring(cut(game, "function ISInventoryPage:getContainerParent(")))()
    assert(loadstring(cut(game, "function ISInventoryPage:updateContainerHighlight()")))()
else
    -- (a copy of the game's 42 code, ISInventoryPage.lua, for a machine without the game)
    function ISInventoryPage:getContainerParent(c) return c and c:getParent() or nil end
    function ISInventoryPage:updateContainerHighlight()
        local o = self:getContainerParent(self.coloredInv)
        if o and ((self.inventory ~= self.coloredInv) or self.isCollapsed) then
            if not ObjectsHighlightedElsewhere[self.player + 1][o] then
                o:setHighlighted(self.player, false); o:setOutlineHighlight(self.player, false); o:setOutlineHlAttached(self.player, false)
            end
            self.coloredInv = nil
        end
        o = self:getContainerParent(self.inventory)
        if not ObjectsHighlightedElsewhere[self.player + 1][o] and not self.isCollapsed and o then
            o:setHighlighted(self.player, true, false)
            if getCore():getOptionDoContainerOutline() then o:setOutlineHighlight(self.player, true); o:setOutlineHlAttached(self.player, true) end
            self.coloredInv = self.inventory
        end
    end
end
ISInventoryPage.__index = ISInventoryPage
local GAME_UCH = ISInventoryPage.updateContainerHighlight

-- ---------------------------------------------------------------- ZeD's code, cut from the World window
local ww = assert(slurp(ZD .. "ZeD_WorldWindow.lua"))
ZeD_WorldWindow = {}
_worldWins = {}
local function line(head) local a = assert(ww:find(head, 1, true), head); assert(loadstring(ww:sub(a, ww:find("\n", a, true))))() end
line("ZeD_WorldWindow._litElsewhere = ZeD_WorldWindow._litElsewhere or")
assert(loadstring(cut(ww, "function ZeD_WorldWindow._parentOf(")))()
assert(loadstring(cut(ww, "function ZeD_WorldWindow._unlight(")))()
line("ZeD_WorldWindow._litFor = ZeD_WorldWindow._litFor or {}")
assert(loadstring(cut(ww, "function ZeD_WorldWindow._litTable(")))()
assert(loadstring(cut(ww, "function ZeD_WorldWindow._elsewhereHolds(")))()
assert(loadstring(cut(ww, "function ZeD_WorldWindow._lightShown(")))()
assert(loadstring(cut(ww, "function ZeD_WorldWindow._showAlone(")))()
assert(loadstring(cut(ww, "function ZeD_WorldWindow._pageLightIsZeDs(")))()
assert(loadstring(cut(ww, "function ZeD_WorldWindow._pageLightOut(")))()
local WRAP = cut(ww, "if ISInventoryPage and ISInventoryPage.updateContainerHighlight and not ZeD_WorldWindow._pageHlWrapped then")

-- ---------------------------------------------------------------- one run: A on show, a plain click shows B
-- frames: the hidden page's update (the engine, every 100 ms), then ZeD's prerender
local function run(wrapped, outline, shownPage)
    OUTLINE = outline
    calls = {}
    ZeD_WorldWindow._litFor = {}
    ISInventoryPage.updateContainerHighlight = GAME_UCH
    ZeD_WorldWindow._pageHlWrapped = nil
    if wrapped then assert(loadstring(WRAP))() end
    local A, B = crate("A"), crate("B")
    local ia, ib = inv(A), inv(B)
    local win = { playerNum = 0, _activeTab = "loot", _mcSelected = {}, _mainVisible = true, _activeContainer = 1,
        _containers = { { inventory = ia }, { inventory = ib } } }
    local content = {}
    _worldWins[0] = win
    -- the game's hidden loot page picked the crate he faces, A
    local page = setmetatable({ player = 0, inventory = ia, isCollapsed = false, pin = true,
        getIsVisible = function() return shownPage end }, ISInventoryPage)
    local function frames(n) for _ = 1, n do page:updateContainerHighlight(); ZeD_WorldWindow._lightShown(win) end end
    frames(3)
    local first = { aHl = A.hl, aOl = A.ol, bHl = B.hl }
    ZeD_WorldWindow._showAlone(win, content, 2)   -- the strip click's path (onMouseDown, Ctrl not held)
    local mark = #calls
    frames(3)
    local after = {}
    for i = mark + 1, #calls do after[#after + 1] = calls[i] end
    return A, B, first, after, content, page
end

-- CONTROL: the fault as QA saw it
do
    local A, B = run(false, true, false)
    ok(A.hl == true and B.hl == true, "CONTROL without the page wrap A stays lit after the swap (the fault)")
end

-- SWAP, option on and off
for _, outline in ipairs({ true, false }) do
    local tag = outline and "(outline on)" or "(outline off)"
    local A, B, first, after, content, page = run(true, outline, false)
    ok(first.aHl == true and first.aOl == outline and first.bHl == false, "SWAP " .. tag .. " A on show: A lit, outline per option, B dark")
    ok(content._inventory ~= nil and B.hl == true and B.ol == outline, "SWAP " .. tag .. " B on show: B lit, outline per option")
    ok(A.hl == false and A.ol == false and A.att == false, "SWAP " .. tag .. " A dark: highlight, outline and attached outline off")
    local relit = false
    for _, c in ipairs(after) do if c == "A setHighlighted true" or c == "A setOutlineHighlight true" then relit = true end end
    ok(not relit, "SWAP " .. tag .. " nothing lights A after the swap")
    ok(page.coloredInv == nil, "SWAP " .. tag .. " the hidden page lets go of its light")
end

-- a hidden page's own light on a crate ZeD does not show goes out once
do
    OUTLINE = true
    ZeD_WorldWindow._litFor = {}
    local C = crate("C")
    local page = setmetatable({ player = 0, inventory = inv(C), isCollapsed = false,
        getIsVisible = function() return false end }, ISInventoryPage)
    page.coloredInv = page.inventory
    C.hl, C.ol, C.att = true, true, true
    page:updateContainerHighlight()
    ok(not C.hl and not C.ol and not C.att and page.coloredInv == nil, "SWAP a hidden page's leftover light goes out")
end

-- SHOWN: a page on show (safe mode) lights as the game's
do
    SAFE = true
    local A, B, _, _, _, page = run(true, true, true)
    ok(A.hl == true and page.coloredInv ~= nil, "SHOWN safe mode: the game's page lights its own pick")
    SAFE = false
end

print(string.format("world_light_swap_sim: %d checks, %d failed", pass + fail, fail))
if fail > 0 then os.exit(1) end
