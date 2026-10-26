-- ZeDUI/tools/qa/zedqa_belt_ammo.lua  (Oct 26 2026)
-- The ammo box beside the main hand (mockup zed_belt_ammo_dash_v1, style B; approved Oct 26 2026):
--   pistol   an M9 with 12 in the magazine and 1 chambered; two M9 magazines (15, 9), 34 loose rounds and a box
--            carried: "12+1", "2 MAG", "34 RDS"; the box named in the hover text, not counted
--   shotgun  a JS-2000 in both hands (the off hand shows BOTH), 3 in it and 1 chambered, 17 shells and a box:
--            "3+1", "17 RDS", "+1 BOX"
--   empty    a revolver with nothing in it: "EMPTY" in the danger colour
--   worn     the pistol at 3 + 0 (a fifth full): the count in the danger colour; at 6 + 1: amber
-- Each: the box sits right after the main hand, the pad steps over it, the hover (the pointer stood in on the belt:
-- a script cannot move a fullscreen game's pointer) gives the full count above the box. Everything given is taken
-- back and the hands put back. Screenshots zqa_ba_*.png; grep "ZEDQA ba".
local p = getPlayer()
local B = ZeD.Belt
local function say(s) print("ZEDQA ba " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ba_" .. n .. ".png") end) end
if not (B and B.ammo and B.ammoWords) then say("ERR the new code is not loaded"); say("DONE"); return end
local hud = B.getHUD()
local inv = p:getInventory()
local was = { p1 = p:getPrimaryHandItem(), p2 = p:getSecondaryHandItem() }
local given = {}
local function give(full, n)
    local out = {}
    for _ = 1, n or 1 do local it = inv:AddItem(full); given[#given + 1] = it; out[#out + 1] = it end
    return out[1], out
end
local Q, qi, wait = {}, 1, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

local function box(kind, which)
    for i, b in ipairs(hud._boxes) do if b.kind == kind and (which == nil or b.which == which) then return b, i end end
    return nil
end
-- the pointer stood in on the belt (its own getMouseX / getMouseY, this panel only)
local function pointAt(b)
    if b then
        local x, y = b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)
        hud.getMouseX = function() return x end
        hud.getMouseY = function() return y end
    else
        hud.getMouseX, hud.getMouseY = nil, nil
    end
end
local function colorIs(c, tok) return c and tok and math.abs(c.r - tok.r) < 0.01 and math.abs(c.g - tok.g) < 0.01 and math.abs(c.b - tok.b) < 0.01 end
local function countColor(a)
    local T = ZeD.T
    return (a.n == 0 and T.danger) or (a.f > 0.5 and T.text) or (a.f > 0.25 and T.warningText) or T.danger
end

-- the layout and the pad for one gun
local function layout(tag)
    local h, hi = box("hand", "p")
    local a, ai = box("ammo")
    check(a ~= nil, tag .. ": the ammo box is on the belt")
    if not (a and h) then return end
    check(ai == hi + 1 and a.x >= h.x + h.w, tag .. ": right after the main hand (hand " .. h.x .. "+" .. h.w .. ", box " .. a.x .. " w " .. a.w .. ")")
    hud._gp = { idx = hi, inList = false, row = 1, list = {} }
    local nx = hud:_padStep(hi, 1)
    check(nx == nil or hud._boxes[nx].kind ~= "ammo", tag .. ": the pad steps over the ammo box (next " .. tostring(nx and hud._boxes[nx].kind) .. ")")
    hud._gp = nil
end

local pistol, shotgun, revolver
-- 1. the pistol
step(5, function()
    pistol = give("Base.Pistol")
    pcall(function() pistol:setContainsClip(true) end)
    pistol:setCurrentAmmoCount(12)
    pcall(function() pistol:setRoundChambered(true) end)
    local _, mags = give("Base.9mmClip", 2)
    mags[1]:setCurrentAmmoCount(15); mags[2]:setCurrentAmmoCount(9)
    give("Base.Bullets9mm", 34)
    give("Base.Bullets9mmBox", 1)
    p:setPrimaryHandItem(pistol); p:setSecondaryHandItem(nil)
    local cw = ZeD_CharacterWindow.getWindow()
    if cw and cw:isVisible() then ZeD_CharacterWindow.toggleBothPaired(p:getPlayerNum()) end   -- the belt in plain sight
end)
step(40, function()
    local a = B.ammo(p)
    if not check(a ~= nil, "pistol: read as a gun with ammo") then return end
    local count, s1, s2 = B.ammoWords(a)
    say(string.format("pistol: inGun %d chambered %s max %d mags {%s} loaded %d loose %d boxes %d words [%s] [%s] [%s]", a.inGun,
        tostring(a.chambered), a.max, table.concat(a.mags, ","), a.loaded, a.loose, a.boxes, count, s1, tostring(s2)))
    check(a.inGun == 12 and a.chambered, "pistol: 12 in the gun, 1 chambered")
    check(count == "12+1", "pistol: the count reads 12+1 (" .. count .. ")")
    check(a.loaded >= 2 and s1 == ZeD.tr("UI_ZeD_Belt_AmmoMags", a.loaded), "pistol: loaded magazines first (" .. s1 .. ")")
    check(a.loose >= 34 and s2 == ZeD.tr("UI_ZeD_Belt_AmmoRounds", a.loose), "pistol: then the loose rounds (" .. tostring(s2) .. ")")
    check(a.boxes >= 1, "pistol: the box is seen (" .. a.boxes .. ")")
    check(a.icon ~= nil, "pistol: the magazine's picture")
    check(colorIs(countColor(a), ZeD.T.text), "pistol: over half full, the count in the text colour")
    layout("pistol")
    shot("1_pistol")
end)
step(5, function() pointAt(box("ammo")) end)
step(30, function()
    local hv = hud._hover
    check(hv and hv.b.kind == "ammo", "pistol: the pointer over the box is its hover (" .. tostring(hv and hv.b.kind) .. ")")
    local l1, l2 = B.ammoLines(B.ammo(p))
    say("pistol hover: " .. l1 .. " || " .. l2)
    check(l1:find("12", 1, true) ~= nil and l2:find("15, 9", 1, true) ~= nil, "pistol: the hover gives the full count")
    shot("2_pistol_hover")
end)
step(5, function() pointAt(box("hand", "p")) end)
step(30, function()
    local hv = hud._hover
    check(hv and hv.b.kind == "hand" and hv.b.which == "p", "pistol: the pointer over the main hand (" .. tostring(hv and hv.b.kind) .. ")")
    shot("3_pistol_hand_hover")
    pointAt(nil)
end)
-- worn: a fifth full, then about half
step(5, function() pcall(function() pistol:setRoundChambered(false) end); pistol:setCurrentAmmoCount(3) end)
step(20, function()
    hud._ammo = nil
    local a = B.ammo(p)
    check(colorIs(countColor(a), ZeD.T.danger), "pistol 3 of 15: the count in the danger colour")
    shot("4_pistol_low")
end)
step(5, function() pcall(function() pistol:setRoundChambered(true) end); pistol:setCurrentAmmoCount(6) end)
step(20, function()
    hud._ammo = nil
    local a = B.ammo(p)
    check(colorIs(countColor(a), ZeD.T.warningText), "pistol 6+1 of 15: the count amber")
    shot("5_pistol_amber")
end)
-- 2. the shotgun, in both hands
step(5, function()
    shotgun = give("Base.Shotgun")
    shotgun:setCurrentAmmoCount(3)
    pcall(function() shotgun:setRoundChambered(true) end)
    give("Base.ShotgunShells", 17)
    give("Base.ShotgunShellsBox", 1)
    p:setPrimaryHandItem(shotgun); p:setSecondaryHandItem(shotgun)
end)
step(40, function()
    local a = B.ammo(p)
    if not check(a ~= nil, "shotgun: read as a gun with ammo") then return end
    local count, s1, s2 = B.ammoWords(a)
    say(string.format("shotgun: inGun %d chambered %s loose %d boxes %d words [%s] [%s] [%s]", a.inGun, tostring(a.chambered), a.loose, a.boxes, count, s1, tostring(s2)))
    check(count == "3+1", "shotgun: 3+1 (" .. count .. ")")
    check(a.loaded == 0 and s1 == ZeD.tr("UI_ZeD_Belt_AmmoRounds", a.loose), "shotgun: the loose shells (" .. s1 .. ")")
    check(s2 == ZeD.tr("UI_ZeD_Belt_AmmoBoxes", a.boxes), "shotgun: the box named, not counted (" .. tostring(s2) .. ")")
    layout("shotgun")
    pointAt(box("ammo"))
end)
step(30, function()
    local l1, l2 = B.ammoLines(B.ammo(p))
    say("shotgun hover: " .. l1 .. " || " .. l2)
    shot("6_shotgun")
    pointAt(nil)
end)
-- 3. the empty revolver (its .357 rounds carried are put aside for this case)
local aside = {}
step(5, function()
    revolver = give("Base.Revolver")
    revolver:setCurrentAmmoCount(0)
    pcall(function() revolver:setRoundChambered(false) end)
    p:setPrimaryHandItem(revolver); p:setSecondaryHandItem(nil)
    local key = B.ammo(p) and B.ammo(p).key
    local list = key and inv:getAllTypeRecurse(key)
    for i = 0, (list and list:size() or 0) - 1 do
        local it = list:get(i)
        aside[#aside + 1] = { it = it, from = it:getContainer() }
    end
    for _, e in ipairs(aside) do e.from:Remove(e.it) end
    say("set aside " .. #aside .. " .357 rounds")
end)
step(40, function()
    local a = B.ammo(p)
    if not check(a ~= nil, "empty: read as a gun with ammo") then return end
    local count, s1 = B.ammoWords(a)
    check(count == ZeD.tr("UI_ZeD_Belt_AmmoEmpty"), "empty: EMPTY (" .. count .. ")")
    check(colorIs(countColor(a), ZeD.T.danger), "empty: the danger colour")
    check(s1 == ZeD.upper(getText("IGUI_None")), "empty: nothing carried says so (" .. s1 .. ")")
    local l1, l2 = B.ammoLines(a)
    say("empty hover: " .. l1 .. " || " .. l2)
    layout("empty")
    pointAt(box("ammo"))
end)
step(30, function() shot("7_empty"); pointAt(nil) end)
-- 4. a melee weapon: no ammo box
step(5, function() p:setPrimaryHandItem(was.p1); p:setSecondaryHandItem(was.p2) end)
step(30, function()
    local a = box("ammo")
    local gun = B.ammo(p)
    check((a == nil) == (gun == nil), "the hands put back: an ammo box only with a gun (" .. tostring(a ~= nil) .. ")")
end)
step(5, function()
    for _, e in ipairs(aside) do e.from:AddItem(e.it) end
    for _, it in ipairs(given) do
        local c = it:getContainer()
        if c then c:Remove(it) end
    end
    hud._ammo = nil
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local function onTick()
    if not Q[qi] then Events.OnTick.Remove(onTick); return end
    wait = wait + 1
    if wait < Q[qi].n then return end
    wait = 0
    local ok, e = pcall(Q[qi].fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. " " .. tostring(e)) end
    qi = qi + 1
end
Events.OnTick.Add(onTick)
say("start")
