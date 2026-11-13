-- ZeDUI/tools/qa/zedqa_cov_equipfurn.lua  (Nov 12 2026, QA coverage: audit Table B, group "equipfurn")
-- In game on the ZeD-QA save only (Saves/Sandbox/ZeD-QA), at the QA home (the Irvington drag strip, 925,13040).
-- Copy to Zomboid/Lua/zedqa.lua and bump zedqa.go, or run cov_equipfurn.txt with zedqa_run.ps1 -Manifest; grep
-- console.txt for "ZEDQA cov_equipfurn". Every check prints "PASS <what>" or "FAIL <what> (<got> vs <want>)",
-- read from ZeD's own objects; the run ends with RESULT and DONE. Captures: Screenshots/zqa_cov_ef_*.png, each
-- announced by a SHOT line.
--
-- WHAT IT CHECKS
-- 1. Equip tab, the defense summary (EquipmentTab.lua's defense dashboard, ProtectionTab.gatherData). Read from
--    the window's own model (win._equipProtCache, what the dashboard draws), against a model this script builds
--    from the worn items (WornItems, the script item's BloodClothingType, Clothing.getDefForPart) and against the
--    game's own per-part number (IsoGameCharacter.getBodyPartClothingDefense, what vanilla's protection panel
--    shows):
--    - bare (the clothes that cover parts taken off): 0 garments, 0%, grade F, every part uncovered, no best part;
--    - a staged outfit (hard hat, denim shirt under a leather jacket, jeans, leather gloves, work boots): the
--      garments, the parts, each part's bite / scratch / bullet / layers, the average, its grade, the uncovered
--      count, the worst and best part; single-layer parts equal the game's number; layered parts equal the game's
--      number (the game adds the layers, up to 100); the Equip list has a row for every garment; the summary
--      refreshed by itself after the change;
--    - a garment held in the hand is not counted as worn; the summary follows the jacket coming off; at the end it
--      reads as it did before the run.
--    (Expected to FAIL on 0.3.0-beta11, by the game's bytecode: the layered parts, where ZeD takes the best layer,
--    and the held garment, which InventoryItem:isEquipped() counts.)
-- 2. World window, the Furniture tab (FurnitureTab.lua), with a piece of furniture made from the game's own
--    furniture sprites (one tile, four faces, no tool to move): opening the tab starts the game's cursor; each of
--    the five mode tabs, pressed through the drawer's click handler, switches the game's cursor and is drawn
--    active. Place: YOUR FURNITURE has the piece's row, its button puts it on the cursor, FACING offers four
--    faces, E turns it east, the tab reads it on the target tile as placeable, and the game's place (the cursor's
--    tryBuild, what a click in the world runs) puts it there facing east, out of the inventory. Rotate: the tab
--    reads the placed piece, S picks the south face for that tile, the rotate turns it south. Disassemble: the
--    tab reads the piece, says it cannot be taken apart with its tools set aside and can with them, its tool
--    line red then green. Repair: the tab shows a target and rows exactly when the game has something to repair
--    on the tile. Pick up: ON THIS TILE lists what the game can pick up there, Target puts the piece on the
--    cursor for the tile, the pick-up takes it off the tile into the inventory. Leaving the tab ends the cursor.
-- 3. Container buttons (ContainerControls.lua) between a shelf placed beside you and a duffel bag in your hand,
--    pressed through each list's own click handler (its "cc:" hit zone): the rows carry their buttons; Same type
--    marks and takes only the shelf's nails; your Same type is off with nothing in common, a press on it moves
--    nothing, then it puts only the screws back; Take all empties the shelf into the bag; Transfer all empties
--    the bag onto the shelf; To floor puts the shelf's things on the ground; the floor's own row has no To floor.
-- THE LEDGER: everything given, set aside, placed or changed goes back at the end, and at once on an error: given
-- items and the furniture (and whatever it became) taken away wherever they are (hands, worn, a container, the
-- ground), the shelf removed, the clothes worn again, set-aside tools given back, the hands, god mode, instant
-- actions, the cursor's mode, the construction mark on the furniture's tile, both windows' tabs and containers.
-- The pointer is parked over the World window during the furniture part (the tab holds its tile while the
-- pointer is on a ZeD window), so leave the mouse alone while it runs. Run it after zedqa_pin_windows.lua (the
-- manifest does): an unpinned window rolls up when the pointer leaves it and stops drawing what is read here.
local function say(s) print("ZEDQA cov_equipfurn " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local FT = ZeD.FurnitureTab
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local R = { pass = 0, fail = 0 }
local S = { eq = true, con = false, fur = false, park = false }
local Q = {}
local MARK = "ZeDQA_cov_ef"
local LG = { added = {}, taken = {}, done = false, worn = {}, outfit = {}, objs = {} }
local drive   -- (forward declaration: Q.fatal removes it; Kahlua captures free names when a closure is made)

local function check(ok, what, got, want)
    if ok then
        R.pass = R.pass + 1
        say("PASS " .. what)
    else
        R.fail = R.fail + 1
        say("FAIL " .. what .. " (" .. tostring(got) .. " vs " .. tostring(want) .. ")")
    end
    return ok
end
local function note(s) say("note: " .. tostring(s)) end
local function shot(n)
    local f = "zqa_cov_ef_" .. n .. ".png"
    say("SHOT " .. f)
    pcall(function() getCore():TakeFullScreenshot(f) end)
end

-- ---------------------------------------------------------------------------------------------------------------
-- WINDOWS AND ITEMS
-- ---------------------------------------------------------------------------------------------------------------
function Q.cw() return CWm.getWindow() end
function Q.ww() return WWm.getWindow() end
function Q.cc() local w = Q.cw(); return w and w._mainContent end
function Q.wc() local w = Q.ww(); return w and w._mainContent end

function Q.mark(o) pcall(function() o:getModData()[MARK] = true end) end
function Q.give(ft, cont)
    local it = (cont or p:getInventory()):AddItem(ft)
    if it then Q.mark(it); LG.added[#LG.added + 1] = it end
    return it
end
-- an item out of the game wherever it is: hands, worn, a container, the ground
function Q.drop(it)
    if not it then return end
    pcall(function() p:removeFromHands(it) end)
    pcall(function() if p:isEquippedClothing(it) then p:removeWornItem(it, false) end end)
    pcall(function()
        local c = it:getContainer()
        if c then
            if c:getType() == "floor" then c:DoRemoveItem(it) else c:Remove(it) end
        end
    end)
    pcall(function()
        local wi = it:getWorldItem()
        if wi then
            local sq = wi:getSquare()
            if sq then sq:transmitRemoveItemFromSquare(wi); sq:removeWorldObject(wi) end
            it:setWorldItem(nil)
        end
    end)
end
-- an item of the character's set aside (the ledger gives it back to the container it came from)
function Q.takeOne(it)
    local c = it and it:getContainer()
    if not c then return end
    pcall(function() p:removeFromHands(it) end)
    c:Remove(it)
    LG.taken[#LG.taken + 1] = { item = it, cont = c }
end
function Q.count(inv, ft)
    local n = 0
    local items = inv and inv:getItems()
    for i = 0, (items and items:size() or 0) - 1 do
        if items:get(i):getFullType() == ft then n = n + 1 end
    end
    return n
end
function Q.size(inv) local it = inv and inv:getItems(); return it and it:size() or -1 end

-- a square beside the character for something to stand on: open floor, nothing on it, reachable
function Q.clear(sq, here)
    local ok, good = pcall(function()
        return sq ~= nil and here ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and sq:getVehicleContainer() == nil
            and not sq:HasTree() and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and here:canReachTo(sq)
    end)
    return ok and good
end
function Q.pickSquares()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local here = getCell():getGridSquare(px, py, pz)
    local orth, diag = {}, {}
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }) do
        local sq = getCell():getGridSquare(px + d[1], py + d[2], pz)
        if Q.clear(sq, here) then orth[#orth + 1] = sq end
    end
    for _, d in ipairs({ { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(px + d[1], py + d[2], pz)
        if Q.clear(sq, here) then diag[#diag + 1] = sq end
    end
    S.T = orth[1]                -- the furniture's tile
    S.C = orth[2] or diag[1]     -- the shelf's
    S.O = here                   -- the tile the cursor reads in between (the info is read again on the way back)
end
function Q.sqName(sq) return sq and (sq:getX() .. "," .. sq:getY()) or "none" end

-- ---------------------------------------------------------------------------------------------------------------
-- 1. THE DEFENSE SUMMARY: the script's own model of the worn items
-- ---------------------------------------------------------------------------------------------------------------
function Q.gradeOf(avg)
    -- (the rule as ProtectionTab's comment states it: A at 60+, B 35+, C 15+, D 1+, else F)
    if avg >= 60 then return "A" end
    if avg >= 35 then return "B" end
    if avg >= 15 then return "C" end
    if avg >= 1 then return "D" end
    return "F"
end
function Q.coveredOf(it)
    local list = nil
    pcall(function() list = BloodClothingType.getCoveredParts(it:getScriptItem():getBloodClothingType()) end)
    return list
end
function Q.model()
    local m = { parts = {}, names = {}, garments = 0 }
    local nMax = BloodBodyPartType.MAX:index()
    for i = 0, nMax - 1 do
        local bp = BloodBodyPartType.FromIndex(i)
        local name = tostring(bp)
        m.names[#m.names + 1] = name
        m.parts[name] = { bp = bp, bite = -1, scratch = -1, bullet = -1, layers = 0 }
    end
    m.nParts = #m.names
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:get(i):getItem()
        if it and instanceof(it, "Clothing") then
            local cov = Q.coveredOf(it)
            if cov and cov:size() > 0 then
                m.garments = m.garments + 1
                for j = 0, cov:size() - 1 do
                    local bp = cov:get(j)
                    local ps = m.parts[tostring(bp)]
                    if ps then
                        ps.bite = math.max(ps.bite, math.floor(it:getDefForPart(bp, true, false)))
                        ps.scratch = math.max(ps.scratch, math.floor(it:getDefForPart(bp, false, false)))
                        ps.bullet = math.max(ps.bullet, math.floor(it:getDefForPart(bp, false, true)))
                        ps.layers = ps.layers + 1
                    end
                end
            end
        end
    end
    local sum, worst, best, unc = 0, 999, -1, 0
    for _, name in ipairs(m.names) do
        local b = m.parts[name].bite
        sum = sum + math.max(0, b)
        if b < worst then worst = b end
        if b > best then best = b end
        if m.parts[name].layers == 0 then unc = unc + 1 end
    end
    m.avg = math.floor(sum / m.nParts)
    m.worst, m.best, m.uncovered = worst, best, unc
    return m
end
function Q.ps(t)
    if not t then return "nil" end
    return tostring(t.bite) .. "/" .. tostring(t.scratch) .. "/" .. tostring(t.bullet) .. " x" .. tostring(t.layers)
end
-- ZeD's summary against the model: a list of { what, ok, got, want }
function Q.defDiff(z, m)
    local out = {}
    local function add(what, ok, got, want) out[#out + 1] = { what = what, ok = ok, got = got, want = want } end
    add("garments counted are the worn garments", z.totalGarments == m.garments, z.totalGarments, m.garments)
    add("parts graded are the game's body parts", z.totalParts == m.nParts, z.totalParts, m.nParts)
    local nb, first = 0, nil
    for _, name in ipairs(m.names) do
        local zs, ms = z.partStats and z.partStats[name], m.parts[name]
        local same = zs ~= nil and zs.bite == ms.bite and zs.scratch == ms.scratch and zs.bullet == ms.bullet and zs.layers == ms.layers
        if not same then
            nb = nb + 1
            first = first or (name .. " " .. Q.ps(zs) .. " vs " .. Q.ps(ms))
        end
    end
    add("each part's bite / scratch / bullet / layers is its best worn layer's (" .. m.nParts .. " parts)", nb == 0,
        first and (nb .. " differ, first " .. first) or "all equal", "all equal")
    add("average bite over all parts", z.avgBiteDef == m.avg, z.avgBiteDef, m.avg)
    add("letter grade for that average", z.grade == Q.gradeOf(m.avg), z.grade, Q.gradeOf(m.avg))
    add("uncovered parts listed", #(z.uncoveredParts or {}) == m.uncovered, #(z.uncoveredParts or {}), m.uncovered)
    add("worst part's bite", z.worstPart and z.worstPart.biteDef == m.worst, z.worstPart and z.worstPart.biteDef, m.worst)
    add("best part's bite", z.bestPart and z.bestPart.biteDef == m.best, z.bestPart and z.bestPart.biteDef, m.best)
    return out
end
function Q.defChecks(pre, z, m)
    if not check(z ~= nil, pre .. "the Equip tab has a defense summary", "nil", "a summary") then return end
    for _, d in ipairs(Q.defDiff(z, m)) do check(d.ok, pre .. d.what, d.got, d.want) end
end
-- one line: does the summary follow the worn items (garments, average, grade, every part)?
function Q.defAll(what, z, m)
    if not z then check(false, what, "no summary", "a summary"); return end
    local bad = nil
    for _, d in ipairs(Q.defDiff(z, m)) do
        if not d.ok then bad = bad or (d.what .. ": " .. tostring(d.got) .. " vs " .. tostring(d.want)) end
    end
    check(bad == nil, what, bad or "", "the worn items' numbers")
end
-- ZeD's per-part bite against the game's own (single layers and layered parts apart)
function Q.gameChecks(pre, z, m)
    local n1, n2, b1, b2, d1, d2 = 0, 0, 0, 0, nil, nil
    for _, name in ipairs(m.names) do
        local ms = m.parts[name]
        if ms.layers >= 1 then
            local g = nil
            pcall(function() g = math.floor(p:getBodyPartClothingDefense(ms.bp:index(), true, false)) end)
            local zb = z.partStats and z.partStats[name] and z.partStats[name].bite
            if g ~= nil then
                if ms.layers == 1 then
                    n1 = n1 + 1
                    if zb ~= g then b1 = b1 + 1; d1 = d1 or (name .. " " .. tostring(zb) .. " vs game " .. g) end
                else
                    n2 = n2 + 1
                    if zb ~= g then b2 = b2 + 1; d2 = d2 or (name .. " " .. tostring(zb) .. " vs game " .. g) end
                end
            end
        end
    end
    if n1 > 0 then
        check(b1 == 0, pre .. "single-layer parts show the game's own bite defense (" .. n1 .. " parts)",
            d1 and (b1 .. " differ, first " .. d1) or "equal", "equal")
    else
        note(pre .. "no single-layer part to hold against the game's number")
    end
    if n2 > 0 then
        check(b2 == 0, pre .. "layered parts show the game's own bite defense, which adds the layers up to 100 (" .. n2 .. " parts)",
            d2 and (b2 .. " differ, first " .. d2) or "equal", "equal")
    else
        note(pre .. "no layered part to hold against the game's number")
    end
end
function Q.rowOf(w, it)
    local d = w and w._equipCache
    for _, g in ipairs(d and d.groups or {}) do
        for _, s in ipairs(g.slots or {}) do
            if s.item == it then return s.type end
        end
    end
    return nil
end
-- the clothes that cover a body part come off (not those that give belt or strap slots); everything worn and the
-- hands are written down first
function Q.strip()
    LG.worn = {}
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local w = wi:get(i)
        LG.worn[#LG.worn + 1] = { it = w:getItem(), loc = w:getLocation() }
    end
    pcall(function() p:setPrimaryHandItem(nil) end)
    pcall(function() p:setSecondaryHandItem(nil) end)
    local off, kept = 0, 0
    for _, w in ipairs(LG.worn) do
        local covers, gives = false, false
        pcall(function() covers = instanceof(w.it, "Clothing") and w.it:getCoveredParts():size() > 0 end)
        pcall(function() local ap = w.it:getAttachmentsProvided(); gives = ap ~= nil and ap:size() > 0 end)
        if covers and not gives then
            pcall(function() p:removeWornItem(w.it, false) end)
            w.off = true
            off = off + 1
        elseif covers then
            kept = kept + 1
        end
    end
    LG.stripped = true
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    return off, kept
end
-- the staged clothes off and away, the character's own worn again, the hands back
function Q.unstage()
    for _, it in ipairs(LG.outfit) do Q.drop(it) end
    LG.outfit = {}
    if LG.heldGlove then Q.drop(LG.heldGlove); LG.heldGlove = nil end
    if LG.stripped then
        for _, w in ipairs(LG.worn) do
            local on = false
            pcall(function() on = p:isEquippedClothing(w.it) end)
            if not on and p:getInventory():contains(w.it) then pcall(function() p:setWornItem(w.loc, w.it) end) end
        end
        LG.stripped = false
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    Q.hands()
end
function Q.hands()
    if not LG.handsSet then return end
    local inv = p:getInventory()
    pcall(function() p:setPrimaryHandItem((LG.prim and inv:contains(LG.prim)) and LG.prim or nil) end)
    pcall(function() p:setSecondaryHandItem((LG.sec and inv:contains(LG.sec)) and LG.sec or nil) end)
end

-- ---------------------------------------------------------------------------------------------------------------
-- 2. THE FURNITURE TAB
-- ---------------------------------------------------------------------------------------------------------------
Q.MODE_IDX = { pickup = 1, place = 2, rotate = 3, scrap = 4, repair = 5 }
-- a piece of furniture to move: one tile, an Object with four faces, no tool or skill to move it, not a table or
-- a container; one that can be taken apart (a scrap definition for its material) first, then the lightest
function Q.pieceOk(name)
    local spr = getSprite(name)
    if not spr then return nil end
    local mp = ISMoveableSpriteProps.new(spr)
    if not (mp and mp.isMoveable and mp.sprite) or mp.isMultiSprite or mp.type ~= "Object" or mp.isoType ~= "IsoObject" then return nil end
    if mp.pickUpTool or mp.placeTool or mp.customItem or (mp.pickUpLevel or 0) > 0 then return nil end
    if mp.isTable or mp.isTableTop or mp.isWaterCollector then return nil end
    local isCont = false
    pcall(function() isCont = mp.spriteProps:has(IsoFlagType.container) end)
    if isCont or not mp:hasFaces() then return nil end
    local f = mp:getFaces()
    if not (f.N and f.E and f.S and f.W) then return nil end
    for _, k in ipairs({ "N", "E", "S", "W" }) do
        local fm = ISMoveableSpriteProps.new(f[k])
        if not (fm and fm.isMoveable and fm.sprite) then return nil end
    end
    local defs = ISMoveableDefinitions:getInstance()
    local scrap = (mp.canScrap and mp.material and defs.isScrapDefinitionValid(mp.material)) and true or false
    return { name = name, mp = mp, faces = f, scrap = scrap, weight = mp.weight or 99,
             set = { [f.N] = true, [f.E] = true, [f.S] = true, [f.W] = true } }
end
function Q.pieceSprite()
    local best = nil
    local fams = { { "furniture_seating_indoor_01_", 63 }, { "furniture_seating_indoor_02_", 63 },
                   { "furniture_seating_indoor_03_", 63 }, { "furniture_seating_indoor_04_", 63 },
                   { "furniture_seating_outdoor_01_", 63 }, { "furniture_seating_outdoor_02_", 63 } }
    for _, fam in ipairs(fams) do
        for i = 0, fam[2] do
            local ok, pc = pcall(Q.pieceOk, fam[1] .. i)
            if ok and pc then
                local better = not best or (pc.scrap and not best.scrap) or (pc.scrap == best.scrap and pc.weight < best.weight)
                if better then best = pc end
            end
        end
    end
    return best
end
-- the piece on a tile: the object and its sprite's name
function Q.pieceOn(sq)
    local objs = sq and sq:getObjects()
    for i = 0, (objs and objs:size() or 0) - 1 do
        local o = objs:get(i)
        local nm = nil
        pcall(function() nm = o:getSprite():getName() end)
        if nm and S.piece and S.piece.set[nm] then return o, nm end
    end
    return nil, nil
end
-- the piece's kind carried in the main inventory
function Q.family()
    local out = {}
    local items = p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local ws = nil
        pcall(function() if instanceof(it, "Moveable") then ws = it:getWorldSprite() end end)
        if ws and S.piece and S.piece.set[ws] then out[#out + 1] = it end
    end
    return out
end
-- the same, less what the character carried before the run
function Q.newFamily()
    local out = {}
    for _, it in ipairs(Q.family()) do if not (S.famBase and S.famBase[it]) then out[#out + 1] = it end end
    return out
end
function Q.cur() return FT.cursorOf(pn) end
-- the tab's hold, as the pointer's rest on a tile leaves it: the cursor works on sq while the pointer is on a ZeD window
function Q.hold(sq)
    local cur = Q.cur()
    if not (cur and sq) then return end
    cur._zedHold = { on = true, sq = sq, rest = sq, cur = sq, since = getTimestampMs() }
    S.holdSq = sq
end
-- read the tile again from scratch: off it (the game's info box rebuilds only for a new tile) and back
function Q.reread(sq)
    local cur = Q.cur()
    if not cur then return nil end
    if S.O and S.O ~= sq then Q.hold(S.O); cur:isValid(S.O) end
    Q.hold(sq)
    cur:isValid(sq)
    return FT.cap[pn]
end
function Q.fur() local w = Q.ww(); return w and w._fur end
function Q.zone(id) local s = Q.fur(); return s and s.byId and s.byId[id] end
function Q.zoneCount(prefix)
    local n = 0
    local s = Q.fur()
    for _, z in ipairs(s and s.zones or {}) do
        if type(z.id) == "string" and z.id:sub(1, #prefix) == prefix then n = n + 1 end
    end
    return n
end
-- a press on a zone the tab stamped, through the World window's drawer click handler (as the mouse's)
function Q.clickZone(id)
    local w = Q.ww()
    local z = Q.zone(id)
    if not (w and z and w._drawerPanel) then return false end
    w._drawerPanel:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
function Q.clickMode(m)
    if Q.clickZone("fur:mode:" .. m) then return true end
    -- (a strip too narrow for the five: its arrows bring the tab into view)
    local s = Q.fur()
    local first = s and s.stripFirst or 1
    Q.clickZone((Q.MODE_IDX[m] or 1) < first and "fur:strip:left" or "fur:strip:right")
    return false
end
function Q.faceZones()
    local have = {}
    for _, f in ipairs({ "N", "E", "S", "W" }) do if Q.zone("fur:face:" .. f) then have[#have + 1] = f end end
    return table.concat(have, ",")
end
function Q.overWin(w)
    if not (w and w:getIsVisible()) then return false end
    local mx, my = getMouseX(), getMouseY()
    return mx >= w:getAbsoluteX() and my >= w:getAbsoluteY() and mx < w:getAbsoluteX() + w:getWidth() and my < w:getAbsoluteY() + w:getHeight()
end
-- the pointer parked on the World window's drawer every tick (the tab then keeps the held tile), the hold renewed
function Q.parkTick()
    local w = Q.ww()
    if not w then return end
    if Mouse and Mouse.setXY then
        local dp = w._drawerPanel
        local x, y
        if dp and dp:getWidth() > 20 then
            x = dp:getAbsoluteX() + math.floor(dp:getWidth() / 2)
            y = dp:getAbsoluteY() + math.floor(dp:getHeight() * 0.8)
        else
            x = w:getAbsoluteX() + math.floor(w:getWidth() / 2)
            y = w:getAbsoluteY() + math.floor(w:getHeight() / 2)
        end
        pcall(function() Mouse.setXY(x, y) end)
    end
    local cur = Q.cur()
    if cur and S.holdSq then
        local H = cur._zedHold
        if not (H and H.on and H.sq == S.holdSq) then Q.hold(S.holdSq) end
    end
end
-- the tool lines of the tab's facts (vanilla's "Tool:" lines as ZeD reads them): "ok", "bad", "plain" or "none"
function Q.toolState(c)
    if not (c and c.mp) then return "none" end
    local info = FT.readLines(c)
    local lbl = getText("IGUI_Tool")
    local st = "none"
    for _, f in ipairs(info.facts or {}) do
        if f.label == lbl then
            if f.state == "bad" then return "bad" end
            st = f.state
        end
    end
    return st
end
-- would ZeD's reading of the game's good / bad highlight colours give green / red? (a colour-blind palette may not)
function Q.colorsRead()
    local ok, res = pcall(function()
        local g, b = getCore():getGoodHighlitedColor(), getCore():getBadHighlitedColor()
        local okG = g:getG() > g:getR() + 0.15 and g:getG() > 0.45
        local okB = b:getR() > b:getG() + 0.15 and b:getR() > 0.45
        return okG and okB
    end)
    return ok and res
end
-- the material's scrap tools: all set aside (false when one is on the belt or worn: it stays)
function Q.scrapTools()
    local def = S.piece and ISMoveableDefinitions:getInstance().getScrapDefinition(S.piece.mp.material)
    local t1, t2 = (def and def.tools) or {}, (def and def.tools2) or {}
    return t1, t2
end
function Q.setAsideTools()
    local t1, t2 = Q.scrapTools()
    local clean = true
    for _, list in ipairs({ t1, t2 }) do
        for _, ft in ipairs(list) do
            local found = p:getInventory():getAllTypeRecurse(ft)
            for k = found:size() - 1, 0, -1 do
                local it = found:get(k)
                local stuck = false
                pcall(function() stuck = p:isAttachedItem(it) or p:isEquippedClothing(it) end)
                if stuck then clean = false else Q.takeOne(it) end
            end
        end
    end
    return clean
end
function Q.giveTools()
    local t1, t2 = Q.scrapTools()
    local got = {}
    if t1[1] then local it = Q.give(t1[1]); if it then got[#got + 1] = it:getType() end end
    if t2[1] then local it = Q.give(t2[1]); if it then got[#got + 1] = it:getType() end end
    return table.concat(got, ", ")
end
function Q.haveCons(sq)
    local v = nil
    pcall(function() local z = sq:getZone(); if z then v = z:haveCons() end end)
    return v
end

-- ---------------------------------------------------------------------------------------------------------------
-- 3. THE CONTAINER BUTTONS
-- ---------------------------------------------------------------------------------------------------------------
function Q.shelf(sq)
    for _, name in ipairs({ "furniture_shelving_01_19", "furniture_shelving_01_23", "furniture_shelving_01_27", "furniture_storage_02_16" }) do
        if sq and getSprite(name) then
            local o = IsoObject.new(sq, name, nil, false)
            sq:AddTileObject(o)
            pcall(function() o:createContainersFromSpriteProperties() end)
            if o:getContainer() then
                Q.mark(o)
                LG.objs[#LG.objs + 1] = { obj = o, sq = sq }
                return o, name
            end
            pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        end
    end
    return nil
end
function Q.idxOf(w, inv)
    for i, c in ipairs(w and w._containers or {}) do if c.inventory == inv then return i end end
    return nil
end
function Q.floorIdx(w)
    for i, c in ipairs(w and w._containers or {}) do if c.isFloor then return i end end
    return nil
end
function Q.selectIn(w, inv, idx)
    idx = idx or Q.idxOf(w, inv)
    if not (w and idx) then return false end
    w._activeContainer = idx
    w._viewedContainer = nil
    return true
end
-- the row's button with this id (take, same, floor, xfer, near) and its place in the frame's hits
function Q.hit(content, key)
    local cc = content and content._cc
    for i, h in ipairs(cc and cc.hits or {}) do if h.key == key then return h, i end end
    return nil, nil
end
function Q.keys(content)
    local t = {}
    local cc = content and content._cc
    for _, h in ipairs(cc and cc.hits or {}) do t[#t + 1] = tostring(h.key) end
    return table.concat(t, ",")
end
-- a press on the button through the list's own mouse handler, at the middle of its "cc:<i>" hit zone
function Q.press(content, key)
    local h, idx = Q.hit(content, key)
    if not h then return false, "no " .. key .. " button" end
    local x, y = h.vx + math.floor(h.vw / 2), h.y + math.floor(h.h / 2)
    local z = content:hitZoneAt(x, y)
    if not (z and z.id == "cc:" .. idx) then return false, "the hit zone there is " .. tostring(z and z.id) end
    content:onMouseDown(x, y)
    return true, nil
end
function Q.pressCheck(content, key, what)
    local ok, why = Q.press(content, key)
    if not ok then check(false, what .. ": pressed through the list's click handler", why, "a press") end
    return ok
end
function Q.counts()
    local b, s = S.bagInv, S.shelfInv
    return "bag nails " .. Q.count(b, "Base.Nails") .. " screws " .. Q.count(b, "Base.Screws") .. " pencils " .. Q.count(b, "Base.Pencil")
        .. " | shelf nails " .. Q.count(s, "Base.Nails") .. " screws " .. Q.count(s, "Base.Screws") .. " pencils " .. Q.count(s, "Base.Pencil")
end
function Q.marksOf(content, key)
    local h = Q.hit(content, key)
    local n, kinds, where = 0, {}, true
    for it in pairs(h and h.spec and h.spec.marks or {}) do
        n = n + 1
        kinds[it:getType()] = true
        if it:getContainer() ~= (content == Q.wc() and S.shelfInv or S.bagInv) then where = false end
    end
    local list = {}
    for k in pairs(kinds) do list[#list + 1] = k end
    table.sort(list)
    return n, table.concat(list, ","), where
end
function Q.onGround()
    local n = 0
    for _, it in ipairs(S.conItems or {}) do
        local wi = nil
        pcall(function() wi = it:getWorldItem() end)
        if wi then n = n + 1 end
    end
    return n
end

-- ---------------------------------------------------------------------------------------------------------------
-- PUTTING IT ALL BACK
-- ---------------------------------------------------------------------------------------------------------------
function Q.restoreFurniture()
    S.park, S.holdSq = false, nil
    pcall(function()
        if WWm.isTabShowing("furniture") then WWm.openTab(pn, (LG.wwTab and LG.wwTab ~= "furniture") and LG.wwTab or "loot") end
    end)
    pcall(function() local cur = Q.cur(); if cur then cur._zedHold = nil; cur:exitCursor() end end)
    local gone = 0
    if S.piece and S.T then
        for _ = 1, 4 do
            local o = Q.pieceOn(S.T)
            if not o then break end
            pcall(function() S.T:transmitRemoveItemFromSquare(o) end)
            pcall(function() if Q.pieceOn(S.T) == o then S.T:RemoveTileObject(o) end end)
            gone = gone + 1
        end
        for _, it in ipairs(Q.newFamily()) do Q.drop(it); gone = gone + 1 end
    end
    if S.T and LG.consT ~= nil and Q.haveCons(S.T) ~= LG.consT then
        pcall(function() S.T:getZone():setHaveConstruction(LG.consT) end)
    end
    if LG.modes then
        pcall(function() ISMoveableCursor.mode[pn] = LG.modes.cursor end)
        pcall(function() FT.state.mode = LG.modes.tab or "pickup" end)
        LG.modes = nil
    end
    return gone
end
function Q.restoreContainers()
    for _, it in ipairs(S.conItems or {}) do Q.drop(it) end
    S.conItems = {}
    if S.bag then Q.drop(S.bag); S.bag = nil end
    local n = 0
    for _, o in ipairs(LG.objs) do
        pcall(function() o.sq:transmitRemoveItemFromSquare(o.obj) end)
        pcall(function()
            local objs = o.sq:getObjects()
            for i = 0, objs:size() - 1 do if objs:get(i) == o.obj then o.sq:RemoveTileObject(o.obj); break end end
        end)
        n = n + 1
    end
    LG.objs = {}
    Q.hands()
    -- each window back on the container it showed
    pcall(function()
        local w = Q.ww()
        if w and LG.wwSel then
            local i = LG.wwSel.inv and Q.idxOf(w, LG.wwSel.inv)
            if i then w._activeContainer = i end
            w._viewedContainer, w._mainVisible = LG.wwSel.viewed, LG.wwSel.mainVis
        end
    end)
    pcall(function()
        local w = Q.cw()
        if w and LG.cwSel then
            local i = LG.cwSel.inv and Q.idxOf(w, LG.cwSel.inv)
            w._activeContainer = i or 1
            w._viewedContainer = LG.cwSel.viewed
        end
    end)
    return n
end
function Q.restore(why)
    if LG.done then return end
    LG.done = true
    pcall(function() ISTimedActionQueue.clear(p) end)
    local f = 0
    pcall(function() f = Q.restoreFurniture() end)
    local c = 0
    pcall(function() c = Q.restoreContainers() end)
    pcall(Q.unstage)
    -- the rest of what was given (tools), newest first
    local gone = 0
    for k = #LG.added, 1, -1 do
        local it = LG.added[k]
        local here = false
        pcall(function() here = it:getContainer() ~= nil or it:getWorldItem() ~= nil end)
        if here then Q.drop(it); gone = gone + 1 end
    end
    local back = 0
    for _, t in ipairs(LG.taken) do
        pcall(function() if not t.item:getContainer() then t.cont:AddItem(t.item); back = back + 1 end end)
    end
    Q.hands()
    pcall(function() p:setTimedActionInstantCheat(LG.instant == true) end)
    pcall(function() p:setGodMod(LG.god == true) end)
    -- the windows' tabs as they were (or shut, when the run opened them)
    pcall(function()
        if not LG.cwOpen then
            if CWm.isOpen() then CWm.toggleBothPaired(pn) end
        else
            if LG.cwTab and LG.cwDrawer then CWm.openTab(pn, LG.cwTab) else CWm.openTab(pn, "loot") end
            if LG.wwTab and LG.wwTab ~= "furniture" and LG.wwDrawer then WWm.openTab(pn, LG.wwTab) end
        end
    end)
    pcall(function() if LG.console then LG.console:setVisible(true) end end)
    say("restored (" .. tostring(why) .. "): furniture pieces removed " .. f .. ", shelves removed " .. c .. ", given items taken back "
        .. gone .. ", set-aside items given back " .. back .. " of " .. #LG.taken)
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE PLAN: timed steps, waits (each tick until true or the time is up) and waits that act until true
-- ---------------------------------------------------------------------------------------------------------------
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function waitFor(maxMs, cond, what) plan[#plan + 1] = { wait = true, maxMs = maxMs, cond = cond, what = what } end
local function pollAct(maxMs, act, cond, what) plan[#plan + 1] = { wait = true, maxMs = maxMs, cond = cond, act = act, what = what } end
function Q.finish()
    say("RESULT " .. R.pass .. " pass, " .. R.fail .. " fail")
    say("DONE")
end
function Q.fatal(msg)
    say("ERR " .. tostring(msg))
    pcall(function() Events.OnTick.Remove(drive) end)
    R.fail = R.fail + 1
    Q.restore("an error")
    Q.finish()
end
-- a mode tab pressed until the game's cursor is in that mode, then the strip's state read
function Q.modeStep(m)
    pollAct(4000, function()
        if not S.fur then return end
        if Q.clickMode(m) then S.clickedMode = m end
    end, function() return (not S.fur) or (S.clickedMode == m and ISMoveableCursor.mode[pn] == m) end, "the " .. m .. " tab")
    add(250, function()
        if not S.fur then return end
        local s = Q.fur()
        local got = tostring(ISMoveableCursor.mode[pn]) .. "/" .. tostring(FT.state.mode) .. "/" .. tostring(s and s.stripModeSeen)
        check(S.clickedMode == m and ISMoveableCursor.mode[pn] == m and FT.state.mode == m and s ~= nil and s.stripModeSeen == m,
            "the " .. m .. " tab switches the game's cursor and is drawn active (cursor/tab/drawn)", got, m .. "/" .. m .. "/" .. m)
        Q.hold(S.T)
    end)
end

-- ---- SETUP -----------------------------------------------------------------------------------------------------
add(0, function()
    if ZEDQA_HOME then ZEDQA_HOME("cov_equipfurn") end
    pcall(function()
        local u = UIManager.getUI()
        for k = 0, u:size() - 1 do
            local e = u:get(k)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then LG.console = e; e:setVisible(false) end
        end
    end)
    LG.god = p:isGodMod()
    LG.instant = p:isTimedActionInstantCheat()
    LG.prim, LG.sec, LG.handsSet = p:getPrimaryHandItem(), p:getSecondaryHandItem(), true
    p:setGodMod(true)
    p:setTimedActionInstantCheat(true)
    LG.cwOpen = CWm.isOpen()
    local cw, ww = Q.cw(), Q.ww()
    LG.cwTab, LG.cwDrawer = cw and cw._activeTab, cw and cw._drawerOpen and cw._drawerMode == "tab"
    LG.wwTab, LG.wwDrawer = ww and ww._activeTab, ww and ww._drawerOpen and ww._drawerMode == "tab"
end)
-- (a moment for a move to the drag strip to settle before the tiles beside the character are read)
add(400, function()
    Q.pickSquares()
    say("start: at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. "; furniture tile " .. Q.sqName(S.T)
        .. ", shelf tile " .. Q.sqName(S.C))
end)

-- ---- 1. THE EQUIP TAB'S DEFENSE SUMMARY --------------------------------------------------------------------------
add(100, function() CWm.openTab(pn, "equip") end)
waitFor(5000, function()
    local w = Q.cw()
    return w ~= nil and w._activeTab == "equip" and w._drawerOpen == true and w._drawerMode == "tab" and w._equipProtCache ~= nil
end, "the Equip tab")
add(400, function()
    local w = Q.cw()
    S.eq = check(w ~= nil and w._activeTab == "equip" and w._equipProtCache ~= nil, "the Equip tab opens with its defense summary",
        w and w._activeTab, "equip")
    if not S.eq then return end
    if w.windowShaded then w:setWindowShaded(false) end
    w._equipSelected = nil
    if ZeD.EquipLoadout and ZeD.EquipLoadout.todoOpen and ZeD.EquipLoadout.todoOpen(w) then note("the loadouts' to-do covers the tab") end
    if w._equipDefHidden then note("the tab's Find text hides the defense block on screen (its numbers are still read)") end
    local z = w._equipProtCache
    LG.z0 = { g = z.totalGarments, avg = z.avgBiteDef, grade = z.grade }
    say("before the run: " .. z.totalGarments .. " garments, " .. z.avgBiteDef .. "% grade " .. tostring(z.grade))
    local off, kept = Q.strip()
    say("clothes that cover a part taken off: " .. off .. (kept > 0 and (", " .. kept .. " kept (they give slots)") or ""))
    S.tChange = getTimestampMs()
end)
add(900, function()
    if not S.eq then return end
    local w = Q.cw()
    local z, m = w._equipProtCache, Q.model()
    check((w._equipProtAt or 0) > S.tChange, "the summary refreshed by itself after the clothes came off", w._equipProtAt, "after " .. S.tChange)
    if m.garments > 0 then
        note(m.garments .. " worn garments still cover parts (they give belt slots): the bare checks are left out")
        return
    end
    check(z.totalGarments == 0, "bare: the summary counts 0 garments", z.totalGarments, 0)
    check(z.avgBiteDef == 0 and z.grade == "F", "bare: average 0% and grade F", z.avgBiteDef .. "% " .. tostring(z.grade), "0% F")
    check(#z.uncoveredParts == m.nParts, "bare: every part listed uncovered", #z.uncoveredParts, m.nParts)
    check(z.worstPart.biteDef == -1 and z.bestPart.biteDef == -1, "bare: the worst part reads uncovered and there is no best part",
        z.worstPart.biteDef .. "/" .. z.bestPart.biteDef, "-1/-1")
end)
add(100, function()
    if not S.eq then return end
    local worn = 0
    for _, ft in ipairs({ "Base.Hat_HardHat", "Base.Shirt_Denim", "Base.Jacket_LeatherBlack", "Base.Trousers_Denim",
                          "Base.Gloves_LeatherGloves", "Base.Shoes_WorkBoots" }) do
        local it = Q.give(ft)
        if it then
            pcall(function() p:setWornItem(it:getBodyLocation(), it) end)
            local on = false
            pcall(function() on = p:isEquippedClothing(it) end)
            if on then
                worn = worn + 1
                LG.outfit[#LG.outfit + 1] = it
                if ft == "Base.Jacket_LeatherBlack" then LG.jacket = it end
            else
                note(ft .. " could not be worn")
            end
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say("outfit on: " .. worn .. " of 6")
    S.tChange = getTimestampMs()
end)
add(900, function()
    if not S.eq then return end
    local w = Q.cw()
    local z, m = w._equipProtCache, Q.model()
    check((w._equipProtAt or 0) > S.tChange, "the summary refreshed by itself after the outfit went on", w._equipProtAt, "after " .. S.tChange)
    say(string.format("outfit model: %d garments, average %d%%, grade %s, worst %d, best %d, %d uncovered",
        m.garments, m.avg, Q.gradeOf(m.avg), m.worst, m.best, m.uncovered))
    Q.defChecks("outfit: ", z, m)
    Q.gameChecks("outfit: ", z, m)
    local missing = {}
    for _, it in ipairs(LG.outfit) do if not Q.rowOf(w, it) then missing[#missing + 1] = it:getType() end end
    check(#LG.outfit > 0 and #missing == 0, "the Equip list has a row for every garment worn", table.concat(missing, ","), "none missing")
    shot("1_defense")
end)
add(100, function()
    if not S.eq then return end
    LG.heldGlove = Q.give("Base.Gloves_LeatherGloves")
    if LG.heldGlove then p:setPrimaryHandItem(LG.heldGlove) end
    S.tChange = getTimestampMs()
end)
add(900, function()
    if not S.eq then return end
    local z, m = Q.cw()._equipProtCache, Q.model()
    check(z.totalGarments == m.garments, "a garment held in the hand is not counted as worn", z.totalGarments, m.garments)
    pcall(function() p:setPrimaryHandItem(nil) end)
    Q.drop(LG.heldGlove)
    LG.heldGlove = nil
end)
add(100, function()
    if not (S.eq and LG.jacket) then return end
    pcall(function() p:removeWornItem(LG.jacket, false) end)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
end)
add(900, function()
    if not (S.eq and LG.jacket) then return end
    Q.defAll("the summary follows the jacket coming off (garments, average, grade, every part)", Q.cw()._equipProtCache, Q.model())
end)
add(100, function()
    if not S.eq then return end
    Q.unstage()
end)
add(900, function()
    if not (S.eq and LG.z0) then return end
    local z = Q.cw()._equipProtCache
    check(z.totalGarments == LG.z0.g and z.avgBiteDef == LG.z0.avg and z.grade == LG.z0.grade,
        "put back: the summary reads as it did before the run",
        z.totalGarments .. " / " .. z.avgBiteDef .. "% " .. tostring(z.grade), LG.z0.g .. " / " .. LG.z0.avg .. "% " .. tostring(LG.z0.grade))
end)

-- ---- 2. THE CONTAINER BUTTONS ------------------------------------------------------------------------------------
add(100, function()
    CWm.openTab(pn, "loot")
    WWm.openTab(pn, "loot")
end)
add(500, function()
    local cw, ww = Q.cw(), Q.ww()
    if not (cw and ww and S.C) then
        check(false, "containers: both windows open and a free tile beside you for the shelf", Q.sqName(S.C), "a tile")
        return
    end
    LG.wwSel = { inv = ww._containers and ww._containers[ww._activeContainer] and ww._containers[ww._activeContainer].inventory,
                 viewed = ww._viewedContainer, mainVis = ww._mainVisible }
    LG.cwSel = { inv = cw._containers and cw._containers[cw._activeContainer] and cw._containers[cw._activeContainer].inventory,
                 viewed = cw._viewedContainer }
    if #(ww._mcSelected or {}) > 0 or #(cw._mcSelected or {}) > 0 then note("a window shows several containers side by side: its row is off there") end
    local o = Q.shelf(S.C)
    if not o then check(false, "containers: a shelf placed beside you", "none", "a shelf"); return end
    S.shelfInv = o:getContainer()
    pcall(function() S.shelfInv:removeAllItems() end)
    S.bag = Q.give("Base.Bag_DuffelBag")
    S.bagInv = S.bag and S.bag:getItemContainer()
    if not S.bagInv then check(false, "containers: a duffel bag to hold", "none", "a bag"); return end
    p:setSecondaryHandItem(S.bag)
    S.conItems = {}
    local function put(inv, ft, n)
        for _ = 1, n do local it = Q.give(ft, inv); if it then S.conItems[#S.conItems + 1] = it end end
    end
    put(S.shelfInv, "Base.Nails", 3); put(S.shelfInv, "Base.Screws", 2)
    put(S.bagInv, "Base.Nails", 2); put(S.bagInv, "Base.Pencil", 1)
    ww._containerTimer = 30
    cw._containerTimer = 30
    S.con = true
end)
waitFor(5000, function()
    return not S.con or (Q.idxOf(Q.ww(), S.shelfInv) ~= nil and Q.idxOf(Q.cw(), S.bagInv) ~= nil)
end, "the shelf and the bag in the windows' lists")
add(100, function()
    if not S.con then return end
    local a = Q.selectIn(Q.ww(), S.shelfInv)
    local b = Q.selectIn(Q.cw(), S.bagInv)
    if not (a and b) then
        check(false, "containers: the shelf and the bag are listed", tostring(a) .. "/" .. tostring(b), "true/true")
        S.con = false
    end
end)
add(700, function()
    if not S.con then return end
    local wc, cc = Q.wc(), Q.cc()
    check(wc._inventory == S.shelfInv and wc._ccEntry ~= nil, "the World list shows the shelf with its button row", tostring(wc._inventory == S.shelfInv), "true")
    check(cc._inventory == S.bagInv and cc._ccEntry ~= nil, "the Character list shows the bag with its button row", tostring(cc._inventory == S.bagInv), "true")
    local wk, ck = Q.keys(wc), Q.keys(cc)
    check(Q.hit(wc, "take") ~= nil and Q.hit(wc, "same") ~= nil and Q.hit(wc, "floor") ~= nil,
        "the World row has Take all, Same type and To floor", wk, "take,same,floor,...")
    check(Q.hit(cc, "xfer") ~= nil and Q.hit(cc, "same") ~= nil, "your row has Transfer all and Same type", ck, "xfer,same,...")
    say("start: " .. Q.counts())
    shot("2_rows")
    local n, kinds, where = Q.marksOf(wc, "same")
    local h = Q.hit(wc, "same")
    check(h and h.spec and h.spec.enabled and n == 3 and kinds == "Nails" and where,
        "Same type marks the shelf's 3 nails and nothing else", n .. " " .. kinds .. (where and "" or " (not all on the shelf)"), "3 Nails")
    Q.pressCheck(wc, "same", "Same type (World)")
end)
waitFor(6000, function() return not S.con or Q.count(S.bagInv, "Base.Nails") == 5 end, "the nails in the bag")
add(300, function()
    if not S.con then return end
    local c = Q.counts()
    check(Q.count(S.bagInv, "Base.Nails") == 5 and Q.count(S.shelfInv, "Base.Nails") == 0 and Q.count(S.shelfInv, "Base.Screws") == 2
        and Q.count(S.bagInv, "Base.Pencil") == 1, "Same type took the 3 nails into the bag and left the screws", c,
        "bag nails 5 pencils 1, shelf nails 0 screws 2")
end)
add(400, function()
    if not S.con then return end
    local cc = Q.cc()
    local h = Q.hit(cc, "same")
    check(h ~= nil and h.spec ~= nil and h.spec.enabled == false, "your Same type is off with no kind both sides hold",
        h and h.spec and tostring(h.spec.enabled), "false")
    S.snap = Q.counts()
    Q.press(cc, "same")
end)
add(600, function()
    if not S.con then return end
    check(Q.counts() == S.snap, "a press on the off button moves nothing", Q.counts(), S.snap)
    local it = Q.give("Base.Screws", S.bagInv)
    if it then S.conItems[#S.conItems + 1] = it end
end)
add(700, function()
    if not S.con then return end
    local cc = Q.cc()
    local n, kinds, where = Q.marksOf(cc, "same")
    local h = Q.hit(cc, "same")
    check(h and h.spec and h.spec.enabled and n == 1 and kinds == "Screws" and where,
        "with a screw in the bag your Same type marks that screw only", n .. " " .. kinds, "1 Screws")
    Q.pressCheck(cc, "same", "Same type (yours)")
end)
waitFor(6000, function() return not S.con or Q.count(S.shelfInv, "Base.Screws") == 3 end, "the screw on the shelf")
add(300, function()
    if not S.con then return end
    check(Q.count(S.shelfInv, "Base.Screws") == 3 and Q.count(S.bagInv, "Base.Screws") == 0 and Q.count(S.bagInv, "Base.Nails") == 5,
        "your Same type put the screw on the shelf and kept the nails", Q.counts(), "shelf screws 3, bag screws 0 nails 5")
    Q.pressCheck(Q.wc(), "take", "Take all")
end)
waitFor(6000, function() return not S.con or Q.size(S.shelfInv) == 0 end, "the shelf emptied")
add(300, function()
    if not S.con then return end
    check(Q.size(S.shelfInv) == 0 and Q.count(S.bagInv, "Base.Nails") == 5 and Q.count(S.bagInv, "Base.Screws") == 3
        and Q.count(S.bagInv, "Base.Pencil") == 1 and Q.size(S.bagInv) == 9,
        "Take all moved everything on the shelf into the bag", Q.counts() .. " | bag " .. Q.size(S.bagInv), "shelf empty, bag 9")
    shot("3_take_all")
    Q.pressCheck(Q.cc(), "xfer", "Transfer all")
end)
waitFor(6000, function() return not S.con or Q.size(S.bagInv) == 0 end, "the bag emptied")
add(300, function()
    if not S.con then return end
    check(Q.size(S.bagInv) == 0 and Q.size(S.shelfInv) == 9 and Q.count(S.shelfInv, "Base.Nails") == 5,
        "Transfer all moved everything in the bag onto the shelf", Q.counts() .. " | shelf " .. Q.size(S.shelfInv), "bag empty, shelf 9")
    Q.pressCheck(Q.wc(), "floor", "To floor")
end)
waitFor(8000, function() return not S.con or (Q.size(S.shelfInv) == 0 and Q.onGround() == 9) end, "the things on the ground")
add(300, function()
    if not S.con then return end
    check(Q.size(S.shelfInv) == 0 and Q.onGround() == 9, "To floor put the shelf's 9 things on the ground",
        "shelf " .. Q.size(S.shelfInv) .. ", on the ground " .. Q.onGround(), "shelf 0, on the ground 9")
    local w = Q.ww()
    local fi = Q.floorIdx(w)
    if fi then Q.selectIn(w, nil, fi) end
end)
add(700, function()
    if not S.con then return end
    local wc = Q.wc()
    local onFloor = wc._inventory and wc._inventory:getType() == "floor"
    check(onFloor and Q.hit(wc, "floor") == nil and Q.hit(wc, "take") ~= nil, "the floor's own row has Take all and no To floor",
        tostring(onFloor) .. " " .. Q.keys(wc), "true, no floor")
    local n = Q.restoreContainers()
    say("containers put back: shelves removed " .. n)
    S.con = false
end)

-- ---- 3. THE FURNITURE TAB ----------------------------------------------------------------------------------------
add(300, function()
    if not S.T then check(false, "furniture: a free tile beside you", "none", "a tile"); return end
    S.piece = Q.pieceSprite()
    if not check(S.piece ~= nil, "furniture: a one-tile piece with four faces the game moves without tools", "none", "a sprite") then return end
    say("furniture piece " .. S.piece.name .. " (" .. tostring(S.piece.mp.name) .. ", " .. tostring(S.piece.mp.weight) .. " kg, faces N "
        .. S.piece.faces.N .. " E " .. S.piece.faces.E .. " S " .. S.piece.faces.S .. " W " .. S.piece.faces.W
        .. (S.piece.scrap and ", can be taken apart" or "") .. ")")
    S.famBase = {}
    for _, it in ipairs(Q.family()) do S.famBase[it] = true end
    local it = S.piece.mp:instanceItem(S.piece.name)
    if not it then
        it = instanceItem("Moveables.Moveable")
        if it and not it:ReadFromWorldSprite(S.piece.name) then it = nil end
    end
    if not check(it ~= nil, "furniture: the piece made as an item to carry", "nil", "an item") then return end
    p:getInventory():AddItem(it)
    Q.mark(it)
    LG.added[#LG.added + 1] = it
    S.pieceItem = it
    LG.consT = Q.haveCons(S.T)
    LG.modes = { cursor = ISMoveableCursor.mode[pn], tab = FT.state.mode }
    S.fur = true
    WWm.openTab(pn, "furniture")
end)
waitFor(5000, function() return not S.fur or (WWm.isTabShowing("furniture") and Q.cur() ~= nil) end, "the Furniture tab and its cursor")
add(300, function()
    if not S.fur then return end
    S.park = true
    check(WWm.isTabShowing("furniture") and Q.cur() ~= nil and FT.state.active == true, "opening the Furniture tab starts the game's furniture cursor",
        tostring(WWm.isTabShowing("furniture")) .. "/" .. tostring(Q.cur() ~= nil) .. "/" .. tostring(FT.state.active), "true/true/true")
    check(ISMoveableCursor.mode[pn] == FT.state.mode, "the tab's mode is the cursor's", ISMoveableCursor.mode[pn], FT.state.mode)
    Q.hold(S.T)
end)
add(300, function()
    if not S.fur then return end
    local w = Q.ww()
    if not (Mouse and Mouse.setXY) then note("the pointer cannot be parked here (no Mouse.setXY): the tab's reads may wander")
    elseif not Q.overWin(w) then note("the pointer is not over the World window after parking it (" .. getMouseX() .. "," .. getMouseY() .. ")") end
end)

-- Place
Q.modeStep("place")
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    local list = cur and (cur.objectListCache or cur:getInventoryObjectList()) or {}
    local k = nil
    for n, e in ipairs(type(list) == "table" and list or {}) do if e.object == S.pieceItem then k = n end end
    local rows = Q.zoneCount("fur:inv:")
    check(k ~= nil and Q.zone("fur:inv:" .. tostring(k)) ~= nil, "Place: YOUR FURNITURE has a row for the carried piece", k and ("row " .. k) or "no row", "a row")
    if #list <= 3 then
        check(rows == #list, "Place: YOUR FURNITURE shows every piece the game can place from your inventory", rows, #list)
    end
    if k then Q.clickZone("fur:inv:" .. k) end
    check(cur ~= nil and k ~= nil and cur.objectIndex == k, "Place: the row's button puts the piece on the cursor", cur and cur.objectIndex, k)
    Q.hold(S.T)
end)
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then check(false, "Place: the cursor is still up", "nil", "a cursor"); return end
    check(Q.faceZones() == "N,E,S,W", "Place: FACING offers the piece's four faces", Q.faceZones(), "N,E,S,W")
    Q.hold(S.T)
    Q.clickZone("fur:face:E")
    check(cur.cursorFacing == 4, "Place: the E button turns the piece on the cursor east", cur.cursorFacing, 4)
    cur:isValid(S.T)
    local c = FT.cap[pn]
    check(c ~= nil and c.mp ~= nil and c.mp.spriteName == S.piece.faces.E and c.sq == S.T,
        "Place: the tab reads the piece facing east on the target tile", c and c.mp and c.mp.spriteName, S.piece.faces.E)
    check(c ~= nil and c.canCreate == true, "Place: the tab says it can go there", c and tostring(c.canCreate), "true")
    cur:tryBuild(S.T:getX(), S.T:getY(), S.T:getZ())
end)
waitFor(8000, function() return not S.fur or Q.pieceOn(S.T) ~= nil end, "the piece on its tile")
add(300, function()
    if not S.fur then return end
    local _, sp = Q.pieceOn(S.T)
    check(sp == S.piece.faces.E, "Place put the piece on the tile facing east", sp, S.piece.faces.E)
    check(not p:getInventory():contains(S.pieceItem), "Place: the piece left your inventory", tostring(p:getInventory():contains(S.pieceItem)), "false")
    if not sp then
        -- (the modes after Place read a piece on the tile: one is set there directly so their checks still run)
        pcall(function() local o = IsoObject.new(getCell(), S.T, S.piece.faces.E); S.T:AddTileObject(o) end)
        Q.drop(S.pieceItem)
        note("the piece was set on its tile directly for the checks after Place")
    end
    shot("4_placed")
end)

-- Rotate
Q.modeStep("rotate")
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then check(false, "Rotate: the cursor is still up", "nil", "a cursor"); return end
    Q.hold(S.T)
    cur:isValid(S.T)
    local c = FT.cap[pn]
    check(c ~= nil and c.mp ~= nil and c.mp.spriteName == S.piece.faces.E and c.sq == S.T, "Rotate: the tab reads the placed piece (facing east)",
        c and c.mp and c.mp.spriteName, S.piece.faces.E)
    check(Q.faceZones() == "N,E,S,W", "Rotate: FACING offers the piece's four faces", Q.faceZones(), "N,E,S,W")
    Q.clickZone("fur:face:S")
    local pk = FT.pick
    check(pk ~= nil and pk.sq == S.T and pk.idx == 3 and cur.objectIndex == 3, "Rotate: the S button picks the south face for this tile",
        tostring(pk and pk.idx) .. " on " .. Q.sqName(pk and pk.sq) .. ", cursor " .. tostring(cur.objectIndex), "3 on " .. Q.sqName(S.T) .. ", cursor 3")
    Q.hold(S.T)
    cur:isValid(S.T)
    c = FT.cap[pn]
    check(c ~= nil and c.mp ~= nil and c.mp.spriteName == S.piece.faces.S and c.canCreate == true, "Rotate: the tab shows the piece turned south, ready",
        tostring(c and c.mp and c.mp.spriteName) .. " " .. tostring(c and c.canCreate), S.piece.faces.S .. " true")
    cur:tryBuild(S.T:getX(), S.T:getY(), S.T:getZ())
end)
waitFor(8000, function() if not S.fur then return true end; local _, sp = Q.pieceOn(S.T); return sp == S.piece.faces.S end, "the piece turned")
add(300, function()
    if not S.fur then return end
    local _, sp = Q.pieceOn(S.T)
    check(sp == S.piece.faces.S, "Rotate turned the piece south on its tile", sp, S.piece.faces.S)
    check(#Q.newFamily() == 0, "Rotate: nothing of the piece is left in your inventory", #Q.newFamily(), 0)
end)

-- Disassemble (read only: nothing is taken apart)
Q.modeStep("scrap")
add(100, function()
    if not S.fur then return end
    local t1 = Q.scrapTools()
    S.scrapTools = S.piece.scrap and S.piece.mp.scrapUseTool and #t1 > 0
    if S.scrapTools then
        S.toolsClean = Q.setAsideTools()
        if not S.toolsClean then note("a scrap tool is on your belt or worn: the no-tool check is left out") end
    end
end)
add(400, function()
    if not S.fur then return end
    local c = Q.reread(S.T)
    if not S.piece.scrap then
        note("the piece's material has no scrap definition: Disassemble is left out")
        return
    end
    local _, onTile = Q.pieceOn(S.T)
    check(c ~= nil and c.mp ~= nil and onTile ~= nil and c.mp.spriteName == onTile and c.sq == S.T, "Disassemble: the tab reads the piece on the tile",
        c and c.mp and c.mp.spriteName, onTile)
    if S.scrapTools and S.toolsClean then
        check(c ~= nil and c.canCreate == false, "Disassemble: with its tools set aside the tab says it cannot be taken apart",
            c and tostring(c.canCreate), "false")
        if Q.colorsRead() then
            check(Q.toolState(c) == "bad", "Disassemble: the tool line reads red without the tools", Q.toolState(c), "bad")
        end
    end
    if S.scrapTools then say("tools given: " .. Q.giveTools()) end
end)
add(400, function()
    if not (S.fur and S.piece.scrap) then return end
    local c = Q.reread(S.T)
    check(c ~= nil and c.canCreate == true, "Disassemble: with the tools in your inventory the tab says it can be taken apart",
        c and tostring(c.canCreate), "true")
    if S.scrapTools and Q.colorsRead() then
        check(Q.toolState(c) == "ok", "Disassemble: the tool line reads green with the tools", Q.toolState(c), "ok")
    end
end)

-- Repair (read only)
Q.modeStep("repair")
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    local c = Q.reread(S.T)
    local list = cur and cur.objectListCache
    local n = type(list) == "table" and #list or 0
    S.repairN = n
    check((n > 0) == (c ~= nil and c.mp ~= nil), "Repair: the tab shows a target exactly when the game has something to repair on the tile",
        tostring(c and c.mp ~= nil) .. " with " .. n .. " repairable", tostring(n > 0))
    if n > 0 and c and c.mp then
        local e = list[cur.objectIndex] or list[1]
        check(e and e.moveProps and c.mp.spriteName == e.moveProps.spriteName, "Repair: the target is the game's pick on the tile",
            c.mp.spriteName, e and e.moveProps and e.moveProps.spriteName)
    end
end)
add(300, function()
    if not S.fur then return end
    check(Q.zoneCount("fur:obj:") == (S.repairN or 0), "Repair: ON THIS TILE lists what the game would repair there",
        Q.zoneCount("fur:obj:"), S.repairN or 0)
end)

-- Pick up
Q.modeStep("pickup")
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then check(false, "Pick up: the cursor is still up", "nil", "a cursor"); return end
    Q.hold(S.T)
    cur:isValid(S.T)
    local list = cur.objectListCache
    local n = type(list) == "table" and #list or 0
    local obj = Q.pieceOn(S.T)
    local k = nil
    for q, e in ipairs(n > 0 and list or {}) do if obj ~= nil and e.object == obj then k = q end end
    S.pickN, S.pickK = n, k
    check(k ~= nil, "Pick up: the game lists the piece on the tile", tostring(n) .. " listed", "the piece among them")
end)
add(300, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then return end
    check((S.pickN or 0) > 0 and Q.zoneCount("fur:obj:") == S.pickN, "Pick up: ON THIS TILE has a row for everything the game can pick up there",
        Q.zoneCount("fur:obj:"), S.pickN)
    local k = S.pickK
    if k then Q.clickZone("fur:obj:" .. k) end
    local pk = FT.pick
    check(k ~= nil and cur.objectIndex == k and pk ~= nil and pk.sq == S.T, "Pick up: Target puts the piece on the cursor for this tile",
        tostring(cur.objectIndex) .. " on " .. Q.sqName(pk and pk.sq), tostring(k) .. " on " .. Q.sqName(S.T))
    Q.hold(S.T)
    cur:isValid(S.T)
    local c = FT.cap[pn]
    local _, onTile = Q.pieceOn(S.T)
    check(c ~= nil and c.mp ~= nil and onTile ~= nil and c.mp.spriteName == onTile and c.canCreate == true, "Pick up: the tab reads the piece, ready to pick up",
        tostring(c and c.mp and c.mp.spriteName) .. " " .. tostring(c and c.canCreate), tostring(onTile) .. " true")
    cur:tryBuild(S.T:getX(), S.T:getY(), S.T:getZ())
end)
waitFor(8000, function() return not S.fur or (Q.pieceOn(S.T) == nil and #Q.newFamily() > 0) end, "the piece in your inventory")
add(300, function()
    if not S.fur then return end
    check(Q.pieceOn(S.T) == nil, "Pick up took the piece off its tile", tostring(Q.pieceOn(S.T) ~= nil), "false")
    check(#Q.newFamily() == 1, "Pick up: the piece came back into your inventory", #Q.newFamily(), 1)
end)

-- leaving the tab
add(100, function()
    if not S.fur then return end
    S.park, S.holdSq = false, nil
    WWm.openTab(pn, "loot")
end)
waitFor(4000, function() return not S.fur or not WWm.isTabShowing("furniture") end, "the Loot view")
add(400, function()
    if not S.fur then return end
    check(Q.cur() == nil and FT.state.active ~= true, "leaving the Furniture tab ends the game's furniture cursor",
        tostring(Q.cur() ~= nil) .. "/" .. tostring(FT.state.active), "false/false")
    local n = Q.restoreFurniture()
    say("furniture put back: " .. n .. " removed")
    S.fur = false
end)

-- ---- THE END: everything put back --------------------------------------------------------------------------------
add(300, function()
    Q.restore("the end")
    Q.finish()
end)

drive = function()
    if S.park then pcall(Q.parkTick) end
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    local now = getTimestampMs()
    if st.wait then
        st.tEnd = st.tEnd or (now + st.maxMs)
        local ok, done = pcall(st.cond)
        if not ok then Q.fatal("wait " .. i .. " (" .. tostring(st.what) .. "): " .. tostring(done)); return end
        if done then i = i + 1; t0 = now; return end
        if now > st.tEnd then note("gave up waiting for " .. tostring(st.what)); i = i + 1; t0 = now; return end
        if st.act and now >= (st.nextAct or 0) then
            st.nextAct = now + 150
            local ok2, e2 = pcall(st.act)
            if not ok2 then Q.fatal("wait " .. i .. " (" .. tostring(st.what) .. "): " .. tostring(e2)) end
        end
        return
    end
    if now - t0 < st.ms then return end
    t0 = now
    i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then Q.fatal("step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
