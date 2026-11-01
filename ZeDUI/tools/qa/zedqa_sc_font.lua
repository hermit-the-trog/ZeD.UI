-- ZeDUI/tools/qa/zedqa_sc_font.lua  (Nov 1 2026, punch list 37: simplified Chinese font, director Nov 1)
-- ZeD's simplified Chinese face (Noto Sans SC, 42/media/fonts/sdf/notoSC.fnt on Cred1, ZeD.Text.scriptFont in
-- shared/ZeD/Scale.lua). Checks, in game with an English-family language (EN / PL / RU lists):
--   1. Cred1 holds ZeD's face: it measures U+56FE (the second letter of "map", missing from the game's
--      traditional face) wider than 0;
--   2. "map" (U+5730 U+56FE) and "simplified Chinese" (U+7B80 U+4F53 U+4E2D U+6587) pick ZeD's face (em 32),
--      measure wider than 0 through ZeD.Text.width and ZeD.TM:MeasureStringX, and the two-letter word measures
--      about twice its first letter (the second letter is not blank);
--   3. "Cafe" with e-acute stays on Fira (no swap) and measures wider than 0;
--   4. for each string, the string with a count after it ("(2)") measures wider than the string alone by at least
--      half the count's own width, so the count lands after the name (in a swapped string the count draws in ZeD's face too);
--   5. a kana string still picks the game's Japanese face (DebugConsole), not ZeD's;
--   6. the three strings drawn through ZeD.Text.draw in a panel at the run's scale: shot zqa_scf_draw.png.
-- Takes its panel away. Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA scf"; ends "ZEDQA scf DONE".
local X = ZeD.Text
local function say(s) print("ZEDQA scf " .. tostring(s)) end
local fails = 0
local function check(label, ok, detail)
    if not ok then fails = fails + 1 end
    say((ok and "PASS " or "FAIL ") .. label .. (detail and (" (" .. tostring(detail) .. ")") or ""))
end
local MAP = string.char(0x5730, 0x56FE)
local SC = string.char(0x7B80, 0x4F53, 0x4E2D, 0x6587)
local CAFE = "Caf" .. string.char(0xE9)
local KANA = string.char(0x3072, 0x3089, 0x304C, 0x306A)
local STRS = { { "map", MAP }, { "simplified", SC }, { "cafe", CAFE } }
local body = ZeD.Font.sdf.body
local function zoom() return body.px * ((ZeD.T and ZeD.T.scale) or 1) / (body.face or 64) end

local function checks()
    local tm = X.realTM()
    local z = zoom()
    say("zoom " .. string.format("%.3f", z) .. " fallback " .. tostring(X.fallback))
    check("1 Cred1 draws U+56FE", tm:MeasureStringX(UIFont.Cred1, string.char(0x56FE)) > 0,
        tm:MeasureStringX(UIFont.Cred1, string.char(0x56FE)))
    for _, s in ipairs(STRS) do
        local name, str = s[1], s[2]
        local e = X.scriptFont(str)
        local w = X.width(body, str, z)
        local wc = X.width(body, str .. "(2)", z)
        local wn = X.width(body, "(2)", z)
        local wt = ZeD.TM:MeasureStringX(ZeD.T.fontF2, str)
        if name == "cafe" then
            check("3 " .. name .. " stays on Fira", e == false, tostring(e))
        else
            check("2 " .. name .. " picks ZeD's face", e and e.em == 32, e and e.em)
        end
        check("2/3 " .. name .. " width", w > 0, string.format("%.1f", w))
        check("2/3 " .. name .. " role measure", wt > 0, string.format("%.1f", wt))
        check("4 " .. name .. " count after name", wc > w + wn * 0.5,
            string.format("%.1f vs %.1f + %.1f", wc, w, wn))
    end
    local w1 = X.width(body, string.char(0x5730), z)
    local w2 = X.width(body, MAP, z)
    check("2 map letter two not blank", w1 > 0 and w2 > w1 * 1.8, string.format("%.1f / %.1f", w2, w1))
    local ek = X.scriptFont(KANA)
    check("5 kana on the game's Japanese face", ek and ek.em ~= 32 and ek.font == UIFont.DebugConsole,
        ek and ek.em)
end

local panel
local tick = 0
local function t()
    tick = tick + 1
    if tick == 5 then
        local ok, err = pcall(checks)
        if not ok then fails = fails + 1; say("FAIL checks threw: " .. tostring(err)) end
        local sc = (ZeD.T and ZeD.T.scale) or 1
        panel = ISPanel:new(100, 100, math.floor(420 * sc), math.floor(140 * sc))
        panel:initialise()
        panel.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 1 }
        panel.render = function(self)
            local z = zoom()
            local y = 10 * sc
            for _, s in ipairs(STRS) do
                local w = X.draw(self, body, s[2] .. "(2)", 10 * sc, y, z, 1, 1, 1, 1)
                self:drawRect(10 * sc, y + 36 * sc, w, 1, 1, 1, 0.3, 0.3)
                y = y + 40 * sc
            end
        end
        panel:addToUIManager()
    elseif tick == 40 then
        pcall(function() getCore():TakeFullScreenshot("zqa_scf_draw.png") end)
    elseif tick == 50 then
        if panel then panel:removeFromUIManager() end
        Events.OnTick.Remove(t)
        say("total " .. (fails == 0 and "all passed" or (fails .. " failed")))
        say("DONE")
    end
end
Events.OnTick.Add(t)
