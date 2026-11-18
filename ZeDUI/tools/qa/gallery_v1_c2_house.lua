-- ZeDUI/tools/qa/gallery_v1_c2_house.lua  (Nov 17 2026, QA): ZeD-GUI 1.0 gallery, lived-in retakes in a furnished house
-- in West Point, the nearest to the Fossoil with a bedroom and a living room (or kitchen), found at run time
-- (C2.house). Same content and names as today's captures; only the place and the window places change:
--   32 Questions (the bedroom)   zqa_pr_01_sleep, zqa_pr_06_keyboard, zqa_pr_07_alarm   (gallery_b19_b.lua's questions:
--        the sleep question, the rename box with the keyboard, "Go Bag" + "s!", Set Alarm on a stand-in alarm 6:30)
--   34 Loadouts (the living room) zed_70_loadout_save, zed_71_loadout_fold, zed_73_loadout_todo_lines
--        (gallery_loadouts.lua: the loadout "Supply run", the list menu on the machete, the Equip tab's fold, the to-do)
--   37 Radios and the CD Player (the living room)  g14_radio_black, g14_radio_red, g14_radio_handbuilt, g14_radio_cd
--        (gallery_t14_radios.lua: each in the main hand, on at 98.0, batteries 60 per cent; the CD player playing)
--   38 Reading and Writing (the living room)  zqa_nb_01_page1, zqa_rd_01_paper  (zedqa_notebook.lua's first page,
--        "Supply runs"; zedqa_reader.lua's Knox Knews, July 1, on Paper)
-- THE NEW RULE: the Character window at the left edge, the World window at the right edge, prompts and the reader along
-- the top or at the left edge; the character and the room clear in the middle. Every shot logs the load line, any
-- container over its limit, and every window's box ("COVERS the character" if one does).
-- The house's power on and its light switches on for the run (vanilla will not write or read in the dark), the clock
-- at 11:00. Puts back: the loadout lists, menu look, Equip view and fold, hands, items given, light switches, power,
-- the clock, the windows, the character at the QA home. Run after gallery_v1_c2_common.lua. grep "ZEDQA gv1h".
if not (C2 and C2.make and ZeD and ZeD_CharacterWindow) then print("ZEDQA gv1h ERR run gallery_v1_c2_common.lua first (and ZeD on)"); print("ZEDQA gv1h DONE"); return end
local S = C2.make("gv1h")
S.v.p, S.v.pn = C2.p, C2.pn

-- ===================================================================== the house
S.step(5, function()
    C2.save(S)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    C2.rule()
end)
C2.goWestPoint(S)
S.step(2, function()
    S.v.B = C2.scan(C2.STORE.cx, C2.STORE.cy, 70)
    S.say("buildings with rooms seen round the store: " .. #S.v.B)
    S.v.H = C2.house(S, S.v.B)
    if not S.v.H then S.say("ERR no furnished house (a bedroom and a living room or kitchen) within 70 squares of the store") end
end)
S.step(5, function()
    if not S.v.H then return end
    C2.tpSq(S.v.H.bed); C2.face("SE")
    C2.placeName = "the bedroom of a house in West Point"
    C2.power(true)
    pcall(function() getGameTime():setTimeOfDay(11.0) end)
end)
S.step(90, function() if S.v.H then C2.lights(S, S.v.H) end end)
S.step(30, function() if S.v.H then C2.pairOpen() end end)
S.step(30, function() if S.v.H then C2.sides(S) end end)

-- ===================================================================== 32 Questions (the bedroom)
S.v.alarm = { h = 6, m = 30, on = true }
function S.v.alarm:getHour() return self.h end
function S.v.alarm:getMinute() return self.m end
function S.v.alarm:isAlarmSet() return self.on end
function S.v.alarm:setHour(v) self.h = v end
function S.v.alarm:setMinute(v) self.m = v end
function S.v.alarm:setAlarmSet(v) self.on = v end
function S.v.alarm:syncAlarmClock() end
function S.v.noop() end
-- the pointer where the prompt opens: top middle (prompts open on the pointer)
function S.v.topPoint() C2.pointAt(C2.core:getScreenWidth() / 2, math.floor(C2.core:getScreenHeight() * 0.12)) end
function S.v.promptEl()
    local P = ZeD.Prompt and ZeD.Prompt.open
    local el = P and P[#P]
    if el and el.isVisible then return el end
    return S.v.cur
end
-- the prompt along the top; the keyboard (if up) right under it; both to the left edge if that still covers
function S.v.placePrompt(withKb)
    local el = S.v.promptEl()
    C2.top(S, el, "the prompt")
    if not withKb then return end
    local kb = ZeD.Keyboard and ZeD.Keyboard.instance
    if not (kb and el) then S.say("note: no keyboard instance to place"); return end
    pcall(function()
        local W, m = C2.core:getScreenWidth(), C2.margin()
        kb:setX(math.floor((W - kb:getWidth()) / 2))
        kb:setY(el:getY() + el:getHeight() + m)
        if C2.coversEl(kb) or C2.coversEl(el) then
            el:setX(m); el:setY(m)
            kb:setX(m); kb:setY(el:getY() + el:getHeight() + m)
        end
        S.say(string.format("placed the keyboard at %d,%d (%dx%d)%s", kb:getX(), kb:getY(), kb:getWidth(), kb:getHeight(),
            C2.coversEl(kb) and " - still COVERS the character" or ""))
    end)
end
function S.v.extras()
    local t = {}
    local el = S.v.promptEl()
    if el then t[#t + 1] = { "prompt", el } end
    local kb = ZeD.Keyboard and ZeD.Keyboard.instance
    if kb then t[#t + 1] = { "keyboard", kb } end
    return t
end
S.step(10, function() if S.v.H then pcall(function() ZeD.Prompt.qaJoy = nil end) end end)
C2.ready(S)
S.step(5, function()
    if not S.v.H then S.notTaken("zqa_pr_01_sleep", "no house"); return end
    S.v.topPoint()
    S.v.cur = ISModalDialog:new(0, 0, 250, 150, getText("IGUI_ConfirmSleep"), true, nil, S.v.noop, 0, S.v.p, nil)
    S.v.cur:initialise(); S.v.cur:addToUIManager()
end)
S.step(15, function() if S.v.H then S.v.placePrompt(false) end end)
S.step(30, function() if S.v.H then C2.shot(S, "zqa_pr_01_sleep", { extra = S.v.extras() }) end end)
S.step(10, function() pcall(function() S.v.cur:answerCancel() end) end)
S.step(20, function()
    if not S.v.H then S.notTaken("zqa_pr_06_keyboard", "no house"); return end
    S.v.topPoint()
    S.v.bag = C2.give("Base.Bag_DuffelBag")
    S.v.bagName = S.v.bag and S.v.bag:getName()
    if S.v.bag then pcall(ISInventoryPaneContextMenu.onRenameBag, S.v.bag, S.v.pn) end
    S.v.cur = ZeD.Prompt and ZeD.Prompt.open and ZeD.Prompt.open[#ZeD.Prompt.open]
    if not (S.v.cur and S.v.cur.entry) then
        S.v.cur = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_NameThisBag"), "Duffel Bag", nil, S.v.noop, 0)
        S.v.cur:initialise(); S.v.cur:addToUIManager()
    end
end)
S.step(20, function()
    if not S.v.H then return end
    pcall(function() S.v.cur.entry:setText("Go Bag") end)
    pcall(function() OnScreenKeyboard.Show(0, S.v.cur.entry, nil) end)
end)
S.step(20, function()
    if not S.v.H then return end
    pcall(function() local k = ZeD.Keyboard.instance; k:pressKey({ lo = "s", up = "S" }); k:pressKey({ lo = "!", up = "!" }) end)
    pcall(function() S.say("typed: " .. tostring(S.v.cur.entry:getText())) end)
    S.v.placePrompt(true)
end)
S.step(30, function() if S.v.H then C2.shot(S, "zqa_pr_06_keyboard", { extra = S.v.extras() }) end end)
S.step(10, function() pcall(function() ZeD.Keyboard.instance:cancel() end) end)
S.step(15, function()
    pcall(function() S.v.cur.entry:setText(S.v.bagName or "Duffel Bag") end)
    if not pcall(function() S.v.cur:answerCancel() end) then pcall(function() S.v.cur:pressPrimary() end) end
end)
S.step(20, function()
    if not S.v.H then S.notTaken("zqa_pr_07_alarm", "no house"); return end
    S.v.topPoint()
    S.v.cur = ISAlarmClockDialog:new(0, 0, 230, 160, S.v.pn, S.v.alarm)
    S.v.cur:initialise(); S.v.cur:addToUIManager()
end)
S.step(15, function() if S.v.H then S.v.placePrompt(false) end end)
S.step(30, function() if S.v.H then C2.shot(S, "zqa_pr_07_alarm", { extra = S.v.extras() }) end end)
S.step(10, function() pcall(function() S.v.cur:press(S.v.cur.ok) end) end)
S.step(10, function() pcall(function() if S.v.cur and S.v.cur:isVisible() then S.v.cur:removeFromUIManager() end end); S.v.cur = nil end)

-- ===================================================================== to the living room
S.step(10, function()
    if not S.v.H then return end
    C2.tpSq(S.v.H.living); C2.face("SE")
    C2.placeName = "the " .. tostring(S.v.H.living.room) .. " of a house in West Point"
end)
S.step(60, function() if S.v.H then C2.lights(S, S.v.H); C2.sides(S) end end)

-- ===================================================================== 34 Loadouts (gallery_loadouts.lua)
S.v.L, S.v.R, S.v.EL, S.v.Opt = ZeD.Lists, ZeD.Restock, ZeD.EquipLoadout, ZeD.Settings
function S.v.deepCopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = S.v.deepCopy(v) end
    return o
end
function S.v.line(t) t.amount = t.amount or 1; t.unit = t.unit or "n"; t.place = t.place or "inv"; t.rule = t.rule or "any"; return t end
function S.v.found(ft)
    local items = S.v.p:getInventory():getAllTypeRecurse(ft)
    return items and items:size() > 0 and items:get(0) or nil
end
S.step(5, function()
    if not (S.v.H and S.v.L and S.v.R and S.v.EL) then S.v.noLo = true; return end
    local md = S.v.p:getModData()
    local w = C2.cw()
    S.v.loWas = { lists = S.v.deepCopy(md.ZeD_Lists), ctx = S.v.Opt.contextStyleOption:getValue(), view = ZeD.EquipDoll.view(),
                  fold = S.v.EL.openFor[S.v.pn], tab = w and w._activeTab, listExp = w and w._equipListExpanded }
    -- (gallery_unload.lua may have set the machete aside: one given for the shots, taken back after)
    if not S.v.found("Base.Machete") then C2.give("Base.Machete"); S.say("a machete given for the loadout (the carried one was set aside)") end
    local machete = S.v.found("Base.Machete")
    md.ZeD_Lists = nil
    local lo = S.v.L.create(S.v.p, "loadout", "Supply run")
    local id = lo.id
    if machete then S.v.L.addLine(S.v.p, id, S.v.line({ sec = "gear", place = "hand:main", rule = "this", type = "Base.Machete", itemId = machete:getID(), name = machete:getDisplayName() })) end
    S.v.L.addLine(S.v.p, id, S.v.line({ sec = "gear", type = "Base.Hammer", name = "Hammer" }))
    S.v.L.addLine(S.v.p, id, S.v.line({ sec = "supply", per = "day", type = "Base.Apple", name = "Apple", amount = 2 }))
    S.v.L.addLine(S.v.p, id, S.v.line({ sec = "supply", per = "day", kind = "water", unit = "l", type = "Base.WaterBottle", name = "Water", amount = 1 }))
    S.v.L.addLine(S.v.p, id, S.v.line({ sec = "supply", per = "fixed", type = "Base.Bandage", name = "Bandage", amount = 4 }))
    S.v.R.setLoadout(S.v.p, id); S.v.R.setDays(S.v.p, 2)
    S.v.EL.plan(C2.cw(), true)
    S.say("loadout Supply run made (machete " .. tostring(machete ~= nil) .. ")")
end)
C2.ready(S)
S.step(5, function()
    if S.v.noLo then return end
    S.v.Opt.contextStyleOption:setValue(2)
    local it = S.v.found("Base.Machete") or S.v.found("Base.Apple")
    local w = C2.cw()
    ISInventoryPaneContextMenu.createMenu(S.v.pn, true, { it }, w:getX() + math.floor(w:getWidth() * 0.42), w:getY() + math.floor(w:getHeight() * 0.22))
end)
S.step(40, function() if S.v.noLo then S.notTaken("zed_70_loadout_save", "no house or no loadout code") else C2.shot(S, "zed_70_loadout_save", { menu = true }) end end)
S.step(5, function() C2.closeMenus(); if S.v.loWas then S.v.Opt.contextStyleOption:setValue(S.v.loWas.ctx) end end)
S.step(10, function()
    if S.v.noLo then return end
    local w = C2.cw()
    ZeD.EquipDoll.setView("list")
    w._activeTab = "equip"; w._drawerMode = "tab"; w._drawerOpen = true
    w._equipSelected = nil; w._equipListExpanded = false
    S.v.EL.openFor[S.v.pn] = true
    if w._equipScroll then w._equipScroll:setScrollPos(0) end
    S.v.EL.plan(w, true)
end)
S.step(30, function() end)
C2.ready(S)
S.step(5, function()
    if S.v.noLo then S.notTaken("zed_71_loadout_fold", "no house or no loadout code"); return end
    pcall(function() local s = S.v.EL.state(C2.cw()); S.say("ready " .. tostring(s.readyN) .. " of " .. tostring(s.readyM)) end)
    C2.shot(S, "zed_71_loadout_fold")
end)
S.step(5, function() if not S.v.noLo then S.v.EL.openTodo(C2.cw()) end end)
S.step(30, function() if not S.v.noLo then local s = S.v.EL.state(C2.cw()); if s.scroll then s.scroll:setScrollPos(1) end end end)
C2.ready(S)
S.step(10, function() if S.v.noLo then S.notTaken("zed_73_loadout_todo_lines", "no house or no loadout code") else C2.shot(S, "zed_73_loadout_todo_lines") end end)
S.step(5, function()
    if not S.v.loWas then return end
    local w = C2.cw()
    local W = S.v.loWas
    pcall(function() S.v.EL.closeTodo(w) end)
    S.v.p:getModData().ZeD_Lists = W.lists
    S.v.L.gen = S.v.L.gen + 1
    pcall(function() S.v.R.touch() end)
    ZeD.EquipDoll.setView(W.view)
    S.v.EL.openFor[S.v.pn] = W.fold
    w._equipListExpanded = W.listExp
    w._activeTab = W.tab or "loot"
    C2.charTab("loot")
    S.say("loadouts put back")
end)

-- ===================================================================== 37 Radios and the CD Player (gallery_t14_radios.lua)
S.v.handsWas = { S.v.p:getPrimaryHandItem(), S.v.p:getSecondaryHandItem() }
function S.v.radio(m)
    S.step(5, function()
        S.v.rOk = S.v.H ~= nil and ZeD.RadioTab ~= nil and ZeD.Rtv ~= nil
        if not S.v.rOk then return end
        local it = C2.give(m.ft)
        S.v.rCur = it
        if not it then S.v.rOk = false; S.say("ERR could not make " .. m.ft); return end
        local dd = it:getDeviceData()
        if dd then
            if dd:getIsBatteryPowered() then dd:setHasBattery(true); dd:setPower(0.6) end
            dd:setDeviceVolume(0.4)
            pcall(function() dd:setChannel(98000) end)
            dd:setIsTurnedOn(true)
            if m.cd then
                pcall(function() dd:addMediaItem(instanceItem("Base.Disc_Retail")) end)
                pcall(function() dd:StartPlayMedia() end)
            end
        end
        S.v.p:setSecondaryHandItem(nil)
        S.v.p:setPrimaryHandItem(it)
    end)
    S.waitFor(5, 300, function() if not S.v.rOk then return true end local r = C2.cw()._radios and C2.cw()._radios[1]; return r ~= nil and r.radioInstance == S.v.rCur end,
        function() if S.v.rOk and not C2.charTab("radio") then S.say("ERR " .. m.name .. ": no Radio tab") end end)
    S.waitFor(5, 300, function() if not S.v.rOk then return true end local t = C2.cw()._radioTw; return t ~= nil and t.dev == S.v.rCur end, function()
        if not S.v.rOk then return end
        local t = C2.cw()._radioTw
        S.say(m.name .. ": face " .. tostring(t and t.pid) .. ", card " .. math.floor(C2.cw()._drawerEffW or 0) .. " px, on " .. tostring(S.v.rCur:getDeviceData():getIsTurnedOn()))
    end)
    S.waitFor(60, 600, function() return not S.v.rOk or not m.cd or S.v.rCur:getDeviceData():isPlayingMedia() end, function() end)
    C2.ready(S)
    S.step(5, function()
        if not S.v.rOk then S.notTaken(m.name, "no house or the radio faces are not loaded"); return end
        C2.shot(S, m.name)
        pcall(function()
            local w, t = C2.cw(), C2.cw()._radioTw
            if t and t.face then S.say(string.format("box %s face %s at %d,%d (window origin %d,%d) k %s", m.name, tostring(t.pid), t.face.x or -1, t.face.y or -1, w:getAbsoluteX(), w:getAbsoluteY(), tostring(t.k))) end
        end)
    end)
    S.step(5, function()
        local dd = S.v.rCur and S.v.rCur:getDeviceData()
        if dd then pcall(function() dd:StopPlayMedia() end); pcall(function() dd:setIsTurnedOn(false) end) end
        pcall(function() S.v.p:setPrimaryHandItem(nil) end)
    end)
end
S.v.radio({ ft = "Base.RadioBlack", name = "g14_radio_black" })
S.v.radio({ ft = "Base.RadioRed", name = "g14_radio_red" })
S.v.radio({ ft = "Base.RadioMakeShift", name = "g14_radio_handbuilt" })
S.v.radio({ ft = "Base.CDplayer", name = "g14_radio_cd", cd = true })
S.step(10, function()
    pcall(function() S.v.p:setPrimaryHandItem(S.v.handsWas[1]); S.v.p:setSecondaryHandItem(S.v.handsWas[2]) end)
    C2.charTab("loot")
end)

-- ===================================================================== 38 Reading and Writing
-- the notebook (zedqa_notebook.lua): Write through vanilla's own path, page 1 and the title; the windows shut, as then
S.v.PAGE1 = "day 3. truck still wont start. tried the battery\nfrom the van on 31W, nothing. maybe its the starter\n\nthe U-Store It place on that flyer - muldraugh.\nlock-ups. guns n ammo it said!! check tmrw early"
function S.v.reader() local r = nil; pcall(function() r = ZeD.Reader.get(S.v.pn) end); return r end
S.step(10, function()
    if not (S.v.H and ZeD.Reader) then S.v.noRd = true; return end
    C2.pairShut()
    S.v.book = C2.give("Base.Notebook")
    S.v.pencil = C2.give("Base.Pencil")
end)
S.waitFor(5, 400, function() if S.v.noRd then return true end local d = true; pcall(function() d = S.v.p:tooDarkToRead() end); return not d end, function(ok)
    if S.v.noRd then return end
    S.say("light to write by: " .. tostring(ok))
    local okW, e = pcall(ISInventoryPaneContextMenu.onWriteSomething, S.v.book, true, S.v.pn)
    if not okW then S.say("ERR write " .. tostring(e)) end
end)
S.waitFor(10, 400, function() if S.v.noRd then return true end local r = S.v.reader(); return r ~= nil and r:isVisible() end, function(ok)
    if S.v.noRd then return end
    if not ok then S.v.nbFail = "the notebook page never opened"; return end
    local r = S.v.reader()
    S.say("open mode " .. tostring(r.mode) .. " pages " .. tostring(r.nPages) .. " readOnly " .. tostring(r.readOnly))
    pcall(function() r.nbEntry:setText(S.v.PAGE1); r.nbTitle:setText("Supply runs") end)
end)
S.step(15, function() if not (S.v.noRd or S.v.nbFail) then C2.side(S, S.v.reader(), "left", "the notebook") end end)
S.step(30, function()
    if S.v.noRd or S.v.nbFail then S.notTaken("zqa_nb_01_page1", S.v.nbFail or "no house or no reader"); return end
    C2.side(S, S.v.reader(), "left", "the notebook")
    C2.shot(S, "zqa_nb_01_page1", { extra = { { "reader", S.v.reader() } } })
end)
S.step(10, function() pcall(function() S.v.reader():endWriting() end) end)
S.step(20, function() pcall(function() local r = S.v.reader(); if r and r:isVisible() then r:close() end end) end)
-- the newspaper (zedqa_reader.lua): Read, instant for the run, Knox Knews July 1 on Paper
function S.v.media(id) return { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" } end
S.step(10, function()
    if S.v.noRd then return end
    pcall(function() S.v.p:setTimedActionInstantCheat(true) end)
    S.v.news = C2.give("Base.Newspaper")
    if not S.v.news then S.v.rdFail = "no newspaper"; return end
    S.v.news:getModData().printMedia = S.v.media("KnoxKnews_July1")
    pcall(function() S.v.news:setName(getText("Print_Media_KnoxKnews_July1_title")) end)
    ISTimedActionQueue.add(ISReadABook:new(S.v.p, S.v.news))
end)
S.waitFor(10, 400, function() if S.v.noRd or S.v.rdFail then return true end local r = S.v.reader(); return r ~= nil and r:isVisible() end, function(ok)
    if not ok and not (S.v.noRd or S.v.rdFail) then S.v.rdFail = "the reader never opened" end
    pcall(function() S.v.p:setTimedActionInstantCheat(false) end)
end)
S.step(40, function()
    if S.v.noRd or S.v.rdFail then return end
    local r = S.v.reader()
    S.say("reader view " .. tostring(r.view) .. " body " .. tostring(r.page and r.page.body))
    C2.side(S, r, "left", "the reader")
end)
S.step(30, function()
    if S.v.noRd or S.v.rdFail then S.notTaken("zqa_rd_01_paper", S.v.rdFail or "no house or no reader"); return end
    C2.side(S, S.v.reader(), "left", "the reader")
    C2.shot(S, "zqa_rd_01_paper", { extra = { { "reader", S.v.reader() } } })
end)
S.step(10, function()
    pcall(function() local r = S.v.reader(); if r and r:isVisible() then r:close() end end)
    pcall(function() S.v.p:setTimedActionInstantCheat(false) end)
end)

-- ===================================================================== put back
S.mark()
S.step(20, function()
    pcall(function() local r = S.v.reader(); if r and r:isVisible() then r:close() end end)
    pcall(function() S.v.p:setTimedActionInstantCheat(false) end)
    if S.v.loWas and S.v.p:getModData().ZeD_Lists ~= S.v.loWas.lists then
        pcall(function() S.v.p:getModData().ZeD_Lists = S.v.loWas.lists; S.v.L.gen = S.v.L.gen + 1 end)
    end
    C2.pairOpen()
end)
S.step(20, function() C2.back(S) end)
S.step(30, function() end)
S.start()
