-- ZeDUI/tools/qa/zedqa_house_ad.lua  (Nov 7 2026, QA; Build's 44df3931, the house ad's fit): the survival guide's
-- house ad (the publisher's own whole-page ad) at Small and at Large text, in the game's language. The book is opened
-- with ZeD.GuideBook.open, so a language that F1 sends to the window (Thai) is seen in the book too (said in the log).
-- Pictures zqa_had_<lang>_<small|large>.png; grep "ZEDQA had". Render frames (the open book pauses the game).
local function say(s) print("ZEDQA had " .. tostring(s)) end
local B, G = ZeD.GuideBook, ZeD.Guide
local lang = "EN"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)
local keepSize = ZeD.currentSize
local function setSize(k) ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, k) end
local function houseSpread()
    local bk = B.books[0]
    for i, p in ipairs(bk and bk.pages or {}) do
        if p.kind == "ad" and (p.ad == nil or p.ad == "house") then return math.floor((i + 1) / 2), i end
    end
end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(30, function()
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow()
    if cw and cw:isReallyVisible() then ZeD_CharacterWindow.toggleBothPaired(0) end
    pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end)
    setSize("small")
    say("language " .. lang .. "; F1 would open " .. (G.useBook() and "the book" or "the window") .. "; the book opened directly")
    B.open(0)
end)
for _, sz in ipairs({ "small", "large" }) do
    step(40, function() setSize(sz) end)
    step(40, function()
        local s, i = houseSpread()
        say(sz .. ": house ad on page index " .. tostring(i) .. " (spread " .. tostring(s) .. "), head " .. tostring(ZeD.tr("UI_ZeD_Guide_Ad1_Head")) .. ", deck " .. tostring(ZeD.tr("UI_ZeD_Guide_Ad1_Deck")))
        if s then B.books[0].spread = s end
    end)
    step(40, function() pcall(function() getCore():TakeFullScreenshot("zqa_had_" .. lang .. "_" .. sz .. ".png") end); say("shot " .. sz) end)
end
step(10, function()
    pcall(B.close, 0)
    setSize(keepSize or "small")
    say("DONE")
end)
local function tick()
    if wait > 0 then wait = wait - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    wait = s.n
end
say("start")
Events.OnRenderTick.Add(tick)
