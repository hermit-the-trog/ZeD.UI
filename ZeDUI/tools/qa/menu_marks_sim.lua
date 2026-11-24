-- ZeDUI/tools/qa/menu_marks_sim.lua  (Nov 10 2026, Build; punch list 138, the menu marks and the new icons)
-- With no game running. Each part loads the REAL files on stubs:
--   (Nov 16 2026: round 1b's three accents, blue, red and gold; the redrawn icons on their menu rows and wheel slices)
--   TABLE  ContextPxIcons.lua: ZeD.PxIconMark names only "blue", "red" or "gold"; every marked icon has its picture and its
--          mark's picture (zw_<id>_mk.png) at 16, 24, 32 and 48; every icon the menu table names has its pictures
--   NAMES  ContextMenuRegistry.lua with ContextIcons.lua: the three safehouse rows get the boarded-up house (claim,
--          release, view), Eat and its parts get the eat figure, Reinforce keeps its shield
--   DRAW   Tokens.lua and Atoms.lua: ZeD.Ctx.markBlue is #1F5FC4, markRed #EA416E, markGold #B57F00 (markAdd and
--          markRemove the older names for blue and red); drawPxIcon with marks draws the icon in its tint and then the
--          mark's picture, the same size, in the mark's color; the older kinds "add" and "remove" still read as blue and
--          red; without marks, or for an icon with no mark, only the icon
--   LIST   each base theme's own set for the list menu (T.marks: Dark and High contrast #5AA2FF / #DC3250 / #F0B429,
--          Light #1D5AB9 / #B81440 / #7A5600), and drawPxIcon given a set draws in it
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
    check("TABLE: " .. id .. " is blue, red or gold", kind == "blue" or kind == "red" or kind == "gold", kind)
    for _, s in ipairs(SIZES) do
        check("TABLE: " .. id .. " has its " .. s, exists(pic(s, id)))
        check("TABLE: " .. id .. " has its mark at " .. s, exists(pic(s, id .. "_mk")))
    end
end
-- (67 since 1.0: the lists' four, outfit_add / _remove and loadout_add / _remove, went with the add-on ZeD-GUI: Loadouts)
check("TABLE: 67 icons take a mark", nMarks == 67, nMarks)
-- (Icon color, the director, Nov 22 2026) the inventory strips' own marks: apart from the menus' table, each with
-- its mark's picture at every size
local STRIPMARK = ZeD.PxIconStripMark or {}
local nStrip = 0
local function isKind(k) return k == "blue" or k == "red" or k == "gold" end
for id, kind in pairs(STRIPMARK) do
    nStrip = nStrip + 1
    -- (a list: an icon with more than one mark, each its own picture, _mk, _mk2, ...; the Filter, Nov 22 2026)
    local kinds = type(kind) == "table" and kind or { kind }
    for i, k in ipairs(kinds) do
        check("STRIP: " .. id .. " mark " .. i .. " is blue, red or gold", isKind(k), tostring(k))
        for _, s in ipairs(SIZES) do
            local mk = id .. "_mk" .. (i > 1 and tostring(i) or "")
            check("STRIP: " .. id .. " has its " .. s .. " and its mark " .. i, exists(pic(s, id)) and exists(pic(s, mk)))
        end
    end
    check("STRIP: " .. id .. " is not in the menus' table (the menus keep it ink)", MARK[id] == nil)
end
-- the director, Nov 22 2026: the Filter's top bar split, blue left and red right; its drop blue alone
local fk = STRIPMARK.filter
check("STRIP: the Filter has two marks, blue then red", type(fk) == "table" and fk[1] == "blue" and fk[2] == "red" and #fk == 2)
check("STRIP: the menus' filter has no mark (Filter water stays ink)", MARK.filter == nil)
check("STRIP: 11 strip icons take a mark", nStrip == 11, nStrip)
for _, id in ipairs({ "filter", "view_list", "view_grid", "same_type", "same_nearby", "power", "match", "campfire",
                      "gears", "extinguisher", "padlock", "tray_in", "tray_out", "to_floor", "trash" }) do
    check("STRIP: the strips' " .. id .. " has a mark (theirs or the menus')", STRIPMARK[id] ~= nil or MARK[id] ~= nil)
end
-- the handoff's pairs, both sides
local PAIRS = {
    { "plus", "minus" }, { "equip", "unequip" }, { "tray_in", "tray_out" }, { "mag_in", "mag_out" },
    { "rounds_in", "rounds_out" }, { "battery_in", "battery_out" }, { "fill", "empty" },
    { "safehouse_claim", "safehouse_release" }, { "car_enter", "car_exit" }, { "window_open", "window_close" },
    { "zoom_in", "zoom_out" }, { "move_up", "move_down" }, { "box_up", "box_down" }, { "autowalk", "autowalk_off" },
    -- (the lists' pair, outfit and loadout, is the add-on ZeD-GUI: Loadouts' own since 1.0)
}
for _, p in ipairs(PAIRS) do
    check("TABLE: " .. p[1] .. " is blue", MARK[p[1]] == "blue", MARK[p[1]])
    check("TABLE: " .. p[2] .. " is red", MARK[p[2]] == "red", MARK[p[2]])
end
for _, id in ipairs({ "to_floor", "trash", "bandage_off", "unplug", "bulb_remove", "bulb_off", "sneak_off", "star_off" }) do
    check("TABLE: " .. id .. " is red", MARK[id] == "red", MARK[id])
end
-- round 1b (Nov 16 2026): each redrawn icon's one accent (i_r1.ACCENT)
local R1 = { r_favorite = "gold", r_place = "red", r_pick_up = "blue", r_put_in = "red", r_take = "blue", r_drop = "red",
             r_wanted = "blue", r_unwanted = "red", r_no_recipes = "gold", r_recipes_ok = "gold", r_install = "blue",
             r_uninstall = "red", r_disassemble = "red", r_destroy = "red", r_light = "gold", r_weapons = "red",
             r_drink = "blue", r_medkit = "red", r_sleep = "gold" }
for id, kind in pairs(R1) do check("TABLE: " .. id .. " is " .. kind, MARK[id] == kind, MARK[id]) end
for _, id in ipairs({ "r_move_to", "r_rename", "r_chop", "r_slice", "r_dice", "r_peel", "r_dig" }) do
    check("TABLE: " .. id .. " is ink only", MARK[id] == nil, MARK[id])
    for _, s in ipairs(SIZES) do check("TABLE: " .. id .. " has its " .. s, exists(pic(s, id))) end
end
-- left ink on purpose
for _, id in ipairs({ "hand_main", "hand_off" }) do
    check("TABLE: " .. id .. "'s which-hand arrow is blue (Equip Primary / Secondary)", MARK[id] == "blue", MARK[id])
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
        -- Grab takes the Take icon, blue; Smash keeps the fist (the director, Nov 10)
        check("NAMES: Grab draws Take", id("Grab") == "tray_in", id("Grab"))
        check("NAMES: ... Grab with its thing after (the first word)", id("Grab Hammer") == "tray_in", id("Grab Hammer"))
        check("NAMES: ... and its blue mark", MK and MK.tray_in == "blue")
        check("NAMES: Smash keeps the fist", id("Smash") == "fist", id("Smash"))
        for _, k in ipairs({ "ContextMenu_Eat", "ContextMenu_Eat_All", "ContextMenu_Eat_Half", "ContextMenu_Eat_Quarter" }) do
            check("NAMES: " .. k .. " draws the eat figure", id(k) == "eat", id(k))
        end
        -- round 1b (Nov 16 2026): the item menu's actions each draw their own redrawn icon
        local ROWS = {
            { "IGUI_CraftUI_Favorite", "r_favorite" }, { "ContextMenu_Place", "r_place" }, { "Place", "r_place" },
            { "ContextMenu_ExtendedPlacement", "r_place" }, { "Pick up", "r_pick_up" }, { "Put In", "r_put_in" },
            { "ContextMenu_Put_in_Container", "r_put_in" }, { "ContextMenu_PutInContainer", "r_put_in" },
            { "ContextMenu_Take", "r_take" }, { "Take Out", "r_take" }, { "Drop", "r_drop" }, { "ContextMenu_DropItems", "r_drop" },
            { "ContextMenu_Move_To", "r_move_to" }, { "ContextMenu_Wanted", "r_wanted" }, { "ContextMenu_Unwanted", "r_unwanted" },
            { "Mark Unwanted", "r_unwanted" }, { "ContextMenu_SetNoRecipes", "r_no_recipes" },
            { "ContextMenu_UnsetNoRecipes", "r_recipes_ok" }, { "Rename", "r_rename" }, { "Chop", "r_chop" },
            { "Slice", "r_slice" }, { "Dice", "r_dice" }, { "Peel", "r_peel" }, { "Install", "r_install" },
            { "Install Part", "r_install" }, { "Uninstall", "r_uninstall" }, { "Remove Part", "r_uninstall" },
            { "Disassemble", "r_disassemble" }, { "ContextMenu_Disassemble", "r_disassemble" },
            { "ContextMenu_Dismantle", "r_disassemble" }, { "ContextMenu_Destroy", "r_destroy" },
            { "ContextMenu_DestroyFloor", "r_destroy" }, { "ContextMenu_DestroyForFuel", "r_destroy" },
            { "ContextMenu_Dig", "r_dig" }, { "ContextMenu_DigWithHands", "r_dig" }, { "ContextMenu_DigGraves", "r_dig" },
            { "ContextMenu_Light", "r_light" }, { "Light Fire", "r_light" }, { "Use Lighter", "r_light" },
        }
        for _, r in ipairs(ROWS) do check("NAMES: " .. r[1] .. " draws " .. r[2], id(r[1]) == r[2], id(r[1])) end
        check("NAMES: Set Unwanted and Unusable in Recipes no longer share a picture",
              id("ContextMenu_Unwanted") ~= id("ContextMenu_SetNoRecipes"))
        check("NAMES: Unfavorite keeps its struck star", id("Unfavorite") == "star_off", id("Unfavorite"))
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
check("DRAW: markBlue is #1F5FC4", near(ZeD.Ctx and ZeD.Ctx.markBlue, 0x1F, 0x5F, 0xC4))
check("DRAW: markRed is #EA416E", near(ZeD.Ctx and ZeD.Ctx.markRed, 0xEA, 0x41, 0x6E))
check("DRAW: markGold is #B57F00", near(ZeD.Ctx and ZeD.Ctx.markGold, 0xB5, 0x7F, 0x00))
check("DRAW: markAdd and markRemove are still there, the blue and the red", ZeD.Ctx and ZeD.Ctx.markAdd == ZeD.Ctx.markBlue
      and ZeD.Ctx.markRemove == ZeD.Ctx.markRed)

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
          and near(p.draws[2], 0x1F, 0x5F, 0xC4), p.draws[2] and p.draws[2].path)
    check("DRAW: the mark sits exactly on the icon", p.draws[2] and p.draws[2].x == p.draws[1].x and p.draws[2].y == p.draws[1].y
          and p.draws[2].w == p.draws[1].w)

    p = panel(); A.drawPxIcon(p, "trash", 0, 0, 24, 0.45, INK, true)
    check("DRAW: Dispose at 24, greyed: its red lid at 24 with the icon's alpha", #p.draws == 2 and p.draws[2].path:find("/24/zw_trash_mk.png", 1, true)
          and near(p.draws[2], 0xEA, 0x41, 0x6E) and p.draws[2].a == 0.45, p.draws[2] and p.draws[2].path)
    p = panel(); A.drawPxIcon(p, "move_down", 0, 0, 52, 1, INK, true)
    check("DRAW: a 52 box draws the 48 and its 48 mark", #p.draws == 2 and p.draws[1].w == 48 and p.draws[2].path:find("/48/zw_move_down_mk.png", 1, true))
    p = panel(); A.drawPxIcon(p, "equip", 0, 0, 16, 1, INK, false)
    check("DRAW: without marks only the icon", #p.draws == 1, #p.draws)
    p = panel(); A.drawPxIcon(p, "eat", 0, 0, 16, 1, INK, true)
    check("DRAW: an icon with no mark draws once", #p.draws == 1, #p.draws)
    p = panel(); A.drawPxIcon(p, "equip", 0, 0, 16, 1, INK)
    check("DRAW: the old call (no marks argument) is unchanged", #p.draws == 1, #p.draws)
    p = panel(); A.drawPxIcon(p, "r_light", 0, 0, 24, 1, INK, true)
    check("DRAW: the lighter's flame is gold", #p.draws == 2 and near(p.draws[2], 0xB5, 0x7F, 0x00), #p.draws)
    p = panel(); A.drawPxIcon(p, "r_medkit", 0, 0, 24, 1, INK, true)
    check("DRAW: the medkit's cross is red", #p.draws == 2 and near(p.draws[2], 0xEA, 0x41, 0x6E), #p.draws)
    -- an older kind still reads: "add" as blue, "remove" as red
    ZeD.PxIconMark.zz_old_add, ZeD.PxIconMark.zz_old_remove = "add", "remove"
    check("DRAW: an older add mark is the blue", ZeD.PxIcon.markColor("zz_old_add", true) == ZeD.Ctx.markBlue)
    check("DRAW: an older remove mark is the red", ZeD.PxIcon.markColor("zz_old_remove", true) == ZeD.Ctx.markRed)
    local oldPair = { add = { r = 0, g = 0, b = 1 }, remove = { r = 1, g = 0, b = 0 } }
    check("DRAW: an older { add, remove } pair still colors blue", ZeD.PxIcon.markColor("equip", oldPair) == oldPair.add)
    check("DRAW: ... and leaves a gold mark ink", ZeD.PxIcon.markColor("r_light", oldPair) == nil)
    ZeD.PxIconMark.zz_old_add, ZeD.PxIconMark.zz_old_remove = nil, nil

    -- LISTS (1.0, Nov 23 2026): the outfit and loadout icons went with Loadouts to the add-on ZeD-GUI: Loadouts (its
    -- tests/source_sim.lua checks L.icon and the pictures; it colors their marks with ZeD.PxIcon.addMark). ZeD alone
    -- ships none of them and colors none of their marks.
    for _, id in ipairs({ "outfit", "loadout", "outfit_add", "loadout_add", "outfit_remove", "loadout_remove" }) do
        for _, sz in ipairs(SIZES) do check("LISTS: " .. id .. " is no longer ZeD's at " .. sz, not exists(pic(sz, id))) end
        check("LISTS: ZeD's own table colors no mark of " .. id, ZeD.PxIconMark[id] == nil)
    end

    -- LIST: the theme's own set on its surfaces (round 1b, Nov 16 2026: the design's dark set; Light the light set
    -- made darker at the same hues for its grey surfaces)
    local SHADES = { dark = { 0x5A, 0xA2, 0xFF, 0xDC, 0x32, 0x50, 0xF0, 0xB4, 0x29 },
                     hicon = { 0x5A, 0xA2, 0xFF, 0xDC, 0x32, 0x50, 0xF0, 0xB4, 0x29 },
                     light = { 0x1D, 0x5A, 0xB9, 0xB8, 0x14, 0x40, 0x7A, 0x56, 0x00 } }
    for key, v in pairs(SHADES) do
        if ZeD.BaseThemes[key] then
            pcall(ZeD.applyTheme, key, "teal", "small")
            local m = ZeD.T and ZeD.T.marks
            check("LIST: " .. key .. "'s blue", m and near(m.add, v[1], v[2], v[3]))
            check("LIST: " .. key .. "'s red", m and near(m.remove, v[4], v[5], v[6]) and m.red == m.remove and m.blue == m.add)
            check("LIST: " .. key .. "'s gold", m and near(m.gold, v[7], v[8], v[9]))
            p = panel(); A.drawPxIcon(p, "r_favorite", 0, 0, 16, 1, INK, m)
            check("LIST: " .. key .. ": the star takes the theme's gold", #p.draws == 2 and near(p.draws[2], v[7], v[8], v[9]))
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
    check("CELL: at rest, Unequip's minus is red", #d == 2 and near(d[2], 0xEA, 0x41, 0x6E), #d)
    d = cell({ pxIcon = "unequip", iconTintable = true, iconTexture = {}, name = "Unequip" }, { isActive = true })
    check("CELL: pointed, the whole icon in one color", #d == 1, #d)
    check("CELL: pointed, the icon in the accent's text color", d[1] and T.textOnAccent and d[1].r == T.textOnAccent.r)
    d = cell({ pxIcon = "car_enter", iconTintable = true, iconTexture = {}, name = "Enter" }, { isDisabled = true })
    check("CELL: greyed, the mark still shows, at the cell's alpha", #d == 2 and near(d[2], 0x1F, 0x5F, 0xC4) and d[2].a == 0.45, #d)
    d = cell({ pxIcon = "equip", iconTintable = false, iconTexture = {}, name = "Equip" }, {})
    check("CELL: a picture that isn't tinted gets no mark", #d == 1, #d)
else
    check("CELL: drawContextCell", false)
end

-- ---------------------------------------------------------------------------
-- STRIP (Icon color, the director, Nov 22 2026): the inventory lists' heading and footer band icon buttons
-- (Molecules.drawIconButton with marks) color the mark at rest, in the theme's set, as the menu does
-- ---------------------------------------------------------------------------
if M and M.drawIconButton and ZeD.T then
    ZeD.PxIconStripMark = STRIPMARK
    local A2 = ZeD.Atoms
    for _, f in ipairs({ "fillRounded", "borderRounded", "requestHint", "padHelp", "windowOf" }) do
        if not A2[f] then A2[f] = function() end end
    end
    pcall(ZeD.applyTheme, "dark", "teal", "small")
    local T = ZeD.T
    local function btn(icon, opts)
        local p = panel()
        local ok, err = pcall(M.drawIconButton, p, 0, 0, 24, icon, opts)
        if not ok then print("  (drawIconButton: " .. tostring(err) .. ")") end
        local tex = {}
        for _, d in ipairs(p.draws) do if d.path then tex[#tex + 1] = d end end
        return tex
    end
    local m = T.marks
    local d = btn("filter", { marks = m })
    check("STRIP: the Filter at rest: the funnel, then the bar's left half and the drop in the theme's blue",
        #d == 3 and d[2].path:find("zw_filter_mk.png", 1, true) and d[2].r == m.blue.r and d[2].b == m.blue.b, #d)
    check("STRIP: ... then the bar's right half in the theme's red", d[3] and d[3].path:find("zw_filter_mk2.png", 1, true)
        and d[3].r == m.red.r and d[3].g == m.red.g, d[3] and d[3].path)
    check("STRIP: the marks sit exactly on the icon", d[3] and d[3].x == d[1].x and d[3].y == d[1].y and d[3].w == d[1].w)
    for _, box in ipairs({ 16, 32 }) do
        local p2 = panel()
        A.drawPxIcon(p2, "filter", 0, 0, box, 1, INK, m, STRIPMARK.filter)
        check("STRIP: the Filter at " .. box .. " (1x, 2x): both marks at " .. box, #p2.draws == 3
            and p2.draws[2].path:find("/" .. box .. "/zw_filter_mk.png", 1, true) and p2.draws[3].path:find("/" .. box .. "/zw_filter_mk2.png", 1, true))
    end
    local p3 = panel(); A.drawPxIcon(p3, "filter", 0, 0, 16, 1, INK, true)
    check("STRIP: the menus' own call (no strip kinds) draws the filter in ink only", #p3.draws == 1, #p3.draws)
    d = btn("view_list", { marks = m })
    check("STRIP: the view button's bullets in the blue", #d == 2 and d[2].r == m.blue.r, #d)
    d = btn("same_type", { marks = m })
    check("STRIP: Same type (World: Take) in the blue", #d == 2 and d[2].r == m.blue.r, #d)
    d = btn("same_type", { marks = m, markKind = "red" })
    check("STRIP: Same type (Character: Put in) in the red", #d == 2 and d[2].r == m.red.r and d[2].g == m.red.g, #d)
    d = btn("tray_out", { marks = m })
    check("STRIP: Take marked's / Transfer's tray keeps the menu's own mark", #d == 2 and d[2].r == m.red.r, #d)
    d = btn("power", { marks = m })
    check("STRIP: a stove's switch: its stem in the gold", #d == 2 and d[2].r == m.gold.r, #d)
    d = btn("filter", { marks = m, hover = true })
    check("STRIP: pointed at: one tint, no mark", #d == 1, #d)
    d = btn("filter", { marks = m, active = true })
    check("STRIP: lit (the Filter open): one tint, no mark", #d == 1, #d)
    d = btn("trash", { marks = m, tint = T.danger })
    check("STRIP: the bin in the warning color keeps its one tint", #d == 1, #d)
    d = btn("filter", { marks = m, disabled = true })
    check("STRIP: greyed, both marks still show at the button's alpha", #d == 3 and d[2].a == T.disabledAlpha and d[3].a == T.disabledAlpha, #d)
    d = btn("filter", {})
    check("STRIP: without marks (every other icon button) only the icon", #d == 1, #d)
    pcall(ZeD.applyTheme, "light", "teal", "small")
    d = btn("filter", { marks = ZeD.T.marks })
    check("STRIP: Light: the theme's own blue and red", #d == 3 and near(d[2], 0x1D, 0x5A, 0xB9) and near(d[3], 0xB8, 0x14, 0x40), #d)
    pcall(ZeD.applyTheme, "hicon", "teal", "small")
    d = btn("filter", { marks = ZeD.T.marks })
    check("STRIP: High contrast: its blue and red", #d == 3 and near(d[2], 0x5A, 0xA2, 0xFF) and near(d[3], 0xDC, 0x32, 0x50), #d)
    pcall(ZeD.applyTheme, "dark", "teal", "small")
else
    check("STRIP: drawIconButton", false)
end
-- the strips ask for it: the heading's Filter and view button, the band's icon buttons
do
    local function rf(p) local f = io.open(p, "rb"); local s = f and f:read("*a") or ""; if f then f:close() end return s end
    local IR, CC = rf(CLIENT .. "InventoryRenderer.lua"), rf(CLIENT .. "ContainerControls.lua")
    local n = 0
    for _ in IR:gmatch("o%.marks = T%.marks") do n = n + 1 end
    check("STRIP: the heading's Filter and view button ask for marks", n == 2, n)
    check("STRIP: the band's icon buttons ask for marks", CC:find("o.marks, o.markKind = T.marks, s and s.mark or nil", 1, true) ~= nil)
    check("STRIP: the Character window's Same type puts in: red", CC:find('mark = "red",   -- (Put in', 1, true) ~= nil)
end

print("menu_marks_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
