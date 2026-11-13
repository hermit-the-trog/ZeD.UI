-- ZeDUI/tools/qa/zedqa_hint_strip.lua  (Nov 4 2026, QA; Build's hint strip, ZeD_HintStrip.lua)
-- In game on the QA save, keyboard and mouse (the pad path needs a real controller: not scripted).
-- For each thing near the QA home (a door, a window, a hoppable fence, a car, a light switch, a stove): stand beside
-- it facing each way until the game's own rules (ISButtonPrompt:getBestInteractButtonAction) offer an action, then
-- read ZeD.HintStrip.prompts(0) and take a picture. The Interact key should show only where the key really does it
-- (doors, windows, fences, cars); a light switch or a stove should show "Right Click | More" only.
-- Then First hours (3 uses spend a hint) and Off. The character goes back home after. grep "ZEDQA hst".
local function say(s) print("ZEDQA hst " .. tostring(s)) end
local H = ZeD.HintStrip
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_hst_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local opt = ZeD.Settings.hintStripOption
local keep = { opt = opt:getValue(), x = p:getX(), y = p:getY(), z = p:getZ() }
local uses = nil
pcall(function() local r = getFileReader("ZeD_hints.txt", false); if r then local t = {}; local l = r:readLine(); while l do t[#t + 1] = l; l = r:readLine() end; r:close(); uses = table.concat(t, "\n") .. "\n" end end)
local DIRS = { IsoDirections.N, IsoDirections.NE, IsoDirections.E, IsoDirections.SE, IsoDirections.S, IsoDirections.SW, IsoDirections.W, IsoDirections.NW }
local function moveTo(x, y, z)
    p:setX(x + 0.5); p:setY(y + 0.5); p:setZ(z or 0)
    p:setLastX(x + 0.5); p:setLastY(y + 0.5); p:setLastZ(z or 0)
end
-- the nearest of each kind within r squares
local finds = {}
local function scan(r)
    local cell = getCell()
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for dy = -r, r do for dx = -r, r do
        local sq = cell:getGridSquare(px + dx, py + dy, 0)
        if sq then
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                local kind
                if instanceof(o, "IsoDoor") then kind = "door"
                elseif instanceof(o, "IsoWindow") then kind = "window"
                elseif instanceof(o, "IsoLightSwitch") then kind = "light"
                elseif instanceof(o, "IsoStove") then kind = "stove"
                else local ok, h = pcall(function() return o:isHoppable() end); if ok and h then kind = "fence" end end
                if kind then
                    local d = dx * dx + dy * dy
                    if not finds[kind] or d < finds[kind].d then finds[kind] = { d = d, x = px + dx, y = py + dy, o = o } end
                end
            end
        end
    end end
    local it = cell:getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local d = (v:getX() - px) ^ 2 + (v:getY() - py) ^ 2
        if d < r * r and (not finds.car or d < finds.car.d) then finds.car = { d = d, x = math.floor(v:getX()), y = math.floor(v:getY()), v = v } end
    end
end
-- the squares beside (or on) the thing, free to stand on
local OFFS = { { 0, 0 }, { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 }, { 1, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 } }
local function spots(f)
    local out = {}
    for _, off in ipairs(OFFS) do
        local sq = getCell():getGridSquare(f.x + off[1], f.y + off[2], 0)
        if sq and sq:isFree(false) then out[#out + 1] = { f.x + off[1], f.y + off[2] } end
    end
    return out
end
-- standing where the character is now (moved some ticks before), the first facing the game offers an action on
local function tryDirs()
    local bp = ISButtonPrompt:new(0)
    for _, d in ipairs(DIRS) do
        p:setDir(d)
        bp:clearButtonBindings()
        pcall(function() bp:getBestInteractButtonAction(d) end)
        if bp.aPrompt and bp.aPrompt ~= "" then return bp.aPrompt end
    end
    return nil
end
local results = {}
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(20, function()
    opt:setValue(1)
    pcall(function() local w = getFileWriter("ZeD_hints.txt", true, false); if w then w:write(""); w:close() end end)
    H.uses = nil
    scan(45)
    local got = {}
    for k, f in pairs(finds) do got[#got + 1] = string.format("%s at %d,%d", k, f.x, f.y) end
    say("found: " .. table.concat(got, "; "))
end)
for _, kind in ipairs({ "door", "window", "fence", "car", "light", "stove" }) do
    step(10, function()
        local f = finds[kind]
        results[kind] = { skip = not f }
        if not f then say("SKIP " .. kind .. ": none within 45 squares"); return end
        results[kind].spots = spots(f)
    end)
    for si = 1, #OFFS do
        step(5, function()
            local r = results[kind]
            if r.skip or r.game or not r.spots[si] then return end
            moveTo(r.spots[si][1], r.spots[si][2], 0)
        end)
        step(15, function()
            local r = results[kind]
            if r.skip or r.game or not r.spots[si] then return end
            r.game = tryDirs()
            if r.game then r.where = r.spots[si] end
        end)
    end
    step(40, function()
        local r = results[kind]
        if r.skip then return end
        if r.where then finds._last = r end
        local ps = H.prompts(0) or {}
        local parts = {}
        local keyShown = false
        for _, h in ipairs(ps) do
            parts[#parts + 1] = tostring(h.glyph) .. " " .. tostring(h.label)
            if h.key and h.glyph ~= getText("IGUI_mouse_btn_1") then keyShown = true end
        end
        say(string.format("%s: the game offers %s; the strip shows: %s", kind, tostring(r.game), #parts > 0 and table.concat(parts, " | ") or "(nothing)"))
        if not r.game then say("SKIP " .. kind .. ": no facing gave the game an action"); return end
        local wantKey = (kind == "door" or kind == "window" or kind == "fence" or kind == "car")
        check(#ps > 0, kind .. ": the strip shows something")
        check(keyShown == wantKey, kind .. ": the Interact key shown " .. tostring(keyShown) .. " (expected " .. tostring(wantKey) .. ")")
        shot("1_" .. kind)
    end)
end
-- First hours: three uses of the door's hint spend it; Off shows nothing
step(10, function()
    local r
    for _, k in ipairs({ "door", "window", "fence", "car" }) do if not r and results[k] and results[k].where then r = results[k] end end
    if not r then say("SKIP First hours: nothing with a key hint"); return end
    moveTo(r.where[1], r.where[2], 0)
    keep.fh = r
end)
step(15, function()
    if keep.fh then tryDirs() end
    opt:setValue(2)
end)
step(30, function()
    local st = H._eval and H._eval[0]
    local before = H.prompts(0) or {}
    if st then for _ = 1, 3 do H.used(st.aFn, st.a) end end
    keep.n1 = #before
end)
step(30, function()
    local after = H.prompts(0) or {}
    local keyLeft = false
    for _, h in ipairs(after) do if h.key and h.glyph ~= getText("IGUI_mouse_btn_1") then keyLeft = true end end
    check(keep.n1 and keep.n1 > 0 and not keyLeft, "First hours: after 3 uses the key hint is gone (" .. tostring(keep.n1) .. " before, " .. #after .. " after)")
    shot("2_first_hours_spent")
    opt:setValue(3)
end)
step(30, function()
    check(H.prompts(0) == nil, "Off: nothing shows")
    shot("3_off")
end)
step(20, function()
    opt:setValue(keep.opt or 1)
    pcall(function() local w = getFileWriter("ZeD_hints.txt", true, false); if w then w:write(uses or ""); w:close() end end)
    H.uses = nil
    if ZEDQA_HOME then pcall(ZEDQA_HOME) else moveTo(math.floor(keep.x), math.floor(keep.y), keep.z) end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then fail = fail + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
