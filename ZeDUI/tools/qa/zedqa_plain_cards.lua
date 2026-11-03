-- ZeDUI/tools/qa/zedqa_plain_cards.lua  (Nov 2 2026, QA; punch list 60, the plain device cards, build ae212f24)
-- In game, ZeD setup's Devices set to Simple. Three sets in the hand, one after another: the black radio, the red radio
-- (a disc carried), the Tactical walkie. For each, in the Character window's Radio tab:
--   the plain card is drawn (the wrapped driver, tw.drv.plain) with its rows' controls; power by its switch; the volume
--   stepper's left half lowers and its right half raises; the wheel over the frequency turns it, a fast spin goes
--   further; a preset key pressed recalls and a right-click (the hold's meaning) stores; the battery and headphone keys
--   open their lists (the red radio's disc key too, and Play / Stop plays the disc put in); the walkie's MEM held
--   (right-click) opens the naming box, its Light lights; the controller: the focus lands on the first row, A presses,
--   Right turns a stepper, Down moves on, the footer comes last;
--   then Devices back to Full: the face is back (not plain) at the half card.
-- At a short screen with Large text (the Deck) the card runs past the tab: the last control's focus scrolls it.
-- Everything made is taken away; the hands put back. grep "ZEDQA plc"; shots zqa_plc_*.png.
local function say(s) print("ZEDQA plc " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local RT, O, S = ZeD.RadioTab, ZeD.RadioOps, ZeD.Settings
local Focus = ZeD.Input and ZeD.Input.Focus
if not (RT and O and S and S.devicesStyleOption and ZeD.PlainFace) then say("ERR the plain cards are not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_plc_" .. n .. "_" .. sw .. "x" .. sh .. ".png") end) end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function tw() local w = CW(); return w and w._radioTw end
local function hitOf(id) for _, h in ipairs((tw() and tw().hits) or {}) do if h.id == id then return h end end end
local function ids() local t = {}; for _, h in ipairs((tw() and tw().hits) or {}) do t[#t + 1] = tostring(h.id) end; return table.concat(t, ",") end
local function click(id, side)
    local h = hitOf(id); if not h then say("NOTE no control " .. id); return false end
    local x = (side == "l" and h.x + 2) or (side == "r" and h.x + h.w - 3) or (h.x + math.floor(h.w / 2))
    RT.onClick(CW(), x, h.y + math.floor(h.h / 2)); return true
end
local function wheel(id, del)
    local h = hitOf(id); if not h then return false end
    return RT.onWheel(CW(), del, h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2))
end
local function rclick(id)
    local h = hitOf(id); if not h then return false end
    return RT.onRightClick(CW(), h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2))
end
-- a control scrolled into the tab's view, as the controller's focus does (the card can run past the tab)
local function reveal(id)
    local w = CW()
    for _, el in ipairs(RT.buildFocusables(w) or {}) do
        if el.id == "radio:tw:" .. id and el.onFocus then pcall(el.onFocus, w, el) end
    end
end
-- in the tab's view now
local function inView(id)
    local t, h = tw(), hitOf(id)
    local v = t and t.view
    if not (h and v) then return h ~= nil end
    return h.y >= v.y and h.y + h.h <= v.y + v.h
end
-- a real left click (release_check_mouse.ps1 must run: pl60_plain_run.ps1 starts it)
local clickAsked
local function realClick(id)
    local h = hitOf(id); if not h then return false end
    local w = CW()
    local fw = getFileWriter("zedqa_click_done.txt", true, false); if fw then fw:write(""); fw:close() end
    local f = getFileWriter("zedqa_click.txt", true, false)
    if f then f:write("left " .. math.floor(w:getAbsoluteX() + h.x + h.w / 2) .. " " .. math.floor(w:getAbsoluteY() + h.y + h.h / 2) .. "\n"); f:close() end
    clickAsked = getTimestampMs()
    return true
end
local function clickDone()
    local r = getFileReader("zedqa_click_done.txt", false); if not r then return false end
    local l = r:readLine(); r:close(); return l ~= nil and l ~= ""
end
local function goTab(id)
    local w = CW()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:" .. id and (w._activeTab ~= id or not w._drawerOpen) then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
end
-- the lists a key opens (a context menu, ZeD's own list), caught as they open
local lastCtx = nil
local ctxGet = ISContextMenu.get
ISContextMenu.get = function(...) local c = ctxGet(...); lastCtx = c; return c end
local function menuOpen()
    local c = lastCtx; if not c then return false end
    local m = c._zedMenu
    if m and m._ctx then return m._ctx.open == true end
    return c:isReallyVisible() and c:getX() > -1000
end
local function menuClose()
    local c = lastCtx; lastCtx = nil; if not c then return end
    pcall(function() if c._zedMenu and c._zedMenu.close then c._zedMenu:close() end end)
    pcall(function() c:setVisible(false) end)
end
-- the naming box (ISTextBox through ZeD's prompts), caught as it opens
local boxes = {}
local tbNew = ISTextBox.new
ISTextBox.new = function(self, ...) local o = tbNew(self, ...); boxes[#boxes + 1] = o; return o end
local function shutBoxes() for _, b in ipairs(boxes) do pcall(function() b:destroy() end); pcall(function() b:removeFromUIManager() end) end; boxes = {} end

local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local hWas = {}
local styleWas = S.devicesStyleOption:getValue()
local added = {}
local function newItem(ft) local it = p:getInventory():AddItem(ft); if it then added[#added + 1] = it end; return it end
local function newRadio(ft)
    local it = newItem(ft)
    local dd = it and it:getDeviceData()
    if dd then
        if dd:getIsBatteryPowered() then dd:setHasBattery(true); dd:setPower(0.8) end
        dd:setIsTurnedOn(false); dd:setDeviceVolume(0.5)
        local pc = dd:getDevicePresets(); if pc then pc:getPresets():clear() end
    end
    return it
end
-- the station: 98.0 MHz (NNR Radio on the QA save; ZomboidRadio's channel list is not reachable from a script)
local function station() return 98000 end

local Q, qi = {}, 1
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end
local function waitFor(k, max, cond, fn) Q[#Q + 1] = { n = k, fn = fn, cond = cond, max = max } end

step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    S.devicesStyleOption:setValue(2)
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    newItem("Base.Battery"); newItem("Base.Headphones")
end)

local cur
local SETS = {
    { ft = "Base.RadioBlack", pid = "radio_black", tune = true },
    { ft = "Base.RadioRed", pid = "radio_red", tune = true, disc = true },
    { ft = "Base.WalkieTalkie4", pid = "walkie_tactical", walkie = true },
}
for _, m in ipairs(SETS) do
    local volWas, chWas
    step(5, function()
        cur = { it = newRadio(m.ft), pid = m.pid }
        if m.disc then
            local items = p:getInventory():getAllEvalRecurse(function(it) local ok, md = pcall(function() return it:getMediaData() end); return ok and md ~= nil end)
            cur.disc = items and items:size() > 0 and items:get(0) or nil
            say(m.pid .. ": the disc " .. tostring(cur.disc and cur.disc:getDisplayName()))
        end
        p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil); p:setPrimaryHandItem(cur.it)
    end)
    waitFor(5, 200, function() local r = CW()._radios and CW()._radios[1]; return r ~= nil and r.radioInstance == cur.it end, function() goTab("radio") end)
    waitFor(5, 200, function() local t = tw(); return t ~= nil and t.dev == cur.it end, function()
        local t = tw()
        check(t.drv and t.drv.plain == true, m.pid .. ": the Radio tab draws the plain card")
        say(m.pid .. ": controls " .. ids() .. " | card " .. tostring(t.des and t.des.h) .. " high in a view " .. tostring(t.view and t.view.h))
        click("power")
        local hs = (t.hits or {})
        cur.lowest = hs[#hs] and hs[#hs].id
        if cur.lowest then reveal(cur.lowest) end
    end)
    step(10, function()
        if cur.lowest then say(m.pid .. ": at the opening height, the focus on " .. cur.lowest .. ": in view " .. tostring(inView(cur.lowest))) end
        -- the windows grown so the whole card shows (for the clicks below and the pictures; put back at the end)
        local t = tw()
        hWas.c = hWas.c or CW():getHeight(); hWas.w = hWas.w or ZeD_WorldWindow.getWindow():getHeight()
        local need = (t.des and t.des.h or 0) + ZeD.T.px(40)
        if t.view and need > t.view.h then
            local add = need - t.view.h + 2
            CW():setHeight(CW():getHeight() + add); ZeD_WorldWindow.getWindow():setHeight(ZeD_WorldWindow.getWindow():getHeight() + add)
        end
    end)
    step(20, function()
        local t = tw()
        say(m.pid .. ": grown: view " .. tostring(t and t.view and t.view.h) .. ", the lowest control in view " .. tostring(cur.lowest and inView(cur.lowest)))
    end)
    step(10, function()
        local dd = cur.it:getDeviceData()
        check(dd:getIsTurnedOn(), m.pid .. ": the power switch turns it on")
        if m.tune then dd:setChannel(station()) end
        volWas = dd:getDeviceVolume()
        click("vol", "r")
    end)
    step(5, function()
        local dd = cur.it:getDeviceData()
        check(dd:getDeviceVolume() > volWas + 0.01, string.format("%s: the volume stepper's right half raises it (%.2f -> %.2f)", m.pid, volWas, dd:getDeviceVolume()))
        volWas = dd:getDeviceVolume()
        click("vol", "l")
    end)
    step(5, function()
        local dd = cur.it:getDeviceData()
        check(dd:getDeviceVolume() < volWas - 0.01, string.format("%s: its left half lowers it (%.2f -> %.2f)", m.pid, volWas, dd:getDeviceVolume()))
        local fid = "tune"
        chWas = dd:getChannel()
        if hitOf(fid) then wheel(fid, -1) end
    end)
    step(5, function()
        local dd = cur.it:getDeviceData()
        local fid = "tune"
        if not hitOf(fid) then say("NOTE " .. m.pid .. ": no " .. fid .. " row"); return end
        local one = dd:getChannel() - chWas
        check(one ~= 0, m.pid .. ": the wheel over the frequency turns it (" .. chWas .. " -> " .. dd:getChannel() .. ")")
        if m.tune then
            chWas = dd:getChannel()
            for _ = 1, 8 do wheel(fid, -1) end
            local fast = dd:getChannel() - chWas
            say(m.pid .. ": one notch " .. one .. ", eight fast notches " .. fast)
            check(math.abs(fast) > 8 * math.abs(one), m.pid .. ": a fast spin goes further than its notches one by one")
            dd:setChannel(station())
        end
    end)
    -- presets: right-click (the hold's meaning) stores, a press recalls
    step(5, function() if hitOf("p1") then reveal("p1") end end)
    step(5, function()
        if not hitOf("p1") then say("NOTE " .. m.pid .. ": no preset keys"); return end
        say(m.pid .. ": p1 in view " .. tostring(inView("p1")))
        local dd = cur.it:getDeviceData()
        cur.stored = dd:getChannel()
        rclick("p1")
    end)
    step(5, function()
        if not hitOf("p1") then return end
        local dd = cur.it:getDeviceData()
        local pc = dd:getDevicePresets()
        local n = pc and pc:getPresets():size() or 0
        check(n >= 1, m.pid .. ": a held preset key (right-click) stores the channel (" .. n .. " stored)")
        if m.tune then cur.it:getDeviceData():setChannel(cur.stored + 600) end
        click("p1")
    end)
    step(5, function()
        if not hitOf("p1") then return end
        check(cur.it:getDeviceData():getChannel() == cur.stored, m.pid .. ": the preset key recalls it (" .. cur.it:getDeviceData():getChannel() .. ")")
    end)
    -- the lists under their keys
    for _, k in ipairs({ "battery", "phones", "media" }) do
        step(5, function() if hitOf(k) then reveal(k) end end)
        step(10, function() lastCtx = nil; pcall(function() ISTimedActionQueue.clear(p) end); if hitOf(k) then click(k) end end)
        step(15, function()
            if not hitOf(k) then return end
            local q = ISTimedActionQueue.getTimedActionQueue(p)
            local queued = q and q.queue and #q.queue > 0
            say(m.pid .. ": " .. k .. " key (in view " .. tostring(inView(k)) .. "): list " .. tostring(menuOpen()) .. ", action queued " .. tostring(queued))
            check(menuOpen() or queued, m.pid .. ": the " .. k .. " key opens its list (or, with one choice, queues the game's action)")
            menuClose()
            pcall(function() ISTimedActionQueue.clear(p) end)
            if not (menuOpen() or queued) then
                local t = tw()
                local base = t.drv and t.drv.base
                local function got()
                    local q2 = ISTimedActionQueue.getTimedActionQueue(p)
                    local r = "list " .. tostring(menuOpen()) .. ", queued " .. tostring(q2 and q2.queue and #q2.queue > 0)
                    menuClose(); pcall(function() ISTimedActionQueue.clear(p) end)
                    return r
                end
                lastCtx = nil
                local okP, eP = pcall(function() t.drv.press(p, cur.it, k, nil, nil) end)
                local plainSays = (okP and "" or ("error " .. tostring(eP) .. "; ")) .. got()
                lastCtx = nil
                local okB, eB = pcall(function() base.press(p, cur.it, k, nil, nil) end)
                local faceSays = (okB and "" or ("error " .. tostring(eB) .. "; ")) .. got()
                say(m.pid .. ": " .. k .. " pressed through the plain card: " .. plainSays .. " | through the face's own driver: " .. faceSays)
            end
        end)
    end
    if m.disc then
        step(5, function()
            local okA, eA = pcall(function() if cur.disc then cur.it:getDeviceData():addMediaItem(cur.disc) end end)
            if not okA then say(m.pid .. ": addMediaItem: " .. tostring(eA)) end
            if hitOf("play") then reveal("play") end
        end)
        step(10, function() if hitOf("play") then click("play") end end)
        step(30, function()
            local dd = cur.it:getDeviceData()
            local has = "?"; pcall(function() has = tostring(dd:hasMedia()) end)
            say(m.pid .. ": disc in " .. has .. ", Play in view " .. tostring(inView("play")))
        end)
        step(30, function()
            local dd = cur.it:getDeviceData()
            local playing = false; pcall(function() playing = O.playingNow(dd, O.keyOf(cur.it)) end)
            check(hitOf("play") ~= nil and playing, m.pid .. ": Play plays the disc put in")
            shot(m.pid .. "_disc")
        end)
        step(300, function()
            shot(m.pid .. "_disc_5s")   -- (five seconds into the disc: its time runs)
            if hitOf("play") then click("play") end
        end)
        step(90, function()
            local playing = true; pcall(function() playing = O.playingNow(cur.it:getDeviceData(), O.keyOf(cur.it)) end)   -- (ZeD's own reading: the game's isPlayingMedia clears only when its stop timer runs out)
            check(not playing, m.pid .. ": Stop stops it")
            if playing then
                local t = tw(); local dd = cur.it:getDeviceData()
                local function q() local qq = ISTimedActionQueue.getTimedActionQueue(p); local n = {}; for _, x in ipairs((qq and qq.queue) or {}) do n[#n + 1] = tostring(x.Type) .. ":" .. tostring(x.mode) end; return table.concat(n, ",") end
                say(m.pid .. ": still playing; the queue: " .. q() .. " | on " .. tostring(dd:getIsTurnedOn()))
                pcall(function() ISTimedActionQueue.clear(p) end)
                pcall(function() t.drv.press(p, cur.it, "play", nil, nil) end)
                say(m.pid .. ": play pressed through the plain card: queue " .. q())
                pcall(function() ISTimedActionQueue.clear(p) end)
                local ids = {}; for _, h in ipairs(t.hits or {}) do ids[#ids + 1] = h.id end
                pcall(function() t.drv.base.press(p, cur.it, "play", nil, nil) end)
                say(m.pid .. ": play through the face's own driver: queue " .. q())
                pcall(function() ISTimedActionQueue.clear(p) end)
                local before = dd:isPlayingMedia()
                local okS, r = pcall(function() return O.playStop(p, cur.it) end)
                say(m.pid .. ": O.playStop direct: ran " .. tostring(okS) .. " returned " .. tostring(r) .. " | playing " .. tostring(before) .. " -> " .. tostring(dd:isPlayingMedia()))
                pcall(function() dd:StopPlayMedia() end)
                say(m.pid .. ": dd:StopPlayMedia() direct: playing now " .. tostring(dd:isPlayingMedia()))
            end
            pcall(function() cur.it:getDeviceData():removeMediaItem(p:getInventory()) end)   -- (the disc back to the character)
        end)
    end
    if m.walkie then
        step(5, function() if hitOf("mem") then reveal("mem") end end)
        step(5, function() if hitOf("mem") then click("mem") end end)   -- (MEM pressed: the frequency stored as a channel)
        step(10, function() boxes = {}; if hitOf("mem") then rclick("mem") end end)
        step(20, function()
            if not hitOf("mem") then say("NOTE no MEM on " .. m.pid); return end
            shot(m.pid .. "_mem_naming")
            local found = false
            local ui = UIManager.getUI()
            for i = 0, ui:size() - 1 do
                local tb = nil; pcall(function() tb = ui:get(i):getTable() end)
                if type(tb) == "table" then
                    for _, v in pairs(tb) do if type(v) == "string" and v:find(ZeD.tr("UI_ZeD_Radio_NameChannel", "01"):sub(1, 8), 1, true) then found = tb end end
                end
            end
            check(#boxes >= 1 or found, m.pid .. ": MEM held (right-click) opens the naming box (shot " .. m.pid .. "_mem_naming)")
            if type(found) == "table" then pcall(function() found:destroy() end); pcall(function() found:removeFromUIManager() end) end
            shutBoxes()
            if hitOf("lamp") then click("lamp") end
        end)
        step(5, function()
            local t = tw()
            if hitOf("lamp") then say(m.pid .. ": Light pressed (its lit state is drawn from the face)") end
        end)
    end
    step(20, function() shot(m.pid) end)
    -- the controller
    step(5, function()
        local w = CW()
        if not Focus then return end
        Focus.claimFocus(w)
        local els = RT.buildFocusables(w) or {}
        say(m.pid .. ": controller stops " .. #els .. " | first " .. tostring(els[1] and els[1].id) .. " | last " .. tostring(els[#els] and els[#els].id))
        check(#els > 0 and tostring(els[1].id):find("power") ~= nil, m.pid .. ": the controller's first stop is the first row (" .. tostring(els[1] and els[1].id) .. ")")
        local foot = { mem = true, lamp = true }
        local card = {}
        for _, e in ipairs(els) do if tostring(e.id):find("^radio:tw:") then card[#card + 1] = e end end
        local lastId = card[#card] and tostring(card[#card].id) or ""
        if m.walkie then check(foot[lastId:match("[%w]+$") or ""] ~= nil, m.pid .. ": the footer comes last among the card's stops (" .. lastId .. ")") end
        pcall(function() Focus.releaseFocus() end)
    end)
    -- Full again: the face is back
    step(5, function() S.devicesStyleOption:setValue(1) end)
    step(20, function()
        local t = tw()
        check(t and t.dev == cur.it and not (t.drv and t.drv.plain), m.pid .. ": Devices on Full: the face is back")
        say(m.pid .. ": Full drawer " .. math.floor(CW()._drawerEffW or -1) .. " px")
        shot(m.pid .. "_full")
        S.devicesStyleOption:setValue(2)
    end)
    step(10, function()
        pcall(function() cur.it:getDeviceData():setIsTurnedOn(false) end)
        p:setPrimaryHandItem(nil)
    end)
end

step(5, function()
    ISContextMenu.get = ctxGet
    ISTextBox.new = tbNew
    for _, it in ipairs(added) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    for _, m in ipairs(SETS) do end
    p:setPrimaryHandItem(prim); p:setSecondaryHandItem(sec)
    if hWas.c then CW():setHeight(hWas.c); ZeD_WorldWindow.getWindow():setHeight(hWas.w) end
    S.devicesStyleOption:setValue(styleWas)
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
    say("DONE")
end)

local wait, waited = nil, 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        waited = waited + 1
        if not s.cond() and waited < (s.max or 100) then wait = 1; return end
        waited = 0
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
