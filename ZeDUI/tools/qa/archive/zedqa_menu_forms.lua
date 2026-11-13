-- ZeDUI/tools/qa/zedqa_menu_forms.lua  (Nov 2 2026, QA; punch list 60, ZeD setup's "Full or simple" group)
-- At the main menu (zedqa_menu_mods_run.ps1, ZeD only). On ZeD setup:
--   the group comes right after Look and holds, in order, Belt, Action bar, Context menu, Equip view, Devices, Watch,
--   Dashboard; no other group shows those rows;
--   the additions' Preset: Vanilla Access sets Devices, Watch and Dashboard to Simple, Vanilla Plus sets them to Full;
--   any of the three picked by hand makes the Preset read Custom.
-- Nothing is applied: the window's own Discard puts every change back. grep "ZEDQA mfs"; shot mfs_group.png.
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA mfs " .. tostring(s)) end
if not (MM and MM.openOptions) then say("ERR ZeD's main menu is not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function O() return MM.root and MM.root.optsWin end
local steps, T0, t = {}, 0, 0
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = T0, fn = fn } end
local function tr(k) return ZeD.tr(k) end
local function label(c, i) local o = c.options and c.options[i]; return tostring(type(o) == "table" and (o.text or o[1]) or o) end
-- (punch list 110, Nov 7 2026: the group is "Immersive or simple"; Action bar to HUD, Context menu, Equip view and Mods
-- to Windows, the Identity card in from Look)
local WANT = { "UI_ZeD_Settings_Belt", "UI_ZeD_Settings_Devices", "UI_ZeD_Settings_WatchStyle", "UI_ZeD_Settings_Dash",
               "UI_ZeD_Settings_Guide", "UI_ZeD_Settings_Identity" }
local THREE = { "UI_ZeD_Settings_Devices", "UI_ZeD_Settings_WatchStyle", "UI_ZeD_Settings_Dash" }
local rowsBy = {}

local function setupRows(w) return w:rowsFor(w:pages()[w.pageIdx]) end
local function find(w, key) for _, r in ipairs(setupRows(w)) do if r.labelKey == key then return r end end end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    MM.openOptions()
end)
at(30, function()
    local w = O(); if not w then say("ERR no Options window"); return end
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    w.scroll = 0
    -- the groups, in order, with their rows
    local groups, cur = {}, nil
    for _, r in ipairs(setupRows(w)) do
        if r.kind == "header" then cur = { name = tostring(r.text), keys = {} }; groups[#groups + 1] = cur
        elseif cur and r.labelKey then cur.keys[#cur.keys + 1] = r.labelKey end
    end
    local names = {}
    for _, g in ipairs(groups) do names[#names + 1] = g.name .. " (" .. #g.keys .. ")" end
    say("groups: " .. table.concat(names, " | "))
    local fi
    for i, g in ipairs(groups) do if g.name:lower() == tr("UI_ZeD_Options_ZedForms"):lower() then fi = i end end
    if not check(fi ~= nil, "60: ZeD setup has the \"" .. tr("UI_ZeD_Options_ZedForms") .. "\" group") then return end
    check(fi == 2, "60: it comes right after " .. tostring(groups[1] and groups[1].name) .. " (group " .. fi .. ")")
    local got = groups[fi].keys
    say("60: its rows: " .. table.concat(got, ", "))
    local same = #got == #WANT
    for i = 1, #WANT do if got[i] ~= WANT[i] then same = false end end
    check(same, "110: Belt, Devices, Watch, Dashboard, Survival guide, Identity card, in that order")
    local strays = {}
    for i, g in ipairs(groups) do
        if i ~= fi then for _, k in ipairs(g.keys) do for _, wk in ipairs(WANT) do if k == wk then strays[#strays + 1] = g.name .. ":" .. k end end end end
    end
    check(#strays == 0, "60: no other group shows those rows (" .. table.concat(strays, ", ") .. ")")
    pcall(function() getCore():TakeFullScreenshot("mfs_group.png") end)
end)

-- the Preset
local pr
at(10, function()
    local w = O(); if not w then return end
    pr = find(w, "UI_ZeD_Settings_Preset")
    if not check(pr ~= nil, "60: the Preset row is there") then return end
    local names = {}
    for i = 1, #(pr.control.options or {}) do names[#names + 1] = i .. "=" .. label(pr.control, i) end
    say("60: preset items " .. table.concat(names, ", ") .. " | now " .. tostring(pr.control.selected))
    for _, k in ipairs(THREE) do rowsBy[k] = find(w, k); say("60: " .. k .. " now " .. tostring(rowsBy[k] and rowsBy[k].control.selected)) end
end)
local function presetTo(w, want)
    for _ = 1, 6 do
        if pr.control.selected == want then return end
        w:nudge(pr, (pr.control.selected or 1) < want and 1 or -1)
    end
end
local function three() local o = {}; for _, k in ipairs(THREE) do o[#o + 1] = rowsBy[k] and rowsBy[k].control.selected end; return o end
at(10, function()
    local w = O(); if not (w and pr) then return end
    presetTo(w, 3)
end)
at(20, function()
    local v = three()
    say("60: Vanilla Access: preset " .. tostring(pr.control.selected) .. " (" .. label(pr.control, pr.control.selected) .. ") | devices, watch, dash " .. table.concat(v, ", "))
    check(v[1] == 2 and v[2] == 2 and v[3] == 2, "60: Vanilla Access sets Devices, Watch and Dashboard to Simple")
    presetTo(O(), 2)
end)
at(20, function()
    local v = three()
    say("60: Vanilla Plus: preset " .. tostring(pr.control.selected) .. " (" .. label(pr.control, pr.control.selected) .. ") | devices, watch, dash " .. table.concat(v, ", "))
    check(v[1] == 1 and v[2] == 1 and v[3] == 1, "60: Vanilla Plus sets them to Full")
end)
for i, k in ipairs(THREE) do
    at(10, function()
        local w = O(); if not (w and rowsBy[k]) then return end
        presetTo(w, 2)
    end)
    at(10, function()
        local w = O(); if not (w and rowsBy[k]) then return end
        w:nudge(rowsBy[k], 1)
    end)
    at(20, function()
        local c = pr.control
        say("60: " .. k .. " to " .. tostring(rowsBy[k].control.selected) .. " by hand: preset " .. tostring(c.selected) .. " (" .. label(c, c.selected) .. ")")
        check(label(c, c.selected):lower():find(tr("UI_ZeD_Options_PresetCustom"):lower(), 1, true) ~= nil or c.selected == #c.options,
            "60: " .. k .. " picked by hand makes the Preset read Custom")
        local w = O(); w:nudge(rowsBy[k], -1)
    end)
end
at(10, function()
    local w = O(); if w then pcall(function() w:discardStay() end) end
end)
at(20, function()
    local v = three()
    say("60: after Discard: preset " .. tostring(pr and pr.control.selected) .. " | devices, watch, dash " .. table.concat(v, ", "))
    local w = O(); if w then pcall(function() w:close() end) end
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
    say("DONE")
end)

local function tick()
    t = t + 1
    local i = 1
    while steps[i] do
        if steps[i].n <= t then
            local ok, e = pcall(steps[i].fn)
            if not ok then say("ERR step: " .. tostring(e)) end
            table.remove(steps, i)
        else i = i + 1 end
    end
    if #steps == 0 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
