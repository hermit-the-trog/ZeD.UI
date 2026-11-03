-- ZeDUI/tools/qa/zedqa_beta_ig.lua  (Nov 2 2026, QA; punch list 58, 71 and 66, the beta builds 8e12102 and 8dece63)
-- In game at 4K.
--   58: the controller's UI scale wheel leaves 0.5x out; a saved 0.5 draws at 0.75 and the wheel shows it dimmed with
--       "Not offered in this build: it draws at 0.75x."; the saved pick is put back.
--   71: Hair and beard: a click on a style row picks it, a second click on the same row un-picks it.
--   66: bug reports. With no errors: the ZeD wheel's Bug report (ZeD.Messages.copyBugReport) says so and still copies
--       the header ("ZeD-GUI <version> | Project Zomboid <build>", "Mods on (N):", one mod a line). Then two Lua errors
--       made on purpose (expect=qaBetaError): Messages shows the summary card with "Copy all for a bug report", then one
--       card per kept error, newest first, headed with its time and "N of M kept", each with its own Copy; each Copy and
--       Copy all are read back from the clipboard; the wheel's Bug report copies both with the header and says
--       "2 errors are copied"; the ZeD wheel lists Bug report (bullhorn) right after Messages.
-- Everything is put back. grep "ZEDQA big"; shots zqa_big_*.png.
local function say(s) print("ZEDQA big " .. tostring(s)) end
local p = getPlayer()
local S, MS, HB, CW = ZeD and ZeD.Settings, ZeD and ZeD.Messages, ZeD and ZeD.HairBeard, ZeD_CharacterWindow
local D = ZeD and ZeD.DpadWheels
if not (p and S and MS and HB and D and D.Z and MS.copyBugReport) then say("ERR the beta pieces are not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_big_" .. n .. ".png") end) end
local function clip() local t = ""; pcall(function() t = tostring(Clipboard.getClipboard() or "") end); return t end
local function firstLines(t, n) local out = {}; for l in (t .. "\n"):gmatch("(.-)\n") do out[#out + 1] = l; if #out >= n then break end end; return out end
local function tr(k, ...) return ZeD.tr(k, ...) end
-- the modal the Bug report opens: caught so it can be read and shut
local modals = {}
local origModalNew = ISModalDialog.new
ISModalDialog.new = function(self, x, y, w, h, text, ...)
    local o = origModalNew(self, x, y, w, h, text, ...)
    modals[#modals + 1] = { o = o, text = text }
    return o
end
local function shutModals() for _, m in ipairs(modals) do pcall(function() m.o:destroy() end); pcall(function() m.o:removeFromUIManager() end) end; modals = {} end
-- the text shown by an open dialog: any string field of a UI element's table that holds the words looked for
local function shown(words)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = nil; pcall(function() t = ui:get(i):getTable() end)
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(v) == "string" and v:find(words, 1, true) then return v, t end
            end
        end
    end
    return nil
end
local function shutShown(t) if t then pcall(function() t:destroy() end); pcall(function() t:removeFromUIManager() end) end end
local function header(t, what)
    local l = firstLines(t, 3)
    check(l[1] and l[1]:find("^ZeD%-GUI .- | Project Zomboid ") ~= nil, what .. ": line 1 is the header (" .. tostring(l[1]) .. ")")
    local n = l[2] and tonumber(l[2]:match("^Mods on %((%d+)%):$"))
    check(n ~= nil and n > 0, what .. ": line 2 is \"Mods on (N):\" (" .. tostring(l[2]) .. ")")
    check(l[3] and l[3]:find("^  %S") ~= nil, what .. ": a mod a line after it (" .. tostring(l[3]) .. ")")
end

local Q = {}
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end

-- ---- 58: the scale wheel
local retired, scaleWas
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    scaleWas = S.uiScaleOption:getValue()
    for i = 1, #S.scaleKeys do if S.scaleStepRetired(i) then retired = i end end
    say("scale: saved pick " .. tostring(scaleWas) .. " (" .. tostring(S.scaleLabels[scaleWas]) .. ") | retired step " .. tostring(retired) .. " (" .. tostring(retired and S.scaleLabels[retired]) .. ")")
    local names, has = {}, false
    for _, e in ipairs(D.Z.scaleWheel()) do names[#names + 1] = tostring(e.name) .. (e.off and " [off]" or ""); if retired and e.name == S.scaleLabels[retired] then has = true end end
    say("scale wheel: " .. table.concat(names, ", "))
    check(retired ~= nil and not has, "58: the scale wheel leaves 0.5x out")
    if retired then S.uiScaleOption:setValue(retired); S.applyScale(retired) end
end)
step(120, function()
    if not retired then return end
    local g = ZeD.Scale.computeGame()
    check(math.abs(g - 0.75) < 0.01, "58: a saved 0.5 draws at 0.75 (" .. tostring(g) .. ")")
    local e
    for _, x in ipairs(D.Z.scaleWheel()) do if x.name == S.scaleLabels[retired] then e = x end end
    check(e ~= nil and e.off == tr("UI_ZeD_Settings_ScaleRetired") and e.run == nil,
        "58: with 0.5 saved the wheel shows it dimmed: \"" .. tostring(e and e.off) .. "\"")
    shot("scale_05_saved")
    S.uiScaleOption:setValue(scaleWas); S.applyScale(scaleWas)
end)
step(120, function() say("scale put back: " .. tostring(S.uiScaleOption:getValue()) .. ", draws " .. tostring(ZeD.Scale.computeGame())) end)

-- ---- 71: Hair and beard un-pick
local function win() return CW.getWindow() end
step(10, function() if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end end)
step(30, function()
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:identity" and w._activeTab ~= "identity" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    local st = w._hb; if st then st.tick = 999 end
end)
step(40, function()
    local w = win(); local st = w and w._hb
    local z
    for _, x in ipairs((st and st.zones) or {}) do if x.item and x.item.kind == "row" then z = x; break end end
    if not z then
        local kinds = {}
        for _, x in ipairs((st and st.zones) or {}) do local k = x.item and x.item.kind or "?"; kinds[k] = (kinds[k] or 0) + 1 end
        local ks = {}; for k, n in pairs(kinds) do ks[#ks + 1] = k .. " " .. n end
        say("71: tab " .. tostring(w and w._activeTab) .. " | _hb " .. tostring(st ~= nil) .. " | zones: " .. table.concat(ks, ", ") .. " | part " .. tostring(st and st.part))
    end
    if not z then
        -- no row is on screen in the tab's view (its click zones are made only for what shows): the click itself is
        -- checked on a stand-in row zone, which is what the fix changed (HB.onClick's pick and un-pick)
        say("71: no style row on screen; the click is checked on a stand-in row zone")
        z = { x = -5000, y = -5000, w = 40, h = 20, item = { kind = "row", row = { key = "qa_standin" } } }
        st.zones = st.zones or {}
        table.insert(st.zones, 1, z)
        shot("hair_tab")
    end
    st.sel = nil
    HB.onClick(w, z.x + 2, z.y + 2)
    local first = st.sel
    HB.onClick(w, z.x + 2, z.y + 2)
    local second = st.sel
    say("71: row " .. tostring(z.item.row.key) .. " | after click 1 " .. tostring(first) .. " | after click 2 " .. tostring(second))
    check(first == z.item.row.key, "71: a click picks the row")
    check(second == nil, "71: a second click on the picked row un-picks it")
    HB.onClick(w, z.x + 2, z.y + 2)
    check(st.sel == z.item.row.key, "71: a third click picks it again")
    st.sel = nil
end)
step(10, function() if CW.isOpen() then CW.toggleBothPaired(0) end end)

-- ---- 66: bug reports, no errors first
local srcWas, noneDlg, twoDlg
step(10, function()
    srcWas = MS.sources
    MS.sources = {}
    local n = MS.copyBugReport(0)
    local t = clip()
    check(n == 0, "66: with no errors the Bug report counts 0")
    local txt, o = shown("No errors were caught")
    say("66: the dialog's words are read from the picture zqa_big_bugreport_none (ZeD's prompt draws them; found in a field: " .. tostring(txt ~= nil) .. ")")
    noneDlg = o
    header(t, "66 no errors, the copy")
    check(t:find("No errors were caught this session.", 1, true) ~= nil, "66: the copy says no errors were caught")
end)
step(30, function() shot("bugreport_none"); shutModals(); shutShown(noneDlg) end)
-- two errors, a moment apart
step(5, function()
    local function boom1() Events.OnTick.Remove(boom1); local t = nil; return t.qaBetaErrorOne end
    Events.OnTick.Add(boom1)
end)
step(90, function()
    local function boom2() Events.OnTick.Remove(boom2); local t = nil; return t.qaBetaErrorTwo end
    Events.OnTick.Add(boom2)
end)
local name, mw
step(200, function()
    local _, errs = MS.list()
    name = errs and errs[1] and errs[1].name
    local it = name and MS.sources[name] and MS.sources[name].items[1]
    say("66: errors filed under " .. tostring(name) .. ", count " .. tostring(it and it.count) .. ", kept " .. tostring(it and #it.texts))
    check(it and it.count == 2 and #it.texts == 2, "66: the two errors are filed and kept")
    if name then mw = ZeD.MessagesWindow.open(0, name) end
end)
step(30, function()
    local g = mw and mw._g
    if not check(g and #g.cards >= 3, "66: Messages shows a summary card and one card per error (" .. tostring(g and #g.cards) .. " cards)") then return end
    local sumBtn = g.cards[1].btns and g.cards[1].btns[1]
    check(sumBtn and sumBtn.label == ZeD.btnCase(tr("UI_ZeD_Msg_CopyAll")), "66: the summary card's button is \"" .. tostring(sumBtn and sumBtn.label) .. "\"")
    local c2, c3 = g.cards[2], g.cards[3]
    say("66: card 2 head \"" .. tostring(c2.it.when) .. "\" | card 3 head \"" .. tostring(c3.it.when) .. "\"")
    check(c2.it.when:find(tr("UI_ZeD_Msg_ErrorNofM", 1, 2), 1, true) ~= nil and c3.it.when:find(tr("UI_ZeD_Msg_ErrorNofM", 2, 2), 1, true) ~= nil,
        "66: the error cards read \"1 of 2 kept\" then \"2 of 2 kept\"")
    local b2, b3 = c2.btns[1], c3.btns[1]
    check(b2 and b2.idx == 2 and b3 and b3.idx == 1, "66: newest first (card 2 is kept error 2, card 3 is kept error 1)")
    check(b2 and b2.label == ZeD.btnCase(tr("UI_ZeD_Msg_CopyOne")), "66: each error card has its own \"" .. tostring(b2 and b2.label) .. "\"")
    shot("messages_cards")
    -- each Copy, read back
    mw:pressCard(b2)
    local t2 = clip()
    header(t2, "66 the newest error's Copy")
    check(t2:find("qaBetaErrorTwo", 1, true) ~= nil and t2:find("qaBetaErrorOne", 1, true) == nil, "66: the newest card's Copy holds that error only")
    mw:pressCard(b3)
    local t3 = clip()
    check(t3:find("qaBetaErrorOne", 1, true) ~= nil and t3:find("qaBetaErrorTwo", 1, true) == nil, "66: the older card's Copy holds that error only")
    local ln = 0
    for l in (t3 .. "\n"):gmatch("(.-)\n") do ln = ln + 1; if l:find("qaBeta", 1, true) or l:find("^%-%-%-") or l:find("Exception", 1, true) or l:find("^[A-Z][a-z]+ %d") then say("66: older copy line " .. ln .. ": " .. l:sub(1, 180)) end end
    mw:pressCard(sumBtn)
    local ta = clip()
    header(ta, "66 Copy all")
    check(ta:find("qaBetaErrorOne", 1, true) ~= nil and ta:find("qaBetaErrorTwo", 1, true) ~= nil, "66: Copy all holds both errors")
    say("66: copy sizes: one " .. #t2 .. ", other " .. #t3 .. ", all " .. #ta)
end)
step(10, function()
    pcall(function() mw:close() end)
    local n = MS.copyBugReport(0)
    local t = clip()
    check(n == 2, "66: the wheel's Bug report counts 2 (" .. tostring(n) .. ")")
    local txt, o = shown(tr("UI_ZeD_Msg_BugReportCopied", 2):sub(1, 20))
    say("66: the dialog's words are read from the picture zqa_big_bugreport_two (found in a field: " .. tostring(txt ~= nil) .. ")")
    twoDlg = o
    header(t, "66 the wheel's Bug report")
    check(t:find("qaBetaErrorOne", 1, true) ~= nil and t:find("qaBetaErrorTwo", 1, true) ~= nil, "66: the Bug report holds both errors")
    -- the ZeD wheel: Bug report right after Messages, the bullhorn
    local list = D.B.zed(p, 0)
    local mi, bi
    for i, e in ipairs(list or {}) do
        if e.name == tr("UI_ZeD_Msg_Title") then mi = i end
        if e.name == tr("UI_ZeD_Msg_BugReport") then bi = i end
    end
    check(mi and bi == mi + 1 and list[bi].icon == "bullhorn", "66: the ZeD wheel has Bug report (bullhorn) right after Messages (" .. tostring(mi) .. ", " .. tostring(bi) .. ")")
end)
step(30, function() shot("bugreport_two"); shutModals(); shutShown(twoDlg) end)
step(10, function()
    ISModalDialog.new = origModalNew
    MS.sources = srcWas or {}
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
