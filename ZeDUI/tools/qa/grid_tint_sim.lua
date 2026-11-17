-- ZeDUI/tools/qa/grid_tint_sim.lua
-- (the director, Nov 16 2026) Item-colored grid tiles: with "Item-colored tiles" on (ZeD setup, Look) a grid tile's
-- fill is a soft tint of its item's main color in place of T.stripe. Runs the REAL GridTint.lua, the REAL baked
-- ItemTints.lua, the REAL option from Settings.lua (on a stub of ModOptions) and the REAL fill lines cut out of
-- InventoryRenderer's drawGridCell, with a stub panel that records each drawRect.
--   OPTION   registered, Off for a new player, named for the Look group, a check box there, in all 28 UI.json files
--   OFF      the tile draws T.stripe, as before
--   ON       a known item (the axe, the CD) draws a tint, per theme: Light pale (lightness 0.74), Dark and High
--            contrast deep (0.21, 0.16); its hue is the item's (the axe red, the CD blue); saturation capped
--   UNKNOWN  another mod's item, a gray icon, no texture: the plain stripe
--   RANGE    every baked color under every rule stays within 0 to 1 and on the rule's lightness
-- Run from the repo root:  lua51 ZeDUI/tools/qa/grid_tint_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]grid_tint_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readSrc(p) local fh = assert(io.open(ROOT .. p, "rb")); local s = fh:read("*a"):gsub("\r\n", "\n"); fh:close(); return s end

ZeD = { tr = function(k) return k end }
function getText(k) return k end
function require() end
STORE = {}

-- the real option, as health_dot_sim loads it
local function loadSettings()
    local dummy
    dummy = setmetatable({}, {
        __index = function(_, k) if type(k) == "number" then return nil end return dummy end,
        __call = function() return dummy end,
        __concat = function(a, b) return tostring(a == dummy and "" or a) .. tostring(b == dummy and "" or b) end,
    })
    local opts = { dict = {} }
    local function newOption(id)
        local o = { id = id, items = {}, element = false }
        function o:addItem(text, selected)
            self.items[#self.items + 1] = text
            if selected then self.default = #self.items; self.value = STORE[id] or #self.items end
        end
        function o:getValue() return self.value end
        function o:setValue(v) self.value = v end
        return setmetatable(o, { __index = function() return function() return dummy end end })
    end
    setmetatable(opts, { __index = function(_, name)
        return function(self, id)
            local o = newOption(id)
            if type(id) == "string" then self.dict[id] = o end
            return o
        end
    end })
    OPTS = opts
    local env = setmetatable({
        PZAPI = { ModOptions = { create = function() return opts end, save = function()
            for id, o in pairs(opts.dict) do STORE[id] = o.value end
        end } },
        getFileReader = function() return nil end,
        getTextOrNull = function(k) return k end,
    }, { __index = function(_, k) local g = _G[k]; if g ~= nil then return g end return dummy end })
    ZeD.Settings = nil
    local sf, serr = loadfile(CLIENT .. "Settings.lua")
    if not sf then error(serr) end
    setfenv(sf, env)
    local ok, e = pcall(sf)
    if not ok then error("Settings.lua: " .. tostring(e)) end
end
loadSettings()
local S = ZeD.Settings
local gt = OPTS.dict.gridTint
check("OPTION: Settings.lua registers gridTint", gt ~= nil)
check("OPTION: Off then On, Off the default", gt and #gt.items == 2 and gt.default == 1, gt and gt.default)
check("OPTION: read through ZeD.Settings.gridTint, off for a new player", S.gridTint and S.gridTint() == false)
check("OPTION: ZeD setup names it", gt and gt.zedNameKey == "UI_ZeD_Settings_GridTint", gt and gt.zedNameKey)
do
    local g = readSrc("42/media/lua/client/ZeD/ZeD_MainMenuOptionGroups.lua")
    local look = g:match('"UI_ZeD_Options_ZedLook",(.-)\n    %-%-')
    check("OPTION: the Look group lists it as a check box", look ~= nil and look:find('{ "gridTint", "onoff" }', 1, true) ~= nil)
    local missing = 0
    for _, l in ipairs({ "AR","CA","CH","CN","CS","DA","DE","EN","ES","ES_CL","ES_MX","FI","FR","HU","ID","IT","JP","KO","NL","NO","PL","PT","PTBR","RO","RU","TH","TR","UA" }) do
        local t = readSrc("42/media/lua/shared/Translate/" .. l .. "/UI.json")
        if not (t:find('"UI_ZeD_Settings_GridTint": "', 1, true) and t:find('"UI_ZeD_Settings_GridTintTip": "', 1, true)) then missing = missing + 1 end
    end
    check("OPTION: its name and help line are in all 28 UI.json files", missing == 0, missing)
end

-- the real data and helper
dofile(ROOT .. "42/media/lua/shared/ZeD/ItemTints.lua")
dofile(CLIENT .. "GridTint.lua")
local G = ZeD.GridTint
check("DATA: the baked table loads, with the axe and the CD", ZeD.ItemTints and ZeD.ItemTints.Axe and ZeD.ItemTints.Disc)

-- the real fill lines of drawGridCell, from the icon's texture to the frame
local ir = readSrc("42/media/lua/client/ZeD/InventoryRenderer.lua")
local cell = ir:match("\nlocal function drawGridCell%(.-\nend\n")
local fill = cell and cell:match("\n(    local tex = item:getTex%(%)\n.-)\n    self:drawRectBorder")
check("finds drawGridCell's fill", fill ~= nil)
local drawFill = assert(loadstring("local self, T, item, ax, cy, cw, ch = ...\n" .. (fill or "")))
local function newPanel() local p = { rects = {} }; function p:drawRect(x, y, w, h, a, r, g, b) self.rects[#self.rects + 1] = { a = a, r = r, g = g, b = b } end; return p end
local function tex(name) return { getName = function() return name end } end
local TEX = { axe = tex("Item_Axe"), cd = tex("Item_Disc"), mod = tex("Item_SomeModsThing"), gray = tex("Item_Wrench"),
              loose = tex("media\\textures\\weapons\\2handed\\Item_Axe.png") }
local function item(t) return { getTex = function() return t end } end
local function rgba(r, g, b, a) return { r = r, g = g, b = b, a = a } end
local THEMES = {
    dark  = { baseKey = "dark", stripe = rgba(1, 1, 1, 0.04), surf1 = rgba(0.078, 0.078, 0.078, 0.92) },
    light = { baseKey = "light", stripe = rgba(0, 0, 0, 0.05), surf1 = rgba(0.745, 0.745, 0.745, 0.97) },
    hicon = { baseKey = "hicon", stripe = rgba(1, 1, 1, 0.06), surf1 = rgba(0.067, 0.067, 0.067, 0.95) },
}
local function fillOf(T, it)
    local p = newPanel()
    drawFill(p, T, it, 0, 0, 52, 52)
    return p.rects[1], #p.rects
end
local function isStripe(r, T) return r and r.a == T.stripe.a and r.r == T.stripe.r and r.g == T.stripe.g and r.b == T.stripe.b end
local function lightness(r) local mx, mn = math.max(r.r, r.g, r.b), math.min(r.r, r.g, r.b); return (mx + mn) / 2 end

-- OFF (the default)
for k, T in pairs(THEMES) do
    local r, n = fillOf(T, item(TEX.axe))
    check("OFF " .. k .. ": the axe's tile draws the plain stripe, once", isStripe(r, T) and n == 1, r and r.a)
end

-- ON
S.setGridTint(true)
check("ON: the pick reads on", S.gridTint() == true and G.on() == true)
for k, T in pairs(THEMES) do
    local r = fillOf(T, item(TEX.axe))
    check("ON " .. k .. ": the axe's tile is a tint, not the stripe", r and not isStripe(r, T))
    check("ON " .. k .. ": drawn at the surface's alpha", r and r.a == T.surf1.a, r and r.a)
    check("ON " .. k .. ": on the rule's lightness", r and math.abs(lightness(r) - G.RULES[k].l) < 0.005, r and lightness(r))
    check("ON " .. k .. ": the axe reads red (red the largest)", r and r.r > r.g and r.r > r.b)
    local c = fillOf(T, item(TEX.cd))
    check("ON " .. k .. ": the CD reads blue (blue the largest)", c and c.b > c.r and c.b > c.g)
    local l = fillOf(T, item(TEX.loose))
    check("ON " .. k .. ": a loose file's texture (named by its path) finds its color", l and r and math.abs(l.r - r.r) < 1e-9)
end
do
    local lt, dk, hc = fillOf(THEMES.light, item(TEX.axe)), fillOf(THEMES.dark, item(TEX.axe)), fillOf(THEMES.hicon, item(TEX.axe))
    check("ON: Light is pale, Dark deep, High contrast deeper still", lightness(lt) > 0.7 and lightness(dk) < 0.25 and lightness(hc) < lightness(dk))
end
-- a theme change shows at once: the same texture under another baseKey
do
    local T = { baseKey = "dark", stripe = THEMES.dark.stripe, surf1 = THEMES.dark.surf1 }
    local a = fillOf(T, item(TEX.axe))
    T.baseKey = "light"
    local b = fillOf(T, item(TEX.axe))
    check("ON: a theme change takes at once (no stale color)", a and b and lightness(b) > lightness(a) + 0.4)
    T.baseKey = "someNewTheme"
    local c = fillOf(T, item(TEX.axe))
    check("ON: an unknown theme takes Dark's rule", c and math.abs(lightness(c) - G.RULES.dark.l) < 0.005)
end

-- UNKNOWN: plain stripe
for k, T in pairs(THEMES) do
    check("UNKNOWN " .. k .. ": another mod's item keeps the stripe", isStripe(fillOf(T, item(TEX.mod)), T))
    check("UNKNOWN " .. k .. ": a gray icon (the wrench) keeps the stripe", isStripe(fillOf(T, item(TEX.gray)), T))
    check("UNKNOWN " .. k .. ": no texture keeps the stripe", isStripe(fillOf(T, item(nil)), T))
end
check("UNKNOWN: a texture whose getName throws keeps the stripe",
    isStripe(fillOf(THEMES.dark, item({ getName = function() error("java") end })), THEMES.dark))

-- OFF again: back to the stripe at once (the cache holds colors, never the switch)
S.setGridTint(false)
check("OFF again: the axe is plain at once", isStripe(fillOf(THEMES.light, item(TEX.axe)), THEMES.light))

-- RANGE: every baked color under every rule
do
    local bad, n, worstS = 0, 0, 0
    for _, raw in pairs(ZeD.ItemTints) do
        n = n + 1
        if type(raw) ~= "number" or raw < 0 or raw > 16777215 or raw ~= math.floor(raw) then bad = bad + 1 end
        for key, rule in pairs(G.RULES) do
            local r, g, b = G.apply(raw, rule)
            local mx, mn = math.max(r, g, b), math.min(r, g, b)
            local l = (mx + mn) / 2
            local s = (mx == mn) and 0 or ((l <= 0.5) and (mx - mn) / (mx + mn) or (mx - mn) / (2 - mx - mn))
            if r < 0 or r > 1 or g < 0 or g > 1 or b < 0 or b > 1 or math.abs(l - rule.l) > 1e-6 or s > rule.s + 1e-6 then
                bad = bad + 1
            end
            if s - rule.s > worstS then worstS = s - rule.s end
        end
    end
    check("RANGE: " .. n .. " colors x 3 rules, all within 0..1, on the rule's lightness, saturation capped", bad == 0 and n > 1000, bad)
    check("RANGE: pure gray, black, white stay gray at the rule's lightness",
        select(1, G.apply(0x808080, G.RULES.light)) == 0.74 and select(3, G.apply(0, G.RULES.dark)) == 0.21 and select(2, G.apply(0xFFFFFF, G.RULES.hicon)) == 0.16)
end
-- KEY
check("KEY: Item_Axe -> Axe; a path and .png stripped", G.key("Item_Axe") == "Axe" and G.key("media/textures/Item_Axe.png") == "Axe"
    and G.key("C:\\x\\Item_Axe.PNG") == "Axe" and G.key(nil) == nil and G.key("") == nil)

print("grid_tint_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
