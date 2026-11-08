-- ZeDUI/tools/qa/zedqa_b8_known.lua  (Nov 8 2026, QA; CHECK_known_issues_20261107.md, the single-player parts)
-- What a single-player game can read of the beta 7 known issues:
--   * split-screen gates, one player: ZeD's windows are player 1's (ZeD.windowsFor: nil and 0 yes, 1 to 3 no), and player 1 has
--     a belt of their own at the game's start (ZeD.Belt.getHUD(0)), no belt for a player 2 who is not there
--   * the inventory key and Y still open and shut ZeD's pair for the first player (the game's key event)
--   * French and Hungarian month words in dates are lower case, English keeps its capitals (Journal and main-menu keys, read through
--     the loaded language: a run in another language says so and checks only what its language has)
--   * the Journal / ticket date stamps use those words in the language's order
-- Not scriptable here (see the final report): ZeD picks with ZeD-GUI (the Mods screen at the main menu: mods_order_sim / a
-- main-menu run), split screen with two pads, the dash ash tray (needs a car and a seat; the dash scripts), servers.
-- Puts back the windows' open state. grep "ZEDQA b8ki".
local TAG = "b8ki"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end; return ok end
local p = getPlayer()
local CW = ZeD_CharacterWindow
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = {}
local lang = "?"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)

local function keepDown()
    local w = CW.getWindow()
    if w then w._autoShaded = false; if w.windowShaded then w:setWindowShaded(false) end; w._outSince = getTimestampMs() + 600000 end
end

step(10, function()
    say("language " .. lang .. ", players: " .. tostring(getNumActivePlayers and getNumActivePlayers()))
    check(ZeD.windowsFor ~= nil, "ZeD.windowsFor exists")
    if ZeD.windowsFor then
        check(ZeD.windowsFor(nil) == true and ZeD.windowsFor(0) == true, "the first player (and nobody named) has ZeD's windows")
        check(not ZeD.windowsFor(1) and not ZeD.windowsFor(2) and not ZeD.windowsFor(3), "players 2 to 4 have the game's own")
    end
    local B = ZeD.Belt
    local b0 = B and B.getHUD and B.getHUD(0)
    check(b0 ~= nil and b0.playerNum == 0, "the first player has a belt of their own")
    check(B and B.getHUD and B.getHUD(1) == nil, "no belt for a player 2 who is not in this game")
    check(B and B.getHUD and B.getHUD() == b0, "no argument: the first player's belt")
    S.was = CW.isOpen()
    keepDown()
end)

-- the inventory key, as a press sends it, still opens and shuts the pair
local function press()
    local key = getCore():getKey("Toggle Inventory")
    pcall(triggerEvent, "OnKeyStartPressed", key)
    pcall(triggerEvent, "OnKeyPressed", key)
end
step(10, function() if CW.isOpen() then CW.toggleBothPaired(0) end end)
step(20, function() press() end)
step(30, function()
    keepDown()
    check(CW.isOpen(), "the inventory key opens ZeD's pair for the first player")
    press()
end)
step(30, function()
    check(not CW.isOpen(), "a second press shuts them")
end)

-- the months
step(5, function()
    local MON = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
    local function lowerFirst(s)
        if not s or s == "" then return false end
        local b1, b2 = s:byte(1), s:byte(2)
        if b1 >= 65 and b1 <= 90 then return false end
        if b1 == 195 and b2 and b2 >= 128 and b2 <= 158 then return false end
        return true
    end
    local words = {}
    for _, fam in ipairs({ "Journal", "MainMenu" }) do
        for _, m in ipairs(MON) do words[#words + 1] = { fam .. m, tostring(ZeD.tr("UI_ZeD_" .. fam .. "_Month" .. m)), fam, m } end
    end
    local missing = {}
    for _, w in ipairs(words) do if w[2] == "UI_ZeD_" .. w[3] .. "_Month" .. w[4] then missing[#missing + 1] = w[1] end end
    check(#missing == 0, "all 24 month words have text in " .. lang .. (#missing > 0 and (" (missing: " .. table.concat(missing, " ") .. ")") or ""))
    local sample = {}
    for i = 1, 12 do sample[#sample + 1] = words[i][2] end
    say("Journal month words in " .. lang .. ": " .. table.concat(sample, " "))
    if lang == "FR" or lang == "HU" then
        local bad = {}
        for _, w in ipairs(words) do if not lowerFirst(w[2]) then bad[#bad + 1] = w[1] .. "=" .. w[2] end end
        check(#bad == 0, lang .. ": the month words are lower case in dates" .. (#bad > 0 and (" (" .. table.concat(bad, " ") .. ")") or ""))
    elseif lang == "EN" then
        local caps = 0
        for i = 1, 12 do if words[i][2] == MON[i] then caps = caps + 1 end end
        check(caps == 12, "English keeps its capitals (" .. caps .. " of 12 equal Jan..Dec)")
    else
        say("note: " .. lang .. " is neither French nor Hungarian: the lower-case rule is checked in a FR or HU run only")
    end
    -- the date stamps built from them (Journal entry stamp, ticket short date): the day and month in the language's own order
    local stamp = tostring(ZeD.tr("UI_ZeD_Journal_EntryStamp", "x1", "x2", "x3"))
    local short = tostring(ZeD.tr("UI_ZeD_Tk_ShortDate", "x1", "x2"))
    say("Journal entry stamp pattern: " .. stamp .. "; ticket short date: " .. short)
    if lang == "FR" then
        check(short == "x2 x1", "French: the ticket short date puts the day first (" .. short .. ")")
    end
end)

step(10, function()
    if S.was and not CW.isOpen() then CW.toggleBothPaired(0) end
    say(pass .. " passed, " .. fail .. " failed")
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
