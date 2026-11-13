-- ZeDUI/tools/qa/zedqa_158_balloon.lua  (Nov 12 2026, bug 158: Chinese letters missing from the speech balloon)
-- QA's Mac, in Simplified Chinese: U+641C U+522E U+72B6 U+6001 ("scavenge status") drew as its first two letters.
-- The game's Chinese face, which stands in for ZeD's under Chinese, is a traditional set with no simplified-only
-- letters; the fix draws such a line in ZeD's Noto Sans SC (Cred1, kept loaded by ZeD's CN font list).
--
-- RUN IT TWICE: with the game in Simplified Chinese (options.ini language=CN, put back to EN after), then in English.
-- The text is made the way the game makes it, never from a .lua literal and never from UTF-8 bytes (the PC probe's
-- string.char of the twelve UTF-8 bytes is twelve Latin-1 characters, which drew as mojibake whatever the font):
--   line   in Chinese, getText("UI_ZeD_Char_TabLoot") .. getText("IGUI_invpanel_Condition") (the four letters); in
--          other languages the same four from their code points, string.char(0x641C, ...), the same Java string
--          (checked in Chinese: the two are equal)
--   item   in Chinese, the bandage's own item name (U+7EF7 U+5E26, both letters simplified-only: the old code drew it
--          as nothing); in other languages from its code points
-- For each: its characters' codes; the face the balloon draws it in and whether that face has every letter; the same
-- for the five role fonts (item names, notes, the guide window draw through those) with ZeD.TM's width against the
-- drawing face's. Then the player says it, and for a few frames every draw the balloon layer makes of it is written
-- down (ZeD_ActionBarLayer.drawTextZoomed wrapped, put back after): the face, its zoom, the letters it has.
-- Expect PASS throughout in both languages. Shots: zqa_158_<line|item>_<language>.png.
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA b158"; ends "ZEDQA b158 DONE".
local TAG = "b158"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local X, B = ZeD.Text, ZeD.Bubbles
if not (X and B and X.faceFor and ZeD.Font and ZeD.T) then say("ERR ZeD text or bubbles not loaded (or the fix not installed)"); say("DONE"); return end
local pn = p:getPlayerNum()
local fails = 0
local function check(label, ok, detail)
    if not ok then fails = fails + 1 end
    say((ok and "PASS " or "FAIL ") .. label .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end

local LANG = "?"
pcall(function() LANG = tostring(Translator.getLanguage():name()) end)

local HEX = "0123456789ABCDEF"
local function hex4(n)
    local s = ""
    for _ = 1, 4 do
        local d = n % 16
        s = string.sub(HEX, d + 1, d + 1) .. s
        n = math.floor(n / 16)
    end
    return s
end
local function codes(s)
    local t = {}
    for i = 1, #s do t[#t + 1] = hex4(string.byte(s, i)) end
    return #s .. " characters: " .. table.concat(t, " ")
end
local SLOTS = { "Cred1", "DebugConsole", "Small", "Medium", "Large", "Title", "MainMenu1", "MainMenu2", "Massive", "Cred2",
    "NewSmall", "NewMedium", "NewLarge", "Dialogue" }
local function slotName(f)
    for _, n in ipairs(SLOTS) do if UIFont[n] == f then return n end end
    return tostring(f)
end
local tm = X.realTM()
-- how many of the string's letters the font draws, and the codes of those it lacks
local function letters(font, s)
    local have, n, lack = 0, 0, {}
    for i = 1, #s do
        local ch = string.sub(s, i, i)
        if ch ~= " " then
            n = n + 1
            if tm:MeasureStringX(font, ch) > 0 then have = have + 1 else lack[#lack + 1] = hex4(string.byte(ch)) end
        end
    end
    return have, n, lack
end
local function lettersNote(font, s)
    local have, n, lack = letters(font, s)
    return slotName(font) .. ", " .. have .. " of " .. n .. " letters" .. ((#lack > 0) and (", lacks " .. table.concat(lack, " ")) or "")
end

-- the two strings ----------------------------------------------------------------------------------------------------
local LINE_CP = string.char(0x641C, 0x522E, 0x72B6, 0x6001)
local ITEM_CP = string.char(0x7EF7, 0x5E26)
local LINES = {}
if LANG == "CN" then
    local line = getText("UI_ZeD_Char_TabLoot") .. getText("IGUI_invpanel_Condition")
    LINES[1] = { tag = "line", s = line, how = "getText(UI_ZeD_Char_TabLoot) .. getText(IGUI_invpanel_Condition)" }
    local nm = nil
    pcall(function() nm = getScriptManager():getItem("Base.Bandage"):getDisplayName() end)
    if type(nm) ~= "string" then pcall(function() nm = getItemNameFromFullType("Base.Bandage") end) end
    if type(nm) == "string" then LINES[2] = { tag = "item", s = nm, how = "Base.Bandage's item name" }
    else LINES[2] = { tag = "item", s = ITEM_CP, how = "code points (the bandage's name was not found)" } end
else
    LINES[1] = { tag = "line", s = LINE_CP, how = "code points (the game is in " .. LANG .. ", not Chinese)" }
    LINES[2] = { tag = "item", s = ITEM_CP, how = "code points" }
end

local function checks()
    say("language " .. LANG .. "; the game's own faces stand in for ZeD's: " .. tostring(X.fallback))
    check("Cred1 holds Noto Sans SC (it draws U+56FE)", tm:MeasureStringX(UIFont.Cred1, string.char(0x56FE)) > 0)
    X.scriptFont("")
    local SF = X._scriptFonts
    local names = {}
    for i = 1, #SF.fonts do names[#names + 1] = slotName(SF.fonts[i].font) end
    say("script faces: " .. table.concat(names, ", ") .. "; tested against " .. slotName(SF.zedFont))
    check("the script faces include Noto Sans SC on Cred1", names[1] == "Cred1", table.concat(names, ", "))
    say("the PC probe's form, string.char of the UTF-8 bytes, is " .. codes(string.char(0xE6, 0x90, 0x9C, 0xE5, 0x88, 0xAE, 0xE7, 0x8A, 0xB6, 0xE6, 0x80, 0x81)))
    for _, L in ipairs(LINES) do
        local s = L.s
        say(L.tag .. ": " .. L.how .. ": " .. codes(s))
        if LANG == "CN" then
            local want = (L.tag == "line") and LINE_CP or ITEM_CP
            check(L.tag .. ": the game's text is the same Java string as the code points", s == want, codes(s))
        end
        -- the balloon's face (ZeD_Bubbles draws through ZeD.Font.sdf.stat at its own zoom)
        local stat = ZeD.Font.sdf.stat
        local bf = X.faceFor(stat, s, 11 / (stat.face or 64))
        local _, _, lack = letters(bf, s)
        check(L.tag .. ": the balloon draws it in a face with every letter", #lack == 0, lettersNote(bf, s))
        local T = ZeD.T
        for i = 1, 5 do
            local f = T["fontF" .. i]
            local df, dz = X.faceFor(f, s, X.zoomOf(f))
            local _, _, l2 = letters(df, s)
            check(L.tag .. ": F" .. i .. " (" .. slotName(f) .. ") draws it in a face with every letter", #l2 == 0, lettersNote(df, s))
            local tw, dw = ZeD.TM:MeasureStringX(f, s), tm:MeasureStringX(df, s) * dz
            check(L.tag .. ": F" .. i .. " measures what it draws", math.abs(tw - dw) < 0.5, string.format("%.1f vs %.1f", tw, dw))
        end
    end
end

-- what the balloon layer draws ---------------------------------------------------------------------------------------
local watch, got = {}, {}
local Lyr = ZeD_ActionBarLayer
local own = Lyr and rawget(Lyr, "drawTextZoomed")
local base = Lyr and Lyr.drawTextZoomed
if Lyr and base then
    Lyr.drawTextZoomed = function(self, str, x, y, zoom, r, g, b, a, font)
        if watch[str] and #got < 40 then got[#got + 1] = { str = str, font = font, zoom = zoom } end
        return base(self, str, x, y, zoom, r, g, b, a, font)
    end
end
local function unwrap() if Lyr and base then Lyr.drawTextZoomed = own end end

-- a plain panel (a vanilla class: the patched ISUIElement draws) with the line in each role font, left and right
-- aligned, for the shots: every row should show all its letters, the right-aligned copy ending at the panel's edge
local panel = nil
local function showPanel(s)
    local sc = (ZeD.T and ZeD.T.scale) or 1
    panel = ISPanel:new(80, 80, math.floor(360 * sc), math.floor(160 * sc))
    panel:initialise()
    panel.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 }
    panel.render = function(self)
        local T = ZeD.T
        local y = 6 * sc
        for i = 1, 5 do
            local f = T["fontF" .. i]
            self:drawText("F" .. i, 6 * sc, y, 0.6, 0.6, 0.6, 1, f)
            self:drawText(s, 40 * sc, y, 1, 1, 1, 1, f)
            self:drawTextRight(s, self.width - 6 * sc, y, 1, 1, 1, 1, f)
            y = y + ZeD.TM:getFontHeight(f) + 4 * sc
        end
    end
    panel:addToUIManager()
end

local function sayIt(L)
    watch = { [L.s] = true }
    got = {}
    p:Say(L.s)
end
local function readBack(L)
    local s = L.s
    local sp = B._sp[pn]
    check(L.tag .. ": the balloon holds the text", sp ~= nil and sp.text == s, sp and codes(sp.text) or "no balloon")
    if sp then
        check(L.tag .. ": one line, the whole text", #sp.lines == 1 and sp.lines[1] == s, #sp.lines .. " lines")
    end
    local n = 0
    local seen = {}
    for _, d in ipairs(got) do
        if d.str == s then
            n = n + 1
            local key = slotName(d.font) .. string.format(" %.3f", d.zoom or 0)
            if not seen[key] then
                seen[key] = true
                local _, _, lack = letters(d.font, s)
                check(L.tag .. ": drawn in a face with every letter", #lack == 0,
                    lettersNote(d.font, s) .. string.format(", zoom %.3f", d.zoom or 0))
            end
        end
    end
    check(L.tag .. ": the balloon layer drew it", n > 0, n .. " draws")
    pcall(function() getCore():TakeFullScreenshot("zqa_158_" .. L.tag .. "_" .. LANG .. ".png") end)
    say("shot zqa_158_" .. L.tag .. "_" .. LANG .. ".png")
end

local tick = 0
local function t()
    tick = tick + 1
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if tick == 5 then
        local ok, err = pcall(checks)
        if not ok then fails = fails + 1; say("FAIL checks threw: " .. tostring(err)) end
        local okP, errP = pcall(showPanel, LINES[1].s)
        if not okP then say("ERR panel: " .. tostring(errP)) end
        sayIt(LINES[1])
    elseif tick == 40 or tick == 105 then
        local L = (tick == 40) and LINES[1] or LINES[2]
        local ok, err = pcall(readBack, L)
        if not ok then fails = fails + 1; say("FAIL " .. L.tag .. ": read-back threw: " .. tostring(err)) end
    elseif tick == 70 then
        sayIt(LINES[2])
    elseif tick >= 115 then
        unwrap()
        if panel then pcall(function() panel:removeFromUIManager() end) end
        Events.OnTick.Remove(t)
        say("total " .. (fails == 0 and "all passed" or (fails .. " failed")))
        say("DONE")
    end
end
Events.OnTick.Add(t)
