-- ZeDUI/tools/qa/zedqa_etw.lua  (Oct 29 2026)
-- Evolving Traits World's progress in ZeD's Traits tab (ZeD/ModSupport/EvolvingTraitsWorld.lua),
-- on the ZeD-QA save with the mod on. Run with etw_manifest.txt through
-- zedqa_mods_run.ps1 -ModList etw_mods.txt -Mode fullscreen4k.
--   1. the Traits tab sits right after Skills (its own tab without Traits As Skills; with it, a
--      section of that mod's tab); its rows are the mod's, named in the mod's words
--   2. a row's progress is the mod's own number: the Food vital (the mod's 31-day average), the
--      Reader System bar (its pages read set for a moment to a quarter of the target, then put
--      back), and a skill line ("Jogger: a/b")
--   3. the controller: into the tab from the strip, onto a row (the details follow focus)
--   4. the foot shows the mod's words (its "Current value", its tooltip); capture zqa_etw_tab.png
-- Everything it changes is put back (the mod's counter, the tab, the focus, Find and the switch).
-- Captures: Zomboid/Screenshots/zqa_etw_<name>.png. grep "ZEDQA etw".
local TAG = "etw"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local S = ZeD.ModSupport and ZeD.ModSupport.EvolvingTraitsWorld
if not S then say("ERR ZeD's Evolving Traits World support is not loaded (is the mod on?)"); say("DONE"); return end
local CW = ZeD_CharacterWindow
local F = ZeD.Input and ZeD.Input.Focus
local core = getCore()
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(name)
    local f = "zqa_etw_" .. name .. ".png"
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then say("shot " .. f) else fails = fails + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
local function win() return CW.getWindow() end
-- the source's rows (read from the mod), and the tab's own state (ZeD's, or Traits As Skills' when it hosts)
local function src() return win()._etw end
local function hostSel()
    local w = win()
    if S.hosted then return w._tas and w._tas.sel end
    return w._etwHost and w._etwHost.sel
end
local function park() pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end) end
local function focused() local e = F.getFocusedElement(win()); return e and e.id end
local function near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.0005 end
local function clamp01(v) return math.max(0, math.min(1, v)) end
local function clickTab(id)
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:" .. id then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2); return true end
    end
    return false
end
-- the mod's own modules, read here independently of ZeD's support
local ETWF = nil
pcall(function() ETWF = require("ETW_CommonFunctions") end)
local SB = SandboxVars.EvolvingTraitsWorld or {}
local function modData() return ETWF and ETWF.getETWModData(p) end

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- 1. the tab and its rows
step(30, function()
    park()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end
    local order = {}
    for _, t in ipairs(CW.TABS) do order[#order + 1] = t.id end
    local s = table.concat(order, ",")
    say("tabs: " .. s .. (S.hosted and " (hosted by Traits As Skills)" or " (own tab)"))
    check(s:find("skills,traits", 1, true) ~= nil, "the Traits tab sits right after Skills")
    check(clickTab("traits"), "the Traits tab is on the strip")
    check(ZeD.TabPx and ZeD.TabPx.has("traits"), "it has the lit pixel-art icon")
    check(ETWF ~= nil and type(modData()) == "table", "the mod's data can be read")
end)
step(60, function()
    check(win()._activeTab == "traits", "the Character window is on Traits")
    local st = src()
    check(st and #st.rows > 0, "the mod's rows are there: " .. tostring(st and #st.rows))
    if not st then return end
    local cats, raw = {}, 0
    for _, r in ipairs(st.rows) do
        cats[r.cat] = (cats[r.cat] or 0) + 1
        -- a name that is still a key means a word of the mod's was not found
        if r.name == nil or r.name == "" or r.name:find("^Sandbox_ETW_") or r.name:find("^UI_ETW_") then raw = raw + 1; say("raw name " .. tostring(r.id)) end
    end
    local parts = {}
    for _, c in ipairs({ "vitals", "combat", "noncombat", "physical", "mental", "delayed" }) do parts[#parts + 1] = c .. "=" .. tostring(cats[c] or 0) end
    say("rows by group: " .. table.concat(parts, " "))
    check(raw == 0, "every row is named in the mod's words")
    local food = st.byId["etw:food"]
    check(food and food.name == getText("UI_ETW_Vitals_Food"), "the Food vital, named as on the mod's page: " .. tostring(food and food.name))
    local reader = st.byId["etw:reader"]
    if reader then check(reader.name == getText("Sandbox_ETW_ReaderSystem"), "the Reader System, named as on the mod's page") end
    -- a skill line named by its trait, as the mod's "Jogger: a/b"
    local runner = st.byId["etw:runner"]
    if runner then
        local d = CharacterTraitDefinition.getCharacterTraitDefinition(CharacterTrait.JOGGER)
        check(d and runner.name == d:getUIName(), "the runner line is named by its trait: " .. tostring(runner.name))
    end
end)

-- 2. the progress is the mod's own number
step(10, function()
    local st = src()
    local md = modData()
    local food = st.byId["etw:food"]
    if food and md then
        local want = clamp01(md.RecentAverageFood or 0)
        check(near(food.value, want), "Food's strip is the mod's 31-day average: " .. tostring(food.value) .. " / " .. tostring(want))
        check(food.raw and food.raw:find(getText("UI_ETW_CurrentValue"), 1, true) == 1, "Food's progress line is the mod's \"Current value\": " .. tostring(food.raw))
    end
    -- the Reader System: set the mod's pages read to a quarter of its target, read, put it back (one Lua call: no game minute passes)
    if md and st.byId["etw:reader"] and (SB.ReaderSystemCounter or 0) > 0 then
        local saved = md.PagesReadCounter
        local ok, err = pcall(function()
            md.PagesReadCounter = math.floor(SB.ReaderSystemCounter / 4)
            local st2 = S.refresh(win(), true)
            local r = st2.byId["etw:reader"]
            local want = md.PagesReadCounter / SB.ReaderSystemCounter
            check(r and near(r.value, want), "the Reader System's strip follows the mod's counter: " .. tostring(r and r.value) .. " / " .. tostring(want))
            check(r and r.raw == getText("UI_ETW_CurrentValue") .. tostring(md.PagesReadCounter), "its line is the mod's own: " .. tostring(r and r.raw))
        end)
        md.PagesReadCounter = saved
        S.refresh(win(), true)
        if not ok then fails = fails + 1; say("ERR reader: " .. tostring(err)) end
        check(md.PagesReadCounter == saved, "the mod's pages read are put back: " .. tostring(saved))
    else
        say("skip Reader System (not on this character's page)")
    end
    -- a skill line: the skill level over the mod's sandbox target
    local lines = { { "etw:runner", "Sprinting", "RunnerSkill" }, { "etw:lightStep", "Lightfoot", "LightStepSkill" },
        { "etw:lowProfile", "Sneak", "LowProfileSkill" }, { "etw:cook", "Cooking", "CookSkill" }, { "etw:firstAid", "Doctor", "FirstAidSkill" },
        { "etw:avClub", "Electricity", "AVClubSkill" }, { "etw:whittler", "Carving", "WhittlerSkill" }, { "etw:angler", "Fishing", "FishingSkill" } }
    local done = false
    for _, l in ipairs(lines) do
        local r = st.byId[l[1]]
        if r and not done and (SB[l[3]] or 0) > 0 then
            done = true
            local lv = p:getPerkLevel(Perks[l[2]])
            local want = clamp01(lv / SB[l[3]])
            check(near(r.value, want), l[1] .. " fills to the mod's " .. lv .. "/" .. SB[l[3]] .. ": " .. tostring(r.value))
            local items = S.detailItems(r)
            check(items[1] and items[1].v == r.name .. ": " .. lv .. "/" .. SB[l[3]], "its details carry the mod's line: " .. tostring(items[1] and items[1].v))
        end
    end
    if not done then say("skip skill line (none listed for this character)") end
end)

-- 3. the controller: into the tab, onto a row (the details follow focus)
step(20, function()
    local w = win()
    pcall(F.claimFocus, w)
    local e = F.focusWhere(w, "charTabBar", function(x) return x.id == "tab:traits" end)
    check(e ~= nil, "focus on the Traits tab in the strip")
end)
step(20, function()
    F.dispatchJoypadDir(win(), "right")
    local id = focused() or ""
    say("into the tab from the strip: " .. id)
    check(id:sub(1, 4) == "etw:" or id:sub(1, 4) == "tas:", "the D-pad goes into the tab")
    -- straight to the Food vital's row (the first of the mod's rows)
    local e = F.focusWhere(win(), "charTabContent", function(x) return x.id == "etw:row:etw:food" end)
    check(e ~= nil, "the Food row is a controller stop")
end)
step(20, function()
    check(focused() == "etw:row:etw:food", "focus is on the Food row: " .. tostring(focused()))
    check(hostSel() == "etw:food", "the details follow focus with no press: " .. tostring(hostSel()))
    F.dispatchJoypadDir(win(), "down")
end)
step(20, function()
    local id = focused() or ""
    check(id:sub(1, 8) == "etw:row:", "down: the next row (" .. id .. ")")
    check(("etw:row:" .. tostring(hostSel())) == id, "walking rows moves the details: " .. tostring(hostSel()))
    F.dispatchJoypadDir(win(), "up")
end)

-- 4. the foot shows the mod's words
step(30, function()
    local st = src()
    local r = st.byId[hostSel() or ""]
    check(r and r.id == "etw:food", "the Food row is picked again")
    if r then
        local items = S.detailItems(r)
        local kWhat, desc = ZeD.tr("UI_ZeD_ETW_KWhat"), nil
        for _, it in ipairs(items) do if it.k == kWhat then desc = it.v end end
        local want = getText("Sandbox_ETW_FoodSystem_tooltip"):gsub("<br>", " "):gsub("%%%%", "%%")
        check(desc == want, "the foot shows the mod's own description of what moves it")
        check(items[1] and items[1].v == r.raw, "the foot's progress line is the mod's \"Current value\" line")
    end
    shot("tab")
end)

-- put everything back
step(10, function()
    park()
    pcall(F.releaseFocus)
    S.find, S.only, S.closed = "", false, {}
    clickTab("identity")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then
        fails = fails + 1
        say("ERR step " .. (qi - 1) .. ": " .. tostring(err))
        -- (a failing last step still ends the run)
        if qi > #Q then say("DONE") end
    end
end
Events.OnRenderTick.Add(tick)
say("start")
