-- ZeDUI/tools/qa/zedqa_cov_equipfurn.lua  (Nov 12 2026, QA coverage: audit Table B, group "equipfurn")
-- In game on the ZeD-QA save only (Saves/Sandbox/ZeD-QA; on any other save it prints an ERR line and touches
-- nothing), at the QA home (the Irvington drag strip, 925,13040). Copy to Zomboid/Lua/zedqa.lua and bump zedqa.go,
-- or run cov_equipfurn.txt with zedqa_run.ps1 -Manifest; grep console.txt for "ZEDQA cov_equipfurn". Every check
-- prints "PASS <what>" or "FAIL <what> (<got> vs <want>)", read from ZeD's own objects. A check named
-- "presence: ..." only shows that something is there; what it does is checked by the lines after it. A part that
-- cannot run says FAIL with the reason, never a silent skip. The run ends with RESULT and DONE. Captures:
-- Screenshots/zqa_cov_ef_*.png, each announced by a SHOT line.
--
-- WHAT IT CHECKS
-- 1. Equip tab, the defense summary (EquipmentTab.lua's defense dashboard, ProtectionTab.gatherData). Read from
--    the window's own model (win._equipProtCache, what the dashboard draws), built again before the first read (an
--    item card or the loadouts' to-do can leave an old one), against a model this script builds from the worn items
--    by the game's own rule (IsoGameCharacter.getBodyPartClothingDefense in 42.22: each worn garment over a part,
--    with no hole there, adds its Clothing.getDefForPart; the total stops at 100; this is what vanilla's protection
--    panel shows and what a bite rolls against), and against that game number itself:
--    - bare (the clothes that cover parts taken off): 0 garments, 0%, grade F, every part uncovered, no best part;
--    - a staged outfit (hard hat, denim shirt under a leather jacket, jeans, leather gloves, work boots): the
--      summary followed the change by itself (no refresh called), the script's model is the game's number on every
--      part, then the garments, each part's bite / scratch / bullet (the layers added) and layer count, the average,
--      its grade, the uncovered count, the worst and best part; single-layer and layered parts against the game's
--      number; the Equip list has a row for every garment (presence);
--    - a garment held in the hand is not counted as worn; the summary follows the jacket coming off; at the end it
--      reads as it did before the run.
--    Whole numbers: ZeD's may be the game's total rounded down or to nearest, or its layers each rounded down and
--    added, so each comparison takes that range (the staged clothes have whole numbers: it is exact here).
--    Expected to FAIL on 0.3.0-beta11 (the game's bytecode): the layered parts (ZeD keeps the best layer; the game
--    adds them), so the per-part line, the average and "layered parts" fail; and the held garment, which
--    InventoryItem:isEquipped() counts. A fixed ZeD reads all PASS.
-- 2. Container buttons (ContainerControls.lua) between a shelf placed beside you (marked explored at once, so the
--    World window does not fill it with the game's loot) and a duffel bag in your hand, pressed through each list's
--    own click handler (its "cc:" hit zone): the rows carry their buttons (presence); the shelf holds only what was
--    put on it; Same type marks and takes only the shelf's nails; your Same type is off with nothing in common, and
--    a press on it while it is drawn off does nothing even with a screw just put in the bag; then it marks and puts
--    only that screw back; Take all empties the shelf into the bag; Transfer all empties the bag onto the shelf; To
--    floor puts the shelf's things on the ground; the floor's own row has Take all and no To floor (presence).
-- 3. World window, the Furniture tab (FurnitureTab.lua), with a piece of furniture made from the game's own
--    furniture sprites (one tile, four faces, no tool to move): opening the tab starts the game's cursor in the
--    tab's own mode (staged as Rotate while the game's last mode is Pick up); each of the five mode tabs, pressed
--    through the drawer's click handler, switches the game's cursor and is drawn active. Place: YOUR FURNITURE has
--    the piece's row (presence), its button puts it on the cursor, FACING offers four faces (presence), E turns it
--    east, the tab reads it on the target tile as placeable, and the game's place (the cursor's tryBuild, what a
--    click in the world runs) puts it there facing east, out of the inventory. Rotate: the tab reads the placed
--    piece, S picks the south face for that tile, the rotate turns it south. Disassemble (the game's furniture
--    cheats off for it): the tab reads the piece, says it cannot be taken apart with its tools set aside (a tool on
--    the belt comes off the belt for it) and can with them, its tool line red then green. Repair: a damaged wooden
--    piece set beside you (one the game's own repair list takes): the tab shows the game's target there, ON THIS
--    TILE has its row (presence) and Target picks it for that tile; then on the furniture's tile, where the game
--    repairs nothing, the target and the rows are gone. Pick up: ON THIS TILE lists what the game can pick up there
--    (presence), Target puts the piece on the cursor for the tile, the pick-up takes it off the tile into the
--    inventory. Leaving the tab ends the cursor.
-- THE LEDGER: everything given, set aside, placed or changed goes back at the end, and at once on an error: given
-- items and the furniture (and whatever it became) taken away wherever they are (hands, worn, a container, the
-- ground), the shelf and the repair piece removed, anything left in the run's shelf or bag, the clothes worn again,
-- set-aside tools given back (a belt tool onto its belt slot), the hands, god mode, instant actions, the furniture
-- cheats, the cursor's and the tab's modes, the tab's pick and last read, the construction mark on the furniture's
-- tile, the Equip tab's item card and to-do, a window rolled up by hand, both windows' tabs and containers, the
-- pointer. The pointer is parked over the World window during the furniture part (the tab holds its tile while the
-- pointer is on a ZeD window), so leave the mouse alone while it runs. Run it after zedqa_pin_windows.lua (the
-- manifest does): an unpinned window rolls up when the pointer leaves it and stops drawing what is read here.
local function say(s) print("ZEDQA cov_equipfurn " .. tostring(s)) end

-- only the QA save, and only with ZeD's windows loaded: anything else is left untouched
do
    local wn = nil
    pcall(function() wn = getWorld():getWorld() end)
    local why = nil
    if wn ~= "ZeD-QA" then why = "not the ZeD-QA save (" .. tostring(wn) .. ")"
    elseif not getPlayer() then why = "no player"
    elseif not (ZeD and ZeD.FurnitureTab and ZeD.ProtectionTab and ZeD_CharacterWindow and ZeD_WorldWindow) then why = "a ZeD module is missing" end
    if why then
        say("ERR " .. why .. ": nothing touched")
        say("RESULT 0 pass, 0 fail")
        say("DONE")
        return
    end
end
-- a run before this one that never finished: its ticks stop and its changes come off first
if type(ZEDQA_COV_EF) == "table" and ZEDQA_COV_EF.abort then pcall(ZEDQA_COV_EF.abort, "a run before this one") end

local p = getPlayer()
local pn = p:getPlayerNum()
local FT = ZeD.FurnitureTab
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local R = { pass = 0, fail = 0 }
local S = { eq = true, con = false, fur = false, park = false }
local Q = {}
local MARK = "ZeDQA_cov_ef"
local LG = { added = {}, taken = {}, done = false, worn = {}, outfit = {}, objs = {}, fobjs = {} }
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
local function inWin(v, lo, hi) return type(v) == "number" and v >= lo and v <= hi end

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
-- an object off its square (the single-player path of transmitRemoveItemFromSquare is RemoveTileObject)
function Q.removeObj(sq, o)
    if not (sq and o) then return end
    pcall(function() sq:transmitRemoveItemFromSquare(o) end)
    pcall(function()
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do if objs:get(i) == o then sq:RemoveTileObject(o); break end end
    end)
end
-- an item of the character's set aside (the ledger gives it back to the container it came from, and a belt tool
-- back onto its belt slot: the hotbar's own way without the animation, ISHotbar.attachItem / removeItem)
function Q.takeOne(it)
    local c = it and it:getContainer()
    if not c then return end
    local rec = { item = it, cont = c }
    pcall(function()
        if p:isAttachedItem(it) then
            rec.slot, rec.slotType, rec.model = it:getAttachedSlot(), it:getAttachedSlotType(), it:getAttachedToModel()
            p:removeAttachedItem(it)
            it:setAttachedSlot(-1)
            it:setAttachedSlotType(nil)
            it:setAttachedToModel(nil)
        end
    end)
    pcall(function() p:removeFromHands(it) end)
    c:Remove(it)
    LG.taken[#LG.taken + 1] = rec
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
    -- the repair piece's: the next free one
    local rest = {}
    for k = 3, #orth do rest[#rest + 1] = orth[k] end
    for _, sq in ipairs(diag) do rest[#rest + 1] = sq end
    for _, sq in ipairs(rest) do if sq ~= S.C and not S.R then S.R = sq end end
end
function Q.sqName(sq) return sq and (sq:getX() .. "," .. sq:getY()) or "none" end

-- ---------------------------------------------------------------------------------------------------------------
-- 1. THE DEFENSE SUMMARY: the script's own model of the worn items, by the game's rule
-- ---------------------------------------------------------------------------------------------------------------
-- the three numbers of a part, as Clothing.getDefForPart's flags (bite, bullet)
Q.KINDS = { { "bite", true, false }, { "scratch", false, false }, { "bullet", false, true } }
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
-- one worn layer over a part: counted, and its numbers added unless it has a hole there (the game skips it)
function Q.addLayer(m, it, bp)
    local ps = m.parts[tostring(bp)]
    if not ps then return end
    ps.layers = ps.layers + 1
    local hole = 0
    pcall(function() hole = it:getVisual():getHole(bp) end)
    if hole ~= 0 then return end
    for k, kd in ipairs(Q.KINDS) do
        local v = it:getDefForPart(bp, kd[2], kd[3]) or 0
        ps.sum[k] = ps.sum[k] + v
        ps.floors[k] = ps.floors[k] + math.floor(v)
    end
end
-- per part and kind the whole numbers a summary may show: lo the layers each rounded down and added, hi the total
-- rounded to nearest, both at most 100 (an uncovered part is -1); and the game's own number beside them
function Q.windows(m)
    local sLo, sHi = 0, 0
    m.worstLo, m.worstHi, m.bestLo, m.bestHi, m.uncovered = 999, 999, -1, -1, 0
    for _, name in ipairs(m.names) do
        local ps = m.parts[name]
        for k, kd in ipairs(Q.KINDS) do
            local g = nil
            pcall(function() g = p:getBodyPartClothingDefense(ps.bp:index(), kd[2], kd[3]) end)
            ps.game[k] = g
            if ps.layers == 0 then
                ps.lo[k], ps.hi[k] = -1, -1
            else
                ps.lo[k] = math.min(100, ps.floors[k])
                ps.hi[k] = math.floor(math.min(100, ps.sum[k]) + 0.5)
            end
        end
        if ps.layers == 0 then m.uncovered = m.uncovered + 1 end
        sLo, sHi = sLo + math.max(0, ps.lo[1]), sHi + math.max(0, ps.hi[1])
        m.worstLo, m.worstHi = math.min(m.worstLo, ps.lo[1]), math.min(m.worstHi, ps.hi[1])
        m.bestLo, m.bestHi = math.max(m.bestLo, ps.lo[1]), math.max(m.bestHi, ps.hi[1])
    end
    m.avgLo, m.avgHi = math.floor(sLo / m.nParts), math.floor(sHi / m.nParts)
end
function Q.model()
    local m = { parts = {}, names = {}, garments = 0 }
    local nMax = BloodBodyPartType.MAX:index()
    for i = 0, nMax - 1 do
        local bp = BloodBodyPartType.FromIndex(i)
        local name = tostring(bp)
        m.names[#m.names + 1] = name
        m.parts[name] = { bp = bp, layers = 0, sum = { 0, 0, 0 }, floors = { 0, 0, 0 }, lo = {}, hi = {}, game = {} }
    end
    m.nParts = #m.names
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:get(i):getItem()
        if it and instanceof(it, "Clothing") then
            local cov = Q.coveredOf(it)
            if cov and cov:size() > 0 then
                m.garments = m.garments + 1
                -- (a garment counts once per part, as in the game's loop, even when two of its blood types share one)
                local seen = {}
                for j = 0, cov:size() - 1 do
                    local bp = cov:get(j)
                    if not seen[tostring(bp)] then seen[tostring(bp)] = true; Q.addLayer(m, it, bp) end
                end
            end
        end
    end
    Q.windows(m)
    return m
end
function Q.win(lo, hi) return lo == hi and tostring(lo) or (tostring(lo) .. "-" .. tostring(hi)) end
function Q.ps(t)
    if not t then return "nil" end
    return tostring(t.bite) .. "/" .. tostring(t.scratch) .. "/" .. tostring(t.bullet) .. " x" .. tostring(t.layers)
end
function Q.pm(ms)
    return Q.win(ms.lo[1], ms.hi[1]) .. "/" .. Q.win(ms.lo[2], ms.hi[2]) .. "/" .. Q.win(ms.lo[3], ms.hi[3]) .. " x" .. ms.layers
end
-- the script's model against the game's own number (a check on this script: if it fails, so may the lines after it)
function Q.modelCheck(pre, m)
    local bad, first = 0, nil
    for _, name in ipairs(m.names) do
        local ps = m.parts[name]
        for k, kd in ipairs(Q.KINDS) do
            local want = (ps.layers == 0) and 0 or math.min(100, ps.sum[k])
            if type(ps.game[k]) ~= "number" or math.abs(ps.game[k] - want) > 0.01 then
                bad = bad + 1
                first = first or (name .. " " .. kd[1] .. " game " .. tostring(ps.game[k]) .. " vs model " .. tostring(want))
            end
        end
    end
    check(bad == 0, pre .. "this script's model (the worn layers added up to 100, holes skipped) is the game's own number on every part",
        first and (bad .. " differ, first " .. first) or "equal", "equal")
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
        local same = zs ~= nil and zs.layers == ms.layers and inWin(zs.bite, ms.lo[1], ms.hi[1])
            and inWin(zs.scratch, ms.lo[2], ms.hi[2]) and inWin(zs.bullet, ms.lo[3], ms.hi[3])
        if not same then
            nb = nb + 1
            first = first or (name .. " " .. Q.ps(zs) .. " vs " .. Q.pm(ms))
        end
    end
    add("each part's bite / scratch / bullet is its worn layers added up to 100, as the game counts them, and its layer count the garments over it ("
        .. m.nParts .. " parts)", nb == 0, first and (nb .. " differ, first " .. first) or "all equal", "all equal")
    add("average bite over all parts", inWin(z.avgBiteDef, m.avgLo, m.avgHi), z.avgBiteDef, Q.win(m.avgLo, m.avgHi))
    local gWant = Q.gradeOf(math.max(m.avgLo, math.min(m.avgHi, z.avgBiteDef or -1)))
    add("letter grade for that average", z.grade == gWant, z.grade, gWant)
    add("uncovered parts listed", #(z.uncoveredParts or {}) == m.uncovered, #(z.uncoveredParts or {}), m.uncovered)
    local wb = z.worstPart and z.worstPart.biteDef
    add("worst part's bite", inWin(wb, m.worstLo, m.worstHi), wb, Q.win(m.worstLo, m.worstHi))
    local bb = z.bestPart and z.bestPart.biteDef
    add("best part's bite", inWin(bb, m.bestLo, m.bestHi), bb, Q.win(m.bestLo, m.bestHi))
    return out
end
function Q.defChecks(pre, z, m)
    if not check(z ~= nil, "presence: " .. pre .. "the Equip tab has a defense summary", "nil", "a summary") then return end
    for _, d in ipairs(Q.defDiff(z, m)) do check(d.ok, pre .. d.what, d.got, d.want) end
end
-- one line: does the summary follow the worn items (garments, every part, average, grade, worst, best)?
function Q.defAll(what, z, m)
    if not z then check(false, what, "no summary", "a summary"); return end
    local bad = nil
    for _, d in ipairs(Q.defDiff(z, m)) do
        if not d.ok then bad = bad or (d.what .. ": " .. tostring(d.got) .. " vs " .. tostring(d.want)) end
    end
    check(bad == nil, what, bad or "", "the worn items' numbers")
end
-- ZeD's per-part numbers against the game's own (single layers and layered parts apart); ZeD's whole number may be
-- the game's rounded down or to nearest, or its layers each rounded down and added
function Q.gameChecks(pre, z, m)
    local n1, n2, b1, b2, d1, d2 = 0, 0, 0, 0, nil, nil
    for _, name in ipairs(m.names) do
        local ms = m.parts[name]
        if ms.layers >= 1 then
            local zs = z.partStats and z.partStats[name]
            local bad = nil
            for k, kd in ipairs(Q.KINDS) do
                local g = ms.game[k]
                local v = zs and zs[kd[1]]
                if type(g) ~= "number" or not inWin(v, math.min(ms.lo[k], math.floor(g)), math.floor(g + 0.5)) then
                    bad = bad or (name .. " " .. kd[1] .. " " .. tostring(v) .. " vs game " .. tostring(g))
                end
            end
            if ms.layers == 1 then
                n1 = n1 + 1
                if bad then b1 = b1 + 1; d1 = d1 or bad end
            else
                n2 = n2 + 1
                if bad then b2 = b2 + 1; d2 = d2 or bad end
            end
        end
    end
    check(n1 > 0 and b1 == 0, pre .. "single-layer parts show the game's own bite / scratch / bullet defense (" .. n1 .. " parts)",
        (n1 == 0 and "no single-layer part") or (d1 and (b1 .. " differ, first " .. d1)) or "equal", "equal")
    check(n2 > 0 and b2 == 0, pre .. "layered parts show the game's own bite / scratch / bullet defense, which adds the layers up to 100 (" .. n2 .. " parts)",
        (n2 == 0 and "no layered part") or (d2 and (b2 .. " differ, first " .. d2)) or "equal", "equal")
end
-- the summary built since t (the tab builds it again every 250 ms while it draws its list)
function Q.fresh(w, t) return w ~= nil and w._equipProtCache ~= nil and (w._equipProtAt or 0) > t end
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
-- a container; one that can be taken apart only with tools first (the Disassemble checks need that), then one that
-- can be taken apart, then the lightest
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
    local tools = false
    if scrap and mp.scrapUseTool then
        local def = defs.getScrapDefinition(mp.material)
        tools = def ~= nil and (#(def.tools or {}) > 0 or #(def.tools2 or {}) > 0)
    end
    return { name = name, mp = mp, faces = f, scrap = scrap, tools = tools, rank = (tools and 2) or (scrap and 1) or 0,
             weight = mp.weight or 99, set = { [f.N] = true, [f.E] = true, [f.S] = true, [f.W] = true } }
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
                local better = not best or pc.rank > best.rank or (pc.rank == best.rank and pc.weight < best.weight)
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
-- the tab's body scrolled to its end: the lists sit under the target's facts, and a row out of view has no zone (on a
-- short window the facts can push them out); the tab clamps it to its real end on its next frame
function Q.scrollDown() local s = Q.fur(); if s then s.scrollY = 100000 end end
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
        LG.parked = true
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
-- would ZeD's reading of the game's good / bad highlight colors give green / red? (a color-blind palette may not)
function Q.colorsRead()
    local ok, res = pcall(function()
        local g, b = getCore():getGoodHighlitedColor(), getCore():getBadHighlitedColor()
        local okG = g:getG() > g:getR() + 0.15 and g:getG() > 0.45
        local okB = b:getR() > b:getG() + 0.15 and b:getR() > 0.45
        return okG and okB
    end)
    return ok and res
end
-- the material's scrap tools: all set aside (false when one is worn: it stays)
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
                local worn = false
                pcall(function() worn = p:isEquippedClothing(it) end)
                if worn then clean = false else Q.takeOne(it) end
            end
        end
    end
    -- (the belt's icons follow a tool taken off it, as ISHotbar.removeItem does)
    pcall(function() local hb = getPlayerHotbar and getPlayerHotbar(pn); if hb then hb:reloadIcons() end end)
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
-- what the game's own repair list takes on a tile (vanilla's ISMoveableCursor.getRepairObjectList on a stand-in
-- cursor for that tile, the tile in sight)
function Q.gameRepairList(sq)
    local out = {}
    pcall(function()
        local probe = setmetatable({ currentSquare = sq, canSeeCurrentSquare = true, character = p, player = pn }, { __index = ISMoveableCursor })
        out = probe:getRepairObjectList() or {}
    end)
    return out
end
-- a damaged wooden piece on sq that the game would repair: a player-built fence (an IsoThumpable, as vanilla's
-- builders and its debug scenarios make one) at half health, else the furniture's own sprite as one; the first the
-- game's repair list takes
function Q.repairTarget(sq)
    if not sq then return nil end
    local names = { "carpentry_02_48", "carpentry_02_49", "carpentry_02_40", "carpentry_02_41", "carpentry_02_44", "carpentry_02_45" }
    if S.piece then names[#names + 1] = S.piece.name end
    for _, name in ipairs(names) do
        if getSprite(name) then
            local o = nil
            pcall(function()
                o = IsoThumpable.new(getCell(), sq, name, nil, false, nil)
                o:setMaxHealth(200)
                o:setHealth(100)
                sq:AddSpecialObject(o)
            end)
            if o then
                Q.mark(o)
                LG.fobjs[#LG.fobjs + 1] = { obj = o, sq = sq }
                for _, e in ipairs(Q.gameRepairList(sq)) do
                    if e.object == o then return { obj = o, name = name } end
                end
                Q.removeObj(sq, o)
                LG.fobjs[#LG.fobjs] = nil
            end
        end
    end
    return nil
end
function Q.removeRepairTarget()
    local n = 0
    for _, o in ipairs(LG.fobjs) do Q.removeObj(o.sq, o.obj); n = n + 1 end
    LG.fobjs = {}
    S.rep = nil
    return n
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
                -- (explored at once: the World window fills an unexplored container with the game's loot the first
                -- time it lists it, ZeD_WorldWindow.lua's ItemPicker.fillContainer; outdoors that is shelf loot)
                for k = 0, o:getContainerCount() - 1 do pcall(function() o:getContainerByIndex(k):setExplored(true) end) end
                pcall(function() o:getContainer():setExplored(true) end)
                Q.mark(o)
                LG.objs[#LG.objs + 1] = { obj = o, sq = sq }
                return o, name
            end
            Q.removeObj(sq, o)
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
-- a window's container selection by the containers themselves (its list is built again, so indices move)
function Q.selOf(w)
    local cs = w and w._containers or {}
    local function invAt(i) local c = i and cs[i]; return c and c.inventory end
    return { inv = invAt(w and w._activeContainer), view = invAt(w and w._viewedContainer), mainVis = w and w._mainVisible }
end
function Q.putSel(w, sel, fallback)
    if not (w and sel) then return end
    local i = sel.inv and Q.idxOf(w, sel.inv)
    if i or fallback then w._activeContainer = i or fallback end
    w._viewedContainer = sel.view and Q.idxOf(w, sel.view) or nil
    if sel.mainVis ~= nil then w._mainVisible = sel.mainVis end
    w._containerTimer = 30
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
    -- (the tab's pick and its last read go with the cursor: FT.setMode clears the pick, the run set the mode directly;
    -- its body back at the top)
    FT.pick = nil
    pcall(function() FT.cap[pn] = nil end)
    pcall(function() local s = Q.fur(); if s then s.scrollY = 0 end end)
    local gone = Q.removeRepairTarget()
    if S.piece and S.T then
        for _ = 1, 4 do
            local o = Q.pieceOn(S.T)
            if not o then break end
            Q.removeObj(S.T, o)
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
    pcall(function() if LG.movCheat ~= nil then p:setMovablesCheat(LG.movCheat) end end)
    pcall(function() if LG.defCheat ~= nil then ISMoveableDefinitions.cheat = LG.defCheat end end)
    LG.movCheat, LG.defCheat = nil, nil
    return gone
end
function Q.restoreContainers()
    for _, it in ipairs(S.conItems or {}) do Q.drop(it) end
    S.conItems = {}
    -- (anything else left in the run's shelf or bag: nothing should be)
    for _, inv in ipairs({ S.shelfInv or false, S.bagInv or false }) do
        if inv then
            pcall(function()
                local items = inv:getItems()
                for k = items:size() - 1, 0, -1 do Q.drop(items:get(k)) end
            end)
        end
    end
    if S.bag then Q.drop(S.bag); S.bag = nil end
    local n = 0
    for _, o in ipairs(LG.objs) do Q.removeObj(o.sq, o.obj); n = n + 1 end
    LG.objs = {}
    Q.hands()
    -- each window back on the container it showed
    pcall(function() Q.putSel(Q.ww(), LG.wwSel, nil) end)
    pcall(function() Q.putSel(Q.cw(), LG.cwSel, 1) end)
    LG.wwSel, LG.cwSel = nil, nil
    return n
end
-- the Equip tab's to-do, and the item card it had open when it shows again (any tab switch closes the card, so
-- this runs after the tabs are put back)
function Q.restoreEquipTab()
    local w = Q.cw()
    if not w then return end
    if LG.todo then pcall(function() if w._el then w._el.todo = true end end); LG.todo = nil end
    if LG.eqSel ~= nil then
        if w._activeTab == "equip" and w._drawerMode == "tab" and w._drawerOpen == true then w._equipSelected = LG.eqSel end
        LG.eqSel = nil
    end
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
        pcall(function()
            if not t.item:getContainer() then t.cont:AddItem(t.item); back = back + 1 end
            if t.model then
                p:setAttachedItem(t.model, t.item)
                t.item:setAttachedSlot(t.slot)
                t.item:setAttachedSlotType(t.slotType)
                t.item:setAttachedToModel(t.model)
            end
        end)
    end
    pcall(function() local hb = getPlayerHotbar and getPlayerHotbar(pn); if hb then hb:reloadIcons() end end)
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
    pcall(Q.restoreEquipTab)
    -- (a window rolled up by hand before the run rolls up again; the hover roll-up does its own)
    pcall(function() local w = Q.cw(); if LG.cwShaded and w and not w.windowShaded then w:setWindowShaded(true) end end)
    pcall(function() local w = Q.ww(); if LG.wwShaded and w and not w.windowShaded then w:setWindowShaded(true) end end)
    pcall(function() if LG.parked and LG.mx and Mouse and Mouse.setXY then Mouse.setXY(LG.mx, LG.my) end end)
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
    ZEDQA_COV_EF = nil
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
        Q.scrollDown()
    end)
end

-- ---- SETUP -----------------------------------------------------------------------------------------------------
add(0, function()
    S.moved = false
    if ZEDQA_HOME then S.moved = ZEDQA_HOME("cov_equipfurn") == true end
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
    pcall(function() LG.mx, LG.my = getMouseX(), getMouseY() end)
    p:setGodMod(true)
    p:setTimedActionInstantCheat(true)
    LG.cwOpen = CWm.isOpen()
    local cw, ww = Q.cw(), Q.ww()
    LG.cwTab, LG.cwDrawer = cw and cw._activeTab, cw and cw._drawerOpen and cw._drawerMode == "tab"
    LG.wwTab, LG.wwDrawer = ww and ww._activeTab, ww and ww._drawerOpen and ww._drawerMode == "tab"
    LG.cwShaded = cw ~= nil and cw.windowShaded == true and cw._autoShaded ~= true
    LG.wwShaded = ww ~= nil and ww.windowShaded == true and ww._autoShaded ~= true
end)
-- (after a move to the drag strip its tiles take a moment to load)
waitFor(15000, function()
    if not S.moved then return true end
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local cell = getCell()
    return cell:getGridSquare(px + 1, py, pz) ~= nil and cell:getGridSquare(px, py + 1, pz) ~= nil
        and cell:getGridSquare(px - 1, py, pz) ~= nil and cell:getGridSquare(px, py - 1, pz) ~= nil
end, "the drag strip's tiles after the move there")
add(400, function()
    Q.pickSquares()
    say("start: at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. "; furniture tile " .. Q.sqName(S.T)
        .. ", shelf tile " .. Q.sqName(S.C) .. ", repair piece tile " .. Q.sqName(S.R))
end)

-- ---- 1. THE EQUIP TAB'S DEFENSE SUMMARY --------------------------------------------------------------------------
add(100, function() CWm.openTab(pn, "equip") end)
waitFor(5000, function()
    local w = Q.cw()
    return w ~= nil and w._activeTab == "equip" and w._drawerOpen == true and w._drawerMode == "tab"
end, "the Equip tab")
add(300, function()
    local w = Q.cw()
    S.eq = check(w ~= nil and w._activeTab == "equip" and w._drawerOpen == true and w._drawerMode == "tab",
        "presence: the Equip tab opens", w and tostring(w._activeTab) .. "/" .. tostring(w._drawerMode), "equip/tab")
    if not S.eq then return end
    -- what keeps the list (and its summary) from drawing: an item card on a row, the loadouts' to-do (both back at the end)
    LG.eqSel = w._equipSelected
    w._equipSelected = nil
    if w._el and w._el.todo == true then
        LG.todo = true
        w._el.todo = false
        note("the loadouts' to-do covered the tab: set aside for the run")
    end
    if w._equipDefHidden then note("the tab's Find text hides the defense block on screen (its numbers are still read)") end
    -- the summary built again from now: an open card or the to-do leaves an old one behind (openTab returns early
    -- when the tab already shows, so nothing else would reset it)
    w._equipProtCache = nil
end)
waitFor(5000, function() local w = Q.cw(); return (not S.eq) or (w ~= nil and w._equipProtCache ~= nil) end, "the defense summary built again")
add(100, function()
    if not S.eq then return end
    local w = Q.cw()
    local z = w._equipProtCache
    S.eq = check(z ~= nil, "presence: the Equip tab builds its defense summary again after a reset", "none", "a summary")
    if not S.eq then return end
    LG.z0 = { g = z.totalGarments, avg = z.avgBiteDef, grade = z.grade }
    say("before the run: " .. z.totalGarments .. " garments, " .. z.avgBiteDef .. "% grade " .. tostring(z.grade))
    local off, kept = Q.strip()
    say("clothes that cover a part taken off: " .. off .. (kept > 0 and (", " .. kept .. " kept (they give slots)") or ""))
end)
add(900, function()
    if not S.eq then return end
    local w = Q.cw()
    local z, m = w._equipProtCache, Q.model()
    if m.garments > 0 then
        check(false, "bare: every garment that covers a part comes off, so the bare checks can run", m.garments .. " still on (they give belt slots)", 0)
        return
    end
    if not z then check(false, "bare: the Equip tab has a defense summary", "none", "a summary"); return end
    check(z.totalGarments == 0, "bare: the summary counts 0 garments", z.totalGarments, 0)
    check(z.avgBiteDef == 0 and z.grade == "F", "bare: average 0% and grade F", z.avgBiteDef .. "% " .. tostring(z.grade), "0% F")
    check(#z.uncoveredParts == m.nParts, "bare: every part listed uncovered", #z.uncoveredParts, m.nParts)
    check(z.worstPart.biteDef == -1 and z.bestPart.biteDef == -1, "bare: the worst part reads uncovered and there is no best part",
        z.worstPart.biteDef .. "/" .. z.bestPart.biteDef, "-1/-1")
end)
add(100, function()
    if not S.eq then return end
    local z0 = Q.cw()._equipProtCache
    S.gBefore = z0 and z0.totalGarments
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
    S.outfitN = worn
    say("outfit on: " .. worn .. " of 6")
end)
add(900, function()
    if not S.eq then return end
    local w = Q.cw()
    local z, m = w._equipProtCache, Q.model()
    check(S.outfitN == 6, "the staged outfit is worn (hard hat, denim shirt under a leather jacket, jeans, leather gloves, work boots)",
        tostring(S.outfitN) .. " of 6", "6 of 6")
    -- (nothing here asks the tab to build it again: the count can only follow the change by the tab's own refresh)
    check(z ~= nil and S.gBefore ~= nil and S.gBefore ~= m.garments and z.totalGarments == m.garments,
        "the summary refreshed by itself after the outfit went on (its garment count followed)",
        tostring(S.gBefore) .. " -> " .. tostring(z and z.totalGarments), tostring(S.gBefore) .. " -> " .. m.garments)
    say("outfit model: " .. m.garments .. " garments, average " .. Q.win(m.avgLo, m.avgHi) .. "%, worst " .. Q.win(m.worstLo, m.worstHi)
        .. ", best " .. Q.win(m.bestLo, m.bestHi) .. ", " .. m.uncovered .. " uncovered")
    Q.modelCheck("outfit: ", m)
    Q.defChecks("outfit: ", z, m)
    if z then Q.gameChecks("outfit: ", z, m) end
    local missing = {}
    for _, it in ipairs(LG.outfit) do if not Q.rowOf(w, it) then missing[#missing + 1] = it:getType() end end
    check(#LG.outfit > 0 and #missing == 0, "presence: the Equip list has a row for every garment worn", table.concat(missing, ","), "none missing")
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
    local w = Q.cw()
    local z, m = w._equipProtCache, Q.model()
    local held = LG.heldGlove ~= nil and p:getPrimaryHandItem() == LG.heldGlove
    local fresh = Q.fresh(w, S.tChange)
    check(held and fresh and z.totalGarments == m.garments, "a garment held in the hand is not counted as worn",
        (not held and "no glove in the hand") or (not fresh and "the summary was not built again after it") or z.totalGarments, m.garments)
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
    if not S.eq then return end
    if not LG.jacket then
        check(false, "the summary follows the jacket coming off (garments, every part, average, grade, worst, best)", "no jacket was worn", "a jacket")
        return
    end
    Q.defAll("the summary follows the jacket coming off (garments, every part, average, grade, worst, best)", Q.cw()._equipProtCache, Q.model())
end)
add(100, function()
    if not S.eq then return end
    Q.unstage()
    S.tChange = getTimestampMs()
end)
add(900, function()
    if not (S.eq and LG.z0) then return end
    local w = Q.cw()
    local z = w._equipProtCache
    local want = LG.z0.g .. " / " .. LG.z0.avg .. "% " .. tostring(LG.z0.grade)
    if not Q.fresh(w, S.tChange) then
        check(false, "put back: the summary reads as it did before the run", "not built again since the clothes went back", want)
        return
    end
    check(z.totalGarments == LG.z0.g and z.avgBiteDef == LG.z0.avg and z.grade == LG.z0.grade,
        "put back: the summary reads as it did before the run", z.totalGarments .. " / " .. z.avgBiteDef .. "% " .. tostring(z.grade), want)
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
    -- (several containers side by side: the row is off there, and the run does not take that view apart)
    if #(ww._mcSelected or {}) > 0 or #(cw._mcSelected or {}) > 0 then
        check(false, "containers: each window shows one list, so the button rows draw (the container checks cannot run)",
            #(cw._mcSelected or {}) .. " / " .. #(ww._mcSelected or {}) .. " extra columns", "0 / 0")
        return
    end
    LG.wwSel, LG.cwSel = Q.selOf(ww), Q.selOf(cw)
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
    -- the shelf holds only what the run put on it (anything else is game loot, taken away at once: it would upset
    -- every count after this)
    local mine, extra = {}, {}
    for _, it in ipairs(S.conItems) do mine[it] = true end
    local items = S.shelfInv:getItems()
    for k = items:size() - 1, 0, -1 do
        local it = items:get(k)
        if not mine[it] then
            extra[#extra + 1] = it:getType()
            Q.mark(it)
            pcall(function() S.shelfInv:Remove(it) end)
        end
    end
    check(#extra == 0, "the new shelf holds only what was put on it (marked explored, so the World window does not fill it with loot)",
        #extra == 0 and "only those" or (#extra .. " more, taken away: " .. table.concat(extra, ",")), "only those")
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
    check(wc._inventory == S.shelfInv and wc._ccEntry ~= nil, "presence: the World list shows the shelf with its button row", tostring(wc._inventory == S.shelfInv), "true")
    check(cc._inventory == S.bagInv and cc._ccEntry ~= nil, "presence: the Character list shows the bag with its button row", tostring(cc._inventory == S.bagInv), "true")
    local wk, ck = Q.keys(wc), Q.keys(cc)
    check(Q.hit(wc, "take") ~= nil and Q.hit(wc, "same") ~= nil and Q.hit(wc, "floor") ~= nil,
        "presence: the World row has Take all, Same type and To floor", wk, "take,same,floor,...")
    check(Q.hit(cc, "xfer") ~= nil and Q.hit(cc, "same") ~= nil, "presence: your row has Transfer all and Same type", ck, "xfer,same,...")
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
    -- a screw into the bag, then at once (the row is built again only on its next frame) a press on the button still
    -- drawn off: it must do nothing, though there is now a screw it could move
    local it = Q.give("Base.Screws", S.bagInv)
    if it then S.conItems[#S.conItems + 1] = it end
    S.snap = Q.counts()
    S.offPress, S.offWhy = Q.press(cc, "same")
end)
add(600, function()
    if not S.con then return end
    check(S.offPress == true and Q.counts() == S.snap,
        "a press on your Same type while it is drawn off does nothing (the screw just put in the bag stays there)",
        S.offPress and Q.counts() or ("no press: " .. tostring(S.offWhy)), S.snap)
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
    if S.con then
        local wc = Q.wc()
        local onFloor = wc._inventory and wc._inventory:getType() == "floor"
        check(onFloor and Q.hit(wc, "floor") == nil and Q.hit(wc, "take") ~= nil, "presence: the floor's own row has Take all, and no To floor",
            tostring(onFloor) .. " " .. Q.keys(wc), "true, no floor")
    end
    -- (put back whatever got this far: the shelf, the bag, the things, both windows' containers)
    if LG.wwSel or #LG.objs > 0 or S.bag then
        local n = Q.restoreContainers()
        say("containers put back: shelves removed " .. n)
    end
    S.con = false
end)

-- ---- 3. THE FURNITURE TAB ----------------------------------------------------------------------------------------
add(300, function()
    if not S.T then check(false, "furniture: a free tile beside you", "none", "a tile"); return end
    S.piece = Q.pieceSprite()
    if not check(S.piece ~= nil, "furniture: a one-tile piece with four faces the game moves without tools", "none", "a sprite") then return end
    say("furniture piece " .. S.piece.name .. " (" .. tostring(S.piece.mp.name) .. ", " .. tostring(S.piece.mp.weight) .. " kg, faces N "
        .. S.piece.faces.N .. " E " .. S.piece.faces.E .. " S " .. S.piece.faces.S .. " W " .. S.piece.faces.W
        .. (S.piece.scrap and ", can be taken apart" or "") .. (S.piece.tools and " with tools" or "") .. ")")
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
    local old = Q.cur()
    if old then
        note("a furniture cursor was up before the run: it is ended first")
        pcall(function() old:exitCursor() end)
    end
    -- the tab's mode staged apart from the game's last one: the cursor must start in the tab's (put back at the end)
    ISMoveableCursor.mode[pn] = "pickup"
    FT.state.mode = "rotate"
    S.fur = true
    WWm.openTab(pn, "furniture")
end)
waitFor(5000, function() return not S.fur or (WWm.isTabShowing("furniture") and Q.cur() ~= nil) end, "the Furniture tab and its cursor")
add(300, function()
    if not S.fur then return end
    S.park = true
    check(WWm.isTabShowing("furniture") and Q.cur() ~= nil and FT.state.active == true, "opening the Furniture tab starts the game's furniture cursor",
        tostring(WWm.isTabShowing("furniture")) .. "/" .. tostring(Q.cur() ~= nil) .. "/" .. tostring(FT.state.active), "true/true/true")
    check(ISMoveableCursor.mode[pn] == "rotate" and FT.state.mode == "rotate",
        "the cursor starts in the tab's own mode (Rotate here), not the game's last one (Pick up)",
        tostring(ISMoveableCursor.mode[pn]) .. "/" .. tostring(FT.state.mode), "rotate/rotate")
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
    check(k ~= nil and Q.zone("fur:inv:" .. tostring(k)) ~= nil, "presence: Place: YOUR FURNITURE has a row for the carried piece", k and ("row " .. k) or "no row", "a row")
    if #list <= 3 then
        check(rows == #list, "presence: Place: YOUR FURNITURE shows every piece the game can place from your inventory", rows, #list)
    end
    -- (the cursor's pick cleared first, as a mode change leaves it: with one piece carried it is already that row's,
    -- so only the press can set it again before the next frame)
    if cur then cur.objectIndex = -1 end
    if k then Q.clickZone("fur:inv:" .. k) end
    check(cur ~= nil and k ~= nil and cur.objectIndex == k, "Place: the row's button puts the piece on the cursor", cur and cur.objectIndex, k)
    Q.hold(S.T)
end)
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then check(false, "Place: the cursor is still up", "nil", "a cursor"); return end
    check(Q.faceZones() == "N,E,S,W", "presence: Place: FACING offers the piece's four faces", Q.faceZones(), "N,E,S,W")
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
    check(Q.faceZones() == "N,E,S,W", "presence: Rotate: FACING offers the piece's four faces", Q.faceZones(), "N,E,S,W")
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
    if not (S.fur and S.piece.scrap) then return end
    local t1, t2 = Q.scrapTools()
    S.scrapTools = S.piece.tools and (#t1 > 0 or #t2 > 0)
    -- (the game's furniture cheats let anything come apart: off for these checks, back at the end)
    LG.movCheat = p:isMovablesCheat()
    LG.defCheat = ISMoveableDefinitions.cheat
    if LG.movCheat then p:setMovablesCheat(false) end
    if LG.defCheat then ISMoveableDefinitions.cheat = false end
    if S.scrapTools then S.toolsClean = Q.setAsideTools() end
end)
add(400, function()
    if not S.fur then return end
    if not S.piece.scrap then
        check(false, "Disassemble: the piece can be taken apart (a scrap definition for its material), so the Disassemble checks can run",
            tostring(S.piece.mp.material), "a scrap material")
        return
    end
    local c = Q.reread(S.T)
    local _, onTile = Q.pieceOn(S.T)
    check(c ~= nil and c.mp ~= nil and onTile ~= nil and c.mp.spriteName == onTile and c.sq == S.T, "Disassemble: the tab reads the piece on the tile",
        c and c.mp and c.mp.spriteName, onTile)
    if not S.scrapTools then
        check(false, "Disassemble: taking the piece apart needs tools, so the without-tools checks can run", "no tool needed", "tools")
    elseif not S.toolsClean then
        check(false, "Disassemble: every scrap tool set aside, so the without-tools checks can run", "one is worn and stays", "all set aside")
    else
        check(c ~= nil and c.canCreate == false, "Disassemble: with its tools set aside the tab says it cannot be taken apart",
            c and tostring(c.canCreate), "false")
        if Q.colorsRead() then
            check(Q.toolState(c) == "bad", "Disassemble: the tool line reads red without the tools", Q.toolState(c), "bad")
        else
            check(false, "Disassemble: the game's good / bad colors read as green / red here, so the tool-line checks can run", "another palette", "green / red")
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

-- Repair (read only): a damaged wooden piece beside you, then the furniture's tile, where the game repairs nothing
add(100, function()
    if not S.fur then return end
    S.rep = Q.repairTarget(S.R)
    if S.rep then say("repair piece " .. S.rep.name .. " on " .. Q.sqName(S.R) .. " at half health") end
end)
Q.modeStep("repair")
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then check(false, "Repair: the cursor is still up", "nil", "a cursor"); return end
    if not S.rep then
        check(false, "Repair: a damaged wooden piece beside you that the game's repair list takes, so the Repair checks can run",
            S.R and "none of the pieces tried is listed" or "no free tile", "one")
        return
    end
    local c = Q.reread(S.R)
    Q.scrollDown()
    local list = cur.objectListCache
    local n = type(list) == "table" and #list or 0
    local k = nil
    for q, e in ipairs(n > 0 and list or {}) do if e.object == S.rep.obj then k = q end end
    S.repN, S.repK = n, k
    local e = n > 0 and list[cur.objectIndex] or nil
    local want = e and e.moveProps and e.moveProps.spriteName
    check(k ~= nil and c ~= nil and c.mp ~= nil and c.sq == S.R and c.mode == "repair" and want ~= nil and c.mp.spriteName == want,
        "Repair: on a tile with something to repair the tab shows the game's target there",
        tostring(c and c.mp and c.mp.spriteName) .. " on " .. Q.sqName(c and c.sq) .. " (" .. n .. " listed)", tostring(want) .. " on " .. Q.sqName(S.R))
end)
add(300, function()
    if not (S.fur and S.rep) then return end
    local cur = Q.cur()
    if not cur then return end
    check((S.repN or 0) > 0 and Q.zoneCount("fur:obj:") == S.repN, "presence: Repair: ON THIS TILE has a row for everything the game would repair there",
        Q.zoneCount("fur:obj:"), S.repN)
    local k = S.repK
    if k then Q.clickZone("fur:obj:" .. k) end
    local pk = FT.pick
    check(k ~= nil and cur.objectIndex == k and pk ~= nil and pk.sq == S.R and pk.mode == "repair" and pk.idx == k,
        "Repair: Target picks the piece on the cursor for this tile",
        tostring(cur.objectIndex) .. " on " .. Q.sqName(pk and pk.sq) .. " in " .. tostring(pk and pk.mode), tostring(k) .. " on " .. Q.sqName(S.R) .. " in repair")
end)
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then check(false, "Repair: the cursor is still up", "nil", "a cursor"); return end
    local c = Q.reread(S.T)
    local list = cur.objectListCache
    local n = type(list) == "table" and #list or 0
    S.repN2 = n
    if n > 0 then
        check(false, "Repair: the furniture's tile holds nothing the game would repair (a plain object), so the empty checks can run", n .. " listed", "none")
        return
    end
    check(c ~= nil and c.sq == S.T and c.mp == nil, "Repair: on a tile with nothing to repair (after one with a target) the tab shows no target",
        tostring(c and c.mp and c.mp.spriteName or "none") .. " on " .. Q.sqName(c and c.sq), "none on " .. Q.sqName(S.T))
end)
add(300, function()
    if not S.fur then return end
    if S.repN2 == 0 then
        check(Q.zoneCount("fur:obj:") == 0, "Repair: ON THIS TILE empties on a tile with nothing to repair", Q.zoneCount("fur:obj:"), 0)
    end
    Q.removeRepairTarget()
end)

-- Pick up
Q.modeStep("pickup")
add(400, function()
    if not S.fur then return end
    local cur = Q.cur()
    if not cur then check(false, "Pick up: the cursor is still up", "nil", "a cursor"); return end
    Q.hold(S.T)
    cur:isValid(S.T)
    Q.scrollDown()
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
    check((S.pickN or 0) > 0 and Q.zoneCount("fur:obj:") == S.pickN, "presence: Pick up: ON THIS TILE has a row for everything the game can pick up there",
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
-- (a later run of this script stops this one and puts its changes back first)
ZEDQA_COV_EF = { abort = function(why)
    pcall(function() Events.OnTick.Remove(drive) end)
    i = #plan + 1
    Q.restore(why)
end }
Events.OnTick.Add(drive)
