-- ZeDUI/tools/qa/gallery_journal_kills.lua  (Oct 22 2026)
-- Gallery shot: the Character window's Journal tab with the ZOMBIES KILLED
-- section expanded and filled. In game on the ZeD-QA save (run with
-- zedqa_prelude.lua before it, at fullscreen 3840x2160).
--   1. snapshot: the zombie kill count, player:getModData().ZeD_Kills, the
--      disclosure (win._killsExpanded), the Journal sub-tab, the open tab, the
--      scroll place, the theme (base / accent / size), the windows open or shut
--   2. seed believable kills: ZeD_Kills in KillTracker's structure
--      { weapon = { <category> = n }, fire, vehicle, explosion }, and
--      player:setZombieKills(n) = the weapon total (the Journal adds fire,
--      vehicle and explosion to the game's own count: 200 + 12 = 212)
--   3. high contrast + PZ Teal (ZeD.applyTheme, in memory only), World window
--      shut for the shot, Character window on the Journal tab (Journal
--      sub-tab), disclosure expanded
--   4. measure: Character window box, kills section box (screen pixels; the
--      section = the disclosure row down to just above the groove under it)
--   5. journal_kills_1.png at the top, journal_kills_2.png scrolled to the bottom
--      (when the tab scrolls at all)
--   6. everything put back
-- Output "ZEDQA jk ..." per step, "MEASURE ..." lines, "ZEDQA jk DONE" last.
local TAG = "jk"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local pn = p:getPlayerNum()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
if not (ZeD and CWm and WWm and ZeD.JournalTab) then say("ERR ZeD is not loaded"); say("DONE"); return end
local function CW() return CWm.getWindow() end

-- ---------------------------------------------------------------------------
-- What there was, to put back
-- ---------------------------------------------------------------------------
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end
local md = p:getModData()
local killsWas = deepCopy(md.ZeD_Kills)          -- nil if the character had none
local countWas = p:getZombieKills()
local baseWas, accentWas, sizeWas = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
local wasChar, wasWorld = CWm.isOpen(), WWm.isOpen()
local w0 = CW()
local expWas = w0 and w0._killsExpanded
local subWas = w0 and w0._journalSubTab
local tabWas = w0 and w0._activeTab
local scrollWas = w0 and w0._journalScroll and w0._journalScroll.scrollPos
local speedWas = getGameSpeed()
local meas = {}
local gt = getGameTime()
local timeWas = gt:getTimeOfDay()
local climWas, hidden = {}, {}
local geomWas = nil

-- ---------------------------------------------------------------------------
-- Helpers (all above their users)
-- ---------------------------------------------------------------------------
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function theme(base, accent, size)
    ZeD.applyTheme(base, accent, size)
    local c, w = CW(), WWm.getWindow()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end
local function shot(name)
    local f = name .. ".png"
    local ok, e = pcall(function() getCore():TakeFullScreenshot(f) end)
    say("shot " .. f .. (ok and " ok" or (" ERR " .. tostring(e))))
end
-- the debug console hidden, daylight with a clear sky (what there was is put back)
local function cleanLook()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); hidden[#hidden + 1] = e end
        end
    end)
    pcall(function()
        gt:setTimeOfDay(10.0)
        local cm = getClimateManager()
        for i = 0, cm:getFloatMax() - 1 do
            local v = cm:getClimateFloat(i)
            local l = tostring(v:getName()):lower()
            if l:find("fog", 1, true) or l:find("precip", 1, true) or l:find("cloud", 1, true) then
                climWas[#climWas + 1] = { v = v, en = v:isEnableAdmin(), val = v:getAdminValue() }
                v:setEnableAdmin(true); v:setAdminValue(0)
            end
        end
    end)
end
local function seed()
    local kills = {
        weapon = {
            Blunt = 38, SmallBlunt = 9, LongBlade = 21, SmallBlade = 14, Axe = 46,
            Spear = 11, Firearm = 52, Unarmed = 6, Other = 3,
        },
        fire = 4, vehicle = 6, explosion = 2,
    }
    local sum = 0
    for _, n in pairs(kills.weapon) do sum = sum + n end
    md.ZeD_Kills = kills
    p:setZombieKills(sum)
    say(string.format("seeded: game count %d + fire %d + vehicle %d + explosion %d = %d",
        sum, kills.fire, kills.vehicle, kills.explosion, sum + kills.fire + kills.vehicle + kills.explosion))
end
local function restoreAll()
    for _, c in ipairs(climWas) do pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end) end
    for _, e in ipairs(hidden) do pcall(function() e:setVisible(true) end) end
    pcall(function() gt:setTimeOfDay(timeWas) end)
    pcall(function()
        local w = CW()
        if w and geomWas then w:setX(geomWas.x); w:setY(geomWas.y); w:setHeight(geomWas.h) end
    end)
    pcall(function() md.ZeD_Kills = killsWas end)
    pcall(function() p:setZombieKills(countWas) end)
    pcall(function()
        local w = CW()
        if w then
            w._killsExpanded = expWas
            w._journalSubTab = subWas or 1
            w._journalCache = nil
            if w._journalScroll then w._journalScroll:setScrollPos(scrollWas or 0) end
            if tabWas and w._tabStripPanel then goTab(w, w._tabStripPanel, tabWas) end
        end
    end)
    pcall(function() theme(baseWas, accentWas, sizeWas) end)
    pcall(function() if ZeD.Settings and ZeD.Settings.reapplyFromOptions then ZeD.Settings.reapplyFromOptions() end end)
    pcall(function() if wasWorld and not WWm.isOpen() then WWm.open(pn) end end)
    pcall(function() if not wasChar and CWm.isOpen() then CWm.toggle(pn) end end)
    pcall(function() if getGameSpeed() <= 0 and speedWas > 0 then setGameSpeed(speedWas) end end)
end

-- the groove under the kills section (the first one below the disclosure row)
local grooveHit = nil
local origGroove = nil
local function hookGroove(on)
    if on then
        if origGroove then return end
        origGroove = ZeD.Atoms.drawGroove
        local orig = origGroove
        ZeD.Atoms.drawGroove = function(panel, x, y, width, ...)
            local w = CW()
            if w and w._activeTab == "journal" and w._killsRowY and y >= w._killsRowY
               and (not grooveHit or y < grooveHit.y) then
                grooveHit = { y = y, x = x, w = width,
                              ax = panel:getAbsoluteX(), ay = panel:getAbsoluteY() }
            end
            return orig(panel, x, y, width, ...)
        end
    elseif origGroove then
        ZeD.Atoms.drawGroove = origGroove
        origGroove = nil
    end
end

local function measure()
    local w = CW()
    if not w then say("ERR no window to measure"); return end
    local T = ZeD.T
    local box = { x = w:getAbsoluteX(), y = w:getAbsoluteY(), w = w:getWidth(), h = w:getHeight() }
    meas.window = box
    say(string.format("MEASURE character window x=%.0f y=%.0f w=%.0f h=%.0f (screen %.0fx%.0f, ZeD scale %s)",
        box.x, box.y, box.w, box.h, getCore():getScreenWidth(), getCore():getScreenHeight(),
        tostring(ZeD.Scale and ZeD.Scale.current and ZeD.Scale.current())))
    local kz = w._journalKillsZone
    if kz and grooveHit then
        local ax, ay = grooveHit.ax, grooveHit.ay
        local top = ay + kz.y
        local bottom = ay + grooveHit.y - T.sp.xs
        meas.kills = { x = ax + kz.x, y = top, w = kz.w, h = bottom - top }
        say(string.format("MEASURE kills section x=%.0f y=%.0f w=%.0f h=%.0f (disclosure row h=%.0f)",
            meas.kills.x, meas.kills.y, meas.kills.w, meas.kills.h, kz.h))
    else
        say("ERR kills box not measured (zone " .. tostring(kz) .. ", groove " .. tostring(grooveHit) .. ")")
    end
    local sc = w._journalScroll
    say("journal scroll visible=" .. tostring(sc and sc.visible) .. " pos=" .. tostring(sc and sc.scrollPos))
end

-- ---------------------------------------------------------------------------
-- The sequencer (OnRenderTick: runs while the pause menu is up too)
-- ---------------------------------------------------------------------------
local queue, qi, tick, lastDone = {}, 1, 0, 0
local startMs = getTimestampMs()
local aborted = false
local function step(after, fn) queue[#queue + 1] = { after = after, fn = fn } end
local function onFrame()
    tick = tick + 1
    local s = queue[qi]
    if not s then Events.OnRenderTick.Remove(onFrame); return end
    if not aborted and getTimestampMs() - startMs > 240000 then
        aborted = true
        say("ERR ran too long: jumping to putting things back")
        qi = #queue - 1; lastDone = tick
        return
    end
    if tick - lastDone < s.after then return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    lastDone = tick; qi = qi + 1
end

step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not CWm.isOpen() then CWm.toggle(pn) end
    if WWm.isOpen() then WWm.close() end
    cleanLook()
    seed()
    theme(((GAL_LOOK and GAL_LOOK[1]) or "hicon"), ((GAL_LOOK and GAL_LOOK[2]) or "teal"), sizeWas)   -- GAL_LOOK: gallery_t14_look.lua
    say(string.format("theme %s %s size %s", tostring(ZeD.currentBase), tostring(ZeD.currentAccent), tostring(ZeD.currentSize)))
end)
step(30, function()
    local w = CW()
    if not w then say("ERR no Character window"); return end
    if not goTab(w, w._tabStripPanel, "journal") then say("ERR no journal tab in the strip") end
end)
step(2, function()
    local w = CW()
    if not w then return end
    geomWas = { x = w:getX(), y = w:getY(), h = w:getHeight() }
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local nh = math.min(math.floor(w:getHeight() * 1.5), sh - 200)
    w:setHeight(nh)
    w:setX(math.floor((sw - w:getWidth()) / 2))
    w:setY(math.floor((sh - nh) / 3))
    w._anchorRightEdge = w:getX() + w:getWidth()
    say(string.format("window placed x=%.0f y=%.0f h=%.0f", w:getX(), w:getY(), w:getHeight()))
end)
step(20, function()
    local w = CW()
    if not w then return end
    w._journalSubTab = 1
    w._killsExpanded = true
    w._journalCache = nil
    pcall(function() w._journalScroll:setScrollPos(0) end)
    say("journal tab " .. tostring(w._activeTab) .. " sub " .. tostring(w._journalSubTab) .. " expanded " .. tostring(w._killsExpanded))
    hookGroove(true)
end)
step(6, function() measure(); hookGroove(false) end)
step(90, function() shot("journal_kills_1") end)
step(4, function()
    local w = CW()
    local sc = w and w._journalScroll
    if sc and sc.visible then
        sc:setScrollPos(1)
        say("scrolled to the bottom")
    else
        say("note: the Journal tab does not scroll here; no bottom shot")
        meas.noScroll = true
    end
end)
step(30, function() if not meas.noScroll then shot("journal_kills_2") end end)
step(4, function() hookGroove(false); restoreAll() end)
step(30, function()
    local w = CW()
    say(string.format("restored: count %s (was %s), expanded %s (was %s), theme %s %s (was %s %s)",
        tostring(p:getZombieKills()), tostring(countWas),
        tostring(w and w._killsExpanded), tostring(expWas), tostring(ZeD.currentBase), tostring(ZeD.currentAccent),
        tostring(baseWas), tostring(accentWas)))
    say("DONE")
end)
Events.OnRenderTick.Add(onFrame)
say("start (" .. #queue .. " steps)")
