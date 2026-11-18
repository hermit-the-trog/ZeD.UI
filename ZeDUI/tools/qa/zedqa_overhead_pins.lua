-- ZeDUI/tools/qa/zedqa_overhead_pins.lua  (Nov 17 2026, QA): Design's foraging pins and the search-mode eye
-- (HANDOFF_design_overhead_icons_pins_20261117.md, sets A and B; Build: Overrides/ForagePins.lua and the eye note in
-- ZeD_Bubbles.lua) in the running game. In Dark, Light and High contrast (ZeD.applyTheme, accent and size kept):
--   pins   search mode on (ISSearchManager.getManager(player):toggleSearchMode(true)); finds staged round the
--          character through the game's own constructors: a mushroom, berries and an insect (ISForageIcon, types
--          picked from forageSystem.itemDefs by category), an unidentified find (its checkIsIdentified held false), a
--          known poisonous mushroom (a poisoned item in its list; the game's isKnownPoison is asked first, and only if
--          it says no is the mark set by hand, which is said), a world item (a pencil dropped before search mode, so
--          the game makes its ISWorldItemIcon itself; built the same way if it does not). No stash pin (Build's
--          ruling, Nov 17). Each is spotted through the game's spotIcon (its xpIcons entry set first, so no XP).
--          FAIL only when the find spills past the lens (over 32 units), sits off the lens center, or the pin is
--          not the game's pin size (Design's first layer against the game's in safe mode). A find drawn smaller
--          than the game's is Design's call: both sizes are logged as SIZE lines.
--          The draw is read by wrapping ISBaseIcon.renderPinIcon (whatever is installed: ZeD's, or the game's in
--          safe mode) and the pin's own drawTextureScaled for that call: every layer's texture, rect and alpha.
--          Design's: pinB_back, the find centered on the lens at (29, 26) at most 32 units, pinB_glass, the poison
--          mark 12 units at (42, 36); pinB_unknown alone for the "?". The game's: pinIconBlank + the
--          find (+ SkullPoison), pinIconUnknown.
--   bounce and fade   the mushroom pin un-seen so the game spots it again (its own resetBounce), its y and alpha
--          logged every frame for about 2 s; the character steps 3 tiles away and back (alpha follows distance).
--   eye    the game's renderEye must draw nothing (the manager's drawTextureScaled is read); the eye is a note in
--          ZeD's over-head stack (ZeD.Bubbles._noteOut), at the game's alpha (held at 1, then 0.33, the game's
--          "something in view"), just above the speed bubble at game speed 2, with a halo note raised
--          (ZeD.Bubbles.note); every note's rect in units and on screen, and no two overlap.
--   safe mode   ZeD.Settings.safeModeOption On: the game's pins (pinIconBlank / pinIconUnknown / SkullPoison) and
--          the game's eye (eyeconOn) come back, ZeD's layer is hidden; bounce and fade logged for comparison; then
--          put back as found.
-- Pictures: Screenshots/ohp_<theme>_<what>.png. Crops: every "CROP <picture> x= y= w= h=" line is a screen rect to
-- cut from that picture. Puts back: finds and the pencil removed, search mode as found (off), speed 1, safe mode and
-- theme as found, the character home. grep "ZEDQA ohp".
local S = { p = getPlayer(), fails = 0, Q = {}, themes = { "dark", "light", "hicon" }, mine = {}, list = {}, byKind = {},
    seq = {}, items = {}, eyeDraws = {}, halo = "QA halo note" }
S.pn = S.p:getPlayerNum()
local function say(s) print("ZEDQA ohp " .. tostring(s)) end
local function check(ok, what) if ok then say("PASS " .. what) else S.fails = S.fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("ohp_" .. n .. ".png") end); say("picture ohp_" .. n .. ".png") end
local function step(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end

function S.i(v) return math.floor((tonumber(v) or 0) + 0.5) end
function S.f(v) return string.format("%.2f", tonumber(v) or -1) end
function S.speed(n) if ZEDQA_SPEED then ZEDQA_SPEED(n) else setGameSpeed(n) end end
function S.tname(t)
    if not t then return "nil" end
    local ok, n = pcall(function() return t:getName() end)
    if ok and n then return tostring(n) end
    return tostring(t)
end
function S.short(n) return (tostring(n):gsub("^.*/", ""):gsub("%.png$", "")) end
function S.kind(n)
    n = tostring(n)
    if string.find(n, "ZeD/forage", 1, true) then return "zed" end
    if string.find(n, "Foraging/pin", 1, true) or string.find(n, "SkullPoison", 1, true) or string.find(n, "eyecon", 1, true) then return "game" end
    return "item"
end
function S.home() pcall(function() S.p:setX(S.hx); S.p:setY(S.hy); S.p:setLastX(S.hx); S.p:setLastY(S.hy) end) end

-- ===================================================================== the readers
-- a pin's layers: the pin's own drawTextureScaled, for one renderPinIcon call
S.recDraw = function(me, tex, x, y, w, h, a, r, g, b)
    local m = S.mine[me]
    if m and m.cur then
        m.cur[#m.cur + 1] = { name = S.tname(tex), x = x, y = y, w = w, h = h, a = a }
        if math.abs((a or 0) - me:getAlpha()) > 0.001 then m.badA = (m.badA or 0) + 1 end
    end
    return ISUIElement.drawTextureScaled(me, tex, x, y, w, h, a, r, g, b)
end
S.pinWas = ISBaseIcon.renderPinIcon
ISBaseIcon.renderPinIcon = function(self)
    local m = S.mine[self]
    if not (m and S.rec) then return S.pinWas(self) end
    m.cur = {}
    self.drawTextureScaled = S.recDraw
    local ok, e = pcall(S.pinWas, self)
    self.drawTextureScaled = nil
    m.last, m.cur = m.cur, nil
    if not ok then say("ERR pin render " .. m.kind .. ": " .. tostring(e)) end
end
-- the game's eye: the manager's own drawTextureScaled (renderEye draws through it)
S.mgrDraw = function(me, tex, x, y, w, h, a, r, g, b)
    if #S.eyeDraws < 400 then
        S.eyeDraws[#S.eyeDraws + 1] = { name = S.tname(tex), x = me:getAbsoluteX() + x, y = me:getAbsoluteY() + y, w = w, h = h, a = a }
    end
    return ISUIElement.drawTextureScaled(me, tex, x, y, w, h, a, r, g, b)
end
-- every frame, before the steps: the eye's alpha held, the bounce and fade trace
function S.everyFrame()
    if S.eyeHold and S.mgr then S.mgr:setAlpha(S.eyeHold) end
    local t = S.tr
    if t and t.icon then
        t.list[#t.list + 1] = { y = t.icon:getY(), a = t.icon:getAlpha(), seen = t.icon:getIsSeen() }
    end
end

-- what each pin should draw: id (identified), q (the "?"), poison
S.want = { mushroom = "id", berries = "id", insect = "id", world = "id", unknown = "q", poison = "poison" }
S.pinRect = {}
function S.expect(label, mode, kind, d, o)
    local w = S.want[kind]
    local tag = label .. " " .. kind
    local has, zedN, gameN = {}, 0, 0
    for j = 1, #d do
        local k = S.kind(d[j].name)
        has[S.short(d[j].name)] = d[j]
        if k == "zed" then zedN = zedN + 1 elseif k == "game" then gameN = gameN + 1 end
    end
    local first = S.short(d[1].name)
    S.pinRect[label .. "_" .. kind] = { x = d[1].x, y = d[1].y, w = d[1].w, h = d[1].h }
    if mode == "zed" and S.want[kind] ~= "q" then
        local g = nil
        for j = 2, #d do if S.short(d[j].name) == "pinB_glass" then g = d[j] end end
        check(g ~= nil and math.abs(g.w - d[1].w) <= 0.5 and math.abs(g.h - d[1].h) <= 0.5 and math.abs(g.x - d[1].x) <= 0.5 and math.abs(g.y - d[1].y) <= 0.5,
            tag .. ": the glass covers the pin exactly (the lens rim is redrawn over the find)")
    end
    local s = o.width / 60
    if mode == "zed" then
        check(gameN == 0 and zedN > 0, tag .. ": Design's pin, none of the game's pin textures (" .. zedN .. " Design, " .. gameN .. " game)")
        if w == "q" then
            check(#d == 1 and first == "pinB_unknown", tag .. ": the frosted lens with the ? alone (pinB_unknown)")
            return
        end
        check(first == "pinB_back" and has.pinB_glass ~= nil and #d >= 3, tag .. ": pinB_back, the find, then pinB_glass over it")
        local it = d[2]
        if it and S.kind(it.name) == "item" then
            S.items[label .. "_" .. kind] = it
            local cx, cy = it.x + it.w / 2, it.y + it.h / 2
            check(math.max(it.w, it.h) <= 32 * s + 0.5 and math.abs(cx - 29 * s) <= 1 and math.abs(cy - 26 * s) <= 1,
                string.format("%s: the find (%s) on the lens: center %.1f,%.1f (want %.1f,%.1f), %.1f x %.1f (at most %.1f)",
                    tag, S.short(it.name), cx, cy, 29 * s, 26 * s, it.w, it.h, 32 * s))
        else
            check(false, tag .. ": the second layer is the find (" .. (it and S.short(it.name) or "none") .. ")")
        end
        if w == "poison" then
            local m = has.poison_mark
            check(m ~= nil and math.abs(m.w - 12 * s) <= 0.5 and math.abs(m.x - 42 * s) <= 0.5 and math.abs(m.y - 36 * s) <= 0.5,
                tag .. ": the green skull mark, 12 units at (42, 36)" .. (m and string.format(" (%.1f x %.1f at %.1f,%.1f)", m.w, m.h, m.x, m.y) or " (not drawn)"))
        else
            check(has.poison_mark == nil, tag .. ": no poison mark")
        end
    else
        check(zedN == 0 and gameN > 0, tag .. ": the game's pin, none of Design's textures (" .. zedN .. " Design, " .. gameN .. " game)")
        if w == "q" then
            check(first == "pinIconUnknown", tag .. ": the game's ? pin (pinIconUnknown), got " .. first)
            return
        end
        check(first == "pinIconBlank", tag .. ": the game's pin (pinIconBlank) then the find, got " .. first)
        if d[2] then S.items[label .. "_" .. kind] = d[2] end
        if w == "poison" then check(has.SkullPoison ~= nil, tag .. ": the game's poison skull (SkullPoison)")
        else check(has.SkullPoison == nil, tag .. ": no poison skull") end
    end
end
function S.readPins(label, mode, pic)
    S.seq[label] = {}
    for i = 1, #S.list do
        local o = S.list[i]
        local m = S.mine[o]
        local d = m.last
        if not d or #d == 0 then
            check(false, label .. " " .. m.kind .. ": no draw recorded (seen " .. tostring(o:getIsSeen()) .. ", alpha " .. S.f(o:getAlpha()) .. ")")
        else
            local names = {}
            for j = 1, #d do names[#names + 1] = S.short(d[j].name) .. "(" .. S.kind(d[j].name) .. ")" end
            S.seq[label][m.kind] = table.concat(names, " + ")
            say(string.format("%s %s: %s | pin %.1f x %.1f, s=%.3f, alpha %.2f, zoom %.2f", label, m.kind, S.seq[label][m.kind],
                o.width, o.height, o.width / 60, o:getAlpha(), tonumber(o.zoom) or -1))
            say(string.format("CROP ohp_%s x=%d y=%d w=%d h=%d (%s)", pic, S.i(o:getAbsoluteX() - 6), S.i(o:getAbsoluteY() - 6), S.i(o.width + 12), S.i(o.height + 12), m.kind))
            S.expect(label, mode, m.kind, d, o)
            check(not m.badA, label .. " " .. m.kind .. ": every layer drawn at the pin's own alpha (the game's fade)" .. (m.badA and (" (" .. m.badA .. " off)") or ""))
        end
        m.badA, m.last = nil, nil
    end
end
function S.hit(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
function S.readEye(tag, wantSpeed, pic)
    local out = ZeD.Bubbles._noteOut and ZeD.Bubbles._noteOut[S.pn]
    local eye, ei, sp, si, halo
    for i = 1, (out and #out or 0) do
        local n = out[i]
        if n.eye then eye, ei = n, i elseif n.speed then sp, si = n, i elseif n.text == S.halo then halo = n end
    end
    check(eye ~= nil, tag .. ": the eye is a note in ZeD's over-head stack")
    check(#S.eyeDraws == 0, tag .. ": the game's own eye drew nothing (" .. #S.eyeDraws .. " draws by the manager)")
    if eye then
        check(math.abs((eye.a or 0) - S.eyeHold) < 0.01, tag .. ": the eye keeps the game's fade (note " .. S.f(eye.a) .. ", the game's " .. S.f(S.mgr:getAlpha()) .. ")")
    end
    if wantSpeed then
        check(sp ~= nil and ei ~= nil and si ~= nil and ei == si - 1, tag .. ": the eye sits just above the speed bubble (eye #" .. tostring(ei) .. ", speed #" .. tostring(si) .. ")")
    end
    say(tag .. ": the halo note is " .. (halo and "in the stack" or "NOT in the stack"))
    local layer = ZeD.ActionBar and ZeD.ActionBar._layers and ZeD.ActionBar._layers[S.pn]
    local L = layer and layer._lay
    local k = layer and layer._k or 1
    for i = 1, (out and #out or 0) do
        local n = out[i]
        local nm = n.eye and "eye" or (n.speed and ("speed" .. tostring(n.speed)) or ("note '" .. tostring(n.text) .. "'"))
        local line = string.format("%s: #%d %s units x=%d y=%d w=%d h=%d a=%.2f", tag, i, nm, S.i(n.x), S.i(n.y), S.i(n.w), S.i(n.h), tonumber(n.a) or 1)
        if L and L.ox then
            local sx, sy = layer:getAbsoluteX() + L.ox + n.x * k, layer:getAbsoluteY() + L.oy + n.y * k
            line = line .. string.format(" | screen x=%d y=%d w=%d h=%d (k %d)", S.i(sx), S.i(sy), S.i(n.w * k), S.i(n.h * k), S.i(k))
            if n.eye then say(string.format("CROP ohp_%s x=%d y=%d w=%d h=%d (the eye)", pic, S.i(sx - 4 * k), S.i(sy - 4 * k), S.i((n.w + 8) * k), S.i((n.h + 8) * k))) end
        end
        say(line)
    end
    if L and L.ox and out and #out > 0 then
        local x0, y0 = layer:getAbsoluteX(), layer:getAbsoluteY()
        say(string.format("CROP ohp_%s x=%d y=%d w=%d h=%d (the whole over-head stack)", pic, S.i(x0 - 8), S.i(y0 - 8), S.i(layer:getWidth() + 16), S.i(layer:getHeight() + 16)))
    end
    local over = 0
    for i = 1, (out and #out or 0) do
        for j = i + 1, #out do
            if S.hit(out[i], out[j]) then over = over + 1; say(tag .. ": notes #" .. i .. " and #" .. j .. " overlap") end
        end
    end
    check(out ~= nil and over == 0, tag .. ": no two over-head notes overlap (" .. (out and #out or 0) .. " notes)")
    S.eyeDraws = {}
end

-- the bounce and fade trace for one pin (the mushroom): un-seen, spotted again by the game, 3 tiles away and back
function S.traceSteps(label)
    step(5, function()
        local o = S.byKind.mushroom
        if not o then say("not run: " .. label .. " bounce and fade (no mushroom pin)"); return end
        S.tr = { icon = o, list = {} }
        o:setIsSeen(false)   -- (the manager still has it as seen: the next update spots it again, with the game's resetBounce)
    end)
    step(60, function() pcall(function() S.p:setX(S.hx - 3); S.p:setLastX(S.hx - 3) end) end)
    step(60, function() S.home() end)
    step(10, function()
        local t = S.tr
        S.tr = nil
        if not (t and #t.list > 100) then say("not run: " .. label .. " bounce and fade (" .. (t and #t.list or 0) .. " frames)"); return end
        local L = t.list
        local parts = {}
        for i = 1, #L, 5 do parts[#parts + 1] = string.format("%d:y%d/a%.2f", i, S.i(L[i].y), L[i].a) end
        say(label .. " trace (frame:y/alpha): " .. table.concat(parts, " "))
        local ymin, ymax = 99999, -99999
        for i = 2, 45 do ymin = math.min(ymin, L[i].y); ymax = math.max(ymax, L[i].y) end
        local settled = true
        for i = 48, 58 do if math.abs(L[i].y - L[58].y) > 1 then settled = false end end
        check(ymax - ymin >= 5 and settled, string.format("%s: the pin bounces when spotted (%d px over the first 45 frames) and settles", label, S.i(ymax - ymin)))
        local near, far = 0, 0
        for i = 50, 58 do near = near + L[i].a end
        for i = 105, 115 do far = far + L[math.min(i, #L)].a end
        near, far = near / 9, far / 11
        check(far < near - 0.03, string.format("%s: the pin fades with distance (%.2f near, %.2f three tiles further)", label, near, far))
    end)
end

-- ===================================================================== setup
step(30, function()
    if ZEDQA_HOME then ZEDQA_HOME("ohp") end
    S.hx, S.hy, S.hz = S.p:getX(), S.p:getY(), S.p:getZ()
    S.px, S.py, S.pz = math.floor(S.hx), math.floor(S.hy), math.floor(S.hz)
    S.look = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
    S.safeWas = ZeD.Settings.safeModeOption:getValue()
    S.mgr = ISSearchManager.getManager(S.p)
    S.searchWas = S.mgr.isSearchMode == true
    say("start: at " .. S.px .. "," .. S.py .. ", theme " .. tostring(S.look[1]) .. ", safe option " .. tostring(S.safeWas) .. ", search mode " .. tostring(S.searchWas) .. ", speed " .. tostring(getGameSpeed()))
    check(ISBaseIcon._zedOrigRenderPinIcon ~= nil, "ZeD's pin override is loaded (ISBaseIcon._zedOrigRenderPinIcon)")
    check(ISSearchManager._zedOrigRenderEye ~= nil and ZeD.Bubbles and ZeD.Bubbles.drawEye ~= nil, "ZeD's eye is loaded (renderEye replaced, ZeD.Bubbles.drawEye)")
    check(not ZeD.Safe.on(), "safe mode is off at the start")
    -- the item types: the alphabetically first of each category, so every run stages the same finds
    S.types = {}
    local function pick(key, cat, wantPoison, notType)
        for t, d in pairs(forageSystem.itemDefs) do
            local inCat = false
            for _, c in ipairs(d.categories or {}) do if c == cat then inCat = true end end
            local ok = inCat and (not wantPoison or (tonumber(d.poisonChance) or 0) > 0) and t ~= notType
            if ok and pcall(instanceItem, t) and (not S.types[key] or t < S.types[key].type) then S.types[key] = { type = t, cat = cat } end
        end
    end
    pick("mush", "Mushrooms")
    pick("poison", "Mushrooms", true, S.types.mush and S.types.mush.type)
    if not S.types.poison then pick("poison", "Mushrooms", false, S.types.mush and S.types.mush.type) end
    pick("berry", "Berries")
    pick("insect", "Insects")
    for _, k in ipairs({ "mush", "poison", "berry", "insect" }) do say("type " .. k .. ": " .. tostring(S.types[k] and S.types[k].type)) end
    -- the world item, dropped before search mode so the game's own square scan makes its pin
    local ok, e = pcall(function()
        local sq = getCell():getGridSquare(S.px - 2, S.py + 1, S.pz)
        S.wItem = sq:AddWorldInventoryItem("Base.Pencil", 0.5, 0.5, 0)
    end)
    say("world item: a pencil at " .. (S.px - 2) .. "," .. (S.py + 1) .. (ok and S.wItem and " dropped" or (" NOT dropped: " .. tostring(e))))
end)
step(10, function()
    S.mgr:toggleSearchMode(true)
    check(S.mgr.isSearchMode == true, "search mode is on (ISSearchManager.getManager(player):toggleSearchMode(true))")
    S.mgr.drawTextureScaled = S.mgrDraw
end)

-- ===================================================================== the finds
function S.own(o, kind, reg)
    S.mine[o] = { kind = kind, reg = reg }
    S.list[#S.list + 1] = o
    S.byKind[kind] = o
end
function S.mk(kind, ty, dx, dy, ident, poison)
    if not ty then say("not staged: " .. kind .. " (no item type)"); return end
    local sq = getCell():getGridSquare(S.px + dx, S.py + dy, S.pz)
    if not sq then say("not staged: " .. kind .. " (no square)"); return end
    local id = "zedqa_ohp_" .. kind
    local fi = { id = id, zoneid = S.zone.id, x = sq:getX(), y = sq:getY(), z = sq:getZ(), catName = ty.cat, itemType = ty.type,
        isBonusIcon = false, canRollForSearchFocus = false }
    if poison then
        local it = instanceItem(ty.type)
        pcall(function() it:setPoisonPower(10) end)
        pcall(function() it:setPoisonDetectionLevel(10) end)
        fi.itemObj = it
        fi.itemList = ArrayList.new()
        fi.itemList:add(it)
    end
    local o = ISForageIcon:new(S.mgr, fi, S.zone)
    o.isValidSquare = true
    o.identified = ident
    o.checkIsIdentified = function(me) me.identified = ident end
    S.mgr.xpIcons[id] = id
    o:doUpdateEvents(true)
    o:addToUIManager()
    o:spotIcon()
    pcall(function() o:checkForPoison() end)
    say(kind .. ": " .. ty.type .. " at " .. sq:getX() .. "," .. sq:getY() .. ", identified " .. tostring(o.identified) .. ", the game's isKnownPoison " .. tostring(o.isKnownPoison))
    if poison and not o.isKnownPoison then say(kind .. ": the game did not count it as known poison: marked known by hand") end
    o.isKnownPoison = poison and true or false
    o.checkForPoison = function(me) me.isKnownPoison = poison and true or false end
    S.own(o, kind, false)
end
step(60, function()
    local okZ, z = pcall(function() return S.mgr:getAndActivateZoneAtXY(S.hx, S.hy) end)
    S.zone = okZ and z or nil
    if not S.zone then
        local zn
        for n in pairs(forageSystem.zoneDefs) do if not zn or n < zn then zn = n end end
        S.zone = { id = "zedqa_ohp_zone", name = zn, forageIcons = {} }
        say("no forage zone under the character: a stand-in zone named " .. tostring(zn) .. " (not added to the game's zones)")
    else
        say("forage zone: " .. tostring(S.zone.name))
    end
    -- (spread so no two pins share a screen column: (dx - dy) differs)
    S.mk("mushroom", S.types.mush, 2, -2, true, false)
    S.mk("berries", S.types.berry, 2, 0, true, false)
    S.mk("insect", S.types.insect, 0, -2, true, false)
    S.mk("unknown", S.types.mush, -1, 1, false, false)
    S.mk("poison", S.types.poison, 1, 3, true, true)
    -- the world item: the game's own pin, if its scan made one
    if S.wItem then
        for _, ic in pairs(S.mgr.worldObjectIcons or {}) do
            if ic.itemObj == S.wItem then S.wIcon = ic end
        end
        if S.wIcon then
            say("world: the game made the pencil's pin itself (ISWorldItemIcon " .. tostring(S.wIcon.iconID) .. ")")
        else
            local wi = S.wItem:getWorldItem()
            local sq = wi:getSquare()
            local icon = { id = tostring(sq) .. "-" .. S.wItem:getFullType(), x = wi:getWorldPosX(), y = wi:getWorldPosY(), z = wi:getWorldPosZ(),
                itemObj = S.wItem, itemObjTable = {}, itemType = S.wItem:getFullType(), isBonusIcon = false, isTrack = false }
            icon.itemObjTable[S.wItem] = S.wItem
            S.wIcon = ISWorldItemIcon:new(S.mgr, icon)
            S.wIcon.iconClass = "worldObject"
            S.mgr.worldObjectIcons[icon.id] = S.wIcon
            S.wIcon:findTextureCenter()
            S.wIcon:doUpdateEvents(true)
            S.wIcon:addToUIManager()
            say("world: the game's scan had not made the pencil's pin in 60 frames: built as loadIcons builds it")
        end
        S.wIcon:spotIcon()
        S.own(S.wIcon, "world", true)
    end
    -- (no stash pin: dropped from this check, Build's ruling of Nov 17)
end)

-- ===================================================================== each theme
for _, th in ipairs(S.themes) do
    step(10, function()
        pcall(ZeD.applyTheme, th, S.look[2], S.look[3])
        say("theme " .. th .. " (now " .. tostring(ZeD.currentBase) .. ")")
    end)
    step(40, function() S.rec = true end)
    step(6, function() shot(th .. "_pins") end)
    step(4, function() S.rec = false; S.readPins(th, "zed", th .. "_pins") end)
    S.traceSteps(th)
    -- the eye: alone with a halo note, then at speed 2, then at the game's 0.33
    step(5, function() S.eyeHold = 1; S.eyeDraws = {}; ZeD.Bubbles.note(S.pn, S.halo, "good") end)
    step(25, function() shot(th .. "_eye") end)
    step(3, function() S.readEye(th .. " eye", false, th .. "_eye") end)
    step(5, function() S.speed(2); ZeD.Bubbles.note(S.pn, S.halo, "good"); S.eyeDraws = {} end)
    step(25, function() shot(th .. "_eye_speed2") end)
    step(3, function() S.readEye(th .. " eye at speed 2", true, th .. "_eye_speed2") end)
    step(5, function() S.eyeHold = 0.33; S.eyeDraws = {} end)
    step(20, function() shot(th .. "_eye_033") end)
    step(3, function() S.readEye(th .. " eye at 0.33 (something in view)", true, th .. "_eye_033") end)
    step(5, function() S.speed(1); S.eyeHold = nil end)
end
step(5, function()
    local base = S.seq[S.themes[1]] or {}
    for i = 2, #S.themes do
        local other = S.seq[S.themes[i]] or {}
        local same = true
        for k, v in pairs(base) do if other[k] ~= v then same = false; say("differs in " .. S.themes[i] .. ": " .. k .. " = " .. tostring(other[k])) end end
        check(same, "the pins draw the same layers in " .. S.themes[1] .. " and " .. S.themes[i])
    end
end)

-- ===================================================================== safe mode: the game's own come back
step(10, function()
    pcall(ZeD.applyTheme, S.look[1], S.look[2], S.look[3])
    ZeD.Settings.safeModeOption:setValue(2)
    pcall(ZeD.Safe.reread)
end)
step(40, function()
    check(ZeD.Safe.on(), "safe mode is on")
    S.rec = true
    S.eyeHold = 1
    S.eyeDraws = {}
end)
step(6, function() shot(tostring(S.look[1]) .. "_safe_pins") end)
step(4, function()
    S.rec = false
    S.readPins("safe", "game", tostring(S.look[1]) .. "_safe_pins")
    local eyeN, last = 0, nil
    for i = 1, #S.eyeDraws do if string.find(S.eyeDraws[i].name, "eyeconOn", 1, true) then eyeN = eyeN + 1; last = S.eyeDraws[i] end end
    check(eyeN > 0, "safe: the game's own eye (eyeconOn) is drawn again (" .. eyeN .. " draws)")
    if last then say(string.format("safe eye: %s at x=%d y=%d %dx%d alpha %.2f", S.short(last.name), S.i(last.x), S.i(last.y), S.i(last.w), S.i(last.h), tonumber(last.a) or -1))
        say(string.format("CROP ohp_%s_safe_pins x=%d y=%d w=%d h=%d (the game's eye)", tostring(S.look[1]), S.i(last.x - 8), S.i(last.y - 8), S.i(last.w + 16), S.i(last.h + 16))) end
    local layer = ZeD.ActionBar and ZeD.ActionBar._layers and ZeD.ActionBar._layers[S.pn]
    check(layer == nil or not layer:isVisible(), "safe: ZeD's over-head layer is hidden, so its eye note is not drawn")
    local mz, mg = S.items["dark_mushroom"] or S.items[S.themes[1] .. "_mushroom"], S.items["safe_mushroom"]
    -- (Build's ruling, Nov 17: a find drawn smaller than the game's is Design's call, not a fail; both sizes logged)
    for _, kind in ipairs({ "mushroom", "berries", "insect", "world", "poison" }) do
        local z, g = S.items[S.themes[1] .. "_" .. kind], S.items["safe_" .. kind]
        if z and g then say(string.format("SIZE the find (%s): Design's lens %.1f x %.1f, the game's pin %.1f x %.1f", kind, z.w, z.h, g.w, g.h)) end
    end
    -- the pin itself must be the game's size: Design's first layer against the game's, kind by kind
    for _, kind in ipairs({ "mushroom", "berries", "insect", "world", "unknown", "poison" }) do
        local z, g = S.pinRect[S.themes[1] .. "_" .. kind], S.pinRect["safe_" .. kind]
        if z and g then
            check(math.abs(z.w - g.w) <= 0.5 and math.abs(z.h - g.h) <= 0.5 and math.abs(z.x - g.x) <= 0.5 and math.abs(z.y - g.y) <= 0.5,
                string.format("%s: Design's pin is the game's pin size (Design %.1f x %.1f, the game %.1f x %.1f)", kind, z.w, z.h, g.w, g.h))
        end
    end
    S.eyeHold = nil
end)
S.traceSteps("safe")
step(10, function()
    ZeD.Settings.safeModeOption:setValue(S.safeWas or 1)
    pcall(ZeD.Safe.reread)
end)
step(40, function()
    check(ZeD.Safe.on() == (S.safeWas == 2), "safe mode put back as found (option " .. tostring(ZeD.Settings.safeModeOption:getValue()) .. ")")
    S.rec = true
end)
step(4, function()
    S.rec = false
    local back = 0
    for i = 1, #S.list do
        local m = S.mine[S.list[i]]
        if m.last and m.last[1] and S.kind(m.last[1].name) == "zed" then back = back + 1 end
        m.last = nil
    end
    check(back == #S.list, "out of safe mode, Design's pins are back (" .. back .. " of " .. #S.list .. ")")
end)

-- ===================================================================== put back
step(10, function()
    S.eyeHold, S.tr, S.rec = nil, nil, false
    ISBaseIcon.renderPinIcon = S.pinWas
    if S.mgr then S.mgr.drawTextureScaled = nil end
    for i = 1, #S.list do
        local o = S.list[i]
        local m = S.mine[o]
        pcall(function()
            if m.reg then S.mgr:removeIcon(o) else o:reset(); o:removeFromUIManager() end
            S.mgr.seenIcons[o.iconID] = nil
            S.mgr.xpIcons[o.iconID] = nil
            if S.mgr.isoMarkers then S.mgr.isoMarkers[o.iconID] = nil end
            if S.mgr.worldMarkers then S.mgr.worldMarkers[o.iconID] = nil end
        end)
    end
    if S.stashKey then pcall(function() S.mgr.stashIcons[S.stashKey] = nil end) end
    if S.wItem then
        pcall(function()
            local wi = S.wItem:getWorldItem()
            if wi then
                local sq = wi:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wi) end
                wi:removeFromWorld()
                wi:removeFromSquare()
            end
        end)
    end
    S.speed(1)
    pcall(ZeD.applyTheme, S.look[1], S.look[2], S.look[3])
    if not S.searchWas then
        pcall(function() S.mgr:toggleSearchMode(false) end)
        pcall(function() local eng = getSearchMode(); eng:setOverride(S.pn, false); eng:setEnabled(S.pn, false) end)
    end
    S.home()
end)
step(20, function()
    local leftW = false
    pcall(function() leftW = S.wItem ~= nil and S.wItem:getWorldItem() ~= nil end)
    check(not leftW, "put back: the pencil is gone from the floor")
    check((S.mgr.isSearchMode == true) == S.searchWas, "put back: search mode " .. tostring(S.mgr.isSearchMode))
    check(getGameSpeed() == 1, "put back: speed " .. tostring(getGameSpeed()))
    check(ZeD.Settings.safeModeOption:getValue() == (S.safeWas or 1), "put back: safe mode option " .. tostring(ZeD.Settings.safeModeOption:getValue()))
    say("put back: theme " .. tostring(ZeD.currentBase))
    say(S.fails == 0 and "all checks passed" or (S.fails .. " failed"))
    say("DONE")
end)

S.qi, S.wait = 1, nil
function S.tick()
    pcall(S.everyFrame)
    local s = S.Q[S.qi]
    if not s then Events.OnPreUIDraw.Remove(S.tick); return end
    S.wait = (S.wait or s.n) - 1
    if S.wait > 0 then return end
    S.wait = nil
    S.qi = S.qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (S.qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(S.tick)
say("start")
