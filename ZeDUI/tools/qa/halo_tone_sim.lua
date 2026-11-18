-- ZeDUI/tools/qa/halo_tone_sim.lua  (Nov 17 2026, QA: the over-head notes lost their red and green mark)
-- The game raises its red and green notes with HaloTextHelper.addTextWithArrow(p, text, up, getColorRed() /
-- getColorGreen()). The colour is a Java ColorRGB with public fields only; Kahlua does not read a Java object's fields
-- as c.r, so ZeD read no colour and the note came out with no mark. ZeD_HaloText now matches the game's own colour
-- objects, then getters, then fields, and, with no colour read, takes the arrow's way. This runs the real wrappers on
-- a stand-in HaloTextHelper whose colours are opaque objects (no readable fields), as Kahlua sees the Java ones.
-- Run from the repo root: lua51 ZeDUI/tools/qa/halo_tone_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]halo_tone_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

-- an opaque object: userdata, as Kahlua types a Java object, and any read of it is counted and errors, as a missing
-- method or field does there. (Nov 17 2026, QA: every failed read inside a pcall still logs a Java exception in the
-- game and counts in its red error box, so the wrappers must never touch one: PROBES must stay 0.)
local PROBES = 0
local function opaque(name)
    local u = newproxy(true)
    local mt = getmetatable(u)
    mt.__index = function(_, k) PROBES = PROBES + 1; error("no field " .. tostring(k) .. " on " .. name) end
    mt.__tostring = function() return name end
    return u
end
local RED, GREEN, WHITE = opaque("RED"), opaque("GREEN"), opaque("WHITE")
local GAME = {}
HaloTextHelper = {
    getColorRed = function() return RED end, getColorGreen = function() return GREEN end,
    getColorWhite = function() return WHITE end, getBadColor = function() return RED end, getGoodColor = function() return GREEN end,
    addText = function(...) GAME[#GAME + 1] = "addText" end,
    addGoodText = function(...) GAME[#GAME + 1] = "addGoodText" end,
    addBadText = function(...) GAME[#GAME + 1] = "addBadText" end,
    addTextWithArrow = function(...) GAME[#GAME + 1] = "addTextWithArrow" end,
}
local NOTES = {}
ZeD = {
    Settings = { haloBubbleOn = function() return true end },
    Bubbles = { note = function(pn, t, tone) NOTES[#NOTES + 1] = { t = t, tone = tone } end },
    Messages = { halo = function() end },
    tr = function(k) return k end,
}
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_HaloText.lua")
local H = ZeD.HaloText
H.install()
local HT = HaloTextHelper
local P = { isLocalPlayer = function() return true end, getPlayerNum = function() return 0 end }
local function last() return NOTES[#NOTES] end

HT.addTextWithArrow(P, "Too heavy", false, HT.getColorRed())
check("a red note (the game's red colour object): the bad mark", last() and last().t == "Too heavy" and last().tone == "bad", last() and last().tone)
HT.addTextWithArrow(P, "Learned a new recipe", true, HT.getColorGreen())
check("a green note: the good mark", last() and last().tone == "good", last() and last().tone)
HT.addTextWithArrow(P, "Ate", false, HT.getColorWhite())
check("a white note going down: the arrow's way (bad)", last() and last().tone == "bad", last() and last().tone)
HT.addTextWithArrow(P, "Up a little", true, nil)
check("no colour, the arrow up: good", last() and last().tone == "good", last() and last().tone)
HT.addTextWithArrow(P, "Sep form", ",", true, HT.getColorRed())
check("the separator form (player, text, sep, up, colour): the colour still read", last() and last().tone == "bad", last() and last().tone)
HT.addText(P, "Plain", HT.getColorGreen())
check("addText with the green colour object: good", last() and last().tone == "good", last() and last().tone)
HT.addText(P, "Numbers", 200, 30, 30)
check("addText with r, g, b numbers: still read (bad)", last() and last().tone == "bad", last() and last().tone)
HT.addText(P, "White", HT.getColorWhite())
check("addText white: no mark", last() and last().tone == nil, last() and last().tone)
-- the game's XP note: getGoodColor() handing back a NEW object each call, so it never matches by identity
-- (XpUpdate.lua: addTextWithArrow(owner, text, "[br/]", true, HaloTextHelper.getGoodColor()))
local good = HT.getGoodColor
HT.getGoodColor = function() return opaque("FRESH_GREEN") end
HT.addTextWithArrow(P, "Carpentry +5", "[br/]", true, HT.getGoodColor())
check("the XP note (a fresh colour object, arrow up): good from the arrow", last() and last().t == "Carpentry +5" and last().tone == "good", last() and last().tone)
HT.addText(P, "Fresh", HT.getGoodColor())
check("addText with a colour object it cannot match: no mark", last() and last().t == "Fresh" and last().tone == nil, last() and last().tone)
HT.getGoodColor = good
-- a mod passing a plain Lua table: still read
HT.addText(P, "Table", { r = 30, g = 200, b = 40 })
check("addText with a Lua table colour: read (good)", last() and last().tone == "good", last() and last().tone)
HT.addText(P, "Getters", setmetatable({}, { __index = { getR = function() return 0.9 end, getG = function() return 0.1 end, getB = function() return 0.1 end } }))
check("addText with a Lua class colour (getters, 0-1): read (bad)", last() and last().tone == "bad", last() and last().tone)
check("no Java colour was ever read (each read logs an exception in the game)", PROBES == 0, PROBES)
HT.addBadText(P, "Bad")
check("addBadText: bad", last() and last().tone == "bad")
check("ZeD took every line (none to the game)", #GAME == 0, #GAME)

print("halo_tone_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
