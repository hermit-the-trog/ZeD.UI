-- ZeDUI/tools/qa/default_accent_sim.lua  (Nov 10 2026, Build; punch list 127, PZ Teal is the default accent)
-- With no game running, the real Tokens.lua and Settings.lua run on Lua 5.1 against a stub of the game's ModOptions
-- (the stubs follow forms_phrase_sim.lua). It checks:
--   * a fresh install starts on PZ Teal: the boot theme, ZeD.currentAccent and the Accent color combo's default item
--   * a saved accent stays what it was: Orange (item 2) and every other item apply their own key, through the combo's
--     onChange with a new pick and with none (the stored value, as at game start and the main menu)
--   * a key that names nothing (an old or hand-edited save) falls back to PZ Teal, not Orange
--   * Orange is still one of the nine, and Teal's hover wash is Orange's 0.22 in Dark
-- What it can't show: the colors on screen, a real ModOptions.ini read by the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/default_accent_sim.lua
-- It prints FAIL lines and a last line "default_accent_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]default_accent_sim%.lua$", "")
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local SDIR = ROOT .. "42/media/lua/shared/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local dummy
dummy = setmetatable({}, {
    __index = function(_, k) if type(k) == "number" then return nil end return dummy end,
    __call = function() return dummy end,
    __concat = function(a, b) return tostring(a == dummy and "" or a) .. tostring(b == dummy and "" or b) end,
})
require = function() end
getText = function(k) return k end
getTextOrNull = function(k) return k end
getFileReader = function() return nil end   -- (no ModOptions.ini: a first run)

local opts = { dict = {}, order = {} }
local function newOption(id, kind)
    -- (element false: the options screen is closed, so a pick is read from the option's own value)
    local o = { id = id, kind = kind, items = {}, default = nil, value = nil, element = false }
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
-- what Tokens.lua reads from files that load before it: a 1080p root scale and ZeD's own fonts in their slots
ZeD = {
    Scale = { root = function() return 1 end },
    Text  = { checkRoleFonts = function() return false end, noFonts = true },   -- (no fonts, as on a server)
    Font  = { sdf = { sec = { font = 1 }, body = { font = 2 }, stat = { font = 3 }, head = { font = 4 }, title = { font = 5 } } },
}
setmetatable(_G, { __index = function() return dummy end })

local function load(dir, name)
    local f, err = loadfile(dir .. name)
    if not f then print("default_accent_sim: " .. tostring(err)); os.exit(1) end
    local ok, e = pcall(f)
    if not ok then print("default_accent_sim: " .. name .. ": " .. tostring(e)); os.exit(1) end
end

load(SDIR, "Tokens.lua")
-- ---------------------------------------------------------------------------
-- THE BOOT: before ModOptions has anything to say
-- ---------------------------------------------------------------------------
check("ZeD.DEFAULT_ACCENT is teal", ZeD.DEFAULT_ACCENT == "teal", ZeD.DEFAULT_ACCENT)
check("the boot theme is on teal", ZeD.currentAccent == "teal", ZeD.currentAccent)
check("the boot theme's accent is Teal's #47A18C", ZeD.T and ZeD.T.accent
      and math.abs(ZeD.T.accent.r - 0x47 / 255) < 1e-6 and math.abs(ZeD.T.accent.g - 0xA1 / 255) < 1e-6)

ZeD.tr = ZeD.tr or function(k) return k end
-- every theme apply is recorded, then passed through to the real one
local realApply = ZeD.applyTheme
local applied = {}
ZeD.applyTheme = function(b, a, s) applied[#applied + 1] = a; return realApply(b, a, s) end

load(CDIR, "Settings.lua")
setmetatable(_G, nil)

-- ---------------------------------------------------------------------------
-- THE COMBO
-- ---------------------------------------------------------------------------
local keys = ZeD.Settings and ZeD.Settings.accentKeys or {}
local combo = opts.dict.accentColor
check("the Accent color combo is registered", combo ~= nil)
check("nine accents, Orange still among them", #keys == 9 and keys[2] == "orange", table.concat(keys, ","))
local tealIdx
for i, k in ipairs(keys) do if k == "teal" then tealIdx = i end end
check("the combo's default item is PZ Teal", combo and tealIdx and combo.default == tealIdx,
      combo and (tostring(combo.default) .. " vs " .. tostring(tealIdx)))
check("the default item's label is PZ Teal's", combo and combo.items[combo.default or 0] == "UI_ZeD_Accent_Teal",
      combo and combo.items[combo.default or 0])
local defaults = 0
for i = 1, combo and #combo.items or 0 do if combo.default == i then defaults = defaults + 1 end end
check("exactly one default item", defaults == 1, defaults)

-- a fresh install: the combo holds its default, and the stored-values apply lands on teal
local function lastApplied() return applied[#applied] end
-- (reapplyFromOptions also sets the scale and the input lock, which stop on these stubs; an onChange with no new
-- index reads the stored value the same way, through the same applyFromOptions)
local function reapply() combo.onChange(combo, nil) end
do
    combo:setValue(combo.default)
    reapply()
    check("fresh install: reapply lands on teal", lastApplied() == "teal" and ZeD.currentAccent == "teal",
          tostring(lastApplied()) .. " / " .. tostring(ZeD.currentAccent))
end

-- a saved accent stays: every item applies its own key (Orange first, the one that used to be the default)
for i, k in ipairs(keys) do
    applied = {}
    combo.onChange(combo, i)
    check("onChange item " .. i .. " applies " .. k, lastApplied() == k and ZeD.currentAccent == k,
          tostring(lastApplied()) .. " / " .. tostring(ZeD.currentAccent))
end
do
    combo:setValue(2)
    applied = {}
    reapply()
    check("a saved Orange stays Orange on reapply", lastApplied() == "orange" and ZeD.currentAccent == "orange",
          tostring(lastApplied()) .. " / " .. tostring(ZeD.currentAccent))
    -- no value at all (the option missing from the file): the default, not Orange
    combo:setValue(nil)
    applied = {}
    reapply()
    check("no stored value falls back to teal", lastApplied() == "teal" and ZeD.currentAccent == "teal",
          tostring(lastApplied()) .. " / " .. tostring(ZeD.currentAccent))
    -- an index past the list (a save from a build with more items)
    combo:setValue(99)
    applied = {}
    reapply()
    check("an index past the list falls back to teal", ZeD.currentAccent == "teal", ZeD.currentAccent)
end

-- ---------------------------------------------------------------------------
-- THE FALLBACK IN applyTheme
-- ---------------------------------------------------------------------------
realApply("dark", "orange", "small")
check("applyTheme keeps orange when asked", ZeD.currentAccent == "orange", ZeD.currentAccent)
realApply("dark", "tangerine", "small")
check("a key that names nothing falls back to teal", ZeD.currentAccent == "teal", ZeD.currentAccent)

local AC = ZeD.AccentColors or {}
check("Teal's Dark hover wash is Orange's (0.22)", AC.teal and AC.orange
      and math.abs(AC.teal.dark.hover.a - AC.orange.dark.hover.a) < 1e-6,
      AC.teal and AC.teal.dark.hover.a)

print("default_accent_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
