-- ZeDUI/tools/qa/addon_options_sim.lua  (Nov 15 2026, add-on hooks: ZeD.Options.addGroup)
-- An add-on's own PZAPI.ModOptions shown as a group on ZeD setup. With no game running, the real
-- shared/ZeD/ModOptionsOwners.lua, shared/ZeD/AddonOptions.lua and client/ZeD/ZeD_MainMenuOptionGroups.lua
-- run on Lua 5.1 against a stub of the game's ModOptions (vanilla's shape: create, getOptions, load,
-- addComboBox, addTickBox) and a stub Mods page (a row per option, its control the option's element).
-- It checks:
--   SAME      nothing registered: ZeD setup's rows are the same as with no ZeD.Options at all, groups in order
--   API       VERSION 1; a call without owner or rows is refused with a log line, never an error; the colon call works
--   AFTER     a group with after = a ZeD group's title follows that group's rows
--   DEFAULT   a group with no after (or an after ZeD has no group for) sits just before Trouble
--   ROWS      a row takes ZeD's drawing (style, under, short, needs) and its owner; name and help come from
--             nameKey / tipKey, else the option's own name and tooltip; a tick box shows plain
--   LATE      a group added after the setup page was built shows on the next build (rev goes up), and one added
--             before its add-on made its options shows once they exist
--   MISSING   an owner or option that is not there: one log line each (not one per build), the row skipped
--   RESET     the add-on rows carry the item they started on (before the saved values were read), and
--             ZeD setup's Defaults puts them back
--   FIND      Find shows the add-on's options on ZeD setup, not again on the Mods page
-- Run from the repo root:  lua51 ZeDUI/tools/qa/addon_options_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]addon_options_sim%.lua$", "")
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local SDIR = ROOT .. "42/media/lua/shared/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        -- (io.write: print is caught below to count the files' log lines)
        io.write("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "") .. "\n")
    end
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
-- the console log: every line the files print is kept, to count the log lines
local logLines = {}
local realPrint = print
print = function(s) logLines[#logLines + 1] = tostring(s) end
local function logCount(word)
    local n = 0
    for _, l in ipairs(logLines) do if string.find(l, word, 1, true) then n = n + 1 end end
    return n
end

-- translations: a few keys known, the rest unknown (getTextOrNull answers nil, getText the key)
local WORDS = { UI_Addon_Group = "Multi-slot inventory", UI_Addon_SizesName = "Item sizes", UI_Addon_SizesTip = "Items take their own size.",
                UI_Addon_Tip = "A tooltip key.", UI_ServerSettingGroup_Other = "Other" }
getText = function(k) return WORDS[k] or k end
getTextOrNull = function(k) return WORDS[k] end
getFileReader = function() return nil end
ZeD = {}
ZeD.tr = function(k) return WORDS[k] or k end   -- (as the real one: a key it cannot find comes back as it is)
ZeD.btnCase = function(s) return s end

-- vanilla's ModOptions, reduced to what these files use
local saved = {}   -- the stub ModOptions.ini: optionsId -> { optionId -> item }
local function newOptions(id)
    local o = { modOptionsID = id, data = {}, dict = {} }
    function o:getOption(oid) return self.dict[oid] end
    function o:addComboBox(oid, name, tooltip)
        local opt = { type = "combobox", id = oid, name = name, tooltip = tooltip, values = {}, selected = 1 }
        function opt:addItem(text, sel) self.values[#self.values + 1] = text; if sel then self.selected = #self.values end end
        function opt:getValue() return self.selected end
        self.data[#self.data + 1] = opt; self.dict[oid] = opt
        return opt
    end
    function o:addTickBox(oid, name, value, tooltip)
        local opt = { type = "tickbox", id = oid, name = name, tooltip = tooltip, value = value }
        function opt:getValue() return self.value end
        self.data[#self.data + 1] = opt; self.dict[oid] = opt
        return opt
    end
    return o
end
PZAPI = { ModOptions = { Data = {}, Dict = {} } }
function PZAPI.ModOptions:create(id, name)
    local o = newOptions(id)
    self.Data[#self.Data + 1] = o; self.Dict[id] = o
    return o
end
function PZAPI.ModOptions:getOptions(id) return self.Dict[id] end
function PZAPI.ModOptions:load()
    for id, vals in pairs(saved) do
        local o = self.Dict[id]
        for oid, v in pairs(vals) do if o and o.dict[oid] then o.dict[oid].selected = v end end
    end
end

local function load(dir, name)
    local f, err = loadfile(dir .. name)
    if not f then realPrint("addon_options_sim: " .. tostring(err)); os.exit(1) end
    local ok, e = pcall(f)
    if not ok then realPrint("addon_options_sim: " .. name .. ": " .. tostring(e)); os.exit(1) end
    return e
end

load(SDIR, "ModOptionsOwners.lua")   -- (wraps create and load: notes each option's declared value before load)
load(CDIR, "ZeD_MainMenuOptionGroups.lua")
local G = ZeD.MainMenu.optionGroups

-- ZeD's own options: a few from four of its groups, as Settings.lua makes them (combos, zedNameKey, zedDefault)
local zo = PZAPI.ModOptions:create("ZeD_UI", "ZeD")
local function zedCombo(id, n, def)
    local o = zo:addComboBox(id, id)
    for i = 1, n do o:addItem(id .. i, i == def) end
    o.zedNameKey = "UI_ZeD_Settings_" .. id
    o.zedDefault = o.selected
    return o
end
zedCombo("baseTheme", 3, 1); zedCombo("accentColor", 9, 1)
zedCombo("inventoryView", 2, 1)
zedCombo("safeMode", 2, 1); zedCombo("testLanguage", 2, 1)

-- the add-on, made as an add-on's file would: its combos (the defaults marked), a tick box
local function addonOptions()
    local ao = PZAPI.ModOptions:create("ZeDMultiSlot", "Multi-slot")
    local sizes = ao:addComboBox("sizes", "Item sizes plain", "UI_Addon_Tip")
    sizes:addItem("Off"); sizes:addItem("On", true)
    local newItems = ao:addComboBox("newItems", "New items", "Plain words tooltip.")
    newItems:addItem("First free", true); newItems:addItem("Last"); newItems:addItem("Ask")
    local mark = ao:addComboBox("noFitMark", "No fit mark")
    mark:addItem("Off", true); mark:addItem("On")
    ao:addTickBox("showEmpty", "Show empty", true, "Tick tooltip.")
    return ao
end

-- the options screen as vanilla builds it: ModOptions:load (the saved values), then a control per option on the
-- Mods page; returns the pages and rowsOf the way ZeD_MainMenuOptions hands them to G.build
local modsRows
local function buildScreen()
    PZAPI.ModOptions:load()
    modsRows = {}
    for _, o in ipairs(PZAPI.ModOptions.Data) do
        for _, opt in ipairs(o.data) do
            local el
            if opt.type == "combobox" then el = { options = opt.values, selected = opt.selected }
            else el = { options = { opt.name }, selected = { opt.value } } end
            opt.element = el
            modsRows[#modsRows + 1] = { kind = (opt.type == "combobox") and "combo" or "tick", control = el, label = opt.name }
        end
    end
end
local pages = { { raw = "UI_mainscreen_mods" } }
local function rowsOf(p) if p.raw == "UI_mainscreen_mods" then return modsRows end return {} end
local function setup() return G.build(pages, rowsOf).zed end

-- a row's signature, and the list's: headers by words, option rows by their control's name and drawing
local function sig(rows)
    local t = {}
    for _, r in ipairs(rows) do
        if r.kind == "header" then t[#t + 1] = "#" .. tostring(r.text)
        else t[#t + 1] = tostring(r.label) .. "/" .. tostring(r.zedStyle) .. "/" .. tostring(r.zedDefault) .. "/" .. tostring(r.under) end
    end
    return table.concat(t, "|")
end
local function headers(rows)
    local t = {}
    for _, r in ipairs(rows) do if r.kind == "header" then t[#t + 1] = r.text end end
    return t
end
local function indexOf(list, v) for i, x in ipairs(list) do if x == v then return i end end return nil end
local function rowOf(rows, label) for _, r in ipairs(rows) do if r.kind ~= "header" and r.label == label then return r end end return nil end

-- ---------------------------------------------------------------------------
-- SAME: nothing registered
-- ---------------------------------------------------------------------------
buildScreen()
local before = sig(setup())                -- no ZeD.Options at all (the code before the hook)
load(SDIR, "AddonOptions.lua")
local O = ZeD.Options
local after0 = sig(setup())                -- ZeD.Options there, nothing added
check("SAME: nothing registered, ZeD setup's rows unchanged", before == after0, after0)
local h0 = headers(setup())
check("SAME: ZeD's groups in their order", table.concat(h0, ",") == "UI_ZeD_Options_ZedLook,UI_ZeD_Options_ZedWindows,UI_ZeD_Options_ZedTrouble",
      table.concat(h0, ","))
check("SAME: no log lines", #logLines == 0, table.concat(logLines, " / "))

-- ---------------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------------
check("API: VERSION is 1", O.VERSION == 1, O.VERSION)
check("API: no table is refused", O.addGroup(nil) == false)
check("API: no owner is refused", O.addGroup({ rows = {} }) == false)
check("API: no rows is refused", O.addGroup({ owner = "X" }) == false)
check("API: each refusal logs one line", logCount("[ZeD] Options:") == 3, #logLines)
check("API: nothing was added", #O.groups == 0 and O.rev == 0, #O.groups)

-- ---------------------------------------------------------------------------
-- LATE (before its options exist) and MISSING owner: registered now, the add-on makes its options later
-- ---------------------------------------------------------------------------
local ok = O:addGroup({ owner = "ZeDMultiSlot", title = "UI_Addon_Group", after = "UI_ZeD_Options_ZedLook", rows = {
    { "sizes", "onoff", nameKey = "UI_Addon_SizesName", tipKey = "UI_Addon_SizesTip" },
    { "newItems", "radio", short = { "UI_Addon_A", "UI_Addon_B", "UI_Addon_C" }, under = "UI_Addon_Under" },
    { "noFitMark", "onoff", needs = "sizes", needsWhy = "UI_Addon_NeedsSizes" },
    { "nope", "onoff" },
    { "showEmpty", "onoff" },
    "not a row",
} })
check("API: the colon call is taken", ok == true)
check("API: a row with no option id is logged and dropped", logCount("has no option id") == 1 and #O.groups[1].rows == 5)
check("LATE: rev went up", O.rev == 1, O.rev)
local s1 = setup()
check("MISSING: an owner with no options yet: no group, no error", indexOf(headers(s1), "Multi-slot inventory") == nil)
check("MISSING: the owner is logged once", logCount("no ModOptions with the id ZeDMultiSlot") == 1)
setup()
check("MISSING: and not again on the next build", logCount("no ModOptions with the id ZeDMultiSlot") == 1)

-- the add-on makes its options; the player had saved newItems = 3 and sizes = 1 (Off) in ModOptions.ini
addonOptions()
saved.ZeDMultiSlot = { newItems = 3, sizes = 1 }
buildScreen()
local s2 = setup()
local h2 = headers(s2)

-- ---------------------------------------------------------------------------
-- AFTER
-- ---------------------------------------------------------------------------
local iLook, iAdd, iWin = indexOf(h2, "UI_ZeD_Options_ZedLook"), indexOf(h2, "Multi-slot inventory"), indexOf(h2, "UI_ZeD_Options_ZedWindows")
check("AFTER: the group shows (title through ZeD.tr)", iAdd ~= nil, table.concat(h2, ","))
check("AFTER: right after Look, before Windows", iLook and iAdd == iLook + 1 and iWin == iAdd + 1, table.concat(h2, ","))

-- ---------------------------------------------------------------------------
-- MISSING option
-- ---------------------------------------------------------------------------
check("MISSING: the missing option is logged once", logCount("has no option nope") == 1)
setup()
check("MISSING: and not again on the next build", logCount("has no option nope") == 1)

-- ---------------------------------------------------------------------------
-- ROWS
-- ---------------------------------------------------------------------------
local rSizes, rNew, rMark, rTick = rowOf(s2, "Item sizes plain"), rowOf(s2, "New items"), rowOf(s2, "No fit mark"), rowOf(s2, "Show empty")
check("ROWS: four rows (the missing one skipped)", rSizes and rNew and rMark and rTick)
if rSizes and rNew and rMark and rTick then
    check("ROWS: the rows sit under the add-on's header, in its order", s2[indexOf(s2, rSizes) - 1].text == "Multi-slot inventory"
          and indexOf(s2, rNew) == indexOf(s2, rSizes) + 1 and indexOf(s2, rMark) == indexOf(s2, rNew) + 1 and indexOf(s2, rTick) == indexOf(s2, rMark) + 1)
    check("ROWS: styles as asked", rSizes.zedStyle == "onoff" and rNew.zedStyle == "radio" and rMark.zedStyle == "onoff")
    check("ROWS: under and short", rNew.under == "UI_Addon_Under" and rNew.zedShort and rNew.zedShort[3] == "UI_Addon_C")
    check("ROWS: needs, needsWhy and the owner (needsOff reads the add-on's own options)",
          rMark.zedNeeds == "sizes" and rMark.zedNeedsWhy == "UI_Addon_NeedsSizes" and rMark.zedOwner == "ZeDMultiSlot")
    check("ROWS: nameKey and tipKey", rSizes.labelKey == "UI_Addon_SizesName" and rSizes.zedTipKey == "UI_Addon_SizesTip" and rSizes.zedTip == nil)
    check("ROWS: no nameKey: the option's own name (labelKey nil, label as on the Mods page)", rNew.labelKey == nil and rNew.label == "New items")
    check("ROWS: no tipKey: the option's own tooltip, plain words as passed", rNew.zedTip == "Plain words tooltip.", rNew.zedTip)
    check("ROWS: a ZeD setup copy, marked as ZeD's own", rNew.setupCopy and rNew.zedOwn == true)
    check("ROWS: a tick box shows plain (no style, no default)", rTick.zedStyle == nil and rTick.zedDefault == nil and rTick.kind == "tick")
    check("ROWS: no ZeD screen named under an add-on row", rNew.zedBack == nil)
end
-- the Mods page rows stay (the add-on's options stay on the Mods page) and take the marks
local modsSizes
for _, r in ipairs(modsRows) do if r.label == "Item sizes plain" then modsSizes = r end end
check("ROWS: the Mods page keeps its row, marked as ZeD's own", modsSizes and modsSizes.zedOwn == true and modsSizes.zedTipKey == "UI_Addon_SizesTip")
-- ZeD's own rows are as they were
local zedOnly = {}
for _, r in ipairs(s2) do if not r.zedOwner and not (r.kind == "header" and r.text == "Multi-slot inventory") then zedOnly[#zedOnly + 1] = r end end
check("ROWS: ZeD's own rows unchanged around the group", sig(zedOnly) == before, sig(zedOnly))

-- ---------------------------------------------------------------------------
-- RESET to defaults: the declared items, not the saved ones
-- ---------------------------------------------------------------------------
check("RESET: sizes defaults to On (2), saved Off", rSizes and rSizes.zedDefault == 2 and rSizes.control.selected == 1, rSizes and rSizes.zedDefault)
check("RESET: newItems defaults to 1, saved 3", rNew and rNew.zedDefault == 1 and rNew.control.selected == 3, rNew and rNew.zedDefault)
-- ZeD_MMOptions:zedOffDefault and :zedDefaults, their loops over ZeD setup's rows (setCombo: c.selected = item)
local function offDefault(rows)
    for _, r in ipairs(rows) do if r.zedDefault and r.control and r.control.selected ~= r.zedDefault then return true end end
    return false
end
check("RESET: Defaults is offered (an add-on row is off its default)", offDefault(s2))
for _, r in ipairs(s2) do
    local c = r.control
    if r.zedDefault and c and not c.disabled and c.selected ~= r.zedDefault then c.selected = r.zedDefault end
end
check("RESET: Defaults puts them back", rSizes and rNew and rSizes.control.selected == 2 and rNew.control.selected == 1 and not offDefault(s2))
-- a row's default = wins over the declared one
O.addGroup({ owner = "ZeDMultiSlot", title = "UI_Addon_Group", after = "UI_ZeD_Options_ZedLook", rows = { { "newItems", "radio", default = 2 } } })
local sD = setup()
check("RESET: default = on the row wins", rowOf(sD, "New items") and rowOf(sD, "New items").zedDefault == 2)
check("API: the same owner and title replaces (one group)", #O.groups == 1 and #headers(sD) == 4, table.concat(headers(sD), ","))

-- ---------------------------------------------------------------------------
-- FIND: the add-on's options on ZeD setup only
-- ---------------------------------------------------------------------------
O.addGroup({ owner = "ZeDMultiSlot", title = "UI_Addon_Group", after = "UI_ZeD_Options_ZedLook", rows = { { "newItems", "radio" }, { "sizes", "onoff" } } })
local fpages = { { title = "Setup", setup = true, raw = "zed" }, { title = "Mods", raw = "mods" } }
local built = setup()
local function rowsFor(p) if p.setup then return built end return modsRows end
local found = G.findRows(fpages, rowsFor, "new items", function(r) return string.lower(tostring(r.label or "")) end)
check("FIND: found once, under ZeD setup", #found == 2 and found[1].text == "Setup" and found[2].label == "New items" and found[2].setupCopy,
      #found)

-- ---------------------------------------------------------------------------
-- DEFAULT place, an unknown after, LATE after the page was built
-- ---------------------------------------------------------------------------
local revBefore = O.rev
local built1 = setup()
local ao2 = PZAPI.ModOptions:create("Other", "Other add-on")
local x = ao2:addComboBox("x", "Other x"); x:addItem("A", true); x:addItem("B")
local y = ao2:addComboBox("y", "Other y"); y:addItem("A", true); y:addItem("B")
buildScreen()
O.addGroup({ owner = "Other", title = "Plain words title", rows = { { "x", "radio" } } })
O.addGroup({ owner = "Other", title = "Second", after = "UI_ZeD_Options_NoSuchGroup", rows = { { "y", "radio" } } })
check("LATE: rev went up after the page was built", O.rev == revBefore + 2)
local h3 = headers(setup())
local iT, iP, iS = indexOf(h3, "UI_ZeD_Options_ZedTrouble"), indexOf(h3, "Plain words title"), indexOf(h3, "Second")
check("LATE: the late groups show on the next build", iP ~= nil and iS ~= nil and #headers(built1) == 4, table.concat(h3, ","))
check("DEFAULT: no after: just before Trouble (plain words as they are)", iP and iT and iS == iP + 1 and iT == iS + 1, table.concat(h3, ","))
check("DEFAULT: an unknown after falls back before Trouble, logged once", logCount("no ZeD group UI_ZeD_Options_NoSuchGroup") == 1)
setup()
check("DEFAULT: and not logged again", logCount("no ZeD group UI_ZeD_Options_NoSuchGroup") == 1)
check("AFTER: the after group is still after Look", indexOf(h3, "Multi-slot inventory") == indexOf(h3, "UI_ZeD_Options_ZedLook") + 1)

-- ---------------------------------------------------------------------------
-- the files: ASCII only (Kahlua drops a literal's high bytes)
-- ---------------------------------------------------------------------------
for _, p in ipairs({ SDIR .. "AddonOptions.lua", CDIR .. "ZeD_MainMenuOptionGroups.lua" }) do
    local f = io.open(p, "rb"); local s = f:read("*a"); f:close()
    check("ASCII: " .. p, not s:find("[\128-\255]"))
end

print = realPrint
print("addon_options_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
