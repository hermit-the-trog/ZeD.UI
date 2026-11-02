-- ZeDUI/tools/qa/zedqa_preview_card.lua  (Nov 1 2026; punch list 49, for t16)
-- The recipe preview card (ObjectCardPreview.lua): the picked recipe's icon in the Build or Craft header
-- opens a half card over the drawer. Driven by the controller path (Focus.focusWhere on the icon stop
-- "build:icon" / "craft:icon", A = the focused element's onActivate, the call the A resolver makes;
-- B through Focus.dispatchJoypadDown). On the World window:
--   Build, the big metal fence (MetalBigMetalFence): the card is the half card over the drawer (rect),
--     tiles not "No picture for this one", Facing with < and > turning it (> then < and < again from the
--     first face), the game's words (its Tooltip), "Strength 450", "Skill Metalworking 3", the Build verb
--     (folded with its need when it cannot be built yet: which is printed); zqa_pvc_build_metal_fence.png
--   B closes the card, the focus is back on the icon stop; open again, pick another recipe: the card closes
--   the log fence (LogFence): "Strength 200 + N from your carpentry", N = 50 a Carpentry level, 100 more for
--     Handy; the log gate (LogGate, the skill-based strength with no fixed number) the same way
--   the plank barricade (BarricadePlanks): no strength line
--   the double gate (DoubleFenceGate): the tiles' count and layout; zqa_pvc_build_double_gate.png
--   Craft, a baseball bat carried: the spiked bat (MakeSpikedBaseballBat): What you get with the facts, What
--     changes against the bat (damage with the step, condition, weight); zqa_pvc_craft_spiked_bat.png
--   a recipe with several results (NailSpikeWeapon, the nail mapper): "or one of N others"
-- Puts back the bat, the card, both recipe picks and both windows' tabs. grep "ZEDQA pvc".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local CC = ZeD.CraftingCore
local T = ZeD.T
local function say(s) print("ZEDQA pvc " .. tostring(s)) end
local fails, passes = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local SW, SH = getCore():getScreenWidth(), getCore():getScreenHeight()
local S = { was = {} }   -- the run's state (one table: the chunk's locals stay few)
local strengthCheck   -- (defined after scriptHealth: the strength against the game's own formula, Build's second pass)

-- ---- the step queue (as zedqa_two_widths.lua): wait n ticks, or until the World window is still
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end
local STILL, STILL_MAX = 30, 600
local function shape()
    local w = ww()
    if not (w and w:isVisible()) then return "none" end
    local oc = w._objectCard
    return string.format("%d,%d,%d,%d,%d,%s,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0),
        tostring(oc and oc:isVisible()), oc and oc:getWidth() or 0)
end
local function whenStill(fn)
    local last, same, waited = nil, 0, 0
    local function poll()
        local s = shape()
        if s == last then same = same + 1 else same, last = 0, s end
        waited = waited + 1
        if same >= STILL or waited >= STILL_MAX then
            if same < STILL then say("WARN the window was still moving after " .. waited .. " ticks: checked anyway") end
            local ok, e = pcall(fn)
            if not ok then say("ERR " .. tostring(e)) end
        else
            insertNext(0, poll)
        end
    end
    insertNext(0, poll)
end

-- ---- tabs (the strips' own click handlers), the pad
local function goTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end
local function worldTab(id) local w = ww(); return w and goTab(w, w._actionTabStrip, id) end
local function fz() local w = ww(); local z = w and Focus.getFocusedZone(w); return z and z.zone end
local function fe() local w = ww(); return w and Focus.getFocusedElement(w) end
local function A()
    local w = ww(); local e = fe()
    if e and e.onActivate then e.onActivate(w, e); return true end
    return false
end
local function B() Focus.dispatchJoypadDown(Focus.getFocusedWindow() or ww(), Joypad.BButton) end
local function rs(x, y, w, h) return string.format("%d,%d %dx%d", math.floor(x), math.floor(y), math.floor(w), math.floor(h)) end
local function shot(what)
    local name = "zqa_pvc_" .. what .. ".png"
    pcall(function() getCore():TakeFullScreenshot(name) end)
    local w, oc = ww(), ww() and ww()._objectCard
    local cr = (oc and oc:isVisible()) and rs(oc:getAbsoluteX(), oc:getAbsoluteY(), oc:getWidth(), oc:getHeight()) or "closed"
    say(string.format("shot %s (%dx%d): card %s | World %s | drawer %d px", name, SW, SH, cr,
        rs(w:getX(), w:getY(), w:getWidth(), w:getHeight()), math.floor(w._drawerEffW or 0)))
end

-- ---- the card
local function card() local w = ww(); return w and w._drawerObject and w._objectCard or nil end
local function cardT()
    local w = ww()
    local e = w and w._drawerObject
    if e and e.def and e.def.id == "preview" then return e.t end
    return nil
end
local function cardHas(fid)
    local c = card()
    for _, z in ipairs(c and c._zones or {}) do if z.fid == fid then return true end end
    return false
end
local function stateOf(kind) local w = ww(); return (kind == "craft") and w._craftState or w._buildState end
local function curFace(t)
    local n = #(t.d and t.d.faces or {})
    if n == 0 then return nil, 0 end
    -- (the card's own expression, run here under the game's Lua: what the card shows for t.face)
    return t.d.faces[((t.face - 1) % n) + 1], n
end
local function faceSay(t)
    local f = curFace(t)
    return "face " .. tostring(t.face) .. " = " .. (f and ("'" .. tostring(f.name) .. "' (" .. #f.tiles .. " tiles)") or "nil (No picture)")
end

-- the recipe by its script name in the tab's own list (gatherData, as gallery_v3_zed.lua's Z.recipe)
local function findRd(kind, names)
    local mod = (kind == "craft") and ZeD.CraftingTab or ZeD.BuildingTab
    local ok, data = pcall(mod.gatherData, p, ww())
    local list = ok and data and data.recipes or {}
    for _, nm in ipairs(names) do
        local low = string.lower(nm)
        for _, rd in ipairs(list) do
            if rd.entry and string.lower(tostring(rd.entry.name)) == low then return rd, #list end
        end
    end
    return nil, #list
end

-- pick a recipe (the tab's open path), wait, then open its card by the icon stop and A; after(t) runs
-- once the card is still. names: the script names to try in order.
local function pickAndOpen(kind, names, label, after)
    local C = { skip = true }
    step(5, function()
        C.tab = check(worldTab(kind), label .. ": the World window's " .. kind .. " tab opened")
        if kind == "craft" then pcall(function() ZeD.Stations.unbind(p) end) end
    end)
    step(5, function()
        if not C.tab then return end
        local rd, n = findRd(kind, names)
        if not check(rd ~= nil, label .. ": the recipe is in the " .. kind .. " list (tried " .. table.concat(names, ", ") .. "; " .. tostring(n) .. " recipes listed)") then return end
        C.rd, C.skip = rd, false
        local st = stateOf(kind)
        if not check(st ~= nil, label .. ": the " .. kind .. " tab has its recipe state") then C.skip = true; return end
        if st.selected ~= rd.entry.name then CC.openCraft(st, rd.entry.name) end
        say(label .. ": picked " .. tostring(rd.entry.name) .. " ('" .. tostring(rd.entry.displayName) .. "'), status " .. tostring(rd.status))
    end)
    step(20, function() whenStill(function() end) end)
    step(5, function()
        if C.skip then return end
        local w = ww()
        local st = stateOf(kind)
        check(st._rdLast ~= nil and st._rdLast.entry == C.rd.entry, label .. ": the drawer shows the picked recipe's header (" .. tostring(st._rdLast and st._rdLast.entry and st._rdLast.entry.name) .. ")")
        Focus.claimFocus(w)
        local fid = kind .. ":icon"
        local el = Focus.focusWhere(w, "worldTabContent", function(e) return e.id == fid end)
        if check(el ~= nil and fz() == "worldTabContent" and fe() and fe().id == fid, label .. ": the header's icon is a controller stop (" .. fid .. ") and has the focus") then
            A()
        else
            say(label .. ": opening by CC.openPreview instead (the icon's own handler)")
            pcall(CC.openPreview, w, st, p)
        end
    end)
    step(20, function() whenStill(function()
        if C.skip then return end
        local t = cardT()
        if not check(t ~= nil and t.d ~= nil, label .. ": A on the icon opened the preview card (" .. tostring(t and t.entry and t.entry.name) .. ")") then return end
        local ok, e = pcall(after, t, C.rd)
        if not ok then say("ERR " .. label .. ": " .. tostring(e)) end
    end) end)
    return C
end

-- ---- setup
local bat
step(10, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() Mouse.setXY(20, 20) end)
    pcall(function() setGameSpeed(1) end)
    S.was.wtab = ww()._activeTab
    S.was.build = ww()._buildState and ww()._buildState.selected
    S.was.craft = ww()._craftState and ww()._craftState.selected
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    say(string.format("screen %dx%d, root %.2f, half card %d px, full card %d px; World tab was %s", SW, SH, ZeD.Scale.root(), T.px(220), T.px(480), tostring(S.was.wtab)))
end)

-- ===================================================================== 1. the big metal fence
local mf = pickAndOpen("build", { "MetalBigMetalFence", "BigMetalFence" }, "metal fence", function(t, rd)
    local w, c = ww(), card()
    local half = T.px(220)
    say(string.format("metal fence: card %s, drawer %d px (%s mode), the window %s", rs(c:getAbsoluteX(), c:getAbsoluteY(), c:getWidth(), c:getHeight()),
        math.floor(w._drawerEffW or 0), tostring(w._drawerMode), rs(w:getX(), w:getY(), w:getWidth(), w:getHeight())))
    check(c:isVisible() and math.abs(c:getWidth() - half) <= 1, "metal fence: the card is the half card (" .. c:getWidth() .. " px, half " .. half .. ")")
    check(w._drawerMode == "tab" and math.floor(w._drawerEffW or 0) > c:getWidth(), "metal fence: it lies over the Build drawer, the list behind it (drawer " .. math.floor(w._drawerEffW or 0) .. " px)")
    check(fz() == "worldItemCard", "metal fence: the focus went into the card (" .. tostring(fz()) .. ":" .. tostring(fe() and fe().id) .. ")")
    local face, n = curFace(t)
    local names = {}
    for _, f in ipairs(t.d.faces or {}) do
        local tl = {}
        for _, x in ipairs(f.tiles) do tl[#tl + 1] = tostring(x.tex and x.tex:getName()) end
        names[#names + 1] = "'" .. tostring(f.name) .. "': " .. table.concat(tl, " ")
    end
    say("metal fence: faces " .. n .. " | " .. table.concat(names, " | "))
    check(face ~= nil and #face.tiles > 0, "metal fence: the card shows tiles, not 'No picture for this one' (" .. faceSay(t) .. ")")
    -- Facing: > turns it, < turns it back, < again from the first face goes round to the last
    if check(n > 1 and cardHas("oc:faceL") and cardHas("oc:faceR"), "metal fence: a Facing row with < and > (" .. n .. " faces)") then
        local before = faceSay(t)
        local f0 = curFace(t)
        Focus.focusWhere(w, "worldItemCard", function(e) return e.id == "oc:faceR" end)
        local onR = fe() and fe().id == "oc:faceR"
        A()
        local f1 = curFace(t)
        check(onR and f1 ~= nil and f1 ~= f0, "metal fence: > turns it (" .. before .. " -> " .. faceSay(t) .. ")")
        Focus.focusWhere(w, "worldItemCard", function(e) return e.id == "oc:faceL" end)
        A()
        check(curFace(t) == f0, "metal fence: < turns it back (" .. faceSay(t) .. ")")
        A()
        local f3 = curFace(t)
        check(f3 ~= nil and f3 ~= f0, "metal fence: < from the first facing goes round to the last, with a picture (" .. faceSay(t) .. ")")
        Focus.focusWhere(w, "worldItemCard", function(e) return e.id == "oc:faceR" end)
        A()
        say("metal fence: back to " .. faceSay(t))
        local nm = f0 and f0.name or ""
        local keys = { N = "UI_ZeD_Track_CompassN", E = "UI_ZeD_Track_CompassE", S = "UI_ZeD_Track_CompassS", W = "UI_ZeD_Track_CompassW" }
        say("metal fence: the Facing row reads '" .. ZeD.tr("UI_ZeD_Preview_Facing", keys[nm] and ZeD.tr(keys[nm]) or nm) .. "'")
    end
    -- the game's words: the recipe's Tooltip through getText, <br> as a space
    local want
    pcall(function()
        local k = rd.entry.recipe:getTooltip()
        if k and k ~= "" then want = (getText(k):gsub("<br>", " ")) end
    end)
    check(want ~= nil and t.d.words == want, "metal fence: the game's own words ('" .. tostring(t.d.words) .. "'; the Tooltip reads '" .. tostring(want) .. "')")
    strengthCheck(t, rd, "metal fence")
    local perk = "?"
    pcall(function() perk = tostring(PerkFactory.getPerk(Perks.MetalWelding):getName()) end)
    check(t.d.skill == perk .. " 3", "metal fence: '" .. ZeD.tr("UI_ZeD_Preview_Skill") .. " " .. tostring(t.d.skill) .. "' (want Skill <the perk's own name> 3; the perk reads " .. perk .. ")")
    local v = t.verbs and t.verbs[1]
    local wantL = ZeD.btnCase and ZeD.btnCase(getText("IGUI_CraftingWindow_Build")) or getText("IGUI_CraftingWindow_Build")
    check(v ~= nil and v.label == wantL, "metal fence: the band's verb is " .. tostring(v and v.label) .. " (want " .. tostring(wantL) .. ")")
    if v then
        say("metal fence: the verb " .. (v.enabled and "can build now" or ("is folded with its need: '" .. tostring(v.needs) .. "'")) .. " (drawer status " .. tostring(rd.status) .. ", hasSkill " .. tostring(rd.hasSkill) .. ")")
        check(v.enabled or (v.needs ~= nil and v.needs ~= ""), "metal fence: a verb that cannot build says why (" .. tostring(v.needs) .. ")")
    end
    shot("build_metal_fence")
end)

-- ===================================================================== 2. B closes, focus back on the icon; a new pick closes it
step(5, function()
    S.bOk = (not mf.skip) and cardT() ~= nil
    if not S.bOk then say("B: no card open to close (the metal fence case did not open one): the B checks are skipped"); return end
    Focus.claimFocus(ww())
    if fz() ~= "worldItemCard" then Focus.focusWhere(ww(), "worldItemCard", function() return true end) end
    say("B from " .. tostring(fz()) .. ":" .. tostring(fe() and fe().id))
    B()
end)
step(15, function()
    if not S.bOk then return end
    check(card() == nil, "B closes the card (" .. tostring(ww()._drawerObject ~= nil and "still open" or "closed") .. ")")
    check(fz() == "worldTabContent" and fe() and fe().id == "build:icon", "the focus is back on the icon stop (" .. tostring(fz()) .. ":" .. tostring(fe() and fe().id) .. ")")
    -- open it again with A on the icon (the focus is there) for the next check
    if not (fe() and fe().id == "build:icon") then Focus.focusWhere(ww(), "worldTabContent", function(e) return e.id == "build:icon" end) end
    A()
end)
step(15, function()
    if not S.bOk then return end
    check(cardT() ~= nil, "A on the icon opens the card again")
    local rd = findRd("build", { "LogFence" })
    if rd then CC.handleRecipeClick(stateOf("build"), rd.entry.name) else CC.closeCraft(stateOf("build")) end
    say("picked another recipe with the card open: " .. tostring(rd and rd.entry.name or "(none found: the pick was closed instead)"))
end)
step(10, function()
    if not S.bOk then return end
    check(card() == nil, "picking another recipe closes the card (" .. tostring(ww()._drawerObject ~= nil and "still open" or "closed") .. ")")
end)

-- ===================================================================== 3. wooden strength: the log fence, the log gate
local function carpentry()
    local lvl = p:getPerkLevel(Perks.Woodwork) or 0
    local handy, how = false, "CharacterTrait.HANDY"
    local ok = pcall(function() handy = p:hasTrait(CharacterTrait.HANDY) and true or false end)
    if not ok then how = "HasTrait('Handy')"; pcall(function() handy = p:HasTrait("Handy") and true or false end) end
    return lvl, handy, lvl * 50 + (handy and 100 or 0), how
end
local function scriptHealth(rd)
    local h, b, bonus, rel = "?", "?", "?", "?"
    pcall(function()
        local l = BuildLogic.new(p, nil, nil)
        l:setRecipe(rd.entry.recipe)
        l:getAllBuildableRecipes()   -- (fills the recipe-to-entity lookup getSelectedBuildObject reads; Build, Nov 1 2026)
        local s = l:getSelectedBuildObject():getScript()
        h, b = s:getHealth(), s:getSkillBaseHealth()
        pcall(function() bonus = s:getBonusHealth() end)
    end)
    pcall(function() rel = rd.entry.recipe:getHighestRelevantSkillLevel(p) end)
    return h, b, bonus, rel
end
-- The strength line against the game's own formula (ObjectCardPreview, Build's second pass, Nov 1 2026):
-- max(health, 0) + bonusHealth x the sandbox Construction Bonus Points multiplier + the highest relevant skill level
-- x skillBaseHealth, shown as the total alone, or as "total (base + N from your Skill + bonus)" when there is more
-- than one part. The check: the leading number is the total, the parts show when there are several, and the skill
-- part names the perk.
strengthCheck = function(t, rd, label)
    local h, b, bonus, rel = scriptHealth(rd)
    local base = math.max(tonumber(h) or 0, 0)
    local sb, bo, lvl = tonumber(b) or 0, tonumber(bonus) or 0, tonumber(rel) or 0
    if bo > 0 then
        local okM, mult = pcall(function() return getSandboxOptions():getOptionByName("ConstructionBonusPoints"):getValue() end)
        local k = ({ [1] = 0.5, [2] = 0.7, [3] = 1.0, [4] = 1.3, [5] = 1.5 })[okM and mult or 3] or 1.0
        bo = math.floor(bo * k + 0.5)
    end
    local skill = (sb > 0) and lvl * sb or 0
    local total = base + bo + skill
    local got = tostring(t.d.strength)
    local lead = tonumber(got:match("^(%d+)"))
    local parts = (base > 0 and 1 or 0) + (skill > 0 and 1 or 0) + (bo > 0 and 1 or 0)
    local hasParen = got:find("(", 1, true) ~= nil
    local okForm = (parts > 1 and hasParen) or (parts <= 1)   -- (a zero skill part shown as "+ 0 from your " is noted, not failed)
    local perk = ""
    pcall(function() perk = tostring(rd.entry.recipe:getHighestRelevantSkill(p):getName()) end)
    local okSkill = (skill <= 0) or (got:find("from your", 1, true) ~= nil and (perk == "" or got:find(perk, 1, true) ~= nil))
    if skill <= 0 and got:find("from your", 1, true) then say("NOTE " .. label .. ": a zero skill part is shown ('" .. got .. "'); the perk's name reads '" .. perk .. "'") end
    say(string.format("%s: the script's health %s, skillBaseHealth %s, bonusHealth %s; relevant skill level %s (%s): the game's build gives %d = %d + %d (skill) + %d (bonus)",
        label, tostring(h), tostring(b), tostring(bonus), tostring(rel), perk, total, base, skill, bo))
    check(lead == total and okForm and okSkill, label .. ": 'Strength " .. got .. "' (want the game's " .. total .. (parts > 1 and " with its parts" or "") .. ")")
end
local function woodCase(names, label, base)
    pickAndOpen("build", names, label, function(t, rd)
        local lvl, handy, n, how = carpentry()
        say(string.format("%s: Carpentry %d, Handy %s (%s): the punch list's first-pass N would be %d", label, lvl, tostring(handy), how, n))
        strengthCheck(t, rd, label)
    end)
end
woodCase({ "LogFence" }, "log fence", 200)
woodCase({ "LogGate" }, "log gate", 300)

-- ===================================================================== 4. a plank barricade: no strength line
pickAndOpen("build", { "BarricadePlanks" }, "plank barricade", function(t, rd)
    check(t.d.strength == nil, "plank barricade: no strength line (" .. tostring(t.d.strength) .. ")")
    say("plank barricade: " .. faceSay(t) .. ", skill " .. tostring(t.d.skill) .. ", words '" .. tostring(t.d.words) .. "'")
end)

-- ===================================================================== 5. a double gate: the tiles on several squares
pickAndOpen("build", { "DoubleFenceGate", "DoubleWireGate", "DoubleDoor" }, "double gate", function(t, rd)
    local best = 0
    for i, f in ipairs(t.d.faces or {}) do
        local minX, maxX, minY, maxY, maxZ = 99, -99, 99, -99, 0
        local cells = {}
        for _, tl in ipairs(f.tiles) do
            if tl.x < minX then minX = tl.x end
            if tl.x > maxX then maxX = tl.x end
            if tl.y < minY then minY = tl.y end
            if tl.y > maxY then maxY = tl.y end
            if tl.z > maxZ then maxZ = tl.z end
            cells[#cells + 1] = string.format("(%d,%d,%d)%s", tl.x, tl.y, tl.z, tostring(tl.tex and tl.tex:getName()))
        end
        local span = math.max(maxX - minX + 1, maxY - minY + 1)
        if #f.tiles > best then best = #f.tiles end
        say(string.format("double gate: face %d '%s': %d tiles, %dx%d squares, %d storeys: %s", i, tostring(f.name), #f.tiles,
            maxX - minX + 1, maxY - minY + 1, maxZ + 1, table.concat(cells, " ")))
        if i == 1 then check(#f.tiles >= 2 and span >= 2, "double gate: the first face shows whole, on several squares (" .. #f.tiles .. " tiles, " .. span .. " squares long)") end
    end
    check(best >= 4, "double gate: a face of four tiles (the gate's script rows; most " .. best .. ")")
    shot("build_double_gate")
end)
-- close the Build pick (the card goes with it)
step(5, function()
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    pcall(CC.closeCraft, stateOf("build"))
end)

-- ===================================================================== 6. Craft: the spiked bat against the carried bat
step(5, function()
    bat = p:getInventory():AddItem("Base.BaseballBat")
    say("a baseball bat carried: " .. tostring(bat and bat:getDisplayName()) .. ", condition " .. tostring(bat and bat:getCondition()) .. "/" .. tostring(bat and bat:getConditionMax())
        .. ", weight " .. tostring(bat and bat:getActualWeight()))
end)
local function changeOf(t, label)
    for _, ch in ipairs(t.d.changes or {}) do if ch.label == label then return ch end end
    return nil
end
pickAndOpen("craft", { "MakeSpikedBaseballBat", "RailspikeBaseballBat" }, "spiked bat", function(t, rd)
    local d = t.d
    local facts = {}
    for _, f in ipairs(d.facts or {}) do facts[#facts + 1] = tostring(f.label) .. " " .. tostring(f.value) end
    say("spiked bat: What you get: " .. tostring(d.outName) .. " (" .. tostring(d.cat) .. "): " .. table.concat(facts, ", ") .. "; weight " .. tostring(d.weight))
    check(d.outName ~= nil and #(d.facts or {}) > 0, "spiked bat: 'What you get' with the item's facts (" .. #(d.facts or {}) .. " facts)")
    local chs = {}
    for _, ch in ipairs(d.changes or {}) do chs[#chs + 1] = ch.label .. " " .. ch.old .. " -> " .. ch.new .. (ch.pct and string.format(" (%+d%%)", ch.pct) or "") end
    say("spiked bat: What changes against '" .. tostring(d.baseName) .. "': " .. (#chs > 0 and table.concat(chs, "; ") or "(none)"))
    local batName = bat and bat:getDisplayName()
    check(d.base ~= nil and d.base:getFullType() == "Base.BaseballBat", "spiked bat: 'What changes' is against the carried bat (" .. tostring(d.baseName) .. ", " .. tostring(d.base and d.base:getFullType()) .. "; the bat is " .. tostring(batName) .. ")")
    local dmg = changeOf(t, "Damage")
    check(dmg ~= nil and dmg.pct ~= nil, "spiked bat: Damage changes, with the step (" .. tostring(dmg and (dmg.old .. " -> " .. dmg.new)) .. ", " .. tostring(dmg and dmg.pct) .. "%)")
    local cond = changeOf(t, "Condition")
    local outMax
    pcall(function() outMax = instanceItem("Base.BaseballBat_Spiked"):getConditionMax() end)
    check(cond ~= nil, "spiked bat: Condition in What changes (" .. tostring(cond and (cond.old .. " -> " .. cond.new)) .. "; the bat " .. tostring(bat and bat:getCondition()) .. "/"
        .. tostring(bat and bat:getConditionMax()) .. ", the spiked bat's most " .. tostring(outMax) .. ")")
    local wt = changeOf(t, ZeD.tr("UI_ZeD_Preview_Weight"))
    check(wt ~= nil, "spiked bat: Weight in What changes (" .. tostring(wt and (wt.old .. " -> " .. wt.new)) .. ")")
    shot("craft_spiked_bat")
end)

-- ===================================================================== 7. a recipe with several results: "or one of N others"
pickAndOpen("craft", { "NailSpikeWeapon" }, "several results", function(t, rd)
    local distinct, list = 0, {}
    pcall(function()
        local seen = {}
        local outs = rd.entry.recipe:getOutputs()
        local items = outs:get(0):getPossibleResultItems()
        for i = 0, items:size() - 1 do
            local ft = items:get(i):getFullType()
            if not seen[ft] then seen[ft] = true; distinct = distinct + 1; list[#list + 1] = ft end
        end
    end)
    say("several results: " .. tostring(rd.entry.name) .. " makes " .. distinct .. ": " .. table.concat(list, ", ") .. "; the card shows " .. tostring(t.d.outName))
    local want = math.max(0, distinct - 1)
    check((tonumber(t.d.others) or 0) > 0, "several results: '" .. ZeD.tr("UI_ZeD_Preview_OneOf", tostring(t.d.others)) .. "' (the card counts " .. tostring(t.d.others) .. " others; the script's own count read " .. tostring(want) .. ")")
    say("several results: What changes against '" .. tostring(t.d.baseName) .. "' (" .. #(t.d.changes or {}) .. " changes)")
end)

-- ===================================================================== put everything back
step(10, function()
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    local w = ww()
    for _, k in ipairs({ "build", "craft" }) do
        local st = stateOf(k)
        if st then
            if S.was[k] then pcall(CC.openCraft, st, S.was[k]) else pcall(CC.closeCraft, st) end
        end
    end
    if bat then
        local c = bat:getContainer()
        if c then pcall(function() c:Remove(bat) end) end
    end
    worldTab(S.was.wtab or "loot")
end)
step(30, function() whenStill(function()
    check(card() == nil, "put back: no card open")
    check(bat == nil or bat:getContainer() == nil, "put back: the bat taken away")
    say("put back: World tab " .. tostring(ww()._activeTab) .. " (was " .. tostring(S.was.wtab) .. "), Build pick " .. tostring(stateOf("build") and stateOf("build").selected)
        .. ", Craft pick " .. tostring(stateOf("craft") and stateOf("craft").selected))
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say(passes .. " passed")
    say(fails == 0 and "all passed" or (fails .. " FAILED"))
    say("DONE")
end) end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
say("start")
