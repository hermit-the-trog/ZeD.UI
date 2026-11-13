-- ZeDUI/tools/qa/zedqa_book83_fonts.lua  (Nov 3 2026, QA; punch list 83: why the book's type draws small and plain)
-- For each face the book names: the UIFont slot, its height and a word's width from the game's own text manager and
-- from ZeD's, then the same word drawn by drawTextZoomed at zoom 1 on a plain panel, pictured beside UIFont.Small and
-- ZeD_PrintPage's SdfOldRegular. Shot zqa_b83f_<w>x<h>.png; grep "ZEDQA b8f".
local function say(s) print("ZEDQA b8f " .. tostring(s)) end
local slots = { "SdfOldRegular", "SdfOldBold", "SdfOldItalic", "SdfRobertoSans", "SdfRegular", "SdfBold", "SdfItalic", "Small", "Medium", "Large" }
local gtm = getTextManager()
local rtm = (ZeD and ZeD.Text and ZeD.Text.realTM and ZeD.Text.realTM()) or gtm
say("ZeD.Text.realTM is " .. ((rtm == gtm) and "the game's own text manager" or "a different object"))
for _, s in ipairs(slots) do
    local f = UIFont[s]
    local h1, w1, h2, w2 = -1, -1, -1, -1
    pcall(function() h1 = gtm:getFontHeight(f); w1 = gtm:MeasureStringX(f, "Apocalypse") end)
    pcall(function() h2 = rtm:getFontHeight(f); w2 = rtm:MeasureStringX(f, "Apocalypse") end)
    say(string.format("%-15s %s | game h %s w %s | realTM h %s w %s", s, tostring(f), tostring(h1), tostring(w1), tostring(h2), tostring(w2)))
end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local p = ISPanel:new(100, 100, 1600, 900)
p:initialise()
p.backgroundColor = { r = 0.96, g = 0.93, b = 0.82, a = 1 }
p:addToUIManager()
p:setAlwaysOnTop(true)
function p:render()
    ISPanel.render(self)
    local y = 20
    for _, s in ipairs(slots) do
        self:drawTextZoomed("Apocalypse " .. s, 20, y, 1.0, 0.1, 0.1, 0.1, 1, UIFont[s])
        self:drawText("| drawText " .. s, 900, y, 0.1, 0.1, 0.1, 1, UIFont[s])
        y = y + 80
    end
end
local n = 0
local function later()
    n = n + 1
    if n == 30 then pcall(function() getCore():TakeFullScreenshot("zqa_b83f_" .. sw .. "x" .. sh .. ".png") end); say("shot") end
    if n < 60 then return end
    Events.OnRenderTick.Remove(later)
    p:removeFromUIManager()
    say("DONE")
end
Events.OnRenderTick.Add(later)
say("start")
