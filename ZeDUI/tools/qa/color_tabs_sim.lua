-- ZeDUI/tools/qa/color_tabs_sim.lua  (Nov 25 2026, Build; the director: "build the icons for the tabs and add the
-- color to the containers", mock-up ZeDUI/mockups/container_tabs_color_v4.html)
--   STRIP  ZeD.GridTint.stripFill / stripCell (the real file): each container button takes the stronger tint of its
--          picture's color (ContainerTints, ItemTints, else neutral gray); the shown one the wash and the frame
--   TABS   ZeD.TabPx.colorSet: the Dark set on Dark and High contrast, the Light set on Light, and on the lit panel
--          the set that stands off it better; every one of the 14 tabs has its art and pictures
--   WIRED  both windows' container buttons draw through stripCell
-- Run from the repo root:  lua51 ZeDUI/tools/qa/color_tabs_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]color_tabs_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local SH = ROOT .. "42/media/lua/shared/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function has(s, x) return string.find(s, x, 1, true) ~= nil end
local function exists(p) local f = io.open(p, "rb"); if f then f:close(); return true end; return false end

local function lum(c)
    local function ch(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b)
end
ZeD = { contrast = function(a, b) local l1, l2 = lum(a), lum(b); if l1 < l2 then l1, l2 = l2, l1 end; return (l1 + 0.05) / (l2 + 0.05) end }
local ACC = { r = 0.83, g = 0.57, b = 0.16 }
ZeD.T = { baseKey = "dark", accent = ACC, accentBright = { r = 0.95, g = 0.70, b = 0.30 }, selectionA = 0.30,
          hover = { r = 1, g = 1, b = 1, a = 0.08 }, px = function(n) return n end }
ZeD.Settings = {}

print("-- STRIP")
assert(loadfile(SH .. "ItemTints.lua"))()
assert(loadfile(SH .. "ContainerTints.lua"))()
assert(loadfile(Z .. "GridTint.lua"))()
local G = ZeD.GridTint
local function tex(name) return { getName = function() return name end } end
check("STRIP: the crate's color from ContainerTints", G.stripRaw(tex("media/ui/Container_Crate.png")) == ZeD.ContainerTints.Container_Crate)
check("STRIP: the main inventory's pocket", G.stripRaw(tex("Container_Pocket")) == 0x536683)
local bagKey
for k in pairs(ZeD.ItemTints) do bagKey = k; break end
check("STRIP: a bag's item icon from ItemTints", G.stripRaw(tex("Item_" .. bagKey)) == ZeD.ItemTints[bagKey])
check("STRIP: an unknown picture: neutral gray", G.stripRaw(tex("SomeModBag")) == 0x808080)
local r, g, b = G.stripFill(ZeD.T, tex("Container_Crate"))
local gr, gg, gb = G.apply(ZeD.ContainerTints.Container_Crate, G.RULES.dark)
check("STRIP: Dark's stronger tint is lighter than the grid's", (r + g + b) > (gr + gg + gb))
local draws = {}
local panel = { drawRect = function(_, x, y, w, h, a, rr, gg2, bb) draws[#draws + 1] = { x = x, y = y, w = w, h = h, a = a } end }
G.stripCell(panel, 0, 0, 40, 40, tex("Container_Crate"), false, false)
check("STRIP: not shown: the tint alone", #draws == 1 and draws[1].a == 1)
draws = {}
G.stripCell(panel, 0, 0, 40, 40, tex("Container_Crate"), true, false)
check("STRIP: shown: the tint, the wash and four frame sides", #draws == 6 and draws[2].a == 0.30 and draws[3].h == 2)
draws = {}
G.stripCell(panel, 0, 0, 40, 40, tex("Container_Crate"), false, true)
check("STRIP: hovered: the tint and the hover wash", #draws == 2 and draws[2].a == 0.08)

print("-- TABS")
assert(loadfile(Z .. "ZeD_TabColorArt.lua"))()
local TABS = { "loot", "equip", "health", "thermal", "identity", "journal", "skills", "craft", "build", "furniture", "maps", "forage", "animals", "vehicle" }
for _, id in ipairs(TABS) do
    local a = ZeD.TabColorArt[id]
    check("TABS: " .. id .. ": art with two sets of three colors", a and #a.dark == 3 and #a.light == 3)
    local d = ROOT .. "42/media/textures/ZeD/TabIcons/color/" .. id
    check("TABS: " .. id .. ": its three pictures", exists(d .. ".png") and exists(d .. "_light.png") and exists(d .. "_sh.png"))
end
-- colorSet, cut from ZeD_TabPx.lua
local TPsrc = readFile(Z .. "ZeD_TabPx.lua")
local a1 = string.find(TPsrc, "local function share(set, bg)", 1, true)
local a2 = string.find(TPsrc, "\n-- the icon centred on (cx, cy)", 1, true)
check("TABS: colorSet found", a1 and a2)
if a1 and a2 then
    local src = "local TP, shade = ...\n" .. string.sub(TPsrc, a1, a2)
    local fn, e = loadstring(src, "colorSet")
    check("TABS: colorSet loads", fn ~= nil, e)
    if fn then
        local TP = {}
        fn(TP, function(out, c, f) out.r, out.g, out.b = c.r * f, c.g * f, c.b * f; return out end)
        ZeD.T.baseKey = "dark"
        check("TABS: Dark: the Dark set", TP.colorSet("health", false) == "dark")
        ZeD.T.baseKey = "hicon"
        check("TABS: High contrast: the Dark set", TP.colorSet("health", false) == "dark")
        ZeD.T.baseKey = "light"
        check("TABS: Light: the Light set", TP.colorSet("health", false) == "light")
        check("TABS: a tab with no color art: none (the accent tones)", TP.colorSet("radio", false) == nil)
        ZeD.T.baseKey = "dark"
        local s = TP.colorSet("journal", true)
        local bg = { r = ACC.r * 0.85, g = ACC.g * 0.85, b = ACC.b * 0.85 }
        local other = (s == "dark") and "light" or "dark"
        check("TABS: on the lit panel: the set standing off it better", TP._colorShare(ZeD.TabColorArt.journal[s], bg) >= TP._colorShare(ZeD.TabColorArt.journal[other], bg))
    end
end
check("TABS: drawIcon draws the color picture and its shadow", has(TPsrc, "el:drawTextureScaled(pic, ix, iy, sz, sz, 1, 1, 1, 1)"))

print("-- WIRED")
local CW = readFile(Z .. "ZeD_CharacterWindow.lua")
local WW = readFile(Z .. "ZeD_WorldWindow.lua")
check("WIRED: the Character window's two kinds of button", select(2, string.gsub(CW, "ZeD.GridTint.stripCell%(self", "")) == 2)
check("WIRED: the World window's two kinds of button", select(2, string.gsub(WW, "ZeD.GridTint.stripCell%(self", "")) == 2)

print("color_tabs_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
