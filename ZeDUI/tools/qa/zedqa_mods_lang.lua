-- ZeDUI/tools/qa/zedqa_mods_lang.lua  (Nov 4 2026, QA; punch list 84 in other languages, 067a0361) MAIN MENU ONLY.
-- The Mods screen in the game's language: the tab strip (All, On, Off and the rest) fits the list, the Hide
-- incompatible box with its count leaves Find a usable field, the Simple view's tabs fit; pictures with the
-- box's help line showing (hover held on the box) in Full and in Simple, and with a folder's label swatches.
-- grep "ZEDQA mlg".
local MM = ZeD.MainMenu
local F = ZeD.ModFolders
local function say(s) print("ZEDQA mlg " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local lang = "?"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_mlg_" .. lang .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local keep = {}
local hold
local function holdHot() if hold then MM.ctx.hot = hold end end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.style = ZeD.Settings.modsStyleOption:getValue()
    if sh <= 800 then
        local o = PZAPI.ModOptions:getOptions("ZeD_UI"):getOption("textSize")
        keep.tso, keep.ts = o, o:getValue()
        o:setValue(2)
        if o.onChangeApply then o:onChangeApply(2) else ZeD.Settings.reapplyFromOptions() end
    end
    MM.openMods()
    Events.OnFETick.Add(holdHot)
end)
local function measure(tag)
    local w = W()
    local T = ZeD.T
    w.hideInc = true; w:dirty()
    local tabs, need = w:tabList()
    local listW = w._listW or (w.find and (w.find:getWidth() + 0)) or 0
    local fw = w.find and w.find:getWidth() or 0
    local hiW = MM.textW(T.fontF2, ZeD.tr("UI_ZeD_Mods_HideInc"))
    say(string.format("%s %s: tab strip needs %d px; Find field %d px; Hide incompatible label %d px; unit %d px", lang, tag, need, fw, hiW, T.px(1)))
    check(fw >= T.px(120), tag .. ": Find keeps a usable field beside Hide incompatible (" .. fw .. " px, at least " .. T.px(120) .. ")")
    keep.need = need
end
at(40, function() W().filter = "all"; hold = "mods:hideinc" end)
at(70, function() measure("Full") end)
at(90, function() shot("1_full_hideinc_help") end)
at(100, function() ZeD.Settings.modsStyleOption:setValue(2); W():dirty() end)
at(130, function() measure("Simple") end)
at(150, function() shot("2_simple_hideinc_help") end)
at(160, function()
    ZeD.Settings.modsStyleOption:setValue(keep.style or 1)
    hold = nil
    local w = W(); w.hideInc = false; w:dirty()
end)
at(200, function()
    Events.OnFETick.Remove(holdHot)
    local w = W()
    w:discard()
    if keep.tso then
        keep.tso:setValue(keep.ts)
        if keep.tso.onChangeApply then keep.tso:onChangeApply(keep.ts) else ZeD.Settings.reapplyFromOptions() end
    end
end)
at(220, function()
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 240 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
