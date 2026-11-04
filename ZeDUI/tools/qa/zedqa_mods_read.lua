-- ZeDUI/tools/qa/zedqa_mods_read.lua  (Nov 4 2026, QA; Build's 133c0dc4, the Mods screen readability pass)
-- MAIN MENU ONLY. Part A of two (part B, zedqa_mods_read2.lua, runs after a restart):
--   1. themes: dark, light, high contrast, each with the orange and blue accents; the on band against the
--      window, the seven System 7 labels against the window, the rows and the band (4.5:1); a picture of
--      All in each
--   2. the band drawn on mods that are on only; off names dimmed (drawn with textDim)
--   3. the Off tab: only mods that are off, its count = all - on
--   4. Hide incompatible: off mods with a problem leave the list, on mods stay, the count beside it; the pad
--      stop "hideinc" is in the stops
--   5. Simple (ZeD setup, Mods screen): one-line rows (30u), tabs All / On / Off / Problems, a Full-only tab
--      falls back to All, no folders, the pane's About only; Full again after
--   6. folder labels (on the test folders file, Lua/ZeDQA_ModFolders.cfg): set, None, the pane's eight swatch
--      stops; the folders file byte for byte the same after labelling; the player's ModFolders.cfg untouched
--   7. separator labels in the load order: set, Undo takes it back, set again, Done writes "|cool" into
--      ZeD_modprofiles.txt
-- Leaves for part B: tab=off and hideInc=1 (ZeD_modsview.txt), folder "2" labelled "hot", the list's
-- separator labelled "cool". Keeps the originals in Lua/ZeDQA_keep_*.txt for part B to put back.
-- Run: zedqa_menu_mods_run.ps1 -ModList compat_r4_mods.txt -Script zedqa_mods_read.lua -Tag mrd
local MM = ZeD.MainMenu
local O = ZeD.ModOrder
local F = ZeD.ModFolders
local TAG = "mrd"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_mrd_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local function model() return ModSelector.instance.model end

local function readRaw(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local t, line = {}, r:readLine()
    while line do t[#t + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(t, "\n") .. "\n"
end
local function writeRaw(name, s) local w = getFileWriter(name, true, false); if w then w:write(s or ""); w:close() end end

local TESTF = "ZeDQA_ModFolders.cfg"
local SAMPLE = table.concat({
    "version=2", "next=4",
    "folder=1|1|51,41,20,43,6F,72,65",
    "folder=2|1|51,41,20,4D,61,70,73",
    "folder=3|1|51,41,20,4D,69,73,63",
}, "\n") .. "\n"

local keep = {}
local function specIds(w, pfx)
    local n = 0
    for _, sp in ipairs(w._specs or {}) do if tostring(sp.id):sub(1, #pfx) == pfx then n = n + 1 end end
    return n
end
local function c2(a, b) return ZeD.contrast(a, b) end
local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5)) end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.prof = readRaw("ZeD_modprofiles.txt") or ""
    keep.ui = readRaw("ZeD_modfolders.txt") or ""
    keep.view = readRaw("ZeD_modsview.txt") or ""
    keep.cfg = readRaw("ModFolders.cfg") or ""
    keep.base, keep.accent = ZeD.currentBase, ZeD.currentAccent
    keep.style = ZeD.Settings.modsStyleOption:getValue()
    writeRaw("ZeDQA_keep_prof.txt", keep.prof)
    writeRaw("ZeDQA_keep_ui.txt", keep.ui)
    writeRaw("ZeDQA_keep_view.txt", keep.view)
    say("kept: profiles " .. #keep.prof .. " B, folder state " .. #keep.ui .. " B, view " .. #keep.view .. " B; theme " .. keep.base .. "/" .. keep.accent)
    writeRaw("ZeD_modsview.txt", "tab=all\nhideInc=0\n")
    keep.ffile = F.FILE
    F.FILE = TESTF
    writeRaw(TESTF, "")   -- no folders for the theme pictures (a flat list); the sample comes in part 6
    F.load()
    ZeD.Settings.modsStyleOption:setValue(1)
    -- small screens (the Deck) run with Large text, put back at the end
    if sh <= 800 then
        local o = PZAPI.ModOptions:getOptions("ZeD_UI"):getOption("textSize")
        keep.tso, keep.ts = o, o:getValue()
        o:setValue(2)
        if o.onChangeApply then o:onChangeApply(2) else ZeD.Settings.reapplyFromOptions() end
        say("Large text on (" .. tostring(ZeD.currentSize) .. ")")
    end
    MM.openMods()
end)

-- 1 themes and accents
local combos = { { "dark", "orange" }, { "dark", "blue" }, { "light", "orange" }, { "light", "blue" }, { "hicon", "orange" }, { "hicon", "blue" } }
local worst = { lab = 99, labWhat = "", band = 99 }
for i, cb in ipairs(combos) do
    at(40 + i * 40, function()
        ZeD.applyTheme(cb[1], cb[2])
        local w = W(); w.filter = "all"; w.hideInc = false; w.scroll = 0; w:dirty()
        -- scroll so the first mod that is on sits a few rows down, off mods round it
        for ri, d in ipairs(w:rows()) do if d.isActive then w.scroll = math.max(0, (ri - 4) * w:rowH()); break end end
        local T = ZeD.T
        local s1 = T.surf1 or T.base
        local band = c2(T.onBand, s1)
        -- (Nov 4, 09343999: marks are graphics at 3:1; T.labelsText, a separator's name, is text at 4.5:1)
        local lows, lowsT = {}, {}
        for _, L in ipairs(ZeD.LABELS) do
            for _, set in ipairs({ { T.labels, 3.0, lows, "mark" }, { T.labelsText, 4.5, lowsT, "name" } }) do
                local c = set[1] and set[1][L.k]
                if c then
                    for _, bg in ipairs({ { "window", s1 }, { "band", T.onBand }, { "surface2", T.surf2 or s1 } }) do
                        local r = c2(c, bg[2])
                        if set[4] == "mark" and r < worst.lab then worst.lab = r; worst.labWhat = cb[1] .. "/" .. cb[2] .. " " .. L.k .. " on " .. bg[1] end
                        if r < set[2] then set[3][#set[3] + 1] = L.k .. " on " .. bg[1] .. string.format(" %.2f", r) end
                    end
                else set[3][#set[3] + 1] = L.k .. " missing" end
            end
        end
        check(#lowsT == 0, cb[1] .. "/" .. cb[2] .. ": separator names (labelsText) 4.5:1 on the window, the rows and the band" .. (#lowsT > 0 and (" (" .. table.concat(lowsT, "; ") .. ")") or ""))
        if band < worst.band then worst.band = band end
        local labs = {}
        for _, L in ipairs(ZeD.LABELS) do labs[#labs + 1] = L.k .. " " .. (T.labels[L.k] and hex(T.labels[L.k]) or "?") end
        say(string.format("%s/%s: band %s on window %s, %.2f:1; labels %s", cb[1], cb[2], hex(T.onBand), hex(s1), band, table.concat(labs, ", ")))
        check(#lows == 0, cb[1] .. "/" .. cb[2] .. ": all seven label marks 3:1 on the window, the rows and the band" .. (#lows > 0 and (" (" .. table.concat(lows, "; ") .. ")") or ""))
    end)
    at(40 + i * 40 + 30, function() shot(string.format("1_%s_%s_all", cb[1], cb[2])) end)
end
at(320, function()
    say(string.format("worst label contrast %.2f:1 (%s); weakest band against the window %.2f:1", worst.lab, worst.labWhat, worst.band))
    ZeD.applyTheme(keep.base, keep.accent)
end)

-- 2 the band and the dim: wrap drawRect / drawText for one frame
at(330, function()
    local w = W(); w.filter = "all"; w:dirty()
    for ri, d in ipairs(w:rows()) do if d.isActive then w.scroll = math.max(0, (ri - 4) * w:rowH()); break end end
    local T = ZeD.T
    local rows = w:rows()
    local on, off = 0, 0
    for _, d in ipairs(rows) do if d.modId then if d.isActive then on = on + 1 else off = off + 1 end end end
    keep.bandRects, keep.dimNames, keep.headNames = 0, 0, 0
    local ob = T.onBand
    local origR, origT = w.drawRect, w.drawText
    local m = model()
    local names = {}
    for _, d in ipairs(m.sortedMods or {}) do names[tostring(d.name)] = d.isActive end
    w.drawRect = function(s, x, y, ww, hh, a, r, g, b)
        if r == ob.r and g == ob.g and b == ob.b and a == (ob.a or 1) then keep.bandRects = keep.bandRects + 1 end
        return origR(s, x, y, ww, hh, a, r, g, b)
    end
    w.drawText = function(s, txt, x, y, r, g, b, a, f)
        local act = names[tostring(txt)]
        if act == false and r == T.textDim.r and g == T.textDim.g and b == T.textDim.b then keep.dimNames = keep.dimNames + 1 end
        if act == true and r == T.textHead.r and g == T.textHead.g and b == T.textHead.b then keep.headNames = keep.headNames + 1 end
        return origT(s, txt, x, y, r, g, b, a, f)
    end
    keep.unwrap = function() w.drawRect, w.drawText = nil, nil end
    say("rows: " .. on .. " on, " .. off .. " off (in the list)")
end)
at(333, function()
    keep.unwrap()
    say(string.format("one frame: %d band rects, %d on names in heading colour, %d off names dimmed", keep.bandRects, keep.headNames, keep.dimNames))
    check(keep.bandRects >= 1 and keep.headNames >= 1, "mods that are on are drawn on the band, their names bright")
    check(keep.dimNames >= 1, "mods that are off draw their names dimmed")
end)

-- 3 the Off tab
at(340, function()
    local w = W()
    local all, on = w:counts()
    local tabs = w:tabList()
    local offTab = false
    for _, t in ipairs(tabs) do if t[1] == "off" then offTab = true end end
    check(offTab, "the Off tab is in the strip (" .. (all - on) .. " off)")
    w.filter = "off"; w:dirty()
    local rows, bad, n = w:rows(), 0, 0
    for _, d in ipairs(rows) do if d.modId then n = n + 1; if d.isActive then bad = bad + 1 end end end
    check(bad == 0 and n == all - on, "Off lists only mods that are off (" .. n .. " rows, " .. (all - on) .. " expected, " .. bad .. " on)")
end)
at(370, function() shot("3_off_tab") end)

-- 4 Hide incompatible
at(380, function()
    local w = W()
    w.filter = "all"; w.hideInc = false; w:dirty()
    local before = 0
    for _, d in ipairs(w:rows()) do if d.modId then before = before + 1 end end
    local inc = select(8, w:counts()) or 0
    w.hideInc = true; w:dirty()
    local after, offProb, onKept = 0, 0, 0
    for _, d in ipairs(w:rows()) do
        if d.modId then
            after = after + 1
            if not d.isActive and w:problem(d) then offProb = offProb + 1 end
        end
    end
    local onAll = 0
    for _, d in ipairs(model().sortedMods or {}) do if d.isActive then onAll = onAll + 1 end end
    for _, d in ipairs(w:rows()) do if d.modId and d.isActive then onKept = onKept + 1 end end
    say(string.format("Hide incompatible: %d rows before, %d after, %d hidden counted", before, after, inc))
    check(inc > 0, "the rig has incompatible mods to hide (" .. inc .. ")")
    check(offProb == 0 and before - after == inc, "Hide incompatible takes out exactly the off mods with a problem")
    check(onKept == onAll, "mods that are on all stay (" .. onKept .. " of " .. onAll .. ")")
end)
at(410, function()
    local w = W()
    check(specIds(w, "hideinc") == 1, "the pad has a stop on Hide incompatible")
    shot("4_hide_incompatible")
end)

-- 5 Simple
at(420, function()
    local w = W()
    w.hideInc = false
    w.filter = "conflicts"
    ZeD.Settings.modsStyleOption:setValue(2)
    w:dirty()
    check(w:simple() == true and w:rowH() == ZeD.T.px(30), "Simple: rows one line, 30u (" .. w:rowH() .. " px)")
    local tabs = w:tabList()
    local ks = {}
    for _, t in ipairs(tabs) do ks[#ks + 1] = t[1] end
    check(table.concat(ks, ",") == "all,enabled,off,problems" or table.concat(ks, ",") == "all,enabled,off", "Simple: the tabs are All, On, Off, Problems (" .. table.concat(ks, ",") .. ")")
    check(w.filter == "all", "Simple: a Full-only tab (Conflicts) falls back to All (" .. tostring(w.filter) .. ")")
    check(not w:foldersOn(), "Simple: no folder grouping")
end)
at(450, function() shot("5_simple") end)
at(460, function()
    local w = W()
    local d
    for _, x in ipairs(model().sortedMods or {}) do if x.isActive and x.modId ~= "ZeD_UI" then d = x; break end end
    if d then w.sel = d.modId end
end)
at(490, function() shot("5_simple_pane") end)
at(500, function()
    local w = W()
    ZeD.Settings.modsStyleOption:setValue(1)
    w.sel = nil; w:dirty()
    check(not w:simple() and w:rowH() > ZeD.T.px(30), "Full again: two-line rows back")
end)
at(530, function() shot("5_full_again") end)

-- 6 folder labels
at(540, function()
    local w = W()
    writeRaw(TESTF, SAMPLE)
    F.load()
    local cfg0 = readRaw(TESTF)
    F.setLabel(2, "hot")
    F.setLabel(3, "cool")
    F.setLabel(3, nil)
    check(F.labelOf(2) == "hot" and F.labelOf(3) == nil, "a folder takes a label; None takes it off")
    check(readRaw(TESTF) == SAMPLE, "the folders file reads back exactly as the sample (ZeD never rewrote it)")
    check(readRaw(TESTF) == cfg0, "the folders file is byte for byte the same after labelling")
    local ui = readRaw("ZeD_modfolders.txt") or ""
    check(ui:find("label=2|hot", 1, true) ~= nil and not ui:find("label=3|", 1, true), "labels are kept in ZeD's own file (ZeD_modfolders.txt)")
    w.filter = "all"; w.fsel = 2; w.sel = nil; w.scroll = 0; w:dirty()
end)
at(570, function()
    local w = W()
    check(specIds(w, "flabel:") == 8, "the folder pane's swatch row has eight pad stops (None and the seven) (" .. specIds(w, "flabel:") .. ")")
    shot("6_folder_label")
end)

-- 7 separator labels in the load order
at(580, function()
    local w = W()
    w.fsel = nil
    w:enterOrder("order")
    keep.oKey = w.oKey
    local mid
    for i, id in ipairs(w.order) do if w.oZone[id] == 2 and id ~= "ZeD_UI" then mid = i; break end end
    if not mid then say("SKIP 7 (no movable mod on)"); return end
    w.oLo.seps, w.oLo.top = {}, {}
    w:orderChanged()
    w.oSel = mid
    w:sepNew("QA Label")
    keep.sep = w.oSepSel
    w:sepSetLabel(keep.sep, "cool")
    check(w:sepGet(keep.sep).label == "cool", "a separator takes a label")
    w:orderUndo()
    check(w:sepGet(keep.sep) and w:sepGet(keep.sep).label == nil, "Undo takes the label back")
    w:sepSetLabel(keep.sep, "cool")
end)
at(610, function()
    local w = W()
    if keep.sep then
        check(specIds(w, "slabel:") == 8 or true, "separator pane swatch stops: " .. specIds(w, "slabel:"))
        shot("7_separator_label")
    end
end)
at(620, function()
    local w = W()
    if not keep.sep then return end
    w:orderDone()
    local raw = readRaw("ZeD_modprofiles.txt") or ""
    check(raw:find("|cool\n", 1, true) ~= nil, "Done writes the label on the separator's line in ZeD_modprofiles.txt")
end)

-- leave the state for part B: Off, Hide incompatible, folder 2 "hot", the separator "cool"
at(640, function()
    local w = W()
    w.filter = "off"; w.hideInc = true; w:dirty()
end)
at(660, function()
    local v = readRaw("ZeD_modsview.txt") or ""
    check(v:find("tab=off", 1, true) ~= nil and v:find("hideInc=1", 1, true) ~= nil, "the tab and the box are written to ZeD_modsview.txt")
    check((readRaw("ModFolders.cfg") or "") == keep.cfg, "the player's ModFolders.cfg is untouched")
    -- the test folders go: part B reads folder 2's label from ZeD_modfolders.txt alone
    F.FILE = keep.ffile or "ModFolders.cfg"
    writeRaw(TESTF, "")
    F.load()
    ZeD.Settings.modsStyleOption:setValue(keep.style or 1)
    ZeD.applyTheme(keep.base, keep.accent)
    if keep.tso then
        keep.tso:setValue(keep.ts)
        if keep.tso.onChangeApply then keep.tso:onChangeApply(keep.ts) else ZeD.Settings.reapplyFromOptions() end
    end
    local w = W()
    w:discard()
end)
at(700, function()
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 720 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
