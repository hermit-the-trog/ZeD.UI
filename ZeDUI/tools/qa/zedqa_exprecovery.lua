-- ZeDUI/tools/qa/zedqa_exprecovery.lua  (Oct 29 2026)
-- With Exp Recovery for Skill Books on (mod list exprecovery_mods.txt): the Skills
-- tab's strip and hover card (ModSupport/ExpRecovery.lua through
-- ZeD.SkillsTab.addExtras). The mod keeps the XP a skill book would have given but
-- the character missed in the character's modData ("ExpRecovery", per skill, five
-- numbers, one per book stage), so this script writes two skills' numbers there (it
-- needs no book read), then checks:
--   * the extra is registered (with the mod off the tab has no extras: the script
--     says so and ends);
--   * the mod's own function (ExpRecovery.getMissedExpForBook, given a stage-1 book
--     of the skill) reads the same number ZeD does;
--   * a staged skill gets a strip (or, with Skill Recovery Journal's support also
--     present, correctly none: that one holds the lane), its shares add up to 1,
--     grey comes first and blue last, and a skill with no saved XP gets none;
--   * the hover card on the controller's focus lists the saved XP per stage and the
--     total.
-- Takes zqa_xr_skills.png (the strips) and zqa_xr_card_pad.png (the card). Puts the
-- modData back as it was (the table made here is removed again). grep "ZEDQA xr".
local function say(s) print("ZEDQA xr " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_xr_" .. n .. ".png") end) end
local function strip(w, s, id) for _, z in ipairs(s._hitZones or {}) do if z.id == "tab:" .. id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local M = ZeD.ModSupport and ZeD.ModSupport.ExpRecovery
local P = nil
local staged = {}          -- { { perk, id, key, numbers } ... } the skills written to
local madeTable = false    -- did the mod's table not exist before this script?
local prior = {}           -- id -> a copy of the numbers that were there, or false
local focusName = nil

-- the row of a skill on the tab, by the skill's id
local function rowOf(id)
    for _, z in ipairs((cw() and cw()._skillRowZones) or {}) do
        if z.skill and z.skill.perk and z.skill.perk:getId() == id then return z end
    end
    return nil
end

-- the perk object in PerkFactory.PerkList for what the mod calls its perk (a perk or its type)
local function perkOf(p)
    if not p then return nil end
    for i = 0, PerkFactory.PerkList:size() - 1 do
        local q = PerkFactory.PerkList:get(i)
        if q == p or q:getType() == p then return q end
    end
    return nil
end

-- put the modData back exactly as it was; safe to call twice
local function restore()
    if not P then return end
    local md = P:getModData()
    if madeTable then
        md["ExpRecovery"] = nil
    else
        for id, was in pairs(prior) do
            if was then md["ExpRecovery"][id] = { was[1], was[2], was[3], was[4], was[5] }
            else md["ExpRecovery"][id] = nil end
        end
    end
    prior, staged, madeTable = {}, {}, false
end

at(2, function()
    P = getPlayer()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    local ids = {}
    for _, e in ipairs(ZeD.SkillsTab.extras or {}) do ids[#ids + 1] = tostring(e.id) end
    say("extras " .. #ids .. " [" .. table.concat(ids, ", ") .. "] | mod support " .. tostring(M ~= nil) .. " | the mod's table " .. tostring(ExpRecovery ~= nil))
    if M then
        local found = false
        for _, e in ipairs(ZeD.SkillsTab.extras) do if e.id == "ExpRecovery" then found = true end end
        if not found then say("FAIL the extra is not registered") end
    end
end)
at(20, function()
    strip(cw(), cw()._tabStripPanel, "skills")
    cw()._skillsGridExpanded = true
end)
-- stage the numbers: the first two skills (in name order) the character has between level 1 and 9
-- that have a stage-1 book to read the mod's own function with
at(30, function()
    if not M then say("mod off: no strips, no card"); return end
    local keys = {}
    for k in pairs(SkillBook or {}) do keys[#keys + 1] = k end
    table.sort(keys)
    local md = P:getModData()
    local amounts = { { 60, 120, 90, 0, 0 }, { 40, 0, 0, 0, 0 } }
    for _, key in ipairs(keys) do
        if #staged < 2 then
            local perk = perkOf(SkillBook[key].perk)
            local lvl = perk and P:getPerkLevel(perk:getType()) or 0
            local okI, book = pcall(instanceItem, "Base.Book" .. key .. "1")
            if perk and lvl >= 1 and lvl <= 9 and okI and book and book:getSkillTrained() == key then
                if not md["ExpRecovery"] then md["ExpRecovery"] = {}; madeTable = true end
                local id = perk:getId()
                local was = md["ExpRecovery"][id]
                prior[id] = was and { was[1], was[2], was[3], was[4], was[5] } or false
                local n = amounts[#staged + 1]
                md["ExpRecovery"][id] = { n[1], n[2], n[3], n[4], n[5] }
                staged[#staged + 1] = { perk = perk, id = id, key = key, book = book, n = n }
                say(string.format("staged %s (level %d): %d, %d, %d, %d, %d", perk:getName(), lvl, n[1], n[2], n[3], n[4], n[5]))
            end
        end
    end
    if #staged == 0 then say("FAIL no skill between level 1 and 9 with a skill book to stage") end
    focusName = staged[1] and staged[1].perk:getName()
end)
at(60, function()
    if not M then return end
    local journalLane = false
    for _, e in ipairs(ZeD.SkillsTab.extras) do if e.id == "SkillRecoveryJournal" then journalLane = true end end
    for _, st in ipairs(staged) do
        local want = 0
        for i = 1, 5 do want = want + st.n[i] end
        -- ZeD's reading against the mod's own function (stage 1 book)
        local d, total = M.saved(P, st.perk)
        local theirs = ExpRecovery and ExpRecovery.getMissedExpForBook and ExpRecovery.getMissedExpForBook(P, st.book)
        say(string.format("%s: ZeD reads total %s | the mod's getMissedExpForBook (stage 1 book) %s | staged %d, stage 1 %d",
            st.perk:getName(), tostring(total), tostring(theirs), want, st.n[1]))
        if total ~= want then say("FAIL " .. st.perk:getName() .. ": total differs from what was staged") end
        if theirs ~= st.n[1] then say("FAIL " .. st.perk:getName() .. ": the mod reads a different stage-1 number") end
        local z = rowOf(st.id)
        if not z then
            say("FAIL " .. st.perk:getName() .. ": no row on the tab")
        else
            local L = M.X.lane(P, st.perk, z.skill.level, z.skill.xpProgress)
            if journalLane then
                say(st.perk:getName() .. ": Skill Recovery Journal's support holds the lane, strip is " .. tostring(L))
                if L then say("FAIL the strip should step aside for the journal's") end
            elseif not L then
                say("FAIL " .. st.perk:getName() .. ": no strip")
            else
                local sum, parts = 0, {}
                for _, sg in ipairs(L.segs) do
                    sum = sum + sg.share
                    parts[#parts + 1] = string.format("%.3f(%.2f,%.2f,%.2f)", sg.share, sg.color.r, sg.color.g, sg.color.b)
                end
                local a, b = M.reach(st.perk, z.skill.level, z.skill.xpProgress, total)
                say(string.format("%s lv%d progress %.2f: strip span %.3f (reach %.2f to %.2f of 10), segments %s, row h %s",
                    st.perk:getName(), z.skill.level, z.skill.xpProgress, L.span, a or -1, b or -1, table.concat(parts, " "), tostring(z.h)))
                if math.abs(sum - 1) > 0.001 then say("FAIL the shares do not add up to 1") end
                local last = L.segs[#L.segs]
                if last.color.b < 0.9 or last.color.r > 0.4 then say("FAIL the last part is not blue") end
                if b and math.abs(L.span * 10 - b) > 0.001 then say("FAIL the span is not the reach") end
            end
        end
    end
    -- a skill with no saved XP gets none
    for i = 0, PerkFactory.PerkList:size() - 1 do
        local perk = PerkFactory.PerkList:get(i)
        if perk:getParent() ~= Perks.None and P:getPerkLevel(perk:getType()) > 0 then
            local isStaged = false
            for _, st in ipairs(staged) do if st.id == perk:getId() then isStaged = true end end
            local d = M.saved(P, perk)
            if not isStaged and not d then
                local L = M.X.lane(P, perk, P:getPerkLevel(perk:getType()), 0.5)
                say(perk:getName() .. " (no saved XP): strip " .. tostring(L))
                if L then say("FAIL a strip for a skill with no saved XP") end
                break
            end
        end
    end
end)
-- the hover card on the controller's focus (the mouse path draws the same card)
at(90, function()
    if not M or not focusName then return end
    local W = cw()
    ZeD.Input.Detector.setLockedMode("gamepad")
    ZeD.Input.Focus.claimFocus(W)
    local ok = ZeD.Input.Focus.focusWhere(W, "charTabContent", function(e) return e.skillName == focusName end)
    say("focus on " .. tostring(focusName) .. " " .. tostring(ok ~= nil))
end)
at(140, function()
    if not M or not focusName then return end
    local W = cw()
    for _, z in ipairs(W._skillRowZones or {}) do
        if z.name == focusName and z.skill then
            local c = M.X.card(P, z.skill.perk, z.skill)
            if c then
                local parts = {}
                for _, l in ipairs(c.lines) do parts[#parts + 1] = l.text .. "=" .. tostring(l.value) end
                say("card " .. focusName .. ": " .. tostring(c.label) .. " | " .. table.concat(parts, "; ") .. " | " .. tostring(c.note))
                local hasTotal = false
                for _, l in ipairs(c.lines) do if l.total then hasTotal = true end end
                if #c.lines < 2 or (not hasTotal and not ZeD.ModSupport.SkillRecoveryJournal) then say("FAIL the card is missing its lines or total") end
            else
                say("FAIL card " .. focusName .. ": none")
            end
        end
    end
    say("pad card up for " .. tostring(ZeD.SkillsTab._cardShown))
    if ZeD.SkillsTab._cardShown ~= focusName then say("FAIL the hover card is not up on the focused row") end
    shot("card_pad")
end)
-- the strips, with the card away (the focus scrolled the row into view)
at(160, function() ZeD.Input.Detector.setLockedMode(nil) end)
at(200, function() if M then shot("skills") end end)
-- everything back as it was; the strip is gone with the numbers
at(220, function()
    if M and staged[1] then
        local st = staged[1]
        restore()
        local z = rowOf(st.id)
        local L = z and M.X.lane(P, st.perk, z.skill.level, z.skill.xpProgress)
        say("restored: saved XP for " .. st.perk:getName() .. " now " .. tostring(M.saved(P, st.perk)) .. ", strip " .. tostring(L) .. ", table kept " .. tostring(P:getModData()["ExpRecovery"] ~= nil))
        if L then say("FAIL the strip is still there after the numbers were removed") end
    else
        restore()
    end
    strip(cw(), cw()._tabStripPanel, "loot")
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 230 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
