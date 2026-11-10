-- ZeDUI/tools/qa/menu_marks_sim.lua  (Nov 10 2026, Build; punch list 138, the menu marks and the new icons)
-- With no game running. Each part loads the REAL files on stubs:
--   TABLE  ContextPxIcons.lua: ZeD.PxIconMark names only "add" or "remove"; every marked icon has its picture and its
--          mark's picture (zw_<id>_mk.png) at 16, 24, 32 and 48; every icon the menu table names has its pictures
--   NAMES  ContextMenuRegistry.lua with ContextIcons.lua: the three safehouse rows get the boarded-up house (claim,
--          release, view), Eat and its parts get the eat figure, Reinforce keeps its shield
--   DRAW   Tokens.lua and Atoms.lua: ZeD.Ctx.markAdd is #0B63B0 and markRemove #C2410C; drawPxIcon with marks draws
--          the icon in its tint and then the mark's picture, the same size, in the mark's color (blue for add, red for
--          remove); without marks, or for an icon with no mark, only the icon
--   LIST   each base theme's own pair for the list menu (T.marks: Dark and High contrast #4491E2 / #D9572A, Light
--          #014E8E / #872801), and drawPxIcon given a pair draws in it
--   CELL   Molecules.lua's drawContextCell (the strip's cell, which the wheels draw too): at rest a ZeD icon's mark is
--          colored; the pointed cell draws the whole icon in the accent's text color; a colored picture (not ZeD's)
--          gets no mark
-- What it can't show: the colors on screen (QA at 1x and 1.75x), the pixels of the pictures (wheelpx/marks.py checks
-- those: every mark pixel is on its icon, and a mark is part of the icon, not all of it).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/menu_marks_sim.lua
-- It prints FAIL lines and a last line "menu_marks_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]menu_marks_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local SHARED = ROOT .. "42/media/lua/shared/ZeD/"
local MEDIA = ROOT .. "42/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local stub
stub = setmetatable({}, {
    __index = function(_, k) if type(k) == "number" then return nil end return stub end,
    __call = function() return stub end,
    __concat = function(a, b) return tostring(a == stub and "" or a) .. tostring(b == stub and "" or b) end,
})
function require() end
local function load(path)
    local fn, err = loadfile(path)
    if not fn then return false, err end
    return pcall(fn)
end
local function exists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true end
    return false
end
local SIZES = { 16, 24, 32, 48 }
local function pic(size, name) return MEDIA .. "media/textures/ZeD/wheel/" .. size .. "/zw_" .. name .. ".png" end

-- ---------------------------------------------------------------------------
-- TABLE
-- ---------------------------------------------------------------------------
ZeD = {}
local okP, errP = load(SHARED .. "ContextPxIcons.lua")
check("TABLE: ContextPxIcons.lua loads", okP, errP)
local MARK = ZeD.PxIconMark or {}
local nMarks = 0
for id, kind in pairs(MARK) do
    nMarks = nMarks + 1
    check("TABLE: " .. id .. " is add or remove", kind == "add" or kind == "remove", kind)
    for _, s in ipairs(SIZES) do
        check("TABLE: " .. id .. " has its " .. s, exists(pic(s, id)))
        check("TABLE: " .. id .. " has its mark at " .. s, exists(pic(s, id .. "_mk")))
    end
end
check("TABLE: 52 icons take a mark", nMarks == 52, nMarks)
-- the handoff's pairs, both sides
local PAIRS = {
    { "plus", "minus" }, { "equip", "unequip" }, { "tray_in", "tray_out" }, { "mag_in", "mag_out" },
    { "rounds_in", "rounds_out" }, { "battery_in", "battery_out" }, { "fill", "empty" },
    { "safehouse_claim", "safehouse_release" }, { "car_enter", "car_exit" }, { "window_open", "window_close" },
    { "zoom_in", "zoom_out" }, { "move_up", "move_down" }, { "box_up", "box_down" }, { "autowalk", "autowalk_off" },
    { "outfit_add", "outfit_remove" }, { "loadout_add", "loadout_remove" },
}
for _, p in ipairs(PAIRS) do
    check("TABLE: " .. p[1] .. " is blue", MARK[p[1]] == "add", MARK[p[1]])
    check("TABLE: " .. p[2] .. " is red", MARK[p[2]] == "remove", MARK[p[2]])
end
for _, id in ipairs({ "to_floor", "trash", "bandage_off", "unplug", "bulb_remove", "bulb_off", "sneak_off", "star_off" }) do
    check("TABLE: " .. id .. " is red", MARK[id] == "remove", MARK[id])
end
-- left ink on purpose
for _, id in ipairs({ "hand_main", "hand_off" }) do
    check("TABLE: " .. id .. "'s which-hand arrow is blue (Equip Primary / Secondary)", MARK[id] == "add", MARK[id])
end
for _, id in ipairs({ "holster", "tent_down", "padlock", "padlock_open", "link", "unlink",
                      "thumbs_up", "thumbs_down", "expand", "contract", "pop_out", "outfit", "loadout",
                      "sneak", "eat", "safehouse", "shield_minus" }) do
    check("TABLE: " .. id .. " stays ink", MARK[id] == nil, MARK[id])
end
local missing = {}
for name, id in pairs(ZeD.ContextPxIcons or {}) do
    for _, s in ipairs(SIZES) do
        if not exists(pic(s, id)) then missing[#missing + 1] = name .. " -> " .. id .. " @" .. s end
    end
end
check("TABLE: every icon the menu table names has its pictures", #missing == 0, table.concat(missing, "; "))
for _, s in ipairs(SIZES) do
    check("TABLE: the new icons are in the mod at " .. s, exists(pic(s, "eat")) and exists(pic(s, "sneak"))
          and exists(pic(s, "safehouse")) and exists(pic(s, "safehouse_claim")) and exists(pic(s, "safehouse_release")))
end

-- ---------------------------------------------------------------------------
-- NAMES
-- ---------------------------------------------------------------------------
do
    local PX = ZeD.ContextPxIcons
    local MK = ZeD.PxIconMark
    ZeD = setmetatable({}, { __index = function() return stub end })
    getText = function(k) return k end
    getTexture = function() return nil end
    getItemNameFromFullType = function(k) return k end
    ISContextMenu = setmetatable({}, { __index = stub })
    local okI, errI = load(SHARED .. "ContextIcons.lua")
    check("NAMES: ContextIcons.lua loads", okI, errI)
    rawset(ZeD, "ContextPxIcons", PX); rawset(ZeD, "PxIconMark", MK)
    rawset(ZeD, "PxIcon", { has = function(id) return id ~= nil end, tex = function(id) return "tex:" .. tostring(id), id end })
    setmetatable(_G, { __index = function() return stub end })
    local okR, errR = load(CLIENT .. "ContextMenuRegistry.lua")
    setmetatable(_G, nil)
    check("NAMES: ContextMenuRegistry.lua loads on the stubs", okR, errR)
    local R = okR and rawget(ZeD, "ContextMenu") and ZeD.ContextMenu.Registry
    if R and R.resolveIconForName then
        local function id(name) local _, i = R.resolveIconForName(name); return i end
        check("NAMES: Claim safehouse draws the house with a plus", id("ContextMenu_SafehouseClaim") == "safehouse_claim", id("ContextMenu_SafehouseClaim"))
        check("NAMES: Release safehouse draws the house with a minus", id("ContextMenu_SafehouseRelease") == "safehouse_release", id("ContextMenu_SafehouseRelease"))
        check("NAMES: View safehouse draws the house", id("ContextMenu_ViewSafehouse") == "safehouse", id("ContextMenu_ViewSafehouse"))
        check("NAMES: Reinforce keeps its shield", id("Reinforce") == "reinforce", id("Reinforce"))
        for _, k in ipairs({ "ContextMenu_Eat", "ContextMenu_Eat_All", "ContextMenu_Eat_Half", "ContextMenu_Eat_Quarter" }) do
            check("NAMES: " .. k .. " draws the eat figure", id(k) == "eat", id(k))
        end
    else
        check("NAMES: the registry's resolveIconForName", false)
    end
end

-- ---------------------------------------------------------------------------
-- DRAW
-- ---------------------------------------------------------------------------
local PX, MK = rawget(ZeD, "ContextPxIcons"), rawget(ZeD, "PxIconMark")
ZeD = {
    Scale = { root = function() return 1 end },
    Text  = { checkRoleFonts = function() return false end, noFonts = true },
    Font  = { sdf = { sec = { font = 1 }, body = { font = 2 }, stat = { font = 3 }, head = { font = 4 }, title = { font = 5 } } },
    ContextPxIcons = PX, PxIconMark = MK,
}
-- a texture is its path when the file is there (the game's getSharedTexture answers nil for a missing one)
Texture = { getSharedTexture = function(path) if exists(MEDIA .. path) then return { path = path } end return nil end }
setmetatable(_G, { __index = function() return stub end })
local okT, errT = load(SHARED .. "Tokens.lua")
local okA, errA = load(CLIENT .. "Atoms.lua")
setmetatable(_G, nil)
check("DRAW: Tokens.lua and Atoms.lua load", okT and okA, tostring(errT) .. " " .. tostring(errA))

local function near(c, r, g, b) return c and math.abs(c.r - r / 255) < 1e-6 and math.abs(c.g - g / 255) < 1e-6 and math.abs(c.b - b / 255) < 1e-6 end
check("DRAW: markAdd is #0B63B0", near(ZeD.Ctx and ZeD.Ctx.markAdd, 0x0B, 0x63, 0xB0))
check("DRAW: markRemove is #C2410C", near(ZeD.Ctx and ZeD.Ctx.markRemove, 0xC2, 0x41, 0x0C))

local function panel()
    local p = { draws = {}, rects = 0 }
    function p:drawTextureScaledAspect(tex, x, y, w, h, a, r, g, b)
        self.draws[#self.draws + 1] = { path = tex and tex.path, x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b }
    end
    return setmetatable(p, { __index = function() return function() end end })
end
local INK = { r = 0.08, g = 0.08, b = 0.08, a = 1 }
local A = ZeD.Atoms
if A and A.drawPxIcon then
    local p = panel(); A.drawPxIcon(p, "equip", 10, 20, 16, 1, INK, true)
    check("DRAW: equip at rest: the icon, then its mark", #p.draws == 2, #p.draws)
    check("DRAW: the icon in the ink", p.draws[1] and p.draws[1].path == "media/textures/ZeD/wheel/16/zw_equip.png"
          and p.draws[1].r == INK.r, p.draws[1] and p.draws[1].path)
    check("DRAW: the mark's picture over it, in blue", p.draws[2] and p.draws[2].path == "media/textures/ZeD/wheel/16/zw_equip_mk.png"
          and near(p.draws[2], 0x0B, 0x63, 0xB0), p.draws[2] and p.draws[2].path)
    check("DRAW: the mark sits exactly on the icon", p.draws[2] and p.draws[2].x == p.draws[1].x and p.draws[2].y == p.draws[1].y
          and p.draws[2].w == p.draws[1].w)

    p = panel(); A.drawPxIcon(p, "trash", 0, 0, 24, 0.45, INK, true)
    check("DRAW: Dispose at 24, greyed: its red lid at 24 with the icon's alpha", #p.draws == 2 and p.draws[2].path:find("/24/zw_trash_mk.png", 1, true)
          and near(p.draws[2], 0xC2, 0x41, 0x0C) and p.draws[2].a == 0.45, p.draws[2] and p.draws[2].path)
    p = panel(); A.drawPxIcon(p, "move_down", 0, 0, 52, 1, INK, true)
    check("DRAW: a 52 box draws the 48 and its 48 mark", #p.draws == 2 and p.draws[1].w == 48 and p.draws[2].path:find("/48/zw_move_down_mk.png", 1, true))
    p = panel(); A.drawPxIcon(p, "equip", 0, 0, 16, 1, INK, false)
    check("DRAW: without marks only the icon", #p.draws == 1, #p.draws)
    p = panel(); A.drawPxIcon(p, "eat", 0, 0, 16, 1, INK, true)
    check("DRAW: an icon with no mark draws once", #p.draws == 1, #p.draws)
    p = panel(); A.drawPxIcon(p, "equip", 0, 0, 16, 1, INK)
    check("DRAW: the old call (no marks argument) is unchanged", #p.draws == 1, #p.draws)

    -- LISTS: the outfit and loadout icons are in the game (the director, Nov 10 2026), their plus and minus versions on
    -- the rows that add to a list (ZeD_Lists.lua's L.icon)
    setmetatable(_G, { __index = function() return stub end })
    local okL, errL = load(CLIENT .. "ZeD_Lists.lua")
    setmetatable(_G, nil)
    local Lst = rawget(ZeD, "Lists")
    check("LISTS: ZeD_Lists.lua loads on the stubs", okL and Lst and Lst.icon, errL)
    if Lst and Lst.icon then
        check("LISTS: an outfit is the shirt on its hanger", Lst.icon("outfit") == "outfit", Lst.icon("outfit"))
        check("LISTS: a loadout is the clipboard", Lst.icon("loadout") == "loadout", Lst.icon("loadout"))
        check("LISTS: Save to outfit takes its plus", Lst.icon("outfit", "add") == "outfit_add", Lst.icon("outfit", "add"))
        check("LISTS: Save to loadout takes its plus", Lst.icon("loadout", "add") == "loadout_add", Lst.icon("loadout", "add"))
        check("LISTS: and the minus is there for a take-out row", Lst.icon("loadout", "remove") == "loadout_remove")
        for _, id in ipairs({ "outfit", "loadout", "outfit_add", "loadout_add", "outfit_remove", "loadout_remove" }) do
            for _, sz in ipairs(SIZES) do check("LISTS: " .. id .. " is in the mod at " .. sz, exists(pic(sz, id))) end
        end
        local pl = panel(); A.drawPxIcon(pl, Lst.icon("outfit", "add"), 0, 0, 16, 1, INK, true)
        check("LISTS: Save to outfit's plus is blue at rest", #pl.draws == 2 and near(pl.draws[2], 0x0B, 0x63, 0xB0))
    end

    -- LIST: the theme's own pair on its surfaces (the director approved the shades Nov 10 2026)
    local SHADES = { dark = { 0x44, 0x91, 0xE2, 0xD9, 0x57, 0x2A }, hicon = { 0x44, 0x91, 0xE2, 0xD9, 0x57, 0x2A },
                     light = { 0x01, 0x4E, 0x8E, 0x87, 0x28, 0x01 } }
    for key, v in pairs(SHADES) do
        if ZeD.BaseThemes[key] then
            pcall(ZeD.applyTheme, key, "teal", "small")
            local m = ZeD.T and ZeD.T.marks
            check("LIST: " .. key .. "'s blue", m and near(m.add, v[1], v[2], v[3]))
            check("LIST: " .. key .. "'s red", m and near(m.remove, v[4], v[5], v[6]))
            p = panel(); A.drawPxIcon(p, "unequip", 0, 0, 16, 1, INK, m)
            check("LIST: " .. key .. ": the mark takes the theme's red, not the paper's", #p.draws == 2 and near(p.draws[2], v[4], v[5], v[6]))
        else
            check("LIST: the base theme " .. key .. " exists", false)
        end
    end
    pcall(ZeD.applyTheme, "dark", "teal", "small")
else
    check("DRAW: ZeD.Atoms.drawPxIcon", false)
end

-- ---------------------------------------------------------------------------
-- CELL
-- ---------------------------------------------------------------------------
setmetatable(_G, { __index = function() return stub end })
local okM, errM = load(CLIENT .. "Molecules.lua")
setmetatable(_G, nil)
check("CELL: Molecules.lua loads on the stubs", okM, errM)
local M = ZeD.Molecules
if M and M.drawContextCell and ZeD.T then
    local T = ZeD.T
    ZeD.Atoms.drawDisabledStipple = ZeD.Atoms.drawDisabledStipple or function() end   -- (AtomExtensions.lua's)
    local function cell(def, flags)
        local p = panel()
        local ok, err = pcall(M.drawContextCell, p, 0, 0, def, flags, T)
        if not ok then print("  (drawContextCell: " .. tostring(err) .. ")") end
        local tex = {}
        for _, d in ipairs(p.draws) do if d.path then tex[#tex + 1] = d end end
        return tex
    end
    local d = cell({ pxIcon = "unequip", iconTintable = true, iconTexture = {}, name = "Unequip" }, {})
    check("CELL: at rest, Unequip's minus is red", #d == 2 and near(d[2], 0xC2, 0x41, 0x0C), #d)
    d = cell({ pxIcon = "unequip", iconTintable = true, iconTexture = {}, name = "Unequip" }, { isActive = true })
    check("CELL: pointed, the whole icon in one color", #d == 1, #d)
    check("CELL: pointed, the icon in the accent's text color", d[1] and T.textOnAccent and d[1].r == T.textOnAccent.r)
    d = cell({ pxIcon = "car_enter", iconTintable = true, iconTexture = {}, name = "Enter" }, { isDisabled = true })
    check("CELL: greyed, the mark still shows, at the cell's alpha", #d == 2 and near(d[2], 0x0B, 0x63, 0xB0) and d[2].a == 0.45, #d)
    d = cell({ pxIcon = "equip", iconTintable = false, iconTexture = {}, name = "Equip" }, {})
    check("CELL: a picture that isn't tinted gets no mark", #d == 1, #d)
else
    check("CELL: drawContextCell", false)
end

print("menu_marks_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
