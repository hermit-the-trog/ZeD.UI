-- ZeDUI/tools/qa/zedqa_padmap.lua  (Oct 23 2026)
-- The pad map (director: "capture each window's full panel first, then build
-- nav from what's on screen"). In game on the ZeD-QA save, at the run's size
-- and once at Large text: every tab of both windows (a long tab also at its
-- bottom), an item card in each window, an object card (the padlock card on a
-- crate built for the run) and the belt. For each capture: a full screenshot
-- Screenshots/zqa_pm_<name>.png and Lua/zqa_pm_<name>.json with every stop
-- the focus manager registers (window-local and screen rects, flags) and
-- where the real D-pad move goes from it in each direction (Focus.previewMove:
-- the dispatch code run dry). ZeDUI/tools/qa/padmap.py draws the overlays and
-- the mismatch tables (ZeDUI/qa/padmap/). Everything made is taken away.
-- grep "ZEDQA pm".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local function say(s) print("ZEDQA pm " .. tostring(s)) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local DIRS = { "up", "down", "left", "right" }
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end
local function stripTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function tabsOf(strip)
    local out = {}
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = z.id:sub(5) end
    end
    return out
end
local function jstr(s)
    s = tostring(s)
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("[%c]", " ")
    return '"' .. s .. '"'
end
local function jnum(v) if type(v) ~= "number" or v ~= v then return "null" end return string.format("%.1f", v) end
local function jbool(v) return v and "true" or "false" end
local function wrect(w) return string.format('{"x":%s,"y":%s,"w":%s,"h":%s}', jnum(w:getX()), jnum(w:getY()), jnum(w:getWidth()), jnum(w:getHeight())) end

-- stray prompts and dialogs (an earlier test's rename prompt) closed before a
-- capture; returns how many were open, and whether one still is
local MODAL = { ZeD_Prompt = true, ISTextBox = true, ISModalDialog = true, ISModalRichText = true, ZeD_Keyboard = true }
local function modals(close)
    local n = 0
    local ui = UIManager.getUI()
    for i = ui:size() - 1, 0, -1 do
        local ok, t = pcall(function() return ui:get(i):getTable() end)
        if ok and t and MODAL[t.Type] and t:isVisible() then
            n = n + 1
            if close then
                if t.close then pcall(t.close, t) elseif t.destroy then pcall(t.destroy, t) else pcall(t.removeFromUIManager, t) end
            end
        end
    end
    return n
end
local count = 0
-- one capture: the screenshot now, the stops of window w and their moves
local function capture(name, w, other, note)
    count = count + 1
    local open = modals(false)
    pcall(function() getCore():TakeFullScreenshot("zqa_pm_" .. name .. ".png") end)
    local flat = Focus.flatElements(w)
    -- where focus is now, put back afterwards
    local savedIdx, savedEl, savedLast = w._focusIdx, {}, w._navLast
    for zi, z in ipairs(w._focusRing or {}) do savedEl[zi] = z.focusedElementIdx end
    local lines = {}
    for i, f in ipairs(flat) do
        local e = f.el or {}
        w._navLast = nil
        w._focusIdx = f.zi
        w._focusRing[f.zi].focusedElementIdx = f.ei
        local mv = {}
        for _, d in ipairs(DIRS) do
            local r = Focus.previewMove(w, d)
            mv[#mv + 1] = string.format('%s:{"zone":%s,"id":%s,"pass":%s,"custom":%s}', jstr(d),
                r.zone and jstr(r.zone) or "null", r.id and jstr(r.id) or "null", r.pass and jstr(r.pass) or "null", jbool(r.custom))
        end
        local active = (e.tabId ~= nil and e.tabId == w._activeTab)
            or (e.containerIdx ~= nil and e.containerIdx == ((w == cw()) and (w._viewedContainer or w._activeContainer) or w._activeContainer))
        lines[#lines + 1] = string.format('{"n":%d,"zone":%s,"id":%s,"x":%s,"y":%s,"w":%s,"h":%s,"item":%s,"primary":%s,"strip":%s,"disclosure":%s,"active":%s,"own":%s,"moves":{%s}}',
            i, jstr(f.zone), jstr(f.id), jnum(f.x), jnum(f.y), jnum(f.w), jnum(f.h),
            e.item and jstr(e.item:getName()) or "null", jbool(e.isPrimary), jbool(e.isStrip), jbool(e.isDisclosure), jbool(active),
            jbool(e.onDpadDir ~= nil), table.concat(mv, ","))
    end
    w._focusIdx, w._navLast = savedIdx, savedLast
    for zi, z in ipairs(w._focusRing or {}) do z.focusedElementIdx = savedEl[zi] or z.focusedElementIdx end
    local ok, err = pcall(function()
        local f = getFileWriter("zqa_pm_" .. name .. ".json", true, false)
        f:write(string.format('{"name":%s,"window":%s,"tab":%s,"size":%s,"note":%s,"modalsOpen":%d,"screen":{"w":%d,"h":%d},"rect":%s,"other":%s,"drawerH":%s,"els":[\n%s\n]}\n',
            jstr(name), jstr((w == cw()) and "Character" or "World"), jstr(w._activeTab), jstr(ZeD.currentSize), jstr(note or ""), open,
            getCore():getScreenWidth(), getCore():getScreenHeight(), wrect(w), other and wrect(other) or "null",
            jnum(w._drawerPanel and w._drawerPanel:getHeight()), table.concat(lines, ",\n")))
        f:close()
    end)
    say(name .. ": " .. #flat .. " stops" .. (ok and "" or (" (json failed: " .. tostring(err) .. ")")))
end

-- the crate and its things (for the World window's list, the cards, the object card)
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end
local crate, crateInv, padlock
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
end
-- each window as tall as the screen allows (director: a whole tab in one
-- shot): top near the screen's top, bottom above the belt, through the same
-- calls as a drag of the resize grip (height, then the engine's onResize,
-- which clamps to minimumHeight); put back at the end
local saved = {}
local function tall(w)
    if not w then return end
    saved[#saved + 1] = { w = w, x = w:getX(), y = w:getY(), wd = w:getWidth(), h = w:getHeight() }
    local m = ZeD.T.px(8)
    local hud = ZeD.Belt and ZeD.Belt._hud
    local bottom = getCore():getScreenHeight() - m
    if hud and hud._drawn and hud:isVisible() then bottom = math.min(bottom, hud:getAbsoluteY() - m) end
    -- (-debug: the engine's Output Log sits along the bottom left; stop above it)
    if isDebugEnabled and isDebugEnabled() then bottom = math.min(bottom, getCore():getScreenHeight() - 300) end
    local h = math.max(w.minimumHeight or 0, bottom - m)
    w:setY(m)
    w:setHeight(h)
    if w.onResize then pcall(w.onResize, w) end
end
local function untall()
    for i = #saved, 1, -1 do
        local s = saved[i]
        s.w:setHeight(s.h); s.w:setY(s.y)
        if s.w.onResize then pcall(s.w.onResize, s.w) end
    end
    saved = {}
end
local paged = {}
local origSize = ZeD.currentSize
local sizes, si = { origSize, "large" }, 1
local list, li = {}, 0

local function tabCaptures()
    modals(true)
    li = li + 1
    local it = list[li]
    if not it then
        if si < #sizes then
            si = si + 1
            ZeD.applyTheme(nil, nil, sizes[si])
            li = 0
            insertNext(60, tabCaptures)
        end
        return
    end
    local w = it.w
    local strip = (w == cw()) and w._tabStripPanel or w._actionTabStrip
    stripTab(w, strip, it.id)
    insertNext(90, function()   -- (the drawer's open animation done)
        Focus.claimFocus(w)
        local base = string.format("%s_%s_%s", (si == 1) and "run" or "large", (w == cw()) and "char" or "world", it.id)
        capture(base .. "_top", w, (w == cw()) and ww() or cw(), "top of the tab")
        -- a long tab: its bottom too (the wheel, all the way)
        local dp = w._drawerPanel
        local low = 0
        for _, f in ipairs(Focus.flatElements(w)) do
            if f.zone:match("TabContent$") then low = math.max(low, f.y + f.h - (dp and dp:getY() or 0)) end
        end
        if dp and dp:isVisible() and low > dp:getHeight() + 1 then
            paged[#paged + 1] = base
            for _ = 1, 80 do pcall(dp.onMouseWheel, dp, 1) end
            insertNext(25, function()
                capture(base .. "_bottom", w, (w == cw()) and ww() or cw(), "the tab scrolled to its bottom")
                for _ = 1, 80 do pcall(dp.onMouseWheel, dp, -1) end
                insertNext(5, tabCaptures)
            end)
        else
            insertNext(5, tabCaptures)
        end
    end)
end

-- the scene: no zombie anywhere near (the QA save's cell has strays), the
-- character safe and whole (a wound changes the Health tab), on open ground
-- away from walls (a 5 x 5 clear square around a spot within 12 tiles), with
-- a crate beside them and a few things on the ground
local ground = {}
local function clearZombies()
    local list = getCell():getZombieList()
    local n = 0
    for i = list:size() - 1, 0, -1 do
        local z = list:get(i)
        if z then n = n + 1; pcall(function() z:removeFromWorld() end); pcall(function() z:removeFromSquare() end) end
    end
    return n
end
local function openSpot()
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    local function clear(cx, cy)
        local c = getCell():getGridSquare(cx, cy, 0)
        if not c then return false end
        for dy = -2, 2 do for dx = -2, 2 do
            local sq = getCell():getGridSquare(cx + dx, cy + dy, 0)
            if not sq or not sq:isFree(false) or not c:canReachTo(sq) then return false end
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if o:getContainer() or instanceof(o, "IsoThumpable") or instanceof(o, "IsoDoor") or instanceof(o, "IsoWindow") then return false end
            end
            if sq:getWorldObjects():size() > 0 then return false end
        end end
        return true
    end
    for r = 0, 12 do
        for dy = -r, r do for dx = -r, r do
            if math.max(math.abs(dx), math.abs(dy)) == r and clear(px + dx, py + dy) then return px + dx, py + dy end
        end end
    end
    return nil
end
local function stage()
    local nz = clearZombies()
    p:setGodMod(true); p:setInvisible(true)
    pcall(function() p:getBodyDamage():RestoreToFullHealth() end)
    local x, y = openSpot()
    if x then p:teleportTo(x + 0.5, y + 0.5, 0) end
    say(string.format("scene: %d zombies removed, health %d, save %s, open ground %s", nz,
        math.floor(p:getBodyDamage():getOverallBodyHealth()), tostring(getWorld():getWorld()), x and (x .. "," .. y) or "not found (stayed)"))
end
step(30, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    modals(true)
    stage()
end)
step(90, function()   -- (the World window's list looks for containers every 30 frames)
    local sq0 = p:getCurrentSquare()
    for _, t in ipairs({ "Base.Plank", "Base.WaterBottle", "Base.Saw" }) do
        local ok, it = pcall(function() return sq0:AddWorldInventoryItem(t, 0.3 + #ground * 0.15, 0.4, 0) end)
        if ok and it then ground[#ground + 1] = it end
    end
    local sq = buildCrate()
    local objs = sq and sq:getObjects()
    for i = 0, (objs and objs:size() or 0) - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoThumpable") and o:getContainer() then crate = o end
    end
    crateInv = crate and crate:getContainer()
    if crateInv then for _, t in ipairs({ "Base.Nails", "Base.Bandage", "Base.Hammer", "Base.Apple" }) do crateInv:AddItem(t) end end
    say("crate " .. tostring(crateInv ~= nil))
    tall(cw()); tall(ww())
    say(string.format("windows tall: Character %d, World %d px high (screen %d)", cw():getHeight(), ww():getHeight(), getCore():getScreenHeight()))
end)
step(60, function()
    -- the World window on the crate (its list has rows)
    local w = ww()
    local on = false
    for _, c in ipairs(Focus.flatElements(w)) do
        if c.zone == "worldContainerStrip" and c.el and c.el.inventory == crateInv then c.el.onActivate(w, c.el); on = true end
    end
    say("the crate on show in the World window: " .. tostring(on))
    for _, id in ipairs(tabsOf(cw()._tabStripPanel)) do list[#list + 1] = { w = cw(), id = id } end
    for _, id in ipairs(tabsOf(ww()._actionTabStrip)) do list[#list + 1] = { w = ww(), id = id } end
    say(#list .. " tabs, at " .. tostring(origSize) .. " and large")
end)
-- the cards, the object card and the belt (at the run's size)
step(30, function()
    modals(true)
    stripTab(ww(), ww()._actionTabStrip, "loot")
    local w = ww()
    Focus.claimFocus(w)
    for _, c in ipairs(Focus.flatElements(w)) do
        if c.zone == "worldMainInv" and c.el and c.el.item and c.el.item:getFullType() == "Base.Nails" then
            Focus.focusWhere(w, "worldMainInv", function(e) return e == c.el end)
            c.el.onActivate(w, c.el)
        end
    end
end)
step(30, function() capture("run_world_card", ww(), cw(), "an item card (the nails in the crate)") end)
step(10, function()
    local w = ww(); local cnt = w._mainContent
    if cnt then cnt._selectedItems = {}; cnt._lastClickedItem = nil; w._updateDrawer() end
    local c = cw()
    stripTab(c, c._tabStripPanel, "loot")
    Focus.claimFocus(c)
    for _, f in ipairs(Focus.flatElements(c)) do
        if f.zone == "charMainInv" and f.el and f.el.item then
            Focus.focusWhere(c, "charMainInv", function(e) return e == f.el end)
            f.el.onActivate(c, f.el)
            break
        end
    end
end)
step(30, function() capture("run_char_card", cw(), ww(), "an item card (the first row of the bag)") end)
step(10, function()
    local c = cw(); local cnt = c._mainContent
    if cnt then cnt._selectedItems = {}; cnt._lastClickedItem = nil; c._updateDrawer(cnt) end
    padlock = p:getInventory():AddItem("Base.CombinationPadlock")
    Focus.claimFocus(ww())
    if crate then ZeD.ObjectCardLock.openFor(p, crate, false) end
end)
step(40, function() capture("run_world_objcard", ww(), cw(), "an object card (the crate's padlock card)") end)
step(10, function()
    if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
    if padlock then p:getInventory():Remove(padlock); padlock = nil end
    -- the belt: its boxes and where each D-pad press takes it
    local B = ZeD.Belt
    local hud = B and B._hud
    if not (hud and hud._drawn) then say("belt: not drawn"); return end
    Focus.releaseFocus()
    B.focus(pn)
end)
step(20, function()
    local B = ZeD.Belt
    local hud = B and B._hud
    if not (hud and hud._gp) then say("belt: did not take the pad"); return end
    pcall(function() getCore():TakeFullScreenshot("zqa_pm_run_belt.png") end)
    local ax, ay = hud:getAbsoluteX(), hud:getAbsoluteY()
    local lines = {}
    local MAP = { up = "onJoypadDirUp", down = "onJoypadDirDown", left = "onJoypadDirLeft", right = "onJoypadDirRight" }
    for i, b in ipairs(hud._boxes) do
        local mv = {}
        for _, d in ipairs(DIRS) do
            hud._gp = { idx = i, inList = false, row = 1, list = B.otherWeapons(p) }
            hud[MAP[d]](hud)
            local g = hud._gp
            local to = (g == nil) and "leave" or (g.inList and "list" or tostring(g.idx))
            mv[#mv + 1] = jstr(d) .. ":" .. jstr(to)
        end
        lines[#lines + 1] = string.format('{"n":%d,"kind":%s,"x":%s,"y":%s,"w":%s,"h":%s,"moves":{%s}}', i, jstr(b.kind),
            jnum(ax + b.x), jnum(ay + b.y), jnum(b.w), jnum(b.h), table.concat(mv, ","))
    end
    if hud._gp then hud:_leavePad() end
    pcall(function()
        local f = getFileWriter("zqa_pm_run_belt.json", true, false)
        f:write('{"name":"run_belt","window":"Belt","boxes":[\n' .. table.concat(lines, ",\n") .. '\n]}\n')
        f:close()
    end)
    say("run_belt: " .. #hud._boxes .. " boxes")
    Focus.claimFocus(cw())
end)
step(10, tabCaptures)
step(10, function()
    ZeD.applyTheme(nil, nil, origSize)
    stripTab(cw(), cw()._tabStripPanel, "loot"); stripTab(ww(), ww()._actionTabStrip, "loot")
    if crate and crate:getSquare() then
        crate:getContainer():removeAllItems()
        crate:getSquare():transmitRemoveItemFromSquare(crate)
    end
    for _, it in ipairs(ground) do
        local wio = it.getWorldItem and it:getWorldItem()
        if wio and wio:getSquare() then pcall(function() wio:getSquare():transmitRemoveItemFromSquare(wio) end) end
        local c = it:getContainer()
        if c then pcall(function() c:Remove(it) end) end
    end
    p:setInvisible(false)
end)
step(20, function()
    untall()
    say("still taller than the screen (captured in pages): " .. (#paged > 0 and table.concat(paged, ", ") or "none"))
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say(count .. " captures; size back to " .. tostring(ZeD.currentSize))
    say("DONE")
end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
say("start")
