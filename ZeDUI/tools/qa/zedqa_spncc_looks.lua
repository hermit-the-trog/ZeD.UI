-- ZeDUI/tools/qa/zedqa_spncc_looks.lua  (Oct 25 2026)
-- MAIN MENU ONLY, with Spongie's Character Customisation (SPNCC) and the Retexture
-- add-on's faces (SPNRetextureCustom) on in mods/default.txt: the Looks screen's
-- FACE and DETAILS rows (ZeD/ModSupport/SPNCC.lua looksRows) drive the mod's own
-- picker on the game's hidden character screen, and the mod's stored data (what it
-- reads when the character spawns) follows. DETAILS is a fold, shut to begin with: this opens it first.
-- Walks New Game > Sandbox > map > sandbox settings > traits > Looks, then back out to the
-- main menu; nothing is started.
-- Shots: zqa_spnl_*.png in Zomboid/Screenshots. grep "ZEDQA spnl".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA spnl " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_spnl_" .. n .. ".png") end); say("shot " .. n) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function vwin(view)
    for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end
    return nil
end
local function looks() return MainScreen.instance and MainScreen.instance.charCreationMain end
local function rowAfter(rows, headText, label)
    local inHead = false
    for i, r in ipairs(rows) do
        if r.kind == "header" then inHead = (r.text == headText)
        elseif inHead and (label == nil or r.label == label) then return r, i end
    end
    return nil
end
-- THE FOLD. S.closed.looks is the switch (true: shut): openFold / shutFold go the player's way, the head's stop and A
local function detHead(rows)
    for i, r in ipairs(rows) do if r.onFold then return r, i end end
    return nil
end
local function headSpec(W, r)
    for _, b in ipairs(W._specs or {}) do if b.rowRef and b.rowRef.onFold then return b end end
    return nil
end
local function pressHead(W)
    local b = headSpec(W)
    check(b ~= nil, "the Details head is a stop")
    if not b then return end
    W.focusId = b.id
    W:joyA()
end

local steps = {}
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
step(30, function()
    check(ZeD.ModSupport and ZeD.ModSupport.SPNCC ~= nil, "ZeD's SPNCC support is loaded")
    MM.showView("newgame")
end)
step(40, function()
    local nw = R.newWin
    for i, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = i end end
    nw:next()
end)
step(60, function() vwin("spawn"):next() end)
step(60, function() vwin("sandbox"):next() end)
step(60, function() vwin("traits"):next() end)
step(90, function()
    local W = vwin("looks")
    local v = looks()
    check(W ~= nil and v ~= nil and v.characterCustomisationPanel ~= nil, "the Looks screen and the mod's picker are up")
    local rows = W:rowsNow()
    local faceRow = rowAfter(rows, getText("UI_characreation_face"))
    check(faceRow ~= nil and faceRow.kind == "combo", "a FACE row")
    say("face options: " .. tostring(faceRow and #faceRow.control.options))
    local dh = detHead(rows)
    say("a DETAILS head: " .. tostring(dh ~= nil))
    if dh then
        check(dh.text == getText("UI_characreation_bodydetail"), "the head has the game's word")
        check(dh.shut == true and ZeD.ModSupport.SPNCC.closed.looks == true, "Details start shut")
        check(rowAfter(rows, dh.text) == nil, "shut, no tick rows are built")
        say("details picked: " .. tostring(dh.count))
    end
    local hair = false
    for _, r in ipairs(rows) do if r.label == getText("UI_ChestHair"):gsub(":%s*$", "") then hair = true end end
    say("body hair row: " .. tostring(hair))
    shot("top")
    -- scroll to the FACE rows
    local _, fi = rowAfter(rows, getText("UI_characreation_face"))
    W.scroll = math.max(0, ((fi or 1) - 10) * ZeD.T.px(32))
end)
step(40, function() shot("face_rows") end)
step(10, function()
    local W, v = vwin("looks"), looks()
    local faceRow = rowAfter(W:rowsNow(), getText("UI_characreation_face"))
    if not faceRow then return end
    local c = faceRow.control
    local i = math.min(3, #c.options)
    c.selected = i
    c.onChange(c.target, c)
    local sel = v.characterCustomisationPanel.faceMenu:getSelectedOption()
    say("picked " .. tostring(c.options[i]) .. ", the mod's face " .. tostring(sel and sel.display))
    check(sel ~= nil and tostring(sel.display or sel.name) == c.options[i], "the mod's face menu holds the pick")
    local ok, data = pcall(require, "CharacterCustomisation/CharacterCreation/StoredCharacterData")
    check(ok and data and data.face and data.face.name == sel.name, "the mod's stored data has the face (read at spawn)")
end)
step(40, function() shot("face_picked") end)
-- the fold, with the controller's stop and A: open it, tick a detail, shut it, and the pick stays
local pickedDet, picksBefore
step(10, function()
    local W = vwin("looks")
    local dh = detHead(W:rowsNow())
    picksBefore = dh and dh.count
    shot("details_shut")
    if dh then pressHead(W) end
end)
step(40, function()
    local W = vwin("looks")
    local rows = W:rowsNow()
    local dh = detHead(rows)
    if not dh then return end
    check(dh.shut == false and ZeD.ModSupport.SPNCC.closed.looks == false, "A opens Details")
    local first = rowAfter(rows, dh.text)
    check(first ~= nil and first.kind == "tick", "open, the tick rows are there")
    shot("details_open")
    if first then
        pickedDet = first.label
        first.control.changeOptionMethod(nil, 1, not first.control.selected[1])
    end
end)
step(40, function()
    local W = vwin("looks")
    local dh = detHead(W:rowsNow())
    if not dh then return end
    check(dh.count ~= picksBefore, "the head's number follows a pick: " .. tostring(picksBefore) .. " to " .. tostring(dh.count))
    picksBefore = dh.count
    local b = headSpec(W)
    if b then
        W.focusId = b.id
        W:joyDir("left")
        check(ZeD.ModSupport.SPNCC.closed.looks == false, "left doesn't fold")
        W.focusId = b.id
        W:joyDir("right")
        check(ZeD.ModSupport.SPNCC.closed.looks == false, "right doesn't fold")
    end
    shot("details_picked")
    pressHead(W)
end)
step(40, function()
    local W = vwin("looks")
    local rows = W:rowsNow()
    local dh = detHead(rows)
    if not dh then return end
    check(dh.shut == true, "A shuts Details")
    check(rowAfter(rows, dh.text) == nil, "shut, the ticks are out of the stops")
    check(dh.count == picksBefore, "the pick stays while shut")
    local ok, data = pcall(require, "CharacterCustomisation/CharacterCreation/StoredCharacterData")
    say("stored details: " .. tostring(ok and data and data.bodyDetails and #data.bodyDetails))
    local panel = looks().characterCustomisationPanel
    local n = 0
    for _ in pairs(panel.bodyDetailMenu.selectedOptions) do n = n + 1 end
    check(n >= dh.count, "the mod's menu keeps the pick with the fold shut")
    shot("details_shut_picked")
end)
step(30, function()
    vwin("looks"):back(); vwin("traits"):back(); vwin("sandbox"):back(); vwin("spawn"):back()
    R.newWin:back(); MM.showView("main")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
