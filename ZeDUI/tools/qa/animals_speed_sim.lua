-- ZeDUI/tools/qa/animals_speed_sim.lua  (Nov 7 2026, Build): the Animals tab's speed work (outside review #6 and #7),
-- with no game running. It cuts the real functions out of ZeD/AnimalsTab.lua and runs them beside the code they
-- replace (copied below from main at 7f17686e), over fake animals, a fake player, fake zones and a fake cell, and
-- counts the calls into the game each side makes.
--   ROWS     the ranch roster rows draw the same, frame for frame; their readings are taken once per animal per
--            500 ms (and again at once for another player); a change shows within 500 ms
--   LIGHT    the zone on the ground is lit the same after every frame (the view's zone changing, the game or ZeD
--            turning the highlight off, another zone selected, a zone remade under the same name, the zone gone)
--   HOOKS    the first scan is the same at once; a later one walks 6 rows a frame and lands on the same hooks in the
--            same order (ties too); a hook taken down mid-walk drops out; a floor change or an idle walk starts over
-- Run from the repo root:  lua51 ZeDUI/tools/qa/animals_speed_sim.lua
-- It prints the counts, FAIL lines, and a last line "animals_speed_sim: N checks, M failed"; exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]animals_speed_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local function readFile(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r", ""))
end
local SRC = readFile(Z .. "AnimalsTab.lua")
local function cut(from)
    local a = string.find(SRC, from, 1, true)
    assert(a, "not in AnimalsTab.lua: " .. from)
    local _, b = string.find(SRC, "\nend\n", a, true)
    return string.sub(SRC, a, b)
end
local function constLine(name)
    local l = string.match(SRC, "\n(local " .. name .. " *= *[%d]+)")
    assert(l, "no constant " .. name)
    return l .. "\n"
end

-- ---------------------------------------------------------------------------
-- CALL COUNTS
-- ---------------------------------------------------------------------------
local calls = {}
local function hit(k) calls[k] = (calls[k] or 0) + 1 end
local function resetCalls() calls = {} end
local function total(keys)
    local n = 0
    for _, k in ipairs(keys) do n = n + (calls[k] or 0) end
    return n
end

-- ---------------------------------------------------------------------------
-- THE GAME, FAKED
-- ---------------------------------------------------------------------------
local NOW = 100000
function getTimestampMs() return NOW end
function getText(k) hit("getText"); return "T:" .. k end
function getTexture(p) hit("getTexture"); if p == nil then return nil end return { tex = p } end
function getSpecificPlayer() return nil end

local LOG
local function rec(...)
    local t = { ... }
    for i = 1, #t do t[i] = tostring(t[i]) end
    LOG[#LOG + 1] = table.concat(t, ",")
end

local function color(n) return { r = n, g = n, b = n, a = 1 } end
ZeD = {
    T = {
        px = function(v) return v * 2 end,
        fontF1 = "F1", fontF2 = "F2", fontF5 = "F5",
        text = color(1), textDim = color(0.6), textOnFocus = color(0.1),
        hover = { r = 1, g = 1, b = 1, a = 0.08 },
        positive = "pos", warning = "warn", danger = "dng", info = "inf",
    },
    TM = {
        MeasureStringX = function(self, f, s) return #s * 7 end,
        getFontHeight = function(self, f) return 16 end,
    },
    Atoms = {
        drawStatusDot = function(panel, x, y, c, sz) rec("dot", x, y, c, sz) end,
        statusColor = function(f, text)   -- (Atoms.lua's status rule, punch list 143)
            local T = ZeD.T
            local lit = (f or 0) <= 0 and 0 or math.max(1, math.ceil(math.min(1, f) * 5 - 1e-6))
            if lit >= 4 then return T.positive end
            if lit >= 2 then return (text and T.warningText) or T.warning end
            return T.danger
        end,
        drawDividerH = function(panel, x, y, w, b) rec("div", x, y, w, b) end,
    },
    Molecules = { drawTag = function(panel, x, y, text, c) rec("tag", x, y, text, c) end },
    textCase = function(s) return s end,
}
local panel = {
    drawRect = function(self, ...) rec("rect", ...) end,
    drawText = function(self, ...) rec("text", ...) end,
    drawTextureScaledAspect = function(self, tex, ...) rec("texture", tex and tex.tex, ...) end,
}

-- animals: plain tables; the data layer counts every read
local function newAnimal(name, kind, female, baby, health, hunger, thirst, tags, age, portrait)
    return { name = name, kind = kind, female = female, baby = baby, health = health, hunger = hunger,
        thirst = thirst, tags = tags, age = age, portrait = portrait }
end
local AD_KEYS = { "resolvePortrait", "getDisplayName", "getHealth", "getHunger", "getThirst", "getConditionTags",
    "getAnimalType", "isFemale", "isBaby", "getAgeText" }
ZeD.AnimalsData = {
    resolvePortrait = function(a) hit("resolvePortrait"); return a.portrait end,
    getDisplayName = function(a) hit("getDisplayName"); return a.name end,
    getHealth = function(a) hit("getHealth"); return a.health end,
    getHunger = function(a) hit("getHunger"); return a.hunger end,
    getThirst = function(a) hit("getThirst"); return a.thirst end,
    getConditionTags = function(a, p) hit("getConditionTags")
        local out = {}
        for i, t in ipairs(a.tags) do out[i] = { label = t.label, sev = t.sev } end
        return out
    end,
    getAnimalType = function(a) hit("getAnimalType"); return a.kind end,
    isFemale = function(a) hit("isFemale"); return a.female end,
    isBaby = function(a) hit("isBaby"); return a.baby end,
    getAgeText = function(a, p) hit("getAgeText"); return (p and p.agePrefix or "") .. a.age end,
}
function AD() return ZeD.AnimalsData end

-- the real helpers the row draws with
local helpers = cut("local function sevColor(") .. cut("local function tagWidth(") .. cut("local function drawTag(")
    .. cut("local function tagY(") .. cut("local function dotColorForValue(")
assert(loadstring(string.gsub(helpers, "local function ", "function ")))()
tc = function(s) return ZeD.textCase(s) end
AROW_H, AROW_ICON_SZ, AROW_DOT_SZ, AROW_DOT_GAP, AROW_PAD = 48, 32, 7, 6, 6
do  -- the row's sizes must be the file's
    for _, n in ipairs({ "AROW_H", "AROW_ICON_SZ", "AROW_DOT_SZ", "AROW_DOT_GAP", "AROW_PAD" }) do
        local v = tonumber(string.match(SRC, "\nlocal " .. n .. " *= *(%d+)"))
        check("ROWS constant " .. n, v == _G[n], v)
    end
end

-- the new code, cut from the file
local NEW = assert(loadstring(constLine("SORT_CACHE_MS") .. constLine("HOOK_SCAN_R") .. constLine("HOOK_SCAN_ROWS")
    .. constLine("HOOK_SWEEP_STALE_MS")
    .. cut("local function getZoneByName(") .. cut("local function animalRowModel(") .. cut("local function drawAnimalRow(")
    .. cut("local function zoneLit(") .. cut("local function lightZone(") .. cut("local function highlightZone(")
    .. cut("local function hookSweepRows(") .. cut("local function hooksNear(")
    .. "\nreturn { animalRowModel = animalRowModel, drawAnimalRow = drawAnimalRow, highlightZone = highlightZone,"
    .. " hooksNear = hooksNear, SORT_CACHE_MS = SORT_CACHE_MS, HOOK_SCAN_ROWS = HOOK_SCAN_ROWS }"))()
check("ROWS the row cache is the sort's 500 ms", NEW.SORT_CACHE_MS == 500, NEW.SORT_CACHE_MS)

-- ---------------------------------------------------------------------------
-- BEFORE (main at 7f17686e, verbatim but for the name)
-- ---------------------------------------------------------------------------
local function oldDrawAnimalRow(panel, x, y, w, animal, player, hovered, onFocus)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM
    local rowH = T.px(AROW_H)
    local ink = onFocus and T.textOnFocus or T.text
    local inkDim = onFocus and T.textOnFocus or T.textDim

    -- Hover highlight
    if hovered then
        local hc = T.hover
        panel:drawRect(x, y, w, rowH, hc.a or 0.08, hc.r, hc.g, hc.b)
    end

    -- Portrait icon (32px, vertically centered)
    local portraitPath = ad.resolvePortrait(animal)
    local tex = getTexture(portraitPath)
    local iconY = y + math.floor((rowH - T.px(AROW_ICON_SZ)) / 2)
    if tex then
        panel:drawTextureScaledAspect(tex, x + T.px(AROW_PAD), iconY, T.px(AROW_ICON_SZ), T.px(AROW_ICON_SZ), 0.9, 1, 1, 1)
    end

    -- === TOP LINE (y + 4px) ===
    local topY = y + T.px(4)
    local textX = x + T.px(AROW_PAD) + T.px(AROW_ICON_SZ) + T.px(AROW_PAD)

    -- Name
    local nameFont = T.fontF2
    local name = ad.getDisplayName(animal)
    panel:drawText(name, textX, topY, ink.r, ink.g, ink.b, ink.a or 1, nameFont)
    local nameW = tm:MeasureStringX(nameFont, name)

    local dotX = textX + nameW + T.px(10)
    local dotY = topY + math.floor((tm:getFontHeight(nameFont) - T.px(AROW_DOT_SZ)) / 2)

    local health = ad.getHealth(animal)
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, health), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ) + T.px(AROW_DOT_GAP)

    local hunger = ad.getHunger(animal)
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, 100 - hunger), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ) + T.px(AROW_DOT_GAP)

    local thirst = ad.getThirst(animal)
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, 100 - thirst), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ)

    local tags = ad.getConditionTags(animal, player)
    local tagX = x + w - T.px(AROW_PAD)
    local tagRowY = tagY(topY, tm:getFontHeight(nameFont))
    for i = #tags, 1, -1 do
        local tag = tags[i]
        local tw = tagWidth(tag.label, sevColor(T, tag.sev) ~= nil)
        tagX = tagX - tw
        if tagX < dotX + T.px(8) then break end
        drawTag(panel, tagX, tagRowY, tag.label, tag.sev)
        tagX = tagX - T.px(4)
    end

    local botY = y + T.px(28)
    local secFont = T.fontF5

    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype
    local sex = ad.isFemale(animal) and getText("IGUI_Animal_Female") or getText("IGUI_Animal_Male")
    if ad.isBaby(animal) then sex = getText("IGUI_Animal_Baby") end
    local age = ad.getAgeText(animal, player)
    local infoLine = species .. ", " .. sex
    if age and age ~= "" then infoLine = infoLine .. " | " .. age end

    panel:drawText(infoLine, textX, botY, inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, secFont)

    A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)

    return rowH
end

-- ---------------------------------------------------------------------------
-- ROWS
-- ---------------------------------------------------------------------------
local animals = {
    newAnimal("Bessie", "cow", true, false, 90, 20, 10, { { label = "Milk", sev = "good" }, { label = "Hungry", sev = "warn" } }, "3 years", "cow.png"),
    newAnimal("Clucky", "hen", true, false, 40, 70, 45, { { label = "Eggs", sev = "info" } }, "8 months", "hen.png"),
    newAnimal("Rex", "ram", false, false, 20, 90, 95, { { label = "Starving", sev = "danger" }, { label = "Thirsty", sev = "danger" }, { label = "Old", sev = nil } }, "", "ram.png"),
    newAnimal("Piglet with a very long name indeed", "pig", false, true, 75, 35, 61, { { label = "A", sev = "warn" }, { label = "B", sev = "warn" }, { label = "C", sev = "warn" } }, "2 weeks", nil),
}
local playerA = { agePrefix = "" }
local playerB = { agePrefix = "B:" }

local function drawFrame(useNew, zs, player, hoveredIdx, focusIdx)
    LOG = {}
    for i, a in ipairs(animals) do
        local y = (i - 1) * 96
        if useNew then
            NEW.drawAnimalRow(panel, 4, y, 300, NEW.animalRowModel(zs, a, player), i == hoveredIdx, i == focusIdx)
        else
            oldDrawAnimalRow(panel, 4, y, 300, a, player, i == hoveredIdx, i == focusIdx)
        end
    end
    return table.concat(LOG, "\n")
end

local zs = {}
local FRAMES = 120   -- two seconds at 60 frames
resetCalls()
local same = true
local firstDiff
local oldReads, newReads = 0, 0
for f = 1, FRAMES do
    NOW = 100000 + math.floor(f * 1000 / 60)
    local hv, fo = (f % 4) + 1, (f % 3) + 1
    resetCalls()
    local o = drawFrame(false, zs, playerA, hv, fo)
    oldReads = oldReads + total(AD_KEYS) + (calls.getText or 0) + (calls.getTexture or 0)
    resetCalls()
    local n = drawFrame(true, zs, playerA, hv, fo)
    newReads = newReads + total(AD_KEYS) + (calls.getText or 0) + (calls.getTexture or 0)
    if o ~= n and same then same = false; firstDiff = f end
end
check("ROWS the same draw calls every frame (2 s, hover and focus moving)", same, firstDiff)
print(string.format("ROWS %d rows x %d frames: game reads before %d, after %d", #animals, FRAMES, oldReads, newReads))
check("ROWS reads once per animal per 500 ms (4 rebuilds in 2 s)", newReads <= oldReads / 20, newReads)

-- a change shows within 500 ms, and not before the cache runs out
NOW = NOW + 1
animals[1].health = 10
animals[2].tags = { { label = "Sick", sev = "danger" } }
local n = drawFrame(true, zs, playerA)
local o = drawFrame(false, zs, playerA)
check("ROWS a change waits for the 500 ms (the sort's own wait)", n ~= o)
NOW = zs._rowModels.t + NEW.SORT_CACHE_MS
n = drawFrame(true, zs, playerA)
check("ROWS a change is drawn at 500 ms", n == o)
-- another player (the age reads with the player): at once
NOW = NOW + 1
n = drawFrame(true, zs, playerB)
o = drawFrame(false, zs, playerB)
check("ROWS another player: read again at once", n == o)
-- only the rows drawn are read
resetCalls()
NOW = NOW + 1000
local zs2 = {}
LOG = {}
NEW.drawAnimalRow(panel, 0, 0, 300, NEW.animalRowModel(zs2, animals[3], playerA), false, false)
check("ROWS one row drawn, one animal read", calls.getDisplayName == 1 and calls.getConditionTags == 1, calls.getDisplayName)

-- ---------------------------------------------------------------------------
-- LIGHT
-- ---------------------------------------------------------------------------
local function jlist(t)
    return { t = t, size = function(self) return #self.t end, get = function(self, i) return self.t[i + 1] end }
end
local function newWorld()
    local W = { zones = {}, see = false, sel = {} }
    W.player = {
        isSeeDesignationZone = function(self) hit("isSee"); return W.see end,
        setSeeDesignationZone = function(self, b) hit("set"); W.see = b end,
        getSelectedZonesForHighlight = function(self) hit("getSel"); return jlist(W.sel) end,
        resetSelectedZonesForHighlight = function(self) hit("set"); W.sel = {} end,
        addSelectedZoneForHighlight = function(self, id) hit("set"); W.sel[#W.sel + 1] = id end,
    }
    function W.add(name, id, streamed)
        local z = { name = name, id = id, streamed = streamed ~= false }
        z.isStillStreamed = function(self) hit("zone"); return self.streamed end
        z.getName = function(self) hit("zone"); return self.name end
        z.getId = function(self) hit("zone"); return self.id end
        W.zones[#W.zones + 1] = z
        return z
    end
    return W
end
local worldOld, worldNew = newWorld(), newWorld()
local function both(fn) fn(worldOld); fn(worldNew) end
for i = 1, 30 do both(function(W) W.add("Pen " .. i, 1000 + i) end) end
DesignationZoneAnimal = { getAllZones = function() hit("zone"); return jlist(CUR.zones) end }

-- before: the zone view's lines, every frame
local function oldLight(player, zoneName)
    local zoneObj = NEW_getZoneByName(zoneName)
    if player and zoneObj then
        player:setSeeDesignationZone(true)
        player:resetSelectedZonesForHighlight()
        player:addSelectedZoneForHighlight(zoneObj:getId())
    end
end
NEW_getZoneByName = assert(loadstring(cut("local function getZoneByName(") .. "\nreturn getZoneByName"))()

local winNew = {}
local lightSame, lightDiff = true, nil
local zoneOld, zoneNew = 0, 0
local setOld, setNew = 0, 0
local function lightFrame(zoneName, label)
    resetCalls()
    CUR = worldOld
    oldLight(worldOld.player, zoneName)
    zoneOld = zoneOld + (calls.zone or 0); setOld = setOld + (calls.set or 0)
    resetCalls()
    CUR = worldNew
    NEW.highlightZone(winNew, worldNew.player, zoneName)
    zoneNew = zoneNew + (calls.zone or 0) + (calls.isSee or 0) + (calls.getSel or 0); setNew = setNew + (calls.set or 0)
    local a = tostring(worldOld.see) .. ":" .. table.concat(worldOld.sel, ",")
    local b = tostring(worldNew.see) .. ":" .. table.concat(worldNew.sel, ",")
    if a ~= b and lightSame then lightSame = false; lightDiff = label .. " " .. a .. " vs " .. b end
    return a == b
end
local function frames(nf, zoneName, label, before, loose)
    for f = 1, nf do
        NOW = NOW + 16
        if before then both(function(W) before(W, f) end) end
        if loose then
            local keep, keepD = lightSame, lightDiff
            lightFrame(zoneName, label)
            lightSame, lightDiff = keep, keepD
        else
            lightFrame(zoneName, label)
        end
    end
end
NOW = 200000
frames(120, "Pen 20", "steady")
print(string.format("LIGHT 120 frames on one zone (30 zones): zone reads before %d, after %d; highlight sets before %d, after %d",
    zoneOld, zoneNew, setOld, setNew))
check("LIGHT lit once, not every frame", setNew == 3, setNew)
check("LIGHT the zone looked up every 500 ms, not every frame", zoneNew < zoneOld / 10, zoneNew)
frames(60, "Pen 20", "game turns it off", function(W, f) if f % 7 == 0 then W.see = false end end)
check("LIGHT the game turns it off: lit again next frame", lightSame, lightDiff)
frames(60, "Pen 20", "game resets selection", function(W, f) if f % 5 == 0 then W.sel = {} end end)
check("LIGHT the selection cleared: lit again", lightSame, lightDiff)
frames(60, "Pen 20", "game selects others", function(W, f) if f % 9 == 0 then W.sel = { 1003, 1004 } end end)
check("LIGHT other zones selected: back to this one", lightSame, lightDiff)
frames(30, "Pen 7", "zone changed")
check("LIGHT the view's zone changes: the new one lit at once", lightSame and worldNew.sel[1] == 1007, lightDiff)
-- (the one difference: a zone remade under the same name while lit is picked up within 500 ms, not the same frame)
frames(32, "Pen 7", "zone remade", function(W, f) if f == 1 then W.zones[7].id = 5007 end end, true)
frames(40, "Pen 7", "zone remade, settled")
check("LIGHT a zone remade under the same name: lit by its new id within 500 ms", lightSame and worldNew.sel[1] == 5007, lightDiff)
frames(20, "Pen 7", "zone renamed away, selection cleared", function(W, f)
    if f == 1 then W.zones[7].name = "Pen 7b"; W.sel = {} end
    if f == 10 then W.zones[7].name = "Pen 7" end
end)
check("LIGHT renamed away and cleared within 500 ms: nothing lit until the name is back, as before", lightSame, lightDiff)
frames(40, "Pen 7", "zone not streamed", function(W, f) if f == 1 then W.zones[7].streamed = false; W.sel = {} end end)
check("LIGHT a zone gone: nothing lit, as before", lightSame and #worldNew.sel == 0, lightDiff)
frames(40, "Pen 7", "zone back", function(W, f) if f == 1 then W.zones[7].streamed = true end end)
check("LIGHT the zone back: lit", lightSame and worldNew.sel[1] == 5007, lightDiff)
frames(5, nil, "no zone")
check("LIGHT no zone: nothing changes", lightSame, lightDiff)
local otherPlayer = newWorld().player
otherPlayer.isSeeDesignationZone = function() return false end
local lit = false
otherPlayer.setSeeDesignationZone = function(self, b) lit = b end
otherPlayer.resetSelectedZonesForHighlight = function() end
otherPlayer.addSelectedZoneForHighlight = function() end
CUR = worldNew
NEW.highlightZone(winNew, otherPlayer, "Pen 7")
check("LIGHT another player: lit at once", lit == true)
NEW.highlightZone(winNew, nil, "Pen 7")
check("LIGHT no player: no error", true)

-- ---------------------------------------------------------------------------
-- HOOKS
-- ---------------------------------------------------------------------------
function instanceof(o, cls) hit("instanceof"); return o.cls == cls end
local hookWorld = {}
local function hk(x, y, z) local h = { cls = "IsoButcherHook", x = x, y = y, z = z or 0 }
    local sq = { getX = function() hit("sqXY"); return x end, getY = function() hit("sqXY"); return y end }
    h.getSquare = function(self) hit("getSquare"); if self.gone then return nil end return sq end
    return h
end
local SQ = {}
local function placeAt(o, x, y, z)
    local k = x .. "," .. y .. "," .. (z or 0)
    SQ[k] = SQ[k] or {}
    table.insert(SQ[k], o)
end
local emptyObjs = { size = function() return 0 end }
function getCell()
    return { getGridSquare = function(self, x, y, z)
        hit("getGridSquare")
        local l = SQ[x .. "," .. y .. "," .. z]
        if not l then return { getObjects = function() hit("getObjects"); return emptyObjs end } end
        return { getObjects = function() hit("getObjects"); return jlist(l) end }
    end }
end
local hooksAll = {}
local function addHook(x, y, z)
    local h = hk(x, y, z)
    placeAt(h, x, y, z)
    placeAt({ cls = "IsoObject" }, x, y, z)
    hooksAll[#hooksAll + 1] = h
    return h
end
-- hooks at mixed and equal distances (ties), one on another floor, one past the 20 tiles
for _, p in ipairs({ { 103, 100 }, { 97, 100 }, { 100, 103 }, { 100, 97 }, { 110, 110 }, { 85, 92 }, { 119, 120 },
    { 101, 101 }, { 99, 99 }, { 121, 100 } }) do addHook(p[1], p[2]) end
addHook(102, 100, 1)
local player = { sqx = 100, sqy = 100, sqz = 0 }
player.getCurrentSquare = function(self)
    return { getX = function() return self.sqx end, getY = function() return self.sqy end, getZ = function() return self.sqz end }
end
player.getX = function(self) hit("playerXY"); return self.sqx + 0.5 end
player.getY = function(self) hit("playerXY"); return self.sqy + 0.25 end

-- before (main at 7f17686e)
local function oldHooksNear(win, player)
    local HOOK_SCAN_R = 20
    local now = getTimestampMs()
    local c = win._animalsHookScan
    if c and now - c.t < 2000 then return c.list end
    local list = {}
    local sq0 = player and player:getCurrentSquare()
    if sq0 then
        local cell = getCell()
        for yy = sq0:getY() - HOOK_SCAN_R, sq0:getY() + HOOK_SCAN_R do
            for xx = sq0:getX() - HOOK_SCAN_R, sq0:getX() + HOOK_SCAN_R do
                local sq = cell:getGridSquare(xx, yy, sq0:getZ())
                if sq then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if instanceof(o, "IsoButcherHook") then list[#list + 1] = o end
                    end
                end
            end
        end
    end
    -- nearest first
    if player then
        local function d2(o) local s = o:getSquare(); return (s:getX() - player:getX()) ^ 2 + (s:getY() - player:getY()) ^ 2 end
        table.sort(list, function(a, b) return d2(a) < d2(b) end)
    end
    win._animalsHookScan = { t = now, list = list }
    return list
end
local function ids(list)
    local t = {}
    for i, h in ipairs(list) do t[i] = h.x .. "," .. h.y .. "," .. h.z end
    return table.concat(t, " ")
end

NOW = 300000
local wOld, wNew = {}, {}
resetCalls()
local lo = oldHooksNear(wOld, player)
local oldCost = { grid = calls.getGridSquare or 0, sortReads = (calls.getSquare or 0) + (calls.sqXY or 0) + (calls.playerXY or 0) }
resetCalls()
local ln = NEW.hooksNear(wNew, player)
local newCost = { grid = calls.getGridSquare or 0, sortReads = (calls.getSquare or 0) + (calls.sqXY or 0) + (calls.playerXY or 0) }
check("HOOKS first scan: the same hooks, the same order, at once", ids(lo) == ids(ln) and #ln == 9, ids(ln) .. " | " .. ids(lo))
print(string.format("HOOKS first scan (9 hooks): squares %d before, %d after; sort reads %d before, %d after",
    oldCost.grid, newCost.grid, oldCost.sortReads, newCost.sortReads))
check("HOOKS the sort reads each hook once", newCost.sortReads == 9 * 3 + 2, newCost.sortReads)
-- within 2 s: the kept list, no walk
resetCalls()
NOW = NOW + 1999
check("HOOKS within 2 s: the kept list", NEW.hooksNear(wNew, player) == ln and (calls.getGridSquare or 0) == 0)
-- after 2 s: the walk spreads; the last list stays up until it is done
NOW = NOW + 1
player.sqx, player.sqy = 101, 99
local newHook = addHook(104, 99)
local maxFrame, framesTaken, lastList = 0, 0, nil
repeat
    resetCalls()
    lastList = NEW.hooksNear(wNew, player)
    framesTaken = framesTaken + 1
    if (calls.getGridSquare or 0) > maxFrame then maxFrame = calls.getGridSquare end
    if lastList == ln then NOW = NOW + 16 end
until lastList ~= ln or framesTaken > 20
lo = oldHooksNear({}, player)
check("HOOKS a later scan: 7 frames, 6 rows (246 squares) a frame at most", framesTaken == 7 and maxFrame == 6 * 41,
    framesTaken .. " frames, " .. maxFrame)
check("HOOKS a later scan lands on the same hooks in the same order", ids(lastList) == ids(lo), ids(lastList) .. " | " .. ids(lo))
print(string.format("HOOKS a later scan: one frame of %d squares before, at most %d a frame over %d frames after",
    oldCost.grid, maxFrame, framesTaken))
-- a hook taken down while the walk runs drops out (before: the sort would have thrown on it)
NOW = NOW + 2000
NEW.hooksNear(wNew, player)
newHook.gone = true
local guard = 0
repeat NOW = NOW + 16; lastList = NEW.hooksNear(wNew, player); guard = guard + 1 until wNew._animalsHookSweep == nil or guard > 20
local has = false
for _, h in ipairs(lastList) do if h == newHook then has = true end end
check("HOOKS a hook gone mid-walk drops out", not has and #lastList == 9, #lastList)
newHook.gone = nil
-- a floor change mid-walk starts over on the new floor
NOW = NOW + 2000
NEW.hooksNear(wNew, player)
player.sqz = 1
guard = 0
repeat NOW = NOW + 16; lastList = NEW.hooksNear(wNew, player); guard = guard + 1 until wNew._animalsHookSweep == nil or guard > 20
lo = oldHooksNear({}, player)
check("HOOKS a floor change mid-walk: the new floor's hooks", ids(lastList) == ids(lo) and #lastList == 1, ids(lastList))
player.sqz = 0
-- a walk left idle (the view shut) starts over from where the player is
NOW = NOW + 2000
NEW.hooksNear(wNew, player)
local sw = wNew._animalsHookSweep
NOW = NOW + 5000
player.sqx, player.sqy = 110, 110
NEW.hooksNear(wNew, player)
check("HOOKS an idle walk starts over around the player", wNew._animalsHookSweep ~= sw and wNew._animalsHookSweep.cx == 110)
guard = 0
repeat NOW = NOW + 16; lastList = NEW.hooksNear(wNew, player); guard = guard + 1 until wNew._animalsHookSweep == nil or guard > 20
lo = oldHooksNear({}, player)
check("HOOKS after the restart: the same hooks", ids(lastList) == ids(lo), ids(lastList) .. " | " .. ids(lo))
-- slow frames (a walk step 900 ms apart) still finish
NOW = NOW + 2000
guard = 0
repeat lastList = NEW.hooksNear(wNew, player); NOW = NOW + 900; guard = guard + 1 until wNew._animalsHookSweep == nil or guard > 20
check("HOOKS slow frames still finish the walk", wNew._animalsHookSweep == nil and guard == 7, guard)
-- no player: an empty list, as before
check("HOOKS no player: empty", #NEW.hooksNear({}, nil) == 0 and #oldHooksNear({}, nil) == 0)

print("animals_speed_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
