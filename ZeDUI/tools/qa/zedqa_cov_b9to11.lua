-- ZeDUI/tools/qa/zedqa_cov_b9to11.lua  (Nov 12 2026, QA coverage; tag cov_b9to11)
-- Real checks for the beta 9 to 11 fixes no check reached (qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md, Table B and B3).
-- In game, on the ZeD-QA save only (it stops at once on any other save). Copy to Zomboid/Lua/zedqa.lua and bump
-- zedqa.go, or run cov_b9to11.txt with zedqa_run.ps1; grep "ZEDQA cov_b9to11". PASS / FAIL / INFO / SHOT lines, a
-- RESULT line, then DONE. Pictures: Screenshots/zqa_cov_b9to11_*.png.
--
-- How it reads what was drawn: for one UI frame at a time (Events.OnPreUIDraw to OnPostUIDraw) it wraps the draw
-- calls the fixes go through (ZeD.Text.draw, ZeD.Atoms.drawTextRight, ZeD.Molecules.drawButton, ZeD.TabPx.drawTab
-- and drawIcon, and the belt's and the tab strips' own drawTextureScaled), records their arguments and the palette at
-- the call, and checks them against the panel's fields and the model it drew from. Every wrapper passes the call on
-- unchanged, and all are taken off at the end (and at once on an error).
--
-- WHAT IT CHECKS. Each pass runs at the scale the run starts at ("a") and again at a second UI scale ("b": 1.0 when
-- the run starts at 1.3 or more, else the largest step the screen's cap allows; none on a Deck at 0.75).
--   #159 windows jumping: both windows on the screen, apart, and still for 120 ticks with nothing pressed; opening
--        Identity, Health, Radio and Loot in the Character window never moves the World window; the pair shut and
--        opened again comes back where and as big as it was; a UI scale change through ZeD's own path (the Scale hook
--        closes, re-themes and reopens the windows) keeps each window's place in design units (the Character window's
--        right edge, the World window's left edge, both tops), and back at the first scale both windows are exactly
--        where they were
--   tab-strip icons (ZeD_TabPx): every tab a strip offers has a lit icon, drawn inside its hit zone, once, centred, at
--        16 x k whole pixels (k = the root scale rounded); its six pictures (shadow, five tones) in order; the shadow
--        one texel down-right at 0.55 idle / 0.25 active; the idle icon's middle tone is the accent the window draws
--        in, the active one's leans to textOnAccent; one tab drawn active, the window's own; with the window's accent
--        switched the idle icons follow it. Every icon's art is 16 x 16 (once)
--   belt strap and buckles (ZeD_Belt): the strap is the art's 30 texels at the whole zoom T.art, centred on the row;
--        the buckle's place 58 x 40 at T.art, on the screen's centre and on the strap; the slots split evenly round
--        it, all on the strap; the strap pieces run end to end, each slot's piece its provider's material
--        (B.materialFor), the waist belt's run under the buckle; in the frame each piece's two ends and repeated
--        middle are drawn from its material's art at the whole zoom, and the closure or profession buckle at 58 x 40
--        x T.art in its place; with another profession (pass a) the drawn buckle is that profession's. Art sizes too
--   #147 permit stamp: a revoked permit (burglar) on the wide license draws PERMIT and the red REVOKED on one line with
--        a visible word space (at least a quarter line: the face's "a a" less "aa", a lone space measures 0 in it),
--        the line centred under CONCEALED CARRY; a valid permit (police officer) draws no REVOKED, PERMIT centred
--   #148 Health percent: with injury rows staged in the model the tab draws (8 rows under the figure, then 1 row with
--        the figure folded; the scrollbar state reported), every row's percent, "%" and all, lies inside its row and
--        inside the tab's stencil (win._healthView), and every row ends inside it
--   #140 radio preset "+": a ValuTech radio in hand with the faces off (the drawn chassis): the + is filled with the
--        accent the window draws in, bordered in the bright accent, its glyph in textOnAccent, not beta 9's fixed
--        orange; a click on it (RadioTab.onClick, the mouse's path) arms assign mode and the + lights in the bright
--        accent; a second click disarms it; with the window's accent switched the + follows it
--   #134 Custom Map Labels on ZeD's map (pass a): the game's Show opens ZeD's map (the game's own stays shut), bound to
--        the game's symbol store; a map mod's place label (text-place, the layer's colour, not user defined) and a
--        player's note (text-note, red ink) staged in the store are read by ZeD's map; in Survey, Color and Paper (the
--        style menu's path) the style has the game's text layers, text-note draws at zoom 14.5, text-place draws in
--        Survey and Color and is hidden in Paper (by design), and both symbols keep their layers and colours
-- PUT BACK at the end, and at once on an error: the wrappers, the radio (taken away) and the hands, the profession,
-- the belt's form, the Identity and radio QA switches, the window accents, the Health model, the two symbols, the
-- map's style and pop-out, the UI scale, the window flags, each window's place and tab (ZeD's own Go to saved position
-- path; the player's saved places are not written), the debug console, and the pair shut again if it was shut.

local TAG = "cov_b9to11"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local R = { pass = 0, fail = 0 }
local function check(ok, what, got, want)
    if ok then
        R.pass = R.pass + 1
        say("PASS " .. what .. (got ~= nil and (" [" .. tostring(got) .. "]") or ""))
    else
        R.fail = R.fail + 1
        say("FAIL " .. what .. " (" .. tostring(got) .. " vs " .. tostring(want) .. ")")
    end
    return ok and true or false
end
local function note(s) say("INFO " .. tostring(s)) end
local function shot(name)
    local f = "zqa_cov_b9to11_" .. name .. ".png"
    pcall(function() getCore():TakeFullScreenshot(f) end)
    say("SHOT " .. f)
end
local function safe(what, fn, a1, a2, a3)
    local ok, e = pcall(fn, a1, a2, a3)
    if not ok then check(false, what .. ": the check itself raised an error", tostring(e), "no error") end
end

local p = getPlayer()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Z = ZeD or {}
local TP, HT, IT, RT = Z.TabPx, Z.HealthTab, Z.IdentityTab, Z.RadioTab
local BL, MN, WP, SC = Z.Belt, Z.MapNotes, Z.WindowPlaces, Z.Scale

do
    local wn = "?"
    pcall(function() wn = tostring(getWorld():getWorld()) end)
    if not p then say("ERR no player: nothing was done"); say("DONE"); return end
    if not string.find(wn, "ZeD-QA", 1, true) then say("ERR this is not the ZeD-QA save (" .. wn .. "): nothing was done"); say("DONE"); return end
    if not (CWm and WWm and TP and HT and IT and RT and BL and MN and WP and SC and Z.Text and Z.Atoms and Z.Molecules and Z.MapsTab) then
        say("ERR a ZeD module is missing: nothing was done"); say("DONE"); return
    end
end
-- a run before this one that never finished: its steps stop and its changes come off first
if type(ZEDQA_COV_B9TO11) == "table" then
    if ZEDQA_COV_B9TO11.stop then pcall(ZEDQA_COV_B9TO11.stop) end
    if ZEDQA_COV_B9TO11.restore then pcall(ZEDQA_COV_B9TO11.restore, "a run before this one") end
end
if getGameSpeed() <= 0 then setGameSpeed(1) end

-- ---------------------------------------------------------------------------------------------------------------
-- THE LEDGER: what the run changed, so it can be put back
-- ---------------------------------------------------------------------------------------------------------------
local L = {
    done = false, hooks = {}, wraps = {}, dbg = {}, at = {},
    prim = p:getPrimaryHandItem(), sec = p:getSecondaryHandItem(),
    useFaces = RT.useFaces,
    qa = { prof = IT.qaProf, layout = IT.qaLayout, style = IT.qaStyle, trend = IT.qaTrend },
    override = SC.override,
    -- the functions the run wraps, as found (the put-back check compares against them)
    orig = { draw = ZeD.Text.draw, tright = ZeD.Atoms.drawTextRight, btn = ZeD.Molecules.drawButton, tab = TP.drawTab, icon = TP.drawIcon,
             hg = HT.gatherData },
}

-- ---------------------------------------------------------------------------------------------------------------
-- small helpers
-- ---------------------------------------------------------------------------------------------------------------
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function fi(v) if type(v) ~= "number" then return tostring(v) end; return tostring(math.floor(v + 0.5)) end
local function cp(c) if not c then return nil end; return { r = c.r, g = c.g, b = c.b } end
local function near(a, b) return a ~= nil and b ~= nil and math.abs(a.r - b.r) < 0.004 and math.abs(a.g - b.g) < 0.004 and math.abs(a.b - b.b) < 0.004 end
local function rgb(c) if not c then return "none" end; return string.format("%.3f,%.3f,%.3f", c.r, c.g, c.b) end
local function geo(w) if not w then return nil end; return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() } end
local function gs(g) if not g then return "none" end; return fi(g.x) .. "," .. fi(g.y) .. " " .. fi(g.w) .. "x" .. fi(g.h) end
local function sameGeo(a, b, tol)
    return a ~= nil and b ~= nil and math.abs(a.x - b.x) <= tol and math.abs(a.y - b.y) <= tol and math.abs(a.w - b.w) <= tol and math.abs(a.h - b.h) <= tol
end
local function overlap(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
local function screen() return getCore():getScreenWidth(), getCore():getScreenHeight() end
local function onScreen(g, sw, sh) return g.x >= 0 and g.y >= 0 and g.x + g.w <= sw and g.y + g.h <= sh end
local function shape()
    local t = {}
    for _, w in ipairs({ CW() or false, WW() or false }) do
        if w then t[#t + 1] = gs(geo(w)) .. "/" .. fi(w._drawerEffW or 0) else t[#t + 1] = "shut" end
    end
    return table.concat(t, ";")
end
local function pre(tag) return "[" .. tag .. " " .. tostring(L.at[tag] or "?") .. "]" end
local function texName(t)
    if t == nil then return nil end
    local ok, n = pcall(function() return t:getName() end)
    if ok then return n end
    return nil
end
local function texSame(a, b)
    if a == nil or b == nil then return false end
    if a == b then return true end
    local na, nb = texName(a), texName(b)
    return na ~= nil and na == nb
end
local function shared(path)
    local ok, t = pcall(function() return Texture.getSharedTexture(path, 3) end)
    if ok then return t end
    return nil
end
local function variantOf(key)
    local set = ZeD.AccentColors and ZeD.AccentColors[key]
    if not set then return nil end
    return (ZeD.currentBase == "light") and set.light or set.dark
end
-- an accent neither window draws in now
local function otherAccent()
    local c, w = CW(), WW()
    local a = (c and c._accentKey) or ZeD.currentAccent
    local b = (w and w._accentKey) or ZeD.currentAccent
    for _, k in ipairs({ "red", "blue", "green", "purple" }) do
        if k ~= a and k ~= b and ZeD.AccentColors[k] then return k end
    end
    return "red"
end
local function setWinAccent(k)
    local c, w = CW(), WW()
    L.acc = { c = c, w = w, ck = c and c._accentKey, wk = w and w._accentKey }
    L.accTest = k
    if c then c._accentKey = k end
    if w then w._accentKey = k end
end
local function restoreWinAccent()
    local a = L.acc
    if not a then return end
    L.acc = nil
    if a.c then a.c._accentKey = a.ck end
    if a.w then a.w._accentKey = a.wk end
end

-- ---------------------------------------------------------------------------------------------------------------
-- RECORDING ONE FRAME
-- ---------------------------------------------------------------------------------------------------------------
local CAP = { want = 0, on = false, done = 0, mark = 0, kinds = {}, text = {}, tright = {}, btn = {}, tabs = {}, icons = {}, belt = {}, icon = nil }
local function onPreUI()
    if CAP.want > 0 and not CAP.on then
        CAP.text, CAP.tright, CAP.btn, CAP.tabs, CAP.icons, CAP.belt, CAP.icon = {}, {}, {}, {}, {}, {}, nil
        CAP.on = true
    end
end
local function onPostUI()
    if CAP.on then CAP.on = false; CAP.want = CAP.want - 1; CAP.done = CAP.done + 1 end
end
local function wrap(tbl, name, make)
    local orig = tbl and tbl[name]
    if type(orig) ~= "function" then return false end
    L.wraps[#L.wraps + 1] = { t = tbl, n = name, f = orig }
    tbl[name] = make(orig)
    return true
end
local function unwrapAll()
    for i = #L.wraps, 1, -1 do local w = L.wraps[i]; w.t[w.n] = w.f end
    L.wraps = {}
end
-- an element's own method shadowed for one capture (the class's is used again when it comes off)
local function hookInst(o, name, rec)
    if not o then return end
    local orig = o[name]
    if type(orig) ~= "function" then return end
    L.hooks[#L.hooks + 1] = { o = o, n = name, had = rawget(o, name) }
    o[name] = function(self, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        if CAP.on then pcall(rec, self, a1, a2, a3, a4, a5, a6, a7, a8, a9) end
        return orig(self, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    end
end
local function unhookInst()
    for i = #L.hooks, 1, -1 do local h = L.hooks[i]; h.o[h.n] = h.had end
    L.hooks = {}
end
local function installWraps()
    wrap(ZeD.Text, "draw", function(orig) return function(el, f, str, x, y, zoom, r, g, b, a, align)
        if CAP.on and CAP.kinds.text then
            local t = CAP.text
            t[#t + 1] = { el = el, f = f, s = tostring(str), x = x, y = y, z = zoom or 1, r = r, g = g, b = b, al = align }
        end
        return orig(el, f, str, x, y, zoom, r, g, b, a, align)
    end end)
    wrap(ZeD.Atoms, "drawTextRight", function(orig) return function(panel, text, x, y, font, color)
        if CAP.on and CAP.kinds.tright then local t = CAP.tright; t[#t + 1] = { el = panel, s = tostring(text), x = x, y = y, font = font } end
        return orig(panel, text, x, y, font, color)
    end end)
    wrap(ZeD.Molecules, "drawButton", function(orig) return function(panel, x, y, w, h, text, variant, pressed, colors, opts)
        if CAP.on and CAP.kinds.btn and text == "+" then
            local T, c = ZeD.T, colors or {}
            local t = CAP.btn
            t[#t + 1] = { el = panel, x = x, y = y, w = w, h = h, variant = variant, bg = cp(c.bg), border = cp(c.border), text = cp(c.text),
                          acc = cp(T.accent), accB = cp(T.accentBright or T.accent), on = cp(T.textOnAccent) }
        end
        return orig(panel, x, y, w, h, text, variant, pressed, colors, opts)
    end end)
    wrap(TP, "drawTab", function(orig) return function(el, x, y, w, h, id, isActive, isWashed, line, opts)
        if CAP.on and CAP.kinds.tabs then
            local t = CAP.tabs
            t[#t + 1] = { el = el, x = x, y = y, w = w, h = h, id = id, active = isActive and true or false }
        end
        return orig(el, x, y, w, h, id, isActive, isWashed, line, opts)
    end end)
    wrap(TP, "drawIcon", function(orig) return function(el, id, cx, cy, isActive)
        if not (CAP.on and CAP.kinds.tabs) then return orig(el, id, cx, cy, isActive) end
        local T = ZeD.T
        local rec = { el = el, id = id, cx = cx, cy = cy, active = isActive and true or false, k = TP.k(),
                      acc = cp(T.accent), on = cp(T.textOnAccent), draws = {} }
        CAP.icon = rec
        local res = orig(el, id, cx, cy, isActive)
        CAP.icon = nil
        local t = CAP.icons
        t[#t + 1] = rec
        return res
    end end)
end
local function iconRec(self, tex, x, y, w, h, a, r, g, b)
    local ic = CAP.icon
    if ic and ic.el == self then local d = ic.draws; d[#d + 1] = { tex = tex, x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b } end
end
local function hookStrips()
    local c, w = CW(), WW()
    hookInst(c and c._tabStripPanel, "drawTextureScaled", iconRec)
    hookInst(w and w._actionTabStrip, "drawTextureScaled", iconRec)
end
local function hookBelt()
    local hud = BL.getHUD and BL.getHUD(0)
    if not hud then return end
    hookInst(hud, "drawTextureScaled", function(self, tex, x, y, w, h)
        if CAP.kinds.belt then local t = CAP.belt; t[#t + 1] = { k = "ts", tex = tex, x = x, y = y, w = w, h = h } end
    end)
    hookInst(hud, "drawTextureScaledAspect", function(self, tex, x, y, w, h)
        if CAP.kinds.belt then local t = CAP.belt; t[#t + 1] = { k = "tsa", tex = tex, x = x, y = y, w = w, h = h } end
    end)
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE HEALTH MODEL: injury rows staged in what the tab draws (the player's body is never touched)
-- ---------------------------------------------------------------------------------------------------------------
local HEALTHS = { 100, 59, 100, 7, 100, 88, 100, 33 }
local function stagedEntries(n)
    local parts = p:getBodyDamage():getBodyParts()
    local out = {}
    for i = 1, n do
        local bp = parts:get(1 + i)   -- (from the left forearm on: QA's "Left Forearm 59" row)
        out[#out + 1] = { name = BodyPartType.getDisplayName(bp:getType()), health = HEALTHS[i], conditions = {}, worstSev = "ok", bodyPart = bp }
    end
    return out
end
local function injectHealth(n)
    L.inject = n
    if n and not L.hg then
        L.hg = HT.gatherData
        HT.gatherData = function(playerObj, opts)
            local d = L.hg(playerObj, opts)
            if L.inject and playerObj == p and opts == nil and type(d) == "table" then
                d.entries = stagedEntries(L.inject)
                d.injuredCount, d.woundedCount = #d.entries, 0
            end
            return d
        end
    elseif not n and L.hg then
        HT.gatherData = L.hg
        L.hg = nil
    end
    local w = CW()
    if w then w._healthCache = nil end
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE MAP (#134)
-- ---------------------------------------------------------------------------------------------------------------
local MARK1, MARK2 = "ZEDQA cov label 134", "ZEDQA cov note 134"
local function mapPanel() local w = WW(); return w and w._worldMapPanel end
local function storeFind(api, text)
    if not api then return nil end
    for i = 0, api:getSymbolCount() - 1 do
        local s = api:getSymbolByIndex(i)
        if s and s:isText() and s:getTranslatedText() == text then return s end
    end
    return nil
end
local function removeMarks()
    local api = MN.api()
    if not api then return 0 end
    local n = 0
    for i = api:getSymbolCount() - 1, 0, -1 do
        local s = api:getSymbolByIndex(i)
        local t = s and s:isText() and s:getTranslatedText()
        if t == MARK1 or t == MARK2 then api:removeSymbolByIndex(i); n = n + 1 end
    end
    return n
end
-- a text layer's fill alpha at zoom z, between its stops as the engine blends them
local function alphaAt(layer, z)
    local n = layer:getFillStops()
    if n <= 0 then return nil end
    local z0, a0 = layer:getFillZoom(0), layer:getFillAlpha(0)
    if z <= z0 then return a0 end
    for i = 1, n - 1 do
        local z1, a1 = layer:getFillZoom(i), layer:getFillAlpha(i)
        if z <= z1 then
            if z1 - z0 <= 0 then return a1 end
            return a0 + (a1 - a0) * (z - z0) / (z1 - z0)
        end
        z0, a0 = z1, a1
    end
    return a0
end
local function restoreMap()
    if L.symsAdded then removeMarks(); L.symsAdded = false end
    local w = WW()
    local mp = w and w._worldMapPanel
    if L.mapTouched then
        if mp and L.styleWas and mp.style ~= L.styleWas then pcall(ZeD.MapsTab.setStyle, w, L.styleWas) end
        local md = p:getModData()
        md.ZeD_MapStyle, md.ZeD_MapPaper = L.mdStyle, L.mdPaper
        L.mapTouched = false
    end
    if L.mapOpened then
        if not L.popWas and w and w._mapPopout then pcall(ISWorldMap.HideWorldMap, 0) end
        L.mapOpened = false
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- PUTTING IT ALL BACK
-- ---------------------------------------------------------------------------------------------------------------
-- the profession's id as the belt reads it ("base:burglar" -> "burglar"), nil without one
local function profIdNow()
    local desc = p:getDescriptor()
    local prof = desc and desc:getCharacterProfession()
    if prof == nil then return nil end
    return string.lower(tostring(prof:getName())):match("([^:]+)$")
end
local function restoreAll(why)
    if L.done then return end
    L.done = true
    CAP.on, CAP.want, CAP.icon = false, 0, nil
    pcall(unhookInst)
    pcall(unwrapAll)
    pcall(function() if L.hg then HT.gatherData = L.hg; L.hg = nil end end)
    pcall(function() Events.OnPreUIDraw.Remove(onPreUI) end)
    pcall(function() Events.OnPostUIDraw.Remove(onPostUI) end)
    pcall(function() IT.qaProf, IT.qaLayout, IT.qaStyle, IT.qaTrend = L.qa.prof, L.qa.layout, L.qa.style, L.qa.trend end)
    pcall(function() RT.useFaces = L.useFaces end)
    pcall(function() local w = CW(); if w then w._radioPresetAssignMode = false end end)
    pcall(restoreWinAccent)
    pcall(function()
        if L.radio then
            local it = L.radio
            L.radio = nil
            pcall(function() p:removeFromHands(it) end)
            local c = it:getContainer()
            if c then c:Remove(it) end
        end
    end)
    pcall(function()
        if L.handsChanged then
            local inv = p:getInventory()
            p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
            if L.prim and inv:contains(L.prim) then p:setPrimaryHandItem(L.prim) end
            if L.sec and inv:contains(L.sec) then p:setSecondaryHandItem(L.sec) end
            L.handsChanged = false
        end
    end)
    pcall(function() if L.profWas then p:getDescriptor():setCharacterProfession(L.profWas); L.profWas = nil end end)
    pcall(function() if L.beltStyleWas then ZeD.Settings.beltStyleOption:setValue(L.beltStyleWas); L.beltStyleWas = nil end end)
    pcall(restoreMap)
    pcall(function() if L.scaleChanged then SC.override = L.override; SC.refresh(); L.scaleChanged = false end end)
    pcall(function()
        local w = CW()
        if w and L.flags then
            w._identityPhotoExpanded, w._healthFigureExpanded = L.flags.id, L.flags.hf
            w._healthCache, w._identityCache = nil, nil
        end
    end)
    pcall(function() for _, e in ipairs(L.dbg) do e:setVisible(true) end end)
    ZEDQA_COV_B9TO11 = nil
    say("restored (" .. tostring(why) .. ")")
end
ZEDQA_COV_B9TO11 = { restore = restoreAll }
-- each window back to its place and tab at the start, through ZeD's own Go to saved position (the record is lent to
-- the places table for the call and taken back: the player's file is never written)
local function placeBack()
    if not (L.R0 and WP.goTo) then return end
    local pl = WP.places or WP.load()
    for _, k in ipairs({ "char", "world" }) do
        local rec = L.R0[k]
        local win = (k == "char") and CW() or WW()
        if rec and win then
            local old = pl[k]
            pl[k] = rec
            pcall(WP.goTo, win)
            pl[k] = old
        end
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE STEP QUEUE: step(n, fn) runs fn n ticks after the last step; waitUntil(max, cond, what, fn) polls cond each
-- tick and calls fn(true / false) when it holds or after max ticks. g = true: a step of the second scale pass,
-- skipped when there is no second scale.
-- ---------------------------------------------------------------------------------------------------------------
local Q, QI = {}, { i = 1, t = 0 }
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitUntil(max, cond, what, fn) Q[#Q + 1] = { max = max, cond = cond, what = what, fn = fn } end
local function gstep(g, n, fn) step(n, function() if g and not L.B then return end; fn() end) end
local function gwait(g, max, cond, what, fn)
    waitUntil(max, function() if g and not L.B then return true end; return cond() end, what, function(ok)
        if g and not L.B then return end
        if fn then fn(ok) elseif not ok then check(false, "waited for " .. what, "timed out", "within " .. max .. " ticks") end
    end)
end
local function stillCond()
    local st = { last = nil, same = 0 }
    return function()
        local s = shape()
        if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
        return st.same >= 30
    end
end
local function whenStill(g, tag, what)
    gwait(g, 900, stillCond(), "the windows to settle (" .. what .. ")", function(ok)
        if not ok then check(false, pre(tag) .. " #159 the windows settle: " .. what, "still moving", "still within 900 ticks") end
    end)
end
local function capture(g, kinds, hooks)
    gstep(g, 1, function()
        CAP.kinds = kinds
        if hooks then hooks() end
        CAP.want, CAP.mark = 1, CAP.done
    end)
    gwait(g, 120, function() return CAP.done > CAP.mark end, "one drawn frame", function(ok)
        unhookInst()
        if not ok then check(false, "a UI frame was drawn to read", "none", "one within 120 ticks") end
    end)
end
local function drive()
    local s = Q[QI.i]
    if not s then Events.OnTick.Remove(drive); return end
    QI.t = QI.t + 1
    local ok, err = true, nil
    if s.cond then
        local okc, yes = pcall(s.cond)
        if not okc then
            ok, err = false, yes
        elseif yes or QI.t >= s.max then
            QI.i, QI.t = QI.i + 1, 0
            if s.fn then ok, err = pcall(s.fn, yes and true or false)
            elseif not yes then check(false, "waited for " .. tostring(s.what), "timed out", "within " .. s.max .. " ticks") end
        end
    elseif QI.t >= s.n then
        QI.i, QI.t = QI.i + 1, 0
        ok, err = pcall(s.fn)
    end
    if not ok then
        say("ERR step " .. tostring(QI.i) .. ": " .. tostring(err))
        Events.OnTick.Remove(drive)
        R.fail = R.fail + 1
        restoreAll("an error")
        pcall(placeBack)
        say("RESULT " .. R.pass .. " pass, " .. R.fail .. " fail")
        say("DONE")
    end
end
ZEDQA_COV_B9TO11.stop = function() Events.OnTick.Remove(drive) end

-- ---------------------------------------------------------------------------------------------------------------
-- TABS: clicks on the strips' own hit zones (the mouse's path)
-- ---------------------------------------------------------------------------------------------------------------
local function clickTab(win, strip, id)
    if not (win and strip) then return false end
    for _, z in ipairs(strip._hitZones or {}) do
        if z.id == "tab:" .. id then
            if win._activeTab ~= id or (id ~= "loot" and not win._drawerOpen) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return clickTab(w, w and w._tabStripPanel, id) end
local function worldTab(id) local w = WW(); return clickTab(w, w and w._actionTabStrip, id) end
local function pairChecks(tag, what)
    local c, w = geo(CW()), geo(WW())
    if not check(c ~= nil and w ~= nil, pre(tag) .. " #159 " .. what .. ": both windows open", tostring(c ~= nil) .. "/" .. tostring(w ~= nil), "true/true") then return end
    local sw, sh = screen()
    check(onScreen(c, sw, sh) and onScreen(w, sw, sh), pre(tag) .. " #159 " .. what .. ": both windows wholly on the screen",
        gs(c) .. " | " .. gs(w), "inside " .. sw .. "x" .. sh)
    check(not overlap(c, w), pre(tag) .. " #159 " .. what .. ": the windows do not overlap", gs(c) .. " | " .. gs(w), "apart")
end
-- the Character window on a tab, then: the World window where it was, the pair on the screen and apart
local function openCharTab(g, tag, id)
    gstep(g, 1, function() L.wwBefore = geo(WW()) end)
    gwait(g, 60, function() return charTab(id) end, "the " .. id .. " tab's hit zone", function(ok)
        if not ok then
            note(pre(tag) .. " the " .. id .. " tab is not on the strip's view: opened directly")
            local w = CW()
            if w then w._activeTab = id; if id ~= "loot" then w._drawerMode = "tab"; w._drawerOpen = true end end
        end
    end)
    gwait(g, 180, function() local w = CW(); return w ~= nil and w._activeTab == id and (id == "loot" or w._drawerOpen == true) end,
        "the " .. id .. " tab to open", function(ok) check(ok, pre(tag) .. " the Character window opens on " .. id) end)
    whenStill(g, tag, "the " .. id .. " tab open")
    gstep(g, 1, function()
        local now = geo(WW())
        check(sameGeo(now, L.wwBefore, 1), pre(tag) .. " #159 " .. id .. " in the Character window leaves the World window where it was", gs(now), gs(L.wwBefore))
        pairChecks(tag, id .. " open")
    end)
end

-- ---------------------------------------------------------------------------------------------------------------
-- TAB-STRIP ICONS
-- ---------------------------------------------------------------------------------------------------------------
local TONES = { "w", "l", "m", "d", "k" }
local function iconPicsOk(ic)
    local P = ZeD.Px
    local d = ic.draws
    if #d ~= 6 then return false, #d .. " draws" end
    if not texSame(d[1].tex, P.tex(TP.DIR .. ic.id .. "_sh.png")) then return false, "the shadow's picture" end
    for i, tn in ipairs(TONES) do
        if not texSame(d[i + 1].tex, P.tex(TP.DIR .. ic.id .. "_" .. tn .. ".png")) then return false, "tone " .. tn end
    end
    return true, nil
end
local function analyzeStrip(tag, side, accKey)
    local win = (side == "c") and CW() or WW()
    local strip = win and ((side == "c") and win._tabStripPanel or win._actionTabStrip)
    local nm = pre(tag) .. " tabs, " .. ((side == "c") and "Character" or "World") .. " window"
    if not check(strip ~= nil, nm .. ": the strip is there") then return end
    local tabRecs, iconRecs = {}, {}
    for _, r in ipairs(CAP.tabs) do if r.el == strip then tabRecs[#tabRecs + 1] = r end end
    for _, r in ipairs(CAP.icons) do if r.el == strip then iconRecs[#iconRecs + 1] = r end end
    if accKey then
        local v = variantOf(accKey)
        local bad, n = nil, 0
        for _, ic in ipairs(iconRecs) do
            if not ic.active then
                n = n + 1
                local m = ic.draws[4]
                if not (m and v and near(m, v.accent)) then bad = bad or (ic.id .. " " .. rgb(m)) end
            end
        end
        check(n > 0 and bad == nil, nm .. ": with the window's accent set to " .. accKey .. ", every idle icon's middle tone is that accent",
            bad or (n .. " icons"), v and rgb(v.accent))
        return
    end
    local zones = {}
    for _, z in ipairs(strip._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then zones[#zones + 1] = { id = z.id:sub(5), z = z } end
    end
    if not check(#zones > 0, nm .. ": the strip offers tabs", #zones, "> 0") then return end
    local kWant = math.max(1, math.floor(SC.root() + 0.5))
    local blank, undrawn, iconBad, picBad, shadowBad, toneBad = {}, {}, {}, {}, {}, {}
    for _, zz in ipairs(zones) do
        local id, z = zz.id, zz.z
        if not TP.has(id) then blank[#blank + 1] = id end
        local tr = nil
        for _, r in ipairs(tabRecs) do if r.id == id then tr = r end end
        if not tr or tr.x < z.x or tr.y < z.y or tr.x + tr.w > z.x + z.w or tr.y + tr.h > z.y + z.h then undrawn[#undrawn + 1] = id end
        local ics = {}
        for _, r in ipairs(iconRecs) do if r.id == id then ics[#ics + 1] = r end end
        local ic = ics[1]
        if #ics ~= 1 then
            iconBad[#iconBad + 1] = id .. " drawn " .. #ics .. " times"
        else
            local sz = 16 * ic.k
            local ix, iy = ic.cx - math.floor(sz / 2), ic.cy - math.floor(sz / 2)
            if ic.cx < z.x or ic.cx >= z.x + z.w or ic.cy < z.y or ic.cy >= z.y + z.h or sz > z.w or sz > z.h
               or ic.k ~= kWant or ix ~= math.floor(ix) or iy ~= math.floor(iy) then
                iconBad[#iconBad + 1] = id .. " at " .. fi(ic.cx) .. "," .. fi(ic.cy) .. " k " .. tostring(ic.k)
            end
            local okPics, why = iconPicsOk(ic)
            if not okPics then
                picBad[#picBad + 1] = id .. " (" .. tostring(why) .. ")"
            else
                local d = ic.draws
                local sh = d[1]
                if sh.x ~= ix + ic.k or sh.y ~= iy + ic.k or sh.w ~= sz or sh.h ~= sz or math.abs((sh.a or 0) - (ic.active and 0.25 or 0.55)) > 0.001
                   or (sh.r or 0) ~= 0 then
                    shadowBad[#shadowBad + 1] = id
                end
                for i = 2, 6 do
                    if d[i].x ~= ix or d[i].y ~= iy or d[i].w ~= sz or d[i].h ~= sz then iconBad[#iconBad + 1] = id .. " tone " .. TONES[i - 1] .. " off its place" end
                end
                local want = ic.acc
                if ic.active then
                    local on, f = ic.on, 0.68
                    if (on.r + on.g + on.b) > 1.5 then f = 1.37 - f end
                    want = { r = ic.acc.r + (on.r - ic.acc.r) * f, g = ic.acc.g + (on.g - ic.acc.g) * f, b = ic.acc.b + (on.b - ic.acc.b) * f }
                end
                if not near(d[4], want) then toneBad[#toneBad + 1] = id .. " " .. rgb(d[4]) .. " vs " .. rgb(want) end
            end
        end
    end
    check(#blank == 0, nm .. ": every tab it offers has a lit icon", #blank == 0 and (#zones .. " tabs") or table.concat(blank, ","), "none blank")
    check(#undrawn == 0, nm .. ": every tab drawn by TabPx.drawTab inside its hit zone", #undrawn == 0 and "all" or table.concat(undrawn, ","), "all")
    check(#iconBad == 0, nm .. ": each icon drawn once, centred in its tab, at 16 x " .. kWant .. " whole pixels",
        #iconBad == 0 and "all" or iconBad[1], "all")
    check(#picBad == 0, nm .. ": each icon is its six pictures (shadow, then the five tones) in order", #picBad == 0 and "all" or picBad[1], "all")
    check(#shadowBad == 0, nm .. ": each shadow one texel down-right, 0.55 idle and 0.25 active", #shadowBad == 0 and "all" or table.concat(shadowBad, ","), "all")
    check(#toneBad == 0, nm .. ": the idle icons' middle tone is the window's accent, the active icon's leans to textOnAccent",
        #toneBad == 0 and "all" or toneBad[1], "all")
    local act = {}
    for _, r in ipairs(tabRecs) do if r.active then act[#act + 1] = r.id end end
    check(#act == 1 and act[1] == win._activeTab, nm .. ": one tab drawn active, the window's own", table.concat(act, ","), tostring(win._activeTab))
end
local function iconArt()
    local missing, sized, n = {}, {}, 0
    for id, on in pairs(TP.ICONS or {}) do
        if on then
            for _, part in ipairs({ "sh", "w", "l", "m", "d", "k" }) do
                n = n + 1
                local t = ZeD.Px.tex(TP.DIR .. id .. "_" .. part .. ".png")
                if not t then missing[#missing + 1] = id .. "_" .. part
                else
                    local ok, w, h = pcall(function() return t:getWidth(), t:getHeight() end)
                    if ok and (w ~= 16 or h ~= 16) then sized[#sized + 1] = id .. "_" .. part .. " " .. tostring(w) .. "x" .. tostring(h) end
                end
            end
        end
    end
    check(#missing == 0, "tabs: every lit icon's six pictures load (" .. n .. ")", #missing == 0 and "all" or table.concat(missing, ","), "all")
    check(#sized == 0, "tabs: every icon picture is 16 x 16 (drawn at whole multiples)", #sized == 0 and "all" or sized[1], "16x16")
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE BELT
-- ---------------------------------------------------------------------------------------------------------------
local BELT, BUCKLES = "media/textures/ZeD/belt/", "media/textures/ZeD/buckles/buckle_"
local function matTex(mat, part)
    if mat == "leather" then return shared(BELT .. "strap_" .. part .. ".png") end
    return shared(BELT .. mat .. "_" .. part .. ".png")
end
local function buckleTexFor(id) return (id and shared(BUCKLES .. id .. ".png")) or shared(BUCKLES .. "unemployed.png") end
local function beltRec(kind, tex, x, y, w, h)
    for _, q in ipairs(CAP.belt) do
        if q.k == kind and texSame(q.tex, tex) and math.abs(q.x - x) < 0.5 and math.abs(q.y - y) < 0.5 and math.abs(q.w - w) < 0.5 and math.abs(q.h - h) < 0.5 then
            return q
        end
    end
    return nil
end
local function beltArt()
    local function size(t) local ok, w, h = pcall(function() return t:getWidth(), t:getHeight() end); if ok then return tostring(w) .. "x" .. tostring(h) end; return "?" end
    local l, m, r = matTex("leather", "l"), matTex("leather", "mid"), matTex("leather", "r")
    local got = (l and size(l) or "none") .. " " .. (m and size(m) or "none") .. " " .. (r and size(r) or "none")
    check(got == "8x30 64x30 8x30", "belt: the strap art (ends, middle) is 8, 64 and 8 texels by 30, as the belt lays it out", got, "8x30 64x30 8x30")
    local b = buckleTexFor(profIdNow())
    check(b ~= nil and size(b) == "58x40", "belt: the profession buckle's art is 58 x 40", b and size(b) or "none", "58x40")
end
local function analyzeBelt(tag)
    local nm = pre(tag) .. " belt"
    local hud = BL.getHUD(0)
    if not check(hud ~= nil and hud._drawn == true, nm .. ": the belt is on the screen") then return end
    local T = ZeD.T
    local k = T.art
    local s, b, c = hud._strap, hud._buckle, hud._closure
    if not check(s ~= nil and b ~= nil, nm .. ": the full belt has its strap and buckle") then return end
    local sy = math.floor((hud:getHeight() - s.h) / 2)
    check(s.h == 30 * k and s.y == sy, nm .. ": the strap is the art's 30 texels at the whole zoom " .. k .. ", centred on the belt's row",
        fi(s.h) .. " at y " .. fi(s.y), fi(30 * k) .. " at y " .. fi(sy))
    check(b.w == 58 * k and b.h == 40 * k, nm .. ": the buckle's place is the art's 58 x 40 at the whole zoom", fi(b.w) .. "x" .. fi(b.h), fi(58 * k) .. "x" .. fi(40 * k))
    local mid = getPlayerScreenLeft(0) + math.floor(getPlayerScreenWidth(0) / 2)
    local bc = hud:getX() + b.x + math.floor(b.w / 2)
    check(math.abs(bc - mid) <= 1, nm .. ": the buckle sits on the screen's centre", fi(bc), fi(mid))
    check(b.x >= s.x and b.x + b.w <= s.x + s.w, nm .. ": the buckle lies on the strap", fi(b.x) .. "-" .. fi(b.x + b.w), fi(s.x) .. "-" .. fi(s.x + s.w))
    local slots = {}
    for _, bx in ipairs(hud._boxes or {}) do if bx.kind == "slot" then slots[#slots + 1] = bx end end
    local n = #slots
    local kk = BL.closureAfter(slots)
    local left, right, off = 0, 0, 0
    for _, bx in ipairs(slots) do
        if bx.x + bx.w <= b.x then left = left + 1 elseif bx.x >= b.x + b.w then right = right + 1 end
        if bx.x < s.x or bx.x + bx.w > s.x + s.w then off = off + 1 end
    end
    check(left == kk and right == n - kk, nm .. ": the buckle splits the " .. n .. " slots evenly, an odd one on the right", left .. " left, " .. right .. " right", kk .. ", " .. (n - kk))
    check(off == 0, nm .. ": every slot box sits on the strap", off .. " off it", 0)
    local runs = hud._runs or {}
    local kind = (c and c.kind) or "buckle"
    local gaps = 0
    for i = 2, #runs do if math.abs(runs[i][1] - runs[i - 1][2]) > 1 then gaps = gaps + 1 end end
    local ends = #runs > 0 and math.abs(runs[1][1] - s.x) <= 1 and math.abs(runs[#runs][2] - (s.x + s.w)) <= 1
    check(ends and gaps <= ((kind == "knot") and 1 or 0), nm .. ": the strap's pieces run end to end" .. ((kind == "knot") and " (cut once at the knot's eye)" or ""),
        #runs .. " pieces, " .. gaps .. " gaps", "end to end")
    local prov = hud._prov or {}
    local wrongMat, mats = nil, {}
    for _, bx in ipairs(slots) do
        local st = bx.s and bx.s.slot and bx.s.slot.slotType or ""
        local want = BL.materialFor(st, prov)
        local cx = bx.x + math.floor(bx.w / 2)
        local got = nil
        for _, r in ipairs(runs) do if cx >= r[1] and cx < r[2] then got = r[3] end end
        mats[#mats + 1] = st .. "=" .. tostring(got)
        if got ~= want then wrongMat = wrongMat or (st .. ": " .. tostring(got) .. " vs " .. tostring(want)) end
    end
    check(wrongMat == nil, nm .. ": the strap behind each slot is the material of the thing that gives the slot", wrongMat or table.concat(mats, " "), "B.materialFor")
    if kind ~= "knot" then
        local cx = b.x + math.floor(b.w / 2)
        local got = nil
        for _, r in ipairs(runs) do if cx >= r[1] and cx < r[2] then got = r[3] end end
        check(got == hud._waist, nm .. ": the piece under the buckle is the waist belt's", tostring(got), tostring(hud._waist))
    end
    -- the frame: each piece's art at the whole zoom
    if not matTex("leather", "mid") then
        note(nm .. ": the strap art is missing; the belt draws its plain leather")
    else
        local th, ew, tw = 30 * k, 8 * k, 64 * k
        local y = s.y + math.floor((s.h - th) / 2)
        local bad = nil
        for _, r in ipairs(runs) do
            local Lt, Mt, Rt = matTex(r[3], "l"), matTex(r[3], "mid"), matTex(r[3], "r")
            if not (Lt and Mt and Rt) then Lt, Mt, Rt = matTex("leather", "l"), matTex("leather", "mid"), matTex("leather", "r") end
            if not beltRec("ts", Lt, r[1], y, ew, th) then bad = bad or (r[3] .. " left end at " .. fi(r[1])) end
            if not beltRec("ts", Rt, r[2] - ew, y, ew, th) then bad = bad or (r[3] .. " right end at " .. fi(r[2] - ew)) end
            local x0, x1 = r[1] + ew, r[2] - ew
            if x1 > x0 then
                local want, got = math.ceil((x1 - x0) / tw), 0
                for _, q in ipairs(CAP.belt) do
                    if q.k == "ts" and texSame(q.tex, Mt) and q.x >= x0 - 0.5 and q.x < x1 and math.abs(q.y - y) < 0.5 and math.abs(q.w - tw) < 0.5 and math.abs(q.h - th) < 0.5 then
                        got = got + 1
                    end
                end
                if got ~= want then bad = bad or (r[3] .. " middle " .. got .. " tiles vs " .. want) end
            end
        end
        check(bad == nil, nm .. ": each piece drawn from its material's art: both ends and the middle repeated, at the whole zoom", bad or (#runs .. " pieces"), "every piece")
    end
    if kind ~= "buckle" then
        local tex = shared(BELT .. "closure_" .. kind .. ".png")
        local q = tex and beltRec("ts", tex, c.x, c.y, 58 * c.k, (c.h or 40) * c.k)
        check(q ~= nil, nm .. ": the waist belt's closure (" .. kind .. ") drawn whole in the buckle's place", q and "drawn" or "not found", "closure_" .. kind)
    else
        local id = profIdNow()
        local tex = buckleTexFor(id)
        local q = tex and beltRec("tsa", tex, b.x + math.floor((b.w - 58 * k) / 2), b.y + math.floor((b.h - 40 * k) / 2), 58 * k, 40 * k)
        check(q ~= nil, nm .. ": the profession's buckle (" .. tostring(id) .. ") drawn at 58 x 40 x " .. k .. " in its place", q and "drawn" or "not found", texName(tex))
        L.lastBuckleKind = kind
    end
end
-- another stable profession that has its own buckle
local function otherProfession()
    local cur = profIdNow()
    local defs = CharacterProfessionDefinition.getProfessions()
    local best, bestId = nil, nil
    for i = 0, defs:size() - 1 do
        local d = defs:get(i)
        local id = nil
        pcall(function() id = string.lower(tostring(d:getType():getName())):match("([^:]+)$") end)
        if id and id ~= cur and (id == "burglar" or id == "carpenter" or id == "chef" or id == "veteran") then
            if not best or id == "burglar" then best, bestId = d, id end
        end
    end
    return best, bestId
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE PERMIT STAMP (#147)
-- ---------------------------------------------------------------------------------------------------------------
local function fits(s, full)
    if s == full then return true end
    return #s >= 3 and s:sub(-3) == "..." and full:sub(1, #s - 3) == s:sub(1, #s - 3)
end
local function analyzeStamp(tag, revoked)
    local nm = pre(tag) .. " #147"
    local X, f = ZeD.Text, ZeD.Font.sdf.sec
    local rv = ZeD.tr("UI_ZeD_Identity_Revoked")
    local l1s, l2s = ZeD.tr("UI_ZeD_Identity_StampLine1"), ZeD.tr("UI_ZeD_Identity_StampLine2")
    local rvR, l1R, l2R = nil, nil, nil
    for _, r in ipairs(CAP.text) do
        if r.f == f then
            if r.s == rv and r.r and math.abs(r.r - 179 / 255) < 0.01 and math.abs((r.g or 0) - 18 / 255) < 0.01 then rvR = r end
            if r.al == "c" and fits(r.s, l1s) then l1R = r end
        end
    end
    for _, r in ipairs(CAP.text) do
        if r.f == f and r.al == "l" and fits(r.s, l2s) and l1R and r.y > l1R.y then
            if not rvR or math.abs(r.y - rvR.y) < 0.5 then l2R = r end
        end
    end
    if not check(l1R ~= nil and l2R ~= nil, nm .. ": the wide license draws its permit stamp (" .. l1s .. " / " .. l2s .. ")",
        tostring(l1R ~= nil) .. "/" .. tostring(l2R ~= nil), "true/true") then return end
    local z = l2R.z
    local w2 = X.width(f, l2R.s, z)
    if revoked then
        if not check(rvR ~= nil, nm .. ": a revoked permit (burglar) draws the red " .. rv) then return end
        local wr = X.width(f, rv, z)
        local lh = math.ceil(X.height(f, z))
        local sp = math.max(X.width(f, "a a", z) - X.width(f, "aa", z), math.floor(lh / 4))
        local gap = rvR.x - (l2R.x + w2)
        check(math.abs(l2R.y - rvR.y) < 0.5 and l2R.x < rvR.x, nm .. ": " .. l2s .. " and " .. rv .. " on one line, " .. l2s .. " first",
            fi(l2R.x) .. "," .. fi(l2R.y) .. " / " .. fi(rvR.x) .. "," .. fi(rvR.y), "one line")
        check(gap >= math.max(1, math.floor(lh / 4)), nm .. ": a visible word space between " .. l2s .. " and " .. rv .. " (beta 10 drew them together)",
            string.format("%.1f px", gap), ">= " .. math.max(1, math.floor(lh / 4)) .. " px (a quarter line)")
        check(math.abs(gap - sp) <= 1, nm .. ": the space is the face's own (\"a a\" less \"aa\", at least a quarter line)", string.format("%.1f", gap), string.format("%.1f", sp))
        note(nm .. ": a lone space measures " .. string.format("%.1f", X.width(f, " ", z)) .. " px in the stamp's face (the cause of the beta 10 bug)")
        local midL = (l2R.x + rvR.x + wr) / 2
        check(math.abs(midL - l1R.x) <= 1, nm .. ": " .. l2s .. " " .. rv .. " centred under " .. l1s, string.format("%.1f", midL), string.format("%.1f", l1R.x))
    else
        check(rvR == nil, nm .. ": a valid permit (police officer) draws no " .. rv, rvR and "drawn" or "none", "none")
        local midL = l2R.x + w2 / 2
        check(math.abs(midL - l1R.x) <= 1, nm .. ": " .. l2s .. " alone, centred under " .. l1s, string.format("%.1f", midL), string.format("%.1f", l1R.x))
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE HEALTH PERCENT (#148)
-- ---------------------------------------------------------------------------------------------------------------
local function analyzeHealth(tag, label, nWant)
    local nm = pre(tag) .. " #148 " .. label
    local w = CW()
    local view, zones = w and w._healthView, (w and w._healthInjuryZones) or {}
    if not check(view ~= nil, nm .. ": the Health tab drew its body") then return end
    check(#zones == nWant, nm .. ": the list shows every staged row", #zones, nWant)
    local vr = view.x + view.w
    local panel = w._healthContentPanel
    local missing, bad, rowOut, worst = 0, nil, nil, -100000
    for _, z in ipairs(zones) do
        local e = z.entryRef or {}
        local pct = math.floor((e.health or 0) + 0.5) .. "%"
        local hit = nil
        for _, r in ipairs(CAP.tright) do
            if r.s == pct and (panel == nil or r.el == panel) and r.y >= z.y and r.y < z.y + z.h then hit = r end
        end
        if z.x + z.w > vr then rowOut = rowOut or (tostring(e.name) .. " ends at " .. fi(z.x + z.w)) end
        if not hit then
            missing = missing + 1
        else
            local tw = ZeD.TM:MeasureStringX(hit.font or ZeD.T.fontF1, pct)
            local right, left = hit.x, hit.x - tw
            if right - vr > worst then worst = right - vr end
            if right > vr or right > z.x + z.w or left < z.x then
                bad = bad or (tostring(e.name) .. " " .. pct .. " spans " .. fi(left) .. "-" .. fi(right) .. ", the row " .. fi(z.x) .. "-" .. fi(z.x + z.w))
            end
        end
    end
    check(missing == 0, nm .. ": every row draws its percent", missing .. " missing", 0)
    check(bad == nil, nm .. ": every percent whole, \"%\" and all, inside its row and the tab's stencil (right edge " .. fi(vr) .. ")",
        bad or ("the rightmost ends " .. fi(-worst) .. " px inside"), "inside")
    check(rowOut == nil, nm .. ": every row ends inside the stencil (the list padded both sides)", rowOut or "all inside", "inside")
    local sb = w._healthScroll and w._healthScroll.visible
    note(nm .. ": the scrollbar is " .. (sb and "on" or "off") .. " here")
    L.sbSeen = L.sbSeen or {}
    L.sbSeen[tag .. (sb and "on" or "off")] = true
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE RADIO'S PRESET + (#140)
-- ---------------------------------------------------------------------------------------------------------------
local OLD_ORANGE = { r = 0.85, g = 0.48, b = 0.12 }
local function plusRec()
    local w = CW()
    local z = w and w._radioPresetAddZone
    if not z then return nil end
    local hit = nil
    for _, r in ipairs(CAP.btn) do
        if r.variant == "flat" and math.abs(r.x - z.x) < 0.5 and math.abs(r.y - z.y) < 0.5 and math.abs(r.w - z.w) < 0.5 and math.abs(r.h - z.h) < 0.5 then hit = r end
    end
    return hit
end
local function pressPlus()
    local w = CW()
    local z = w and w._radioPresetAddZone
    if not z then return false end
    return RT.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) == true
end
local function analyzePlus(tag, mode)
    local nm = pre(tag) .. " #140"
    local r = plusRec()
    if not check(r ~= nil, nm .. " (" .. mode .. "): the drawn chassis draws its preset + button") then return end
    local w = CW()
    local key = (w and w._accentKey) or ZeD.currentAccent
    if mode == "normal" then
        L.plusBg = r.bg
        check(near(r.bg, r.acc), nm .. ": the + is filled with the accent the window draws in (" .. tostring(key) .. ")", rgb(r.bg), rgb(r.acc))
        check(near(r.border, r.accB), nm .. ": its border is the bright accent", rgb(r.border), rgb(r.accB))
        check(near(r.text, r.on), nm .. ": its glyph is the ink that reads on the accent (textOnAccent)", rgb(r.text), rgb(r.on))
        if key ~= "orange" then check(not near(r.bg, OLD_ORANGE), nm .. ": no longer beta 9's fixed orange", rgb(r.bg), "not " .. rgb(OLD_ORANGE)) end
    elseif mode == "assign" then
        check(near(r.bg, r.accB), nm .. ": armed for a slot, the + lights in the bright accent", rgb(r.bg), rgb(r.accB))
    else
        local v = variantOf(L.accTest)
        check(v ~= nil and near(r.bg, v.accent), nm .. ": with the window's accent set to " .. tostring(L.accTest) .. ", the + follows it", rgb(r.bg), v and rgb(v.accent))
        check(L.plusBg ~= nil and not near(r.bg, L.plusBg), nm .. ": and it changed from the + before", rgb(r.bg), "not " .. rgb(L.plusBg))
    end
end
local function giveRadio()
    if not L.radio then
        local it = p:getInventory():AddItem("Base.RadioBlack")
        if not it then error("could not make a Base.RadioBlack") end
        L.radio = it
        local dd = it:getDeviceData()
        if dd then
            if dd:getIsBatteryPowered() then dd:setHasBattery(true); dd:setPower(0.6) end
            dd:setIsTurnedOn(false)
        end
    end
    L.handsChanged = true
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    p:setPrimaryHandItem(L.radio)
end

-- ---------------------------------------------------------------------------------------------------------------
-- #134: ZeD's map and a map mod's labels
-- ---------------------------------------------------------------------------------------------------------------
local ZOOM = 14.5
local function mapStyleChecks(st)
    local nm = pre("a") .. " #134 " .. st
    local mp = mapPanel()
    if not check(mp ~= nil and mp.mapAPI ~= nil, nm .. ": ZeD's map is there") then return end
    local styleAPI = mp.mapAPI:getStyleAPI()
    local lp, ln = nil, nil
    pcall(function() lp = styleAPI:getLayerByName("text-place") end)
    pcall(function() ln = styleAPI:getLayerByName("text-note") end)
    check(lp ~= nil and ln ~= nil, nm .. ": the style has the game's text layers (text-place, text-note)", tostring(lp ~= nil) .. "/" .. tostring(ln ~= nil), "true/true")
    local an = ln and alphaAt(ln, ZOOM)
    local ap = lp and alphaAt(lp, ZOOM)
    check(an ~= nil and an > 0, nm .. ": text-note, the player's notes, draws at zoom " .. ZOOM, an, "> 0")
    if st == "paper" then
        check(ap ~= nil and ap == 0, nm .. ": the place-label layers are hidden by design (Paper prints its own names), a mod's label in them too", ap, 0)
    else
        check(ap ~= nil and ap > 0, nm .. ": text-place, where a map mod writes its labels, draws at zoom " .. ZOOM .. " as on the game's map", ap, "> 0")
    end
    local api = MN.api()
    local s1, s2 = storeFind(api, MARK1), storeFind(api, MARK2)
    local ok1 = s1 ~= nil and s1:getAlpha() == 0 and s1:getLayerID() == "text-place"
    local ok2 = s2 ~= nil and math.abs(s2:getRed() - 0.65) < 0.01 and s2:getAlpha() > 0.99 and s2:getLayerID() == "text-note"
    check(ok1 and ok2, nm .. ": the restyle keeps both staged symbols with their layers and colours", tostring(ok1) .. "/" .. tostring(ok2), "true/true")
    local zf = nil
    pcall(function() zf = mp.mapAPI:getZoomF() end)
    note(nm .. ": the map shows zoom " .. tostring(zf))
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE PLAN
-- ---------------------------------------------------------------------------------------------------------------
local function pass(tag)
    local g = (tag == "b")
    gstep(g, 1, function()
        L.at[tag] = string.format("%.2fx", SC.root())
        say("pass " .. tag .. " at UI scale " .. L.at[tag] .. " (T.scale " .. string.format("%.3f", ZeD.T.scale or 0) .. ", art zoom " .. tostring(ZeD.T.art) .. ")")
        worldTab("loot"); charTab("loot")
    end)
    whenStill(g, tag, "both windows on Loot")
    gstep(g, 1, function() pairChecks(tag, "both on Loot"); L.hold, L.moved = shape(), false; L.holdN = 0 end)
    gwait(g, 125, function()
        L.holdN = L.holdN + 1
        if shape() ~= L.hold then L.moved = true end
        return L.holdN >= 120
    end, "120 still ticks", function() check(not L.moved, pre(tag) .. " #159 both windows hold still for 120 ticks with nothing pressed", L.moved and "moved" or "still", "still") end)

    -- the tab-strip icons, then with the windows' accent switched
    capture(g, { tabs = true }, hookStrips)
    gstep(g, 1, function()
        safe(pre(tag) .. " tabs", analyzeStrip, tag, "c")
        safe(pre(tag) .. " tabs", analyzeStrip, tag, "w")
        shot(tag .. "_tabs")
        setWinAccent(otherAccent())
    end)
    gstep(g, 3, function() end)
    capture(g, { tabs = true }, hookStrips)
    gstep(g, 1, function()
        safe(pre(tag) .. " tabs", analyzeStrip, tag, "c", L.accTest)
        safe(pre(tag) .. " tabs", analyzeStrip, tag, "w", L.accTest)
        shot(tag .. "_tabs_accent_" .. tostring(L.accTest))
        restoreWinAccent()
    end)

    -- the belt (its full form for the check, the player's own put back after)
    gstep(g, 1, function()
        if BL.simple() then
            L.beltStyleWas = ZeD.Settings.beltStyleOption:getValue()
            ZeD.Settings.beltStyleOption:setValue(1)
            note(pre(tag) .. " belt: the Simple belt is set; the full belt is put on for the check")
        end
    end)
    gstep(g, 5, function() end)
    capture(g, { belt = true }, hookBelt)
    gstep(g, 1, function() safe(pre(tag) .. " belt", analyzeBelt, tag); shot(tag .. "_belt") end)
    if tag == "a" then
        gstep(g, 1, function()
            if L.lastBuckleKind ~= "buckle" then note("belt: the waist belt has its own closure: the profession buckle is not drawn"); return end
            local d, id = otherProfession()
            if not d then note("belt: no other profession with a buckle found"); return end
            L.profWas = p:getDescriptor():getCharacterProfession()
            L.profTo = id
            p:getDescriptor():setCharacterProfession(d:getType())
        end)
        gstep(g, 5, function() end)
        capture(g, { belt = true }, hookBelt)
        gstep(g, 1, function()
            if L.profTo then
                local hud = BL.getHUD(0)
                local b = hud and hud._buckle
                local k = ZeD.T.art
                local tex = shared(BUCKLES .. L.profTo .. ".png")
                local q = b and tex and beltRec("tsa", tex, b.x + math.floor((b.w - 58 * k) / 2), b.y + math.floor((b.h - 40 * k) / 2), 58 * k, 40 * k)
                check(q ~= nil, pre(tag) .. " belt: with the profession changed to " .. L.profTo .. ", the belt draws that profession's buckle", q and "drawn" or "not found", "buckle_" .. L.profTo)
                shot(tag .. "_belt_buckle_" .. L.profTo)
                p:getDescriptor():setCharacterProfession(L.profWas)
                L.profWas, L.profTo = nil, nil
            end
        end)
    end
    gstep(g, 1, function()
        if L.beltStyleWas then ZeD.Settings.beltStyleOption:setValue(L.beltStyleWas); L.beltStyleWas = nil end
    end)

    -- #147 the permit stamp on the wide license
    gstep(g, 1, function()
        IT.qaProf, IT.qaLayout, IT.qaStyle = "base:burglar", "wide", "immersive"
        local w = CW()
        if w then w._identityPhotoExpanded = false end
    end)
    openCharTab(g, tag, "identity")
    capture(g, { text = true })
    gstep(g, 1, function() safe(pre(tag) .. " #147", analyzeStamp, tag, true); shot(tag .. "_stamp_revoked"); IT.qaProf = "base:policeofficer" end)
    gstep(g, 5, function() end)
    capture(g, { text = true })
    gstep(g, 1, function()
        safe(pre(tag) .. " #147", analyzeStamp, tag, false)
        IT.qaProf, IT.qaLayout, IT.qaStyle = L.qa.prof, L.qa.layout, L.qa.style
    end)

    -- #148 the Health tab's percents: 8 rows under the figure, then 1 row with the figure folded
    gstep(g, 1, function()
        injectHealth(8)
        local w = CW()
        if w then w._healthFigureExpanded = true end
    end)
    openCharTab(g, tag, "health")
    gstep(g, 10, function() local w = CW(); if w then w._healthCache = nil end end)
    gstep(g, 10, function() end)
    capture(g, { tright = true })
    gstep(g, 1, function()
        safe(pre(tag) .. " #148", analyzeHealth, tag, "8 rows under the figure", 8)
        shot(tag .. "_health_8")
        injectHealth(1)
        local w = CW()
        if w then w._healthFigureExpanded = false end
    end)
    gstep(g, 20, function() end)
    capture(g, { tright = true })
    gstep(g, 1, function()
        safe(pre(tag) .. " #148", analyzeHealth, tag, "1 row, the figure folded", 1)
        shot(tag .. "_health_1")
        injectHealth(nil)
        local w = CW()
        if w and L.flags then w._healthFigureExpanded = L.flags.hf end
    end)

    -- #140 the radio's preset +: a ValuTech radio in hand, the drawn chassis (faces off)
    gstep(g, 1, giveRadio)
    gwait(g, 150, function()
        local w = CW()
        local r = w and w._radios and w._radios[1]
        return r ~= nil and r.radioInstance == L.radio
    end, "the radio in hand to be listed", function(ok) check(ok, pre(tag) .. " #140 the Character window lists the radio in hand") end)
    openCharTab(g, tag, "radio")
    gstep(g, 1, function() RT.useFaces = false end)
    gwait(g, 90, function() local w = CW(); return w ~= nil and w._radioPresetAddZone ~= nil end, "the chassis' preset bank",
        function(ok) check(ok, pre(tag) .. " #140 with the faces off the radio tab draws the chassis and its preset bank") end)
    whenStill(g, tag, "the radio's chassis (the drawer may change card)")
    capture(g, { btn = true })
    gstep(g, 1, function()
        safe(pre(tag) .. " #140", analyzePlus, tag, "normal")
        shot(tag .. "_radio_plus")
        check(pressPlus(), pre(tag) .. " #140 a click on the + is taken (RadioTab.onClick)")
    end)
    gstep(g, 3, function()
        local w = CW()
        check(w ~= nil and w._radioPresetAssignMode == true, pre(tag) .. " #140 the click arms the preset assign mode", tostring(w and w._radioPresetAssignMode), "true")
    end)
    capture(g, { btn = true })
    gstep(g, 1, function()
        safe(pre(tag) .. " #140", analyzePlus, tag, "assign")
        shot(tag .. "_radio_plus_armed")
        pressPlus()
    end)
    gstep(g, 3, function()
        local w = CW()
        check(w ~= nil and w._radioPresetAssignMode ~= true, pre(tag) .. " #140 a second click disarms it", tostring(w and w._radioPresetAssignMode), "false")
        setWinAccent(otherAccent())
    end)
    gstep(g, 3, function() end)
    capture(g, { btn = true })
    gstep(g, 1, function()
        safe(pre(tag) .. " #140", analyzePlus, tag, "window accent")
        shot(tag .. "_radio_plus_accent_" .. tostring(L.accTest))
        restoreWinAccent()
        RT.useFaces = L.useFaces
    end)
    openCharTab(g, tag, "loot")
end

-- 0. the start: the pair open and still, the place of each window kept
step(1, function()
    pcall(function()
        local u = UIManager.getUI()
        for k = 0, u:size() - 1 do
            local e = u:get(k)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); L.dbg[#L.dbg + 1] = e end
        end
    end)
    installWraps()
    Events.OnPreUIDraw.Add(onPreUI)
    Events.OnPostUIDraw.Add(onPostUI)
    L.pairWasOpen = CWm.isOpen() and WWm.isOpen()
    if not L.pairWasOpen then CWm.toggleBothPaired(0) end
end)
waitUntil(150, function() return CWm.isOpen() and WWm.isOpen() end, "the window pair to open", function(ok)
    if not ok then error("the window pair did not open") end
end)
whenStill(false, "a", "the start")
step(1, function()
    local c, w = CW(), WW()
    L.G0 = { c = geo(c), w = geo(w) }
    L.flags = { id = c._identityPhotoExpanded, hf = c._healthFigureExpanded }
    L.prof0 = p:getDescriptor():getCharacterProfession()
    L.R0 = {}
    local k1, r1 = WP.capture(c)
    if k1 then L.R0[k1] = r1 end
    local k2, r2 = WP.capture(w)
    if k2 then L.R0[k2] = r2 end
    local sw, sh = screen()
    say(string.format("start: screen %dx%d, root %.2f, base %s, accent %s, Character %s, World %s", sw, sh, SC.root(),
        tostring(ZeD.currentBase), tostring(ZeD.currentAccent), gs(L.G0.c), gs(L.G0.w)))
    safe("tabs art", iconArt)
    safe("belt art", beltArt)
end)

pass("a")

-- #134 (pass a): ZeD's map, a map mod's place label and a note
step(1, function()
    local w = WW()
    L.popWas = (w ~= nil and w._mapPopout ~= nil)
    local md = p:getModData()
    L.mdStyle, L.mdPaper = md.ZeD_MapStyle, md.ZeD_MapPaper
    L.mapOpened = true
    ISWorldMap.ShowWorldMap(0, p:getX(), p:getY(), ZOOM)
end)
waitUntil(300, function()
    local w = WW()
    local mp = w and w._worldMapPanel
    return w ~= nil and w._mapPopout ~= nil and mp ~= nil and mp.mapAPI ~= nil and mp._styled == true
end, "ZeD's map to open", function(ok)
    check(ok, pre("a") .. " #134 the game's Show (the Map key's route) opens ZeD's map, unfolded")
    check(ISWorldMap_instance == nil or not ISWorldMap_instance:isVisible(), pre("a") .. " #134 the game's own map stays shut")
    local mp = mapPanel()
    if mp then L.styleWas = mp.style; L.mapTouched = true end
    check(mp ~= nil and mp._zedNotesBound == true, pre("a") .. " #134 ZeD's map is bound to the game's symbol store (the world map item)")
end)
step(5, function()
    local api, mp = MN.api(), mapPanel()
    if not check(api ~= nil and mp ~= nil, pre("a") .. " #134 the symbol store answers") then return end
    L.symN0 = api:getSymbolCount()
    local sc = (ISMap and ISMap.SCALE) or 0.666
    local x, y = p:getX(), p:getY()
    local s1 = api:addTranslatedText(MARK1, "text-place", x, y - 6)
    L.symsAdded = true
    s1:setRGBA(0, 0, 0, 0)   -- (the layer's own colour, as a map mod writes its labels)
    s1:setAnchor(0.5, 0.5)
    s1:setScale(sc)
    pcall(function() s1:setUserDefined(false) end)
    local s2 = api:addTranslatedText(MARK2, "text-note", x, y + 6)
    s2:setRGBA(0.65, 0.054, 0.054, 1.0)
    s2:setAnchor(0.5, 0.5)
    s2:setScale(sc)
    local n1 = api:getSymbolCount()
    check(n1 == L.symN0 + 2, pre("a") .. " #134 a map mod's place label and a note put in the store", n1, L.symN0 + 2)
    local pa = MN.panelAPI(mp)
    check(pa ~= nil and pa:getSymbolCount() == n1 and storeFind(pa, MARK1) ~= nil, pre("a") .. " #134 ZeD's map reads the same store: it holds the mod's label",
        pa and pa:getSymbolCount(), n1)
    -- (the Show route already centred the map on the character at zoom 14.5; the layer checks read zoom 14.5 whatever it shows)
end)
for _, st in ipairs({ "survey", "color", "paper" }) do
    step(2, function()
        L.styleSkip = (st == "paper" and not (ZeD.MapsTab.hasPaper and ZeD.MapsTab.hasPaper()))
        if L.styleSkip then note(pre("a") .. " #134 no Paper art on this install: Paper is not checked"); return end
        ZeD.MapsTab.setStyle(WW(), st)
    end)
    waitUntil(240, function()
        if L.styleSkip then return true end
        local mp = mapPanel()
        return mp ~= nil and mp.style == st and mp._styleWanted == nil
    end, "the map to restyle", function(ok)
        if not L.styleSkip then check(ok, pre("a") .. " #134 the style menu's " .. st .. " restyles ZeD's map") end
    end)
    step(20, function()
        if L.styleSkip then return end
        safe(pre("a") .. " #134", mapStyleChecks, st)
        shot("a_map_" .. st)
    end)
end
step(2, function()
    local n = removeMarks()
    L.symsAdded = false
    local api = MN.api()
    check(n == 2 and api ~= nil and api:getSymbolCount() == L.symN0, pre("a") .. " #134 put back: the two staged symbols taken out of the store",
        api and api:getSymbolCount(), L.symN0)
    local mp = mapPanel()
    if mp and L.styleWas and mp.style ~= L.styleWas then ZeD.MapsTab.setStyle(WW(), L.styleWas) end
end)
waitUntil(240, function()
    local mp = mapPanel()
    return mp == nil or L.styleWas == nil or (mp.style == L.styleWas and mp._styleWanted == nil)
end, "the map's own style back", function(ok) check(ok, pre("a") .. " #134 put back: the map's own style (" .. tostring(L.styleWas) .. ")") end)
step(2, function()
    local md = p:getModData()
    md.ZeD_MapStyle, md.ZeD_MapPaper = L.mdStyle, L.mdPaper
    L.mapTouched = false
    if not L.popWas then ISWorldMap.HideWorldMap(0) end
    L.mapOpened = false
end)
waitUntil(120, function() local w = WW(); return L.popWas or w == nil or w._mapPopout == nil end, "the map's pop-out to close",
    function(ok) check(ok, pre("a") .. " #134 put back: the map's pop-out closes (the game's Hide)") end)

-- #159: the pair shut and opened again (the inventory key's toggle)
step(1, function() worldTab("loot"); charTab("loot") end)
whenStill(false, "a", "both on Loot before the pair is shut")
step(1, function() L.G5 = { c = geo(CW()), w = geo(WW()) }; CWm.toggleBothPaired(0) end)
waitUntil(90, function() return not CWm.isOpen() and not WWm.isOpen() end, "the pair to shut",
    function(ok) check(ok, pre("a") .. " #159 the pair shuts (the inventory key's toggle)") end)
step(10, function() CWm.toggleBothPaired(0) end)
waitUntil(150, function() return CWm.isOpen() and WWm.isOpen() end, "the pair to open again",
    function(ok) if not ok then error("the window pair did not open again") end end)
whenStill(false, "a", "the pair opened again")
step(1, function()
    local c, w = geo(CW()), geo(WW())
    check(sameGeo(c, L.G5.c, 1), pre("a") .. " #159 shut and opened again, the Character window comes back where and as big as it was", gs(c), gs(L.G5.c))
    check(sameGeo(w, L.G5.w, 1), pre("a") .. " #159 shut and opened again, the World window comes back where and as big as it was", gs(w), gs(L.G5.w))
    pairChecks("a", "opened again")
end)

-- #159: a UI scale change through ZeD's own path (the Scale hook closes, re-themes and reopens the windows), the
-- second pass there, and the way back
local function pickB()
    local A = SC.root()
    if A >= 1.3 then return 1.0 end
    local cap = (SC.fitCap and SC.fitCap()) or A
    local floorS = SC.STEP_FLOOR or 0.75
    local best = nil
    for _, v in ipairs(SC.FIT_STEPS or { 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 }) do
        if v >= floorS - 1e-6 and v <= cap + 1e-6 and math.abs(v - A) >= 0.2 and (best == nil or v > best) then best = v end
    end
    return best
end
local function scaledUp(tag)
    local A, r = L.GA, (ZeD.T.scale or 1) / (L.GA.s or 1)
    local sw, sh = screen()
    local c, w = geo(CW()), geo(WW())
    if not (c and w) then check(false, pre(tag) .. " #159 both windows open after the scale change", gs(c) .. " | " .. gs(w), "both open"); return end
    local cr = math.min(sw, (A.c.x + A.c.w) * r)
    check(math.abs((c.x + c.w) - cr) <= 3, pre(tag) .. " #159 the Character window's right edge keeps its place in design units", fi(c.x + c.w), fi(cr))
    local cy = math.max(0, math.min(A.c.y * r, sh - c.h))
    check(math.abs(c.y - cy) <= 3, pre(tag) .. " #159 the Character window's top keeps its place in design units", fi(c.y), fi(cy))
    local wx = math.max(0, math.min(A.w.x * r, sw - w.w))
    check(math.abs(w.x - wx) <= 3, pre(tag) .. " #159 the World window's left edge keeps its place in design units", fi(w.x), fi(wx))
    local wy = math.max(0, math.min(A.w.y * r, sh - w.h))
    check(math.abs(w.y - wy) <= 3, pre(tag) .. " #159 the World window's top keeps its place in design units", fi(w.y), fi(wy))
end
step(1, function()
    worldTab("loot"); charTab("loot")
    L.B = pickB()
    if not L.B then
        note("no second UI scale fits this screen (root " .. string.format("%.2f", SC.root()) .. ", cap " .. tostring(SC.fitCap and SC.fitCap()) .. "): pass b is not run")
    end
end)
whenStill(true, "b", "on Loot before the scale change")
gstep(true, 1, function()
    L.GA = { c = geo(CW()), w = geo(WW()), s = ZeD.T.scale, root = SC.root() }
    L.scaleChanged = true
    say("scale " .. string.format("%.2f", L.GA.root) .. " -> " .. tostring(L.B) .. " through ZeD's Scale hook (the windows shut, re-theme and open again)")
    SC.override = L.B
    SC.refresh()
end)
gwait(true, 600, function()
    return math.abs((SC._appliedRoot or 0) - L.B) < 0.001 and SC._reopenAt == nil and CWm.isOpen() and WWm.isOpen()
end, "the Scale hook to reopen the windows", function(ok)
    check(ok, string.format("[b %.2fx]", L.B) .. " #159 the UI scale change shuts, re-themes and reopens both windows")
end)
whenStill(true, "b", "after the scale change")
gstep(true, 1, function()
    L.at.b = string.format("%.2fx", SC.root())
    safe(pre("b") .. " #159", scaledUp, "b")
    pairChecks("b", "after the scale change")
    shot("b_windows_after_scale")
end)
pass("b")
gstep(true, 1, function()
    worldTab("loot"); charTab("loot")
    SC.override = L.override
    SC.refresh()
end)
gwait(true, 600, function()
    return math.abs((SC._appliedRoot or 0) - L.GA.root) < 0.001 and SC._reopenAt == nil and CWm.isOpen() and WWm.isOpen()
end, "the windows back at the first scale", function(ok)
    check(ok, pre("a") .. " #159 the UI scale back: both windows shut, re-theme and reopen")
    L.scaleChanged = false
end)
whenStill(true, "a", "back at the first scale")
gstep(true, 1, function()
    local c, w = geo(CW()), geo(WW())
    check(sameGeo(c, L.GA.c, 2), pre("a") .. " #159 back at the first scale, the Character window is where and as big as it was", gs(c), gs(L.GA.c))
    check(sameGeo(w, L.GA.w, 2), pre("a") .. " #159 back at the first scale, the World window is where and as big as it was", gs(w), gs(L.GA.w))
    shot("a_windows_back")
end)

-- the end: everything put back, each window to its place and tab at the start
step(1, function()
    restoreAll("the end")
    placeBack()
end)
whenStill(false, "a", "put back")
step(1, function()
    local api = MN.api()
    local back = {}
    if L.radio ~= nil then back[#back + 1] = "the radio" end
    if p:getPrimaryHandItem() ~= L.prim then back[#back + 1] = "the main hand" end
    if SC.override ~= L.override then back[#back + 1] = "the UI scale" end
    if RT.useFaces ~= L.useFaces or IT.qaProf ~= L.qa.prof or IT.qaLayout ~= L.qa.layout then back[#back + 1] = "the QA switches" end
    if L.symN0 and api and api:getSymbolCount() ~= L.symN0 then back[#back + 1] = "the map's symbols" end
    if HT.gatherData ~= L.orig.hg then back[#back + 1] = "the Health model" end
    local o = L.orig
    if ZeD.Text.draw ~= o.draw or ZeD.Atoms.drawTextRight ~= o.tright or ZeD.Molecules.drawButton ~= o.btn or TP.drawTab ~= o.tab or TP.drawIcon ~= o.icon then
        back[#back + 1] = "the draw wrappers"
    end
    if p:getDescriptor():getCharacterProfession() ~= L.prof0 then back[#back + 1] = "the profession" end
    check(#back == 0, "put back: the radio and the hands, the scale, the QA switches, the map's symbols, the Health model, the draw wrappers, the profession",
        #back == 0 and "all" or table.concat(back, ", "), "all")
    if L.G0 and L.R0 and L.R0.char then
        local c, w = geo(CW()), geo(WW())
        check(sameGeo(c, L.G0.c, 2) and sameGeo(w, L.G0.w, 2), "put back: both windows where the run found them", gs(c) .. " | " .. gs(w), gs(L.G0.c) .. " | " .. gs(L.G0.w))
    end
    if not L.pairWasOpen and CWm.isOpen() then CWm.toggleBothPaired(0) end
    if L.sbSeen then
        note("#148 scrollbar states seen: " .. ((L.sbSeen.aon or L.sbSeen.bon) and "on " or "") .. ((L.sbSeen.aoff or L.sbSeen.boff) and "off" or ""))
    end
    say("RESULT " .. R.pass .. " pass, " .. R.fail .. " fail")
    say("DONE")
end)

Events.OnTick.Add(drive)
say("start")
