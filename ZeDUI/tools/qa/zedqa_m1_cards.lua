-- ZeDUI/tools/qa/zedqa_m1_cards.lua  (Nov 7 2026, QA; the next beta's merge 1, a60a0399): the cards and clips it changed.
-- After zedqa_padlock.lua (LK_QA: a free crate, a locker on a combination lock, a crate on a key padlock).
--   1. the lock cards (World window object card) on each of the three: their width (the half card, 220 units) and a picture
--   2. item cards on the Loot tab: a half-read carpentry book (Progress against the character's pages), a pistol (Ammo type),
--      a raw steak (its Cooking), a padlock and a combination padlock (their item cards)
--   3. Character tabs with a card open and after it closes: Equip, Health, Skills, Identity, Journal (each page), Radio
--      (a walkie in the hand), and World Ranch; each drawer's clips at the end of a frame against the start (must be 0)
-- Everything made is taken away (the batch puts the save back too). Pictures zqa_m1c_<n>.png; grep "ZEDQA m1c".
local function say(s) print("ZEDQA m1c " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local OC = ZeD.ObjectCards
local T = ZeD.T
local p = getPlayer()
local inv = p:getInventory()
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_m1c_" .. n .. ".png") end) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

-- clips left at the end of a frame (as zedqa_tab_sweep.lua)
local worst = {}
local function hook(w, key)
    local d = w and w._drawerPanel
    if not d or d._m1Hooked then return end
    local orig = d.prerender
    d._m1Hooked = true
    d.prerender = function(self)
        local a = self._zedStencilN or 0
        orig(self)
        local dd = (self._zedStencilN or 0) - a
        if dd ~= 0 then worst[key] = dd end
    end
end
local function unhook(w) local d = w and w._drawerPanel; if d and d._m1Hooked then d.prerender = nil; d._m1Hooked = nil end end
local function nums(key, w, what)
    local s = w and w._actionTabStrip
    local d = worst[key] or 0
    check(d == 0, what .. ": clips left " .. d .. " (tab " .. tostring(w and w._activeTab) .. ", footer " .. tostring(w and w.footerHeight and w:footerHeight())
        .. ", strip " .. tostring(s and s:isVisible()) .. ", zones " .. tostring(s and s._hitZones and #s._hitZones) .. ")")
    worst[key] = nil
end
local function pick(w, item)
    local sel = w._mainContent._selectedItems
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    w._updateDrawer(w._mainContent)   -- (the Character window's takes its content panel; the World window's reads its own)
end
local function cardW(w) local c = w and w._itemCard; return c and c:isVisible() and math.floor(c:getWidth()) or nil end

local made = {}
local function make(ft) local it = inv:AddItem(ft); made[#made + 1] = it; return it end
local book, pistol, steak, pad, combo, walkie
local handWas = { p:getPrimaryHandItem(), p:getSecondaryHandItem() }

add(500, function()
    say("screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ", text " .. tostring(ZeD.currentSize) .. ", half " .. T.px(220) .. " px, full " .. T.px(480) .. " px")
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(2000, function()
    hook(CWm.getWindow(), "char"); hook(WWm.getWindow(), "world")
    book = make("Base.BookCarpentry1"); pistol = make("Base.Pistol"); steak = make("Base.Steak"); pad = make("Base.Padlock"); combo = make("Base.CombinationPadlock")
    local pages = book:getNumberOfPages()
    p:setAlreadyReadPages("Base.BookCarpentry1", math.floor(pages / 2))
    say("book pages " .. pages .. ", the character has read " .. tostring(p:getAlreadyReadPages("Base.BookCarpentry1")) .. ", this copy " .. tostring(book:getAlreadyReadPages()))
end)

-- 1. the lock cards
local LK = LK_QA or {}
for _, k in ipairs({ "locker", "keyed", "crate" }) do
    add(1500, function()
        local o = LK[k]
        if not o then say("ERR no " .. k .. " (zedqa_padlock.lua first)"); return end
        local ok, r = pcall(OC.open, p, "lock", o)
        say("lock card on the " .. k .. ": open " .. tostring(ok and r) .. (ok and "" or (" " .. tostring(r))))
    end)
    add(2000, function()
        local w = WWm.getWindow()
        local c = w and w._objectCard
        local cw = c and c:isVisible() and math.floor(c:getWidth()) or nil
        check(cw ~= nil and cw <= T.px(220) + T.px(10), "the " .. k .. "'s lock card is the half card (width " .. tostring(cw) .. ", half " .. T.px(220) .. ")")
        nums("world", w, "lock card " .. k)
        shot("lock_" .. k)
    end)
    add(800, function() pcall(WWm.closeObjectCard) end)
end

-- 2. item cards on Loot
local cards = { { "book", function() return book end }, { "pistol", function() return pistol end }, { "steak", function() return steak end },
                { "padlock", function() return pad end }, { "combo", function() return combo end } }
add(800, function() CWm.openTab(0, "loot"); WWm.openTab(0, "loot") end)
for _, c in ipairs(cards) do
    add(1000, function() pick(CWm.getWindow(), c[2]()) end)
    add(1800, function()
        local w = CWm.getWindow()
        say("card " .. c[1] .. ": up " .. tostring(w._drawerItem ~= nil) .. ", width " .. tostring(cardW(w)))
        if c[1] == "pistol" then
            local ok, stats = pcall(ZeD.itemFacts, pistol)
            local at
            if ok and type(stats) == "table" then for _, r in ipairs(stats) do if tostring(r.label):lower():find("ammo") then at = tostring(r.label) .. " = " .. tostring(r.value) end end end
            check(ok, "pistol facts without an error (" .. tostring(at or stats) .. ")")
        end
        nums("char", w, "card " .. c[1])
        shot("card_" .. c[1])
    end)
    add(600, function() pick(CWm.getWindow(), nil) end)
end

-- 3. tabs with a card open, and after
local function tabCard(M, key, id, setup, label)
    add(800, function() M.openTab(0, id); if setup then pcall(setup) end end)
    add(1200, function() local w = M.getWindow(); check(w._activeTab == id, label .. " is open (" .. tostring(w._activeTab) .. ")"); nums(key, w, label .. " alone"); pick(w, book) end)
    add(1800, function() local w = M.getWindow(); say(label .. " card up " .. tostring(w._drawerItem ~= nil)); nums(key, w, label .. " with a card"); shot("tab_" .. label:gsub("%W", "_") .. "_card"); pick(w, nil) end)
    add(1500, function() local w = M.getWindow(); nums(key, w, label .. " after the card"); shot("tab_" .. label:gsub("%W", "_") .. "_after") end)
end
for _, id in ipairs({ "equip", "health", "skills", "identity" }) do tabCard(CWm, "char", id, nil, id) end
for sub, name in ipairs({ "journal", "notebooks", "papers", "recipes", "loadouts" }) do
    tabCard(CWm, "char", "journal", function()
        local w = CWm.getWindow()
        if ZeD.JournalTab.switchSub then ZeD.JournalTab.switchSub(w, sub) end
        w._journalSubTab = sub
    end, "journal " .. name)
end
add(500, function()
    walkie = make("Base.WalkieTalkie3")
    p:setSecondaryHandItem(nil); p:setPrimaryHandItem(walkie)
end)
tabCard(CWm, "char", "radio", nil, "radio")
add(500, function() p:setPrimaryHandItem(handWas[1]); p:setSecondaryHandItem(handWas[2]); pcall(function() ZeD.AnimalsAlertPoller.refreshCache() end) end)
tabCard(WWm, "world", "animals", nil, "ranch")

add(800, function()
    unhook(CWm.getWindow()); unhook(WWm.getWindow())
    CWm.openTab(0, "loot"); WWm.openTab(0, "loot")
    for _, it in ipairs(made) do local c = it and it:getContainer(); if c then c:Remove(it) end end
    p:setAlreadyReadPages("Base.BookCarpentry1", 0)
    say(pass .. " passed, " .. fail .. " failed")
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
say("start")
Events.OnTick.Add(drive)
