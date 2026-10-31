-- ZeDUI/tools/qa/zedqa_break_c1c2.lua  (Oct 31 2026, QA; break-it C1 and C2 re-checked)
-- C1: the item card's "Name this item" box goes with its card. Opened from a card (the card's own Rename,
--     ZeD.ItemMenu.rename(item, pn, card)), then each of: another tab, another item, the drawer folded, the
--     window closed: the box must be gone a few frames later. Opening it twice leaves one box.
-- C2: a flyer's reader (ZeD.Reader.openPrint) stays over both windows: after a press on each window it is
--     still above them in the UI order; a window's menu opened while it is up shows above the reader.
-- Puts back the windows and the tabs; the flyer given is taken away. grep "ZEDQA bc12".
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local p = getPlayer(); local pn = p:getPlayerNum(); local inv = p:getInventory()
local function say(s) print("ZEDQA bc12 " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bc12_" .. n .. ".png") end) end
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function open() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(pn) end end
local function tab(win, key, id) local s = win and win[key]; for _, z in ipairs((s and s._hitZones) or {}) do if type(z.id) == "string" and z.id == "tab:" .. id and win._activeTab ~= id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local function select(item)
    local c = CW(); local cp = c and c._mainContent
    if not cp then return end
    local sel = cp._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    cp._selectedItems, cp._lastClickedItem = sel, item
    pcall(function() c._updateDrawer(cp) end)
end
-- the "Name this item" boxes on screen
local function boxes()
    local n = 0
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = ui:get(i):getTable()
        local want = ZeD.tr("UI_ZeD_ItemMenu_NameThis")
        local ok, vis = pcall(function() return ui:get(i):isVisible() end)
        if t and ok and vis and (t.Type == "ISTextBox" or (t.text == want)) then n = n + 1
        elseif t and ok and vis and t.Type and (tostring(t.Type):find("Box") or tostring(t.Type):find("Prompt")) then ZEDQA_BC12_SEEN = tostring(t.Type) end
    end
    return n
end
local function idx(obj)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do if ui:get(i) == obj then return i end end
    return -1
end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local a, b, flier
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    open(); tab(CW(), "_tabStripPanel", "loot")
    a = inv:AddItem("Base.Hammer"); b = inv:AddItem("Base.Screwdriver")
end)
-- C1: one way at a time
local function c1(label, act)
    step(10, function()
        open(); tab(CW(), "_tabStripPanel", "loot"); select(a)
    end)
    step(40, function()
        local card = CW()._itemCard
        local vis = false; pcall(function() vis = card:isReallyVisible() end)
        say(label .. ": card holds the item " .. tostring(card and card.item == a) .. ", really visible " .. tostring(vis))
        ZeD.ItemMenu.rename(a, pn, card)
        ZeD.ItemMenu.rename(a, pn, card)   -- twice: one box
        say(label .. ": boxes right after " .. boxes() .. " (other box-like types seen: " .. tostring(ZEDQA_BC12_SEEN) .. ")")
    end)
    step(10, function() check(boxes() == 1, label .. ": the card's Rename opens one box (" .. boxes() .. ")"); act() end)
    step(20, function() check(boxes() == 0, label .. ": the box is gone (" .. boxes() .. " left)"); if boxes() > 0 then shot("c1_" .. label) end end)
end
c1("another tab", function() tab(CW(), "_tabStripPanel", "health") end)
c1("another item", function() select(b) end)
c1("drawer folded", function() select(nil) end)
c1("window closed", function() CWm.toggleBothPaired(pn) end)
step(20, function() open(); tab(CW(), "_tabStripPanel", "loot"); select(nil) end)
-- C2: the reader over both windows
local reader
step(10, function()
    flier = inv:AddItem("Base.Flier")
    flier:getModData().printMedia = { id = "ustoreitmuldraugh", title = "Print_Media_UStoreItMuldraugh_title", info = "Print_Media_UStoreItMuldraugh_info", text = "Print_Text_UStoreItMuldraugh_info" }
    flier:setName(getText("Print_Media_UStoreItMuldraugh_title"))
    local ok = ZeD.Reader.openPrint(p, flier)
    say("reader opened " .. tostring(ok))
end)
step(20, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local t = ui:get(i):getTable(); if t and t.Type and tostring(t.Type):find("Reader") and t:isVisible() then reader = ui:get(i) end end
    say("reader found " .. tostring(reader ~= nil))
    -- a press on each window (the order a click gives: the window comes to the top)
    pcall(function() CW():bringToTop() end); pcall(function() WW():bringToTop() end)
end)
step(10, function()
    local r, c, w = idx(reader), idx(CW().javaObject), idx(WW().javaObject)
    check(reader ~= nil and r > c and r > w, string.format("C2: after presses on both windows the reader is above them (reader %d, Character %d, World %d)", r, c, w))
    shot("c2_reader_over")
    pcall(function() CW():openWindowMenu() end)
end)
step(15, function()
    local menu
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local t = ui:get(i):getTable(); if t and t.Type == "ZeD_WindowMenu" and t._ctx and t._ctx.open then menu = ui:get(i) end end
    check(menu ~= nil and idx(menu) > idx(reader), string.format("C2: a window's menu opened under the reader shows above it (menu %d, reader %d)", menu and idx(menu) or -1, idx(reader)))
    shot("c2_menu_over_reader")
    pcall(function() menu:getTable():close() end)
end)
step(10, function()
    pcall(function() reader:getTable():close() end)
    for _, it in ipairs({ a, b, flier }) do if it and it:getContainer() then pcall(function() it:getContainer():Remove(it) end) end end
    open(); tab(CW(), "_tabStripPanel", "loot"); select(nil)
end)
step(20, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
