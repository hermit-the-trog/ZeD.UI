-- ZeDUI/tools/qa/hfr_common.lua  (Nov 20 2026, QA): shared helpers for the beta 21 hotfix report's in-game pictures
-- (hfr_inv.lua, hfr_prompts.lua, hfr_devices.lua, hfr_tabs.lua). Run after gallery_v1_a_common.lua (G1) in the
-- manifest. HFR.init(tag) returns S: the step queue S.Q (G1.make), the windows, tab and row helpers, S.add / S.takeMade
-- (things given and taken back), S.shot(name) (the picture to Screenshots/hfr_<name>.png; the run wrapper moves them
-- into Screenshots/beta21_hotfix_report/). grep "ZEDQA <tag>".
HFR = HFR or {}
function HFR.init(tag, noStory)
    local Q = G1 and G1.make and G1.make(tag)
    if not Q then print("ZEDQA " .. tag .. " ERR run gallery_v1_a_common.lua first"); print("ZEDQA " .. tag .. " DONE"); return nil end
    if not noStory and not (STORY and STORY.ready and STORY.P) then Q.say("ERR run gallery_story_stage.lua first"); Q.say("DONE"); return nil end
    local S = { Q = Q, was = {}, made = {}, p = G1.p, pn = G1.pn, core = G1.core, P = STORY and STORY.P or {}, CWm = ZeD_CharacterWindow, WWm = ZeD_WorldWindow }
    S.DIR = "hfr_"
    function S.CW() return S.CWm.getWindow() end
    function S.WW() return S.WWm.getWindow() end
    function S.goTab(win, strip, tab)
        for _, z in ipairs(strip and strip._hitZones or {}) do
            if z.id == "tab:" .. tab then
                if win._activeTab ~= tab or (tab ~= "loot" and win._drawerOpen == false) then strip:onMouseDown(z.x + 2, z.y + 2) end
                return true
            end
        end
        return false
    end
    function S.charTab(id) local w = S.CW(); return (w and S.goTab(w, w._tabStripPanel, id)) and true or false end
    function S.worldTab(id) local w = S.WW(); return (w and S.goTab(w, w._actionTabStrip, id)) and true or false end
    function S.openPair()
        if getGameSpeed() <= 0 then setGameSpeed(1) end
        if not (S.CWm.isOpen() and S.WWm.isOpen()) then S.CWm.toggleBothPaired(S.pn) end
    end
    function S.closePair()
        if S.CWm.isOpen() and S.WWm.isOpen() then S.CWm.toggleBothPaired(S.pn)
        else
            if S.CWm.isOpen() then S.CWm.toggle(S.pn) end
            if S.WWm.isOpen() then S.WWm.close(S.pn) end
        end
    end
    function S.clearChar()
        G1.clear(Q, S.CW(), "left", "the Character window")
        G1.clear(Q, S.WW(), "right", "the World window")
    end
    function S.add(ft)
        local it = nil
        pcall(function() it = S.p:getInventory():AddItem(ft) end)
        if it then S.made[#S.made + 1] = it end
        return it
    end
    function S.takeMade()
        for _, it in ipairs(S.made) do
            pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
            pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
            pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
        end
        S.made = {}
    end
    -- (QA, Nov 20: the debug build's red "ERROR" box at the bottom right showed in some pictures; hidden before each one)
    function S.shot(name, keepMenu) pcall(G1.hideErrors, Q); Q.shot(S.DIR .. name, keepMenu) end
    function S.oneSource()
        local done = true
        for _, pair in ipairs({ { S.CW(), S.CWm }, { S.WW(), S.WWm } }) do
            local win, mod = pair[1], pair[2]
            if win then
                for _, j in ipairs(win._mcSelected or {}) do
                    local c = win._containers and win._containers[j]
                    if c and c.inventory and mod.toggleColumn and #(win._mcSelected or {}) > 1 then mod.toggleColumn(c.inventory); done = false; break end
                end
            end
        end
        return done
    end
    -- the list panels' hit zones
    function S.cc() local w = S.CW(); return w and w._mainContent end
    function S.wc() local w = S.WW(); return w and w._mainContent end
    function S.zone(c, id)
        for _, z in ipairs((c and c._hitZones) or {}) do if z.id == id then return z end end
        return nil
    end
    function S.zoneStarts(c, pre)
        for _, z in ipairs((c and c._hitZones) or {}) do if type(z.id) == "string" and z.id:sub(1, #pre) == pre then return z end end
        return nil
    end
    function S.click(c, z)
        if not (c and z) then return false end
        local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
        c._zedLastClick = nil
        c:onMouseDown(x, y)
        c:onMouseUp(x, y)
        return true
    end
    function S.seekRow(c, item)
        if not (c and item) then return false end
        if S.zone(c, item) then return true end
        local sc = c._scroll
        if sc and sc.setScrollPos then
            S.seekPos = (S.seekPos or -0.1) + 0.1
            if S.seekPos > 1.001 then S.seekPos = 0 end
            sc:setScrollPos(S.seekPos)
        end
        return false
    end
    function S.cardOn(item)
        local w = S.CW()
        local c = w and w._itemCard
        return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
    end
    -- a station or object card on the World window
    function S.worldClear()
        G1.clear(Q, S.WW(), "right", "the World window")
    end
    -- the first free square round the player (for a placed thing)
    function S.freeSq(offs)
        for _, o in ipairs(offs or { { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 }, { 3, 1 }, { -3, 1 } }) do
            local sq = getCell():getGridSquare(math.floor(S.p:getX()) + o[1], math.floor(S.p:getY()) + o[2], math.floor(S.p:getZ()))
            local free = false
            if sq then pcall(function() free = sq:isFree(false) end) end
            if free then return sq end
        end
        return nil
    end
    function S.start0()
        local W = S.was
        W.speed = getGameSpeed()
        W.pairOpen = S.CWm.isOpen() and S.WWm.isOpen()
        pcall(function() W.inv = S.p:isInvisible(); W.god = S.p:isGodMod(); W.dda = S.p:isZombiesDontAttack() end)
        G1.clean(Q)
        pcall(function() if STORY and STORY.day then STORY.day(11.0) end end)
        Q.say(string.format("start at %d,%d | screen %dx%d | Style %s", math.floor(S.p:getX()), math.floor(S.p:getY()),
            S.core:getScreenWidth(), S.core:getScreenHeight(), tostring(ZeD.Settings.lookStyleOption:getValue())))
        local gone = 0
        pcall(function()
            local zl = getCell():getZombieList()
            local px, py = S.p:getX(), S.p:getY()
            for i = zl:size() - 1, 0, -1 do
                local z = zl:get(i)
                if z and math.abs(z:getX() - px) < 40 and math.abs(z:getY() - py) < 40 then z:removeFromWorld(); z:removeFromSquare(); gone = gone + 1 end
            end
        end)
        Q.say("zombies taken away near the store: " .. gone)
        if S.P.stock then G1.tp(S.P.stock, "SE") end
    end
    -- ===== Style, picked as a player picks it (ZeD setup and Apply), as beta21_report.lua
    function S.opt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
    function S.menuUp() local up = false; pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end); return up end
    function S.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
    function S.setupRow(w, id)
        local o = S.opt(id)
        local el = o and o.element
        if not el then return nil end
        local rows = {}
        pcall(function() rows = w:zedSetupRows() end)
        for _, r in ipairs(rows) do if r.control == el then return r end end
        return nil
    end
    function S.stepTo(w, r, want)
        local c = r and r.control
        if not c then return false end
        for _ = 1, 8 do
            local cur = c.selected or 1
            if cur == want then return true end
            pcall(function() w:nudge(r, (want > cur) and 1 or -1) end)
            if c.selected == cur then break end
        end
        if c.selected ~= want then
            c.selected = want
            if c.onChange then pcall(c.onChange, c.target, c) end
        end
        return c.selected == want
    end
    function S.pickStyle(want)
        local MM, St = ZeD.MainMenu, ZeD.Settings
        Q.step(5, function()
            S.mu = S.menuUp()
            S.optOk = false
            if not S.mu then S.toggleMenu() end
        end)
        Q.waitFor(10, 400, function() return S.menuUp() and MM.pauseOpts ~= nil end, function(ok)
            if ok then pcall(MM.openOptions) end
        end)
        Q.waitFor(5, 300, function() return MM.pauseOpts ~= nil and MM.pauseOpts:isVisible() end, function(ok)
            local o = St.lookStyleOption
            if not ok then
                Q.say("note: Options did not open; Style set straight on the option")
                pcall(function() o:setValue(want); o:onChange(want) end)
                return
            end
            S.optOk = true
            local w = MM.pauseOpts
            for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
            w.scroll = 0
            local r = S.setupRow(w, "lookStyle")
            Q.say("Style row " .. tostring(r ~= nil) .. "; stepped to " .. want .. ": " .. tostring(r and S.stepTo(w, r, want)))
            pcall(function() w:apply(false) end)
        end)
        Q.step(30, function()
            local w = MM.pauseOpts
            if not (S.optOk and w) then return end
            if w.confirm and w.confirm ~= "back" then pcall(function() w:setConfirm(false) end) end
            w._groupCache = nil
            w.scroll = 0
            pcall(function() Mouse.setXY(20, 20) end)
        end)
        Q.step(10, function()
            local w = MM.pauseOpts
            if not (S.optOk and w) then return end
            pcall(function() w:back() end)
            if w.confirm == "back" then pcall(function() w:discard() end) end
        end)
        Q.step(10, function() if not S.mu and S.menuUp() then S.toggleMenu() end end)
        Q.waitFor(5, 300, function() return S.mu or not S.menuUp() end, function()
            Q.say("Style now " .. tostring(St.lookStyleOption:getValue()) .. ", lite() " .. tostring(St.lite and St.lite()))
        end)
    end
    -- the put-back at the end (call inside Q.step after Q.mark)
    function S.back0()
        S.takeMade()
        pcall(function() S.p:setInvisible(S.was.inv == true); S.p:setGodMod(S.was.god == true); S.p:setZombiesDontAttack(S.was.dda == true) end)
        pcall(function() setGameSpeed((S.was.speed and S.was.speed > 0) and S.was.speed or 1) end)
    end
    return S
end
print("ZEDQA hfrc helpers ready")
do local f; f = function() Events.OnTick.Remove(f); print("ZEDQA hfrc DONE") end; Events.OnTick.Add(f) end
