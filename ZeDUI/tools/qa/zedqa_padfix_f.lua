-- ZeDUI/tools/qa/zedqa_padfix_f.lua  (Nov 14 2026, QA): 199's item on jr:read (which InventoryItem the Papers page holds),
-- and 198's Building "Show" pull-up opened from code for a picture. grep "ZEDQA pff".
local function say(s) print("ZEDQA pff " .. tostring(s)) end
local p = getPlayer()
local Focus = ZeD.Input.Focus
local inv = p:getInventory()
local mine = inv:AddItem("Base.Newspaper")
local w
local function go(pred) for _, s in ipairs(Focus.flatElements(w)) do if pred(tostring(s.id)) then Focus.focusWhere(w, s.zone, function(e) return tostring(e.id) == tostring(s.id) end); return s end end end
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
    go(function(id) return id == "jr:read" end)
    local e = Focus.getFocusedElement(w)
    say("on " .. tostring(e and e.id))
    local it = e and e.item
    if not it then
        pcall(function() for k, v in pairs(w) do if tostring(k):find("^_jr") and type(v) == "table" and v.item then it = v.item; say("item from w." .. tostring(k)) end end end)
    end
    if not it then say("no item found on the element or w._jr*") else
        local c = it:getContainer()
        local tag = "?"; pcall(function() tag = tostring(it:hasTag(ItemTag.UNINTERESTING)) end)
        local illit = "?"; pcall(function() illit = tostring(p:hasTrait(CharacterTrait.ILLITERATE)) end)
        if illit == "?" then pcall(function() illit = tostring(p:HasTrait("Illiterate")) end) end
        say("item " .. tostring(it:getFullType()) .. " | container " .. tostring(c and c:getType()) .. " | in my bag " .. tostring(c == inv) ..
            " | uninteresting " .. tag .. " | illiterate " .. illit .. " | same object as the bag's newspaper " .. tostring(it == mine))
    end
end)
at(4500, function()
    pcall(function() ZeD_WorldWindow.openTab(0, "building") end)
end)
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
