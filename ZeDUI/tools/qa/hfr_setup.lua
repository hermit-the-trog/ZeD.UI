-- ZeDUI/tools/qa/hfr_setup.lua  (Nov 20 2026, QA; tag mset): MAIN MENU ONLY, pushed through the QA bridge by
-- zedqa_menu_mods_run.ps1 (hotfix_report_run.ps1 -Part setup). The beta 21 hotfix report, CUTS C (git 9b1311da2):
-- Options > ZeD setup, walked a screen at a time in Full and in Lite, 4K at 1.75x, the pointer hidden:
--   C_setup_full_1 .. _n, C_setup_lite_1 .. _n (a screen is the list's height less 120 units; it stops where the page ends)
-- Nothing is applied or saved: Options is left with Back (changes none). What it puts back: every ZeD option as found,
-- the look, ModOptions.ini line for line. grep "ZEDQA mset".
-- every ZeD option as found, the look on screen, ModOptions.ini line for line. grep "ZEDQA mset".
local MM = ZeD.MainMenu
local St = ZeD.Settings
local function say(s) print("ZEDQA mset " .. tostring(s)) end
local pass, fail, tick = 0, 0, 0
local steps = {}
local OFF = 80   -- (the desk's screen fades in at boot: every step after the first waits for it)
local T0 = 0
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = (T0 > 2) and (T0 + OFF) or T0, fn = fn } end
local keep = {}
local K = {}

function K.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function K.val(id)
    local zo = K.opts()
    local o = zo and zo.dict and zo.dict[id]
    local v = nil
    pcall(function() v = o:getValue() end)
    return v
end
function K.readIni()
    local t = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function K.writeIni(lines)
    if not lines then return end
    pcall(function()
        local w = getFileWriter("ModOptions.ini", true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end)
end
function K.style(i)
    local o = St.lookStyleOption
    pcall(function() o:setValue(i) end)
    if o.onChange then pcall(o.onChange, o, i) end
end
function K.shot(name, keepMouse)
    pcall(function() if not keepMouse then Mouse.setXY(4, 4) end; Mouse.setCursorVisible(false) end)
    local ok, e = pcall(function() getCore():TakeFullScreenshot("hfr_" .. name .. ".png") end)
    if ok then pass = pass + 1; say("shot hfr_" .. name) else fail = fail + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
function K.W() return MM.root and MM.root.modsWin end
function K.rows() local w = K.W(); local r = {}; if w then pcall(function() r = w:rows() end) end; return r end
-- the first mod whose tab has something (not greyed) and, for options/sandbox/conflicts, a count; nil when none
function K.modFor(tab)
    local w = K.W()
    if not w then return nil end
    local best = nil
    for _, d in ipairs(K.rows()) do
        local list = {}
        pcall(function() list = w:detailTabs(d) end)
        for _, t in ipairs(list) do
            if t.id == tab and not t.none and (not best or (t.count or 0) > best.n) then best = { d = d, n = t.count or 0 } end
        end
    end
    return best and best.d or nil
end
function K.pickTab(tab, name)
    local w = K.W()
    local d = (tab == "about") and (function() for _, x in ipairs(K.rows()) do if x.modId == "ZeD_UI" then return x end end; return K.rows()[1] end)() or K.modFor(tab)
    if not (w and d) then fail = fail + 1; say("not taken: " .. name .. " (no mod with a " .. tab .. " tab)"); keep.skipTab = true; return end
    keep.skipTab = false
    w.sel = d.modId; w.fsel = nil; w.dtab = tab; w.dscroll = 0
    say(name .. ": " .. tostring(d.name) .. " (" .. tostring(d.modId) .. ")")
end

function K.setupIdx()
    local w = MM.root and MM.root.optsWin
    for i, p in ipairs(w and w:pages() or {}) do if p.setup then return i end end
    return 1
end
function K.O() return MM.root and MM.root.optsWin end
-- one walk: n screens, pictures named C_setup_<tag>_<i>
function K.walk(tag)
    at(10, function()
        local w = K.O()
        if not w then fail = fail + 1; say("ERR no Options window"); return end
        w.pageIdx = K.setupIdx(); w.scroll = 0; w.focusId = nil
        keep.prev, keep.stop = -1, false
        local heads = {}
        for _, r in ipairs(w:rowsFor(w:pages()[w.pageIdx])) do if r.kind == "header" then heads[#heads + 1] = tostring(r.text) end end
        say(tag .. " groups: " .. table.concat(heads, " | "))
    end)
    for i = 1, 8 do
        at(12, function() local w = K.O(); if w then w._groupCache = nil end end)
        at(8, function()
            local w = K.O()
            if not w or keep.stop then return end
            if w.scroll == keep.prev then keep.stop = true; return end
            keep.prev = w.scroll
            say(tag .. " screen " .. i .. " scroll " .. tostring(w.scroll))
            K.shot("C_setup_" .. tag .. "_" .. i)
            w.scroll = w.scroll + math.max(ZeD.T.px(40), w._list.h - ZeD.T.px(120))
        end)
    end
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.opt0 = {}
    local zo = K.opts()
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.id then keep.opt0[o.id] = o.selected end
    end
    keep.ini0 = K.readIni()
    keep.base, keep.accent, keep.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    say("as found: Style " .. tostring(K.val("lookStyle")) .. ", view " .. tostring(MM.view) .. ", look " .. tostring(keep.base))
    if MM.view ~= "main" then pcall(MM.showView, "main") end
    K.style(1)
end)
at(20, function() MM.openOptions() end)
at(40, function() say("Options open " .. tostring(K.O() ~= nil and K.O():isVisible())) end)
K.walk("full")
at(10, function() K.style(2) end)
at(40, function() say("Lite " .. tostring(St.lite())); local w = K.O(); if w then w._groupCache = nil end end)
K.walk("lite")
at(10, function()
    local w = K.O()
    if w then pcall(function() w:back() end); if w.confirm then pcall(function() w:discard() end) end end
end)
at(20, function() if MM.view ~= "main" then pcall(MM.showView, "main") end end)
at(15, function()
    local zo = K.opts()
    for id, v in pairs(keep.opt0 or {}) do
        local o = zo and zo.dict and zo.dict[id]
        if o and o.selected ~= v then pcall(function() o:setValue(v) end) end
    end
    pcall(ZeD.Settings.reapplyFromOptions)
    if keep.base and ZeD.applyTheme then pcall(ZeD.applyTheme, keep.base, keep.accent, keep.size) end
    K.writeIni(keep.ini0)
end)
at(10, function()
    local bad = {}
    for id, v in pairs(keep.opt0 or {}) do if K.val(id) ~= v then bad[#bad + 1] = id end end
    say("put back: options " .. ((#bad == 0) and "all as found" or ("NOT " .. table.concat(bad, " "))) .. ", look " .. tostring(ZeD.currentBase) .. ", view " .. tostring(MM.view))
    pcall(function() Mouse.setCursorVisible(true) end)
end)
at(5, function() say(string.format("end: %d shots, %d fail", pass, fail)); say("DONE") end)
local last = T0
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if tick > last + 20 + OFF then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
