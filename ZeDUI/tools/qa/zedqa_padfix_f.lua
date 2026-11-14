-- ZeDUI/tools/qa/zedqa_padfix_f.lua  (Nov 14 2026, QA): 199, the Papers page's entry item for Knox Knews and why reading
-- doesn't queue; then 198, Building's "Show" pull-up opened from code (World tab "build") for a picture. grep "ZEDQA pff".
local function say(s) print("ZEDQA pff " .. tostring(s)) end
local p = getPlayer()
local Focus = ZeD.Input.Focus
local inv = p:getInventory()
local mine = inv:AddItem("Base.Newspaper")
local w, entryItem
local function go(pred) for _, s in ipairs(Focus.flatElements(w)) do if pred(tostring(s.id)) then Focus.focusWhere(w, s.zone, function(e) return tostring(e.id) == tostring(s.id) end); return s end end end
local function queue()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local t = {}
    if q and q.queue then for _, a in ipairs(q.queue) do t[#t + 1] = tostring(a.Type) end end
    return #t > 0 and table.concat(t, " > ") or "(empty)"
end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function() ZeD_CharacterWindow.openTab(0, "journal"); w = ZeD_CharacterWindow.getInstance(0) end)
at(1300, function() w._journalSubTab = 3 end)
at(2500, function()
    Focus.claimFocus(w)
    go(function(id) return id:find("^jr:paper:knox") ~= nil end)
    local e = Focus.getFocusedElement(w); if e and e.onActivate then e.onActivate(w, e) end
end)
at(3500, function()
    local papers = w._jr and w._jr.carried and w._jr.carried.papers
    say("carried papers: " .. tostring(papers and #papers))
    if papers then for k, e in ipairs(papers) do say("  entry " .. k .. " id " .. tostring(e.id) .. " item " .. tostring(e.item)); if tostring(e.id):find("knox") then entryItem = e.item end end end
    local it = entryItem
    if not it then say("no entry item for Knox Knews") else
        local c = it:getContainer()
        local tag, illit, dark, lvl, sk = "?", "?", "?", "?", "?"
        pcall(function() tag = tostring(it:hasTag(ItemTag.UNINTERESTING)) end)
        pcall(function() illit = tostring(p:hasTrait(CharacterTrait.ILLITERATE)) end)
        pcall(function() dark = tostring(p:tooDarkToRead()) end)
        pcall(function() lvl = tostring(it:getLvlSkillTrained()) end)
        pcall(function() sk = tostring(it:getSkillTrained()) end)
        say("item " .. tostring(it:getFullType()) .. " | container " .. tostring(c and c:getType()) .. " | in my bag " .. tostring(c == inv) ..
            " | same as the bag's newspaper " .. tostring(it == mine) .. " | uninteresting " .. tag .. " | lvlSkillTrained " .. lvl ..
            " | skillTrained " .. sk .. " | illiterate " .. illit .. " | too dark " .. dark)
        local ok, v = pcall(function() return ISReadABook:new(p, it, 150):isValid() end)
        say("ISReadABook:new(p, item, 150):isValid() -> ok " .. tostring(ok) .. " " .. tostring(v))
    end
    go(function(id) return id == "jr:read" end)
    local e = Focus.getFocusedElement(w)
    say("on " .. tostring(e and e.id))
    if e and e.onActivate then local ok, er = pcall(e.onActivate, w, e); say("onActivate ok " .. tostring(ok) .. " " .. tostring(er)) end
    say("queue same frame: " .. queue())
    ZEDQA_PFF_T = 0
end)
at(3560, function() say("queue a few ticks later: " .. queue()) end)
at(4200, function() say("queue 0.7 s later: " .. queue()); pcall(function() local q = ISTimedActionQueue.getTimedActionQueue(p); if q and q.clearQueue then q:clearQueue() end end) end)
at(4500, function() pcall(function() ZeD_WorldWindow.openTab(0, "build") end) end)
at(6000, function()
    local ww = ZeD_WorldWindow.getWindow(0)
    say("world window " .. tostring(ww and ww._zedLabel) .. " buildState " .. tostring(ww and ww._buildState ~= nil))
    if ww and ww._buildState then local ok, e = pcall(function() ZeD.CraftingCore.openPopMenu(ww._buildState, "show") end); say("openPopMenu show ok=" .. tostring(ok) .. " " .. tostring(e)) end
end)
at(7000, function()
    pcall(function() getCore():TakeFullScreenshot("zqa_pff_building_show.png") end)
    pcall(function() inv:Remove(mine) end)
    say("DONE")
end)
local function tick()
    local now = getTimestampMs()
    if not t0 then t0 = now end
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
