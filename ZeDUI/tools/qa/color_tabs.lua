-- ZeDUI/tools/qa/color_tabs.lua  (Nov 25 2026, QA; tag color_tabs): the full-color tab icons and the pastel container
-- buttons, in the running game on the QA save. The director picked them from the mock-up
-- ZeDUI/mockups/container_tabs_color_v4.html ("Multicolor", "Lit accent panel", "Stronger tint", "Wash and frame").
-- Build's change (feat/colortabs, 85b6338db; the other 8 tabs, feat/colortabs8, 580bb49a3):
--   * the tabs with color art (ZeD.TabColorArt; pictures media/textures/ZeD/TabIcons/color/zedtabc_<id>.png,
--     _light.png, _sh.png) draw in their own three colors: ZeD.TabPx.colorSet(id, isActive) gives "dark" on Dark and
--     High contrast, "light" on Light; on the lit panel (accent x0.85) the set with more of its pixels 3:1 off the
--     panel. The shadow is alpha 0.55, 0.25 on the panel. The tab list is read from ZeD.TabColorArt when the script
--     starts (S.readArt; 14 before feat/colortabs8, 22 after), with the window(s) each lives in from the windows' own
--     tab lists (ZeD_CharacterWindow.TABS, ZeD_WorldWindow.TABS); a window's tab with no art is named in a NOTE.
--   * every container button of both strips is filled by ZeD.GridTint.stripCell(panel, x, y, w, h, tex, lit, hover):
--     G.apply(raw, G.STRIP[baseKey]) (Light l .80 s .60, Dark l .26 s .50, High contrast l .20 s .55), raw from
--     ZeD.ContainerTints (Container_* pictures), else ZeD.ItemTints (a bag's icon), else neutral gray 0x808080; the
--     shown button keeps the accent wash (T.selectionA) and gains a 2u frame (accentBright, on Light accent x0.72).
-- Run after zedqa_prelude.lua and rt_kit.lua (color_tabs.txt). grep "ZEDQA color_tabs".
--
-- How it reads the draws: while the script runs ZeD.GridTint.stripCell, ZeD.TabPx.drawTab and ZeD.TabPx.drawIcon are
-- wrapped (put back at the end). The stripCell wrapper sets a drawRect of its own on the panel for the one call (the
-- panel's own drawRect is put back right after), so every rect the cell draws is recorded: the fill, the wash and
-- the four frame sides. drawTab gives each tab's rect, lit or not; drawIcon gives the icon's centre, the whole
-- multiple k and the set (TP.colorSet as the icon drew, with the accent of that moment).
--
-- Staging (on the drag strip, the prelude's home):
--   * worn: a backpack and a fanny pack (the Character strip lists the bags he wears and every key ring he carries),
--     one key ring carried; a slot already filled keeps the bag found there
--   * round him: a crate (carpentry_01_16) and one object of each container kind the sprites in S.SPRITES give
--     (fridge, stove, counter, ...), each made only when its sprite gives a container; a duffel bag on his square
--   * for the Vehicle tab: a car (the prelude's ZEDQA_CAR_WAIT), him beside it, its tab opened the mechanics key's way
--   * both windows' own accents (win._accentKey) set to follow the global accent for the run
--   * the tabs that show in context, after the car (S.CTX; each CHECKed shown): a radio in his off hand (Character
--     Radio), a fishing rod in his main hand (World Fishing), bread slices and cheese carried (Character Cooking: a
--     dish's base on him and a fit for it), a TV set (IsoTelevision) on a free square beside him (the World Radio tab
--     draws "tv"). Admin (World) and Server (Character) want a server (isClient()): SKIP in single player. Appearance
--     (SPNCC) and Traits (EvolvingTraitsWorld, traitsAsSkills) are add-ons' tabs, not loaded on the QA save: no window
--     offers them. Every tab with art no strip shows (S.OFF) is drawn on the add-on panel instead.
-- 1. Containers, in Dark, Light and High contrast (the accent as found), both windows on Loot, a crate shown on the
--    World window:
--   * CHECK every button in view got a fill (an opaque rect over the whole cell, the first thing the cell draws)
--   * CHECK every fill is G.apply(raw, rule) for the theme's rule, its lightness the rule's, its saturation the raw's
--     capped at the rule's, its hue the raw's; and the raw is the picture's (ContainerTints, ItemTints, else gray)
--   * CHECK every shown button draws the wash (T.selectionA of the accent) and a T.px(2) frame in the theme's frame
--     color; a button not shown draws its fill alone (and the hover wash under the pointer)
--   * pictures ctab_containers_<cw|ww>_<theme>_<w>x<h>, a CTAB line per button in view
-- 2. Tabs: Dark with orange, teal, red and mono; Light and High contrast with orange and teal. Equipment shown on the
--    Character window, Crafting on the World window:
--   * CHECK colorSet(id, false) is "dark" on Dark and High contrast, "light" on Light, for every tab with art (a plain
--     call: the add-ons' tabs too)
--   * CHECK colorSet(id, true) is the set with the larger share of pixels 3:1 off the lit panel (a TSET line each)
--   * CHECK every colored tab the window shows drew, the shown one lit, each icon in the set colorSet gives (a tab its
--     rule hides is named in a NOTE)
--   * pictures ctab_tabs_<cw|ww>_<theme>_<accent>_<w>x<h>, a CTAB line per tab
--   * close-ups in Dark orange, Dark teal and Light orange: each colored tab each window shows lit once, a Character
--     tab and a World tab per picture, ctab_lit_<cw id>_<ww id>_<theme>_<accent>_<w>x<h> (the ids the tabs draw: the
--     World Radio tab with the TV set is "tv")
--   * the add-on panel in the same three: a panel of the script's own (an ISPanel, on the screen for its picture)
--     draws each tab of S.OFF through ZeD.TabPx.drawTab, unlit and lit, their TabPx.ICONS flags set for it; CHECK each
--     drew in colorSet's set; ctab_addon_<theme>_<accent>_<w>x<h> (CTAB lines win=ad); then CHECK the panel is off
--     the screen and the ICONS flags as found
-- 3. CHECK no new Lua error.
--
-- The CTAB lines (for ctab_measure.py; abs = screen pixels; colors rrggbb):
--   ZEDQA color_tabs CTAB pic=<p> kind=btn win=<cw|ww> theme=<t> accent=<a> i=<n> x= y= w= h= u=<px per unit>
--     lit=0|1 hov=0|1 src=<ct|it|gray> tex=<picture name> raw=<rrggbb> fill=<rrggbb> exp=<rrggbb (the fill with the
--     washes over it: the pixel to expect)> frame=<rrggbb|none> fw=<frame px> icon=<x>,<y>,<size> draws=<n>
--   ZEDQA color_tabs CTAB pic=<p> kind=tab win=<cw|ww|ad> theme=<t> accent=<a> id=<id> x= y= w= h= lit=0|1 wash=0|1
--     foc=0|1 set=<dark|light|accent> k=<k> ix= iy= sz=<16k> panel=<rrggbb (accent x0.85)> acc=<rrggbb> line=<px>
--     vis=0|1 pal=<rrggbb:n,rrggbb:n,rrggbb:n|none>
-- Puts back: the theme and the accent (and their options), both windows' own accents, both windows' tabs and every
-- strip's scroll offset, the World window's shown container, the bags, the key ring, the floor bag, the crate and the
-- objects, the radio, the rod, the dish's items, his hands as found, the TV set, the add-on panel and the ICONS flags,
-- the car (the look ended), him where he stood, the pointer and the wrapped draws.
if not RT then print("ZEDQA color_tabs ERR rt_kit.lua did not run first"); print("ZEDQA color_tabs DONE"); return end
local Q = RT.make("color_tabs")
Q.maxMs = 1080000                    -- (the runner gives this script 1200 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, worn = {}, floorMade = {}, objs = {}, shots = {},
            frame = 0, errs = 0, ctabN = 0, tsetN = 0 }

-- ===================================================================== constants
S.TAG = "color_tabs"
-- the tabs with color art are read from ZeD.TabColorArt when the script starts (S.readArt): S.IDS every id with art,
-- S.CW_TABS / S.WW_TABS each window's tab ids (its TABS list, the add-ons' tabs that loaded included) whose picture
-- has art, S.HOME[id] the window(s) that offer it ("cw", "ww", "cw+ww", nil for none)
S.IDS, S.CW_TABS, S.WW_TABS, S.HOME = {}, {}, {}, {}
S.CW_SHOWN, S.WW_SHOWN = "equip", "craft"
-- staging the tabs that show in context (each list tried in order, the first item the game knows given)
S.RADIOS = { "Base.RadioRed", "Base.RadioBlack", "Base.WalkieTalkie1" }   -- in his off hand: the Character Radio tab
S.RODS = { "Base.FishingRod", "Base.CraftedFishingRod" }                  -- in his main hand: the World Fishing tab
S.DISHES = { { "Base.BreadSlices", "Base.Cheese" }, { "Base.Bowl", "Base.Lettuce" } }   -- a dish's base and a fit for
                                                                          -- it, carried: the Character Cooking tab
S.TVS = { "appliances_television_01_5", "appliances_television_01_0", "appliances_television_01_3" }   -- a TV set beside
                                                                          -- him: the World Radio tab draws "tv"
-- why a tab's rule cannot be met in a single-player run (its icon is drawn on the add-on panel instead)
S.WHY = { admin = "its rule wants a server and an admin (isClient() and getRole():hasAdminTool()); a single-player run has none",
          server = "its rule wants a server (isClient()); a single-player run has none" }
-- the brief's rule per theme (G.STRIP is checked against it)
S.STRIP = { light = { l = 0.80, s = 0.60 }, dark = { l = 0.26, s = 0.50 }, hicon = { l = 0.20, s = 0.55 } }
S.THEMES = { "dark", "light", "hicon" }
S.COMBOS = {
    { theme = "dark", accent = "orange", close = true },
    { theme = "dark", accent = "teal", close = true },
    { theme = "dark", accent = "red" },
    { theme = "dark", accent = "mono" },
    { theme = "light", accent = "orange", close = true },
    { theme = "light", accent = "teal" },
    { theme = "hicon", accent = "orange" },
    { theme = "hicon", accent = "teal" },
}
S.BAGS = {
    { what = "a backpack", list = { "Base.Bag_Schoolbag", "Base.Bag_NormalHikingBag", "Base.Bag_ALICEpack" } },
    { what = "a fanny pack", list = { "Base.Bag_FannyPackFront", "Base.Bag_FannyPackBack" } },
}
S.RING = "Base.KeyRing"
S.FLOORBAG = { "Base.Bag_DuffelBag", "Base.Bag_Satchel", "Base.Bag_Schoolbag" }
S.CRATE = "carpentry_01_16"
-- other container objects: each sprite is tried, kept only when it gives a container of a kind not placed yet
S.SPRITES = { "appliances_refrigeration_01_0", "appliances_refrigeration_01_4", "appliances_cooking_01_0",
              "appliances_cooking_01_4", "fixtures_counters_01_0", "appliances_laundry_01_0", "furniture_storage_01_0",
              "furniture_storage_02_0", "furniture_shelving_01_19", "trashcontainers_01_16", "trashcontainers_01_0",
              "location_business_office_generic_01_0" }
S.CARS = { "Base.CarNormal", "Base.PickUpTruck" }
S.BESIDE = { { -3, 0 }, { 3, 0 }, { -3, 1 }, { 3, -1 }, { 0, -5 }, { 0, 5 } }
S.HEX = "0123456789abcdef"
S.BTN, S.ICON, S.ROW = 36, 22, 16    -- the button and its icon (design units), the [^ v] row
S.OFFS = { { "cw", "_stripScrollOffset" }, { "cw", "_tabScrollOffset" }, { "ww", "_stripScrollOffset" },
           { "ww", "_actionTabScrollOffset" }, { "ww", "_tabScrollOffset" } }

-- ===================================================================== small helpers (strip_arrows')
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.note(s) Q.say("NOTE " .. tostring(s)) end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.waitIdle(n) Q.step(n, function() end) end
function S.i(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x + 0.5)) end
function S.n(v) local x = tonumber(v); if x == nil then return 0 end; return math.floor(x + 0.5) end
function S.f2(v) return string.format("%.2f", tonumber(v) or 0) end
function S.f3(v) return string.format("%.3f", tonumber(v) or 0) end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.idxOf(list, key) for i, v in ipairs(list or {}) do if v == key then return i end end; return nil end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
function S.known(ft)
    local ok = false
    if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end
    return ok
end
function S.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function S.hex2(v)
    local n = math.floor((tonumber(v) or 0) * 255 + 0.5)
    if n < 0 then n = 0 elseif n > 255 then n = 255 end
    local hi = math.floor(n / 16)
    local lo = n - hi * 16
    return string.sub(S.HEX, hi + 1, hi + 1) .. string.sub(S.HEX, lo + 1, lo + 1)
end
function S.hexRGB(r, g, b) return S.hex2(r) .. S.hex2(g) .. S.hex2(b) end
function S.hexC(c)
    if type(c) ~= "table" then return "none" end
    return S.hexRGB(c.r, c.g, c.b)
end
-- 0xRRGGBB -> r, g, b (0 to 1); no % (Kahlua)
function S.unpack(raw)
    local v = math.floor(tonumber(raw) or 0)
    local r = math.floor(v / 65536)
    local g = math.floor((v - r * 65536) / 256)
    local b = v - r * 65536 - g * 256
    return r / 255, g / 255, b / 255
end
function S.rawHex(raw) local r, g, b = S.unpack(raw); return S.hexRGB(r, g, b) end
-- hue (0 to 1), saturation, lightness: the HLS the bake and G.apply use
function S.hsl(r, g, b)
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local l = (mx + mn) / 2
    local d = mx - mn
    if d < 0.000001 then return 0, 0, l end
    local s = (l <= 0.5) and (d / (mx + mn)) or (d / (2 - mx - mn))
    local h
    if r == mx then h = (g - b) / d elseif g == mx then h = 2 + (b - r) / d else h = 4 + (r - g) / d end
    h = h / 6
    h = h - math.floor(h)
    return h, s, l
end
function S.hueGap(a, b) local d = math.abs(a - b); if d > 0.5 then d = 1 - d end; return d end
function S.isItem(it) return it ~= nil and instanceof(it, "InventoryItem") end
function S.ft(it) local t = "none"; if S.isItem(it) then pcall(function() t = it:getFullType() end) end; return tostring(t) end
function S.win(key) if key == "cw" then return RT.cw() end; return RT.ww() end
function S.shade(c, f)
    local function cl(v) if v < 0 then return 0 elseif v > 1 then return 1 end; return v end
    return { r = cl(c.r * f), g = cl(c.g * f), b = cl(c.b * f) }
end
function S.copyC(c) if type(c) ~= "table" then return nil end; return { r = c.r, g = c.g, b = c.b, a = c.a } end
function S.near(a, b, tol) return math.abs((tonumber(a) or -9) - (tonumber(b) or 9)) <= (tol or 0.002) end
function S.sameC(c, r, g, b, tol) return c ~= nil and S.near(c.r, r, tol) and S.near(c.g, g, tol) and S.near(c.b, b, tol) end

-- ===================================================================== things (sb_edges' and strip_arrows')
function S.removeItem(it)
    if not S.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    local wo = it:getWorldItem()
    if wo then
        local sq = wo:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
        pcall(function() wo:removeFromWorld() end)
        pcall(function() wo:removeFromSquare() end)
        pcall(function() it:setWorldItem(nil) end)
    end
    local c = it:getContainer()
    if c then pcall(function() c:Remove(it) end) end
end
function S.mark(it, list)
    if not S.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    list[#list + 1] = it
    return it
end
function S.wornSet()
    local set = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do set[wi:get(i):getItem()] = true end
    end)
    return set
end
function S.isWorn(it)
    local w = false
    if it then pcall(function() w = S.p:isEquippedClothing(it) end) end
    return w and true or false
end
-- a bag worn where its slot is free (bxr_inv's way); a filled slot keeps the bag found there
function S.wearBag(spec)
    local ft = nil
    for _, f in ipairs(spec.list) do if not ft and S.known(f) then ft = f end end
    if not ft then return spec.what .. ": none of " .. table.concat(spec.list, ", ") .. " is an item this game knows" end
    local it = RT.give(ft)
    if not S.isItem(it) then return spec.what .. ": " .. ft .. " could not be given" end
    S.mark(it, S.made)
    local loc = nil
    pcall(function() loc = it:canBeEquipped() end)
    if loc == nil or tostring(loc) == "" then return spec.what .. ": " .. ft .. " has no place to be worn" end
    local there = nil
    pcall(function() there = S.p:getWornItem(loc) end)
    if there then
        S.removeItem(it)
        local nm = "?"
        pcall(function() nm = there:getName() end)
        return spec.what .. ": he already wears " .. tostring(nm) .. " there (" .. tostring(loc) .. "), kept"
    end
    pcall(function() S.p:setWornItem(loc, it) end)
    if S.isWorn(it) then S.worn[#S.worn + 1] = it; return spec.what .. ": " .. ft .. " worn (" .. tostring(loc) .. ")" end
    return spec.what .. ": " .. ft .. " given but not worn (" .. tostring(loc) .. ")"
end
-- the free squares round him (lv_move's)
function S.freeSquares()
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local free = {}
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x + d[1], y + d[2], z)
        local ok = sq ~= nil
        if sq then pcall(function() ok = sq:isFree(false) end) end
        if ok then free[#free + 1] = sq end
    end
    return free
end
-- an object with a sprite's containers (lv_move's mkCrate), put on the square only when it has a container; returns
-- the container types it gives ("" when none)
function S.mkObj(sq, sprite, kinds)
    local made = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, sprite)
        o:createContainersFromSpriteProperties()
        local n = o:getContainerCount()
        if not n or n < 1 then return end
        local types, fresh = {}, false
        for ci = 0, n - 1 do
            local c = o:getContainerByIndex(ci)
            if c then
                local t = tostring(c:getType())
                types[#types + 1] = t
                if not kinds[t] then fresh = true end
            end
        end
        if not fresh then return end
        sq:AddTileObject(o)
        for _, t in ipairs(types) do kinds[t] = true end
        for ci = 0, n - 1 do
            local c = o:getContainerByIndex(ci)
            if c then pcall(function() c:setExplored(true) end) end
        end
        made = { obj = o, sq = sq, sprite = sprite, types = table.concat(types, "+") }
    end)
    if made then S.objs[#S.objs + 1] = made end
    return made
end
function S.rmObj(c)
    if not (c and c.obj) then return end
    -- (each way the game has, each in its own pcall: one that throws must not stop the next; then the square c was
    -- laid on, in case the object's own square is nil by now)
    local o = c.obj
    for _, sq in ipairs({ (function() local q = nil; pcall(function() q = o:getSquare() end); return q end)(), c.sq }) do
        if sq then
            pcall(function() sq:transmitRemoveItemFromSquare(o) end)
            pcall(function() sq:RemoveTileObject(o) end)
            pcall(function() sq:getObjects():remove(o) end)
            pcall(function() sq:getSpecialObjects():remove(o) end)
            pcall(function() sq:RecalcProperties() end)
        end
    end
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
end
function S.objLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() local objs = c.sq:getObjects(); left = objs:contains(c.obj) end)
    return left
end
function S.layObjects()
    local free = S.freeSquares()
    local kinds, said = {}, {}
    local fi = 1
    if free[fi] and S.mkObj(free[fi], S.CRATE, kinds) then fi = fi + 1 end
    for _, sp in ipairs(S.SPRITES) do
        if free[fi] then
            local m = S.mkObj(free[fi], sp, kinds)
            if m then fi = fi + 1; said[#said + 1] = sp .. " (" .. m.types .. ")" end
        end
    end
    -- a bag on his own square: the World strip lists it with its item picture (ItemTints)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())) end)
    local bag = nil
    if sq and instanceof(sq, "IsoGridSquare") then
        for _, ft in ipairs(S.FLOORBAG) do
            if not bag and S.known(ft) then
                local it = nil
                pcall(function() it = sq:AddWorldInventoryItem(ft, 0.5, 0.5, 0) end)
                if S.mark(it, S.floorMade) then bag = ft end
            end
        end
    end
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end
    pcall(function() triggerEvent("OnContainerUpdate") end)
    return #S.objs, #free, table.concat(said, ", "), bag
end
function S.clearObjects()
    for _, c in ipairs(S.objs) do S.rmObj(c) end
    for _, it in ipairs(S.floorMade) do S.removeItem(it) end
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end
    pcall(function() triggerEvent("OnContainerUpdate") end)
end

-- ===================================================================== the pointer and pictures (strip_arrows')
function S.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
-- a picture, then after(name) (its CTAB lines); name and what may be functions (read when the picture is taken), gate
-- one that says whether to take it
function S.shot(name, what, gate, after)
    local st = {}
    Q.step(1, function()
        if S.dead then return end
        if gate and not gate() then st.off = true; return end
        st.mine = S.parked == nil
        S.park(true)
    end)
    Q.step(4, function()
        if st.off then return end
        if S.dead then if st.mine then S.park(false) end; return end
        local nm = (type(name) == "function") and name() or name
        local file = tostring(nm) .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then
            S.shots[#S.shots + 1] = file
            local wh = what
            if type(what) == "function" then pcall(function() wh = what() end) end
            Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. tostring(wh))
            if after then
                local ok2, e2 = pcall(after, tostring(nm))
                if not ok2 then S.errs = S.errs + 1; S.note("the lines for " .. tostring(nm) .. " threw: " .. tostring(e2)) end
            end
        else Q.say("NOTE the picture " .. tostring(nm) .. " was not taken: " .. tostring(e)) end
        if st.mine then S.park(false) end
    end)
    Q.waitMs(1500)
end

-- ===================================================================== the theme and the accent
function S.setLook(base, accent)
    local ob, oa = S.zopt("baseTheme"), S.zopt("accentColor")
    local bi, ai = S.idxOf(ZeD.Settings.baseKeys, base), S.idxOf(ZeD.Settings.accentKeys, accent)
    if ob and bi then pcall(function() ob:setValue(bi) end) end
    if oa and ai then pcall(function() oa:setValue(ai) end) end
    S.back.look = true
    pcall(ZeD.applyTheme, base, accent, nil)
end
function S.lookBack()
    if not S.back.look then return end
    S.back.look = nil
    local f = S.found
    local ob, oa = S.zopt("baseTheme"), S.zopt("accentColor")
    if ob and f.baseIdx then pcall(function() ob:setValue(f.baseIdx) end) end
    if oa and f.accIdx then pcall(function() oa:setValue(f.accIdx) end) end
    pcall(ZeD.applyTheme, f.base, f.accent, nil)
end
-- both windows draw in the global accent for the run (a window's own accent swaps it in while it draws)
function S.winAccentOff()
    local cw, ww = RT.cw(), RT.ww()
    if cw then cw._accentKey = nil end
    if ww then ww._accentKey = nil end
    S.back.winAcc = true
end
function S.winAccentBack()
    if not S.back.winAcc then return end
    S.back.winAcc = nil
    local cw, ww = RT.cw(), RT.ww()
    if cw then cw._accentKey = S.found.cwAcc end
    if ww then ww._accentKey = S.found.wwAcc end
end
function S.offsBack()
    local f = S.found.offs
    if not f then return end
    for _, o in ipairs(S.OFFS) do
        local w = S.win(o[1])
        if w then w[o[2]] = f[o[1] .. o[2]] end
    end
end
function S.geo(win)
    if not win then return "none" end
    return S.i(win:getX()) .. "," .. S.i(win:getY()) .. "," .. S.i(win:getWidth()) .. "," .. S.i(win:getHeight())
end
-- both windows still for 6 frames (a tab's drawer slides open)
function S.settle(lab)
    local st = { last = "", n = 0 }
    S.wait(4, 600, function()
        local g = S.geo(RT.cw()) .. "|" .. S.geo(RT.ww())
        if g == st.last then st.n = st.n + 1 else st.last, st.n = g, 0 end
        return st.n >= 6
    end, function(ok)
        if not ok then S.note(tostring(lab) .. ": the windows did not settle (" .. st.last .. ")") end
    end)
    S.waitIdle(4)
end

-- ===================================================================== the draws as drawn
function S.count() S.frame = S.frame + 1 end
-- the list of records an element drew in this frame (a new frame starts a new list)
function S.listFor(store, el)
    local L = store[el]
    if not L or L.frame ~= S.frame then L = { frame = S.frame, list = {} }; store[el] = L end
    return L.list
end
function S.fresh(store, el)
    local L = el and store[el]
    if L and L.frame >= S.frame - 3 then return L.list end
    return nil
end
function S.spyOn()
    if S.spy then return true end
    local G, TP = ZeD and ZeD.GridTint, ZeD and ZeD.TabPx
    if type(G) ~= "table" or type(rawget(G, "stripCell")) ~= "function" then return false, "ZeD.GridTint.stripCell is missing (Build's change is not in this build)" end
    if type(TP) ~= "table" or type(rawget(TP, "drawTab")) ~= "function" or type(rawget(TP, "drawIcon")) ~= "function"
       or type(rawget(TP, "colorSet")) ~= "function" then
        return false, "ZeD.TabPx.drawTab / drawIcon / colorSet is missing"
    end
    local sp = { own = { stripCell = rawget(G, "stripCell"), drawTab = rawget(TP, "drawTab"), drawIcon = rawget(TP, "drawIcon") },
                 cells = {}, tabs = {}, icons = {} }
    G.stripCell = function(panel, x, y, w, h, tex, lit, hover)
        local rec, hook, had = nil, false, nil
        if type(panel) == "table" then
            local T = ZeD.T
            rec = { x = x, y = y, w = w, h = h, tex = tex, lit = lit and true or false, hov = hover and true or false,
                    draws = {}, base = T and T.baseKey, acc = S.copyC(T and T.accent), bright = S.copyC(T and T.accentBright),
                    selA = T and T.selectionA, f = T and T.px and T.px(2) }
            local list = S.listFor(sp.cells, panel)
            if #list < 80 then list[#list + 1] = rec end
            had = rawget(panel, "drawRect")
            local base = panel.drawRect
            local draws = rec.draws
            if type(base) == "function" then
                panel.drawRect = function(self, rx, ry, rw, rh, a, r, g, b)
                    if #draws < 12 then draws[#draws + 1] = { x = rx, y = ry, w = rw, h = rh, a = a, r = r, g = g, b = b } end
                    return base(self, rx, ry, rw, rh, a, r, g, b)
                end
                hook = true
            end
        end
        local ok, e = pcall(sp.own.stripCell, panel, x, y, w, h, tex, lit, hover)
        if hook then panel.drawRect = had end
        if not ok then error(e) end
    end
    TP.drawTab = function(el, x, y, w, h, id, isActive, isWashed, line, opts)
        if type(el) == "table" then
            local list = S.listFor(sp.tabs, el)
            if #list < 40 then
                list[#list + 1] = { x = x, y = y, w = w, h = h, id = id, act = isActive and true or false,
                                    wash = isWashed and true or false, line = line,
                                    foc = (type(opts) == "table" and opts.focus ~= nil) and true or false }
            end
        end
        return sp.own.drawTab(el, x, y, w, h, id, isActive, isWashed, line, opts)
    end
    -- (bg: what is behind the icon when it is not the lit panel, the controller's one-wash mark; passed on as given)
    TP.drawIcon = function(el, id, cx, cy, isActive, bg)
        if type(el) == "table" then
            local list = S.listFor(sp.icons, el)
            if #list < 40 then
                local T = ZeD.T
                local set = nil
                pcall(function() set = TP.colorSet(id, isActive, bg) end)
                local k = 1
                pcall(function() k = TP.k() end)
                list[#list + 1] = { id = id, cx = cx, cy = cy, act = isActive and true or false, set = set, k = k,
                                    acc = S.copyC(T and T.accent), base = T and T.baseKey }
            end
        end
        return sp.own.drawIcon(el, id, cx, cy, isActive, bg)
    end
    S.spy = sp
    return true
end
function S.spyOff()
    local sp = S.spy
    if not sp then return end
    S.spy = nil
    local G, TP = ZeD and ZeD.GridTint, ZeD and ZeD.TabPx
    if type(G) == "table" then G.stripCell = sp.own.stripCell end
    if type(TP) == "table" then TP.drawTab = sp.own.drawTab; TP.drawIcon = sp.own.drawIcon end
end
function S.spyIsOff()
    local G, TP = ZeD and ZeD.GridTint, ZeD and ZeD.TabPx
    if not (S.own0 and type(G) == "table" and type(TP) == "table") then return true end
    return rawget(G, "stripCell") == S.own0.stripCell and rawget(TP, "drawTab") == S.own0.drawTab
        and rawget(TP, "drawIcon") == S.own0.drawIcon
end
-- a panel's place on the screen (sb_edges' way: its absolute place and its scroll)
function S.absOf(p)
    local ax, ay, xs, ys = 0, 0, 0, 0
    pcall(function() ax, ay = p:getAbsoluteX(), p:getAbsoluteY() end)
    if type(p.getXScroll) == "function" then pcall(function() xs = p:getXScroll() or 0 end) end
    if type(p.getYScroll) == "function" then pcall(function() ys = p:getYScroll() or 0 end) end
    return ax + xs, ay + ys
end

-- ===================================================================== the container buttons
-- a picture's name without its folder or .png (as G.stripRaw reads it)
function S.texName(tex)
    local n = nil
    if tex then pcall(function() n = tex:getName() end) end
    if type(n) ~= "string" then return "" end
    n = string.gsub(n, "\\", "/")
    n = string.match(n, "([^/]+)$") or n
    n = string.gsub(n, "%.[pP][nN][gG]$", "")
    return n
end
-- the raw color and where it came from, looked up here (not through G.stripRaw)
function S.rawOf(tex)
    local name = S.texName(tex)
    local ct = ZeD.ContainerTints and ZeD.ContainerTints[name]
    if ct then return ct, "ct", name end
    local key = string.gsub(name, "^Item_", "")
    local it = ZeD.ItemTints and ZeD.ItemTints[key]
    if it then return it, "it", name end
    return 0x808080, "gray", name
end
-- the cells of a window's container strip in the last frame, the ones in view, and the count the strip should have
function S.cellsOf(wk)
    local w = S.win(wk)
    local p = w and w._containerStrip
    local list = p and S.spy and S.fresh(S.spy.cells, p)
    if not list then return nil, p, w end
    local T = ZeD.T
    local btn = T.px(S.BTN)
    local lay = w._stripLay or {}
    local listY, listH, scroll = tonumber(lay.listY) or 0, tonumber(lay.listH) or 0, tonumber(lay.scroll) or 0
    local want = (w._containers and #w._containers > 0) and 1 or 0
    for i = 1, #(lay.entries or {}) do
        local y = listY - scroll + (i - 1) * btn
        if y + btn > listY and y < listY + listH then want = want + 1 end
    end
    -- (the first cell drawn is the pinned one at the top, the main inventory or the floor; the Character strip draws
    -- every list button, scrolled out of view too, under its clip, so those are left out here)
    local view = {}
    for i, r in ipairs(list) do
        if i == 1 or (r.y + r.h > listY and r.y < listY + listH) then view[#view + 1] = r end
    end
    return view, p, w, want
end
-- the pixel a cell should show away from its icon: the fill with every full-cell wash over it
function S.expOf(r)
    local d1 = r.draws[1]
    if not d1 then return nil end
    local cr, cg, cb = d1.r, d1.g, d1.b
    for j = 2, #r.draws do
        local d = r.draws[j]
        if d.x == r.x and d.y == r.y and d.w == r.w and d.h == r.h then
            local a = tonumber(d.a) or 0
            cr, cg, cb = cr * (1 - a) + d.r * a, cg * (1 - a) + d.g * a, cb * (1 - a) + d.b * a
        end
    end
    return S.hexRGB(cr, cg, cb)
end
-- the frame color the theme asks for
function S.frameOf(r)
    if r.base == "light" then return S.shade(r.acc or { r = 0, g = 0, b = 0 }, 0.72) end
    return r.bright or r.acc
end
function S.isFrame(r)
    if #r.draws < 6 then return false end
    local f, fc = r.f, S.frameOf(r)
    local sides = { { r.x, r.y, r.w, f }, { r.x, r.y + r.h - f, r.w, f }, { r.x, r.y, f, r.h }, { r.x + r.w - f, r.y, f, r.h } }
    for j = 1, 4 do
        local d, s = r.draws[j + 2], sides[j]
        if not (d and d.x == s[1] and d.y == s[2] and d.w == s[3] and d.h == s[4] and S.near(d.a, 1, 0.001)
                and S.sameC(fc, d.r, d.g, d.b, 0.003)) then return false end
    end
    return true
end
-- the checks on one window's strip
function S.cellChecks(wk, theme)
    local lab = ((wk == "cw") and "the Character window's" or "the World window's") .. " container strip (" .. theme .. ")"
    local view, p, w, want = S.cellsOf(wk)
    if not view then Q.check(false, lab .. ": the strip drew its buttons through stripCell", "no stripCell call on the strip panel lately"); return end
    Q.check(#view == want and #view > 0, lab .. ": every button in view drew through stripCell",
        #view .. " drawn in view, " .. tostring(want) .. " in the list in view (" .. #(w._containers or {}) .. " containers)")
    local rule = S.STRIP[theme]
    local noFill, badFill, badSrc, kinds, kindN = {}, {}, {}, {}, 0
    local lit, litOk, badUnlit, hov = 0, 0, {}, 0
    local G = ZeD.GridTint
    for i, r in ipairs(view) do
        local raw, src, name = S.rawOf(r.tex)
        r.raw, r.src, r.name = raw, src, name
        if not kinds[raw] then kinds[raw] = true; kindN = kindN + 1 end
        local gr = nil
        pcall(function() gr = G.stripRaw(r.tex) end)
        if gr ~= raw then badSrc[#badSrc + 1] = name .. " stripRaw " .. S.rawHex(gr) .. " vs " .. S.rawHex(raw) .. " (" .. src .. ")" end
        local d1 = r.draws[1]
        if not (d1 and d1.x == r.x and d1.y == r.y and d1.w == r.w and d1.h == r.h and S.near(d1.a, 1, 0.001)) then
            noFill[#noFill + 1] = "#" .. i .. " " .. name
        else
            local er, eg, eb = G.apply(raw, rule)
            local h0, s0 = S.hsl(S.unpack(raw))
            local h1, s1, l1 = S.hsl(d1.r, d1.g, d1.b)
            local wantS = math.min(s0, rule.s)
            local ok = S.near(d1.r, er, 0.003) and S.near(d1.g, eg, 0.003) and S.near(d1.b, eb, 0.003)
                and S.near(l1, rule.l, 0.006) and S.near(s1, wantS, 0.012)
            if ok and s0 > 0.05 and S.hueGap(h0, h1) > 0.01 then ok = false end
            if not ok then
                badFill[#badFill + 1] = "#" .. i .. " " .. name .. " raw " .. S.rawHex(raw) .. " fill " .. S.hexRGB(d1.r, d1.g, d1.b)
                    .. " (l " .. S.f3(l1) .. " s " .. S.f3(s1) .. "), rule " .. S.hexRGB(er, eg, eb) .. " (l " .. S.f2(rule.l)
                    .. " s " .. S.f3(wantS) .. ")"
            end
        end
        if r.hov then hov = hov + 1 end
        if r.lit then
            lit = lit + 1
            local d2 = r.draws[2]
            local wash = d2 ~= nil and d2.x == r.x and d2.w == r.w and d2.h == r.h and S.near(d2.a, r.selA or 0.30, 0.001)
                and S.sameC(r.acc, d2.r, d2.g, d2.b, 0.003)
            if wash and S.isFrame(r) then litOk = litOk + 1
            else badUnlit[#badUnlit + 1] = "shown #" .. i .. " " .. name .. ": " .. #r.draws .. " rects, wash " .. tostring(wash) end
        else
            local n = #r.draws
            if not (n == 1 or (r.hov and n == 2)) then badUnlit[#badUnlit + 1] = "#" .. i .. " " .. name .. " (not shown) drew " .. n .. " rects" end
        end
    end
    Q.check(#noFill == 0, lab .. ": every button got a fill (an opaque rect over the whole cell, first)", (#noFill == 0) and (#view .. " filled") or table.concat(noFill, "; "))
    Q.check(#badFill == 0, lab .. ": every fill follows G.STRIP for " .. theme .. " (l " .. S.f2(rule.l) .. ", s at most " .. S.f2(rule.s) .. ", the raw's hue)",
        (#badFill == 0) and (#view .. " right, " .. kindN .. " kinds of color") or table.concat(badFill, "; "))
    Q.check(#badSrc == 0, lab .. ": every raw color is the picture's (ContainerTints, ItemTints, else gray)",
        (#badSrc == 0) and "all match" or table.concat(badSrc, "; "))
    if lit == 0 then Q.skip(lab .. ": the shown button draws the wash and the frame", "no button is shown on this strip now")
    else
        Q.check(litOk == lit and #badUnlit == 0, lab .. ": the shown button draws the wash and a T.px(2) frame in "
            .. ((theme == "light") and "the accent x0.72" or "accentBright") .. "; the others their fill alone",
            lit .. " shown, " .. litOk .. " framed" .. ((#badUnlit > 0) and ("; " .. table.concat(badUnlit, "; ")) or ""))
    end
    if hov > 0 then S.note(lab .. ": " .. hov .. " button(s) under the pointer (hover wash)") end
    if wk == "ww" and kindN < 3 then S.note(lab .. ": only " .. kindN .. " kinds of color on the strip") end
end
function S.cellLines(wk, theme, pic)
    local view, p = S.cellsOf(wk)
    if not view then S.note(pic .. ": no button drew on the strip in the frame before the picture"); return end
    local T = ZeD.T
    local ax, ay = S.absOf(p)
    local pw = p:getWidth()
    local is = T.px(S.ICON)
    local acc = tostring(ZeD.currentAccent)
    for i, r in ipairs(view) do
        local raw, src, name = S.rawOf(r.tex)
        local d1 = r.draws[1]
        local ix = math.floor((pw - is) / 2)
        local iy = r.y + math.floor((r.h - is) / 2)
        local fr = (r.lit and S.isFrame(r)) and S.hexC(S.frameOf(r)) or "none"
        S.ctabN = S.ctabN + 1
        Q.say("CTAB pic=" .. pic .. " kind=btn win=" .. wk .. " theme=" .. theme .. " accent=" .. acc .. " i=" .. i
            .. " x=" .. S.n(ax + r.x) .. " y=" .. S.n(ay + r.y) .. " w=" .. S.i(r.w) .. " h=" .. S.i(r.h)
            .. " u=" .. S.f2(T.px(100) / 100) .. " lit=" .. (r.lit and 1 or 0) .. " hov=" .. (r.hov and 1 or 0)
            .. " src=" .. src .. " tex=" .. string.gsub(name, "%s", "_") .. " raw=" .. S.rawHex(raw)
            .. " fill=" .. (d1 and S.hexRGB(d1.r, d1.g, d1.b) or "none") .. " exp=" .. tostring(S.expOf(r) or "none")
            .. " frame=" .. fr .. " fw=" .. S.i(r.f) .. " icon=" .. S.n(ax + ix) .. "," .. S.n(ay + iy) .. "," .. S.i(is)
            .. " draws=" .. #r.draws)
    end
end

-- ===================================================================== the tabs with art (read at run time)
function S.winMod(wk) if wk == "cw" then return ZeD_CharacterWindow end; return ZeD_WorldWindow end
-- a window's tab list (ZeD_CharacterWindow.TABS / ZeD_WorldWindow.TABS: the add-ons' tabs that loaded are in it)
function S.tabDefs(wk)
    local M = S.winMod(wk)
    if M and type(M.TABS) == "table" then return M.TABS end
    return {}
end
-- the pictures a tab can draw: its own, and the TV's on the World Radio tab (while a TV set shows on it)
function S.drawIds(tab)
    local out = { tab.id }
    if type(tab.tv) == "table" and type(tab.tv.px) == "string" then out[#out + 1] = tab.tv.px end
    return out
end
-- the picture a tab draws now (ZeD_WorldWindow.tabIcon, as the strip asks it)
function S.drawIdOf(wk, tab)
    if wk == "ww" and type(tab.tv) == "table" then
        local w = RT.ww()
        local id = nil
        if w then pcall(function() id = ZeD_WorldWindow.tabIcon(tab, w) end) end
        if type(id) == "string" then return id end
    end
    return tab.id
end
-- the tab's own rule (isTabVisible)
function S.tabVisible(wk, tab)
    local M, w = S.winMod(wk), S.win(wk)
    if not (M and w and M.isTabVisible) then return false end
    local v = false
    pcall(function() v = M.isTabVisible(tab, w) and true or false end)
    return v
end
-- every id with art (S.IDS), each window's tab ids that draw art (S.CW_TABS, S.WW_TABS), the window(s) each art id
-- lives in (S.HOME) and the pictures the windows draw that have no art yet (S.NOART)
function S.readArt()
    local art = (ZeD and ZeD.TabColorArt) or {}
    local ids = {}
    for id, _ in pairs(art) do if type(id) == "string" then ids[#ids + 1] = id end end
    table.sort(ids)
    S.IDS, S.HOME, S.NOART = ids, {}, {}
    for _, wk in ipairs({ "cw", "ww" }) do
        local list = {}
        for _, tab in ipairs(S.tabDefs(wk)) do
            local has = false
            for _, d in ipairs(S.drawIds(tab)) do
                if art[d] then
                    has = true
                    S.HOME[d] = S.HOME[d] and (S.HOME[d] .. "+" .. wk) or wk
                elseif not S.inList(S.NOART, d) then S.NOART[#S.NOART + 1] = d end
            end
            if has then list[#list + 1] = tab.id end
        end
        if wk == "cw" then S.CW_TABS = list else S.WW_TABS = list end
    end
end
-- a window's colored tabs now, in strip order: { id = the picture it draws, tab = the tab's id, vis = its rule shows it }
function S.wantTabs(wk)
    local art = ZeD.TabColorArt or {}
    local out = {}
    for _, tab in ipairs(S.tabDefs(wk)) do
        local d = S.drawIdOf(wk, tab)
        if art[d] then out[#out + 1] = { id = d, tab = tab.id, vis = S.tabVisible(wk, tab) } end
    end
    return out
end
-- the shown ones only
function S.shownTabs(wk)
    local out = {}
    for _, e in ipairs(S.wantTabs(wk)) do if e.vis then out[#out + 1] = e end end
    return out
end

-- ===================================================================== the tabs
function S.stripOf(wk) local w = S.win(wk); if not w then return nil end; return (wk == "cw") and w._tabStripPanel or w._actionTabStrip end
function S.offField(wk) return (wk == "cw") and "_tabScrollOffset" or "_actionTabScrollOffset" end
function S.tabsOf(wk)
    local p = S.stripOf(wk)
    if not (p and S.spy) then return nil, nil, p end
    return S.fresh(S.spy.tabs, p), S.fresh(S.spy.icons, p), p
end
-- act (optional): the one drawn lit (true) or unlit (false), for a panel that draws an id twice
function S.iconFor(icons, id, act)
    for _, ic in ipairs(icons or {}) do if ic.id == id and (act == nil or ic.act == act) then return ic end end
    return nil
end
-- the shown tab in view (the strip scrolled to it when it is not)
function S.reveal(wk, id)
    local tabs, _, p = S.tabsOf(wk)
    if not (tabs and p) then return end
    local w = S.win(wk)
    local f = S.offField(wk)
    local ph = p:getHeight()
    local row = ZeD.T.px(S.ROW)
    for _, t in ipairs(tabs) do
        if t.id == id then
            local off = tonumber(w[f]) or 0
            if t.y < 0 then w[f] = math.max(0, off + t.y)
            elseif t.y + t.h > ph - row then w[f] = math.max(0, off + (t.y + t.h) - (ph - row)) end
        end
    end
end
-- a set's share of pixels 3:1 or more off bg (the palette's counts)
function S.share(set, bg)
    local n, ok = 0, 0
    for _, c in ipairs(set or {}) do
        n = n + c.n
        if ZeD.contrast(c, bg) >= 3 then ok = ok + c.n end
    end
    return (n > 0) and (ok / n) or 0
end
function S.palText(set)
    if type(set) ~= "table" then return "none" end
    local out = {}
    for _, c in ipairs(set) do out[#out + 1] = S.hexC(c) .. ":" .. S.i(c.n) end
    return table.concat(out, ",")
end
-- colorSet for every colored tab: the theme's set unlit, the better set lit (a TSET line each)
function S.setChecks(cb)
    local TP, art = ZeD.TabPx, ZeD.TabColorArt or {}
    local want = (cb.theme == "light") and "light" or "dark"
    local bg = S.shade(ZeD.T.accent, 0.85)
    local badU, badL, low = {}, {}, {}
    for _, id in ipairs(S.IDS) do
        local u, l = nil, nil
        pcall(function() u = TP.colorSet(id, false) end)
        pcall(function() l = TP.colorSet(id, true) end)
        if u ~= want then badU[#badU + 1] = id .. "=" .. tostring(u) end
        local a = art[id]
        local sd, sl = S.share(a and a.dark, bg), S.share(a and a.light, bg)
        local better = (sl > sd) and "light" or "dark"
        if l ~= better then badL[#badL + 1] = id .. "=" .. tostring(l) .. " (dark " .. S.f2(sd) .. ", light " .. S.f2(sl) .. ")" end
        local got = (l == "light") and sl or sd
        if got < 0.5 then low[#low + 1] = id .. " " .. S.f2(got) end
        S.tsetN = S.tsetN + 1
        Q.say("TSET theme=" .. cb.theme .. " accent=" .. cb.accent .. " id=" .. id .. " unlit=" .. tostring(u) .. " lit=" .. tostring(l)
            .. " panel=" .. S.hexC(bg) .. " shareDark=" .. S.f2(sd) .. " shareLight=" .. S.f2(sl))
    end
    local lab = cb.theme .. ", " .. cb.accent
    local all = "all " .. #S.IDS
    Q.check(#S.IDS > 0 and #badU == 0, "tabs (" .. lab .. "): colorSet(id, false) is \"" .. want .. "\" for every tab with art",
        (#badU == 0) and all or table.concat(badU, ", "))
    Q.check(#S.IDS > 0 and #badL == 0, "tabs (" .. lab .. "): colorSet(id, true) is the set with more pixels 3:1 off the lit panel " .. S.hexC(bg),
        (#badL == 0) and all or table.concat(badL, "; "))
    if #low > 0 then S.note("tabs (" .. lab .. "): on the lit panel these keep under half their pixels at 3:1 (palette counts): " .. table.concat(low, ", ")) end
end
-- the window's colored tabs drew, the shown one lit, each icon in colorSet's set
function S.drawChecks(wk, shown, cb)
    local lab = ((wk == "cw") and "the Character window's" or "the World window's") .. " tabs (" .. cb.theme .. ", " .. cb.accent .. ", " .. shown .. " shown)"
    local tabs, icons = S.tabsOf(wk)
    if not tabs then Q.check(false, lab .. ": the strip drew its tabs through TabPx.drawTab", "no drawTab call on the strip lately"); return end
    local miss, bad, hidden, n = {}, {}, {}, 0
    local offered = RT.tabs(S.stripOf(wk))
    -- (a tab its rule hides now, and the strip does not offer, is not missing: it is named once in a NOTE)
    for _, e in ipairs(S.wantTabs(wk)) do
        local id = e.id
        local t = nil
        for _, x in ipairs(tabs) do if x.id == id then t = x end end
        local ic = S.iconFor(icons, id)
        if not t then
            if e.vis or S.inList(offered, e.tab) then miss[#miss + 1] = id else hidden[#hidden + 1] = id end
        else
            n = n + 1
            local wantSet = nil
            pcall(function() wantSet = ZeD.TabPx.colorSet(id, t.act) end)
            if t.act ~= (e.tab == shown) then bad[#bad + 1] = id .. " lit " .. tostring(t.act) end
            if not ic then bad[#bad + 1] = id .. " no icon drawn"
            elseif ic.set ~= wantSet or ic.act ~= t.act then bad[#bad + 1] = id .. " icon set " .. tostring(ic.set) .. " (want " .. tostring(wantSet) .. ")" end
        end
    end
    Q.check(#miss == 0 and #bad == 0, lab .. ": every colored tab drew, only the shown one lit, each icon in colorSet's set",
        ((#miss > 0) and ("not drawn: " .. table.concat(miss, ", ") .. "; ") or "") .. ((#bad > 0) and table.concat(bad, "; ") or (n .. " colored tabs drawn")))
    local hs = table.concat(hidden, ", ")
    S.hidSaid = S.hidSaid or {}
    if hs ~= (S.hidSaid[wk] or "") then
        S.hidSaid[wk] = hs
        if hs ~= "" then S.note(lab .. ": not shown now (their rule): " .. hs) end
    end
end
-- panel (optional): a panel of the script's own (the add-on panel, wk "ad") in place of the window's strip
function S.tabLines(wk, cb, pic, panel)
    local tabs, icons, p = nil, nil, nil
    if panel then
        p = panel
        if S.spy then tabs, icons = S.fresh(S.spy.tabs, panel), S.fresh(S.spy.icons, panel) end
    else tabs, icons, p = S.tabsOf(wk) end
    if not tabs then S.note(pic .. ": no tab drew on the " .. wk .. " strip in the frame before the picture"); return end
    local ax, ay = S.absOf(p)
    local ph = p:getHeight()
    local art = ZeD.TabColorArt or {}
    for _, t in ipairs(tabs) do
        local want = nil
        if panel then want = t.act end
        local ic = S.iconFor(icons, t.id, want)
        local k = ic and ic.k or 1
        local sz = 16 * k
        local ix = ic and (ic.cx - math.floor(sz / 2)) or (t.x + math.floor(t.w / 2) - math.floor(sz / 2))
        local iy = ic and (ic.cy - math.floor(sz / 2)) or (t.y + math.floor(t.h / 2) - math.floor(sz / 2))
        local set = (ic and ic.set) or "accent"
        local acc = (ic and ic.acc) or ZeD.T.accent
        local pal = (art[t.id] and art[t.id][set]) or nil
        local vis = (t.y >= 0 and t.y + t.h <= ph) and 1 or 0
        S.ctabN = S.ctabN + 1
        Q.say("CTAB pic=" .. pic .. " kind=tab win=" .. wk .. " theme=" .. cb.theme .. " accent=" .. cb.accent .. " id=" .. tostring(t.id)
            .. " x=" .. S.n(ax + t.x) .. " y=" .. S.n(ay + t.y) .. " w=" .. S.i(t.w) .. " h=" .. S.i(t.h)
            .. " lit=" .. (t.act and 1 or 0) .. " wash=" .. (t.wash and 1 or 0) .. " foc=" .. (t.foc and 1 or 0)
            .. " set=" .. set .. " k=" .. S.i(k) .. " ix=" .. S.n(ax + ix) .. " iy=" .. S.n(ay + iy) .. " sz=" .. S.i(sz)
            .. " panel=" .. S.hexC(S.shade(acc, 0.85)) .. " acc=" .. S.hexC(acc) .. " line=" .. S.i(t.line)
            .. " vis=" .. vis .. " pal=" .. S.palText(pal))
    end
end
function S.tabTo(cwId, wwId)
    if cwId and not RT.charTab(cwId) then S.note("the Character window does not offer the tab " .. cwId) end
    if wwId and not RT.worldTab(wwId) then S.note("the World window does not offer the tab " .. wwId) end
end

-- ===================================================================== the car (sb_edges')
function S.carStart()
    if not ZEDQA_CAR_WAIT then S.carWhy = "the prelude's car helpers are not loaded"; return end
    ZEDQA_CAR_WAIT(S.CARS[1], S.TAG, function(v)
        if S.carGaveUp then if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v) end; return end
        S.car = { v = v, script = S.CARS[1] }
    end, function(why) S.carWhy = why end, 4000)
end
function S.dist(v)
    local d = 999
    if not (v and instanceof(v, "BaseVehicle")) then return d end
    local dx, dy = v:getX() - S.p:getX(), v:getY() - S.p:getY()
    return math.sqrt(dx * dx + dy * dy)
end
function S.carNear(v)
    local d = S.dist(v)
    if d <= 4.0 then return d end
    local vx, vy, z = math.floor(v:getX()), math.floor(v:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(S.BESIDE) do
        local sq = getCell():getGridSquare(vx + o[1], vy + o[2], z)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and sq:getVehicleContainer() == nil end) end
        if free then
            S.goTo(vx + o[1] + 0.5, vy + o[2] + 0.5, z)
            S.note("moved him beside the car (it stood " .. string.format("%.1f", d) .. " tiles away)")
            return S.dist(v)
        end
    end
    return d
end
function S.carAway()
    S.carGaveUp = true
    pcall(function() ZeD.MechanicsTab.endLooks(S.p) end)
    local c = S.car
    if not c or c.going then return end
    c.going = true
    if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, c.v, nil) end
end
function S.carLive(v)
    if not v then return false end
    local live = false
    local vs = nil
    pcall(function() vs = getCell():getVehicles() end)
    if not vs then return false end
    local it = nil
    pcall(function() it = vs:iterator() end)
    if not it then return false end
    pcall(function() while it:hasNext() do if it:next() == v then live = true end end end)
    return live
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        f.pair = RT.isOpen()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.accent, f.accIdx = ZeD.currentAccent, S.optVal(S.zopt("accentColor"))
        f.inv0 = {}
        pcall(function()
            local items = S.p:getInventory():getItems()
            for i = 0, items:size() - 1 do f.inv0[items:get(i)] = true end
        end)
        f.worn0 = S.wornSet()
        pcall(function() f.hand1, f.hand2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() end)
        S.back.on = true
        RT.pairOpen()
        if ZEDQA_HOME then pcall(ZEDQA_HOME, S.TAG) end
        Events.OnPreUIDraw.Add(S.count)
        S.counting = true
        local spied, why = S.spyOn()
        Q.check(spied, "setup: the draws can be watched (GridTint.stripCell, TabPx.drawTab, TabPx.drawIcon)", why)
        if not spied then S.dead = true end
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", theme " .. tostring(f.base) .. ", accent "
            .. tostring(f.accent) .. ", text " .. tostring(ZeD.currentSize) .. ", k " .. tostring(ZeD.TabPx.k()) .. ", screen " .. S.sizeTag())
    end)
    S.wait(10, 300, function()
        local cw, ww = RT.cw(), RT.ww()
        return cw ~= nil and cw._tabStripPanel ~= nil and cw._containerStrip ~= nil and ww ~= nil and ww._actionTabStrip ~= nil
            and ww._containerStrip ~= nil
    end, function(ok)
        local cw, ww = RT.cw(), RT.ww()
        if not Q.check(ok, "setup: the Character and World windows are open, their strips there") then S.dead = true; return end
        local f = S.found
        f.charTab, f.worldTab = cw._activeTab, ww._activeTab
        f.cwAcc, f.wwAcc = cw._accentKey, ww._accentKey
        f.cwGeo, f.wwGeo = S.geo(cw), S.geo(ww)
        f.worldInv = ww._mainContent and ww._mainContent._inventory or nil
        f.offs = {}
        for _, o in ipairs(S.OFFS) do
            local w = S.win(o[1])
            f.offs[o[1] .. o[2]] = w and w[o[2]] or nil
        end
        S.winAccentOff()
        Q.say("found: Character tab " .. tostring(f.charTab) .. " " .. f.cwGeo .. " (own accent " .. tostring(f.cwAcc) .. "), World tab "
            .. tostring(f.worldTab) .. " " .. f.wwGeo .. " (own accent " .. tostring(f.wwAcc) .. ")")
    end)
    -- the rule, the art and its pictures, as shipped
    S.step(1, function()
        local G, TP, art = ZeD.GridTint, ZeD.TabPx, ZeD.TabColorArt
        local bad = {}
        for _, k in ipairs(S.THEMES) do
            local g, s = G.STRIP and G.STRIP[k], S.STRIP[k]
            if not (g and S.near(g.l, s.l, 0.0001) and S.near(g.s, s.s, 0.0001)) then
                bad[#bad + 1] = k .. " " .. (g and (S.f2(g.l) .. "/" .. S.f2(g.s)) or "none") .. " (want " .. S.f2(s.l) .. "/" .. S.f2(s.s) .. ")"
            end
        end
        Q.check(#bad == 0, "setup: G.STRIP is the picked rule (Light l .80 s .60, Dark l .26 s .50, High contrast l .20 s .55)",
            (#bad == 0) and "as picked" or table.concat(bad, "; "))
        -- (the tab list is the art's own, read when the script started: S.readArt)
        local missArt, missPic, homes, none = {}, {}, {}, {}
        for _, id in ipairs(S.IDS) do
            local a = art and art[id]
            -- (TabPx.has only for a tab a window offers: an add-on's tab registers its icon only when the add-on loads)
            if not (a and type(a.dark) == "table" and #a.dark == 3 and type(a.light) == "table" and #a.light == 3
                    and (S.HOME[id] == nil or TP.has(id))) then
                missArt[#missArt + 1] = id
            end
            for _, suf in ipairs({ ".png", "_light.png", "_sh.png" }) do
                local t = nil
                pcall(function() t = ZeD.Px.tex(TP.COLOR_DIR .. "zedtabc_" .. id .. suf) end)   -- (Build 0bfeef129: a prefix no game texture shares)
                if not t then missPic[#missPic + 1] = id .. suf end
            end
            if S.HOME[id] then homes[#homes + 1] = id .. " " .. S.HOME[id] else none[#none + 1] = id end
        end
        Q.check(#S.IDS > 0 and #missArt == 0, "setup: ZeD.TabColorArt has both 3-color sets for every tab with art (and TabPx.has the ones a window offers)",
            (#missArt == 0) and (#S.IDS .. " tabs: " .. table.concat(S.IDS, ", ")) or table.concat(missArt, ", "))
        Q.check(#S.IDS > 0 and #missPic == 0, "setup: every color tab's three pictures load (zedtabc_<id>.png, _light, _sh)",
            (#missPic == 0) and ((#S.IDS * 3) .. " pictures") or table.concat(missPic, ", "))
        Q.say("found: the tabs with art and their windows: " .. table.concat(homes, ", "))
        if #none > 0 then
            S.note("no window offers " .. table.concat(none, ", ") .. " in this run (an add-on's tab: its add-on is not loaded, mods.txt):"
                .. " colorSet is checked as a plain call and the icon is drawn on the add-on panel (ctab_addon_*)")
        end
        if #S.NOART > 0 then S.note("tabs with no color art yet (they keep the accent tones): " .. table.concat(S.NOART, ", ")) end
    end)
end

-- ===================================================================== 1. the containers
function S.containers()
    S.step(2, function()
        local said = {}
        for _, b in ipairs(S.BAGS) do said[#said + 1] = S.wearBag(b) end
        local ring = nil
        if S.known(S.RING) then ring = S.mark(RT.give(S.RING), S.made) end
        said[#said + 1] = "key ring " .. ((ring ~= nil) and "carried" or "not given")
        pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
        local cw = RT.cw()
        if cw then cw._containerTimer = 30 end
        local n, free, objs, bag = S.layObjects()
        Q.say("staged: " .. table.concat(said, "; ") .. "; " .. n .. " objects on " .. free .. " free squares round him (the crate"
            .. ((objs ~= "") and (", " .. objs) or "") .. "), on his square " .. tostring(bag or "no bag"))
    end)
    S.waitIdle(40)
    for _, theme in ipairs(S.THEMES) do
        S.step(2, function()
            S.setLook(theme, S.found.accent)
            S.tabTo("loot", "loot")
            local cw, ww = RT.cw(), RT.ww()
            if cw then cw._containerTimer = 30 end
            if ww then ww._containerTimer = 30 end
        end)
        S.settle("containers " .. theme)
        S.waitIdle(20)
        -- a crate shown on the World window (a list button with its frame)
        S.step(1, function()
            local c = S.objs[1]
            local inv = nil
            if c then pcall(function() inv = c.obj:getContainer() end) end
            if inv then
                S.back.worldInv = true
                pcall(ZeD_WorldWindow.selectContainer, inv, 60, S.pn)
            end
        end)
        S.waitIdle(12)
        S.step(1, function()
            Q.say("pass containers " .. theme .. ": theme " .. tostring(ZeD.currentBase) .. " (T.baseKey " .. tostring(ZeD.T.baseKey)
                .. "), accent " .. tostring(ZeD.currentAccent) .. " " .. S.hexC(ZeD.T.accent) .. ", bright " .. S.hexC(ZeD.T.accentBright))
            Q.check(ZeD.T.baseKey == theme, "containers (" .. theme .. "): the palette is on " .. theme, tostring(ZeD.T.baseKey))
            for _, wk in ipairs({ "cw", "ww" }) do
                local ok, e = pcall(S.cellChecks, wk, theme)
                if not ok then S.errs = S.errs + 1; Q.check(false, "containers (" .. wk .. ", " .. theme .. "): the checks ran without an error", tostring(e)) end
            end
        end)
        for _, wk in ipairs({ "cw", "ww" }) do
            S.shot(function() return "ctab_containers_" .. wk .. "_" .. theme .. "_" .. S.sizeTag() end,
                ((wk == "cw") and "the Character window's" or "the World window's") .. " container strip, " .. theme,
                nil, function(pic) S.cellLines(wk, theme, pic) end)
        end
    end
    -- the crate and the rest away before the car comes (a car's spot must be clear)
    S.step(2, function()
        if S.back.worldInv and S.found.worldInv then pcall(ZeD_WorldWindow.selectContainer, S.found.worldInv, 60, S.pn) end
        S.clearObjects()
    end)
    S.waitIdle(20)
end

-- ===================================================================== 2. the tabs
function S.carStage()
    local st = {}
    S.step(2, function()
        local MT = ZeD.MechanicsTab
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_AWAY and MT and MT.openFromAction) then
            st.off = true
            S.note("no car (the prelude's car helpers or the Mechanics tab are not loaded): the Vehicle tab is left out")
            return
        end
        S.tabTo("loot", "loot")
        S.carStart()
    end)
    S.wait(10, 3600, function() return st.off or S.car ~= nil or S.carWhy ~= nil end, function(ok)
        if st.off then return end
        if not S.car then st.off = true; S.carGaveUp = true; S.note("no car could be spawned ready (" .. tostring(S.carWhy or "none in time") .. "): the Vehicle tab is left out") end
    end)
    S.step(5, function()
        if st.off then return end
        local v = S.car.v
        pcall(function() v:repair() end)
        local d = S.carNear(v)
        local ok, r = pcall(ZeD.MechanicsTab.openFromAction, S.p, v)
        Q.say("staged: the car " .. tostring(S.car.script) .. " " .. string.format("%.1f", d) .. " tiles away; its tab opened " .. tostring(ok and r))
    end)
    S.wait(4, 600, function() return st.off or S.inList(RT.tabs(RT.worldStrip()), "vehicle") end, function(ok)
        if st.off then return end
        if not ok then S.note("the World window does not offer the Vehicle tab with the car beside him") end
    end)
end
function S.tabPics(cb)
    S.step(2, function() S.tabTo(S.CW_SHOWN, S.WW_SHOWN) end)
    S.settle("tabs " .. cb.theme .. " " .. cb.accent)
    S.step(1, function() S.reveal("cw", S.CW_SHOWN); S.reveal("ww", S.WW_SHOWN) end)
    S.waitIdle(6)
    S.step(1, function()
        local ok, e = pcall(function()
            S.setChecks(cb)
            S.drawChecks("cw", S.CW_SHOWN, cb)
            S.drawChecks("ww", S.WW_SHOWN, cb)
        end)
        if not ok then S.errs = S.errs + 1; Q.check(false, "tabs (" .. cb.theme .. ", " .. cb.accent .. "): the checks ran without an error", tostring(e)) end
    end)
    for _, wk in ipairs({ "cw", "ww" }) do
        S.shot(function() return "ctab_tabs_" .. wk .. "_" .. cb.theme .. "_" .. cb.accent .. "_" .. S.sizeTag() end,
            ((wk == "cw") and "the Character window's" or "the World window's") .. " tab strip, " .. cb.theme .. " " .. cb.accent,
            nil, function(pic) S.tabLines(wk, cb, pic) end)
    end
end
-- each colored tab each window shows now lit once, a Character tab and a World tab per picture (both windows in one
-- picture). The slots are counted from the windows' tab lists when the script starts; which tab a slot shows is read
-- when it comes (the tabs their rule hides left out), and a slot past both windows' shown tabs takes no picture.
function S.closeUps(cb)
    local n = math.max(#S.CW_TABS, #S.WW_TABS)
    for i = 1, n do
        local T = {}
        S.step(2, function()
            local cl, wl = S.shownTabs("cw"), S.shownTabs("ww")
            if i > #cl and i > #wl then T.off = true; return end
            local c, w = cl[i] or cl[1], wl[i] or wl[1]
            if not (c and w) then T.off = true; S.note("close-up " .. i .. ": a window shows no colored tab"); return end
            T.cw, T.cwD, T.ww, T.wwD = c.tab, c.id, w.tab, w.id
            -- (a tab past the strip's end has no hit zone: scrolled into view first)
            S.reveal("cw", T.cwD); S.reveal("ww", T.wwD)
        end)
        S.waitIdle(4)
        S.step(1, function() if T.off then return end; S.tabTo(T.cw, T.ww) end)
        S.settle("close-up " .. i)
        S.step(1, function() if T.off then return end; S.reveal("cw", T.cwD); S.reveal("ww", T.wwD) end)
        S.waitIdle(6)
        S.step(1, function()
            if T.off then return end
            local cw, ww = RT.cw(), RT.ww()
            Q.check(cw ~= nil and ww ~= nil and cw._activeTab == T.cw and ww._activeTab == T.ww,
                "close-up (" .. cb.theme .. ", " .. cb.accent .. "): " .. T.cwD .. " and " .. T.wwD .. " shown",
                tostring(cw and cw._activeTab) .. " / " .. tostring(ww and ww._activeTab))
        end)
        S.shot(function() return "ctab_lit_" .. tostring(T.cwD) .. "_" .. tostring(T.wwD) .. "_" .. cb.theme .. "_" .. cb.accent .. "_" .. S.sizeTag() end,
            function() return "the tabs " .. tostring(T.cwD) .. " and " .. tostring(T.wwD) .. " lit, " .. cb.theme .. " " .. cb.accent end,
            function() return not T.off end,
            function(pic) S.tabLines("cw", cb, pic); S.tabLines("ww", cb, pic) end)
    end
end

-- ===================================================================== the tabs that show in context
-- each staged tab: the picture it draws, its window, the tab's id there and what makes it show
S.CTX = {
    { id = "radio", wk = "cw", tab = "radio", how = "a radio in his off hand" },
    { id = "cooking", wk = "cw", tab = "cooking", how = "a dish's base and a fit for it carried" },
    { id = "tv", wk = "ww", tab = "radio", how = "a TV set beside him: the Radio tab draws the TV" },
    { id = "fishing", wk = "ww", tab = "fishing", how = "a fishing rod in his main hand" },
}
function S.giveOne(list, what)
    local ft = nil
    for _, f in ipairs(list) do if not ft and S.known(f) then ft = f end end
    if not ft then return nil, what .. ": none of " .. table.concat(list, ", ") .. " is an item this game knows" end
    local it = S.mark(RT.give(ft), S.made)
    if not it then return nil, what .. ": " .. ft .. " could not be given" end
    return it, what .. ": " .. ft
end
-- a TV set (IsoTelevision, bx_world's way) on a free square beside him, in S.objs (taken away with the rest)
function S.layTV()
    if not IsoTelevision then return nil, "a TV set: no IsoTelevision in this build" end
    local spr = nil
    for _, s in ipairs(S.TVS) do
        local ok = false
        if not spr then pcall(function() ok = getSprite(s) ~= nil end) end
        if ok then spr = s end
    end
    if not spr then return nil, "a TV set: none of the sprites " .. table.concat(S.TVS, ", ") .. " is known" end
    for _, sq in ipairs(S.freeSquares()) do
        local car = nil
        pcall(function() car = sq:getVehicleContainer() end)
        if car == nil then
            local o = nil
            pcall(function() o = IsoTelevision.new(getCell(), sq, getSprite(spr)) end)
            if o ~= nil and instanceof(o, "IsoWaveSignal") then
                local put = false
                pcall(function() sq:AddTileObject(o); put = true end)
                if put then
                    S.objs[#S.objs + 1] = { obj = o, sq = sq, sprite = spr, types = "tv set" }
                    pcall(function() local d = o:getDeviceData(); if d then d:setIsTurnedOn(false) end end)
                    local at = "?"
                    pcall(function() at = S.i(sq:getX()) .. "," .. S.i(sq:getY()) end)
                    return o, "a TV set: " .. spr .. " at " .. at
                end
            end
        end
    end
    return nil, "a TV set: no free square beside him took it"
end
-- the staged tab's window offers it, drawing its picture
function S.ctxShows(e)
    for _, tab in ipairs(S.tabDefs(e.wk)) do
        if tab.id == e.tab then return S.tabVisible(e.wk, tab) and S.drawIdOf(e.wk, tab) == e.id end
    end
    return false
end
-- after the car (he may stand beside it now): the radio, the rod, the dish and the TV set; then which tabs with art
-- no strip shows in this run (S.OFF: drawn on the add-on panel)
function S.ctxStage()
    S.step(2, function()
        local said = {}
        local radio, s1 = S.giveOne(S.RADIOS, "a radio")
        local rod, s2 = S.giveOne(S.RODS, "a fishing rod")
        said[#said + 1] = s1
        said[#said + 1] = s2
        S.back.hands = true
        if S.isItem(rod) then pcall(function() S.p:setPrimaryHandItem(rod) end) end
        if S.isItem(radio) then pcall(function() S.p:setSecondaryHandItem(radio) end) end
        local dish = nil
        for _, pair in ipairs(S.DISHES) do
            if not dish and S.known(pair[1]) and S.known(pair[2]) then
                local a = S.mark(RT.give(pair[1]), S.made)
                local b = S.mark(RT.give(pair[2]), S.made)
                if a and b then dish = pair[1] .. " and " .. pair[2] end
            end
        end
        said[#said + 1] = "a dish: " .. tostring(dish or "none of " .. #S.DISHES .. " pairs could be given")
        local _, s3 = S.layTV()
        said[#said + 1] = s3
        local cw, ww = RT.cw(), RT.ww()
        if cw then cw._containerTimer = 30 end   -- (the Character window reads his hands' radios with its list)
        if ww then ww._containerTimer = 30; ww._radioSq = false end   -- (the World window its 9 squares' radios)
        pcall(function() triggerEvent("OnContainerUpdate") end)
        Q.say("staged for the tabs in context: " .. table.concat(said, "; "))
    end)
    S.wait(10, 600, function()
        for _, e in ipairs(S.CTX) do if S.HOME[e.id] and not S.ctxShows(e) then return false end end
        return true
    end, function(ok)
        for _, e in ipairs(S.CTX) do
            local win = (e.wk == "cw") and "Character" or "World"
            if not S.HOME[e.id] then S.note("the tab " .. e.id .. " has no art or no window offers it: not staged")
            else
                Q.check(S.ctxShows(e), "staged: the " .. win .. " window shows the tab " .. e.tab .. " drawing " .. e.id .. " (" .. e.how .. ")",
                    "offered: " .. table.concat(RT.tabs(S.stripOf(e.wk)), ", "))
            end
        end
        -- the tabs with art no strip shows now
        local on = {}
        for _, wk in ipairs({ "cw", "ww" }) do for _, x in ipairs(S.shownTabs(wk)) do on[x.id] = true end end
        S.OFF = {}
        for _, id in ipairs(S.IDS) do
            if not on[id] then
                S.OFF[#S.OFF + 1] = id
                if S.WHY[id] and S.HOME[id] then
                    Q.skip("the tab " .. id .. " on the " .. ((S.HOME[id] == "cw") and "Character" or "World") .. " window's strip",
                        S.WHY[id] .. "; its icon is drawn on the add-on panel (ctab_addon_*)")
                elseif not S.HOME[id] then
                    S.note("the tab " .. id .. ": no window offers it (its add-on is not loaded, mods.txt); drawn on the add-on panel (ctab_addon_*)")
                else
                    S.note("the tab " .. id .. ": its rule hides it in this run; drawn on the add-on panel (ctab_addon_*)")
                end
            end
        end
        Q.say("found: tabs with art not on a strip now: " .. ((#S.OFF > 0) and table.concat(S.OFF, ", ") or "none"))
    end)
end

-- ===================================================================== the add-on panel
-- the tabs with art no strip shows in this run (an add-on's that is not loaded, a server's) drawn through
-- ZeD.TabPx.drawTab, the strips' own draw, on a panel of the script's own: each id unlit and lit. Their ICONS flags
-- are set for the picture and put back right after (S.iconsSaved keeps each one's value as found).
function S.iconsOn()
    local TP = ZeD.TabPx
    S.iconsSaved = S.iconsSaved or {}
    for _, id in ipairs(S.OFF or {}) do
        if S.iconsSaved[id] == nil then S.iconsSaved[id] = { v = rawget(TP.ICONS, id) } end
        TP.ICONS[id] = true
    end
end
function S.iconsBack()
    local TP = ZeD and ZeD.TabPx
    if not (TP and TP.ICONS) then return end
    for id, s in pairs(S.iconsSaved or {}) do TP.ICONS[id] = s.v end
end
function S.iconsNotBack()
    local TP, bad = ZeD.TabPx, {}
    for id, s in pairs(S.iconsSaved or {}) do
        if rawget(TP.ICONS, id) ~= s.v then bad[#bad + 1] = id .. " " .. tostring(rawget(TP.ICONS, id)) .. " (found " .. tostring(s.v) .. ")" end
    end
    return bad
end
function S.inUI(p)
    local inside = false
    if p and p.javaObject then pcall(function() inside = UIManager.getUI():contains(p.javaObject) and true or false end) end
    return inside
end
function S.addonLay()
    local T = ZeD.T
    local strip = RT.charStrip()
    local tw = T.px(40)
    if strip then pcall(function() tw = strip:getWidth() - T.px(1) end) end
    local th = (T.stripH or T.px(36)) - T.px(1)
    local gap = T.px(8)
    local w = gap + 2 * (tw + gap)
    local h = gap + #S.OFF * (th + gap)
    local sw, sh = S.screen()
    local p = ISPanel:new(math.floor((sw - w) / 2), math.floor((sh - h) / 2), w, h)
    p:initialise()
    p.zedqaCells = {}
    for i, id in ipairs(S.OFF) do
        for c = 0, 1 do
            p.zedqaCells[#p.zedqaCells + 1] = { id = id, lit = (c == 1), x = gap + c * (tw + gap), y = gap + (i - 1) * (th + gap) }
        end
    end
    -- (unlit on the strips' ground, T.surf1, as drawTab's own wash reads it; lit on drawTab's own panel)
    p.prerender = function(self)
        local T2 = ZeD.T
        local bg = T2.surf1 or T2.base
        if bg then self:drawRect(0, 0, self.width, self.height, 1, bg.r, bg.g, bg.b) end
        for _, c in ipairs(self.zedqaCells) do
            ZeD.TabPx.drawTab(self, c.x, c.y, tw, th, c.id, c.lit, false, T2.px(1), nil)
        end
    end
    p.render = function() end
    p:addToUIManager()
    pcall(function() p:bringToTop() end)
    S.addon = p
    S.addonMade = S.addonMade or {}
    S.addonMade[#S.addonMade + 1] = p
end
function S.addonOff()
    local p = S.addon
    if not p then return end
    S.addon = nil
    pcall(function() p:setVisible(false) end)
    pcall(function() p:removeFromUIManager() end)
end
-- every id drew unlit and lit, each icon in colorSet's set
function S.addonChecks(cb)
    local lab = "the add-on panel (" .. cb.theme .. ", " .. cb.accent .. ")"
    local p = S.addon
    local tabs = p and S.spy and S.fresh(S.spy.tabs, p)
    local icons = p and S.spy and S.fresh(S.spy.icons, p)
    if not tabs then Q.check(false, lab .. ": its tabs drew through TabPx.drawTab", "no drawTab call on the panel lately"); return end
    local bad, n = {}, 0
    for _, id in ipairs(S.OFF) do
        for _, lit in ipairs({ false, true }) do
            local t = nil
            for _, x in ipairs(tabs) do if x.id == id and x.act == lit then t = x end end
            local ic = S.iconFor(icons, id, lit)
            local wantSet = nil
            pcall(function() wantSet = ZeD.TabPx.colorSet(id, lit) end)
            local how = id .. (lit and " lit" or " unlit")
            if not t then bad[#bad + 1] = how .. " not drawn"
            elseif not ic then bad[#bad + 1] = how .. " no icon drawn"
            elseif ic.set ~= wantSet or wantSet == nil then bad[#bad + 1] = how .. " icon set " .. tostring(ic.set) .. " (want " .. tostring(wantSet) .. ")"
            else n = n + 1 end
        end
    end
    Q.check(#bad == 0, lab .. ": " .. table.concat(S.OFF, ", ") .. " each drew unlit and lit, each icon in colorSet's set",
        (#bad == 0) and (n .. " drawn") or table.concat(bad, "; "))
end
function S.addonPic(cb)
    local st = {}
    S.step(1, function()
        if not (S.OFF and #S.OFF > 0) then st.off = true; return end
        local ok, e = pcall(function() S.iconsOn(); S.addonLay() end)
        if not ok then
            st.off = true
            S.errs = S.errs + 1
            S.addonOff()
            S.iconsBack()
            Q.check(false, "the add-on panel (" .. cb.theme .. ", " .. cb.accent .. "): laid", tostring(e))
        end
    end)
    S.waitIdle(6)
    S.step(1, function()
        if st.off then return end
        local ok, e = pcall(S.addonChecks, cb)
        if not ok then S.errs = S.errs + 1; Q.check(false, "the add-on panel (" .. cb.theme .. ", " .. cb.accent .. "): the checks ran without an error", tostring(e)) end
    end)
    S.shot(function() return "ctab_addon_" .. cb.theme .. "_" .. cb.accent .. "_" .. S.sizeTag() end,
        function() return "the tabs no strip shows (" .. table.concat(S.OFF or {}, ", ") .. ") unlit and lit, " .. cb.theme .. " " .. cb.accent end,
        function() return not st.off end,
        function(pic) S.tabLines("ad", cb, pic, S.addon) end)
    S.step(1, function()
        if st.off then return end
        local p = S.addon
        S.addonOff()
        S.iconsBack()
        Q.check(p ~= nil and not S.inUI(p), "the add-on panel (" .. cb.theme .. ", " .. cb.accent .. "): taken off the screen after its picture")
        local bad = S.iconsNotBack()
        Q.check(#bad == 0, "the add-on panel (" .. cb.theme .. ", " .. cb.accent .. "): TabPx.ICONS as found again",
            (#bad == 0) and table.concat(S.OFF, ", ") or table.concat(bad, "; "))
    end)
end

function S.tabs()
    S.carStage()
    S.ctxStage()
    for _, cb in ipairs(S.COMBOS) do
        S.step(2, function()
            if not (ZeD.AccentColors and ZeD.AccentColors[cb.accent]) then S.note("no accent " .. cb.accent .. " in this build") end
            S.setLook(cb.theme, cb.accent)
        end)
        S.waitIdle(20)
        S.step(1, function()
            Q.say("pass tabs " .. cb.theme .. " " .. cb.accent .. ": theme " .. tostring(ZeD.T.baseKey) .. ", accent " .. tostring(ZeD.T.accentKey)
                .. " " .. S.hexC(ZeD.T.accent) .. ", the lit panel " .. S.hexC(S.shade(ZeD.T.accent, 0.85)))
        end)
        S.tabPics(cb)
        if cb.close then S.closeUps(cb); S.addonPic(cb) end
    end
end

function S.build()
    S.readArt()   -- (the tab lists, before the steps are laid: the close-ups' slots are counted from them)
    S.setup()
    S.containers()
    S.tabs()
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.park(false)
    S.addonOff()
    S.iconsBack()
    S.lookBack()
    S.winAccentBack()
    S.carAway()
    S.clearObjects()
    for _, it in ipairs(S.made) do S.removeItem(it) end
    if S.back.hands then
        S.back.hands = nil
        local f = S.found
        pcall(function() S.p:setPrimaryHandItem(f.hand1) end)
        pcall(function() S.p:setSecondaryHandItem(f.hand2) end)
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    local cw, ww = RT.cw(), RT.ww()
    if cw then cw._containerTimer = 30 end
    if ww then ww._containerTimer = 30 end
    pcall(function() triggerEvent("OnContainerUpdate") end)
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        S.putBack()
        RT.pairOpen()
    end)
    Q.step(10, function()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
    end)
    Q.step(20, function()
        local f = S.found
        if f.charTab then RT.charTab(f.charTab) end
        if f.worldTab then RT.worldTab(f.worldTab) end
    end)
    Q.step(30, function()
        local f = S.found
        S.offsBack()
        if S.back.worldInv and f.worldInv then pcall(ZeD_WorldWindow.selectContainer, f.worldInv, 60, S.pn) end
    end)
    Q.waitFor(10, 600, function() return not (S.car and S.carLive(S.car.v)) end, function(ok)
        if S.car and not ok then S.note("the car is still in the world 10 s after it was sent away") end
    end)
    -- the windows where they stood once the found tabs' drawers are open again (said, not mended: ZEDQA_LAYOUT_BACK
    -- would reset the tabs and the windows' own accents too)
    S.settle("put back")
    Q.step(2, function()
        local f = S.found
        if not f.cwGeo then return end
        local g1, g2 = S.geo(RT.cw()), S.geo(RT.ww())
        if g1 ~= f.cwGeo or g2 ~= f.wwGeo then
            S.note("the windows stand at " .. g1 .. " / " .. g2 .. " (found " .. f.cwGeo .. " / " .. f.wwGeo .. ")")
        end
    end)
    Q.step(20, function()
        S.spyOff()
        if S.counting then Events.OnPreUIDraw.Remove(S.count); S.counting = nil end
        local f = S.found
        if not f.base then Q.skip("put back", "nothing was staged"); return end
        local left = 0
        local function still(it)
            if not S.isItem(it) then return false end
            local c = it:getContainer()
            local held = false
            if c then pcall(function() held = c:contains(it) end) end
            local laid = false
            pcall(function() local wo = it:getWorldItem(); laid = wo ~= nil and wo:getSquare() ~= nil end)
            return held or laid
        end
        for _, it in ipairs(S.made) do if still(it) then left = left + 1 end end
        for _, it in ipairs(S.floorMade) do if still(it) then left = left + 1 end end
        Q.check(left == 0, "put back: every bag, key ring, floor bag, radio, rod and dish item given is gone", left .. " of " .. (#S.made + #S.floorMade) .. " left")
        local h1, h2 = nil, nil
        pcall(function() h1, h2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() end)
        Q.check(h1 == f.hand1 and h2 == f.hand2, "put back: his hands hold what they held",
            "main " .. S.ft(h1) .. ", off " .. S.ft(h2) .. " (found " .. S.ft(f.hand1) .. ", " .. S.ft(f.hand2) .. ")")
        local extra = 0
        pcall(function()
            local items = S.p:getInventory():getItems()
            for i = 0, items:size() - 1 do if not f.inv0[items:get(i)] then extra = extra + 1 end end
        end)
        Q.check(extra == 0, "put back: the inventory holds only what it held", extra .. " more")
        local wornExtra, wornGone = 0, 0
        local now = S.wornSet()
        for it, _ in pairs(now) do if not f.worn0[it] then wornExtra = wornExtra + 1 end end
        for it, _ in pairs(f.worn0) do if not now[it] then wornGone = wornGone + 1 end end
        Q.check(wornExtra == 0 and wornGone == 0, "put back: he wears what he wore", wornExtra .. " more, " .. wornGone .. " gone")
        local ol = 0
        for _, c in ipairs(S.objs) do if S.objLeft(c) then ol = ol + 1 end end
        local leftNames = {}
        for _, c in ipairs(S.objs) do if S.objLeft(c) then leftNames[#leftNames + 1] = tostring(c.sprite) .. " (" .. tostring(c.types) .. ")" end end
        Q.check(ol == 0, "put back: the crate, every object laid and the TV set are gone", ol .. " of " .. #S.objs .. " left" .. ((#leftNames > 0) and (": " .. table.concat(leftNames, ", ")) or ""))
        if S.addonMade then
            local still = 0
            for _, p in ipairs(S.addonMade) do if S.inUI(p) then still = still + 1 end end
            local bad = S.iconsNotBack()
            Q.check(still == 0 and S.addon == nil and #bad == 0, "put back: the add-on panel is off the screen and TabPx.ICONS as found",
                still .. " of " .. #S.addonMade .. " panels on the screen" .. ((#bad > 0) and ("; ICONS " .. table.concat(bad, "; ")) or ""))
        end
        Q.check(ZeD.currentBase == f.base and ZeD.currentAccent == f.accent and S.optVal(S.zopt("baseTheme")) == f.baseIdx
            and S.optVal(S.zopt("accentColor")) == f.accIdx, "put back: the theme and the accent as found (and their options)",
            tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " (found " .. tostring(f.base) .. " " .. tostring(f.accent) .. ")")
        local cw, ww = RT.cw(), RT.ww()
        Q.check(cw ~= nil and ww ~= nil and cw._accentKey == f.cwAcc and ww._accentKey == f.wwAcc, "put back: both windows' own accents",
            tostring(cw and cw._accentKey) .. " / " .. tostring(ww and ww._accentKey) .. " (found " .. tostring(f.cwAcc) .. " / " .. tostring(f.wwAcc) .. ")")
        Q.check(cw ~= nil and ww ~= nil and cw._activeTab == f.charTab and ww._activeTab == f.worldTab, "put back: both windows' tabs",
            "Character " .. tostring(cw and cw._activeTab) .. " (found " .. tostring(f.charTab) .. "), World " .. tostring(ww and ww._activeTab)
            .. " (found " .. tostring(f.worldTab) .. ")")
        local offOk, offT = true, {}
        for _, o in ipairs(S.OFFS) do
            local w = S.win(o[1])
            local nowO, was = w and w[o[2]], f.offs and f.offs[o[1] .. o[2]]
            if nowO ~= was then offOk = false end
            offT[#offT + 1] = o[1] .. "." .. o[2] .. " " .. tostring(nowO) .. " (found " .. tostring(was) .. ")"
        end
        Q.check(offOk, "put back: every strip's scroll offset as found", table.concat(offT, ", "))
        if S.back.worldInv and f.worldInv then
            local shown = ww and ww._mainContent and ww._mainContent._inventory
            Q.check(shown == f.worldInv, "put back: the World window shows the container it showed")
        end
        Q.check(not (S.car and S.carLive(S.car.v)), "put back: the car is gone", tostring(S.car and S.car.script))
        Q.check(S.spyIsOff() and S.spy == nil and S.parked == nil, "put back: stripCell, drawTab, drawIcon and the pointer the game's own again")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6, "put back: he stands where he stood", string.format("%.1f,%.1f off", dx, dy))
        Q.check(S.errs == 0, "put back: nothing staged for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the color tabs run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the run's Lua error count", "the game's Lua error count cannot be read here") end
        Q.say("pictures: " .. #S.shots .. ", CTAB lines: " .. S.ctabN .. ", TSET lines: " .. S.tsetN
            .. " (measure them: ctab_measure.py --console console.txt --pics <Screenshots folder> --crops <folder>)")
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
S.own0 = {}
if ZeD and type(ZeD.GridTint) == "table" then S.own0.stripCell = rawget(ZeD.GridTint, "stripCell") end
if ZeD and type(ZeD.TabPx) == "table" then
    S.own0.drawTab = rawget(ZeD.TabPx, "drawTab")
    S.own0.drawIcon = rawget(ZeD.TabPx, "drawIcon")
end
if not (ZeD and ZeD.T and ZeD.T.px and ZeD.applyTheme and ZeD.Settings and ZeD.contrast and ZeD.Px and S.own0.stripCell
        and ZeD.GridTint.STRIP and ZeD.TabPx and ZeD.TabPx.colorSet and ZeD.TabColorArt) then
    Q.check(false, "ZeD's tokens, theme, GridTint.stripCell / STRIP and TabPx.colorSet / TabColorArt (Build's feat/colortabs) are loaded")
else
    S.build()
end
S.buildPutBack()
Q.start()
