-- ZeDUI/tools/qa/oc_fluid_layout_sim.lua  (Nov 26 2026, Build; the director's call, fluid card side by side)
-- Draws the real ObjectCardFluid.lua body over a card that keeps where everything lands, with the English words
-- from Translate/EN/UI.json and a 7-unit character, at the full card's body (450) and the half card's (186):
--   * the full card puts From and Into side by side: one line, Into in the right half
--   * the half card stacks them: Into under From, both at the left edge
--   * nothing drawn (words, keys, strips, zones) runs past the body's width, at either size
--   * the two containers in the pour leave the list (their rows' From / Into keys are not drawn); the rest stay
--   * the amount steps in quarters of the most a pour can move with - and +, the D-pad's left and right on
--     either key the same; the box between them reads the litres, the quarter's name beside it on the full card
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_fluid_layout_sim.lua
-- It prints FAIL lines and a last line "oc_fluid_layout_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_fluid_layout_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("oc_fluid_layout_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed > 0 and 1 or 0)
end
local function readFile(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end

-- the English words, as the game reads them
local EN = {}
for k, v in readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json"):gmatch('"(UI_ZeD_[%w_]+)"%s*:%s*"(.-)",?\n') do EN[k] = v end
local GAME = { Fluid_Amount = "Amount", Fluid_All = "All", Fluid_Empty = "Empty", IGUI_media_stop = "Stop",
    Fluid_Unknown = "Unknown", Fluid_Transferring = "Pouring", Fluid_Mixture = "Mixture" }
function getText(k) return GAME[k] or EN[k] or k end
function getTextOrNull(k) return GAME[k] or EN[k] end
function getDebug() return false end
SandboxVars = {}

-- the game's liquids and containers (water only)
local WATER = { getTranslatedName = function() return "Water" end, getColor = function() return nil end,
    getFluidType = function() return "Water" end, isPoisonous = function() return false end }
Fluid = { getAllFluids = function() return { size = function() return 1 end, get = function() return WATER end } end }
local BLUE = { getRedFloat = function() return 0.2 end, getGreenFloat = function() return 0.4 end, getBlueFloat = function() return 0.9 end }
local function newFC(name, amt, cap)
    local fc = { name = name, amt = amt, cap = cap }
    function fc:getAmount() return self.amt end
    function fc:getCapacity() return self.cap end
    function fc:isEmpty() return self.amt <= 0 end
    function fc:isHiddenAmount() return false end
    function fc:getColor() return BLUE end
    function fc:getPrimaryFluid() return WATER end
    function fc:isPureFluid() return true end
    function fc:isPoisonous() return false end
    function fc:getPoisonEffect() return "None" end
    function fc:isTainted() return false end
    function fc:canPlayerEmpty() return true end
    function fc:getSpecificFluidAmount(f) return (f == WATER) and self.amt or 0 end
    function fc:getTranslatedContainerName() return self.name end
    return fc
end
local function newSq(x, y) return { getX = function() return x end, getY = function() return y end, getZ = function() return 0 end } end
local nextId = 10
local function newItem(name, fc)
    nextId = nextId + 1
    local id = nextId
    return { _item = true, getDisplayName = function() return name end, isInPlayerInventory = function() return true end,
        getTex = function() return nil end, getID = function() return id end, getFluidContainer = function() return fc end }
end
local owners = {}
local function wrapFC(fc, owner)
    local c = { fc = fc, owner = owner }
    function c:getFluidContainer() return self.fc end
    function c:isItem() return self.owner._item == true end
    function c:isIsoPanel() return self.owner._iso == true end
    function c:isResource() return false end
    function c:isValid() return true end
    function c:getOwner() return self.owner end
    return c
end
ISFluidContainer = { new = function(_, fc) return wrapFC(fc, owners[fc]) end }
ISFluidUtil = { validateContainer = function(c) return c ~= nil and c.getFluidContainer ~= nil end }
FluidContainer = { CanTransfer = function(a, b) return a ~= b and a.amt > 0 and b.amt < b.cap end, GetTransferReason = function() return nil end }
FluidUtil = { roundTransfer = function(v) return math.floor(v * 100 + 0.5) / 100 end }
ISTimedActionQueue = { getTimedActionQueue = function() return { queue = {} } end }
function instanceof(o, cls)
    if type(o) ~= "table" then return false end
    if cls == "InventoryItem" then return o._item == true end
    return false
end

-- the player: a bottle, a pot and a pop bottle; the rain collector 4 tiles off
local player = { inv = {} }
function player:getX() return 100 end
function player:getY() return 100 end
function player:hasFullInventory() return false end
function player:getInventory()
    local items = self.inv
    return { getAllEvalRecurse = function(_, fn)
        local out = {}
        for _, it in ipairs(items) do if fn(it) then out[#out + 1] = it end end
        return { size = function() return #out end, get = function(_, i) return out[i + 1] end }
    end }
end
local bottleFC, potFC, popFC = newFC("Water Bottle", 0, 1.0), newFC("Cooking Pot", 1.2, 3.0), newFC("Pop Bottle", 0, 0.6)
local bottleIt, potIt, popIt = newItem("Water Bottle", bottleFC), newItem("Cooking Pot", potFC), newItem("Pop Bottle", popFC)
owners[bottleFC], owners[potFC], owners[popFC] = bottleIt, potIt, popIt
player.inv = { bottleIt, potIt, popIt }
local collSq = newSq(104, 100)
local collFC = newFC("Rain Collector Barrel", 50, 400)
owners[collFC] = { _iso = true, getSquare = function() return collSq end }
local coll, bottle = wrapFC(collFC, owners[collFC]), wrapFC(bottleFC, bottleIt)

-- ZeD: the words, and a theme where a design unit is a pixel and a character 7 wide
local CW = 7
local function tw(s) return CW * #tostring(s or "") end
ZeD = { tr = function(k, ...)
    local s = EN[k] or GAME[k] or k
    for i, v in ipairs({ ... }) do s = s:gsub("%%" .. i, tostring(v)) end
    return s
end, Safe = { on = function() return false end } }
local COL = { r = 1, g = 1, b = 1, a = 1 }
ZeD.T = setmetatable({ px = function(n) return n end, selectionA = 0.2, fillBarH = 6, buttonH = 22 },
    { __index = function() return COL end })
ZeD.TM = { MeasureStringX = function(_, _, s) return tw(s) end, getFontHeight = function() return 12 end }

-- what the card drew: texts { s, x, y, w }, boxes { x, y, w, h, what }, zones
local texts, boxes, zones = {}, {}, {}
local function noteText(s, x, y) texts[#texts + 1] = { s = tostring(s), x = x, y = y, w = tw(s) } end
local function noteBox(what, x, y, w, h) boxes[#boxes + 1] = { what = what, x = x, y = y, w = w, h = h } end
ZeD.Atoms = {
    textCase = function(s) return s end,
    drawTextRight = function(_, s, x, y) noteText(s, x - tw(s), y) end,
    fillSegsLit = function(f) return math.floor((f or 0) * 10 + 1e-6) end,
    drawSegFill = function(_, x, y, w, h) noteBox("seg", x, y, w, h); return false end,
    fillBarCompactH = function() return 4 end,
    frame = function(_, x, y, w, h) noteBox("frame", x, y, w, h) end,
    drawStatusDot = function(_, x, y, c, s) noteBox("dot", x, y, s, s) end,
    drawSmoothBar = function(_, x, y, w) noteBox("bar", x, y, w, 4) end,
    mouseIn = function() return false end,
}
ZeD.Help = { set = function() end }
-- (cut to the room with "...", as the game's)
ZeD.CraftingCore = { truncText = function(s, _, w)
    s = tostring(s or "")
    if tw(s) <= w then return s end
    while #s > 0 and tw(s .. "...") > w do s = s:sub(1, -2) end
    return s .. "..."
end }
ZeD.Molecules = { drawEmptyLine = function(_, x, y, w, s) noteText(ZeD.CraftingCore.truncText(s, nil, w), x, y) end }
local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
local OC = { kinds = {}, LEASH = 6, REFRESH = 15, DOT = "|", call = call, ui = {} }
function OC.register(def) OC.kinds[def.id] = def end
function OC.whereOf() return "Inventory" end
function OC.squareDist(p, sq) return math.sqrt((sq:getX() - p:getX()) ^ 2 + (sq:getY() - p:getY()) ^ 2) end
local CARD = {}
OC.ui.fill = function(_, x, y, w, h) noteBox("fill", x, y, w, h) end
OC.ui.section = function(_, x, y, w, a, b) noteText(a, x, y); noteBox("section", x, y, w, 20); return 20 end
OC.ui.tagW = function(s, mark) return tw(s) + 10 + (mark and 10 or 0) end
OC.ui.tag = function(_, x, y, s) noteText(s, x + 5, y); noteBox("tag", x, y, OC.ui.tagW(s), 16) end
OC.ui.buttonW = function(s) return tw(s) + 16 end
OC.ui.button = function(card, x, y, s, o)
    o = o or {}
    local w = o.w or OC.ui.buttonW(s)
    noteBox("button", x, y, w, o.h or 22)
    noteText(s, x + math.floor((w - tw(s)) / 2), y)
    if o.fid then card:zone({ fid = o.fid, x = x, y = y, w = w, h = o.h or 22, run = (not o.disabled) and o.run or nil }) end
    return w
end
ZeD.ObjectCards = OC
function CARD:drawText(s, x, y) noteText(s, x, y) end
function CARD:drawRect(x, y, w, h) noteBox("rect", x, y, w, h) end
function CARD:drawRectBorder(x, y, w, h) noteBox("border", x, y, w, h) end
function CARD:drawTextureScaledAspect(_, x, y, w, h) noteBox("icon", x, y, w, h) end
function CARD:zone(z) zones[#zones + 1] = z end
function CARD:focusOf() return nil end

function require() end
assert(loadstring(readFile(Z .. "ObjectCardFluid.lua"), "ObjectCardFluid.lua"))()
local def = OC.kinds.fluid
check("the fluid card registers", def ~= nil)
if not def then done() end

local X0 = 10
local function draw(t, w)
    texts, boxes, zones = {}, {}, {}
    def.refresh(t, player)
    local ok, err = pcall(def.body, CARD, X0, 0, w, t, player)
    check("the body draws at " .. w, ok, err)
end
local function text(s) for _, e in ipairs(texts) do if e.s == s then return e end end end
local function zone(fid) for _, z in ipairs(zones) do if z.fid == fid then return z end end end
local function fits(w)
    local bad = {}
    local r = X0 + w
    for _, e in ipairs(texts) do if e.x < X0 or e.x + e.w > r then bad[#bad + 1] = "'" .. e.s .. "' " .. e.x .. ".." .. (e.x + e.w) end end
    for _, b in ipairs(boxes) do if b.x < X0 or b.x + b.w > r then bad[#bad + 1] = b.what .. " " .. b.x .. ".." .. (b.x + b.w) end end
    for _, z in ipairs(zones) do if z.x < X0 or z.x + z.w > r then bad[#bad + 1] = z.fid .. " " .. z.x .. ".." .. (z.x + z.w) end end
    return #bad == 0, table.concat(bad, "; ")
end

local FROM, INTO = EN.UI_ZeD_Fluid_From, EN.UI_ZeD_Fluid_Into
check("the From and Into words are in the English", FROM ~= nil and INTO ~= nil)
local bottleKey, potKey = "i" .. tostring(bottleIt:getID()), "i" .. tostring(potIt:getID())

-- the full card: side by side
local t = { key = "fluid", frac = 1, from = coll, into = bottle, pinned = coll, sq = collSq }
local FULL, HALF = 450, 186
draw(t, FULL)
-- (the column labels are the first From and Into drawn: the rows' keys come after them)
local f, i = text(FROM), text(INTO)
check("full: From and Into are drawn", f ~= nil and i ~= nil)
if f and i then
    check("full: From and Into sit on one line", f.y == i.y, f.y .. " / " .. i.y)
    check("full: From at the left edge, Into in the right half", f.x == X0 and i.x >= X0 + FULL / 2, f.x .. " / " .. i.x)
end
local ok, why = fits(FULL)
check("full: nothing runs past the card's width", ok, why)
check("full: the bottle (Into) leaves the list", zone("fl:into:" .. bottleKey) == nil and zone("fl:from:" .. bottleKey) == nil)
check("full: the collector (From) leaves the list", zone("fl:from:pin") == nil and zone("fl:into:pin") == nil)
check("full: the pot and the pop bottle stay, with From and Into", zone("fl:from:" .. potKey) ~= nil and zone("fl:into:" .. potKey) ~= nil)
check("full: the list is headed Other containers", text(EN.UI_ZeD_Fluid_OtherContainers) ~= nil)
check("full: the quarter's name shows (All)", text("All") ~= nil)
local where = nil
for _, e in ipairs(texts) do if e.s:sub(1, 6) == ZeD.tr("UI_ZeD_Fluid_NearbyTiles", 4):sub(1, 6) then where = e end end
check("full: the collector's where shows by its name (cut to the room)", where ~= nil)

-- the half card: stacked
draw(t, HALF)
f, i = text(FROM), text(INTO)
check("half: From and Into are drawn", f ~= nil and i ~= nil)
if f and i then
    check("half: Into stacks under From", i.y > f.y, f.y .. " / " .. i.y)
    check("half: both at the left edge", f.x == X0 and i.x == X0, f.x .. " / " .. i.x)
end
ok, why = fits(HALF)
check("half: nothing runs past the card's width", ok, why)
check("half: no quarter's name (no room)", text("All") == nil)
local fz, nz = zone("fl:from:" .. potKey), zone("fl:into:" .. potKey)
local pn = text("Cooking Pot")
check("half: a row's keys sit on a line under its name", fz and nz and pn and fz.y > pn.y and nz.y == fz.y)

-- nothing picked on the right: the hint fits too
local t0 = { key = "fluid", frac = 1, from = coll, pinned = coll, sq = collSq }
for _, w in ipairs({ FULL, HALF }) do
    draw(t0, w)
    ok, why = fits(w)
    check("no Into yet at " .. w .. ": nothing runs past the card's width", ok, why)
    check("no Into yet at " .. w .. ": no amount keys", zone("fl:amt:less") == nil and zone("fl:amt:more") == nil)
end

-- the amount in quarters: the most is the bottle's 1 L; the box reads the litres
local function boxText()
    local a, b = zone("fl:amt:less"), zone("fl:amt:more")
    if not (a and b) then return nil end
    for _, e in ipairs(texts) do
        if e.x >= a.x + a.w and e.x + e.w <= b.x and e.y >= a.y - 2 and e.y <= a.y + a.h then return e.s end
    end
end
for _, w in ipairs({ FULL, HALF }) do
    t.frac = 1
    draw(t, w)
    local less, more = zone("fl:amt:less"), zone("fl:amt:more")
    check(w .. ": the - and + keys are stops", less ~= nil and more ~= nil)
    if not (less and more) then done() end
    check(w .. ": both keys take the D-pad's left and right", type(less.dpad) == "function" and type(more.dpad) == "function")
    check(w .. ": at the most, + is greyed", more.run == nil and less.run ~= nil)
    check(w .. ": the box reads 1.00 L", boxText() == "1.00 L", boxText())
    local want = { { 0.75, "0.75 L" }, { 0.5, "0.50 L" }, { 0.25, "0.25 L" }, { 0, "0.00 L" } }
    for _, s in ipairs(want) do
        local z = zone("fl:amt:less")
        if z and z.run then z.run() end
        draw(t, w)
        check(w .. ": - steps to " .. s[1], math.abs((t.frac or -1) - s[1]) < 1e-9, t.frac)
        check(w .. ": and the box reads " .. s[2], boxText() == s[2], boxText())
    end
    check(w .. ": at nothing, - is greyed", zone("fl:amt:less").run == nil and zone("fl:amt:more").run ~= nil)
    check(w .. ": the pad's left at nothing stays at nothing", zone("fl:amt:less").dpad("left") == true and t.frac == 0)
    check(w .. ": the pad's right on - steps up a quarter", zone("fl:amt:less").dpad("right") == true and t.frac == 0.25)
    draw(t, w)
    zone("fl:amt:more").run()
    check(w .. ": + steps up a quarter", t.frac == 0.5)
    check(w .. ": the pad's up and down move on", zone("fl:amt:more").dpad("up") == false)
    draw(t, w)
    ok, why = fits(w)
    check(w .. ": at a half, nothing runs past the card's width", ok, why)
    check(w .. ": the pour's verb pours the quarter", (function()
        for _, v in ipairs(t.verbs or {}) do if v.id == "pour" then return v.enabled == true end end
    end)())
end

done()
