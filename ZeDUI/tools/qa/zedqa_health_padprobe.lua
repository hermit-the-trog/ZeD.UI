-- ZeDUI/tools/qa/zedqa_health_padprobe.lua  (Oct 27 2026)
-- Where Down goes on the Character window's Health tab at Large text: the world
-- pad test found Down stopping on the figure's Left Foot instead of reaching the
-- exercise time buttons (Oct 30 2026: those are in the footer band now, with the
-- exercise pop-up and Start: ids health:exercise, health:time:dec / inc, health:start). Wounds as that test sets them; every Health stop listed
-- with its rect, then a Down walk from the first stop with each landing printed.
-- (Oct 30 2026, punch list 21 a-f; run it at 1280x800 too: zedqa_run.ps1 -Width 1280 -Height 800)
-- Checks (PASS / FAIL): the Down walk reaches the band (a bandStop: the exercise box, - / +,
-- Start) at Large text and at the player's size; every body stop it lands on is whole in the
-- body's view, between the pinned header and the band (none under the band); no stop the
-- ring holds lies under the band.
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
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
-- the body's view (HealthTab stamps it each frame): a body stop must lie in it
local function inView(w, e)
    local v = w._healthView
    if not v or e.bandStop or e.isDisclosure then return true end
    return e.y >= v.y - 1 and e.y + e.h <= v.y + v.h + 1
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
local function census()
    local w = cw()
    local dp = w._drawerPanel
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    say("screen " .. sw .. "x" .. sh .. " drawer " .. (dp and (dp:getWidth() .. "x" .. dp:getHeight()) or "none") .. " size " .. tostring(ZeD.currentSize))
    local v, under = w._healthView, 0
    for i, e in ipairs(stops(w)) do
        say(string.format("stop %02d %s", i, rect(e)))
        if v and not e.bandStop and not e.isDisclosure and e.y >= v.y + v.h then under = under + 1 end
    end
    check(under == 0, ZeD.currentSize .. ": no body stop under the band (" .. under .. ")")
    Focus.claimFocus(w)
    local first = stops(w)[1]
    Focus.focusWhere(w, "charTabContent", function(e) return e == first end)
end
-- the Down walk: each landing printed and checked in view; ends where Down stays put
local n, last, band, outside = 0, nil, false, 0
local function walk()
    local w = cw()
    local e = Focus.getFocusedElement(w)
    local z = Focus.getFocusedZone(w)
    say(string.format("down %02d -> %s %s", n, tostring(z and z.zone), e and rect(e) or "nil"))
    if e and e.bandStop then band = true end
    if e and n > 0 and not inView(w, e) then outside = outside + 1; say("  (out of the body's view)") end
    if band or n >= 40 or not z or z.zone ~= "charTabContent" or (e and e.id == last and n > 0) then
        check(band, ZeD.currentSize .. ": Down from the figure reaches the band (ended on " .. tostring(e and e.id) .. ")")
        check(outside == 0, ZeD.currentSize .. ": every body stop the walk landed on was whole in view (" .. outside .. " not)")
        return
    end
    last = e and e.id
    n = n + 1
    Focus.dispatchJoypadDir(w, "down")
    insertNext(6, walk)   -- (the body scrolls to the stop, then the ring takes the new places)
end
step(90, census)
step(5, walk)
step(10, function()
    -- the same walk at the player's own size
    ZeD.applyTheme(nil, nil, origSize)
    n, last, band, outside = 0, nil, false, 0
end)
step(60, census)
step(5, walk)
step(10, function()
    woundsOn(false)
    stripTab(cw(), "loot")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
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
