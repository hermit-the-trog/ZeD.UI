-- ZeDUI/tools/qa/zedqa_b11_notes.lua  (Nov 11 2026, beta 11): the director's Nov 10 notes that changed what is drawn,
-- each as numbers and a picture. grep "ZEDQA b11n". Pictures zqa_b11n_<w>x<h>_<n>.png. Screen size is read, never set.
--   155 belt hands   both hands empty: the main ring draws hand_right, the off ring hand_left, dim, no words; the hint
--                    words are the game's Right Hand / Left Hand; a two-handed item (Base.Sledgehammer) makes the off
--                    ring a peek with no icon; unequipped, the icons are back
--   156 loot drawer  an item card opened and closed in the Character window: the drawer folds; the drawer put in tab mode
--                    on Loot (a restored state) becomes the card / nothing, and neither window draws a placeholder line
--   157 Nothing here. the World list on an empty floor tile, in an empty crate, the Character list in an empty bag
--   160 Dark text    the card's body (T.text), secondary (T.textSec) and dim (T.textDim) colors at Teal and at Orange:
--                    RGB and the contrast on the window (surf1 over a dark world; the secondary and dim over white too)
--   162 stack bar    four water bottles (empty, 0.3, 0.6, full): the stack row's bar and the grid cell's bar read the
--                    emptiest in both sort orders of the Cond column; opened, each row has its own level
-- Setup: the QA character on the QA save, the floor under the character empty (the QA home), both windows closed or open.
-- Everything spawned is removed and every setting put back at the end, also after a failed step.
local TAG = "b11n"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, s) if ok then pass = pass + 1 else fail = fail + 1 end; say((ok and "PASS " or "FAIL ") .. s); return ok end
if ZEDQA_HOME then ZEDQA_HOME(TAG) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local pn = 0
say("screen " .. sw .. "x" .. sh)
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local IR = ZeD.InventoryRenderer
local IM = ZeD.ItemMeter
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function near(a, b, tol) return a ~= nil and b ~= nil and math.abs(a - b) <= (tol or 0.02) end

-- the plan: steps run in order, each after its delay (or, for addWhen, once its condition holds or its time is up)
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function addWhen(max, cond, fn) plan[#plan + 1] = { ms = max, cond = cond, fn = fn } end

-- ------------------------------------------------------------------ hooks (each put back in the last step)
local H = { icons = {}, texts = {}, empties = {}, bars = {}, undo = {} }
local function hookFn(tbl, name, wrap)
    local orig = tbl[name]
    if orig == nil then return end
    tbl[name] = wrap(orig)
    H.undo[#H.undo + 1] = function() tbl[name] = orig end
end
local function hookIcons(hud)
    hookFn(ZeD.Atoms, "drawPxIcon", function(orig) return function(panel, id, x, y, box, alpha, color, ...)
        if panel == hud then H.icons[#H.icons + 1] = { id = id, x = x, y = y, box = box, a = alpha, c = color } end
        return orig(panel, id, x, y, box, alpha, color, ...)
    end end)
end
local function hookEmpty()
    hookFn(ZeD.Molecules, "drawEmptyLine", function(orig) return function(panel, x, y, w, text, ...)
        H.empties[#H.empties + 1] = { panel = panel, text = text }
        return orig(panel, x, y, w, text, ...)
    end end)
end
local function hookBars()
    hookFn(ZeD.Atoms, "drawFillBar", function(orig) return function(panel, x, y, w, f, ...)
        H.bars[#H.bars + 1] = { panel = panel, x = x, y = y, f = f }
        return orig(panel, x, y, w, f, ...)
    end end)
end
-- the words an element draws (best effort: the belt's own, the windows' drawers)
local function hookTexts(obj, tag)
    if not obj then return end
    for _, nm in ipairs({ "drawText", "drawTextCentre" }) do
        local own = rawget(obj, nm)
        local orig = obj[nm]
        if orig then
            obj[nm] = function(s, str, ...)
                H.texts[#H.texts + 1] = { tag = tag, text = tostring(str) }
                return orig(s, str, ...)
            end
            H.undo[#H.undo + 1] = function() obj[nm] = own end
        end
    end
end
local function unhookAll() for k = #H.undo, 1, -1 do pcall(H.undo[k]) end; H.undo = {} end
local function lastIcon(id)
    for k = #H.icons, 1, -1 do if H.icons[k].id == id then return H.icons[k] end end
end
local function anyIcon(prefix)
    for _, r in ipairs(H.icons) do if tostring(r.id):find(prefix, 1, true) == 1 then return true end end
    return false
end

-- ------------------------------------------------------------------ state to put back
local S = { added = {}, undo = {} }
local function spawn(full)
    local it = p:getInventory():AddItem(full)
    if it then S.added[#S.added + 1] = it end
    return it
end
local function removeThing(it)
    if not it then return end
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    pcall(function() local wio = it.getWorldItem and it:getWorldItem(); if wio and wio:getSquare() then wio:getSquare():transmitRemoveItemFromSquare(wio) end end)
end
local function elFor(win, zone, inv)
    for _, z in ipairs(win and win._focusRing or {}) do
        if z.zone == zone then
            for _, e in ipairs(z.elements or {}) do if e.inventory == inv then return e end end
        end
    end
end
local function activeInv(win)
    local c = win and win._containers and win._containers[win._viewedContainer or win._activeContainer or 1]
    return c and c.inventory or nil
end
local function mid(a, b) return (a + b) / 2 end

-- list rows and cells: is the row really under its point; one wheel notch toward it per call (an addWhen condition)
local function rowShown(win, it)
    local c = win and win._mainContent
    local y = it and c and c._itemRenderYMap and c._itemRenderYMap[it]
    if not y or not c.hitZoneAt then return false end
    local x = (c._itemRenderXMap and c._itemRenderXMap[it]) or 0
    local cell = c._gridCell
    local lx, ly = x + (cell and cell / 2 or 170), y + (cell and cell / 2 or ZeD.T.rowH / 2)
    if ly < 0 or ly >= c:getHeight() then return false end
    local z = c:hitZoneAt(lx, ly)
    return z ~= nil and z.id == it
end
local function revealRow(win, it)
    if not it then return false end
    if rowShown(win, it) then return true end
    local c = win._mainContent
    local y = c._itemRenderYMap and c._itemRenderYMap[it] or 0
    if c._scroll and c._scroll.handleMouseWheel then c._scroll:handleMouseWheel((y < 0) and -1 or 1) end
    return false
end

-- ------------------------------------------------------------------ setup
local hud = ZeD.Belt and ZeD.Belt.getHUD(pn)
local keepPins, keepHands, keepTheme, keepGrid, keepSort, keepInvPick = nil, nil, nil, nil, nil, {}
add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    keepTheme = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
    keepHands = { p:getPrimaryHandItem(), p:getSecondaryHandItem() }
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    CW():setPinned(true); WW():setPinned(true)   -- (nothing rolls while the steps run)
    CWm.openTab(0, "loot"); WWm.openTab(0, "loot")
    keepInvPick.cw, keepInvPick.ww = activeInv(CW()), activeInv(WW())
    say("theme " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
    check(hud ~= nil, "the belt's HUD is up")
end)

-- ================================================================== 155 belt hands
local function handBoxes()
    local m, o
    for _, b in ipairs(hud and hud._boxes or {}) do
        if b.kind == "hand" then if b.which == "p" then m = b else o = b end end
    end
    return m, o
end
local function inBox(r, b) return r ~= nil and b ~= nil and r.x >= b.x - 1 and r.x <= b.x + b.w end
local sledge
add(300, function()
    -- (both hands empty; what was held is put back at the end)
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    if hud then
        hookIcons(hud); hookTexts(hud, "belt")
    end
    H.icons, H.texts = {}, {}
end)
add(900, function()
    local m, o = handBoxes()
    check(m ~= nil and o ~= nil, "155 the belt has a main hand and an off hand box")
    local rI, lI = lastIcon("hand_right"), lastIcon("hand_left")
    check(rI ~= nil and inBox(rI, m), "155 empty hands: the main ring draws hand_right")
    check(lI ~= nil and inBox(lI, o), "155 empty hands: the off ring draws hand_left")
    if rI and lI then
        check(lI.box < rI.box, "155 the off ring's icon is the smaller (main " .. tostring(rI.box) .. " px, off " .. tostring(lI.box) .. " px)")
        local dim = ZeD.T.textDim
        check(near(rI.a, dim.a or 1, 0.02) and near(lI.a, dim.a or 1, 0.02), "155 both icons dim (alpha " .. tostring(rI.a) .. " / " .. tostring(lI.a) .. ", textDim " .. tostring(dim.a or 1) .. ")")
        check(rI.c == dim or (rI.c and near(rI.c.r, dim.r, 0.01) and near(rI.c.g, dim.g, 0.01)), "155 the icon color is textDim (not the accent)")
    end
    -- the texture each ring draws (the kit: 16, 24, 32 and 48)
    local texs = {}
    for _, id in ipairs({ "hand_right", "hand_left" }) do
        for _, s in ipairs({ 16, 24, 32, 48 }) do
            local tx, got = ZeD.PxIcon.tex(id, s)
            local nm = "nil"
            if tx then pcall(function() nm = tostring(tx:getName()) end) end
            texs[#texs + 1] = id .. "@" .. s .. "=" .. nm .. "(" .. tostring(got) .. ")"
            check(tx ~= nil and got == s, "155 icon " .. id .. " exists at " .. s)
        end
    end
    say("155 textures: " .. table.concat(texs, " "))
    say("155 drawn: right " .. (rI and (rI.x .. "," .. rI.y .. " box " .. rI.box) or "none") .. "; left " .. (lI and (lI.x .. "," .. lI.y .. " box " .. lI.box) or "none"))
    -- no words in either ring
    local rw, lw = ZeD.Belt.handName("p"), ZeD.Belt.handName("s")
    local words = 0
    for _, t in ipairs(H.texts) do if t.text == rw or t.text == lw then words = words + 1 end end
    check(words == 0, "155 no hand word drawn in the rings (" .. #H.texts .. " belt texts seen, " .. words .. " are a hand word)")
    -- the hint words: the game's own
    local gr, gl = getTextOrNull("IGUI_health_Right_Hand"), getTextOrNull("IGUI_health_Left_Hand")
    local ex1 = gr and (ZeD.textCase and ZeD.textCase(gr) or gr)
    local ex2 = gl and (ZeD.textCase and ZeD.textCase(gl) or gl)
    say("155 hint words: main '" .. tostring(rw) .. "' off '" .. tostring(lw) .. "'; the game's '" .. tostring(gr) .. "' / '" .. tostring(gl) .. "'")
    check(gr ~= nil and rw == ex1, "155 the main hand's hint is the game's Right Hand")
    check(gl ~= nil and lw == ex2, "155 the off hand's hint is the game's Left Hand")
    check(rw ~= "Primary" and lw ~= "Secondary", "155 the belt no longer says Primary / Secondary")
    shot("1_hands_empty")
    -- a two-handed item
    sledge = spawn("Base.Sledgehammer") or spawn("Base.Axe")
    if sledge then
        say("155 two-handed item: " .. tostring(sledge:getFullType()) .. ", isTwoHandWeapon " .. tostring(sledge:isTwoHandWeapon()))
        p:setPrimaryHandItem(sledge); p:setSecondaryHandItem(sledge)
    else
        check(false, "155 could not spawn Base.Sledgehammer or Base.Axe")
    end
    H.icons = {}
end)
add(900, function()
    local m, o = handBoxes()
    check(sledge ~= nil and p:getPrimaryHandItem() == sledge and p:getSecondaryHandItem() == sledge, "155 the two-handed item is in both hands")
    check(o ~= nil and o.peek == true and (o.peekW or 0) > 0 and (o.peekW or 0) <= o.w, "155 the off ring is a peek (peek " .. tostring(o and o.peek) .. ", peekW " .. tostring(o and o.peekW) .. " of " .. tostring(o and o.w) .. ")")
    check(not anyIcon("hand_"), "155 no empty-hand icon is drawn while one item fills both hands")
    say("155 peek: main " .. (m and (m.x .. "," .. m.w) or "-") .. ", off " .. (o and (o.x .. "," .. o.w) or "-"))
    shot("2_two_handed_peek")
    -- unequip and take it out
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    removeThing(sledge); sledge = nil
    H.icons = {}
end)
add(900, function()
    local m, o = handBoxes()
    check(lastIcon("hand_right") ~= nil and lastIcon("hand_left") ~= nil, "155 unequipped: both hand icons are back")
    check(o ~= nil and not o.peek, "155 unequipped: the off ring is a ring again")
    shot("3_hands_empty_again")
end)

-- ================================================================== 156 the loot drawer folds
local hammer
local function cwList() local w = CW(); return w and w._mainContent end
local function selectCard(win, it)
    local c = win._mainContent
    c._selectedItems = {}
    if it then c._selectedItems[it] = true end
    win._updateDrawer(c)
end
local function drawerSay(tag, w) say("156 " .. tag .. ": tab=" .. tostring(w._activeTab) .. " mode=" .. tostring(w._drawerMode) .. " open=" .. tostring(w._drawerOpen) .. " card=" .. tostring(w._drawerItem ~= nil) .. " tabUnder=" .. tostring(w._tabUnder)) end
local function placeholderSeen()
    local n = {}
    local coming = ZeD.tr and ZeD.tr("UI_ZeD_World_ComingSoon") or ""
    for _, t in ipairs(H.texts) do
        local lo = string.lower(t.text)
        if t.tag ~= "belt" and (lo:find("placeholder", 1, true) or lo:find("coming soon", 1, true) or (coming ~= "" and coming ~= "UI_ZeD_World_ComingSoon" and t.text == coming)) then n[#n + 1] = t.tag .. ":" .. t.text end
    end
    return n
end
add(400, function()
    CWm.openTab(0, "loot")
    hammer = spawn("Base.Hammer")
    H.texts = {}
    local w = CW()
    hookTexts(w, "char-window"); hookTexts(w._drawerPanel, "char-drawer")
    local ww = WW()
    hookTexts(ww, "world-window"); hookTexts(ww._drawerPanel, "world-drawer")
end)
addWhen(4000, function() return cwList() ~= nil and cwList()._inventory == p:getInventory() end, function() end)
add(500, function()
    local w, c = CW(), cwList()
    check(hammer ~= nil and c ~= nil and c._inventory == p:getInventory(), "156 setup: the Character list shows the carried inventory with a hammer in it")
    selectCard(w, hammer)
    drawerSay("card open", w)
    check(w._drawerItem == hammer and w._drawerMode == "item" and w._drawerOpen == true, "156 a Loot item card opens (item mode, drawer open)")
end)
add(900, function()
    shot("4_char_card_open")
    -- (the card put in tab mode over Loot, as a restored state or a hidden tab leaves it: it stays the card)
    local w = CW()
    w._drawerMode = "tab"; w._drawerOpen = true
end)
add(700, function()
    local w = CW()
    drawerSay("tab mode with a card", w)
    check(w._drawerMode == "item" and w._drawerOpen == true and w._tabUnder == nil, "156 tab mode on Loot with a card up becomes the card (no tab drawer)")
    selectCard(w, nil)   -- the card closed
end)
add(900, function()
    local w = CW()
    drawerSay("card closed", w)
    check(w._drawerItem == nil and w._drawerMode == nil and w._drawerOpen == false, "156 closing the card folds the drawer (no half card left)")
    shot("5_char_card_closed")
    H.texts = {}
    w._drawerMode = "tab"; w._drawerOpen = true   -- (a restored tab drawer on Loot with nothing in it)
end)
add(700, function()
    local w = CW()
    drawerSay("tab mode, nothing in it", w)
    check(w._drawerMode ~= "tab" and w._drawerOpen == false and w._tabUnder == nil, "156 Character: a tab drawer on Loot with nothing in it folds")
    local ph = placeholderSeen()
    check(#ph == 0, "156 Character: no placeholder line drawn (" .. #ph .. " seen" .. (ph[1] and (": " .. ph[1]) or "") .. ", " .. #H.texts .. " texts)")
    shot("6_char_folded")
    -- the World window's twin
    local ww = WW()
    ww._drawerMode = "tab"; ww._drawerOpen = true
    H.texts = {}
end)
add(700, function()
    local ww = WW()
    say("156 World: tab=" .. tostring(ww._activeTab) .. " mode=" .. tostring(ww._drawerMode) .. " open=" .. tostring(ww._drawerOpen) .. " tabUnder=" .. tostring(ww._tabUnder))
    check(ww._activeTab == "loot" and ww._drawerMode ~= "tab" and ww._drawerOpen == false and ww._tabUnder == nil, "156 World: a tab drawer on Loot with nothing in it folds")
    local ph = placeholderSeen()
    check(#ph == 0, "156 World: no Coming soon / placeholder line drawn (" .. #ph .. " seen" .. (ph[1] and (": " .. ph[1]) or "") .. ")")
    shot("7_world_folded")
    unhookAll(); hookEmpty()   -- (the texts hooks are off; next the empty line's hook)
    H.empties = {}
end)

-- ================================================================== 157 Nothing here.
local function emptyFor(panel)
    for k = #H.empties, 1, -1 do if H.empties[k].panel == panel then return H.empties[k].text end end
end
local function wantEmpty() return ZeD.tr("UI_ZeD_Inv_Empty") end
local function checkNothing(tag, text)
    local want = wantEmpty()
    say("157 " .. tag .. ": drawn '" .. tostring(text) .. "', key UI_ZeD_Inv_Empty says '" .. tostring(want) .. "'")
    check(text ~= nil and text == want, "157 " .. tag .. ": the empty list draws the key's words")
    if want and want ~= "UI_ZeD_Inv_Empty" and string.find(want, "Nothing", 1, true) then
        check(text == "Nothing here.", "157 " .. tag .. ": the words are Nothing here. (not Nothing in here.)")
    end
end
-- the QA spot's floor holds things: the character goes to a bare tile nearby (no world items, nothing built on it),
-- and comes back at the end
local homePos
local function goTo(x, y, z)
    pcall(function() p:teleportTo(x, y, z) end)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end
local function bareTile(sq)
    if not sq or not sq:isFree(false) then return false end
    local wo = sq:getWorldObjects()
    if wo and wo:size() > 0 then return false end
    local objs = sq:getObjects()
    return objs ~= nil and objs:size() <= 1
end
add(300, function()
    homePos = { p:getX(), p:getY(), p:getZ() }
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local found
    for r = 1, 8 do
        for dy = -r, r do for dx = -r, r do
            if not found and (math.abs(dx) == r or math.abs(dy) == r) then
                local sq = getCell():getGridSquare(px + dx, py + dy, pz)
                -- (its neighbors bare too: the crate is built beside the character)
                local nb = bareTile(sq) and bareTile(getCell():getGridSquare(px + dx + 1, py + dy, pz))
                if nb then found = { px + dx + 0.5, py + dy + 0.5, pz } end
            end
        end end
        if found then break end
    end
    check(found ~= nil, "157 setup: a bare tile was found near the QA spot" .. (found and (" (" .. found[1] .. "," .. found[2] .. ")") or ""))
    if found then goTo(found[1], found[2], found[3]) end
end)
add(2000, function()
    local ww = WW()
    WWm.openTab(0, "loot")
    local floor = ww._mainContent and ww._mainContent._inventory
    local n = floor and floor:getItems():size() or -1
    say("157 floor container: " .. tostring(floor and floor:getType()) .. ", " .. n .. " item(s)")
    check(n == 0, "157 setup: the floor tile under the character is empty (move the character to a bare tile if not)")
    H.empties = {}
end)
add(1500, function()
    local ww = WW()
    checkNothing("World, empty floor", emptyFor(ww._mainContent))
    shot("8_world_floor_empty")
end)
-- an empty crate beside the character (the World window's strip), then a carried empty bag (the Character window's)
local crate, crateSq, crateInv, bag, bagLoc, bagPrev
local function unwearBag()
    if bag then pcall(function() p:removeWornItem(bag) end) end
    if bagPrev and bagLoc then pcall(function() p:setWornItem(bagLoc, bagPrev) end) end
    bagPrev = nil
end
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for k = 0, infos:size() - 1 do
        local info = infos:get(k)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end
local function buildCrate()
    local info = findInfo("Base.Wood_Crate_Lvl1")
    if not info then return nil end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for _, o in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 } }) do
        local sq = getCell():getGridSquare(px + o[1], py + o[2], 0)
        if sq then
            p:setBuildCheat(true)
            local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
            b.buildCheat = true; b.player = pn; b.sq = sq
            local ok, valid = pcall(function() return b:isValid(sq) end)
            if ok and valid then pcall(function() b:create(px + o[1], py + o[2], 0, false, nil) end) end
            p:setBuildCheat(false)
            if ok and valid then return sq end
        end
    end
    return nil
end
add(300, function()
    crateSq = buildCrate()
    local objs = crateSq and crateSq:getObjects()
    for k = 0, (objs and objs:size() or 0) - 1 do
        local o = objs:get(k)
        if instanceof(o, "IsoThumpable") and o:getContainer() then crate = o end
    end
    crateInv = crate and crate:getContainer()
    check(crateInv ~= nil and crateInv:getItems():size() == 0, "157 setup: an empty crate was built beside the character")
    bag = spawn("Base.Bag_Schoolbag")
    -- (the strip lists a bag only when it is worn: the back's own bag is put back at the end)
    if bag then
        bagLoc = bag:getBodyLocation()
        bagPrev = p:getWornItem(bagLoc)
        pcall(function() p:setWornItem(bagLoc, bag) end)
    end
    check(bag ~= nil and p:isEquipped(bag), "157 setup: an empty schoolbag is worn")
end)
-- (the strips look for new containers every 30 frames)
addWhen(5000, function() return crateInv ~= nil and elFor(WW(), "worldContainerStrip", crateInv) ~= nil end, function() end)
add(300, function()
    local ww = WW()
    local el = crateInv and elFor(ww, "worldContainerStrip", crateInv)
    if check(el ~= nil and el.onActivate ~= nil, "157 the crate has a stop in the World window's container strip") then el.onActivate(ww, el) end
    H.empties = {}
end)
add(1200, function()
    local ww = WW()
    check(activeInv(ww) == crateInv, "157 the World list shows the crate")
    checkNothing("World, empty crate", emptyFor(ww._mainContent))
    shot("9_world_crate_empty")
    -- back to the container the list showed
    local el = keepInvPick.ww and elFor(ww, "worldContainerStrip", keepInvPick.ww)
    if el and el.onActivate then el.onActivate(ww, el) end
end)
addWhen(5000, function() return bag ~= nil and elFor(CW(), "charContainerStrip", bag:getInventory()) ~= nil end, function() end)
add(300, function()
    local w = CW()
    local el = bag and elFor(w, "charContainerStrip", bag:getInventory())
    if check(el ~= nil and el.onActivate ~= nil, "157 the bag has a stop in the Character window's container strip") then el.onActivate(w, el) end
    H.empties = {}
end)
add(1200, function()
    local w = CW()
    say("157 Character active container: " .. tostring(w._activeContainer) .. ", viewed " .. tostring(w._viewedContainer))
    checkNothing("Character, empty bag", emptyFor(w._mainContent))
    shot("10_char_bag_empty")
    local el = keepInvPick.cw and elFor(w, "charContainerStrip", keepInvPick.cw)
    if el and el.onActivate then el.onActivate(w, el) end
    unhookAll()
    if crate and crate:getSquare() then
        pcall(function() crate:getContainer():removeAllItems() end)
        pcall(function() crate:getSquare():transmitRemoveItemFromSquare(crate) end)
    end
    crate = nil
    unwearBag(); removeThing(bag); bag = nil
end)

-- ================================================================== 160 Dark text contrast
local function eff(c, bg)   -- a text color over its background, by the color's own alpha
    local a = c.a or 1
    return { r = c.r * a + bg.r * (1 - a), g = c.g * a + bg.g * (1 - a), b = c.b * a + bg.b * (1 - a) }
end
local function windowOver(world)   -- the window color (surf1 at its alpha) over a grey world
    local s = ZeD.T.surf1
    local a = s.a or 1
    return { r = s.r * a + world * (1 - a), g = s.g * a + world * (1 - a), b = s.b * a + world * (1 - a) }
end
local function rgb(c) return string.format("%d,%d,%d", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5)) end
local function contrastAt(accent)
    ZeD.applyTheme("dark", accent, nil)
    local T = ZeD.T
    local dark, white = windowOver(0), windowOver(1)
    local body, sec, dim = eff(T.text, dark), eff(T.textSec, dark), eff(T.textDim, dark)
    local cb, cs, cd = ZeD.contrast(body, dark), ZeD.contrast(sec, dark), ZeD.contrast(dim, dark)
    local sw2, dw = ZeD.contrast(eff(T.textSec, white), white), ZeD.contrast(eff(T.textDim, white), white)
    say(string.format("160 Dark %s: window %s (surf1 alpha %.2f); body T.text %s alpha %.2f = %.2f:1; secondary T.textSec %s = %.2f:1; dim T.textDim %s = %.2f:1; over a white world: secondary %.2f:1, dim %.2f:1",
        accent, rgb(dark), T.surf1.a or 1, rgb(body), T.text.a or 1, cb, rgb(sec), cs, rgb(dim), cd, sw2, dw))
    check(cb >= 12, "160 Dark/" .. accent .. ": body text >= 12:1 (" .. string.format("%.2f", cb) .. ")")
    check(cs >= 6.9, "160 Dark/" .. accent .. ": secondary text >= 7:1 within 0.1 (" .. string.format("%.2f", cs) .. ")")
    check(cd >= 4.5, "160 Dark/" .. accent .. ": dim text >= 4.5:1 (" .. string.format("%.2f", cd) .. ")")
    check(sw2 >= 4.45 and dw >= 4.45, "160 Dark/" .. accent .. ": secondary and dim >= 4.5:1 on the window over a white world (" .. string.format("%.2f / %.2f", sw2, dw) .. ")")
    check(cb > cs and cs > cd, "160 Dark/" .. accent .. ": the three tiers run body > secondary > dim")
    return cb, cs, cd
end
add(400, function()
    say("160 the item card's label uses T.textSec, its value T.text, its dim tags T.textDim (ItemCardOrganism / Atoms.drawSecondary)")
    CWm.openTab(0, "loot")
    local w = CW()
    if hammer then selectCard(w, hammer) end
    contrastAt("teal")
end)
add(1000, function() shot("11_dark_teal_card") end)
add(300, function()
    check(ZeD.AccentColors and ZeD.AccentColors.orange ~= nil, "160 the Orange accent exists")
    contrastAt("orange")
end)
add(1000, function()
    shot("12_dark_orange_card")
    -- the player's own theme back, the card closed
    ZeD.applyTheme(keepTheme.base, keepTheme.accent, keepTheme.size)
    selectCard(CW(), nil)
    say("160 theme restored: " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
    removeThing(hammer); hammer = nil
end)

-- ================================================================== 162 a stack's bar is its emptiest item's
local LEVELS = { 0, 0.3, 0.6, 1.0 }
local bottles = {}
local playerKey, playerGrid
local WB = "Base.WaterBottle"
local function wbStack(c)
    for rep, s in pairs(c and c._stacks or {}) do
        if s.key == WB then return rep, s end
    end
end
local function barOf(c, it, h, cell)
    local y = c._itemRenderYMap and c._itemRenderYMap[it]
    if not y then return nil end
    local x = (c._itemRenderXMap and c._itemRenderXMap[it]) or 0
    local best
    for _, r in ipairs(H.bars) do
        if r.panel == c and r.y >= y - 1 and r.y < y + h and (not cell or (r.x >= x - 1 and r.x <= x + cell)) then best = r end
    end
    return best
end
local function emptiest(s)
    local m = 1
    for _, it in ipairs(s.items) do local k, f = IM.of(it); if k == "fluid" and f < m then m = f end end
    return m
end
local function barCheck(tag, sortAsc, grid)
    local c = CW()._mainContent
    local rep, s = wbStack(c)
    if not check(rep ~= nil and s.count >= 4, "162 " .. tag .. ": the water bottles are one stack of " .. tostring(s and s.count)) then return end
    local want = emptiest(s)
    local own = select(2, IM.of(rep))
    local r = barOf(c, rep, grid and c._gridCell or ZeD.T.rowH, grid and c._gridCell or nil)
    say(string.format("162 %s: sort Cond %s, the stack's head item holds %.2f, the emptiest holds %.2f, bar drawn %s", tag, sortAsc and "ascending" or "descending", own or -1, want, r and string.format("%.2f", r.f) or "none (row not drawn)"))
    check(near(want, 0, 0.001), "162 " .. tag .. ": the emptiest bottle is the empty one (" .. string.format("%.2f", want) .. ")")
    if check(r ~= nil, "162 " .. tag .. ": the stack's bar was drawn") then
        check(near(r.f, want, 0.01), "162 " .. tag .. ": the bar reads the emptiest (drawn " .. string.format("%.2f", r.f) .. ", wanted " .. string.format("%.2f", want) .. ")")
    end
    local k, f = IM.ofStack(rep, s.items)
    check(k == "fluid" and near(f, want, 0.001), "162 " .. tag .. ": ItemMeter.ofStack says the same (" .. tostring(f) .. ")")
end
-- a view of the player's list, in a sort order, with the bottles' row in sight and the bars recorded afresh
local function setView(grid, asc)
    local c = CW()._mainContent
    IR.setGridKey(playerKey, grid)
    c._sortCol, c._sortAsc = "cond", asc
    IR.dirtyModels()
    H.bars = {}
end
local function ready() local c = CW()._mainContent; local rep = wbStack(c); return rep ~= nil and revealRow(CW(), rep) end
-- rows back in view (the Deck's list scrolls them out), then the bars drawn afresh and the head's seen
local function waitBars(grid)
    addWhen(6000, function()
        local c = CW()._mainContent
        local rep = wbStack(c)
        if not (rep and revealRow(CW(), rep)) then return false end
        return barOf(c, rep, grid and c._gridCell or ZeD.T.rowH, grid and c._gridCell or nil) ~= nil
    end, function() end)
end
add(300, function()
    for _, f in ipairs(LEVELS) do
        local it = spawn(WB)
        bottles[#bottles + 1] = it
        pcall(function()
            local fc = it:getFluidContainer()
            fc:Empty()
            if f > 0 then fc:addFluid(FluidType.Water, fc:getCapacity() * f) end
        end)
    end
    local out = {}
    for _, it in ipairs(bottles) do local k, f = IM.of(it); out[#out + 1] = tostring(k) .. "=" .. string.format("%.2f", f or -1) end
    say("162 bottles: " .. table.concat(out, " "))
    check(#bottles == 4 and near(select(2, IM.of(bottles[1])), 0, 0.001) and near(select(2, IM.of(bottles[4])), 1, 0.01), "162 setup: four bottles, one empty and the rest watered")
    CWm.openTab(0, "loot")
    local c = CW()._mainContent
    playerKey = IR.containerKey(p:getInventory(), p)
    playerGrid = IR.isGridKey(playerKey)
    keepSort = { c._sortCol, c._sortAsc }
    say("162 the player's list: " .. (playerGrid and "grid" or "list") .. " sorted " .. tostring(c._sortCol) .. (c._sortAsc and " asc" or " desc") .. " (" .. tostring(playerKey) .. ")")
    hookBars()
    setView(false, true)
end)
-- list, ascending then descending (descending puts the fullest bottle first: the head item is no longer the emptiest)
addWhen(5000, ready, function() end)
waitBars(false)
add(300, function() barCheck("list", true, false); shot("13_stack_list_asc") end)
add(300, function() setView(false, false) end)
addWhen(5000, ready, function() end)
waitBars(false)
add(300, function() barCheck("list", false, false); shot("14_stack_list_desc") end)
-- grid, both orders
add(300, function() setView(true, true) end)
addWhen(5000, ready, function() end)
waitBars(true)
add(300, function() barCheck("grid", true, true); shot("15_stack_grid_asc") end)
add(300, function() setView(true, false) end)
addWhen(5000, ready, function() end)
waitBars(true)
add(300, function() barCheck("grid", false, true); shot("16_stack_grid_desc") end)
-- the stack opened in the list: each row its own level
add(300, function()
    setView(false, true)
    local c = CW()._mainContent
    c._expandedStacks = c._expandedStacks or {}
    c._expandedStacks[WB] = true
    IR.dirtyModels()
end)
local function bottleRows(c)
    local n = 0
    for _, it in ipairs(c._flatItems or {}) do if it:getFullType() == WB then n = n + 1 end end
    return n
end
addWhen(5000, function()
    local c = CW()._mainContent
    if bottleRows(c) < 4 then return false end
    for _, it in ipairs(c._flatItems or {}) do if it:getFullType() == WB and not revealRow(CW(), it) then return false end end
    return true
end, function() H.bars = {} end)
addWhen(6000, function()
    local c = CW()._mainContent
    local n = 0
    for _, it in ipairs(c._flatItems or {}) do
        if it:getFullType() == WB then
            if not revealRow(CW(), it) then return false end
            if barOf(c, it, ZeD.T.rowH, nil) then n = n + 1 end
        end
    end
    return n >= 4
end, function() end)
add(300, function()
    local c = CW()._mainContent
    local rows = bottleRows(c)
    check(rows >= 4, "162 the stack opens into its own rows (" .. rows .. " bottle rows)")
    local rep, s = wbStack(c)
    local seen, okRows, line = 0, 0, {}
    for _, it in ipairs(c._flatItems or {}) do
        if it:getFullType() == WB then
            local k, own = IM.of(it)
            local r = barOf(c, it, ZeD.T.rowH, nil)
            line[#line + 1] = string.format("%s own %.2f bar %s", it == rep and "head" or "row", own or -1, r and string.format("%.2f", r.f) or "none")
            if it ~= rep then
                seen = seen + 1
                if r and near(r.f, own, 0.01) then okRows = okRows + 1 end
            end
        end
    end
    say("162 open stack: " .. table.concat(line, "; ") .. " (the head row keeps the stack's bar as drawn)")
    check(seen >= 3 and okRows == seen, "162 each opened row's bar is its own bottle's level (" .. okRows .. " of " .. seen .. ")")
    shot("17_stack_open")
    c._expandedStacks[WB] = nil
    IR.dirtyModels()
end)

-- ================================================================== put everything back
add(500, function()
    unhookAll()
    pcall(function() ZeD.applyTheme(keepTheme.base, keepTheme.accent, keepTheme.size) end)
    pcall(function()
        local c = CW()._mainContent
        if keepSort then c._sortCol, c._sortAsc = keepSort[1], keepSort[2] end
        if playerKey then IR.setGridKey(playerKey, playerGrid == true) end
        c._expandedStacks = c._expandedStacks or {}
        c._expandedStacks[WB] = nil
        c._selectedItems = {}
        IR.dirtyModels()
    end)
    pcall(function() selectCard(CW(), nil) end)
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    unwearBag()
    if homePos then goTo(homePos[1], homePos[2], homePos[3]) end
    for _, it in ipairs(S.added) do removeThing(it) end
    if crate and crate:getSquare() then
        pcall(function() crate:getContainer():removeAllItems() end)
        pcall(function() crate:getSquare():transmitRemoveItemFromSquare(crate) end)
    end
    if keepHands then
        if keepHands[1] then p:setPrimaryHandItem(keepHands[1]) end
        if keepHands[2] then p:setSecondaryHandItem(keepHands[2]) end
    end
    if keepPins then
        p:getModData().ZeD_WinPinned = keepPins
        for _, pair in ipairs({ { CW(), "char" }, { WW(), "world" } }) do
            local win, k = pair[1], pair[2]
            local a, b = keepPins[k .. "Inv"], keepPins[k .. "Tabs"]
            if a == nil and b == nil then a, b = keepPins[k] == true, keepPins[k] == true end
            pcall(function() ZeD.Halves.setPin(win, "inv", a == true); ZeD.Halves.setPin(win, "drawer", b == true) end)
        end
    end
end)
add(800, function()
    local left = 0
    for _, it in ipairs(S.added) do if it:getContainer() or (it.getWorldItem and it:getWorldItem()) then left = left + 1 end end
    check(left == 0, "cleanup: everything spawned is gone (" .. left .. " left)")
    say("cleanup: theme " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize) .. ", player's list " .. (playerGrid and "grid" or "list"))
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)

local function drive()
    local now = getTimestampMs()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if st.cond then
        local okC, met = pcall(st.cond)
        if not (okC and met) and now - t0 < st.ms then return end
    elseif now - t0 < st.ms then
        return
    end
    t0 = now; i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
