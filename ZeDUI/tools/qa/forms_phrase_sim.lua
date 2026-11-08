-- ZeDUI/tools/qa/forms_phrase_sim.lua  (Nov 7 2026, Build; punch list 110, one phrase for the two forms)
-- With no game running, the real Settings.lua and ZeD_MainMenuOptionGroups.lua run on Lua 5.1 against a stub of the
-- game's ModOptions, and the English UI.json is read as text. It checks:
--   * ZeD setup's sections: "Immersive or simple" holds Belt, Devices, Watch, Dashboard, Survival guide and Identity
--     card, in that order; Look no longer holds the Identity card; the Action bar sits in HUD; Context menu, Equipped
--     items and the Mods screen sit in Windows, Context menu and Equipped items right after Inventory; every row once
--   * the labels: the six take UI_ZeD_Settings_Immersive, the Action bar and the Mods screen the Detailed key; the
--     English reads Immersive / Detailed, and each help line names its two forms
--   * saved choices keep their values: every moved option has the same items in the same order with the same default
--     (item 1 the rich form, item 2 Simple; Context menu and Equipped items as they were), and the additions' presets
--     still set the same items (Vanilla Access picks Simple)
-- What it can't show: the rows drawn on screen, the other languages read in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/forms_phrase_sim.lua
-- It prints FAIL lines and a last line "forms_phrase_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]forms_phrase_sim%.lua$", "")
local ZDIR = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE STUBS: anything the files touch at load that this sim does not care about is a do-nothing object
-- ---------------------------------------------------------------------------
local dummy
dummy = setmetatable({}, {
    __index = function(_, k) if type(k) == "number" then return nil end return dummy end,   -- (ipairs ends)
    __call = function() return dummy end,
    __concat = function(a, b) return tostring(a == dummy and "" or a) .. tostring(b == dummy and "" or b) end,
})
require = function() end
getText = function(k) return k end
getTextOrNull = function(k) return k end
getFileReader = function() return nil end   -- (no ModOptions.ini: a first run)

-- ModOptions: an option keeps its items as the keys they were made with (ZeD.tr hands back the key)
local opts = { dict = {}, order = {} }
local function newOption(id, kind)
    local o = { id = id, kind = kind, items = {}, default = nil, value = nil }
    function o:addItem(text, selected)
        self.items[#self.items + 1] = text
        if selected then self.default = #self.items; self.value = #self.items end
    end
    function o:getValue() return self.value end
    function o:setValue(v) self.value = v end
    function o:setEnabled() end
    return setmetatable(o, { __index = function() return function() return dummy end end })
end
setmetatable(opts, { __index = function(_, name)
    return function(self, id, ...)
        local o = newOption(id, name)
        if type(id) == "string" then self.dict[id] = o; self.order[#self.order + 1] = id end
        return o
    end
end })
PZAPI = { ModOptions = { create = function() return opts end, save = function() end } }
ZeD = { tr = function(k) return k end }
setmetatable(_G, { __index = function() return dummy end })

local function load(name)
    local f, err = loadfile(ZDIR .. name)
    if not f then print("forms_phrase_sim: " .. tostring(err)); os.exit(1) end
    local ok, e = pcall(f)
    if not ok then print("forms_phrase_sim: " .. name .. ": " .. tostring(e)); os.exit(1) end
end
load("Settings.lua")
load("ZeD_MainMenuOptionGroups.lua")
setmetatable(_G, nil)

-- ---------------------------------------------------------------------------
-- THE SECTIONS
-- ---------------------------------------------------------------------------
local G = ZeD.MainMenu and ZeD.MainMenu.optionGroups
check("the option groups load", G and G.ZED_GROUPS)
local where, rows, count = {}, {}, {}
for _, g in ipairs(G and G.ZED_GROUPS or {}) do
    rows[g[1]] = {}
    for i, r in ipairs(g[2] or {}) do
        rows[g[1]][i] = r[1]
        where[r[1]] = g[1]
        count[r[1]] = (count[r[1]] or 0) + 1
    end
end
local function list(t) return table.concat(t or {}, ", ") end
local FORMS = { "beltStyle", "devicesStyle", "watchStyle", "dashStyle", "guideStyle", "identityStyle" }
check("Immersive or simple holds the six, in order", list(rows.UI_ZeD_Options_ZedForms) == list(FORMS),
      list(rows.UI_ZeD_Options_ZedForms))
check("the Identity card has left Look", where.identityStyle == "UI_ZeD_Options_ZedForms", where.identityStyle)
check("the Action bar sits in HUD", where.actionBar == "UI_ZeD_Options_ZedHud", where.actionBar)
check("the Mods screen sits in Windows", where.modsStyle == "UI_ZeD_Options_ZedWindows", where.modsStyle)
local win = rows.UI_ZeD_Options_ZedWindows or {}
check("Windows: Inventory, Context menu, Equipped items lead", win[1] == "inventoryView" and win[2] == "contextStyle"
      and win[3] == "equipView", list(win))
for _, id in ipairs({ "beltStyle", "devicesStyle", "watchStyle", "dashStyle", "guideStyle", "identityStyle", "actionBar",
                      "modsStyle", "contextStyle", "equipView", "inventoryView" }) do
    check(id .. " shows in one section", count[id] == 1, count[id])
end

-- ---------------------------------------------------------------------------
-- THE LABELS AND THE SAVED VALUES
-- ---------------------------------------------------------------------------
local function items(id) local o = opts.dict[id]; return o and list(o.items) or "(none)" end
local function default(id) local o = opts.dict[id]; return o and o.default end
local IMM = "UI_ZeD_Settings_Immersive, UI_ZeD_Settings_ActionBarSimple"
local DET = "UI_ZeD_Settings_ActionBarVerbose, UI_ZeD_Settings_ActionBarSimple"
for _, id in ipairs(FORMS) do
    check(id .. ": Immersive then Simple", items(id) == IMM, items(id))
    check(id .. ": default item 1", default(id) == 1, default(id))
end
for _, id in ipairs({ "actionBar", "modsStyle" }) do
    check(id .. ": Detailed then Simple", items(id) == DET, items(id))
    check(id .. ": default item 1", default(id) == 1, default(id))
end
check("contextStyle keeps its items", items("contextStyle") == "UI_ZeD_Settings_ContextStrip, UI_ZeD_Settings_ViewList"
      and default("contextStyle") == 1, items("contextStyle") .. " / " .. tostring(default("contextStyle")))
check("equipView keeps its items", items("equipView") == "UI_ZeD_Settings_ViewList, UI_ZeD_Settings_ViewDoll"
      and default("equipView") == 1, items("equipView") .. " / " .. tostring(default("equipView")))

local P = ZeD.Settings and ZeD.Settings.ADDITION_PRESETS
check("the presets load", P and P[2] and P[3])
for _, id in ipairs({ "devicesStyle", "watchStyle", "dashStyle", "guideStyle", "modsStyle", "identityStyle" }) do
    check("Vanilla Plus keeps " .. id .. " on item 1", P and P[2] and P[2][id] == 1, P and P[2] and P[2][id])
    check("Vanilla Access picks Simple for " .. id, P and P[3] and P[3][id] == 2, P and P[3] and P[3][id])
end

-- ---------------------------------------------------------------------------
-- THE ENGLISH
-- ---------------------------------------------------------------------------
local f = io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb")
local en = f and f:read("*a") or ""
if f then f:close() end
local function s(k) return en:match('"' .. k .. '"%s*:%s*"(.-)"%s*,?\r?\n') end
check("the section reads Immersive or simple", s("UI_ZeD_Options_ZedForms") == "Immersive or simple", s("UI_ZeD_Options_ZedForms"))
check("Immersive reads Immersive", s("UI_ZeD_Settings_Immersive") == "Immersive", s("UI_ZeD_Settings_Immersive"))
check("Detailed reads Detailed", s("UI_ZeD_Settings_ActionBarVerbose") == "Detailed", s("UI_ZeD_Settings_ActionBarVerbose"))
for _, k in ipairs({ "Belt", "Devices", "WatchStyle", "Dash", "Guide", "Identity" }) do
    local t = s("UI_ZeD_Settings_" .. k .. "Tip") or ""
    check(k .. "Tip: Immersive: ... Simple: ...", t:find("Immersive: ", 1, true) and t:find("Simple: ", 1, true)
          and not t:find("Full: ", 1, true), t)
end
for _, k in ipairs({ "ActionBar", "Mods" }) do
    local t = s("UI_ZeD_Settings_" .. k .. "Tip") or ""
    check(k .. "Tip: Detailed: ... Simple: ...", t:find("Detailed: ", 1, true) and t:find("Simple: ", 1, true)
          and not t:find("Verbose", 1, true) and not t:find("Full: ", 1, true), t)
end
for _, k in ipairs({ "UI_ZeD_GCh_zed_setup_Title", "UI_ZeD_GCh_zed_setup_Text", "UI_ZeD_GCh_whatsnew_beta3_Text" }) do
    local t = s(k) or ""
    check(k .. " says Immersive, not Full", t:find("Immersive", 1, true) and not t:find("Full", 1, true), t)
end

print("forms_phrase_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
