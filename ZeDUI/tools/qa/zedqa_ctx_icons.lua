-- ZeDUI/tools/qa/zedqa_ctx_icons.lua  (Oct 28 2026)
-- In game on the ZeD-QA save, after the prelude: the right-click menu's pixel icons (ZeD.ContextPxIcons), the
-- ones that replaced its licensed pictures, at the UI scale in use.
--   1. checks: every picture name ZeD.ContextIcons gives has a pixel icon with its drawings; the registry hands
--      the id back for English names and for names read through the game's words; the box rule picks the
--      drawing for the menu's icon box;
--   2. a test panel: every pixel icon of the menu in a real strip cell (at rest and pointed at), its grid
--      logged so the capture can be checked pixel for pixel (scratch: ctx_px_check.py);
--   3. the real menus: the strip and the list on an apple, a pistol, a bandage, a hammer and the floor; each
--      menu's options counted (a pixel icon, a licensed picture left, no icon).
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA cx"; captures Screenshots/zqa_cx_*.png.
local function say(s) print("ZEDQA cx " .. tostring(s)) end
local T, M = ZeD.T, ZeD.Molecules
local R = ZeD.ContextMenu.Registry
local p = getPlayer()
local fails = 0
local function check(ok, what) if ok then say("ok " .. what) else fails = fails + 1; say("ERR " .. what) end end

-- 1. the table, the drawings, the lookup
local PX = ZeD.ContextPxIcons or {}
local names, left, nodraw = 0, {}, {}
local seen = {}
for _, pic in pairs(ZeD.ContextIcons) do
    if type(pic) == "string" and not seen[pic] then
        seen[pic] = true; names = names + 1
        local id = PX[pic]
        if not id then left[#left + 1] = pic
        else
            for _, s in ipairs({ 16, 24, 32, 48 }) do
                local t, got = ZeD.PxIcon.tex(id, s)
                if not t or got ~= s then nodraw[#nodraw + 1] = id .. "@" .. s end
            end
        end
    end
end
check(#left == 0, names .. " pictures in the menu's table, each with a pixel icon" .. (#left > 0 and (": left " .. table.concat(left, ", ")) or ""))
check(#nodraw == 0, "each pixel icon has its four drawings" .. (#nodraw > 0 and (": " .. table.concat(nodraw, ", ")) or ""))
local box = T.ctx.iconPx
local want = (box >= 48 and 48) or (box >= 32 and 32) or (box >= 24 and 24) or (box >= 16 and 16) or box
local _, got = ZeD.PxIcon.tex("walk", box)
say("scale " .. tostring(T.scale) .. ": the cell is " .. T.ctx.cellW .. " px, its icon box " .. box .. ", the drawing " .. tostring(got))
check(got == want, "the box rule picks " .. want .. " for the menu's icon box")
local function idFor(name) local _, id = R.resolveIconForName(name); return id end
check(idFor("Walk to") == "walk", "Walk to: walk (" .. tostring(idFor("Walk to")) .. ")")
for _, k in ipairs({ "ContextMenu_Eat", "ContextMenu_Drink", "ContextMenu_Equip_Primary", "ContextMenu_Barricade" }) do
    local w = getTextOrNull and getTextOrNull(k)
    if w then check(idFor(w) ~= nil, k .. " (" .. w .. "): " .. tostring(idFor(w))) end
end
check(idFor("Read Doctor Magazine") ~= nil, "a label with a changing part finds its verb's icon: " .. tostring(idFor("Read Doctor Magazine")))

-- 2. the test panel: every id the menu uses, in strip cells
local ids = {}
do
    local u = {}
    for _, id in pairs(PX) do if not u[id] then u[id] = true; ids[#ids + 1] = id end end
    table.sort(ids)
end
local P = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
P:initialise(); P.backgroundColor = { r = 0.08, g = 0.08, b = 0.08, a = 1 }
local cw, gap = T.ctx.cellW, T.px(4)
local x0, y0 = T.px(20), T.px(20)
local per = math.floor((P.width - 2 * x0 + gap) / (cw + gap))
local drawErr
function P:render()
    local ok, e = pcall(function()
        for row = 0, 1 do
            for i, id in ipairs(ids) do
                local n = i - 1
                local x = x0 + (n % per) * (cw + gap)
                local y = y0 + (row * (math.floor((#ids - 1) / per) + 1) + math.floor(n / per)) * (cw + gap)
                local tex = ZeD.PxIcon.tex(id, 16)
                M.drawContextCell(self, x, y, { iconTexture = tex, pxIcon = id, iconTintable = true, name = id },
                    { isActive = row == 1 }, T)
            end
        end
    end)
    if not ok and not drawErr then drawErr = tostring(e); say("ERR the test panel: " .. drawErr) end
end
say("grid x0=" .. x0 .. " y0=" .. y0 .. " cell=" .. cw .. " gap=" .. gap .. " per=" .. per .. " n=" .. #ids .. " box=" .. box)
say("ids " .. table.concat(ids, ","))

-- 3. the real menus
local opt = ZeD.Settings.contextStyleOption
local was = opt:getValue()
local made = {}
local function zm() local v = getPlayerContextMenu(0); return v and v._zedMenu end
local function count(defs, c)
    for _, d in ipairs(defs or {}) do
        if d.pxIcon then c.px = c.px + 1
        elseif d.iconTexture and d.iconTintable then c.lic = c.lic + 1; c.licNames[#c.licNames + 1] = tostring(d.name)
        elseif d.iconTexture then c.sprite = c.sprite + 1
        else c.none = c.none + 1; c.noneNames[#c.noneNames + 1] = tostring(d.name) end
        count(d.children, c)
    end
end
local function report(what)
    local m = zm()
    local defs = m and m._ctx and m._ctx.actions
    if not defs and m and m._levels and m._levels[1] then
        defs = {}
        for _, r in ipairs(m._levels[1].rows or {}) do if r.def then defs[#defs + 1] = r.def end end
    end
    local c = { px = 0, lic = 0, sprite = 0, none = 0, licNames = {}, noneNames = {} }
    count(defs, c)
    say(what .. ": " .. tostring(m and m.Type) .. " | pixel " .. c.px .. ", licensed " .. c.lic .. ", item pictures " .. c.sprite
        .. ", none " .. c.none .. (c.none > 0 and (" (" .. table.concat(c.noneNames, ", ") .. ")") or ""))
    check(m ~= nil and c.px > 0, what .. " opened with pixel icons")
    check(c.lic == 0, what .. ": no licensed picture left" .. (c.lic > 0 and (" (" .. table.concat(c.licNames, ", ") .. ")") or ""))
end
local function closeMenu() local m = zm(); if m then pcall(function() m:close() end) end end

local ITEMS = { "Base.Apple", "Base.Pistol", "Base.Bandage", "Base.Hammer" }
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_cx_" .. name .. ".png") end); say("shot zqa_cx_" .. name) end

-- (the drawings load in the background: 291 icons asked for at once take a few hundred frames; a menu asks
-- for a dozen. The panel waits until every drawing it shows is ready, at most 900 frames.)
local function notReady()
    local c = 0
    for _, id in ipairs(ids) do
        local t = ZeD.PxIcon.tex(id, box)
        local ok, r = pcall(function() return t:isReady() end)
        if ok and r == false then c = c + 1 end
    end
    return c
end
local gridAt
at(5, function() P:addToUIManager(); say("drawings not ready yet: " .. notReady()) end)
at(6, function() gridAt = "wait" end)
at(50, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    for _, t in ipairs(ITEMS) do made[t] = p:getInventory():AddItem(t) end
end)
local n = 60
local mx, my = math.floor(getCore():getScreenWidth() * 0.4), math.floor(getCore():getScreenHeight() * 0.35)
for style = 1, 2 do
    local sname = style == 1 and "strip" or "list"
    at(n, function() opt:setValue(style) end); n = n + 5
    for _, t in ipairs(ITEMS) do
        local short = t:gsub("^Base%.", ""):lower()
        at(n, function() ISInventoryPaneContextMenu.createMenu(0, true, { made[t] }, mx, my) end)
        at(n + 30, function() report(sname .. " " .. short); shot(sname .. "_" .. short) end)
        at(n + 35, closeMenu)
        n = n + 45
    end
    at(n, function()
        local sq = p:getCurrentSquare()
        local objs = {}
        if sq then for i = 0, sq:getObjects():size() - 1 do objs[#objs + 1] = sq:getObjects():get(i) end end
        ISWorldObjectContextMenu.createMenu(0, objs, mx, my)
    end)
    at(n + 30, function() report(sname .. " floor"); shot(sname .. "_floor") end)
    at(n + 35, closeMenu)
    n = n + 45
end
at(n, function()
    opt:setValue(was)
    for _, t in ipairs(ITEMS) do if made[t] then p:getInventory():Remove(made[t]) end end
    say("DONE " .. fails .. " failed")
end)
local last = n
local k, i, g = 0, 1, 0
local function tick()
    -- the grid holds the steps (its own frame count) until its capture is taken
    if gridAt == "wait" then
        g = g + 1
        local left = notReady()
        if left == 0 or g > 900 then
            say("drawings not ready after " .. g .. " frames: " .. left)
            check(left == 0, "every drawing on the panel loaded")
            gridAt = g
        end
        return
    elseif type(gridAt) == "number" then
        g = g + 1
        if g == gridAt + 20 then shot("grid"); check(drawErr == nil, "the test panel drew")
        elseif g >= gridAt + 25 then P:removeFromUIManager(); gridAt = "done" end
        return
    end
    k = k + 1
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then fails = fails + 1; say("ERR step " .. steps[i].n .. " " .. tostring(e)) end; i = i + 1 end
    if k > last then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
