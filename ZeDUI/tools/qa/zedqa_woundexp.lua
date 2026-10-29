-- ZeDUI/tools/qa/zedqa_woundexp.lua  (Oct 29 2026)
-- With Wound Expansion on (mod list woundexp_mods.txt): the Health tab's detail view
-- carries the mod's own wound words (ModSupport/WoundExpansion.lua through the new
-- general hook ZeD.HealthTab.addExtras). The mod keeps its wounds per body part in
-- the character's modData; this script gives one arm part a Sprain (a wound) and a
-- Bruised (a condition) through the mod's own functions (WoundExpansion.Core.addWound
-- / addCondition: they skip the god-mode guard the prelude's god mode would trip, and
-- add no pain or bleeding), then checks:
--   * the extra is registered (with the mod off the tab has no such extra: the script
--     says so and ends);
--   * before: the part has no lines;
--   * the lines are the mod's own words (getText of its keys) in the order the mod
--     writes them (wounds, then conditions), with colours;
--   * the tab's data carries them (gatherData extraByFigureName), the injury list has
--     the part with both words as tags, and the summary counts it as injured;
--   * the detail view on the controller's focus on that part shows them (the tab
--     stamps win._healthExtraShown), screenshot zqa_wx_part.png;
--   * the mod's treatment entries reach the menu ZeD opens for the part (the stand-in
--     panel's getPatient): opening it raises no error, and "Splint" (the mod's entry for
--     a sprained limb) is among the options (logged; a missing entry is a FAIL);
--   * healed back (the mod's WoundExpansion.clearPart; a part the mod had no record of
--     gets that empty record removed again): the lines, the tags and the detail view's
--     lines are gone.
-- Puts everything back (wounds, the part's record, focus, input mode, tab). grep "ZEDQA wx".
local function say(s) print("ZEDQA wx " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_wx_" .. n .. ".png") end) end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function ok(label, cond) say((cond and "ok   " or "FAIL ") .. label) end
local P = getPlayer()
local pn = P:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local H = ZeD.HealthTab
local M = ZeD.ModSupport and ZeD.ModSupport.WoundExpansion

-- the parts to try, the first the mod has no record on: figure name, game part type
local CANDIDATES = {
    { fig = "Left Forearm",  bp = BodyPartType.ForeArm_L },
    { fig = "Right Forearm", bp = BodyPartType.ForeArm_R },
    { fig = "Left Upper Arm", bp = BodyPartType.UpperArm_L },
    { fig = "Right Upper Arm", bp = BodyPartType.UpperArm_R },
}
local part, index, hadEntry = nil, nil, nil
local sprainWord, bruisedWord, splintWord = nil, nil, nil
local added = false

local function has(list, text)
    for _, s in ipairs(list or {}) do if s == text then return true end end
    return false
end

-- the rows of the menu that is up now: the game's list and ZeD's rows, by name
local function menuNames()
    local names = {}
    local ctx = getPlayerContextMenu(pn)
    if not ctx then return names end
    for _, o in ipairs(ctx.options or {}) do
        if o.name then names[#names + 1] = tostring(o.name) end
    end
    local lv = ctx._zedMenu and ctx._zedMenu._levels and ctx._zedMenu._levels[1]
    for _, r in ipairs(lv and lv.rows or {}) do
        if r.def and r.def.name then names[#names + 1] = tostring(r.def.name) end
    end
    return names
end
local function closeMenu()
    pcall(function()
        local ctx = getPlayerContextMenu(pn)
        if ctx and ctx._zedMenu then ctx._zedMenu:close() end
        if ctx and ctx:isVisible() then ctx:closeAll() end
    end)
end

-- the wounds away, the part's record as it was; safe to call twice
local function restore()
    local WE = WoundExpansion
    if not (WE and index) then return end
    pcall(function()
        if added then WE.clearPart(P, index) end
        if added and not hadEntry then WE.Core.root(P).parts[index] = nil end
        WE.Core.touchState(index)
    end)
    added = false
end

at(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    local ids = {}
    for _, e in ipairs(H.extras or {}) do ids[#ids + 1] = tostring(e.id) end
    say("health extras " .. #ids .. " [" .. table.concat(ids, ", ") .. "] | mod support " .. tostring(M ~= nil) .. " | the mod's table " .. tostring(WoundExpansion ~= nil))
    if M then
        local found = false
        for _, e in ipairs(H.extras) do if e.id == "WoundExpansion" then found = true end end
        ok("the extra is registered", found)
    end
end)

-- pick the part, check it is bare
at(10, function()
    if not (M and WoundExpansion) then say("mod off: no extra, nothing to check"); return end
    local WE = WoundExpansion
    for _, c in ipairs(CANDIDATES) do
        local bp = P:getBodyDamage():getBodyPart(c.bp)
        local entry = bp and WE.Core.peekPart(P, bp:getIndex())
        local bare = (not entry) or (table.isempty(entry.wounds) and table.isempty(entry.conditions))
        if bp and bare then part = c; index = bp:getIndex(); hadEntry = entry ~= nil; break end
    end
    ok("a bare arm part to use", part ~= nil)
    if not part then return end
    sprainWord = getText("IGUI_WE_Wound_Sprain")
    bruisedWord = getText("IGUI_WE_Cond_Bruised")
    splintWord = getText("ContextMenu_WE_SplintSprain")
    say("part " .. part.fig .. " (index " .. tostring(index) .. ") | mod record before: " .. tostring(hadEntry)
        .. " | words: " .. sprainWord .. ", " .. bruisedWord .. ", " .. splintWord)
    local bp = P:getBodyDamage():getBodyPart(part.bp)
    ok("before: no lines for the bare part", M.partLines(P, bp) == nil)
    ok("before: the tab's data has none either", H.gatherData(P).extraByFigureName[part.fig] == nil)
end)

-- give the part the wounds, through the mod's own functions
at(20, function()
    if not part then return end
    local WE = WoundExpansion
    WE.Core.addWound(P, index, WE.WOUND.SPRAIN, { hoursLeft = WE.Config.SPRAIN_HOURS })
    WE.Core.addCondition(P, index, WE.CONDITION.BRUISED, { hours = 0 })
    added = true
    say("added Sprain and Bruised to " .. part.fig)
end)

-- the data
at(30, function()
    if not part then return end
    local bp = P:getBodyDamage():getBodyPart(part.bp)
    local lines = M.partLines(P, bp)
    local words = {}
    for _, l in ipairs(lines or {}) do words[#words + 1] = l.text .. "[" .. tostring(l.severity) .. "]" end
    say("the mod's lines: " .. table.concat(words, ", "))
    ok("two lines", lines ~= nil and #lines == 2)
    ok("first the wound in the mod's word (" .. sprainWord .. ")", lines ~= nil and lines[1] and lines[1].text == sprainWord)
    ok("then the condition in the mod's word (" .. bruisedWord .. ")", lines ~= nil and lines[2] and lines[2].text == bruisedWord)
    ok("each has a colour", lines ~= nil and #lines == 2 and lines[1].color.r ~= nil and lines[2].color.g ~= nil)
    if lines and #lines == 2 then
        say(string.format("colours: %s %.2f,%.2f,%.2f | %s %.2f,%.2f,%.2f", lines[1].text, lines[1].color.r, lines[1].color.g, lines[1].color.b,
            lines[2].text, lines[2].color.r, lines[2].color.g, lines[2].color.b))
    end
    local d = H.gatherData(P)
    local ex = d.extraByFigureName[part.fig]
    ok("the tab's data carries both lines", ex ~= nil and #ex == 2)
    local entry
    for _, e in ipairs(d.entries) do if e.name == part.fig then entry = e end end
    ok("the injury list has the part", entry ~= nil)
    if entry then
        local labels = {}
        for _, c in ipairs(entry.conditions) do labels[#labels + 1] = c.label end
        say("list tags: " .. table.concat(labels, ", "))
        ok("the list tags carry the mod's words", has(labels, sprainWord) and has(labels, bruisedWord))
    end
    ok("counted as injured", (d.woundedCount or 0) >= 1)
    -- the tab, on the part, on the controller's focus
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.claimFocus(cw()); tab("health")
    cw()._healthFigureExpanded = true
end)
at(60, function()
    if not part then return end
    local W = cw()
    local f = Focus.focusWhere(W, "charTabContent", function(e) return e.partName == part.fig end)
    say("focus on " .. part.fig .. " " .. tostring(f ~= nil))
end)
at(100, function()
    if not part then return end
    local W = cw()
    say("tab " .. tostring(W._activeTab) .. " | active part " .. tostring(W._healthActivePart) .. " | extra lines shown " .. tostring(W._healthExtraShown))
    ok("the detail view is on the part", W._healthActivePart == part.fig)
    ok("the detail view shows the mod's two lines", W._healthExtraShown == 2)
    shot("part")
end)

-- the treatments: the menu ZeD opens for the part, with the mod's entries in it
at(110, function()
    if not part then return end
    local okOpen, err = pcall(H._onPartClicked, cw(), part.fig, nil, nil, nil)
    ok("opening the part's menu raises no error" .. (okOpen and "" or " (" .. tostring(err) .. ")"), okOpen)
end)
at(125, function()
    if not part then return end
    local names = menuNames()
    say("menu rows: " .. table.concat(names, ", "))
    local low = {}
    for _, n in ipairs(names) do low[#low + 1] = string.lower(n) end
    ok("the mod's '" .. splintWord .. "' entry is in the menu", has(low, string.lower(splintWord)))
    shot("menu")
    closeMenu()
end)

-- heal back and check the lines go
at(140, function()
    if not part then return end
    restore()
end)
at(160, function()
    if not part then return end
    local bp = P:getBodyDamage():getBodyPart(part.bp)
    ok("healed: no lines", M.partLines(P, bp) == nil)
    local d = H.gatherData(P)
    ok("healed: the tab's data has none", d.extraByFigureName[part.fig] == nil)
    local listed = false
    for _, e in ipairs(d.entries) do
        if e.name == part.fig then
            for _, c in ipairs(e.conditions) do if c.label == sprainWord or c.label == bruisedWord then listed = true end end
        end
    end
    ok("healed: no tags from the mod in the list", not listed)
end)
at(190, function()
    if part then
        local W = cw()
        say("healed: extra lines shown " .. tostring(W._healthExtraShown))
        ok("healed: the detail view shows none", W._healthExtraShown == 0)
        shot("healed")
    end
end)
at(200, function()
    restore()
    closeMenu()
    tab("loot")
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    Focus.releaseFocus()
    say("DONE")
end)

local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok2, e = pcall(s.fn)
            if not ok2 then say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if tick > 205 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
