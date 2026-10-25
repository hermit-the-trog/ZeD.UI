-- ZeDUI/tools/qa/zedqa_spncc_looks.lua  (Oct 25 2026)
-- MAIN MENU ONLY, with Spongie's Character Customisation (SPNCC) and the Retexture
-- add-on's faces (SPNRetextureCustom) on in mods/default.txt: the Looks screen's
-- FACE and DETAILS rows (ZeD/ModSupport/SPNCC.lua looksRows) drive the mod's own
-- picker on the game's hidden character screen, and the mod's stored data (what it
-- reads when the character spawns) follows. Walks New Game > Sandbox > map > sandbox
-- settings > traits > Looks, then back out to the main menu; nothing is started.
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
    local detRow = rowAfter(rows, getText("UI_characreation_bodydetail"))
    say("a DETAILS row: " .. tostring(detRow ~= nil))
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
