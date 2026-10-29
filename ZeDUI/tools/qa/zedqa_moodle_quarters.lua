-- ZeDUI/tools/qa/zedqa_moodle_quarters.lua  (Oct 29 2026)
-- Moodle Quarters [B42] (mod id moodle_quarters) with ZeD's three moodle places
-- (ModSupport/moodle_quarters.lua). The mod draws the whole moodle stack on a panel
-- of its own (MoodleQuartersUI) in place of the game's column; ZeD moves that panel
-- to where it put the moodles. With four moodles on (hungry, thirsty, tired,
-- stressed), for right, left and bottom:
--   * ZeD knows the mod draws (its stand-in) and the mod's panel has a size;
--   * the panel lies over ZeD's moodles (its rect against ZeD.Moodles.rect) and
--     holds one slot per moodle;
--   * once the slide in has settled, every plate the mod drew lies inside it;
--   * ZeD lists the moodles in the mod's order, and ZeD's note for the moodle
--     under the pointer (moodle 2) is for the one the mod drew there;
--   * bottom: ZeD draws no copy of its own row (the mod's row only);
-- with a picture of each (zqa_mq_<place>.png). The stats, god mode, the place and
-- the windows are put back. grep "ZEDQA mq".
local p = getPlayer()
local pn = p:getPlayerNum()
local MO = ZeD and ZeD.Moodles
local S = ZeD and ZeD.ModSupport and ZeD.ModSupport.moodle_quarters
local function say(s) print("ZEDQA mq " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mq_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() is true or maxMs have gone, then fn(ok)
local function waitFor(n, maxMs, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, maxMs = maxMs } end

if not (MO and MO.rect and MO.standIn and ZeD.Settings and ZeD.Settings.moodlePlaceOption) then
    say("ERR ZeD.Moodles (with rect / standIn) is not loaded"); say("DONE"); return
end
if not (S and type(MoodleQuarters) == "table" and MoodleQuartersUI) then
    say("ERR Moodle Quarters or ZeD's support for it is not loaded (is moodle_quarters in the save's mod list?)")
    say("DONE"); return
end
local opt = ZeD.Settings.moodlePlaceOption
local placeWas = opt:getValue()
local st = p:getStats()
local WANT = { HUNGER = 0.45, THIRST = 0.45, FATIGUE = 0.75, STRESS = 0.6 }
local kept = {}
local god = p:isGodMod()
local winsWere = ZeD_CharacterWindow.isOpen()
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()

local function setStats()
    for k, v in pairs(WANT) do
        local ok, err = pcall(function() st:set(CharacterStat[k], v) end)
        if not ok then say("ERR set " .. k .. ": " .. tostring(err)) end
    end
end

-- the moodle keys in the order the mod draws them now (its shown slots)
local function mqKeys()
    local panel = S.panel(pn)
    local out = {}
    if not panel then return out end
    for i, e in ipairs(MoodleQuarters.moodles) do
        local s = panel.slots and panel.slots[i]
        if s and s.shown then out[#out + 1] = e.id end
    end
    return out
end
local function zedKeys()
    local L = MO.getLayer(pn)
    local out = {}
    for _, m in ipairs(L and L._list or {}) do out[#out + 1] = m.key end
    return out
end
-- the mod's slide has stopped (every shown slot at its place; a wiggle may still run,
-- since a level that moves starts one, so the plate check allows its width sideways)
local function settled()
    local panel = S.panel(pn)
    if not panel then return false end
    for _, s in ipairs(panel.slots or {}) do
        if s.shown and s.pos ~= s.desired then return false end
    end
    return true
end
local WIGGLE = math.ceil(MoodleQuarters.wobbleWidth or 16)

step(10, function()
    for k in pairs(WANT) do
        local cs = CharacterStat[k]
        if cs then kept[k] = st:get(cs) end
    end
    setStats()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() Mouse.setXY(20, 20) end)
end)
step(90, function()
    say("90 frames on: moodles on " .. #MO.active(p) .. "; god " .. tostring(p:isGodMod()))
    -- god mode can hold the stats at zero; off for the run, put back at the end
    if #MO.active(p) < 4 then p:setGodMod(false); setStats() end
end)
step(90, function()
    setStats()
    say("180 frames on: moodles on " .. #MO.active(p) .. " (" .. table.concat(zedKeys(), ", ") .. ")")
    check(S.panel(pn) ~= nil, "the mod's panel is up and drawing for the player")
    check(MO.standIn(pn) ~= nil, "ZeD knows the mod draws the moodles (stand-in)")
end)

local rowCalls = 0
for _, place in ipairs({ { 1, "right" }, { 2, "left" }, { 3, "bottom" } }) do
    local name = place[2]
    step(10, function()
        opt:setValue(place[1])
        -- count ZeD's own row drawing (it still draws if it is called; the count is all that changes)
        rowCalls = 0
        local L = MO.getLayer(pn)
        if L then
            local orig = ZeD_MoodleLayer._drawRow
            L._drawRow = function(self) rowCalls = rowCalls + 1; return orig(self) end
        end
    end)
    waitFor(30, 8000, function() setStats(); return settled() end, function(ok)
        check(ok, name .. ": the mod's slide in has settled")
    end)
    step(5, function()
        local L = MO.getLayer(pn)
        local panel = S.panel(pn)
        local r = MO.rect(pn)
        local list = L and L._list or {}
        say(name .. ": " .. #list .. " moodles on (" .. table.concat(zedKeys(), ", ") .. "); the mod's order ("
            .. table.concat(mqKeys(), ", ") .. ")")
        check(MO.place() == name and r ~= nil and r.place == name, name .. ": the place is in effect (ZeD's rect)")
        check(#list >= 4, name .. ": at least four moodles are on")
        check(MO.standIn(pn) ~= nil, name .. ": ZeD knows the mod draws the moodles")
        if not (panel and r) then check(false, name .. ": the mod's panel and ZeD's rect are there"); return end
        local x, y, w, h = panel:getX(), panel:getY(), panel:getWidth(), panel:getHeight()
        say(string.format("%s: ZeD's moodles %d,%d %dx%d (size %d, %d on); the mod's panel %d,%d %dx%d, %d slots, visible %s",
            name, r.x, r.y, r.w, r.h, r.size, r.n, x, y, w, h, panel.usedSlots or -1, tostring(panel:isVisible())))
        check(w > 0 and h > 0, name .. ": the mod's panel has a size")
        check(x == r.x and y == r.y, name .. ": the mod's panel starts where ZeD put the moodles")
        if name == "bottom" then
            check(w == r.w and h == r.h, name .. ": the mod's panel is ZeD's row, exactly")
            check(math.abs(x + w / 2 - sw / 2) <= 2, "bottom: the row is centred")
            local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()
            if hud and hud._drawn then check(y + h <= hud:getY(), "bottom: the row sits above the belt") end
        else
            -- the mod's column counts a gap after the last moodle too (n x (size + 10))
            check(w == r.w and h >= r.h and h <= r.h + 10, name .. ": the mod's panel is ZeD's column")
            if name == "left" then check(x <= 20, "left: on the left edge (x " .. x .. ")")
            else check(x + w >= sw - 20, "right: on the right edge (x " .. x .. ")") end
        end
        check(x >= 0 and y >= 0 and x + r.w <= sw and y + r.h <= sh, name .. ": every moodle is on screen")
        check(panel.usedSlots == r.n, name .. ": one of the mod's slots per moodle ZeD placed")
        check(panel.size == r.size, name .. ": the mod's moodle size is ZeD's (" .. tostring(panel.size) .. ")")
        -- every plate the mod drew this frame lies inside its panel
        local e = panel._zedExtent
        local drawnLately = panel._zedDrawnAt and getTimestampMs() - panel._zedDrawnAt < 1000
        check(drawnLately and e and e.n >= 2 * r.n, name .. ": the mod drew a plate and an icon per moodle ("
            .. tostring(e and e.n) .. " drawn)")
        if e and e.n > 0 then
            say(string.format("%s: the mod's plates reach %d,%d to %d,%d inside its panel", name, e.x0, e.y0, e.x1, e.y1))
            check(e.x0 >= -WIGGLE and e.y0 >= 0 and e.x1 <= w + WIGGLE and e.y1 <= h,
                name .. ": every plate lies inside the panel (give or take the mod's wiggle, " .. WIGGLE .. " sideways)")
        end
        -- same moodles, same order: ZeD's note lands on the moodle the mod drew there
        check(table.concat(zedKeys(), ",") == table.concat(mqKeys(), ","), name .. ": ZeD lists the moodles in the mod's order")
        if name == "bottom" then
            check(rowCalls == 0, "bottom: ZeD draws no copy of its own (" .. rowCalls .. " frames drawn)")
        end
    end)
    step(5, function() shot(name) end)
    -- the pointer on moodle 2 (ZeD's note reads the layer's mouse only; a script cannot move a fullscreen pointer)
    step(2, function()
        local L = MO.getLayer(pn)
        local s = L._size or 32
        local lx, ly = s / 2, s + 10 + s / 2
        if L._mode == "bottom" then lx, ly = s + 10 + s / 2, s / 2 end
        L.getMouseX = function() return lx end
        L.getMouseY = function() return ly end
    end)
    step(10, function()
        local L = MO.getLayer(pn)
        local c = L._chip
        local want = mqKeys()[2]
        say(name .. " note: for " .. tostring(c and c.key) .. ", the mod's moodle 2 is " .. tostring(want))
        check(c ~= nil and c.idx == 2 and c.key == want, name .. ": the note is for the moodle the mod drew under the pointer")
        shot(name .. "_hover")
    end)
    step(2, function()
        local L = MO.getLayer(pn)
        L.getMouseX, L.getMouseY, L._drawRow = nil, nil, nil
    end)
end

step(10, function()
    opt:setValue(placeWas or 1)
    for k, v in pairs(kept) do pcall(function() st:set(CharacterStat[k], v) end) end
    p:setGodMod(god)
    local L = MO.getLayer(pn)
    if L then L.getMouseX, L.getMouseY, L._drawRow = nil, nil, nil end
    if winsWere and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    local res
    if s.cond then
        s.t0 = s.t0 or getTimestampMs()
        local okc, done = pcall(s.cond)
        res = okc and done and true or false
        if not res and getTimestampMs() - s.t0 < s.maxMs then wait = 1; return end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn, res)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
