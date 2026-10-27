-- ZeDUI/tools/qa/zedqa_health_padprobe.lua  (Oct 27 2026)
-- Where Down goes on the Character window's Health tab at Large text: the world
-- pad test found Down stopping on the figure's Left Foot instead of reaching the
-- exercise time buttons. Wounds as that test sets them; every Health stop listed
-- with its rect, then a Down walk from the first stop with each landing printed.
-- Puts the text size, the wounds and the tab back. grep "ZEDQA hp".
local p = getPlayer()
local Focus = ZeD.Input.Focus
local function say(s) print("ZEDQA hp " .. tostring(s)) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local origSize = ZeD.currentSize
local wounds = { "Hand_L", "ForeArm_R", "UpperLeg_L", "Foot_R", "Torso_Upper", "Head" }
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end

local function woundsOn(on)
    local bd = p:getBodyDamage()
    for _, n in ipairs(wounds) do
        local bp = bd:getBodyPart(BodyPartType.FromString(n))
        if bp then
            pcall(function() bp:setScratched(on, true) end)
            pcall(function() bp:setCut(on) end)
            if not on then pcall(function() bp:setScratchTime(0); bp:setCutTime(0); bp:setBleedingTime(0); bp:setBleeding(false) end) end
        end
    end
end
local function stripTab(w, id)
    local strip = w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function stops(w)
    local out = {}
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == "charTabContent" and z.focusable then
            for _, e in ipairs(z.elements or {}) do out[#out + 1] = e end
        end
    end
    return out
end
local function rect(e)
    return string.format("%s x%d y%d w%d h%d", tostring(e.id), math.floor(e.x or -1), math.floor(e.y or -1),
        math.floor(e.w or -1), math.floor(e.h or -1))
end

step(10, function()
    woundsOn(true)
    ZeD.applyTheme(nil, nil, "large")
end)
step(40, function() stripTab(cw(), "health") end)
step(90, function()
    local w = cw()
    local dp = w._drawerPanel
    say("drawer " .. (dp and (dp:getWidth() .. "x" .. dp:getHeight()) or "none") .. " size " .. tostring(ZeD.currentSize))
    for i, e in ipairs(stops(w)) do say(string.format("stop %02d %s", i, rect(e))) end
    Focus.claimFocus(w)
    local first = stops(w)[1]
    Focus.focusWhere(w, "charTabContent", function(e) return e == first end)
end)
local n, last = 0, nil
local function walk()
    local w = cw()
    local e = Focus.getFocusedElement(w)
    local z = Focus.getFocusedZone(w)
    say(string.format("down %02d -> %s %s", n, tostring(z and z.zone), e and rect(e) or "nil"))
    if n >= 40 or not z or z.zone ~= "charTabContent" or (e and e.id == last and n > 0) then
        -- one more: what Down offers from here (cone-nav picks nothing = stays)
        return
    end
    last = e and e.id
    n = n + 1
    Focus.dispatchJoypadDir(w, "down")
    insertNext(4, walk)
end
step(5, walk)
step(10, function()
    -- the same walk at the player's own size, for comparison
    ZeD.applyTheme(nil, nil, origSize)
end)
step(60, function()
    local w = cw()
    say("at " .. tostring(ZeD.currentSize) .. ":")
    for i, e in ipairs(stops(w)) do say(string.format("stop %02d %s", i, rect(e))) end
end)
step(10, function()
    woundsOn(false)
    stripTab(cw(), "loot")
    say("DONE")
end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
