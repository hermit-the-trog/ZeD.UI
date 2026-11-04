-- ZeDUI/tools/qa/zedqa_print_compare.lua  (Nov 4 2026, QA; the director: compare the game's newspapers and flyers
-- with ZeD's reader). In game on the QA save. For each piece: the game's own PZAPI PrintMedia window (built the way
-- ISReadABook:displayPrintMedia builds it), a picture, closed; then ZeD's reader (ZeD.Reader.openPrint), a picture,
-- closed. Pieces: two newspapers and two flyers. grep "ZEDQA prc". Pictures zqa_prc_<id>_vanilla / _zed.
local function say(s) print("ZEDQA prc " .. tostring(s)) end
local core = getCore()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_prc_" .. n .. ".png") end); say("shot " .. n) end
local p = getPlayer()
local IDS = { { "KnoxKnews_July1", "Base.Newspaper" }, { "KentuckyHerald_July6", "Base.Newspaper" },
              { "TacodelPancho", "Base.Flier" }, { "CrossRoadsMall", "Base.Flier" } }
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local cur = {}
for _, pair in ipairs(IDS) do
    local id, itype = pair[1], pair[2]
    step(20, function()
        local m = ZeD.Print.ofId(id)
        local it = instanceItem(itype) or instanceItem("Base.Newspaper")
        it:getModData().printMedia = { id = m.id, title = m.title, info = m.info, text = m.text }
        cur.item, cur.m = it, m
        say(id .. ": title " .. tostring(getTextOrNull(m.title)) .. ", layout " .. tostring(getTextOrNull(m.info) ~= nil))
        local win = PZAPI.UI.PrintMedia{ x = 730, y = 100 }
        win.media_id = m.id
        win.data = getText(m.info)
        win.children.bar.children.name.text = getText(m.title)
        win.textTitle = getText(m.title)
        win.textData = string.gsub(getText(m.text), "\\n", "\n")
        win:instantiate()
        win:centerOnScreen(0)
        cur.win = win
    end)
    step(60, function() shot(id .. "_vanilla") end)
    step(10, function()
        pcall(function() cur.win.javaObj:removeFromUIManager() end)
        local ok, r = pcall(ZeD.Reader.openPrint, p, cur.item)
        say(id .. ": ZeD reader opened " .. tostring(ok and r))
    end)
    step(60, function() shot(id .. "_zed") end)
    step(10, function() pcall(function() ZeD.Reader.get(0):close() end) end)
end
step(20, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
