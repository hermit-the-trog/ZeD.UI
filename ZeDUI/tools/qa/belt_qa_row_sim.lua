-- ZeDUI/tools/qa/belt_qa_row_sim.lua  (QA belt row run, Nov 22 2026): the three faults QA saw in the game, with no game
-- running. The real functions are cut out of their files; the game's objects are small stubs.
--   PEND    the belt's bag button on a bag the Character window's list does not have yet: kept as pending on the
--           window, shown alone on the first frame whose list has it; a second click finds it (showsBagAlone);
--           a bag that never comes falls back to the main inventory alone after both bounds, not before
--   KEEP    a menu with zedKeepOrder: the rows in the order added, each with its own iconTexture (no ZeD icon, no
--           tint), one group (the list draws no rule between rows), applyPins leaves the order; without the flag
--           applyPins still groups by category (the old behavior stays for every other menu); the reused menu's
--           ISContextMenu.get clears the flag
--   LIGHT   the World window's light: crate A on show lit, then crate B on show: B lit, A dark (highlight and
--           outline off); a light left by an earlier window is put out by the window on show; an old window
--           lights nothing; a stale "lit elsewhere" mark (no menu up) does not keep A lit, a live one (menu up) does
-- Run from the repo root: lua51 ZeDUI/tools/qa/belt_qa_row_sim.lua

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end
local ZD = "42/media/lua/client/ZeD/"
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

local NOW = 1000
getTimestampMs = function() return NOW end

-- ============================================================================ PEND
do
    local cw = slurp(ZD .. "ZeD_CharacterWindow.lua")
    ZeD_CharacterWindow = {}
    _charWins = {}
    local switched = 0
    _switchTabForNav = function(win, content, tab) win._activeTab = tab; switched = switched + 1 end
    function ZeD_CharacterWindow._showAlone(win, content, cIdx)
        win._activeContainer = cIdx
        win._viewedContainer = (cIdx ~= 1) and cIdx or nil
        win._mainVisible = cIdx == 1
        win._mcSelected = {}
    end
    local a = assert(cw:find("ZeD_CharacterWindow.BAG_PENDING_MS, ZeD_CharacterWindow.BAG_PENDING_FRAMES", 1, true))
    assert(loadstring(cw:sub(a, (cw:find("\n", a, true)))))()
    assert(loadstring(cut(cw, "function ZeD_CharacterWindow.containerIndex(")))()
    assert(loadstring(cut(cw, "function ZeD_CharacterWindow.showBagAlone(")))()
    assert(loadstring(cut(cw, "function ZeD_CharacterWindow._applyBagPending(")))()
    assert(loadstring(cut(cw, "function ZeD_CharacterWindow.showsBagAlone(")))()
    ok(cw:find("if win._bagAlonePending then ZeD_CharacterWindow._applyBagPending(win, content) end", 1, true) ~= nil,
        "PEND the strip's list refresh applies a pending bag")

    local MAIN, BAG, OTHER = { n = "main" }, { n = "backpack" }, { n = "fanny" }
    local content = {}
    local win = { _mainContent = content, _containers = { { inventory = MAIN, isMain = true } }, _activeTab = "health",
        _activeContainer = 1, _mcSelected = {}, _mainVisible = true }
    _charWins[0] = win
    -- the bag button's click on a window whose list does not have the bag
    ok(ZeD_CharacterWindow.showBagAlone(0, BAG) == true, "PEND showBagAlone answers true while it waits")
    ok(win._bagAlonePending and win._bagAlonePending.inv == BAG, "PEND the bag kept as pending on the window")
    ok(win._containerTimer == 30, "PEND a fresh list asked for on the next frame")
    ok(win._activeContainer == 1 and win._activeTab == "health", "PEND nothing changes before the list has the bag")
    ok(ZeD_CharacterWindow.showsBagAlone(0, BAG) == true, "PEND a second click finds the bag (pending) and closes the pair")
    ok(ZeD_CharacterWindow.showsBagAlone(0, OTHER) == false, "PEND another bag is not the one pending")
    -- frames go by without the bag
    for _ = 1, 3 do ZeD_CharacterWindow._applyBagPending(win, content) end
    ok(win._bagAlonePending ~= nil and win._activeContainer == 1, "PEND still waiting a few frames in")
    -- the list is rebuilt with the bag in it
    win._containers[2] = { inventory = OTHER }
    win._containers[3] = { inventory = BAG }
    ZeD_CharacterWindow._applyBagPending(win, content)
    ok(win._bagAlonePending == nil, "PEND applied and cleared")
    ok(win._activeTab == "loot" and win._activeContainer == 3 and win._viewedContainer == 3 and win._mainVisible == false,
        "PEND the backpack alone on Loot")
    ok(ZeD_CharacterWindow.showsBagAlone(0, BAG) == true, "PEND a second click finds the backpack alone")
    -- in the list already: shown at once, no pending
    ok(ZeD_CharacterWindow.showBagAlone(0, OTHER) == true and win._activeContainer == 2 and win._bagAlonePending == nil,
        "PEND a bag in the list shows at once")
    -- a bag that never comes: the main inventory after both bounds, not before
    local GONE = { n = "gone" }
    ZeD_CharacterWindow.showBagAlone(0, GONE)
    for _ = 1, ZeD_CharacterWindow.BAG_PENDING_FRAMES + 5 do ZeD_CharacterWindow._applyBagPending(win, content) end
    ok(win._bagAlonePending ~= nil and win._activeContainer == 2, "PEND the frame bound alone does not give up early (time not up)")
    NOW = NOW + ZeD_CharacterWindow.BAG_PENDING_MS + 1
    ZeD_CharacterWindow._applyBagPending(win, content)
    ok(win._bagAlonePending == nil and win._activeContainer == 1 and win._mainVisible == true,
        "PEND past both bounds: the main inventory alone")
    -- no window: false, nothing thrown
    _charWins[0] = nil
    ok(ZeD_CharacterWindow.showBagAlone(0, BAG) == false, "PEND no window: false")
    ok(ZeD_CharacterWindow.showsBagAlone(0, BAG) == false, "PEND no window: not shown")
end

-- ============================================================================ KEEP
do
    require = function() end
    getText = function(k) return k end
    getTexture = function(p) return { path = p } end
    instanceof = function() return false end
    ISContextMenu = { onMouseMoveOutside = function() end }
    ISInventoryPage = { OnObjectHighlighted = function() end }
    getSpecificPlayer = function() return { getModData = function() return {} end } end
    local PXT = { px = "backpack" }
    ZeD = { tr = function(k) return k end, ContextMenu = {},
        -- ZeD's name-to-icon map knows all three names (the backpack drawing), as the game's map knows "Inventory"
        ContextIcons = { Inventory = "bp", ["Leather Satchel"] = "bp", ["Fanny Pack"] = "bp" }, ContextPxIcons = { bp = "backpack" },
        PxIcon = { has = function() return true end, tex = function(id) return { px = id } end } }
    dofile(ZD .. "ContextMenuRegistry.lua")
    local R = ZeD.ContextMenu.Registry or ZeD.ContextMenu.Registry
    assert(R, "the registry")
    -- the belt's bag menu: Inventory with the pocket, then each bag with its own picture (param1 a player number,
    -- as B.bagMenu adds them)
    local POCKET, SATCHEL, FANNY = { t = "pocket" }, { t = "satchel" }, { t = "fanny" }
    local function menuOf(keep)
        local m = { zedKeepOrder = keep, options = {
            { name = "Inventory", iconTexture = POCKET, param1 = 0 },
            { name = "Leather Satchel", iconTexture = SATCHEL, param1 = 0 },
            { name = "Fanny Pack", iconTexture = FANNY, param1 = 0 },
        } }
        return m
    end
    local m = menuOf(true)
    ok(R.keepsOrder(m) == true and R.keepsOrder({}) == false and R.keepsOrder(nil) == false, "KEEP keepsOrder reads the flag")
    ok(R.keepsOrder({ parent = m }) == true, "KEEP a submenu of a kept menu keeps too")
    local tree = R.buildActionsFromVanilla(m.options, nil, m)
    -- an applyPins with every row's group set apart would reorder: it must leave the kept tree
    tree[1].category, tree[2].category = "ADMIN", "USE"
    R.applyPins(tree, nil, 0)
    ok(#tree == 3 and tree[1].name == "Inventory" and tree[2].name == "Leather Satchel" and tree[3].name == "Fanny Pack",
        "KEEP the rows in the order added (applyPins leaves them)")
    ok(tree[1].iconTexture == POCKET and tree[2].iconTexture == SATCHEL and tree[3].iconTexture == FANNY,
        "KEEP each row's own iconTexture")
    ok(tree[1].pxIcon == nil and tree[2].pxIcon == nil and tree[3].pxIcon == nil, "KEEP no ZeD pixel icon on any row")
    ok(not tree[1].iconTintable and not tree[2].iconTintable and not tree[3].iconTintable, "KEEP no tint (colored pictures)")
    local t2 = R.buildActionsFromVanilla(m.options, nil, m)
    ok(t2[1].category == t2[2].category and t2[2].category == t2[3].category, "KEEP one group for every row")
    -- the list's rules between groups (ZeD_ContextList's rowsOf): none for the kept menu
    local cl = slurp(ZD .. "ZeD_ContextList.lua")
    local env = {}
    local chunk = cut(cl, "local LIST_GROUP = ") .. cut(cl, "local function groupOf(def)") .. cut(cl, "local function rowsOf(items)")
        .. "return rowsOf"
    local rowsOf = assert(loadstring(chunk))()
    local rows = rowsOf(t2)
    local seps = 0
    for _, r in ipairs(rows) do if r.sep then seps = seps + 1 end end
    ok(#rows == 3 and seps == 0, "KEEP the list draws three rows, no rule")
    -- a row without its own icon in a kept menu: no ZeD stand-in either
    local m2 = { zedKeepOrder = true, options = { { name = "Inventory" } } }
    local t3 = R.buildActionsFromVanilla(m2.options, nil, m2)
    ok(t3[1].iconTexture == nil and t3[1].pxIcon == nil, "KEEP no icon of its own: none drawn, no stand-in")
    -- every other menu: applyPins still groups by category (the old order rule stays)
    local plain = menuOf(nil)
    local t4 = R.buildActionsFromVanilla(plain.options, nil, plain)
    t4[1].category, t4[2].category, t4[3].category = "ADMIN", "USE", "ADMIN"
    R.applyPins(t4, nil, 0)
    local cats = R.CATEGORIES or {}
    local pos = {}
    for i, c in ipairs(cats) do pos[c] = i end
    local sorted = true
    for i = 2, #t4 do if (pos[t4[i - 1].category] or 99) > (pos[t4[i].category] or 99) then sorted = false end end
    ok(t4.zedKeepOrder == nil and sorted, "KEEP a plain menu is still grouped by category")
    -- (the map is live in this sim: a plain menu's rows take its drawing, so the KEEP icon checks above prove the flag)
    local t5 = R.buildActionsFromVanilla(plain.options, nil, plain)
    ok(t5[1].pxIcon == "backpack" and t5[1].iconTexture ~= POCKET, "KEEP control: without the flag the map replaces Inventory's icon")
    -- the reused menu: ISContextMenu.get clears the flag (Overrides/ContextMenu.lua), so the belt sets it after get
    local ov = slurp(ZD .. "Overrides/ContextMenu.lua")
    local getSrc = cut(ov, "ISContextMenu.get = function(player, x, y)")
    ok(getSrc:find("context.zedKeepOrder = nil", 1, true) ~= nil, "KEEP ISContextMenu.get clears zedKeepOrder")
    -- the tree is built on the menu's first prerender (after the caller's options): the flag set any time before it
    ok(cut(ov, "function ISContextMenu:prerender()"):find("Registry.buildActionsFromVanilla(self.options, target, self)", 1, true) ~= nil,
        "KEEP the tree is built in the first prerender, from the menu itself")
end

-- ============================================================================ LIGHT
do
    local ww = slurp(ZD .. "ZeD_WorldWindow.lua")
    ZeD_WorldWindow = {}
    _worldWins = {}
    local MENU_UP = false
    getPlayerContextMenu = function() return { getIsVisible = function() return MENU_UP end } end
    instanceof = function() return false end
    local OUTLINE = true
    local col = { getR = function() return 1 end, getG = function() return 1 end, getB = function() return 1 end }
    getCore = function() return { getOptionDoContainerOutline = function() return OUTLINE end,
        getObjectHighlitedColor = function() return col end, getWorldItemHighlightColor = function() return col end } end
    ZeD.Input = nil
    local function obj(name)
        local o = { name = name, hl = false, ol = false }
        function o:setHighlighted(_, v) self.hl = v end
        function o:setOutlineHighlight(_, v) self.ol = v end
        function o:setOutlineHlAttached() end
        function o:setOutlineHighlightCol() end
        function o:setHighlightColor() end
        return o
    end
    local A, B = obj("A"), obj("B")
    local function inv(o) return { getParent = function() return o end } end
    local a0 = assert(ww:find("ZeD_WorldWindow._litElsewhere = ZeD_WorldWindow._litElsewhere or", 1, true))
    assert(loadstring(ww:sub(a0, ww:find("\n", a0, true))))()
    assert(loadstring(cut(ww, "function ZeD_WorldWindow._parentOf(")))()
    assert(loadstring(cut(ww, "function ZeD_WorldWindow._unlight(")))()
    local a1 = assert(ww:find("ZeD_WorldWindow._litFor = ZeD_WorldWindow._litFor or {}", 1, true))
    assert(loadstring(ww:sub(a1, ww:find("\n", a1, true))))()
    assert(loadstring(cut(ww, "function ZeD_WorldWindow._litTable(")))()
    assert(loadstring(cut(ww, "function ZeD_WorldWindow._elsewhereHolds(")))()
    assert(loadstring(cut(ww, "function ZeD_WorldWindow._unlightAll(")))()
    assert(loadstring(cut(ww, "function ZeD_WorldWindow._lightShown(")))()
    local function newWin()
        return { playerNum = 0, _activeTab = "loot", _mcSelected = {}, _mainVisible = true, _activeContainer = 1,
            _containers = { { inventory = inv(A) }, { inventory = inv(B) } } }
    end
    local w = newWin()
    _worldWins[0] = w
    ZeD_WorldWindow._lightShown(w)
    ok(A.hl and A.ol and not B.hl, "LIGHT crate A on show: A lit and outlined, B dark")
    w._activeContainer = 2   -- a plain click shows B alone
    ZeD_WorldWindow._lightShown(w)
    ok(B.hl and B.ol, "LIGHT crate B on show: B lit and outlined")
    ok(not A.hl and not A.ol, "LIGHT the switch: A unlit, its outline off")
    -- a window built again over the old one: the old one's light is put out by the new one
    local w2 = newWin()
    w2._activeContainer = 1
    _worldWins[0] = w2
    ZeD_WorldWindow._lightShown(w2)
    ok(A.hl and not B.hl and not B.ol, "LIGHT a light left by the earlier window goes out when the new one shows A")
    -- the old window still drawing lights nothing
    ZeD_WorldWindow._lightShown(w)
    ok(A.hl and not B.hl, "LIGHT the old window lights nothing")
    -- a stale lit-elsewhere mark on A (no menu up) does not keep it lit after the switch
    ZeD_WorldWindow._litElsewhere[1][A] = true
    w2._activeContainer = 2
    ZeD_WorldWindow._lightShown(w2)
    ok(not A.hl and not A.ol and B.hl, "LIGHT a stale mark (no menu up) does not keep A lit")
    ok(ZeD_WorldWindow._litElsewhere[1][A] == nil, "LIGHT the stale mark dropped")
    -- a live mark (a menu up, the right-click menu's hover on A) is left alone
    A.hl = true
    ZeD_WorldWindow._litElsewhere[1][A] = true
    MENU_UP = true
    ZeD_WorldWindow._lightShown(w2)
    ok(A.hl, "LIGHT a menu holding A's light: ZeD leaves A alone")
    MENU_UP = false
    ZeD_WorldWindow._litElsewhere[1][A] = nil
    A.hl = false
    -- close: nothing stays lit
    ZeD_WorldWindow._unlightAll(w2)
    ok(not B.hl and not B.ol, "LIGHT the close puts everything out")
    -- the window rolled up: nothing lit
    ZeD_WorldWindow._lightShown(w2)
    w2.windowShaded = true
    ZeD_WorldWindow._lightShown(w2)
    ok(not B.hl, "LIGHT rolled up: dark")
end

print(string.format("belt_qa_row_sim: %d checks, %d failed", pass + fail, fail))
if fail > 0 then os.exit(1) end
