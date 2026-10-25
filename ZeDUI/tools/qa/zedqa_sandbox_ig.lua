-- ZeDUI/tools/qa/zedqa_sandbox_ig.lua  (Oct 24 2026)
-- Sandbox options in game (ZeD_SandboxInGame.lua, mockup zed_sandbox_ingame_v1):
--   * the pause window's line only with Options > ZeD setup > Sandbox on
--   * the window: vanilla's pages plus Changed and History, a fixed setting locked,
--     the World page's day line, the three-part help band
--   * Zombie Count sets Population Multiplier (vanilla's link); Undo changes
--   * Apply asks first (on the Changed page), then sets the game's options and
--     SandboxVars, the day's length on the clock, and History
--   * Put back + Apply returns every value; the controller's prompts
-- Everything it changes is put back: the settings, the switch, History's entries.
-- grep "ZEDQA sbx". Screenshots zqa_sbx_*.png.
local p = getPlayer()
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA sbx " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sbx_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

local opt = ZeD.Settings and ZeD.Settings.sandboxInGameOption
if not (opt and MM and ZeD_MMSandboxIG) then say("ERR the sandbox window is not loaded"); say("DONE"); return end
local switchWas = opt:getValue()
local so = getSandboxOptions()
local CHANGE = { FoodRotSpeed = true, HoursForCorpseRemoval = true, FireSpread = true, DayLength = true }
local was = {}
for n in pairs(CHANGE) do was[n] = so:getOptionByName(n):getValueAsString() end
local minutesWas = getGameTime():getMinutesPerDay()
local hist = ZeD.SandboxIG.history()
local histWas = #hist
local sw

local function menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
local function toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
local function hasLine()
    for _, b in ipairs(MM.pause and MM.pause._specs or {}) do if b.id == "sandbox" then return true end end
    return false
end
local function page(title)
    for i, pg in ipairs(sw:pages()) do if pg.raw == title or pg.title == title then sw.pageIdx = i; sw.scroll = 0; sw.focusId = nil; return pg end end
end
local function row(name) return sw.ctls[name] end
-- the help band shows this setting (as if the pointer were on it)
local function help(r) sw.qaHelp = r end

-- the line: off, then on
step(10, function()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(p:getPlayerNum()) end
    opt:setValue(1)
    pcall(function() Mouse.setXY(5, 5) end)   -- (the pointer off the window: the help band shows what the test points at)
    if not menuUp() then toggleMenu() end
end)
step(40, function()
    check(menuUp() and MM.pause and MM.pause:isVisible(), "the pause window is up")
    check(not hasLine(), "switch off: no Sandbox options line")
    opt:setValue(2)
end)
step(20, function()
    check(hasLine(), "switch on: the Sandbox options line is there")
    shot("pause_line")
end)
step(10, function() MM.openSandboxIG() end)

-- the window
step(40, function()
    sw = MM.pauseSandbox
    if not check(sw and sw:isVisible() and MM.pauseView == "sandbox", "the window is open over the paused game") then return end
    local pages = sw:pages()
    local titles = {}
    for _, pg in ipairs(pages) do titles[#titles + 1] = pg.title end
    say("pages: " .. table.concat(titles, ", "))
    check(#pages >= 11, "vanilla's pages plus Changed and History (" .. #pages .. ")")
    local n = 0
    for _ in pairs(sw.ctls) do n = n + 1 end
    check(n >= 250, "every setting has a row (" .. n .. ")")
    check(sw.nDiff == 0, "nothing marked changed on opening")
    check(sw:helpBandH() > 0, "the help band has room")
    local sm = row("StartMonth")
    check(sm and sw:rowDisabled(sm), "Start Month is fixed (locked)")
    if sm then
        local before = sm.control.selected
        sw:nudge(sm, 1)
        check(sm.control.selected == before, "a fixed setting does not change")
    end
    help(row("DayLength"))
end)
step(30, function() shot("time") end)
step(5, function()
    page("World")
    local rows = sw:rowsFor(sw:pages()[sw.pageIdx])
    check(rows[1] and rows[1].kind == "note", "the World page starts with the world's day")
    say("world line: " .. tostring(rows[1] and rows[1].text))
    help(row("WorldItemRemovalList"))
end)
step(30, function() shot("world_help") end)

-- Zombie Count's link, then Undo changes
step(5, function()
    page("Zombie")
    local z, pm = row("Zombies"), row("ZombieConfig.PopulationMultiplier")
    if not check(z and pm, "Zombie Count and Population Multiplier rows") then return end
    z.control.selected = 5
    sw:onCombo(z.control, "Zombies")
    local want = ZombiePopulationMultiplierTable and tonumber(ZombiePopulationMultiplierTable[5])
    check(want ~= nil and tonumber(pm.control:getText()) == want, "Zombie Count Low sets Population Multiplier to " .. tostring(want) .. " (" .. tostring(pm.control:getText()) .. ")")
    check(sw.nDiff == 2, "two settings marked changed (" .. sw.nDiff .. ")")
    help(z)
end)
step(30, function() shot("zombie_changed") end)
step(5, function()
    sw:undoAll()
    check(sw.nDiff == 0, "Undo changes puts both back")
end)

-- four harmless changes, Apply asks, then applies
step(5, function()
    page("World")
    local f = row("FoodRotSpeed")
    sw:nudge(f, (f.control.selected < #f.control.options) and 1 or -1)
    local h = row("HoursForCorpseRemoval")
    h.control:setText("100")
    local fs = row("FireSpread")
    fs.control.selected[1] = not (fs.control.selected[1] == true)
    local d = row("DayLength")
    sw:nudge(d, (d.control.selected < #d.control.options) and 1 or -1)
    sw:refreshDiff(true)
    check(sw.nDiff == 4, "four changes marked (" .. sw.nDiff .. ")")
    check(so:getOptionByName("FoodRotSpeed"):getValueAsString() == was.FoodRotSpeed, "nothing applied before Apply")
    sw:askApply()
    help(row("DayLength"))
end)
step(30, function()
    check(sw.confirm == "apply", "Apply asks first")
    check(sw:pages()[sw.pageIdx].virtual == "changed", "the question shows the Changed page")
    say("ask: " .. tostring(sw._ask))
    shot("ask_apply")
end)
step(5, function()
    sw:applyNow()
    for n in pairs(CHANGE) do
        local now = so:getOptionByName(n):getValueAsString()
        check(now ~= was[n], n .. " applied (" .. was[n] .. " > " .. now .. ")")
    end
    check(tostring(SandboxVars.HoursForCorpseRemoval) == "100" or SandboxVars.HoursForCorpseRemoval == 100, "SandboxVars has the new number (" .. tostring(SandboxVars.HoursForCorpseRemoval) .. ")")
    check(getGameTime():getMinutesPerDay() ~= minutesWas, "the clock took the new day length (" .. minutesWas .. " > " .. getGameTime():getMinutesPerDay() .. ")")
    check(#hist == histWas + 1, "History has the apply")
    check(sw.nDiff == 0, "nothing marked changed after Apply")
    say("strip: " .. tostring(sw._ask))
end)
step(30, function() shot("applied") end)
step(5, function()
    page("~history")
    local rows = sw:rowsFor(sw:pages()[sw.pageIdx])
    local btns = 0
    for _, r in ipairs(rows) do if r.kind == "button" then btns = btns + 1 end end
    check(btns >= 4, "History lists the four with Put back (" .. btns .. ")")
    help(rows[2])
end)
step(30, function() shot("history") end)

-- Put back each, apply, everything as it was
step(5, function()
    local e = hist[#hist]
    for _, c in ipairs(e.rows or {}) do sw:putBack(c.n, c.from) end
    check(sw.nDiff == 4, "Put back marks four changes (" .. sw.nDiff .. ")")
    sw:askApply()
end)
step(10, function()
    sw:applyNow()
    for n in pairs(CHANGE) do
        check(so:getOptionByName(n):getValueAsString() == was[n], n .. " back to " .. was[n])
    end
    check(getGameTime():getMinutesPerDay() == minutesWas, "the day's length back (" .. getGameTime():getMinutesPerDay() .. ")")
end)

-- the controller
step(5, function()
    MM.forceGamepad = true
    sw.qaHelp = nil
    page("Time")
    sw.focusId = nil
end)
step(10, function() sw:joyDir("down") end)   -- (once the page has drawn its rows)
step(20, function()
    local fr = sw:focusedRow()
    check(fr ~= nil, "the D-pad lands on a row")
    local pr = sw:getFooterPrompts() or {}
    local g = {}
    for _, t in ipairs(pr) do g[#g + 1] = t.glyph end
    say("prompts: " .. table.concat(g, " "))
    check(#pr >= 3, "the footer shows the pad's buttons")
    shot("pad")
end)

-- put back what the test added
step(5, function()
    MM.forceGamepad = false
    sw.qaHelp = nil
    sw:finish()
    for _ = 1, #hist - histWas do table.remove(hist) end
    check(#hist == histWas, "History as it was")
    opt:setValue(switchWas or 1)
    if menuUp() then toggleMenu() end
end)
step(20, function()
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
