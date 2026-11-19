-- ZeDUI/tools/qa/zedqa_menu_b21r.lua  (Nov 19 2026, QA; tag mb21r): MAIN MENU ONLY, pushed through the QA bridge. The
-- beta 21 visual report's main menu pictures (the director's standing ask, Nov 19: full-screen pictures of every
-- change before a full release test). 4K at 1.75x, the pointer hidden, the debug console hidden:
--   b21r_lite_08_desk     the desk in Lite (no desk apps)
--   b21r_lite_09_mods     the Mods screen in Lite (Profiles and Load order in the band)
--   b21r_welcome_12       the first-launch window: Pick your own, Light picked (the preview shows it)
--   b21r_welcome_13       the same window with Load a setup picked
-- Style set as ZeD setup's row sets it (the option's value, then its onChange); the welcome's picks through the
-- window's own activate path (as zedqa_menu_welcome.lua). Nothing is saved: Done is never pressed. What it puts back:
-- every ZeD option as found, the look on screen, ModOptions.ini line for line (beta21_report_run.ps1 also puts the
-- director's four files back byte for byte). grep "ZEDQA mb21r".
local MM = ZeD.MainMenu
local St = ZeD.Settings
local function say(s) print("ZEDQA mb21r " .. tostring(s)) end
local pass, fail, tick = 0, 0, 0
local steps = {}
local OFF = 80   -- (the desk's screen fades in at boot: every step after the first waits for it)
local function at(n, fn) steps[#steps + 1] = { n = (n > 2) and (n + OFF) or n, fn = fn } end
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
function K.shot(name)
    pcall(function() Mouse.setXY(4, 4); Mouse.setCursorVisible(false) end)
    local ok, e = pcall(function() getCore():TakeFullScreenshot("b21r_" .. name .. ".png") end)
    if ok then pass = pass + 1; say("shot b21r_" .. name) else fail = fail + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
function K.W() return MM.root and MM.root.welcomeWin end
function K.open() local w = K.W(); return MM.view == "welcome" and w ~= nil and w:isVisible() end
function K.spec(id)
    local w = K.W()
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
function K.press(id)
    local w = K.W()
    local why = nil
    if not K.open() then why = "the welcome window is not open (view " .. tostring(MM.view) .. ")"
    else
        local s = K.spec(id)
        if not s then why = "no spec " .. id
        elseif s.disabled then why = id .. " is disabled"
        else
            w.focusId = id
            local rows, ri, ci = w:focusPos()
            if not ri or rows[ri][ci].id ~= id then why = "the focus did not land on " .. id
            else w:joyA() end
        end
    end
    if why then fail = fail + 1; say("ERR press " .. id .. " | " .. why) end
    return why == nil
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
    K.style(2)
end)
at(25, function()
    say("Lite " .. tostring(St.lite()) .. ", desk apps " .. tostring(#(MM.leftItems() or {})) .. ", view " .. tostring(MM.view))
    K.shot("lite_08_desk")
end)
at(30, function() MM.ctx.open = nil; MM.openMods() end)
at(55, function()
    local w = MM.root and MM.root.modsWin
    say("Mods screen open " .. tostring(w ~= nil and w:isVisible()))
    K.shot("lite_09_mods")
end)
at(60, function()
    local w = MM.root and MM.root.modsWin
    if w then pcall(function() w:back() end) end
end)
at(70, function() MM.openWelcome() end)
at(95, function() K.press("way:1") end)
at(103, function() K.press("opt:theme:2") end)   -- (Light)
at(110, function()
    say("welcome open " .. tostring(K.open()) .. ", look " .. tostring(ZeD.currentBase))
    K.shot("welcome_12")
end)
at(115, function() K.press("way:2") end)
at(135, function() K.shot("welcome_13") end)
-- put back: every option as found, the look, ModOptions.ini, the desk
at(140, function()
    if MM.view ~= "main" then pcall(MM.showView, "main") end   -- (not the window's Back: that is Skip, which writes)
    local zo = K.opts()
    for id, v in pairs(keep.opt0 or {}) do
        local o = zo and zo.dict and zo.dict[id]
        if o and o.selected ~= v then pcall(function() o:setValue(v) end) end
    end
    pcall(ZeD.Settings.reapplyFromOptions)
    if keep.base and ZeD.applyTheme then pcall(ZeD.applyTheme, keep.base, keep.accent, keep.size) end
    K.writeIni(keep.ini0)
end)
at(150, function()
    local bad = {}
    for id, v in pairs(keep.opt0 or {}) do if K.val(id) ~= v then bad[#bad + 1] = id end end
    say("put back: options " .. ((#bad == 0) and "all as found" or ("NOT " .. table.concat(bad, " "))) .. ", look " .. tostring(ZeD.currentBase) .. ", view " .. tostring(MM.view))
    if #bad > 0 then fail = fail + 1 end
    pcall(function() Mouse.setCursorVisible(true) end)
end)
at(155, function()
    say(string.format("end: %d pass, %d fail; view=%s", pass, fail, tostring(MM.view)))
    say(fail > 0 and ("VERDICT FAIL " .. fail) or ("VERDICT PASS " .. pass))
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if tick > 170 + OFF then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
