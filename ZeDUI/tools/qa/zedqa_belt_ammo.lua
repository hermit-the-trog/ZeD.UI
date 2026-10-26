-- ZeDUI/tools/qa/zedqa_belt_ammo.lua  (Oct 26 2026)
-- The ammo pouch beside the main hand (mockup zed_belt_ammo_dash_v1, style B; approved Oct 26 2026; redrawn the
-- same day to the director's "needs segments for each round"):
--   pistol   an M9, 12 in the magazine and 1 chambered; two magazines (15, 9), 34 loose rounds, a box:
--            "12+1", "2 MAG", "34 RDS"; 15 segments and the chamber's
--   shotgun  a JS-2000 in both hands, 2 shells in the tube, none chambered, 17 shells and a box: "2", "+1 BOX"
--   rifle    an M16, 22 in a 30-round magazine and 1 chambered: 30 segments in groups of five
--   empty    a revolver with nothing in it: "EMPTY", the danger colour, no chamber segment
--   low      the pistol at 3 (danger) and 6+1 (amber)
-- Each gun at 1.75x and at 1.0x (ZeD's UI scale), a picture of each and the belt's place on the screen
-- (zqa_ba_<scale>_<gun>.png; "ZEDQA ba rect" lines for the close-up crops). Then the pad steps over the pouch, the
-- hover gives the full count, and ZeD setup's "Ammo on the belt" switched off takes the pouch away (and back on).
-- Then the pouch in Light and High contrast (Oct 26 2026): spent rounds 3:1 off the pouch and hollow, the words readable
-- (zqa_ba_175_<theme>_<gun>.png). Then the slots' and the pouch's frame in Dark, Light (and Light's old frame) and High
-- contrast: 3:1 off the fill and the strap in Light, no worse elsewhere, the same lines on both (zqa_ba_frame_<theme>.png).
-- Everything given is taken back; the hands, the scale and the switch are put back. grep "ZEDQA ba".
local p = getPlayer()
local B = ZeD.Belt
local S = ZeD.Settings
local function say(s) print("ZEDQA ba " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ba_" .. n .. ".png") end) end
if not (B and B.ammo and B.segLayout and S and S.ammoBoxOption) then say("ERR the new code is not loaded"); say("DONE"); return end
local hud = B.getHUD()
local inv = p:getInventory()
local was = { p1 = p:getPrimaryHandItem(), p2 = p:getSecondaryHandItem(), scale = S.uiScaleOption:getValue() or 1, sw = S.ammoBoxOption:getValue() or 2,
    base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
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
    if B.ammoInk then return B.ammoInk(a).text end
    return (a.n == 0 and T.danger) or (a.f > 0.5 and T.text) or (a.f > 0.25 and T.warningText) or T.danger
end
local function rect(tag)
    say(string.format("rect %s %d %d %d %d", tag, hud:getAbsoluteX(), hud:getAbsoluteY(), hud:getWidth(), hud:getHeight()))
end

-- the guns
local guns = {}
local function setup()
    local pistol = give("Base.Pistol")
    pcall(function() pistol:setContainsClip(true) end)
    local _, mags = give("Base.9mmClip", 2)
    mags[1]:setCurrentAmmoCount(15); mags[2]:setCurrentAmmoCount(9)
    give("Base.Bullets9mm", 34); give("Base.Bullets9mmBox", 1)
    local shotgun = give("Base.Shotgun")
    give("Base.ShotgunShells", 17); give("Base.ShotgunShellsBox", 1)
    local rifle = give("Base.AssaultRifle")
    pcall(function() rifle:setContainsClip(true) end)
    local _, rm = give("Base.556Clip", 1); rm[1]:setCurrentAmmoCount(30)
    local revolver = give("Base.Revolver")
    guns = {
        { "pistol", pistol, 12, true, false }, { "shotgun", shotgun, 2, false, true },
        { "rifle", rifle, 22, true, false }, { "empty", revolver, 0, false, false },
    }
end
local function hold(g)
    local gun = g[2]
    gun:setCurrentAmmoCount(g[3])
    pcall(function() gun:setRoundChambered(g[4]) end)
    p:setPrimaryHandItem(gun); p:setSecondaryHandItem(g[5] and gun or nil)
    hud._ammo = nil
end

step(5, function()
    setup()
    local cw = ZeD_CharacterWindow.getWindow()
    if cw and cw:isVisible() then ZeD_CharacterWindow.toggleBothPaired(p:getPlayerNum()) end
end)
-- the gallery: each gun at 1.75x and 1.0x
for _, sc in ipairs({ { 7, "175" }, { 4, "100" } }) do
    step(5, function() S.uiScaleOption:setValue(sc[1]); S.applyScale() end)
    for gi = 1, 4 do
        step(20, function() hold(guns[gi]) end)
        step(40, function()
            local g = guns[gi]
            local a = B.ammo(p)
            local ab = box("ammo")
            if not check(a ~= nil and ab ~= nil, sc[2] .. " " .. g[1] .. ": the pouch is on the belt") then return end
            local count, s1, s2 = B.ammoWords(a)
            local L = B.segLayout(a.max, a.chamber, math.floor((ab.w - 2 * ZeD.T.px(4)) / math.max(1, ZeD.T.art or 1)))
            say(string.format("%s %s: in %d chambered %s max %d chamber %s loaded %d loose %d boxes %d words [%s] [%s] [%s] segs %s",
                sc[2], g[1], a.inGun, tostring(a.chambered), a.max, tostring(a.chamber), a.loaded, a.loose, a.boxes, count, s1, tostring(s2),
                L and string.format("sw %d gap %d group %d groupGap %d width %d art px", L.sw, L.gap, L.group, L.gg, L.w) or "bar"))
            check(L ~= nil, sc[2] .. " " .. g[1] .. ": a segment for each round fits (" .. a.max .. ")")
            if g[1] == "rifle" then check(L and L.group == 5, sc[2] .. " rifle: 30 rounds in groups of five") end
            if g[1] == "empty" then
                check(count == ZeD.tr("UI_ZeD_Belt_AmmoEmpty") and colorIs(countColor(a), ZeD.T.dangerText) and not a.chamber, sc[2] .. " empty: EMPTY in the danger colour, no chamber segment")
            end
            if g[1] == "pistol" then
                check(count == "12+1" and s1 == ZeD.tr("UI_ZeD_Belt_AmmoMags", a.loaded) and a.loaded >= 2, sc[2] .. " pistol: 12+1, the magazines first (" .. s1 .. ")")
            end
            if g[1] == "shotgun" then
                check(count == "2" and s2 == ZeD.tr("UI_ZeD_Belt_AmmoBoxes", a.boxes), sc[2] .. " shotgun: 2 in the tube, the box named (" .. tostring(s2) .. ")")
            end
            local h, hi = box("hand", "p")
            local _, ai = box("ammo")
            check(ai == hi + 1 and ab.x - (h.x + h.w) >= ZeD.T.px(10), sc[2] .. " " .. g[1] .. ": right after the main hand, its own gap (" .. (ab.x - h.x - h.w) .. " px)")
            rect(sc[2] .. "_" .. g[1])
            shot(sc[2] .. "_" .. g[1])
        end)
    end
end
-- the pouch in the Light and High contrast themes (1.75x; Oct 26 2026: it was only looked at in Dark). The pouch's
-- inks come from the live tokens (B.ammoInk): a spent round must stand 3:1 off the pouch, and a loaded round must
-- not look like a spent one (a different shape where the colours cannot be 3:1 apart)
local function flat(c, a, under) return { r = c.r * a + under.r * (1 - a), g = c.g * a + under.g * (1 - a), b = c.b * a + under.b * (1 - a) } end
local function inks(a)
    local T = ZeD.T
    local k = B.ammoInk and B.ammoInk(a) or { fill = countColor(a), text = countColor(a), spent = T.borderS, spentA = 0.55, hollow = false }
    local worst = 99
    for _, w in ipairs({ 0, 1 }) do
        local bg = flat(T.surf2, 0.95, { r = w, g = w, b = w })
        local sp = flat(k.spent, k.spentA or 1, bg)
        local ld = flat(k.fill, 1, bg)
        local tx = flat(k.text, k.text.a or 1, bg)
        worst = math.min(worst, ZeD.contrast(sp, bg))
        k.ls = math.min(k.ls or 99, ZeD.contrast(ld, sp))
        k.tb = math.min(k.tb or 99, ZeD.contrast(tx, bg))
        k.dim = math.min(k.dim or 99, ZeD.contrast(flat(T.textDim, T.textDim.a or 1, bg), bg))
    end
    k.sb = worst
    return k
end
for _, th in ipairs({ "light", "hicon" }) do
    step(5, function()
        S.uiScaleOption:setValue(7); S.applyScale()
        ZeD.applyTheme(th, was.accent, was.size)
    end)
    for gi = 1, 4 do
        step(20, function() hold(guns[gi]) end)
        step(40, function()
            local g = guns[gi]
            local a = B.ammo(p)
            if not check(a ~= nil and box("ammo") ~= nil, th .. " " .. g[1] .. ": the pouch is on the belt") then return end
            local k = inks(a)
            say(string.format("%s %s: spent vs pouch %.2f, loaded vs spent %.2f, count text %.2f, carried text %.2f, spent hollow %s",
                th, g[1], k.sb, k.ls, k.tb, k.dim, tostring(k.hollow)))
            if a.max > a.inGun then
                check(k.sb >= 3, th .. " " .. g[1] .. ": spent rounds 3:1 off the pouch (" .. string.format("%.2f", k.sb) .. ")")
                check(k.ls >= 3 or k.hollow, th .. " " .. g[1] .. ": loaded and spent apart at a glance (" .. string.format("%.2f", k.ls) .. (k.hollow and ", spent drawn hollow" or "") .. ")")
            end
            check(k.tb >= 4.5 and k.dim >= 4.5, th .. " " .. g[1] .. ": the count and carried words read (" .. string.format("%.2f / %.2f", k.tb, k.dim) .. ")")
            rect("175_" .. th .. "_" .. g[1])
            shot("175_" .. th .. "_" .. g[1])
        end)
    end
end
-- The slots' and the pouch's frame (Oct 26 2026: the frame grey stood 2.3:1 off the fill in Light). From the live
-- tokens: the keyline (T.frameS) 3:1 off the slots' fills (empty surf1, full surf2, at their 0.95 over black and
-- white) in Light, and the outer line (T.frameHi) 3:1 off the leather strap (its art's darkest and lightest tones)
-- and off the keyline; Dark and High contrast no worse than their strong border was. Then the frame actually drawn:
-- the same lines, insets and colours on a slot as on the pouch. "before" is the old frame (the strong border alone)
-- for the comparison picture. Pictures zqa_ba_frame_<theme>.png with the whole belt.
local STRAP = { { r = 86 / 255, g = 57 / 255, b = 31 / 255 }, { r = 106 / 255, g = 76 / 255, b = 43 / 255 }, { r = 59 / 255, g = 42 / 255, b = 27 / 255 } }
local function frameRatios()
    local T = ZeD.T
    local fs, fh = T.frameS or T.borderS, T.frameHi
    local r = { fill = 99, old = 99, strap = 99, oldStrap = 99, inner = 99 }
    for _, s in ipairs({ T.surf1, T.surf2 }) do
        for _, w in ipairs({ 0, 1 }) do
            local bg = flat(s, 0.95, { r = w, g = w, b = w })
            r.fill = math.min(r.fill, ZeD.contrast(flat(fs, fs.a or 1, bg), bg))
            r.old = math.min(r.old, ZeD.contrast(flat(T.borderS, T.borderS.a or 1, bg), bg))
        end
    end
    local out = (fh and (fh.a or 1) > 0) and fh or fs
    for _, c in ipairs(STRAP) do
        r.strap = math.min(r.strap, ZeD.contrast(out, c))
        r.oldStrap = math.min(r.oldStrap, ZeD.contrast(T.borderS, c))
    end
    if out ~= fs then r.inner = ZeD.contrast(out, fs) end
    return r
end
-- the frame lines a box draws in a frame: {inset, colour} of each drawRectBorder inside the box
local frameLog = nil
local function hookFrames()
    frameLog = {}
    hud.drawRectBorder = function(self, x, y, w, h, a, r, g, b)
        frameLog[#frameLog + 1] = { x = x, y = y, w = w, h = h, c = string.format("%.3f,%.3f,%.3f,%.2f", r or 0, g or 0, b or 0, a or 1) }
        return ISUIElement.drawRectBorder(self, x, y, w, h, a, r, g, b)
    end
end
local function linesOf(b)
    local out, seen = {}, {}
    for _, l in ipairs(frameLog or {}) do
        if l.x >= b.x and l.y >= b.y and l.x + l.w <= b.x + b.w and l.y + l.h <= b.y + b.h then
            local e = (l.x - b.x) .. "/" .. (l.y - b.y) .. "/" .. (b.x + b.w - l.x - l.w) .. "/" .. (b.y + b.h - l.y - l.h) .. " " .. l.c
            if not seen[e] then seen[e] = true; out[#out + 1] = e end   -- (the log spans a few frames)
        end
    end
    return table.concat(out, " | ")
end
local FRAMES = { { "dark", "dark" }, { "light_before", "light" }, { "light", "light" }, { "hc", "hicon" } }
for _, fr in ipairs(FRAMES) do
    step(5, function()
        S.uiScaleOption:setValue(7); S.applyScale()
        ZeD.applyTheme(fr[2], was.accent, was.size)
        if fr[1] == "light_before" then ZeD.T.frameS = ZeD.T.borderS; ZeD.T.frameHi = nil end   -- the old frame, for the picture
        hold(guns[1])
    end)
    step(30, function() hookFrames() end)
    step(3, function()
        hud.drawRectBorder = nil
        local T = ZeD.T
        local r = frameRatios()
        say(string.format("frame %s: keyline vs fill %.2f (strong border %.2f), outer vs strap %.2f (strong border %.2f), outer vs keyline %s",
            fr[1], r.fill, r.old, r.strap, r.oldStrap, r.inner < 99 and string.format("%.2f", r.inner) or "-"))
        if fr[1] == "light" then
            check(r.fill >= 3, "light: the frame 3:1 off the slots' fill (" .. string.format("%.2f", r.fill) .. ", was " .. string.format("%.2f", r.old) .. ")")
            check(r.strap >= 3, "light: the frame 3:1 off the strap behind it (" .. string.format("%.2f", r.strap) .. ", was " .. string.format("%.2f", r.oldStrap) .. ")")
            check(r.inner >= 3, "light: its outer line 3:1 off its keyline (" .. string.format("%.2f", r.inner) .. ")")
            -- every accent tints the greys: the worst of them
            local wf, ws, wk = 99, 99, 99
            for key, _ in pairs(ZeD.AccentColors) do
                ZeD.applyTheme("light", key, was.size)
                local q = frameRatios()
                wf, ws, wk = math.min(wf, q.fill), math.min(ws, q.strap), math.min(wk, q.inner)
            end
            ZeD.applyTheme("light", was.accent, was.size)
            check(wf >= 3 and ws >= 3 and wk >= 3, string.format("light, every accent: worst keyline vs fill %.2f, outer vs strap %.2f, outer vs keyline %.2f", wf, ws, wk))
        elseif fr[1] ~= "light_before" then
            check(r.fill >= r.old - 0.005 and r.strap >= r.oldStrap - 0.005, fr[1] .. ": the frame no worse than the strong border was")
        end
        -- the drawn frame: the same on a slot as on the pouch
        local ab = box("ammo")
        local sl = nil
        for _, b in ipairs(hud._boxes) do if b.kind == "slot" and linesOf(b) ~= "" then sl = b; break end end
        if check(ab ~= nil and sl ~= nil, fr[1] .. ": a framed slot and the pouch drawn") then
            local a1, s1 = linesOf(ab), linesOf(sl)
            say(fr[1] .. " pouch frame: " .. a1)
            say(fr[1] .. " slot frame:  " .. s1)
            if fr[1] ~= "light_before" then check(a1 == s1, fr[1] .. ": the slot's frame and the pouch's are the same lines") end
            local fs = T.frameS or T.borderS
            if fr[1] ~= "light_before" then
                check(a1:find(string.format("%.3f,%.3f,%.3f", fs.r, fs.g, fs.b), 1, true) ~= nil, fr[1] .. ": drawn in the live frame token")
            end
        end
        rect("frame_" .. fr[1])
        shot("frame_" .. fr[1])
    end)
end
step(5, function() ZeD.applyTheme(was.base, was.accent, was.size); S.uiScaleOption:setValue(4); S.applyScale() end)
-- the low counts' colours (1.0x)
step(5, function() hold({ "low", guns[1][2], 3, false, false }) end)
step(20, function() check(colorIs(countColor(B.ammo(p)), ZeD.T.dangerText), "pistol 3 of 15: the danger colour"); rect("100_low"); shot("100_low") end)
step(5, function() hold({ "amber", guns[1][2], 6, true, false }) end)
step(20, function() check(colorIs(countColor(B.ammo(p)), ZeD.T.warningText), "pistol 6+1 of 15: amber") end)
-- back to 1.75x: the hover and the pad
step(5, function() S.uiScaleOption:setValue(7); S.applyScale(); hold(guns[1]) end)
step(30, function() pointAt(box("ammo")) end)
step(30, function()
    local hv = hud._hover
    check(hv and hv.b.kind == "ammo", "the pointer over the pouch is its hover")
    local l1, l2 = B.ammoLines(B.ammo(p))
    say("hover: " .. l1 .. " || " .. l2)
    check(l2:find("15, 9", 1, true) ~= nil, "the hover gives the full count")
    rect("175_hover"); shot("175_hover")
    pointAt(nil)
    local _, hi = box("hand", "p")
    hud._gp = { idx = hi, inList = false, row = 1, list = {} }
    local nx = hud:_padStep(hi, 1)
    check(nx == nil or hud._boxes[nx].kind ~= "ammo", "the pad steps over the pouch")
    hud._gp = nil
end)
-- the switch
step(5, function() S.ammoBoxOption:setValue(1) end)
step(20, function()
    check(box("ammo") == nil and hud:_ammoState(p) == nil, "Ammo on the belt off: no pouch, the belt as it was")
    rect("175_off"); shot("175_off")
    S.ammoBoxOption:setValue(2)
end)
step(20, function() check(box("ammo") ~= nil, "Ammo on the belt on again: the pouch is back") end)
step(5, function()
    S.ammoBoxOption:setValue(was.sw)
    S.uiScaleOption:setValue(was.scale); S.applyScale()
    p:setPrimaryHandItem(was.p1); p:setSecondaryHandItem(was.p2)
    for _, it in ipairs(given) do local c = it:getContainer(); if c then c:Remove(it) end end
    hud._ammo = nil
end)
step(20, function()
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
