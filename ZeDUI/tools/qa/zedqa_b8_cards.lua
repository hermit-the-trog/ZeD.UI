-- ZeDUI/tools/qa/zedqa_b8_cards.lua  (Nov 7 2026, QA; tag b8cd): three fixes from the outside review of beta 7, in game.
--   band     (item 2, 1c8ce4aa) ZeD.Molecules.bandRoom on its own, then the Journal tab with an item card open over it: the
--            question band's Cancel and Delete and the Save button lie in the part the card leaves showing (the question is set
--            on a stand-in entry; nothing is deleted or saved).
--   craft    (item 8, 1c8ce4aa and ae42c21e) the craft's own start check (ZeD.CraftingTab.startCheck) over every craft recipe with the
--            character's own inventory: it answers (not nil), and a recipe it passes always has a possible count above 0, which is the
--            "Craft enabled at Required 1/4" fault. Then the Craft tab on screen. The real Required 1/4 recipe is a manual item.
--   prompt   (item 5, 5c00c592) a ZeD one-line text prompt opens with its default selected (ZeD.selectDefault records it) - the
--            selection itself is a picture (zqa_b8_cd_prompt.png), typing over it is a manual item.
-- Restores the windows it opened. Pictures zqa_b8_cd_<name>.png. grep "ZEDQA b8cd".
local TAG = "b8cd"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local Q = { pass = 0, fail = 0 }
local function verdict(ok, what)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what)
    return ok
end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_b8_cd_" .. name .. ".png") end) end

local p = getPlayer()
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local M = ZeD and ZeD.Molecules
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local S = {}

local function keepDown(w)
    if w then
        w._autoShaded = false
        if w.windowShaded then w:setWindowShaded(false) end
        w._outSince = getTimestampMs() + 600000
    end
end

-- ---------------------------------------------------------------------------
-- band: bandRoom on its own
-- ---------------------------------------------------------------------------
at(2, function()
    if not (M and M.bandRoom) then verdict(false, "item 2: ZeD.Molecules.bandRoom exists"); return end
    local l, r = M.bandRoom({}, 100, 400, 80)
    verdict(l == 100 and r == 500, "bandRoom with no card keeps the whole band (" .. l .. "," .. r .. ")")
    l, r = M.bandRoom({ _coverX = 300 }, 100, 400, 80)
    verdict(l == 100 and r == 300, "bandRoom with a card over the right keeps the left part (" .. l .. "," .. r .. ")")
    l, r = M.bandRoom({ _coverL = 250 }, 100, 400, 80)
    verdict(l == 250 and r == 500, "bandRoom with a card over the left keeps the right part (" .. l .. "," .. r .. ")")
    l, r = M.bandRoom({ _coverX = 150 }, 100, 400, 80)
    verdict(l == 100 and r == 500, "bandRoom with less room than the band needs keeps the whole band (" .. l .. "," .. r .. ")")
end)

-- ---------------------------------------------------------------------------
-- band: the Journal tab with an item card open
-- ---------------------------------------------------------------------------
local rec = { n = 0 }
local realRoom = M and M.bandRoom
at(5, function()
    S.openedChar = not CW.isOpen()
    if S.openedChar then CW.toggleBothPaired(0) end
end)
at(30, function()
    keepDown(CW.getWindow())
    CW.openTab(0, "journal")
    if realRoom then
        M.bandRoom = function(panel, x, w, need)
            local l, r = realRoom(panel, x, w, need)
            if panel and panel._coverX then rec.n = rec.n + 1; rec.cover, rec.l, rec.r = panel._coverX, l, r end
            return l, r
        end
    end
end)
at(70, function()
    local win = CW.getWindow()
    keepDown(win)
    if not win then verdict(false, "item 2: the Character window is open"); return end
    say("journal tab: active " .. tostring(win._activeTab) .. ", mode " .. tostring(win._drawerMode))
    verdict(win._activeTab == "journal", "item 2: the Journal tab is open")
    -- a stand-in question: Cancel and Delete show, nothing is deleted (the entry is not in the character's journal)
    win._journalAsk = { entry = {} }
    local items = p:getInventory():getItems()
    S.item = items:size() > 0 and items:get(0) or nil
    say("item card over the Journal: " .. tostring(S.item and S.item:getDisplayName()))
end)
for k = 71, 100 do
    at(k, function()
        local win = CW.getWindow()
        if win and S.item then
            win._drawerItem = S.item
            pcall(function() if win._itemCard and win._itemCard.setItem then win._itemCard:setItem(S.item) end end)
        end
    end)
end
at(105, function()
    local win = CW.getWindow()
    if not win then return end
    local r = win._journalAskRects
    say("card edge (drawer px) " .. tostring(rec.cover) .. ", bandRoom calls under a card " .. rec.n .. ", room " .. tostring(rec.l) .. " to " .. tostring(rec.r))
    verdict(rec.n > 0 and rec.cover ~= nil, "item 2: the band asks bandRoom while a card is open")
    if r and r.cancel and r.verb and rec.cover then
        say(string.format("Cancel x %d..%d, Delete x %d..%d", r.cancel.x, r.cancel.x + r.cancel.w, r.verb.x, r.verb.x + r.verb.w))
        verdict(r.cancel.x + r.cancel.w <= rec.cover + 1, "item 2: Cancel lies left of the card's edge")
        verdict(r.verb.x + r.verb.w <= rec.cover + 1, "item 2: Delete lies left of the card's edge")
    else
        verdict(false, "item 2: the question band was drawn (Cancel and Delete rectangles)")
    end
    shot("journal_question_card")
    win._journalAsk, win._journalAskRects = nil, nil
end)
at(130, function()
    local win = CW.getWindow()
    if not win then return end
    local sb, box = win._journalSaveBtn, win._journalInput
    if rec.cover and sb and sb:isVisible() then
        say(string.format("Save x %d..%d of the card edge %d", sb:getX(), sb:getX() + sb:getWidth(), rec.cover))
        verdict(sb:getX() + sb:getWidth() <= rec.cover + 1, "item 2: Save lies left of the card's edge")
    else
        say("NOTE the Save button is not visible (hidden under the card, or the tab has none): " .. tostring(sb and sb:isVisible()))
    end
    if rec.cover and box and box:isVisible() then
        verdict(box:getX() + box:getWidth() <= rec.cover + 1, "item 2: the entry box ends at the card")
    end
    shot("journal_save_card")
end)
at(150, function()
    local win = CW.getWindow()
    if win then win._drawerItem = nil end
    if realRoom then M.bandRoom = realRoom end
    if CW.isOpen() and S.openedChar then CW.toggleBothPaired(0) end
end)

-- ---------------------------------------------------------------------------
-- craft: the start check over the recipe list
-- ---------------------------------------------------------------------------
local CT, CC = ZeD.CraftingTab, ZeD.CraftingCore
local R = { i = 0, yes = 0, no = 0, unknown = 0, bad = 0, total = 0, firstBad = nil }
at(170, function()
    if not (CT and CT.startCheck and CC and CC.buildContainers) then verdict(false, "item 8: ZeD.CraftingTab.startCheck exists"); return end
    S.containers = CC.buildContainers(p)
    S.recipes = ScriptManager.instance:getAllCraftRecipes()
    S.logic = HandcraftLogic.new(p, nil, nil)
    S.logic:setContainers(S.containers)
    R.total = S.recipes:size()
    say("craft recipes in the game: " .. R.total)
end)
for k = 171, 230 do
    at(k, function()
        if not S.recipes then return end
        local last = math.min(R.total, R.i + 40)
        while R.i < last do
            local rc = S.recipes:get(R.i)
            R.i = R.i + 1
            local ok, most = CT.startCheck(p, nil, S.containers, rc, false, nil)
            if ok == nil then R.unknown = R.unknown + 1
            elseif ok == false then R.no = R.no + 1
            else
                R.yes = R.yes + 1
                local cnt = 0
                pcall(function() S.logic:setRecipe(rc); cnt = S.logic:getPossibleCraftCount(true) end)
                if cnt <= 0 then R.bad = R.bad + 1; R.firstBad = R.firstBad or tostring(rc:getName()) end
            end
        end
    end)
end
at(235, function()
    if not S.recipes then return end
    say(string.format("start check over %d of %d recipes: passed %d, refused %d, no answer %d, passed with a count of 0: %d %s", R.i, R.total,
        R.yes, R.no, R.unknown, R.bad, R.firstBad or ""))
    verdict(R.i >= R.total, "item 8: every recipe was asked")
    verdict(R.unknown < R.total, "item 8: the game answers the start check (not every answer nil)")
    verdict(R.bad == 0, "item 8: no recipe passes the start check with a possible count of 0")
    verdict(R.no > 0, "item 8: the check refuses recipes this character cannot make (" .. R.no .. ")")
end)
at(240, function()
    S.openedWorld = not WW.isOpen()
    if S.openedWorld then CW.toggleBothPaired(0) end
end)
at(280, function()
    keepDown(WW.getWindow()); keepDown(CW.getWindow())
    WW.openTab(0, "craft")
end)
at(340, function()
    local w = WW.getWindow()
    keepDown(w)
    say("Craft tab: active " .. tostring(w and w._activeTab))
    shot("craft_tab")
end)
at(360, function()
    if S.openedWorld and WW.isOpen() then CW.toggleBothPaired(0) end
end)

-- ---------------------------------------------------------------------------
-- prompt: a text prompt's default is selected
-- ---------------------------------------------------------------------------
at(390, function()
    verdict(ZeD.selectDefault ~= nil, "item 5: ZeD.selectDefault exists")
    local ok, box = pcall(function()
        local b = ISTextBox:new(0, 0, 280, 180, "b8 prompt check", "Duffel Bag", nil, function() end, 0)
        b:initialise(); b:addToUIManager()
        return b
    end)
    if not ok then verdict(false, "item 5: the text prompt opened (" .. tostring(box) .. ")"); return end
    S.box = box
end)
at(420, function()
    local b = S.box
    if not b then return end
    local e = b.entry
    local t = nil
    pcall(function() t = e:getInternalText() end)
    say("prompt field holds '" .. tostring(t) .. "', default recorded '" .. tostring(e and e._zedDefaultText) .. "'")
    verdict(e ~= nil and e._zedDefaultText == "Duffel Bag" and t == "Duffel Bag", "item 5: the prompt's default is selected as it opens")
    shot("prompt")
    pcall(function() b:close() end)
    pcall(function() b:removeFromUIManager() end)
    S.box = nil
end)
at(440, function()
    say("summary: " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
    say("DONE")
end)

local last = 0
for _, s in ipairs(steps) do if s.n > last then last = s.n end end
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR step " .. s.n .. ": " .. tostring(e)) end
        end
    end
    if tick > last + 5 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
