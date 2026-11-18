-- ZeDUI/tools/qa/gallery_v1_b_setup.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's picture 05 "Before you install":
-- ZeD setup only (the Options window's first page, opened as the Select wheel's Setup slice opens it,
-- ZeD.DpadWheels H.openSetup: the pause screen, then the window). Needs gallery_v1_b_lib.lua first.
--   g1_05_setup_top         the page from the top (the first groups' switches)
--   g1_05_setup_multislot   scrolled to the Multi-slot inventory group (ZeD Multi-Slot's own switches on ZeD setup,
--                           after Windows). Only with ZeD Multi-Slot loaded: gallery_v1_b_setup.txt runs the save with
--                           it (zedqa_mods_run.ps1 -ModList gallery_v1_b_setup_mods.txt -ZeDFirst). Without it: not taken.
--   g1_05_setup_trouble     scrolled to Troubleshooting: the switches that turn ZeD's parts off (safe mode, the
--                           windows, the belt ...)
-- Every header on the page is logged with its place, and the window's box, so Design can see what is in each view.
-- Puts back: the window shut, the pause screen shut, the scroll at the top. grep "ZEDQA g1bs".
local S = GV1 and GV1.new("g1bs")
if not S then print("ZEDQA g1bs ERR run gallery_v1_b_lib.lua first"); print("ZEDQA g1bs DONE"); return end
S.L = GV1
S.MM = ZeD.MainMenu
function S.win() return S.MM and (S.MM.pauseOpts or (S.MM.root and S.MM.root.optsWin)) end
function S.menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
-- the setup page's headers: { text, y } down the page
function S.heads(w)
    local out, y = {}, 0
    local pg = w:pages()[w.pageIdx]
    for _, r in ipairs(w:rowsFor(pg)) do
        if r.kind == "header" then out[#out + 1] = { t = tostring(r.text), y = y } end
        y = y + (r._h or ZeD.T.px(30))
    end
    return out, y
end
function S.scrollTo(w, key, name)
    local want = string.lower(ZeD.tr(key))
    local hs = S.heads(w)
    for _, h in ipairs(hs) do
        if string.lower(h.t) == want then
            w.scroll = math.max(0, h.y - ZeD.T.px(6))
            S.say(name .. ": the " .. h.t .. " header at " .. h.y .. ", scroll " .. w.scroll)
            return true
        end
    end
    return false
end

S.step(10, function()
    S.L.keepCheats(S)
    S.L.cheats(S); S.L.console()
    local groups = {}
    for _, g in ipairs((ZeD.Options and ZeD.Options.groups) or {}) do groups[#groups + 1] = tostring(g.owner) .. ":" .. tostring(g.title) end
    S.say("add-on groups on ZeD setup: " .. ((#groups > 0) and table.concat(groups, ", ") or "none"))
    local ms = false
    pcall(function() ms = getActivatedMods():contains("ZeDMultiSlot") end)
    S.say("ZeD Multi-Slot loaded: " .. tostring(ms))
    local D = ZeD.DpadWheels
    if D and D.H and D.H.openSetup then D.H.openSetup(S.p, S.pn) else pcall(S.MM.openOptions) end
end)
S.step(60, function()
    local w = S.win()
    if not (w and w:isVisible()) then S.say("ERR no ZeD setup window"); return end
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    w.scroll = 0
    S.ok = true
end)
S.step(40, function()   -- (rendered once: the rows know their heights)
    local w = S.win()
    if not S.ok then S.L.notTaken(S, "g1_05_setup_top", "no ZeD setup window"); return end
    local hs, total = S.heads(w)
    local t = {}
    for _, h in ipairs(hs) do t[#t + 1] = h.t .. " @" .. h.y end
    S.say("headers (page " .. total .. " tall, window " .. math.floor(w:getHeight()) .. " tall): " .. table.concat(t, " | "))
    w.scroll = 0
    if GAL_UNLOAD and GAL_UNLOAD.park then GAL_UNLOAD.park() end
end)
S.step(30, function() if S.ok then S.L.shot(S, "g1_05_setup_top") end end)
S.step(10, function()
    if not S.ok then return end
    S.ms = S.scrollTo(S.win(), "UI_ZMS_Options_Group", "multi-slot")
    if not S.ms then S.L.notTaken(S, "g1_05_setup_multislot", "no Multi-slot inventory group on ZeD setup (ZeD Multi-Slot not loaded)") end
end)
S.step(40, function() if S.ms then S.L.shot(S, "g1_05_setup_multislot") end end)
S.step(10, function()
    if not S.ok then return end
    S.tr = S.scrollTo(S.win(), "UI_ZeD_Options_ZedTrouble", "trouble")
    if not S.tr then S.L.notTaken(S, "g1_05_setup_trouble", "no Troubleshooting group found") end
end)
S.step(40, function() if S.tr then S.L.shot(S, "g1_05_setup_trouble") end end)

S.step(10, function()
    local w = S.win()
    if w then w.scroll = 0; pcall(function() w:close() end) end
end)
S.step(20, function()
    if S.menuUp() then pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
end)
S.step(20, function()
    S.L.putCheats(S)
    S.L.summary(S)
    S.say("put back: setup shut at the top, the pause screen shut (" .. tostring(not S.menuUp()) .. ")")
    S.L.done(S)
end)
S.L.run(S)
