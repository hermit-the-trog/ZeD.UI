-- ZeDUI/tools/qa/zedqa_cov_b9to11.lua  (Nov 12 2026, QA coverage; tag cov_b9to11)
-- Real checks for the beta 9 to 11 fixes no check reached (qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md, Table B and B3).
-- In game, on the ZeD-QA save only (it stops at once on any other save). Copy to Zomboid/Lua/zedqa.lua and bump
-- zedqa.go, or run cov_b9to11.txt with zedqa_run.ps1; grep "ZEDQA cov_b9to11". PASS / FAIL / INFO / SHOT lines, a
-- RESULT line, then DONE. Pictures: Screenshots/zqa_cov_b9to11_*.png. Run it at 4K fullscreen (1.75x, then 1.0) and in
-- the 1920 x 1080 window (1.0, then a bigger step): only the 1080p run can catch #150's narrower inventory (opened for
-- the bigger scale) never widening again.
-- A check that only proves something is there or drawn says "(presence)"; one that proves the run's own staging says
-- "(setup)". A part the run cannot reach records a FAIL "...: not checked" with the reason, never silence.
--
-- How it reads what was drawn: for one UI frame at a time (Events.OnPreUIDraw to OnPostUIDraw) it wraps the draw
-- calls the fixes go through (ZeD.Text.draw, ZeD.Atoms.drawTextRight, ZeD.Molecules.drawButton, ZeD.TabPx.drawTab
-- and drawIcon, and the belt's and the tab strips' own drawTextureScaled), records their arguments and the palette at
-- the call, and checks them against the panel's fields and the model it drew from. Every wrapper passes the call on
-- unchanged, and all are taken off at the end (and after an error).
--
-- WHAT IT CHECKS. Each pass runs at the scale the run starts at ("a") and again at a second UI scale ("b": 1.0 when
-- the run starts at 1.3 or more, else the largest step the screen's cap allows; none on a Deck at 0.75, a FAIL there).
--   #159 windows jumping: both windows on Loot, wholly on the screen, apart, and still for 120 ticks with nothing
--        pressed; a click on Identity, Health, Radio and Loot in the Character window's strip opens it there and never
--        moves the World window; the pair shut and opened again comes back where and as big as it was; a UI scale
--        change through ZeD's own path (the Scale hook shuts, re-themes and reopens the windows: new windows) keeps each
--        window's place in design units (the Character window's right edge, the World window's left edge, both tops),
--        and back at the first scale both windows are exactly where they were, each inventory as wide as it was (#150)
--   tab-strip icons (ZeD_TabPx): every tab a strip offers has a lit icon, the tab drawn inside its hit zone, the icon
--        drawn once, centered in the drawn tab and inside the hit zone, at 16 x k whole pixels (k read from the drawing,
--        against the root scale rounded: 1.75 -> 2, 1.0 -> 1); its six pictures (shadow, five tones) in order; the
--        shadow one texel down-right at 0.55 idle / 0.25 active; the idle icon's middle tone is the accent the window
--        draws in, the active one's leans to textOnAccent; one tab drawn active, the window's own; with the window's
--        accent switched the idle icons follow it. Every icon's art is 16 x 16 (once)
--   belt strap and buckles (ZeD_Belt), read from the drawn frame, the whole zoom k from the rule (T.scale rounded, not
--        the belt's own T.art): the strap's pieces 30 texels tall at k, centered on the belt's row; the buckle (or the
--        waist belt's closure) drawn 58 x 40 at k, its middle on the screen's center, on the strap; the slots split
--        evenly round it (an odd one on the right) and on the strap (no belt slot on the QA character is a FAIL:
--        nothing to compare); the strap's pieces run end to end, each slot's piece its provider's material
--        (B.materialFor), the waist belt's piece under the buckle; each piece's two ends and repeated middle drawn from
--        its material's art at k; with another profession (pass a) the belt draws that profession's buckle. Art sizes
--   #147 permit stamp: a revoked permit (burglar) on the wide license draws PERMIT and the red REVOKED on one line with
--        a visible word space (at least a quarter line: the face's "a a" less "aa", a lone space measures 0 in it),
--        the line centered under CONCEALED CARRY; a valid permit (police officer) draws no REVOKED, PERMIT centered
--   #148 Health percent: with injury rows staged in the model the tab draws (8 rows under the figure, then 1 row with
--        the figure folded; the scrollbar state reported), every row's percent, "%" and all, lies inside its row and
--        inside the tab's stencil (win._healthView), and every row ends inside it
--   (#140, the radio's preset + on the drawn chassis, went with the chassis, Nov 13 2026)
--   #134 Custom Map Labels on ZeD's map (pass a): the game's Show opens ZeD's map (the game's own stays shut), bound to
--        the game's symbol store; a map mod's place label (text-place, the layer's color, not user defined, as Custom
--        Map Labels writes them) and a player's note (text-note, red ink) staged in the store are read by ZeD's map; in
--        Survey, Color and Paper (the style menu's path, the map's own style last) the style has the game's text layers,
--        and each symbol is judged by the engine's own rule on ZeD's map (WorldMapBaseSymbol.isVisible through the
--        map's own symbols: a symbol that is not user defined draws only while the map's PlaceNames is on) and its
--        layer's fill at zoom 14.5: the note draws in all three; the mod's label draws in Survey and Color and is hidden
--        in Paper by design. ZeD turns PlaceNames off outside Survey (MapsTab applyStyle: street and place names on
--        Survey only), so today the Color label check FAILs: the director's call (show a map mod's labels over the Color
--        picture, or hide them with the game's own names and make this check expect that)
-- PUT BACK at the end, and after an error (the run goes straight to its last steps): the wrappers, the radio (taken
-- away) and the hands, the profession, the belt's form, the Identity tab's QA switches, the window accents, the
-- Health model, the two symbols, the map's style and pop-out, the UI scale, the window flags, each window's place and
-- tab (ZeD's own Go to saved position path; the player's saved places are not written), the debug console, each window
-- open or shut as the run found it, the game speed. Each is checked after it is put back.

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
-- a part of the run it could not reach: a FAIL with the reason, never silence
local function skip(what, why) check(false, what .. ": not checked", why, "checked") end
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
    if wn ~= "ZeD-QA" then say("ERR this is not the ZeD-QA save (" .. wn .. "): nothing was done"); say("DONE"); return end
    if not (CWm and WWm and TP and HT and IT and RT and BL and MN and WP and SC and Z.Text and Z.Atoms and Z.Molecules and Z.MapsTab) then
        say("ERR a ZeD module is missing: nothing was done"); say("DONE"); return
    end
end
-- a run before this one that never finished: its steps stop and its changes come off first
if type(ZEDQA_COV_B9TO11) == "table" then
    if ZEDQA_COV_B9TO11.stop then pcall(ZEDQA_COV_B9TO11.stop) end
    if ZEDQA_COV_B9TO11.restore then pcall(ZEDQA_COV_B9TO11.restore, "a run before this one") end
end
-- the QA home (the drag strip), as the other scripts start; a run without the prelude has no ZEDQA_HOME
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end

-- ---------------------------------------------------------------------------------------------------------------
-- THE LEDGER: what the run found and changed, so it can be put back and checked
-- ---------------------------------------------------------------------------------------------------------------
-- the profession object (nil without one); the Belt option's value (1 Full, 2 Simple)
local function profNow()
    local d = p:getDescriptor()
    if not d then return nil end
    return d:getCharacterProfession()
end
local function beltStyleNow()
    local o = ZeD.Settings and ZeD.Settings.beltStyleOption
    if not o then return nil end
    local ok, v = pcall(function() return o:getValue() end)
    if ok then return v end
    return nil
end
local L = {
    done = false, hooks = {}, wraps = {}, dbg = {}, at = {},
    prim = p:getPrimaryHandItem(), sec = p:getSecondaryHandItem(),
    qa = { prof = IT.qaProf, layout = IT.qaLayout, style = IT.qaStyle, trend = IT.qaTrend },
    override = SC.override, root0 = SC.root(), prof0 = profNow(), beltStyle0 = beltStyleNow(), speed0 = getGameSpeed(),
    charWasOpen = CWm.isOpen() and true or false, worldWasOpen = WWm.isOpen() and true or false,
    -- the functions the run wraps, as found (the put-back check compares against them)
    orig = { draw = ZeD.Text.draw, tright = ZeD.Atoms.drawTextRight, btn = ZeD.Molecules.drawButton, tab = TP.drawTab, icon = TP.drawIcon,
             hg = HT.gatherData },
}
-- the pair opens both windows only while the game runs (paused, the toggle opens the Character window alone): a paused
-- game is unpaused for the run and paused again at its end
if L.speed0 <= 0 then setGameSpeed(1); L.speedChanged = true end

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
-- the accent a window draws in: its own, else the theme's
local function effAccent(win) if not win then return nil end; return win._accentKey or ZeD.currentAccent end
-- the whole multiple pixel art draws at for scale s, from the rule itself (the nearest whole number, exactly .5 up,
-- never below 1: Scale.lua's 1.75 -> 2, 1.25 -> 1), not from the mod's TP.k or T.art; the fixed steps by table
local ART_K = { ["0.50"] = 1, ["0.75"] = 1, ["1.00"] = 1, ["1.25"] = 1, ["1.50"] = 2, ["1.75"] = 2, ["2.00"] = 2 }
local function wholeZoom(s)
    local k = ART_K[string.format("%.2f", s)]
    if k then return k end
    k = math.floor(s)
    if s - k >= 0.5 - 1e-6 then k = k + 1 end
    if k < 1 then k = 1 end
    return k
end
local function itemName(it)
    if it == nil then return "nothing" end
    local ok, n = pcall(function() return it:getFullType() end)
    if ok and n then return tostring(n) end
    return tostring(it)
end
local function profName(pr)
    if pr == nil then return "none" end
    local ok, n = pcall(function() return pr:getName() end)
    if ok and n then return tostring(n) end
    return tostring(pr)
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
        -- (the size and place it is drawn at are read from the draws, not from TP.k)
        local rec = { el = el, id = id, cx = cx, cy = cy, active = isActive and true or false,
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
    -- (the belt's own fields as found, for the put-back check)
    if not L.hudRaw then L.hudRaw = { hud = hud, ts = rawget(hud, "drawTextureScaled"), tsa = rawget(hud, "drawTextureScaledAspect") } end
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
    local prof = profNow()
    if prof == nil then return nil end
    return string.lower(tostring(prof:getName())):match("([^:]+)$")
end
local function speedBack()
    if L.speedChanged then L.speedChanged = false; setGameSpeed(L.speed0) end
end
-- the Identity photo and Health figure folds as the run found them, on the Character window open now
local function applyFolds()
    local w = CW()
    if w and L.flags then
        w._identityPhotoExpanded, w._healthFigureExpanded = L.flags.id, L.flags.hf
        w._healthCache, w._identityCache = nil, nil
    end
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
    -- (by the flag: a character that started with no profession gets none back)
    pcall(function() if L.profChanged then p:getDescriptor():setCharacterProfession(L.profWas); L.profWas, L.profChanged = nil, false end end)
    pcall(function() if L.beltStyleWas then ZeD.Settings.beltStyleOption:setValue(L.beltStyleWas); L.beltStyleWas = nil end end)
    pcall(restoreMap)
    pcall(function() if L.scaleChanged then SC.override = L.override; SC.refresh(); L.scaleChanged = false end end)
    pcall(applyFolds)
    pcall(function() for _, e in ipairs(L.dbg) do e:setVisible(true) end end)
    say("restored (" .. tostring(why) .. ")")
end
-- (a later run that finds this one unfinished puts its changes back through this)
ZEDQA_COV_B9TO11 = { restore = function(why) restoreAll(why); pcall(speedBack) end }
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
-- skipped when there is no second scale. An error in a step goes straight to the last steps (from EPI.at: the
-- put-back and its checks), so a stopped run puts back and checks what it changed as a finished one does.
-- ---------------------------------------------------------------------------------------------------------------
local Q, QI, EPI = {}, { i = 1, t = 0 }, { at = nil }
local drive   -- (named before the closures that use it: Kahlua binds a free name when the closure is made)
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
local function whenStill(g, tag, what, lbl)
    gwait(g, 900, stillCond(), "the windows to settle (" .. what .. ")", function(ok)
        if not ok then check(false, pre(tag) .. " " .. (lbl or "#159 the windows settle") .. ": " .. what, "still moving", "still within 900 ticks") end
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
-- an error while putting back: what is left goes back at once (no ticks left to wait on)
local function finishNow(why)
    restoreAll(why)
    pcall(placeBack)
    pcall(function()
        if L.charWasOpen == false and CWm.isOpen() then CWm.toggle(0) end
        if L.worldWasOpen == false and WWm.isOpen() then WWm.close(0) end
    end)
    pcall(speedBack)
    say("RESULT " .. R.pass .. " pass, " .. R.fail .. " fail")
    say("DONE")
    ZEDQA_COV_B9TO11 = nil
end
drive = function()
    local cur = QI.i
    local s = Q[cur]
    if not s then Events.OnTick.Remove(drive); return end
    QI.t = QI.t + 1
    local ok, err = true, nil
    if s.cond then
        local okc, yes = pcall(s.cond)
        if not okc then
            ok, err = false, yes
        elseif yes or QI.t >= s.max then
            QI.i, QI.t = cur + 1, 0
            if s.fn then ok, err = pcall(s.fn, yes and true or false)
            elseif not yes then check(false, "waited for " .. tostring(s.what), "timed out", "within " .. s.max .. " ticks") end
        end
    elseif QI.t >= s.n then
        QI.i, QI.t = cur + 1, 0
        ok, err = pcall(s.fn)
    end
    if ok then return end
    -- (the step that failed, not the one after it)
    say("ERR step " .. tostring(cur) .. ": " .. tostring(err))
    R.fail = R.fail + 1
    if EPI.at and cur < EPI.at then
        L.why = "an error at step " .. tostring(cur)
        QI.i, QI.t = EPI.at, 0
        return
    end
    Events.OnTick.Remove(drive)
    finishNow("an error while putting back")
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
-- the Character window on a tab through a click on its strip, then: the World window where it was, the pair on the
-- screen and apart. A tab the strip offers no hit zone for is a FAIL; it is never opened by writing the window's state
-- (that would make the next check pass on the values written)
local function openCharTab(g, tag, id)
    gstep(g, 1, function() L.wwBefore = geo(WW()); L.tabState = "looking" end)
    gwait(g, 60, function() return charTab(id) end, "the " .. id .. " tab's hit zone", function(ok)
        if ok then L.tabState = "clicked"; return end
        L.tabState = "no zone"
        check(false, pre(tag) .. " the " .. id .. " tab is on the Character window's strip to click", "no hit zone in 60 ticks", "tab:" .. id)
    end)
    gwait(g, 180, function()
        if L.tabState ~= "clicked" then return true end
        local w = CW()
        return w ~= nil and w._activeTab == id and (id == "loot" or w._drawerOpen == true)
    end, "the " .. id .. " tab to open", function(ok)
        if L.tabState ~= "clicked" then return end
        if check(ok, pre(tag) .. " a click on the strip opens the Character window on " .. id) then L.tabState = "open" end
    end)
    whenStill(g, tag, "the " .. id .. " tab open")
    gstep(g, 1, function()
        if L.tabState ~= "open" then
            skip(pre(tag) .. " #159 " .. id .. " in the Character window leaves the World window where it was", "the " .. id .. " tab did not open")
            return
        end
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
    if not check(strip ~= nil, nm .. ": (presence) the strip is there") then return end
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
    if not check(#zones > 0, nm .. ": (presence) the strip offers tabs", #zones, "> 0") then return end
    local root = SC.root()
    local kWant = wholeZoom(root)
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
            local okPics, why = iconPicsOk(ic)
            if not okPics then
                picBad[#picBad + 1] = id .. " (" .. tostring(why) .. ")"
                iconBad[#iconBad + 1] = id .. " (its pictures: " .. tostring(why) .. ")"
            else
                local d = ic.draws
                local t1 = d[2]           -- (the first tone, as drawn: its size and place are the icon's)
                local sz = t1.w
                local k = sz / 16         -- (the multiple it was drawn at)
                local mx, my = t1.x + sz / 2, t1.y + t1.h / 2
                if not tr or math.abs(mx - (tr.x + tr.w / 2)) > 0.5 or math.abs(my - (tr.y + tr.h / 2)) > 0.5
                   or t1.h ~= sz or k ~= kWant or t1.x ~= math.floor(t1.x) or t1.y ~= math.floor(t1.y)
                   or t1.x < z.x or t1.y < z.y or t1.x + sz > z.x + z.w or t1.y + sz > z.y + z.h then
                    iconBad[#iconBad + 1] = id .. " drawn at " .. fi(t1.x) .. "," .. fi(t1.y) .. " " .. tostring(sz) .. "x" .. tostring(t1.h)
                        .. (tr and (", its tab " .. fi(tr.x) .. "," .. fi(tr.y) .. " " .. fi(tr.w) .. "x" .. fi(tr.h)) or ", no tab drawn")
                end
                for i = 3, 6 do
                    if d[i].x ~= t1.x or d[i].y ~= t1.y or d[i].w ~= sz or d[i].h ~= t1.h then iconBad[#iconBad + 1] = id .. " tone " .. TONES[i - 1] .. " off the first tone's place" end
                end
                local sh = d[1]
                if sh.x ~= t1.x + k or sh.y ~= t1.y + k or sh.w ~= sz or sh.h ~= t1.h or math.abs((sh.a or 0) - (ic.active and 0.25 or 0.55)) > 0.001
                   or (sh.r or 0) ~= 0 then
                    shadowBad[#shadowBad + 1] = id
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
    check(#iconBad == 0, nm .. ": each icon drawn once, centered in its drawn tab and inside its hit zone, at 16 x " .. kWant
        .. " whole pixels (the root scale " .. string.format("%.2f", root) .. " rounded)", #iconBad == 0 and "all" or iconBad[1], "all")
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
-- the first piece drawn with this picture, wherever it is
local function beltFind(kind, tex)
    for _, q in ipairs(CAP.belt) do
        if q.k == kind and texSame(q.tex, tex) then return q end
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
    L.lastBuckleKind = nil
    local hud = BL.getHUD(0)
    if not check(hud ~= nil and hud._drawn == true, nm .. ": (presence) the belt is on the screen") then return end
    local s, b, c = hud._strap, hud._buckle, hud._closure
    if not check(s ~= nil and b ~= nil, nm .. ": (presence) the full belt lays out its strap and buckle") then return end
    local T = ZeD.T
    local k = wholeZoom(T.scale or 1)   -- (from the rule; the belt draws at its own T.art, which is what is checked)
    local runs = hud._runs or {}
    local kind = (c and c.kind) or "buckle"
    L.lastBuckleKind = kind
    local art = matTex("leather", "mid") ~= nil
    -- the strap as drawn: every piece of a run's material art, its ends and its middle tiles
    local dl, dr, pieces, badH, offRow = nil, nil, 0, nil, nil
    local rowMid = hud:getHeight() / 2
    if not art then
        skip(nm .. ": the strap's pixel art (its height, place and pieces as drawn)", "the strap art is missing: the belt draws its plain leather")
    else
        local seen = {}
        for _, r in ipairs(runs) do
            local Lt, Mt, Rt = matTex(r[3], "l"), matTex(r[3], "mid"), matTex(r[3], "r")
            if not (Lt and Mt and Rt) then Lt, Mt, Rt = matTex("leather", "l"), matTex("leather", "mid"), matTex("leather", "r") end
            for _, q in ipairs(CAP.belt) do
                local isL, isR = texSame(q.tex, Lt), texSame(q.tex, Rt)
                if q.k == "ts" and not seen[q] and (isL or isR or texSame(q.tex, Mt)) then
                    seen[q] = true
                    pieces = pieces + 1
                    if math.abs(q.h - 30 * k) > 0.5 then badH = badH or fi(q.h) end
                    if math.abs(q.y + q.h / 2 - rowMid) > 1 then offRow = offRow or ("drawn at y " .. fi(q.y) .. ", " .. fi(q.h) .. " tall") end
                    if isL and (dl == nil or q.x < dl) then dl = q.x end
                    if isR and (dr == nil or q.x + q.w > dr) then dr = q.x + q.w end
                end
            end
        end
        check(pieces > 0 and badH == nil and offRow == nil, nm .. ": the strap is drawn 30 texels tall at the whole zoom " .. k
            .. " (T.scale " .. string.format("%.3f", T.scale or 0) .. " rounded), centered on the belt's row",
            (pieces == 0 and "no strap piece drawn") or (badH and ("a piece " .. badH .. " px tall")) or offRow or (pieces .. " pieces " .. fi(30 * k) .. " px tall"),
            fi(30 * k) .. " px tall, its middle at " .. fi(rowMid))
    end
    local sl, sr = dl or s.x, dr or (s.x + s.w)   -- (the strap's ends as drawn; as laid out without its art)
    -- the buckle, or the waist belt's own closure, as drawn
    local q, ww, wh, what = nil, 58 * k, 40 * k, nil
    if kind ~= "buckle" then
        local tex = shared(BELT .. "closure_" .. kind .. ".png")
        wh = ((BL.CLOSURE_H and BL.CLOSURE_H[kind]) or 40) * k
        q = tex and beltFind("ts", tex)
        what = "the waist belt's closure (" .. kind .. ")"
    else
        local tex = buckleTexFor(profIdNow())
        q = tex and beltFind("tsa", tex)
        what = "the profession's buckle (" .. tostring(profIdNow()) .. ")"
    end
    if check(q ~= nil, nm .. ": (presence) " .. what .. " is drawn", q and "drawn" or "not found", "drawn") then
        check(math.abs(q.w - ww) < 0.5 and math.abs(q.h - wh) < 0.5, nm .. ": " .. what .. " is drawn " .. fi(ww) .. " x " .. fi(wh)
            .. " (its art at the whole zoom " .. k .. ")", fi(q.w) .. "x" .. fi(q.h), fi(ww) .. "x" .. fi(wh))
        local mid = getPlayerScreenLeft(0) + math.floor(getPlayerScreenWidth(0) / 2)
        local qm = hud:getAbsoluteX() + q.x + q.w / 2
        check(math.abs(qm - mid) <= 1, nm .. ": " .. what .. ", as drawn, has its middle on the screen's center", fi(qm), fi(mid))
        check(q.x >= sl - 0.5 and q.x + q.w <= sr + 0.5, nm .. ": " .. what .. " lies on the strap as drawn", fi(q.x) .. "-" .. fi(q.x + q.w), fi(sl) .. "-" .. fi(sr))
    end
    local bl, br = (q and q.x) or b.x, (q and (q.x + q.w)) or (b.x + b.w)
    local slots = {}
    for _, bx in ipairs(hud._boxes or {}) do if bx.kind == "slot" then slots[#slots + 1] = bx end end
    local n = #slots
    if n == 0 then
        skip(nm .. ": the slots round the buckle (the split, on the strap, each one's material)", "the QA character has no belt slots: nothing to compare (wear a belt or a holster)")
    else
        local kk = math.floor(n / 2)   -- (half each side, an odd one on the right: the rule, not BL.closureAfter)
        local left, right, off = 0, 0, 0
        for _, bx in ipairs(slots) do
            if bx.x + bx.w <= bl then left = left + 1 elseif bx.x >= br then right = right + 1 end
            if bx.x < sl or bx.x + bx.w > sr then off = off + 1 end
        end
        check(left == kk and right == n - kk, nm .. ": the buckle splits the " .. n .. " slots evenly, an odd one on the right", left .. " left, " .. right .. " right", kk .. ", " .. (n - kk))
        check(off == 0, nm .. ": every slot box sits on the strap as drawn", off .. " off it", 0)
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
    end
    local gaps = 0
    for i = 2, #runs do if math.abs(runs[i][1] - runs[i - 1][2]) > 1 then gaps = gaps + 1 end end
    local ends = #runs > 0 and math.abs(runs[1][1] - s.x) <= 1 and math.abs(runs[#runs][2] - (s.x + s.w)) <= 1
    check(ends and gaps <= ((kind == "knot") and 1 or 0), nm .. ": the strap's pieces run end to end" .. ((kind == "knot") and " (cut once at the knot's eye)" or ""),
        #runs .. " pieces, " .. gaps .. " gaps", "end to end")
    if kind ~= "knot" then
        local cx = math.floor((bl + br) / 2)
        local got = nil
        for _, r in ipairs(runs) do if cx >= r[1] and cx < r[2] then got = r[3] end end
        check(got == hud._waist, nm .. ": the piece under the buckle is the waist belt's", tostring(got), tostring(hud._waist))
    end
    -- the frame: each piece's art at the whole zoom
    if art then
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
                for _, qq in ipairs(CAP.belt) do
                    if qq.k == "ts" and texSame(qq.tex, Mt) and qq.x >= x0 - 0.5 and qq.x < x1 and math.abs(qq.y - y) < 0.5 and math.abs(qq.w - tw) < 0.5 and math.abs(qq.h - th) < 0.5 then
                        got = got + 1
                    end
                end
                if got ~= want then bad = bad or (r[3] .. " middle " .. got .. " tiles vs " .. want) end
            end
        end
        check(bad == nil, nm .. ": each piece drawn from its material's art: both ends and the middle repeated, at the whole zoom " .. k, bad or (#runs .. " pieces"), "every piece")
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
    if not check(l1R ~= nil and l2R ~= nil, nm .. ": (presence) the wide license draws its permit stamp (" .. l1s .. " / " .. l2s .. ")",
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
        check(math.abs(midL - l1R.x) <= 1, nm .. ": " .. l2s .. " " .. rv .. " centered under " .. l1s, string.format("%.1f", midL), string.format("%.1f", l1R.x))
    else
        check(rvR == nil, nm .. ": a valid permit (police officer) draws no " .. rv, rvR and "drawn" or "none", "none")
        local midL = l2R.x + w2 / 2
        check(math.abs(midL - l1R.x) <= 1, nm .. ": " .. l2s .. " alone, centered under " .. l1s, string.format("%.1f", midL), string.format("%.1f", l1R.x))
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE HEALTH PERCENT (#148)
-- ---------------------------------------------------------------------------------------------------------------
local function analyzeHealth(tag, label, nWant)
    local nm = pre(tag) .. " #148 " .. label
    local w = CW()
    local view, zones = w and w._healthView, (w and w._healthInjuryZones) or {}
    if not check(view ~= nil, nm .. ": (presence) the Health tab drew its body") then return end
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
    check(#zones > 0 and missing == 0, nm .. ": every row draws its percent", missing .. " missing of " .. #zones, 0)
    check(#zones > 0 and bad == nil, nm .. ": every percent whole, \"%\" and all, inside its row and the tab's stencil (right edge " .. fi(vr) .. ")",
        bad or ("the rightmost ends " .. fi(-worst) .. " px inside"), "inside")
    check(#zones > 0 and rowOut == nil, nm .. ": every row ends inside the stencil (the list padded both sides)", rowOut or "all inside", "inside")
    local sb = w._healthScroll and w._healthScroll.visible
    note(nm .. ": the scrollbar is " .. (sb and "on" or "off") .. " here")
    L.sbSeen = L.sbSeen or {}
    L.sbSeen[tag .. (sb and "on" or "off")] = true
end

-- ---------------------------------------------------------------------------------------------------------------
-- #134: ZeD's map and a map mod's labels
-- ---------------------------------------------------------------------------------------------------------------
local ZOOM = 14.5
local function mapStyleChecks(st)
    local nm = pre("a") .. " #134 " .. st
    local mp = mapPanel()
    if not check(mp ~= nil and mp.mapAPI ~= nil, nm .. ": (presence) ZeD's map is there") then return end
    local styleAPI = mp.mapAPI:getStyleAPI()
    local lp, ln = nil, nil
    pcall(function() lp = styleAPI:getLayerByName("text-place") end)
    pcall(function() ln = styleAPI:getLayerByName("text-note") end)
    check(lp ~= nil and ln ~= nil, nm .. ": the style has the game's text layers (text-place, text-note)", tostring(lp ~= nil) .. "/" .. tostring(ln ~= nil), "true/true")
    local an = ln and alphaAt(ln, ZOOM)
    local ap = lp and alphaAt(lp, ZOOM)
    -- each staged symbol as ZeD's map judges it: read through the map's own symbols (MapNotes.panelAPI), whose
    -- isVisible is the engine's WorldMapBaseSymbol.isVisible on this map: a symbol that is not user defined (a map's or
    -- a map mod's label) draws only while this map's PlaceNames is on
    local pa = MN.panelAPI(mp)
    local s1, s2 = storeFind(pa, MARK1), storeFind(pa, MARK2)
    if not check(s1 ~= nil and s2 ~= nil, nm .. ": after the restyle ZeD's map still reads both staged symbols from the game's store",
        tostring(s1 ~= nil) .. "/" .. tostring(s2 ~= nil), "true/true") then return end
    local pn, v1, v2, ud1 = nil, nil, nil, nil
    pcall(function() pn = mp.mapAPI:getBoolean("PlaceNames") end)
    pcall(function() v1 = s1:isVisible() end)
    pcall(function() v2 = s2:isVisible() end)
    pcall(function() ud1 = s1:isUserDefined() end)
    local why1 = "isVisible " .. tostring(v1) .. " (PlaceNames " .. tostring(pn) .. ", user defined " .. tostring(ud1) .. "), text-place fill " .. tostring(ap)
    check(v2 == true and an ~= nil and an > 0, nm .. ": a player's note (text-note, user defined) draws at zoom " .. ZOOM,
        "isVisible " .. tostring(v2) .. ", text-note fill " .. tostring(an), "true, > 0")
    if st == "paper" then
        check(v1 ~= nil and (v1 == false or (ap ~= nil and ap == 0)), nm .. ": a map mod's label is hidden by design (Paper prints its own names)", why1, "hidden")
    else
        local ok = check(v1 == true and ap ~= nil and ap > 0, nm .. ": a map mod's label (text-place, not user defined) draws at zoom " .. ZOOM
            .. ", as on the game's map with its Place Names on", why1, "isVisible true, text-place fill > 0")
        if not ok and pn == false then
            note(nm .. ": ZeD's " .. st .. " turns the game's PlaceNames off (MapsTab applyStyle: street and place names on Survey only), and the"
                .. " engine draws no symbol that is not user defined then: a map mod's labels go with the game's own names. Show them over"
                .. " this style, or hidden by design: the director's call")
        end
    end
    local zf = nil
    pcall(function() zf = mp.mapAPI:getZoomF() end)
    note(nm .. ": the map shows zoom " .. tostring(zf))
end

-- ---------------------------------------------------------------------------------------------------------------
-- THE PUT-BACK CHECKS: each thing the run changed, against what it found (after the put-back and the windows' return)
-- ---------------------------------------------------------------------------------------------------------------
local function finalChecks()
    local inv = p:getInventory()
    local it = L.radioGiven
    local radioGone = (it == nil) or not (inv:contains(it) or p:getPrimaryHandItem() == it or p:getSecondaryHandItem() == it)
    check(radioGone and p:getPrimaryHandItem() == L.prim and p:getSecondaryHandItem() == L.sec,
        "put back: the radio given is gone, and the hands hold what they held (main and off hand)",
        "radio " .. (radioGone and "gone" or "left") .. ", hands " .. itemName(p:getPrimaryHandItem()) .. " / " .. itemName(p:getSecondaryHandItem()),
        "gone, " .. itemName(L.prim) .. " / " .. itemName(L.sec))
    check(profNow() == L.prof0, "put back: the profession", profName(profNow()), profName(L.prof0))
    check(IT.qaProf == L.qa.prof and IT.qaLayout == L.qa.layout and IT.qaStyle == L.qa.style and IT.qaTrend == L.qa.trend,
        "put back: the Identity tab's QA switches (profession, layout, style, trend)",
        tostring(IT.qaProf) .. "," .. tostring(IT.qaLayout) .. "," .. tostring(IT.qaStyle) .. "," .. tostring(IT.qaTrend),
        tostring(L.qa.prof) .. "," .. tostring(L.qa.layout) .. "," .. tostring(L.qa.style) .. "," .. tostring(L.qa.trend))
    check(beltStyleNow() == L.beltStyle0, "put back: the belt's form (the Belt option)", tostring(beltStyleNow()), tostring(L.beltStyle0))
    if L.acc0 then
        local ca, wa = effAccent(CW()), effAccent(WW())
        check(ca == L.acc0.c and wa == L.acc0.w, "put back: the accent each window draws in", tostring(ca) .. "/" .. tostring(wa), tostring(L.acc0.c) .. "/" .. tostring(L.acc0.w))
    end
    check(SC.override == L.override and math.abs(SC.root() - L.root0) < 0.001, "put back: the UI scale (its QA override and the root scale)",
        tostring(SC.override) .. ", " .. string.format("%.2f", SC.root()), tostring(L.override) .. ", " .. string.format("%.2f", L.root0))
    local api = MN.api()
    local left = (api and storeFind(api, MARK1) and 1 or 0) + (api and storeFind(api, MARK2) and 1 or 0)
    check(left == 0, "put back: no staged symbol left in the game's map store", left .. " left", 0)
    if L.popWas ~= nil then
        local w = WW()
        local popNow = w ~= nil and w._mapPopout ~= nil
        local md = p:getModData()
        local mp = mapPanel()
        local styleNow = mp and mp.style
        check(popNow == L.popWas and (mp == nil or L.styleWas == nil or styleNow == L.styleWas) and md.ZeD_MapStyle == L.mdStyle and md.ZeD_MapPaper == L.mdPaper,
            "put back: the map's pop-out, its style and the character's saved map style",
            tostring(popNow) .. ", " .. tostring(styleNow) .. ", " .. tostring(md.ZeD_MapStyle) .. "/" .. tostring(md.ZeD_MapPaper),
            tostring(L.popWas) .. ", " .. tostring(L.styleWas) .. ", " .. tostring(L.mdStyle) .. "/" .. tostring(L.mdPaper))
    end
    local o = L.orig
    local wrapsOk = ZeD.Text.draw == o.draw and ZeD.Atoms.drawTextRight == o.tright and ZeD.Molecules.drawButton == o.btn and TP.drawTab == o.tab and TP.drawIcon == o.icon
    local hr = L.hudRaw
    local hudOk = hr == nil or (rawget(hr.hud, "drawTextureScaled") == hr.ts and rawget(hr.hud, "drawTextureScaledAspect") == hr.tsa)
    check(HT.gatherData == o.hg and wrapsOk and hudOk, "put back: the Health model, the draw wrappers and the belt's own draw calls",
        tostring(HT.gatherData == o.hg) .. "/" .. tostring(wrapsOk) .. "/" .. tostring(hudOk), "true/true/true")
    if #L.dbg > 0 then
        local hidden = 0
        for _, e in ipairs(L.dbg) do if not e:isVisible() then hidden = hidden + 1 end end
        check(hidden == 0, "put back: the debug console shows again", hidden .. " hidden", 0)
    end
    local c, w = CW(), WW()
    if c and L.flags then
        local idNow, hfNow = c._identityPhotoExpanded and true or false, c._healthFigureExpanded and true or false
        check(idNow == (L.flags.id and true or false) and hfNow == (L.flags.hf and true or false),
            "put back: the Character window's Identity photo and Health figure folds", tostring(idNow) .. "/" .. tostring(hfNow), tostring(L.flags.id) .. "/" .. tostring(L.flags.hf))
    end
    if L.G0 and L.R0 and L.R0.char then
        local cg, wg = geo(c), geo(w)
        check(sameGeo(cg, L.G0.c, 2) and sameGeo(wg, L.G0.w, 2), "put back: both windows where the run found them", gs(cg) .. " | " .. gs(wg), gs(L.G0.c) .. " | " .. gs(L.G0.w))
        local ct, wt = c and c._activeTab, w and w._activeTab
        local ct0, wt0 = L.R0.char.activeTab, L.R0.world and L.R0.world.activeTab
        check(ct == ct0 and (L.R0.world == nil or wt == wt0), "put back: each window on the tab it was on", tostring(ct) .. "/" .. tostring(wt), tostring(ct0) .. "/" .. tostring(wt0))
    end
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
    gstep(g, 1, function()
        local c, w = CW(), WW()
        check(c ~= nil and w ~= nil and c._activeTab == "loot" and w._activeTab == "loot", pre(tag) .. " (setup) both windows on Loot",
            tostring(c and c._activeTab) .. "/" .. tostring(w and w._activeTab), "loot/loot")
        pairChecks(tag, "both on Loot"); L.hold, L.moved = shape(), false; L.holdN = 0
    end)
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
            L.profTo = nil
            local what = pre(tag) .. " belt: the buckle follows the profession"
            if L.lastBuckleKind ~= "buckle" then
                skip(what, (L.lastBuckleKind == nil) and "the belt was not read" or ("the waist belt shuts with its own closure (" .. tostring(L.lastBuckleKind) .. "): no profession buckle"))
                return
            end
            local d, id = otherProfession()
            if not d then skip(what, "no other profession with a buckle found"); return end
            L.profWas, L.profChanged = profNow(), true
            L.profTo = id
            p:getDescriptor():setCharacterProfession(d:getType())
        end)
        gstep(g, 5, function() end)
        capture(g, { belt = true }, hookBelt)
        gstep(g, 1, function()
            if L.profTo then
                local k = wholeZoom(ZeD.T.scale or 1)
                local tex = shared(BUCKLES .. L.profTo .. ".png")
                local q = tex and beltFind("tsa", tex)
                check(q ~= nil and math.abs(q.w - 58 * k) < 0.5 and math.abs(q.h - 40 * k) < 0.5,
                    pre(tag) .. " belt: with the profession changed to " .. L.profTo .. ", the belt draws that profession's buckle (58 x 40 at the whole zoom " .. k .. ")",
                    q and (fi(q.w) .. "x" .. fi(q.h)) or "not found", "buckle_" .. L.profTo)
                shot(tag .. "_belt_buckle_" .. L.profTo)
                p:getDescriptor():setCharacterProfession(L.profWas)
                L.profWas, L.profTo, L.profChanged = nil, nil, false
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
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end)
waitUntil(150, function() return CWm.isOpen() and WWm.isOpen() end, "the window pair to open", function(ok)
    if not ok then error("the window pair did not open") end
end)
whenStill(false, "a", "the start")
step(1, function()
    local c, w = CW(), WW()
    L.G0 = { c = geo(c), w = geo(w) }
    L.flags = { id = c._identityPhotoExpanded, hf = c._healthFigureExpanded }
    L.acc0 = { c = effAccent(c), w = effAccent(w) }
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
    -- the styles in an order that ends on the map's own, so each one is a real restyle from another
    L.styleOrder = {}
    for _, s in ipairs({ "survey", "color", "paper" }) do if s ~= L.styleWas then L.styleOrder[#L.styleOrder + 1] = s end end
    if L.styleWas == "survey" or L.styleWas == "color" or L.styleWas == "paper" then L.styleOrder[#L.styleOrder + 1] = L.styleWas end
    check(mp ~= nil and mp._zedNotesBound == true, pre("a") .. " #134 (presence) ZeD's map says it is bound to the game's symbol store (the world map item)")
end)
step(5, function()
    local api, mp = MN.api(), mapPanel()
    if not check(api ~= nil and mp ~= nil, pre("a") .. " #134 (presence) the symbol store answers") then return end
    L.symN0 = api:getSymbolCount()
    local sc = (ISMap and ISMap.SCALE) or 0.666
    local x, y = p:getX(), p:getY()
    local s1 = api:addTranslatedText(MARK1, "text-place", x, y - 6)
    L.symsAdded = true
    s1:setRGBA(0, 0, 0, 0)   -- (the layer's own color: a text symbol with no alpha takes its layer's, as the mod's read in QA's probe)
    s1:setAnchor(0.5, 0.5)
    s1:setScale(sc)
    pcall(function() s1:setUserDefined(false) end)
    local s2 = api:addTranslatedText(MARK2, "text-note", x, y + 6)
    s2:setRGBA(0.65, 0.054, 0.054, 1.0)
    s2:setAnchor(0.5, 0.5)
    s2:setScale(sc)
    local n1 = api:getSymbolCount()
    check(n1 == L.symN0 + 2, pre("a") .. " #134 (setup) a map mod's place label and a note put in the store", n1, L.symN0 + 2)
    check(s1:isUserDefined() == false and s2:isUserDefined() == true,
        pre("a") .. " #134 (setup) the label is not user defined, as Custom Map Labels writes its labels; the note is, as the player's are",
        tostring(s1:isUserDefined()) .. "/" .. tostring(s2:isUserDefined()), "false/true")
    local pa = MN.panelAPI(mp)
    check(pa ~= nil and pa:getSymbolCount() == n1 and storeFind(pa, MARK1) ~= nil, pre("a") .. " #134 ZeD's map reads the same store: it holds the mod's label",
        pa and pa:getSymbolCount(), n1)
    -- (the Show route already centered the map on the character at zoom 14.5; the layer checks read zoom 14.5 whatever it shows)
end)
for i = 1, 3 do
    step(2, function()
        local st = (L.styleOrder and L.styleOrder[i]) or ({ "survey", "color", "paper" })[i]
        local mp = mapPanel()
        L.styleNow, L.styleFrom = st, mp and mp.style
        L.styleSkip = (st == "paper" and not (ZeD.MapsTab.hasPaper and ZeD.MapsTab.hasPaper()))
        if L.styleSkip then skip(pre("a") .. " #134 paper", "no Paper art on this install (the base map's spawnSelectImagePyramid)"); return end
        ZeD.MapsTab.setStyle(WW(), st)
    end)
    waitUntil(240, function()
        if L.styleSkip then return true end
        local mp = mapPanel()
        return mp ~= nil and mp.style == L.styleNow and mp._styleWanted == nil
    end, "the map to restyle", function(ok)
        if not L.styleSkip then check(ok, pre("a") .. " #134 the style menu's " .. tostring(L.styleNow) .. " restyles ZeD's map (from " .. tostring(L.styleFrom) .. ")") end
    end)
    step(20, function()
        if L.styleSkip then return end
        safe(pre("a") .. " #134", mapStyleChecks, L.styleNow)
        shot("a_map_" .. tostring(L.styleNow))
    end)
end
step(2, function()
    local n = removeMarks()
    L.symsAdded = false
    local api = MN.api()
    local left = (api and storeFind(api, MARK1) and 1 or 0) + (api and storeFind(api, MARK2) and 1 or 0)
    check(n == 2 and api ~= nil and left == 0, pre("a") .. " #134 put back: the two staged symbols taken out of the store", n .. " taken out, " .. left .. " left", "2 taken out, 0 left")
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
        skip("[b] #159 the UI scale change, the way back and the second pass (every check above at another scale)",
            "no second UI scale fits this screen (root " .. string.format("%.2f", SC.root()) .. ", cap " .. tostring(SC.fitCap and SC.fitCap()) .. ")")
    end
end)
whenStill(true, "b", "on Loot before the scale change")
gstep(true, 1, function()
    local c, w = CW(), WW()
    -- (the windows themselves too: the Scale hook's reopen makes new ones)
    L.GA = { c = geo(c), w = geo(w), s = ZeD.T.scale, root = SC.root(), cObj = c, wObj = w, cInv = c and c._baseInvW, wInv = w and w._baseInvW }
    L.scaleChanged = true
    say("scale " .. string.format("%.2f", L.GA.root) .. " -> " .. tostring(L.B) .. " through ZeD's Scale hook (the windows shut, re-theme and open again)")
    SC.override = L.B
    SC.refresh()
end)
gwait(true, 600, function()
    return math.abs((SC._appliedRoot or 0) - L.B) < 0.001 and SC._reopenAt == nil and CWm.isOpen() and WWm.isOpen()
end, "the Scale hook to reopen the windows", function(ok)
    local c, w = CW(), WW()
    local fresh = c ~= nil and w ~= nil and c ~= L.GA.cObj and w ~= L.GA.wObj
    check(ok and fresh, string.format("[b %.2fx]", L.B) .. " #159 the UI scale change shuts, re-themes and reopens both windows (new windows, the new scale applied)",
        (ok and "applied" or "not applied") .. ", " .. (fresh and "new windows" or "not new windows"), "applied, new windows")
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
    L.GB = { cObj = CW(), wObj = WW() }
    SC.override = L.override
    SC.refresh()
end)
gwait(true, 600, function()
    return math.abs((SC._appliedRoot or 0) - L.GA.root) < 0.001 and SC._reopenAt == nil and CWm.isOpen() and WWm.isOpen()
end, "the windows back at the first scale", function(ok)
    local c, w = CW(), WW()
    local fresh = c ~= nil and w ~= nil and c ~= L.GB.cObj and w ~= L.GB.wObj
    check(ok and fresh, pre("a") .. " #159 the UI scale back: both windows shut, re-theme and reopen (new windows, the first scale applied)",
        (ok and "applied" or "not applied") .. ", " .. (fresh and "new windows" or "not new windows"), "applied, new windows")
    L.scaleChanged = false
end)
whenStill(true, "a", "back at the first scale")
gstep(true, 1, function()
    local c, w = CW(), WW()
    local cg, wg = geo(c), geo(w)
    check(sameGeo(cg, L.GA.c, 2), pre("a") .. " #159 back at the first scale, the Character window is where and as big as it was", gs(cg), gs(L.GA.c))
    check(sameGeo(wg, L.GA.w, 2), pre("a") .. " #159 back at the first scale, the World window is where and as big as it was", gs(wg), gs(L.GA.w))
    -- (#150: the narrower inventory a window opens at where the usual one would shift is kept in its saved layout; at
    -- 1080p the bigger step opens it narrower, and only this round trip shows whether it widens again)
    local ci, wi = c and c._baseInvW, w and w._baseInvW
    check(type(ci) == "number" and type(wi) == "number" and type(L.GA.cInv) == "number" and type(L.GA.wInv) == "number"
          and math.abs(ci - L.GA.cInv) < 0.5 and math.abs(wi - L.GA.wInv) < 0.5,
        pre("a") .. " #159 back at the first scale, each window's inventory is as wide as it was in design units (#150's narrower one for the bigger scale widened again)",
        tostring(ci) .. "/" .. tostring(wi), tostring(L.GA.cInv) .. "/" .. tostring(L.GA.wInv))
    shot("a_windows_back")
end)

-- ---------------------------------------------------------------------------------------------------------------
-- THE END, where an error goes too: everything put back, each window back in its place and tab, then checked; each
-- window open or shut, and the game speed, as the run found them
-- ---------------------------------------------------------------------------------------------------------------
EPI.at = #Q + 1
step(1, function() restoreAll(L.why or "the end") end)
-- (a run stopped in pass b: the Scale hook shuts and reopens the windows at the first scale; it is waited out)
waitUntil(600, function()
    return SC._reopenAt == nil and (SC._appliedRoot == nil or math.abs(SC._appliedRoot - SC.root()) < 0.001)
end, "the UI scale to settle", function(ok)
    if not ok then check(false, "put back: the UI scale settles (the Scale hook done)", "still applying", "settled within 600 ticks") end
end)
step(1, function() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end end)
waitUntil(150, function() return CWm.isOpen() and WWm.isOpen() end, "the pair to open for the put-back", function(ok)
    if not ok then check(false, "put back: the pair opens for the put-back", "shut", "open within 150 ticks") end
end)
whenStill(false, "a", "before the put-back", "put back: the windows settle")
-- (the folds again here: an error in pass b, or while the pair was shut, leaves a new window on its own defaults)
step(1, function() pcall(applyFolds); placeBack() end)
whenStill(false, "a", "after the put-back", "put back: the windows settle")
step(1, finalChecks)
step(1, function()
    if L.charWasOpen == false and CWm.isOpen() then CWm.toggle(0) end
    if L.worldWasOpen == false and WWm.isOpen() then WWm.close(0) end
end)
step(2, function()
    if L.charWasOpen ~= nil then
        local co, wo = CWm.isOpen() and true or false, WWm.isOpen() and true or false
        check(co == L.charWasOpen and wo == L.worldWasOpen, "put back: each window open or shut as the run found it",
            tostring(co) .. "/" .. tostring(wo), tostring(L.charWasOpen) .. "/" .. tostring(L.worldWasOpen))
    end
    if L.sbSeen then
        note("#148 scrollbar states seen: " .. ((L.sbSeen.aon or L.sbSeen.bon) and "on " or "") .. ((L.sbSeen.aoff or L.sbSeen.boff) and "off" or ""))
    end
    -- (last: a game paused again runs no more ticks)
    local changed = L.speedChanged
    speedBack()
    if changed then check(getGameSpeed() == L.speed0, "put back: the game speed (the run unpaused a paused game)", getGameSpeed(), L.speed0) end
    say("RESULT " .. R.pass .. " pass, " .. R.fail .. " fail")
    say("DONE")
    ZEDQA_COV_B9TO11 = nil
end)

Events.OnTick.Add(drive)
say("start")
