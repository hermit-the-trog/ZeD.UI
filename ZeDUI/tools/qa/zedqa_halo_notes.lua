-- ZeDUI/tools/qa/zedqa_halo_notes.lua  (Nov 4 2026, QA; Build's cfd52083, overhead notes in ZeD's bubble + Messages)
-- In game on the QA save, Overhead notes switched on (put back after):
--   1. a real game path: ISReadABook:doHaloText with a skill book far above the character's level ("Too complicated"
--      or a sister line: bad), and a learned-recipe line (good) through the global, as the game's callers do
--   2. both at once while the character is speaking (Say): pictures at 0.3 s, 2.0 s, 2.9 s (fading), 3.6 s (gone)
--   3. the same line three times: one bubble, one Messages card "3 times"
--   4. Messages: the "Over your head" source, newest first, tags, read (no unread count)
--   5. XP: AddXP with the halo flag on (the game's "+n Carpentry"): the game's own line still draws, Messages sums it
--   6. a level up (LevelPerk): logged
--   7. switch off: a bad line draws the game's way again, nothing new in Messages
-- grep "ZEDQA hln". Pictures zqa_hln_<w>x<h>_<n>.png.
local function say(s) print("ZEDQA hln " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_hln_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local pn = p:getPlayerNum()
local M = ZeD.Messages or ZeD_Messages
local B = ZeD.Bubbles or ZeD_Bubbles
local opt = ZeD.Settings.haloBubbleOption
local keep = { opt = opt:getValue() }
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function src() return M and M.sources and M.sources[ZeD.tr("UI_ZeD_Msg_OverHead")] end
local function items() local s = src(); return s and s.items or {} end
local function notes() return B and B._notes and B._notes[pn] or {} end
local function unread() local n = 0; for _, s in pairs(M.sources or {}) do for _, it in ipairs(s.items or {}) do if not it.read then n = n + 1 end end end; return n end

step(30, function()
    say("Messages " .. tostring(M ~= nil) .. ", Bubbles " .. tostring(B ~= nil) .. ", switch was " .. tostring(keep.opt))
    opt:setValue(2)
    keep.unread = unread()
    keep.n0 = #items()
end)
-- 1 + 2: real bad line (book) and a good line, while speaking
step(10, function()
    p:Say(getText("IGUI_PlayerText_Hungry") ~= "IGUI_PlayerText_Hungry" and getText("IGUI_PlayerText_Hungry") or "QA speaking")
    local book = instanceItem("Base.BookCarpentry5")
    local act = ISReadABook:new(p, book)
    act:doHaloText()
    HaloTextHelper.addGoodText(p, getText("IGUI_HaloNote_LearnedRecipe", "Make Plank"), "[br/]")
end)
step(18, function()
    local ns = notes()
    local bad, good = 0, 0
    for _, n in ipairs(ns) do if n.tone == "bad" then bad = bad + 1 elseif n.tone == "good" then good = good + 1 end end
    say("bubble notes now: " .. #ns)
    for i, n in ipairs(ns) do say("  note " .. i .. " [" .. tostring(n.tone) .. "] " .. tostring(n.text)) end
    check(bad == 1 and good == 1, "the book's real line (bad) and a learned recipe (good) are in the bubble")
    shot("1_two_notes_with_speech")
end)
step(100, function() shot("2_at_2s") end)
step(55, function() shot("3_fading") end)
step(45, function()
    shot("4_gone")
    check(#notes() == 0, "the notes are gone after about 3.1 s")
end)
-- 3: the same line three times
step(10, function()
    for _ = 1, 3 do HaloTextHelper.addBadText(p, getText("IGUI_Sleep_NotSafe")) end
end)
step(10, function()
    local same = 0
    for _, n in ipairs(notes()) do if string.upper(tostring(n.text)) == string.upper(getText("IGUI_Sleep_NotSafe")) then same = same + 1 end end
    check(same == 1, "the same line three times is one bubble (" .. same .. ")")
    local top = items()[1]
    check(top and top.text == getText("IGUI_Sleep_NotSafe") and (top.n or 1) == 3, "Messages keeps one card counting 3 (" .. tostring(top and top.n) .. ")")
    shot("5_repeat")
end)
-- 4: Messages
step(10, function()
    local its = items()
    say("Messages 'Over your head': " .. #its .. " cards")
    for i = 1, math.min(#its, 6) do local it = its[i]; say("  card " .. i .. " [" .. tostring(it.tone) .. "] " .. tostring(it.text) .. " x" .. tostring(it.n or 1)) end
    check(#its >= keep.n0 + 3, "Messages logged the lines (" .. #its .. " cards)")
    check(unread() == keep.unread, "they are read: no unread count (" .. unread() .. ")")
    pcall(ZeD.MessagesWindow.open, pn, ZeD.tr("UI_ZeD_Msg_OverHead"))
end)
step(60, function() shot("6_messages") end)
-- 5: XP with the game's halo flag
step(10, function()
    pcall(function() local w = ZeD.MessagesWindow.get(pn); if w then w:close() end end)
    keep.xp0 = #items()
    p:getXp():AddXP(Perks.Woodwork, 12, true, true, false, true)
end)
step(12, function() shot("7_xp_game_line") end)
step(10, function()
    p:getXp():AddXP(Perks.Woodwork, 8, true, true, false, true)
end)
step(30, function()
    local top = items()[1]
    say("after two XP adds, the top card: " .. tostring(top and top.text) .. " sumKey " .. tostring(top and top.sumKey) .. " amount " .. tostring(top and top.amount))
    check(top and top.sumKey ~= nil and math.abs((top.amount or 0) - 20) < 3, "Messages sums the XP on one card (about 20)")
    local inBubble = false
    for _, n in ipairs(notes()) do if string.upper(tostring(n.text)):find(string.upper(getText("IGUI_perks_Carpentry")), 1, true) then inBubble = true end end
    check(not inBubble, "the XP is not also in ZeD's bubble (the game draws its own)")
end)
-- 6: a level up
step(10, function() keep.lv0 = #items(); p:LevelPerk(Perks.Cooking) end)
step(30, function()
    local top = items()[1]
    say("after LevelPerk, the top card: " .. tostring(top and top.text))
    check(#items() > keep.lv0, "a level up is logged in Messages")
    shot("8_level_up")
end)
-- 7: switch off
step(10, function()
    opt:setValue(1)
    keep.off0 = #items()
    HaloTextHelper.addBadText(p, getText("ContextMenu_TooDark"))
end)
step(15, function()
    check(#items() == keep.off0 and #notes() == 0, "switched off: nothing to the bubble or Messages")
    shot("9_off_game_text")
end)
step(30, function()
    opt:setValue(keep.opt or 1)
    pcall(function() p:LoseLevel(Perks.Cooking) end)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then fail = fail + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
