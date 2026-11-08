-- ZeDUI/tools/qa/zedqa_b8_forms.lua  (Nov 8 2026, QA; punch list 110, CHECK_forms_phrase_20261107.md)
-- One phrase for the two forms, read from the live game (the real Settings.lua, ZeD_MainMenuOptionGroups.lua and the loaded
-- translation), the same facts forms_phrase_sim.lua reads off disk:
--   * ZeD setup's sections: "Immersive or simple" holds Belt, Devices, Watch, Dashboard, Survival guide and Identity card in that
--     order; Look no longer holds the Identity card; the Action bar sits in HUD; the Mods screen, Context menu and Equipped items sit
--     in Windows (Context menu and Equipped items right after Inventory); every row once
--   * the words (English game only; another language checks the keys are translated): Immersive, Detailed, each help line
--     "Immersive: ... Simple: ..." (Detailed for the Action bar and the Mods screen), the guide's ZeD setup chapter and the beta 3
--     what's-new line say Immersive, not Full
--   * the saved choices: each option reads 1 or 2 (nothing out of range), the presets still set the same items (Vanilla Access Simple,
--     Vanilla Plus the rich one), the preset the live values make is read
--   * a picture of the guide's ZeD setup chapter
-- Manual: the rows drawn on screen in ZeD setup (main menu or Options), the Find box, other languages' fit at the Deck / 720p with
-- Large text. Nothing is changed. grep "ZEDQA b8fm". Picture zqa_b8_forms_guide.png.
local TAG = "b8fm"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end; return ok end
local core = getCore()
local G, B = ZeD.Guide, ZeD.GuideBook
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = { was = {} }

local lang = "?"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)
local EN = (lang == "EN")
local function list(t) return table.concat(t or {}, ", ") end
local function tr(k) return tostring(ZeD.tr(k)) end

step(10, function()
    say("language " .. lang)
    local og = ZeD.MainMenu and ZeD.MainMenu.optionGroups
    if not check(og and og.ZED_GROUPS, "the option groups are loaded") then return end
    local rows, where, count = {}, {}, {}
    for _, g in ipairs(og.ZED_GROUPS) do
        rows[g[1]] = {}
        for i, r in ipairs(g[2] or {}) do
            rows[g[1]][i] = r[1]
            where[r[1]] = g[1]
            count[r[1]] = (count[r[1]] or 0) + 1
        end
    end
    local FORMS = { "beltStyle", "devicesStyle", "watchStyle", "dashStyle", "guideStyle", "identityStyle" }
    check(list(rows.UI_ZeD_Options_ZedForms) == list(FORMS), "Immersive or simple holds the six, in order (" .. list(rows.UI_ZeD_Options_ZedForms) .. ")")
    check(where.identityStyle == "UI_ZeD_Options_ZedForms", "the Identity card has left Look (it is in " .. tostring(where.identityStyle) .. ")")
    check(where.actionBar == "UI_ZeD_Options_ZedHud", "the Action bar sits in HUD (" .. tostring(where.actionBar) .. ")")
    check(where.modsStyle == "UI_ZeD_Options_ZedWindows", "the Mods screen sits in Windows (" .. tostring(where.modsStyle) .. ")")
    local win = rows.UI_ZeD_Options_ZedWindows or {}
    check(win[1] == "inventoryView" and win[2] == "contextStyle" and win[3] == "equipView", "Windows: Inventory, Context menu, Equipped items lead (" .. list(win) .. ")")
    local hud = rows.UI_ZeD_Options_ZedHud or {}
    check(hud[3] == "actionBar", "HUD: the Action bar comes after Watch place (" .. list(hud) .. ")")
    for _, id in ipairs({ "beltStyle", "devicesStyle", "watchStyle", "dashStyle", "guideStyle", "identityStyle", "actionBar", "modsStyle", "contextStyle", "equipView", "inventoryView" }) do
        check(count[id] == 1, id .. " shows in one section (" .. tostring(count[id]) .. ")")
    end
    check(tr("UI_ZeD_Options_ZedForms") ~= "UI_ZeD_Options_ZedForms", "the section has a name in this language (" .. tr("UI_ZeD_Options_ZedForms") .. ")")
    if EN then check(tr("UI_ZeD_Options_ZedForms") == "Immersive or simple", "the section reads 'Immersive or simple'") end
end)

step(5, function()
    local Se = ZeD.Settings
    local OPT = { beltStyle = "beltStyleOption", devicesStyle = "devicesStyleOption", watchStyle = "watchStyleOption", dashStyle = "dashStyleOption",
                  guideStyle = "guideStyleOption", identityStyle = "identityStyleOption", actionBar = "actionBarOption", modsStyle = "modsStyleOption",
                  contextStyle = "contextStyleOption", equipView = "equipViewOption" }
    local vals = {}
    for id, field in pairs(OPT) do
        local o = Se[field]
        local ok, v = false, nil
        if o then ok, v = pcall(o.getValue, o) end
        vals[#vals + 1] = id .. "=" .. tostring(v)
        check(ok and (v == 1 or v == 2), id .. " reads item 1 or 2 (" .. tostring(v) .. ")")
    end
    table.sort(vals)
    say("saved choices now: " .. table.concat(vals, ", "))
    local P = Se.ADDITION_PRESETS
    if check(P and P[2] and P[3], "the additions' presets load") then
        for _, id in ipairs({ "devicesStyle", "watchStyle", "dashStyle", "guideStyle", "modsStyle", "identityStyle" }) do
            check(P[2][id] == 1, "Vanilla Plus keeps " .. id .. " on item 1 (the rich form)")
            check(P[3][id] == 2, "Vanilla Access picks Simple for " .. id)
        end
    end
end)

step(5, function()
    -- the words
    local keys = { "UI_ZeD_Settings_Immersive", "UI_ZeD_Settings_ActionBarVerbose", "UI_ZeD_Settings_BeltTip", "UI_ZeD_Settings_DevicesTip",
                   "UI_ZeD_Settings_WatchStyleTip", "UI_ZeD_Settings_DashTip", "UI_ZeD_Settings_GuideTip", "UI_ZeD_Settings_IdentityTip",
                   "UI_ZeD_Settings_ActionBarTip", "UI_ZeD_Settings_ModsTip", "UI_ZeD_GCh_zed_setup_Title", "UI_ZeD_GCh_zed_setup_Text",
                   "UI_ZeD_GCh_whatsnew_beta3_Text" }
    local missing = {}
    for _, k in ipairs(keys) do if tr(k) == k or tr(k) == "" then missing[#missing + 1] = k end end
    check(#missing == 0, "every changed key has text in this language" .. (#missing > 0 and (" (missing: " .. list(missing) .. ")") or ""))
    if not EN then say("note: the wording checks (Immersive / Detailed / 'Full') are English; this run is " .. lang); return end
    check(tr("UI_ZeD_Settings_Immersive") == "Immersive", "Immersive reads Immersive")
    check(tr("UI_ZeD_Settings_ActionBarVerbose") == "Detailed", "Detailed reads Detailed")
    for _, k in ipairs({ "Belt", "Devices", "WatchStyle", "Dash", "Guide", "Identity" }) do
        local t = tr("UI_ZeD_Settings_" .. k .. "Tip")
        check(t:find("Immersive: ", 1, true) ~= nil and t:find("Simple: ", 1, true) ~= nil and t:find("Full: ", 1, true) == nil, k .. "Tip reads 'Immersive: ... Simple: ...'")
    end
    for _, k in ipairs({ "ActionBar", "Mods" }) do
        local t = tr("UI_ZeD_Settings_" .. k .. "Tip")
        check(t:find("Detailed: ", 1, true) ~= nil and t:find("Simple: ", 1, true) ~= nil and t:find("Verbose", 1, true) == nil and t:find("Full: ", 1, true) == nil, k .. "Tip reads 'Detailed: ... Simple: ...'")
    end
    for _, k in ipairs({ "UI_ZeD_GCh_zed_setup_Title", "UI_ZeD_GCh_zed_setup_Text", "UI_ZeD_GCh_whatsnew_beta3_Text" }) do
        local t = tr(k)
        check(t:find("Immersive", 1, true) ~= nil and t:find("Full", 1, true) == nil, k .. " says Immersive, not Full")
    end
end)

-- a picture of the guide's ZeD setup chapter (the Full book)
step(10, function()
    local look = ZeD.Settings.guideStyleOption
    S.was.look = look:getValue()
    S.cwOpen = ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isReallyVisible()
    if S.cwOpen then ZeD_CharacterWindow.toggleBothPaired(0) end
    pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end)
    look:setValue(1)
    G.open(0, "UI_ZeD_GCh_zed_setup_Title")
end)
step(40, function()
    if B.isOpen(0) then
        local bk = B.books[0]
        local at = nil
        for _, t in ipairs(bk.flat or {}) do if t.titleKey == "UI_ZeD_GCh_zed_setup_Title" then at = bk.pageOf[t.id] end end
        check(at ~= nil, "the guide has the ZeD setup chapter (page " .. tostring(at) .. ")")
        if at then bk.spread = math.floor((at + 1) / 2) end
    else
        say("note: the guide opened as the window in this language")
    end
end)
step(30, function() pcall(function() core:TakeFullScreenshot("zqa_b8_forms_guide.png") end); say("shot forms_guide") end)
step(10, function()
    pcall(B.close, 0)
    local w = G.get(0); if w and w:isReallyVisible() then pcall(function() w:close() end) end
    ZeD.Settings.guideStyleOption:setValue(S.was.look or 1)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if S.cwOpen and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    say(pass .. " passed, " .. fail .. " failed")
    say("DONE")
end)

local function tick()
    if wait > 0 then wait = wait - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    wait = s.n
end
say("start")
Events.OnRenderTick.Add(tick)
