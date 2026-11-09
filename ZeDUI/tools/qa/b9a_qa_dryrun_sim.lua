-- ZeDUI/tools/qa/b9a_qa_dryrun_sim.lua  (Nov 8 2026, hotfix 0.3.0-beta9a's QA scripts): a dry run of the nine
-- zedqa_b9a_*.lua scripts and zedqa_dual_pin.lua with no game running. Each script is loaded on a stub world in the
-- state QA's prelude leaves (both windows open, pinned whole, as zedqa_pin_windows does) and stepped on a fake clock
-- with a stand-in for the real-mouse helper (release_check_mouse.ps1): it takes ONE request at a time from
-- zedqa_click.txt, deletes it, moves the pointer, and writes zedqa_click_done.txt a quarter second later.
-- What it shows: every script runs to DONE with no Lua error in its steps ("ERR step"), never writes a mouse request
-- while one is still unread (two in a row overwrote each other in the game: drags never started), and every request
-- names a point (no nil in "move x y"). What it can't show: whether the halves, drags and cards behave (the stub
-- windows only hold the fields the scripts read); that is the game's run (batch_b9a.ps1).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/b9a_qa_dryrun_sim.lua
-- It prints FAIL lines and a last line "b9a_qa_dryrun_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]b9a_qa_dryrun_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local QA = ROOT .. "ZeDUI/tools/qa/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE STUB WORLD (rebuilt for each script)
-- ---------------------------------------------------------------------------
local CLOCK, MX, MY, FILES, LOG, REQS, OVERWRITES, BADREQ, HELPER
local function panel(x, y, w, h, parent)
    local o = { x = x, y = y, w = w, h = h, parent = parent, visible = true }
    function o:getX() return self.x end
    function o:getY() return self.y end
    function o:getAbsoluteX() return (self.parent and self.parent:getAbsoluteX() or 0) + self.x end
    function o:getAbsoluteY() return (self.parent and self.parent:getAbsoluteY() or 0) + self.y end
    function o:getWidth() return self.w end
    function o:getHeight() return self.h end
    function o:isVisible() return self.visible end
    function o:getMouseX() return MX - self:getAbsoluteX() end
    function o:getMouseY() return MY - self:getAbsoluteY() end
    return o
end
local function item(ft, inv)
    local it = { ft = ft, inv = inv }
    function it:getFullType() return self.ft end
    function it:getContainer() return self.inv end
    function it:getDisplayName() return self.ft end
    return it
end
local function container(kind)
    local c = { kind = kind, items = {} }
    function c:AddItem(ft) local it = item(ft, self); self.items[#self.items + 1] = it; return it end
    function c:getCountTypeRecurse(ft) local n = 0; for _, it in ipairs(self.items) do if it.ft == ft and it.inv == self then n = n + 1 end end; return n end
    function c:getItems() local s = self; return { size = function() return #s.items end, get = function(_, i) return s.items[i + 1] end } end
    function c:getType() return self.kind end
    return c
end

local function window(key)
    local left = key == "char"
    local w = panel(left and 200 or 2000, 0, 1617, 735)
    w.key, w.title, w.windowShaded, w.pinned = key, left and "Angel Cross" or "Ground", false, true
    w._activeTab, w._drawerOpen, w._drawerMode = "loot", false, nil
    w._halves = { inv = { pinned = true }, drawer = { pinned = true }, side = left and "left" or "right" }
    w._focusRing = { { zone = "list", elements = {} } }
    w._tabStripPanel = left and panel(0, 46, 63, 680, w) or nil
    w._actionTabStrip = (not left) and panel(1554, 46, 63, 680, w) or nil
    local strip = w._tabStripPanel or w._actionTabStrip
    strip._hitZones = {}
    for i, id in ipairs(left and { "loot", "health", "equip" } or { "loot", "maps" }) do
        strip._hitZones[i] = { id = "tab:" .. id, x = 4, y = (i - 1) * 60, w = 56, h = 56 }
    end
    w._containerStrip = panel(left and 1554 or 0, 46, 63, 680, w)
    local content = panel(left and 900 or 63, 46, 654, 680, w)
    content._flatItems, content._itemRenderYMap, content._itemRenderXMap, content._expandedStacks = {}, {}, {}, {}
    content._drag = { isActive = function() return false end }
    content._scroll = { handleMouseWheel = function() end }
    content._hitZones = {}
    -- (the list's hit zones as the renderer stamps them: each row's thing over its row)
    function content:hitZoneAt(lx, ly)
        for _, it in ipairs(self._flatItems) do
            local y = self._itemRenderYMap[it]
            if y and ly >= y and ly < y + 46 then return { id = it } end
        end
        for _, z in ipairs(self._hitZones) do if lx >= z.x and lx < z.x + z.w and ly >= z.y and ly < z.y + z.h then return z end end
        return nil
    end
    content._inventory = left and PINV or FLOOR
    w._mainContent = content
    w._curtain = { canRoll = function() return w._drawerOpen and w._drawerMode == "tab" end }
    w._equipExpanded = { held = false }
    w._equipSlotZones, w._equipBeltZones = {}, { { x = 300, y = 600, w = 40, h = 40, i = 1 } }
    w._equipDollAll = { { x = 600, y = 40, w = 80, h = 80, id = "back" } }
    w._equipPanel = panel(63, 46, 840, 680, w)
    w._equipDollPanel = w._equipPanel
    w._equipScroll = { scrollPos = 0, setScrollPos = function(sb, v) sb.scrollPos = math.max(0, math.min(1, v)) end }
    w._itemCard = panel(63, 46, 385, 680, w)
    w._itemCard._sb = { visible = true, x = 360, y = 120, width = 25, height = 500, arrowH = 25 }
    w._itemCard._headH, w._itemCard._contentH, w._itemCard._scrollPixels = 120, 900, 0
    function w:titleBarHeight() return 46 end
    function w:windowBoxRect() return { x = self.w - 30, y = 11, w = 23, h = 23 } end
    function w:setWindowShaded(on) self.windowShaded = on and true or false end
    function w:setPinned(on) self.pinned = on and true or false; self._halves.inv.pinned, self._halves.drawer.pinned = self.pinned, self.pinned end
    return w
end

local function list(win, inv)
    -- the list as the renderer stamps it: the container's things in rows
    local c = win._mainContent
    c._flatItems, c._itemRenderYMap = {}, {}
    for i, it in ipairs(inv.items) do
        if it.inv == inv then c._flatItems[#c._flatItems + 1] = it; c._itemRenderYMap[it] = 40 + (#c._flatItems - 1) * 46 end
    end
    c._hitZones = { { id = "stack:Base.Nails", x = 0, y = 40, w = 30, h = 46 } }
end

local function world()
    CLOCK, MX, MY, FILES, LOG, REQS, OVERWRITES, BADREQ = 100000, 1000, 1000, {}, {}, 0, 0, {}
    HELPER = { busyUntil = nil, line = nil }
    PINV, FLOOR = container("none"), container("floor")
    PLAYER = { md = {} }
    function PLAYER:getModData() return self.md end
    function PLAYER:getInventory() return PINV end
    function PLAYER:getCurrentSquare() return { AddWorldInventoryItem = function(_, ft) FLOOR:AddItem(ft) end } end
    function PLAYER:setIsAiming() end
    function PLAYER:getPlayerNum() return 0 end
    getPlayer = function() return PLAYER end
    getSpecificPlayer = getPlayer
    getTimestampMs = function() return CLOCK end
    getMouseX = function() return MX end
    getMouseY = function() return MY end
    getGameSpeed = function() return 1 end
    setGameSpeed = function() end
    getCore = function() return { getScreenWidth = function() return 3840 end, getScreenHeight = function() return 2160 end,
                                  TakeFullScreenshot = function() end } end
    print = function(s) LOG[#LOG + 1] = tostring(s) end
    -- the Lua folder's files, and the mouse helper reading them
    getFileWriter = function(name)
        local buf = {}
        return { write = function(_, s) buf[#buf + 1] = s end,
                 close = function()
                     local s = table.concat(buf)
                     if name == "zedqa_click.txt" then
                         REQS = REQS + 1
                         if FILES[name] ~= nil then OVERWRITES = OVERWRITES + 1 end
                         if not s:match("^%s*%a+ %d+ %d+%s*$") then BADREQ[#BADREQ + 1] = s end
                     end
                     FILES[name] = s
                 end }
    end
    getFileReader = function(name)
        local s = FILES[name]
        if s == nil then return nil end
        local done = false
        return { readLine = function() if done then return nil end; done = true; return s end, close = function() end }
    end
    Events = { OnTick = { fns = {} } }
    function Events.OnTick.Add(fn) Events.OnTick.fns[#Events.OnTick.fns + 1] = fn end
    function Events.OnTick.Remove(fn) for i, f in ipairs(Events.OnTick.fns) do if f == fn then table.remove(Events.OnTick.fns, i); return end end end

    CWIN, WWIN = window("char"), window("world")
    ZeD_CharacterWindow = { getWindow = function() return CWIN end, isOpen = function() return true end, toggleBothPaired = function() end,
        openTab = function(_, id) CWIN._activeTab = id; CWIN._drawerOpen = id ~= "loot"; CWIN._drawerMode = id ~= "loot" and "tab" or nil end }
    ZeD_WorldWindow = { getWindow = function() return WWIN end,
        openTab = function(_, id) WWIN._activeTab = id; WWIN._drawerOpen = id ~= "loot"; WWIN._drawerMode = id ~= "loot" and "tab" or nil end }
    local H = {}
    function H.setPin(w, half, on)
        w._halves[half].pinned = on and true or false; w.pinned = w._halves.inv.pinned and w._halves.drawer.pinned
        local t = PLAYER.md.ZeD_WinPinned or {}; PLAYER.md.ZeD_WinPinned = t
        t[w.key .. (half == "inv" and "Inv" or "Tabs")] = w._halves[half].pinned
    end
    function H.isPinned(w, half) return w._halves[half].pinned end
    function H.pinRect(w, e) return (e == "left") and { x = 37, y = 11, w = 23, h = 23 } or { x = w.w - 60, y = 11, w = 23, h = 23 } end
    function H.foldedTab(w) return w._halves.foldTab end
    function H.titleShift() return 30 end
    function H.drive() end
    function H.aim() end
    function H.showAll() end
    function H.split(w) return math.floor(w.w / 2) end
    BELT = { slots = { { i = 1, slot = { slotType = "Back" } } } }
    ZeD = {
        T = { rowH = 46, sp = { sm = 7, md = 14, titleBoxPad = 7 }, closeBoxSz = 23, px = function(v) return v end, fontF3 = "F3", scale = 1.75 },
        TM = { MeasureStringX = function(_, _, s) return #tostring(s) * 12 end },
        tr = function(k) return ({ UI_ZeD_Pin_Pin = "Pin to title bar", UI_ZeD_Pin_Unpin = "Unpin from title bar" })[k] or k end,
        Halves = H,
        Curtain = { finishUnroll = function(w) w._rolled = false end },
        Input = { Focus = { showWin = function() end, claimFocus = function() end } },
        Settings = { textSize = function() return 1 end, hiddenActions = function() return "folded" end },
        Pins = { kindOf = function() return "fluid" end },
        InventoryRenderer = { containerKey = function() return "floor" end, setGridKey = function() end, dirtyModels = function() end },
        EquipDoll = { view = function() return "list" end, setView = function() end },
        Belt = { slots = function() return BELT.slots end, detach = function() BELT.slots[1].item = nil end },
        ContextMenu = { Registry = { resolveIconForName = function() return "tex", "pin" end } },
    }
    ISInventoryPaneContextMenu = { dropItem = function(it) it.inv = FLOOR end }
    getPlayerContextMenu = function() return { options = { { name = "Pin to title bar", onSelect = function() end }, { name = "Unpin from title bar", onSelect = function() end } },
                                               hideAndChildren = function() end } end
end

-- the helper: one request at a time, a quarter second each, as release_check_mouse.ps1
local function helperTick()
    if HELPER.busyUntil then
        if CLOCK >= HELPER.busyUntil then FILES["zedqa_click_done.txt"] = "done " .. HELPER.line; HELPER.busyUntil = nil end
        return
    end
    local s = FILES["zedqa_click.txt"]
    if s then
        FILES["zedqa_click.txt"] = nil
        local btn, x, y = s:match("^%s*(%a+) (%d+) (%d+)")
        if x then MX, MY = tonumber(x), tonumber(y) end
        -- a press on a list starts its drag once the pointer moves past the threshold (as ZeD's DragState); up ends it
        if btn == "down" then
            HELPER.press = nil
            for _, w in ipairs({ CWIN, WWIN }) do
                local c = w._mainContent
                if MX >= c:getAbsoluteX() and MX < c:getAbsoluteX() + c.w and MY >= c:getAbsoluteY() and MY < c:getAbsoluteY() + c.h then
                    HELPER.press = { c = c, x = MX, y = MY }
                end
            end
        elseif btn == "move" and HELPER.press and math.abs(MX - HELPER.press.x) + math.abs(MY - HELPER.press.y) > 8 then
            local c = HELPER.press.c
            c._drag = { isActive = function() return true end }
        elseif btn == "up" and HELPER.press then
            HELPER.press.c._drag = { isActive = function() return false end }
            HELPER.press = nil
        end
        HELPER.line = s
        HELPER.busyUntil = CLOCK + 550
    end
end

local function run(file, tag, maxSec)
    world()
    list(CWIN, PINV); list(WWIN, FLOOR)
    local fn, err = loadfile(QA .. file)
    check(tag .. ": the script parses", fn ~= nil, err)
    if not fn then return end
    local okL, errL = pcall(fn)
    check(tag .. ": the script loads on the prelude's state (windows open, pinned whole)", okL, errL)
    local ticks = 0
    while #Events.OnTick.fns > 0 and ticks < maxSec * 60 do
        CLOCK = CLOCK + 16
        ticks = ticks + 1
        helperTick()
        list(CWIN, PINV); list(WWIN, FLOOR)   -- (the lists follow the containers each frame)
        for _, f in ipairs(Events.OnTick.fns) do
            local okT, errT = pcall(f)
            if not okT then LOG[#LOG + 1] = "LUA ERROR " .. tostring(errT); Events.OnTick.Remove(f) end
        end
    end
    local doneLine, errs, luaErr = false, {}, nil
    for _, l in ipairs(LOG) do
        if l:find("DONE", 1, true) then doneLine = true end
        if l:find(" ERR ", 1, true) and not l:find("mouse helper never answered", 1, true) then errs[#errs + 1] = l end
        if l:find("LUA ERROR", 1, true) then luaErr = l end
    end
    _G.print = function(s) io.write(tostring(s), "\n") end
    -- (lua51 b9a_qa_dryrun_sim.lua b9a5: that script's whole log)
    if arg and arg[1] == tag then for _, l in ipairs(LOG) do io.write("   | ", l, "\n") end end
    check(tag .. ": runs to DONE", doneLine, "after " .. math.floor(ticks / 60) .. " s")
    check(tag .. ": no Lua error in its steps", #errs == 0 and luaErr == nil, errs[1] or luaErr)
    check(tag .. ": never writes a mouse request over one still unread", OVERWRITES == 0, OVERWRITES .. " of " .. REQS)
    check(tag .. ": every mouse request names a point", #BADREQ == 0, BADREQ[1])
    print(string.format("   %-20s %3d mouse requests, %3d s on the clock", file, REQS, math.floor(ticks / 60)))
end

local REAL_PRINT = print
for n = 1, 9 do
    run("zedqa_b9a_" .. n .. ".lua", "b9a" .. n, 400)
    print = REAL_PRINT
end
run("zedqa_dual_pin.lua", "dpn", 600)
print = REAL_PRINT
print("b9a_qa_dryrun_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
