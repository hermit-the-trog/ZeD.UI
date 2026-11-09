-- ZeDUI/tools/qa/zedqa_b10_tooltips.lua  (Nov 8 2026, beta 10; punch list 118 and 119): the balloon in game, on the
-- ZeD-QA save. Run it at 4K 1.75x (fullscreen4k) and at 1280x800 (windowed -Width 1280 -Height 800), in EN, then DE and
-- RU (the language is the game's setting: set it, restart, run again). The screen size is read, not set.
--   REQ     a drawers piece beside the character with an apple in it, every saw taken, a hammer given, the movables
--           cheat off; World menu > Disassemble > the piece, in the strip and in the list, in Dark, Light and High
--           contrast, Small and Large text. Checks: the row is disabled; the Registry read the requirement list (rows,
--           a met row, a missing row, the condition row, the Name row left out); the balloon is up, inside the screen,
--           clear of the strip, its tail's tip on the selected cell (strip) or at the row's height (list); one picture
--           each (zqa_b10tt_req_<look>_<theme>_<size>.png).
--   ARROWS  the strip made to scroll (maxVisible 4), in every theme and all nine accents: the end boxes are the accent,
--           the arrow the accent's text color (zqa_b10tt_arrows_<theme>_<accent>.png); the ratio is logged.
--   TOKENS  positiveText and dangerText against surface 2 in every theme, logged with their ratio (4.5 : 1 or more).
--   ONE     with the strip's balloon up, the slot is the menu's (prio 2); Escape (ZeD.Balloon.dismiss) leaves a menu's
--           balloon alone.
-- Puts the theme, the look, the cheat, the saws, maxVisible back and removes the piece.
-- grep "ZEDQA b10tt"; shots zqa_b10tt_*.png. Look at the pictures: no word outside a box, the tail on its cell / row,
-- checks and crosses in green and red that read on the box, the strip never covered.
local TAG = "b10tt"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
local p = getPlayer()
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_" .. n .. ".png") end) end
local function zm() local v = getPlayerContextMenu(0); return v and v._zedMenu end
local B = ZeD.Balloon
local opt = ZeD.Settings and ZeD.Settings.contextStyleOption
if not (p and B and opt and ZeD.RichTip) then say("ERR the balloon, the menus or the Settings are not loaded"); say("DONE"); return end
local wasStyle = opt:getValue()
local wasBase, wasAccent, wasSize = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
local wasCheat = ISMoveableDefinitions and ISMoveableDefinitions.cheat
local wasPCheat = p:isMovablesCheat()
local wasMaxVis = ZeD.T.ctx and ZeD.T.ctx.maxVisible
local SW, SH = getCore():getScreenWidth(), getCore():getScreenHeight()
local mx, my = math.floor(SW / 2), math.floor(SH / 2)
say("screen " .. SW .. "x" .. SH .. " | ZeD scale " .. tostring(ZeD.T.scale) .. " | language " .. tostring(Translator and Translator.getLanguage and Translator.getLanguage()))
local obj, objName, sq
local taken, gaveHammer = {}, nil
local DIS = getText("ContextMenu_Disassemble")

local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end

-- a drawers piece that cannot be taken apart: scrapped with a saw (the character has none), with a container
local function tryPlace(name)
    local spr = getSprite(name)
    if not spr then return false end
    local o = IsoObject.new(getCell(), sq, spr)
    sq:AddTileObject(o)
    o:createContainersFromSpriteProperties()
    local mp = ISMoveableSpriteProps.fromObject(o)
    local good = mp and mp.isMoveable and mp.canScrap and not mp.isMultiSprite and o:getContainer() ~= nil
    if good then
        o:getContainer():AddItem("Base.Apple")
        local r = mp:canScrapObject(p)
        good = r.craftValid and not r.canScrap
    end
    if good then
        obj, objName = o, Translator.getMoveableDisplayName(mp.name)
        return true
    end
    pcall(function() sq:transmitRemoveItemFromSquare(o) end)
    pcall(function() sq:RemoveTileObject(o) end)
    return false
end
local function place()
    sq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), math.floor(p:getZ()))
    if not sq then return false end
    for _, sheet in ipairs({ "furniture_storage_02", "furniture_storage_01" }) do
        for n = 0, 63 do
            if tryPlace(sheet .. "_" .. n) then return true end
        end
    end
    return false
end

-- the strip: Disassemble, then the piece
local function stripTo()
    local m = zm()
    if not (m and m._ctx and m._ctx.items) then return nil end
    for n, d in ipairs(m._ctx.items) do if d.name == DIS then m._ctx.selected = n end end
    m:confirm()
    for n, d in ipairs(m._ctx.items) do if d.name == objName then m._ctx.selected = n; return d end end
    return nil
end
-- the list: Disassemble, its submenu, the piece (the pad's way: the balloon shows at once)
local function listTo()
    local m = zm()
    local lv = m and m._levels and m._levels[1]
    if not lv then return nil end
    m._nav = "pad"
    for n, r in ipairs(lv.rows) do if r.def and r.def.name == DIS then lv.sel = n end end
    m:onJoypadDirRight()
    local sub = m._levels[2]
    if not sub then return nil end
    for n, r in ipairs(sub.rows) do if r.def and r.def.name == objName then sub.sel = n; m._nav = "pad"; return r.def end end
    return nil
end

local function boxOnScreen()
    local s = B._slot
    local b = s and s.box
    if not b then return false, "no box" end
    local m = ZeD.T.px(4)
    return b.x >= m - 1 and b.y >= m - 1 and b.x + b.w <= SW - m + 1 and b.y + b.h <= SH - m + 1,
        string.format("%d,%d %dx%d", b.x, b.y, b.w, b.h)
end

local function reqLook(look, value, goTo, theme, size)
    local tag = look .. " " .. theme .. " " .. size
    step(10, function()
        ZeD.applyTheme(theme, wasAccent, size)
        opt:setValue(value)
        ISWorldObjectContextMenu.createMenu(0, { obj }, mx, my)
    end)
    step(20, function()
        local def = goTo()
        if not check(def ~= nil, tag .. ": Disassemble > " .. tostring(objName) .. " is in the menu") then return end
        check(def.disabled and def.disabled(nil), tag .. ": the row is disabled")
        local m = def.bodyRich
        if check(m ~= nil, tag .. ": the requirement list was read (rows and marks)") then
            local met, miss = 0, 0
            for _, r in ipairs(m.rows) do
                if r.st == "ok" then met = met + 1 elseif r.st == "bad" then miss = miss + 1 end
                check(string.lower(r.values[1].t) ~= string.lower(tostring(objName)) or #r.values > 1, tag .. ": no Name row (" .. r.label .. ")")
            end
            for _, k in ipairs(m.conds) do if k.st == "bad" then miss = miss + 1 end end
            check(met >= 1, tag .. ": a met row (" .. met .. ")")
            check(miss >= 2, tag .. ": the saws and the full container missing (" .. miss .. ")")
            check(#m.conds >= 1, tag .. ": the condition row (" .. #m.conds .. ")")
        end
    end)
    step(20, function()
        local s = B._slot
        check(s and s.key ~= nil and getTimestampMs() - s.t < 500, tag .. ": the balloon is up")
        check(s and s.prio == 2, tag .. ": it is the menu's balloon (one at a time, the menu first)")
        local okS, where = boxOnScreen()
        check(okS, tag .. ": the balloon is inside the screen (" .. tostring(where) .. ")")
        local pl = B.lastPlace
        local menu = zm()
        if look == "strip" and menu and menu._layoutCache and pl then
            local c = menu._layoutCache
            local ax, ay = menu:getAbsoluteX(), menu:getAbsoluteY()
            local cell = menu:_selectedCellRect(c)
            check(pl.tipX >= ax + cell.x and pl.tipX < ax + cell.x + cell.w, tag .. ": the tail's tip is on the selected cell")
            local b = s.box
            local top, bot = ay + c.stripY, ay + c.stripY + c.stripH
            check(b and (b.y + b.h <= top or b.y >= bot), tag .. ": the balloon does not cover the strip")
        elseif look == "list" and menu and menu._levels and pl then
            local sub = menu._levels[2]
            local r = sub and sub.sel and sub.rows[sub.sel]
            check(pl.side == "right" or pl.side == "left", tag .. ": beside the row (" .. tostring(pl.side) .. ")")
            if sub and r then check(pl.tipY >= sub.y + r.y and pl.tipY < sub.y + r.y + ZeD.T.px(28), tag .. ": the tail's tip at the row's height") end
        end
        -- Escape leaves a menu's balloon alone (it pops the menu instead)
        local k = s and s.key
        B.dismiss()
        check(B._slot.key == k, tag .. ": Escape does not hide a menu's balloon")
    end)
    step(30, function() shot("req_" .. look .. "_" .. theme .. "_" .. size) end)
    step(10, function() local m = zm(); if m then m:close() end end)
end

-- the strip made to scroll, every accent: its arrows
local function lum(c)
    local function ch(v) if v <= 0.03928 then return v / 12.92 end return ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b)
end
local function ratio(a, b) local x, y = lum(a), lum(b); if x < y then x, y = y, x end; return (x + 0.05) / (y + 0.05) end
local ACC = { "red", "orange", "yellow", "green", "blue", "teal", "purple", "pink", "mono" }
local function arrows(theme, accent)
    step(8, function()
        ZeD.applyTheme(theme, accent, "small")
        if ZeD.T.ctx then ZeD.T.ctx.maxVisible = 4 end
        opt:setValue(1)
        ISWorldObjectContextMenu.createMenu(0, { obj }, mx, my)
    end)
    step(20, function()
        local m = zm()
        check(m and m._ctx and m._ctx.truncating, theme .. " " .. accent .. ": the strip scrolls (its end boxes show)")
        local T = ZeD.T
        local r = ratio(T.textOnAccent, T.accent)
        check(r >= 3, string.format("%s %s: the arrow on the accent %.2f : 1", theme, accent, r))
        shot("arrows_" .. theme .. "_" .. accent)
    end)
    step(6, function() local m = zm(); if m then m:close() end end)
end

step(30, function()
    if ISMoveableDefinitions then ISMoveableDefinitions.cheat = false end
    p:setMovablesCheat(false)
    local inv = p:getInventory()
    local items = inv:getItems()
    for n = items:size() - 1, 0, -1 do
        local it = items:get(n)
        if it and tostring(it:getType()):find("Saw", 1, true) then taken[#taken + 1] = it:getFullType(); inv:Remove(it) end
    end
    gaveHammer = inv:AddItem("Base.Hammer")
    check(place(), "a drawers piece with an apple in it beside the character: " .. tostring(objName))
    for _, theme in ipairs({ "dark", "light", "hicon" }) do
        ZeD.applyTheme(theme, wasAccent, wasSize)
        local T, s2 = ZeD.T, ZeD.BaseThemes[theme].surf2
        local rp, rd = ratio(T.positiveText, s2), ratio(T.dangerText, s2)
        check(rp >= 4.5 and rd >= 4.5, string.format("%s: positiveText %.2f : 1, dangerText %.2f : 1 on surface 2", theme, rp, rd))
    end
end)
for _, theme in ipairs({ "dark", "light", "hicon" }) do
    for _, size in ipairs({ "small", "large" }) do
        reqLook("strip", 1, stripTo, theme, size)
        reqLook("list", 2, listTo, theme, size)
    end
end
for _, theme in ipairs({ "dark", "light", "hicon" }) do
    for _, accent in ipairs(ACC) do arrows(theme, accent) end
end
step(10, function()
    if ZeD.T.ctx then ZeD.T.ctx.maxVisible = wasMaxVis end
    ZeD.applyTheme(wasBase, wasAccent, wasSize)
    opt:setValue(wasStyle)
    if ISMoveableDefinitions then ISMoveableDefinitions.cheat = wasCheat end
    p:setMovablesCheat(wasPCheat == true)
    local inv = p:getInventory()
    if gaveHammer then inv:Remove(gaveHammer) end
    for _, t in ipairs(taken) do inv:AddItem(t) end
    if obj and sq then
        pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
        pcall(function() sq:RemoveTileObject(obj) end)
    end
    say("RESULT " .. passes .. " pass, " .. misses .. " fail")
    say("DONE")
end)

local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    qc = qc + 1
    if qc < s.wait then return end
    qc, qi = 0, qi + 1
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(onTick)
say("start")
