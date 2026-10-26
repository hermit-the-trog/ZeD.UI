-- ZeDUI/tools/qa/zedqa_srj.lua  (Oct 26 2026)
-- With Skill Recovery Journal on (srj via mapmods_mods.txt): the Skills tab's
-- strip, key line and hover card (ModSupport/SkillRecoveryJournal.lua through
-- ZeD.SkillsTab.addExtras). Logs the mod's four numbers for every skill with a
-- strip; the key line with no journal, then with a Bound Journal in the main
-- inventory and in a bag (each taken back); the hover card on the controller's
-- focus (the mouse path draws the same card); the grid folded (no key, no
-- strips); the pinned title stays text. With the mod off the tab has no extras
-- (the script says so and ends). Captures zqa_srj_<name>.png. grep "ZEDQA srj".
local function say(s) print("ZEDQA srj " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_srj_" .. n .. ".png") end) end
local function strip(w, s, id) for _, z in ipairs(s._hitZones or {}) do if z.id == "tab:" .. id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local M = ZeD.ModSupport and ZeD.ModSupport.SkillRecoveryJournal
local P, journal, bag, focusName = nil, nil, nil, nil

at(2, function()
    P = getPlayer()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    say("extras " .. #(ZeD.SkillsTab.extras or {}) .. " | mod support " .. tostring(M ~= nil))
end)
at(20, function()
    strip(cw(), cw()._tabStripPanel, "skills")
    cw()._skillsGridExpanded = true
    -- no journal on the character for the first picture
    local inv = P:getInventory()
    say("journal carried at start: " .. tostring(inv:getFirstTypeRecurse("SkillRecoveryBoundJournal") ~= nil))
end)
at(60, function()
    if not M then say("mod off: no strips, no key line, no card"); return end
    local n, red = 0, 0
    for i = 0, PerkFactory.PerkList:size() - 1 do
        local perk = PerkFactory.PerkList:get(i)
        if perk:getParent() ~= Perks.None and P:getPerkLevel(perk:getType()) > 0 then
            local a = M.amounts(P, perk)
            if a then
                n = n + 1
                if a.deficitXP > 0 then red = red + 1 end
                say(string.format("%s lv%d: start %d (%.0f) unrec %.0f rec %.0f notwritten %.0f total %.0f", perk:getName(), P:getPerkLevel(perk:getType()),
                    a.startingLevel, a.settledXP, a.deductedXP, a.greenXP, a.deficitXP, a.totalXP))
            else
                say(perk:getName() .. ": not recorded by the mod (no strip)")
            end
        end
    end
    say("skills with a strip " .. n .. ", with red " .. red)
    local z = cw()._skillRowZones or {}
    say("rows " .. #z .. " row height " .. tostring(z[1] and z[1].h))
    shot("none")
end)
at(80, function()
    if not M then return end
    journal = P:getInventory():AddItem("Base.SkillRecoveryBoundJournal")
    say("journal added: " .. tostring(journal and journal:getDisplayName()))
end)
at(110, function()
    if not M then return end
    local j = M.journal(P)
    say("key line: journal " .. tostring(j and j.where) .. " by " .. tostring(j and j.who))
    shot("main")
    -- into a bag, if one is worn
    local inv = P:getInventory()
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "InventoryContainer") and it:isEquipped() then bag = it; break end
    end
    if bag and journal then
        inv:Remove(journal); bag:getItemContainer():AddItem(journal)
    end
end)
at(140, function()
    if not M then return end
    local j = M.journal(P)
    say("in a bag: " .. tostring(j and j.where) .. (bag and "" or " (no bag worn)"))
    -- the hover card on the controller's focus: the first skill with red, else the first row
    local W = cw()
    for _, z in ipairs(W._skillRowZones or {}) do
        local a = z.skill and z.skill.perk and M.amounts(P, z.skill.perk)
        if a and a.deficitXP > 0 and z.skill.level > 0 then focusName = z.name; break end
    end
    focusName = focusName or (W._skillRowZones[1] and W._skillRowZones[1].name)
    ZeD.Input.Detector.setLockedMode("gamepad")
    ZeD.Input.Focus.claimFocus(W)
    local ok = ZeD.Input.Focus.focusWhere(W, "charTabContent", function(e) return e.skillName == focusName end)
    say("focus on " .. tostring(focusName) .. " " .. tostring(ok ~= nil))
end)
at(170, function()
    if not M then return end
    local W = cw()
    for _, z in ipairs(W._skillRowZones or {}) do
        if z.name == focusName and z.skill then
            local c = M.X.card(P, z.skill.perk, z.skill)
            if c then
                local parts = {}
                for _, l in ipairs(c.lines) do parts[#parts + 1] = l.text .. "=" .. tostring(l.value) end
                say("card " .. focusName .. ": " .. table.concat(parts, "; ") .. " | " .. tostring(c.note))
            else
                say("card " .. focusName .. ": none")
            end
        end
    end
    local F = ZeD.Input.Focus
    local fe = F.getFocusedElement and F.getFocusedElement(W)
    say("pad card: mode " .. tostring(ZeD.Input.Detector.getMode()) .. " focused window is Character " .. tostring(F.getFocusedWindow() == W)
        .. " element " .. tostring(fe and fe.skillName) .. " card up " .. tostring(ZeD.SkillsTab._cardShown))
    if ZeD.SkillsTab._cardShown ~= focusName then say("FAIL the hover card is not up on the focused row") end
    shot("card_pad")
end)
at(190, function()
    ZeD.Input.Detector.setLockedMode(nil)
    -- the journal away: the card's last sentence points at it
    if journal and journal:getContainer() then journal:getContainer():Remove(journal) end
    journal = nil
end)
at(220, function()
    if not M then return end
    ZeD.Input.Detector.setLockedMode("gamepad")
    ZeD.Input.Focus.focusWhere(cw(), "charTabContent", function(e) return e.skillName == focusName end)
end)
at(250, function() if M then shot("card_none") end; ZeD.Input.Detector.setLockedMode(nil) end)
at(260, function() cw()._skillsGridExpanded = false end)
at(290, function()
    shot("folded")
    cw()._skillsGridExpanded = true
    strip(cw(), cw()._tabStripPanel, "loot")
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 300 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
