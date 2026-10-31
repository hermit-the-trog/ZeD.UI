-- ZeDUI/tools/qa/zedqa_hairbeard.lua  (Oct 26 2026; Hidden actions Oct 29 2026)
-- Hair and beard in the Identity tab (ZeD_HairBeard.lua, mockup zed_hair_beard_v1),
-- on the ZeD-QA save. Runs with no hair mod (zedqa_run.ps1) and with them on
-- (zedqa_mods_run.ps1 with hairbeard_mods_*.txt): the mod checks run only when that mod is on.
-- ZeD setup's Hidden actions (Folded by default, Show all, Hide; ZeD.Settings.hiddenActionsOption):
-- a cut, style, shave or trim the character lacks the tool for, and a style the hair is too short
-- for, are not greyed rows at Folded: they sit under one hint row (hb:more:<part>) that opens. The
-- script starts at Folded, sets Show all (2) only for the checks that need the greyed rows in the
-- list, and puts the player's pick (and each hint row's open / shut state) back at the end.
--   1. long hair and a full beard, no tools: rows from the game's own menu, greyed with its reasons
--      (the rows' data). Folded: only the rows that can be done show, the hint row is there, no
--      greyed row, no click zone or controller stop for the cut. Hide: no hint row. Show all: every
--      row shows greyed (Out of reach too), no hint row. The figures lists run at Show all
--   2. the mouse. Folded: a click on the hint row opens it (the greyed rows come), a second shuts it.
--      Show all: pick a greyed row (the strip says why), hover (the game's hint), the button greyed
--   3. scissors and a cap: the strip names the cap and the tool; Cut runs the game's action;
--      the license follows (Folded)
--   4. tie and untie by controller (A on the row), the rows follow
--   5. controller, no tools in the beard list. Folded: down from the Hair | Beard switch lands on
--      the hint row, A opens it, down walks the greyed rows (the strip follows focus), A on a greyed
--      row does nothing, A on the hint row shuts it. Show all: down lands on the first greyed row at
--      once, same checks. Then scissors: A trims
--   6. the hint row holds Out of reach (it is a stop, A opens it, an out-of-reach row can be focused);
--      the Identity traits' descriptions on focus and hover
--   7. Large text, Light; the hair mods (Spongie's tag; the picture mods' styles as rows) when on
--   A. the figures (Oct 26 2026, "use game avatars for each style"): every row in view (also
--      one the view's edge cuts), and Now / After, show the game's 3D figure (no drawn heads
--      left); the figures are a stand-in, the real character never changes; frame time with
--      the list open; the figures leave the window when the tab changes and when the window closes
--   B. (Oct 26 2026, second pass) the beard list keeps the character's own hair on every figure
--      and each row's figure wears that row's beard; Now shows in both lists, also with its
--      frame half scrolled out of the view, and After shows the picked row's result; a woman's
--      hair list (the QA character made a woman for a few seconds, then put back)
-- Captures: Zomboid/Screenshots/zqa_hb_<name>.png (each with "rect" lines for crops). grep "ZEDQA hb".
local TAG = "hb"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local HB = ZeD.HairBeard
if not HB then say("ERR ZeD.HairBeard is not loaded"); return end
local DS = ZeD.Disclose
if not DS then say("ERR ZeD.Disclose is not loaded"); return end
local CW = ZeD_CharacterWindow
local F = ZeD.Input and ZeD.Input.Focus
local core = getCore()
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(name)
    local f = "zqa_hb_" .. name .. ".png"
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then say("shot " .. f) else fails = fails + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
local function win() return CW.getWindow() end
local function st() local w = win(); return w and w._hb end
local function park() pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end) end
local function mods()
    local m = {}
    local list = getActivatedMods()
    for i = 0, list:size() - 1 do m[(tostring(list:get(i)):gsub("^\\", ""))] = true end
    return m
end
local MODS = mods()
local hv = p:getHumanVisual()
local female = p:isFemale()
local A_before
local orig = { hair = hv:getHairModel(), beard = hv:getBeardModel(), na = hv:getNonAttachedHair() }
local LONG = female and "Long2" or "Fabian"
-- the character's own hair (the beard part runs with it, not with the long test hair)
local REAL = (orig.hair and orig.hair ~= "" and orig.hair ~= LONG) and orig.hair or (female and "Bob" or "Short")
local size, base, accent = ZeD.currentSize, ZeD.currentBase, ZeD.currentAccent
local given, taken = {}, {}
local function give(ft) local it = p:getInventory():AddItem(ft); if it then given[#given + 1] = it end; return it end
local function refresh() local s = st(); if s then s.tick = 999 end end
local function setLook(hair, beard)
    hv:setNonAttachedHair(nil)
    hv:setHairModel(hair)
    if not female and beard then hv:setBeardModel(beard) end
    p:resetModel()
    refresh()
    local w = win(); if w then w._identityCache = nil end
end
local function rows() local s = st(); return s and s.rows or {} end
local function rowWhere(fn) for _, r in ipairs(rows()) do if fn(r) then return r end end; return nil end
local function zoneOf(key) local s = st(); for _, z in ipairs(s and s.zones or {}) do if z.item.row and z.item.row.key == key then return z end end; return nil end
local function els() local w = win(); return w and ZeD.IdentityTab.focusables(w) or {} end
local function el(id) for _, e in ipairs(els()) do if e.id == id then return e end end; return nil end
local function focusId(id) local w = win(); return F.focusWhere(w, "charTabContent", function(x) return x.id == id end) end
local function focused() local w = win(); local e = F.getFocusedElement(w); return e and e.id end
local function queueLen() local q = ISTimedActionQueue.getTimedActionQueue(p); return q and q.queue and #q.queue or 0 end

-- Hidden actions: ZeD setup's pick (1 Folded, 2 Show all, 3 Hide) is the player's, so it is read here
-- before anything moves and put back at the end; so is whether each hint row was open. The layout
-- follows the pick within a few frames (HB.key carries it), so a step that changes it waits on lay().
local HO = ZeD.Settings and ZeD.Settings.hiddenActionsOption
local SET0 = HO and HO:getValue() or nil
local OPEN0 = { hair = DS.isOpen("hb:more:hair"), beard = DS.isOpen("hb:more:beard") }
local function setHidden(i)
    if HO then HO:setValue(i) end
    refresh()
end
-- the list as laid out now: the hint row (an item of kind "more"), the rows and how many are greyed
local function lay()
    local o = { rows = 0, canDo = 0, greyed = 0, keys = {} }
    local s = st()
    for _, it in ipairs(s and s.L and s.L.items or {}) do
        if it.kind == "more" then
            o.more = it
        elseif it.kind == "row" then
            o.rows = o.rows + 1
            o.keys[it.row.key] = true
            if it.row.ok then o.canDo = o.canDo + 1 else o.greyed = o.greyed + 1 end
        end
    end
    return o
end
local function okRows() local n = 0; for _, r in ipairs(rows()) do if r.ok then n = n + 1 end end; return n end
local function moreZone() local s = st(); for _, z in ipairs(s and s.zones or {}) do if z.item.kind == "more" then return z end end; return nil end
-- the controller's marks put away for a mouse check (they hide the mouse's hover and cards while they show)
local cuesOrig
local function cuesAway(on)
    if on and not cuesOrig and F and F.cuesVisible then
        cuesOrig = F.cuesVisible
        F.cuesVisible = function() return false end
    elseif not on and cuesOrig then
        F.cuesVisible = cuesOrig
        cuesOrig = nil
    end
end
-- a trait's card: the mouse's goes through ZeD.Atoms.requestDetailCard (drawn after the shared pause), the
-- controller's focus draws ZeD.Molecules.drawDetailCard at once; both are listened to while this is on
local cardSeen, cardOrig = { req = {}, drawn = {} }, nil
local function cardListen(on)
    local A, M = ZeD.Atoms, ZeD.Molecules
    if on and not cardOrig then
        cardOrig = { req = A.requestDetailCard, draw = M.drawDetailCard }
        A.requestDetailCard = function(owner, key, card, panel)
            if type(key) == "string" and key:sub(1, 15) == "identity:trait:" then
                cardSeen.req[key] = { title = card and card.title, lines = card and card.lines }
            end
            return cardOrig.req(owner, key, card, panel)
        end
        M.drawDetailCard = function(panel, ax, ay, card)
            if card and card.title then cardSeen.drawn[card.title] = true end
            return cardOrig.draw(panel, ax, ay, card)
        end
    elseif not on and cardOrig then
        A.requestDetailCard, M.drawDetailCard = cardOrig.req, cardOrig.draw
        cardOrig = nil
    end
end
-- the tab's scroll so the section shows (its top at the view's top)
local function scrollToHair()
    local w, s = win(), st()
    local sc = w and w._identityScroll
    if not (sc and sc.visible and s and s.top) then return end
    local view = w._identityGridScrollZone
    if not view then return end
    local total = view.h / math.max(0.01, sc.barSizeRatio)
    local maxOff = math.max(1, total - view.h)
    local off = math.floor(sc.scrollPos * maxOff)
    local want = off + (s.top - view.y)
    sc:setScrollPos(math.max(0, math.min(1, want / maxOff)))
end
-- the tab's scroll so the list fills the view (the first row at the view's top)
local function scrollToRows()
    local w, s = win(), st()
    local sc = w and w._identityScroll
    if not (sc and sc.visible and s and s.top and s.L) then return end
    local view = w._identityGridScrollZone
    if not view then return end
    local first
    for _, it in ipairs(s.L.items) do if not first and (it.kind == "gh" or it.kind == "row") then first = it end end
    if not first then return end
    local total = view.h / math.max(0.01, sc.barSizeRatio)
    local maxOff = math.max(1, total - view.h)
    local off = math.floor(sc.scrollPos * maxOff)
    local want = off + (s.top + first.y - view.y)
    sc:setScrollPos(math.max(0, math.min(1, want / maxOff)))
end
-- scroll the tab so a point of the section (dy below the heads' top) sits at the view's top
local function scrollToHeads(dy)
    local w, s = win(), st()
    local sc = w and w._identityScroll
    if not (sc and sc.visible and s and s.top and s.L) then return end
    local view = w._identityGridScrollZone
    if not view then return end
    local hy
    for _, it in ipairs(s.L.items) do if it.kind == "heads" then hy = it.y end end
    if not hy then return end
    local total = view.h / math.max(0.01, sc.barSizeRatio)
    local maxOff = math.max(1, total - view.h)
    local off = math.floor(sc.scrollPos * maxOff)
    local want = off + (s.top + hy + dy - view.y)
    sc:setScrollPos(math.max(0, math.min(1, want / maxOff)))
end
-- scroll the tab so a row (its stop) shows in the middle of the view
local function showEl(id)
    local w = win()
    local sc, view = w._identityScroll, w._identityGridScrollZone
    local e = el(id)
    if not (sc and view and e and sc.visible) then return end
    local total = view.h / math.max(0.01, sc.barSizeRatio)
    local maxOff = math.max(1, total - view.h)
    local off = sc.scrollPos * maxOff
    local want = off + (e.y - view.y) - view.h / 3
    sc:setScrollPos(math.max(0, math.min(1, want / maxOff)))
end
local function showRow(key) showEl("hb:row:" .. key) end
-- the pointer over the drawer: the drawer's own getMouseX/Y answer a test position (Mouse.setXY
-- moved the OS cursor but the game did not see it in the 4K runs); nil puts the real one back
local function pointAt(x, y)
    local dp = win()._drawerPanel
    if x then dp.getMouseX = function() return x end; dp.getMouseY = function() return y end
    else dp.getMouseX = nil; dp.getMouseY = nil end
end
local function absOf(z) local dp = win()._drawerPanel; return dp:getAbsoluteX() + z.x, dp:getAbsoluteY() + z.y end
local function hairWord(n) local k = "IGUI_Hair_" .. tostring(n); local s = getText(k); return s == k and tostring(n) or s end

-- the windows still (place, size, drawer width) for 30 checks in a row
local function shape()
    local t = {}
    for _, w in ipairs({ CW.getWindow(), ZeD_WorldWindow.getWindow() }) do
        if w and w:isVisible() then
            local dp = w._drawerPanel
            t[#t + 1] = string.format("%d,%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(),
                math.floor(w._drawerEffW or 0), dp and dp:getWidth() or 0)
        end
    end
    return table.concat(t, ";")
end
local stillLast, stillN = nil, 0
local function still()
    local sh = shape()
    if sh == stillLast then stillN = stillN + 1 else stillLast, stillN = sh, 0 end
    if stillN >= 30 then stillLast, stillN = nil, 0; return true end
    return false
end

-- the real character's look, to show the figures never change it
local function lookNow()
    local t = { tostring(hv:getHairModel()), tostring(hv:getBeardModel()), tostring(hv:getNonAttachedHair()) }
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do local it = wi:getItemByIndex(i); t[#t + 1] = tostring(it and it:getID()) end
    return table.concat(t, "|")
end

-- rows wholly inside the section's view, and the figures showing (by row key / "now" / "after")
local function rowsInView()
    local s, out = st(), {}
    if not (s and s.L and s.top and s.av and s.av.clip) then return out end
    local c = s.av.clip
    for _, it in ipairs(s.L.items) do
        if it.kind == "row" then
            local y = s.top + it.y
            if y >= c.y and y + it.h <= c.y + c.h then out[#out + 1] = it.row end
        end
    end
    return out
end
local function figIds()
    local ids, n = {}, 0
    for _, f in ipairs(HB.figures(win())) do ids[f.id] = f; n = n + 1 end
    return ids, n
end
local HEAD_H = 76   -- the heads' frame (design units, ZeD_HairBeard.lua)
-- the Now / After frames in the view (any of them past a sliver), and whole?
local function headsInView()
    local s = st()
    if not (s and s.L and s.top and s.av and s.av.clip) then return false, false end
    local c = s.av.clip
    local fh = ZeD.T.px(HEAD_H)
    for _, it in ipairs(s.L.items) do
        if it.kind == "heads" then
            local y = s.top + it.y
            local shown = math.min(y + fh, c.y + c.h) - math.max(y, c.y)
            return shown >= 12, (y >= c.y and y + fh <= c.y + c.h)
        end
    end
    return false, false
end
-- rows the view's edge cuts (12 px or more showing): they show the part of their figure inside
local function rowsCut()
    local s, out = st(), {}
    if not (s and s.L and s.top and s.av and s.av.clip) then return out end
    local c = s.av.clip
    for _, it in ipairs(s.L.items) do
        if it.kind == "row" then
            local y = s.top + it.y
            local whole = y >= c.y and y + it.h <= c.y + c.h
            local shown = math.min(y + it.h, c.y + c.h) - math.max(y, c.y)
            if not whole and shown >= it.h * 0.6 then out[#out + 1] = it.row end
        end
    end
    return out
end
-- every row in view has its figure (and Now, and After when a row that can be done is
-- picked, when the heads show whole)
local function figuresAll(what)
    local rs = rowsInView()
    local ids, n = figIds()
    local missing = 0
    for _, r in ipairs(rs) do if not ids[r.key] then missing = missing + 1 end end
    for _, r in ipairs(rowsCut()) do if not ids[r.key] then missing = missing + 1 end end
    local s = st()
    local headsOk = true
    if headsInView() then
        headsOk = ids.now ~= nil
        for _, r in ipairs(s.rows or {}) do if r.key == s.sel and not ids.after then headsOk = false end end
    end
    if #rs > 0 and missing == 0 and headsOk then
        say("figures " .. what .. ": " .. #rs .. " rows in view, " .. n .. " figures showing, pool " .. HB.poolSize(win()))
        return true
    end
    return false
end
local function hbChildren()
    local n = 0
    local w = win()
    for _, c in pairs(w and w.children or {}) do if c._hbModel or c._hbLayer then n = n + 1 end end
    return n
end
local function switchTab(id)
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:" .. id and w._activeTab ~= id then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
end
local function otherTab()
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" and z.id ~= "tab:identity" then return z.id:sub(5) end
    end
end
-- the section's view and the heads in screen pixels (for crops)
local function rects(name)
    local w, s = win(), st()
    local dp = w._drawerPanel
    local ax, ay = dp:getAbsoluteX(), dp:getAbsoluteY()
    local c = s.av and s.av.clip
    if c then say(string.format("rect %s list %d %d %d %d", name, ax + c.x, ay + c.y, c.w, c.h)) end
    for _, it in ipairs(s.L and s.L.items or {}) do
        if it.kind == "heads" then say(string.format("rect %s heads %d %d %d %d", name, ax + (s.x or 0) + it.x, ay + s.top + it.y, it.w, it.h)) end
    end
end
-- frame time: mean, 95th and worst ms over n frames (OnRenderTick)
local perf = {}
local function sample(tag, n)
    local last, list = nil, {}
    local function f()
        local now = getTimestampMs()
        if last then list[#list + 1] = now - last end
        last = now
        if #list >= n then
            Events.OnRenderTick.Remove(f)
            local sum, worst = 0, 0
            for _, v in ipairs(list) do sum = sum + v; if v > worst then worst = v end end
            table.sort(list)
            local p95 = list[math.max(1, math.floor(#list * 0.95))]
            perf[tag] = { mean = sum / #list, worst = worst, p95 = p95 }
            say(string.format("perf %s: mean %.1f ms, 95th %d ms, worst %d ms over %d frames", tag, sum / #list, p95, worst, #list))
        end
    end
    Events.OnRenderTick.Add(f)
end

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- a step that waits: fn returns true when done, false to look again in n frames (up to tries)
local function until_(n, tries, fn, what) Q[#Q + 1] = { n = n, fn = fn, tries = tries, what = what } end

-- 1. the look and no tools
step(30, function()
    park()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:identity" and w._activeTab ~= "identity" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    local inv = p:getInventory()
    local function tool(it)
        local t = it:getType()
        return it:hasTag(ItemTag.RAZOR) or it:hasTag(ItemTag.SCISSORS) or it:hasTag(ItemTag.DO_HAIRDO)
            or t == "Razor" or t == "Scissors" or t == "Hairgel" or t == "Hairspray2"
    end
    local list = inv:getAllEvalRecurse(tool)
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        local c = it:getContainer()
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        if c then c:Remove(it); taken[#taken + 1] = { it = it, c = c } end
    end
    say("tools taken away for the test: " .. #taken .. " | female " .. tostring(female) .. " | was " .. tostring(orig.hair) .. " / " .. tostring(orig.beard))
    -- Hidden actions: the no-tool checks run at Folded (the default), whatever the player had; both hint rows start shut
    say("Hidden actions was " .. tostring(SET0) .. " (" .. DS.setting() .. "); hint rows open: hair " .. tostring(OPEN0.hair) .. ", beard " .. tostring(OPEN0.beard))
    check(HO ~= nil, "Hidden actions is a ZeD setting (ZeD.Settings.hiddenActionsOption)")
    DS.setOpen("hb:more:hair", false)
    DS.setOpen("hb:more:beard", false)
    setHidden(1)
    setLook(LONG, "Full")
    HB.setPart(w, "hair")
end)
step(60, function()
    local w = win()
    check(w._activeTab == "identity", "the Character window is on Identity")
    local rs = rows()
    check(#rs > 3, "hair rows from the game's menu: " .. #rs)
    local grp = {}
    for _, r in ipairs(rs) do grp[r.grp] = (grp[r.grp] or 0) + 1 end
    say("groups: tie " .. tostring(grp.Tie) .. " shave " .. tostring(grp.Shave) .. " cut " .. tostring(grp.Cut) .. " style " .. tostring(grp.Style))
    check((grp.Tie or 0) > 0 and (grp.Cut or 0) > 0, "Tie and Cut groups")
    -- (the rows' own data: whether they show greyed or sit under the hint row is the layout's, checked below)
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    check(cut and not cut.ok and cut.reason == getText("Tooltip_RequireScissors"), "a cut with no scissors is greyed with the game's reason: " .. tostring(cut and cut.reason))
    local tie = rowWhere(function(r) return r.grp == "Tie" end)
    check(tie and tie.ok, "tying needs no tool")
    local sty = rowWhere(function(r) return r.grp == "Style" end)
    if sty then check(not sty.ok and sty.reason ~= nil, "a style with no gel or spray is greyed: " .. tostring(sty.reason)) end
    local okWord = true
    for _, r in ipairs(rs) do if r.label:sub(1, 7) == "[DEBUG]" then okWord = false end end
    check(okWord, "no debug rows")
    if MODS.SpnHairAPI then say("Out of reach with Spongie's Hairstyle Unlocker on: " .. #(st().out or {}) .. " (every style at or under the length can be picked)")
    else check(#(st().out or {}) > 0, "Out of reach holds what the hair cannot become: " .. #(st().out or {})) end
    scrollToHair()
end)
until_(1, 900, still, "the windows are still")
until_(10, 60, function() scrollToHair(); return figuresAll("no tools") end, "every hair row in view shows its figure, and Now")
-- Hidden actions at Folded (the default): what the character cannot do is not a row; one hint row keeps it
step(5, function()
    local o = lay()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    local sty = rowWhere(function(r) return r.grp == "Style" end)
    check(DS.setting() == "folded", "Hidden actions is at Folded (" .. DS.setting() .. ")")
    check(o.more ~= nil and o.more.key == "hb:more:hair", "folded: the hint row is there: " .. tostring(o.more and o.more.key))
    local ok, text = pcall(DS.rowText, o.more and o.more.groups or {})
    check(o.more ~= nil and #o.more.groups > 0 and ok and text ~= "", "folded: the hint row speaks for the hidden verbs (" .. #(o.more and o.more.groups or {}) .. " kinds): " .. tostring(text))
    check(o.greyed == 0, "folded: no greyed row in the list (" .. o.greyed .. ")")
    check(o.rows == okRows(), "folded: only the rows the character can do show (" .. o.rows .. " of " .. #rows() .. ", " .. okRows() .. " can be done)")
    check(cut ~= nil and not o.keys[cut.key] and zoneOf(cut.key) == nil, "folded: the cut row is not in the list and has no click zone")
    check(cut ~= nil and el("hb:row:" .. cut.key) == nil and (not sty or el("hb:row:" .. sty.key) == nil), "folded: the cut and style rows are no controller stops")
    check(el("hb:more") ~= nil, "folded: the hint row is a controller stop (hb:more)")
    check(not DS.isOpen("hb:more:hair"), "folded: the hint row is shut")
end)
-- Hide: no hint row at all
step(5, function() setHidden(3) end)
until_(5, 60, function() return lay().more == nil end, "Hide: the hint row is gone")
step(5, function()
    local o = lay()
    check(DS.setting() == "hide" and o.greyed == 0 and el("hb:more") == nil, "hide: no hint row, no greyed row, no stop for them (" .. DS.setting() .. ")")
    check(o.rows == okRows(), "hide: only the rows the character can do show (" .. o.rows .. ")")
    setHidden(2)
end)
-- Show all: every row shows, greyed, Out of reach with them; no hint row. The figures lists below run here
until_(5, 60, function() return lay().greyed > 0 end, "Show all: the greyed rows show")
step(5, function()
    local o = lay()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    check(DS.setting() == "all", "Hidden actions is at Show all (" .. DS.setting() .. ")")
    check(o.more == nil and el("hb:more") == nil, "show all: no hint row")
    check(o.rows == #rows() + #(st().out or {}), "show all: every row shows, Out of reach too (" .. o.rows .. " of " .. #rows() .. " + " .. #(st().out or {}) .. ")")
    check(o.greyed == o.rows - okRows(), "show all: the rows that cannot be done show greyed (" .. o.greyed .. ")")
    check(cut ~= nil and o.keys[cut.key] and el("hb:row:" .. cut.key) ~= nil, "show all: the greyed cut row is in the list and a controller stop")
end)
step(5, function() scrollToRows() end)
until_(10, 60, function() scrollToRows(); return figuresAll("the list") end, "the list scrolled: every row in view shows its figure")
step(30, function() shot("list_no_tools"); rects("list_no_tools") end)
step(5, function()
    check(HB.drawHead == nil and HB.openPictures == nil, "no drawn heads and no Pictures window left in the section")
    local any, notPlayer = false, true
    for _, f in ipairs(HB.figures(win())) do
        any = true
        if f.model.javaObject:getCharacter() ~= nil then notPlayer = false end
    end
    check(any and notPlayer, "the figures are a stand-in, not the player's own model")
    local r = rowsInView()[1]
    local ids = figIds()
    local f = r and ids[r.key]
    check(f ~= nil and f.look:find("#" .. tostring(r.style) .. "/", 1, true) ~= nil, "a row's figure wears that row's style: " .. tostring(r and r.style) .. " -> " .. tostring(f and f.look))
    A_before = lookNow()
end)
step(30, function() scrollToHair() end)
step(30, function() shot("no_tools"); rects("no_tools") end)
-- the list at its longest (Show all: every row and Out of reach too, scrolled to fill the view), the frame time with it, then another tab
step(5, function() scrollToRows() end)
until_(10, 60, function() scrollToRows(); return figuresAll("Show all, Out of reach with it") end, "figures with Out of reach shown")
step(10, function() sample("list", 240) end)
until_(30, 120, function() return perf.list ~= nil end, "frame time sampled with the list open")
-- the window as tall as the screen: the most rows (figures) at once
local tallH
step(5, function()
    local w = win()
    tallH = w:getHeight()
    w:setHeight(core:getScreenHeight() - w:getY() - 60)
end)
until_(1, 900, still, "the tall window is still")
until_(10, 90, function() scrollToRows(); return figuresAll("tall window") end, "the tall window: every row in view with its figure")
step(10, function() shot("tall"); rects("tall"); sample("list_tall", 240) end)
until_(30, 120, function() return perf.list_tall ~= nil end, "frame time sampled with the tall window")
step(5, function()
    local _, n = figIds()
    say("perf tall window: " .. n .. " figures showing")
    win():setHeight(tallH)
end)
until_(1, 900, still, "the window back to its height")
step(5, function()
    check(lookNow() == A_before, "the real character is unchanged while the figures show (" .. lookNow() .. ")")
    setHidden(1)   -- back to Folded (the default) for the rest
    local o = otherTab()
    say("tab for the release check: " .. tostring(o))
    switchTab(o)
end)
step(20, function()
    check(HB.poolSize(win()) == 0 and hbChildren() == 0, "another tab: the figures leave the window (pool " .. HB.poolSize(win()) .. ", children " .. hbChildren() .. ")")
    sample("other_tab", 240)
end)
until_(30, 120, function() return perf.other_tab ~= nil end, "frame time sampled on another tab")
step(5, function()
    if perf.list and perf.other_tab then
        say(string.format("perf the figures cost %.1f ms a frame on the mean (list %.1f, other tab %.1f)", perf.list.mean - perf.other_tab.mean, perf.list.mean, perf.other_tab.mean))
        if perf.list_tall then say(string.format("perf tall window costs %.1f ms a frame on the mean (%.1f)", perf.list_tall.mean - perf.other_tab.mean, perf.list_tall.mean)) end
    end
    switchTab("identity")
end)
until_(10, 60, function() scrollToHair(); return figuresAll("back on Identity") end, "back on Identity, the figures come back")

-- 2. the mouse. Folded: the hint row opens with a click and shuts with another
step(10, function() park(); showEl("hb:more") end)
step(20, function()
    local w = win()
    local mz = moreZone()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    check(mz ~= nil, "folded: the hint row has a click zone")
    check(cut ~= nil and zoneOf(cut.key) == nil, "folded: the cut row has no click zone (it is under the hint row)")
    if mz then
        HB.onClick(w, mz.x + 6, mz.y + 4)
        check(DS.isOpen("hb:more:hair"), "a click on the hint row opens it")
    end
end)
until_(5, 60, function() return lay().greyed > 0 end, "opened: the greyed rows show under the hint row")
step(10, function()
    local o, s = lay(), st()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    check(o.more ~= nil and o.rows == #rows() + #(s.out or {}), "opened: the hint row keeps its place and every hidden row follows it (" .. o.rows .. " of " .. #rows() .. " + " .. #(s.out or {}) .. ")")
    check(cut ~= nil and o.keys[cut.key] == true and el("hb:row:" .. cut.key) ~= nil, "opened: the greyed cut row is there, a controller stop")
end)
-- the open list is longer, so the tab's scroll (a fraction of its length) moved the hint row: bring it into view
-- first, wait for a frame to draw its click zone there, then click the same zone the first click used
step(10, function() showEl("hb:more") end)
step(20, function()
    local mz = moreZone()
    check(mz ~= nil and mz.h >= ZeD.T.px(10), "opened: the hint row is in view with its click zone (the fold stays open until shut: HB.onClick -> DS.toggle)")
    if mz then HB.onClick(win(), mz.x + 6, mz.y + 4) end
    check(not DS.isOpen("hb:more:hair"), "a second click shuts the hint row")
    if DS.isOpen("hb:more:hair") then DS.setOpen("hb:more:hair", false) end   -- (the rest of the run starts shut either way)
end)
until_(5, 60, function() return lay().greyed == 0 end, "shut: the greyed rows go again")
-- Show all: pick a greyed cut, hover it, the button stays greyed
step(5, function() setHidden(2) end)
until_(5, 60, function() return lay().greyed > 0 end, "Show all: the greyed rows show again")
step(10, function()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    if cut then showRow(cut.key) end
end)
step(20, function()
    local w, s = win(), st()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    local z = cut and zoneOf(cut.key)
    check(z ~= nil, "show all: the cut row has a click zone")
    if z then
        HB.onClick(w, z.x + 6, z.y + 4)
        check(s.sel == cut.key, "a click picks the row")
        cuesAway(true)
        pointAt(z.x + 40, z.y + 6)
    end
end)
step(50, function()
    check(st().hover ~= nil, "the mouse is over a row (its hint shows)")
    shot("greyed_hover")
    pointAt(nil)
    showEl("hb:do")   -- (Cut scrolls with the fold now: bring it into the view)
end)
step(20, function()
    local s = st()
    check(s.btn and not s.btn.on, "Cut (beside the Hair | Beard switch) is greyed for a greyed row")
    local before = queueLen()
    if s.btn then HB.onClick(win(), s.btn.x + 4, s.btn.y + 4) end
    check(queueLen() == before, "pressing the greyed button does nothing")
    cuesAway(false)
    s.sel = nil
    setHidden(1)   -- back to Folded (the default) for the rest
end)
until_(5, 60, function() return lay().greyed == 0 end, "Folded again: the greyed rows are gone")

-- 3. scissors and a cap: Cut runs the game's action, the license follows
local target, capGiven
step(10, function()
    park()
    give("Base.Scissors")
    if not p:getClothingItem_Head() then
        local cap = give("Base.Hat_BaseballCap")
        if cap then pcall(function() p:setWornItem(cap:getBodyLocation(), cap) end); capGiven = cap end
    end
    refresh()
end)
step(40, function()
    local s = st()
    local cut = rowWhere(function(r) return r.grp == "Cut" and r.style == (female and "Bob" or "Short") end)
        or rowWhere(function(r) return r.grp == "Cut" end)
    check(cut and cut.ok, "with scissors the cut can be done: " .. tostring(cut and cut.label))
    target = cut and cut.style
    s.sel = cut and cut.key
    say("head item: " .. tostring(p:getClothingItem_Head() and p:getClothingItem_Head():getDisplayName()))
end)
until_(10, 60, function() scrollToHair(); return figuresAll("scissors and a cap") and headsInView() end, "every row in view with its figure, and the Now / After heads")
step(10, function()
    local ids = figIds()
    check(ids.after ~= nil and ids.after.look:find("#" .. tostring(target) .. "/", 1, true) ~= nil, "the After head wears the picked style: " .. tostring(ids.after and ids.after.look))
    check(ids.now ~= nil and ids.now.look:find("#" .. tostring(hv:getHairModel()) .. "/", 1, true) ~= nil, "the Now head wears the hair now: " .. tostring(ids.now and ids.now.look))
    check(p:getClothingItem_Head() ~= nil, "the cap is still on the real character (only the figures go without it)")
end)
-- the heads half scrolled out of the view: Now and After still show, cut by the view's edge
local function halfHeads() scrollToHeads(math.floor(ZeD.T.px(HEAD_H) / 2)) end
step(5, function() halfHeads() end)
until_(10, 60, function()
    halfHeads()
    local ids = figIds()
    return ids.now ~= nil and ids.after ~= nil and (ids.now.cut or 0) > 0
end, "the heads half out of the view: Now and After show the part inside it")
step(20, function()
    local ids = figIds()
    check(ids.now and ids.now.cut > 0 and ids.after and ids.after.cut > 0, "hair: Now and After cut by the view's edge, not left empty (cut " .. tostring(ids.now and ids.now.cut) .. " px)")
    shot("heads_cut"); rects("heads_cut")
end)
step(10, function() scrollToHair() end)
step(30, function()
    shot("ready"); rects("ready")
    scrollToRows()
end)
until_(10, 60, function() scrollToRows(); return figuresAll("with scissors") end, "with scissors, the list: every row in view with its figure")
step(30, function() shot("hair_list"); rects("hair_list"); showEl("hb:do") end)   -- (Cut scrolls with the fold: bring it into the view for the press)
step(30, function()
    local s = st()
    check(s.btn and s.btn.on, "Cut is live")
    HB.onClick(win(), s.btn.x + 4, s.btn.y + 4)
    check(s.busy ~= nil, "the cut is running")
end)
step(40, function()
    check(ISTimedActionQueue.hasActionType(p, "ISCutHair"), "the game's ISCutHair is queued")
    shot("cutting")
end)
until_(30, 60, function() return st().busy == nil end, "the cut ends")
step(30, function()
    local s = st()
    check(hv:getHairModel() == target, "the hair is now " .. tostring(target) .. ": " .. tostring(hv:getHairModel()))
    check(s.done ~= nil, "the line under the switch says done: " .. tostring(s.done))
    check(p:getClothingItem_Head() == nil, "the cap came off first")
    local w = win()
    check(w._identityCache and w._identityCache.hairStyle == hairWord(target), "the license's Hair style line follows: " .. tostring(w._identityCache and w._identityCache.hairStyle))
    shot("done")
end)

-- 4. tie and untie (A on the row)
step(10, function() setLook(LONG, "Full") end)
local tieKey
step(40, function()
    local tie = rowWhere(function(r) return r.grp == "Tie" end)
    check(tie ~= nil, "a tie row after growing it back")
    tieKey = tie and tie.key
    local w = win()
    pcall(F.claimFocus, w)
end)
step(20, function()
    local e = tieKey and focusId("hb:row:" .. tieKey)
    check(e ~= nil, "the tie row is a controller stop")
    if e then e.onActivate(win(), e) end
end)
until_(30, 40, function() return st().busy == nil and not ISTimedActionQueue.hasActionType(p, "ISCutHair") end, "the tie ends")
step(30, function()
    check(hv:getNonAttachedHair() == LONG, "tied: the loose style is kept (" .. tostring(hv:getNonAttachedHair()) .. ")")
    local rs = rows()
    check(#rs == 1 and rs[1].label == getText("ContextMenu_UntieHair"), "tied: Untie Hair is the only row (" .. #rs .. ")")
    shot("tied")
    local e = rs[1] and focusId("hb:row:" .. rs[1].key)
    if e then e.onActivate(win(), e) end
end)
until_(30, 40, function() return st().busy == nil and not ISTimedActionQueue.hasActionType(p, "ISCutHair") end, "the untie ends")
step(20, function()
    check(hv:getHairModel() == LONG and hv:getNonAttachedHair() == nil, "untied: back to " .. LONG .. " (" .. tostring(hv:getHairModel()) .. ")")
end)

-- 5. the controller path (the beard part on the character's own hair)
step(10, function() setLook(REAL, "Full") end)
step(20, function()
    local w = win()
    w._identityScroll:setScrollPos(0)
    check(focusId("identity:__disclosure") ~= nil, "focus on the tab's disclosure")
end)
step(20, function()
    F.dispatchJoypadDir(win(), "down")
    check(focused() == "hb:part", "down from the disclosure lands on the Hair | Beard switch (" .. tostring(focused()) .. ")")
    -- Cut (Oct 30 2026: beside the switch, no footer band) is the next stop in the order, and always a stop
    local at, cutAt
    for i, e in ipairs(els()) do
        if e.id == "hb:part" then at = i elseif e.id == "hb:do" then cutAt = i end
    end
    check(at ~= nil and cutAt == at + 1, "Cut is a stop right after the Hair | Beard switch (" .. tostring(at) .. ", " .. tostring(cutAt) .. ")")
    local sb = st().btn
    local ce = el("hb:do")
    check(sb ~= nil and ce ~= nil and ce.x == sb.x, "Cut's stop sits where its button draws")
end)
step(20, function()
    if female then say("no beard half for a woman: skipped"); return end
    F.dispatchJoypadDir(win(), "right")
    check(st().part == "beard" and focused() == "hb:part", "right flips to Beard and stays on the switch")
end)
step(30, function()
    if female then return end
    -- no tools: the beard rows are greyed; A does nothing
    for i = #given, 1, -1 do
        local it = given[i]
        if it:getType() == "Scissors" then
            if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
            if it:getContainer() then it:getContainer():Remove(it) end
            table.remove(given, i)
        end
    end
    refresh()
end)
-- on a greyed beard row (focus walked onto it): the strip follows focus with no press, says why; A does nothing
local function greyedRowFocus(what)
    local id = focused() or ""
    check(id:sub(1, 7) == "hb:row:", what .. ": down walks into the beard rows (" .. id .. ")")
    local s = st()
    check(s.sel ~= nil and ("hb:row:" .. s.sel) == id, what .. ": the strip follows focus with no press")
    local r = rowWhere(function(x) return x.key == s.sel end)
    check(r and not r.ok and r.reason == getText("Tooltip_requireRazorOrScissors"), what .. ": greyed with the game's reason: " .. tostring(r and r.reason))
    local before = queueLen()
    local e = F.getFocusedElement(win())
    if e then e.onActivate(win(), e) end
    check(queueLen() == before and s.busy == nil, what .. ": A on a greyed row does nothing")
end
-- Folded (the default): nothing in the beard list can be done, so down from the switch lands on the hint row and picks nothing
step(30, function()
    if female then return end
    local s = st()
    s.sel = nil
    F.dispatchJoypadDir(win(), "down")
    check(focused() == "hb:more", "folded: down from the switch lands on the hint row (" .. tostring(focused()) .. ")")
    check(s.sel == nil, "folded: focus on the hint row picks nothing (" .. tostring(s.sel) .. ")")
    local o = lay()
    check(o.rows == 0 and o.more ~= nil and o.more.key == "hb:more:beard", "folded: no beard row can be done, only the hint row shows (" .. o.rows .. " rows)")
    shot("pad_beard_folded")
end)
-- A on the hint row opens it; down walks the greyed rows
step(20, function()
    if female then return end
    local e = F.getFocusedElement(win())
    if e then e.onActivate(win(), e) end
    check(DS.isOpen("hb:more:beard"), "folded: A on the hint row opens it")
end)
until_(5, 60, function() if female then return true end; return lay().greyed > 0 end, "opened: the greyed beard rows show under the hint row")
step(30, function()
    if female then return end
    F.dispatchJoypadDir(win(), "down")
    greyedRowFocus("opened")
    shot("pad_beard_greyed")
end)
-- A on the hint row again shuts it
step(20, function()
    if female then return end
    local e = focusId("hb:more")
    check(e ~= nil, "opened: the hint row is a stop")
    if e then e.onActivate(win(), e) end
    check(not DS.isOpen("hb:more:beard"), "A on the hint row shuts it")
end)
until_(5, 60, function() if female then return true end; return lay().greyed == 0 end, "shut: the greyed beard rows go again")
-- Show all: the greyed rows are in the list already, down from the switch lands on the first of them
step(10, function() if not female then setHidden(2) end end)
until_(5, 60, function() if female then return true end; return lay().greyed > 0 end, "Show all: the greyed beard rows show")
step(20, function()
    if female then return end
    check(el("hb:more") == nil, "show all: no hint row to walk through")
    st().sel = nil
    focusId("hb:part")
end)
step(20, function()
    if female then return end
    F.dispatchJoypadDir(win(), "down")
    greyedRowFocus("show all")
    shot("pad_beard_show_all")
end)
-- back to Folded (the default) for the trim
step(10, function() if not female then setHidden(1) end end)
until_(5, 60, function() if female then return true end; return lay().greyed == 0 end, "Folded again: the greyed beard rows are gone")
local beardKey
step(10, function() if not female then give("Base.Scissors"); refresh() end end)
step(40, function()
    if female then return end
    local r = rowWhere(function(x) return x.style == "Moustache" end) or rowWhere(function(x) return x.grp == "Trim" end)
    check(r and r.ok, "with scissors the trim can be done: " .. tostring(r and r.label))
    target = r and r.style
    beardKey = r and r.key
    if r then focusId("hb:row:" .. r.key) end
end)
until_(10, 60, function()
    if female then return true end
    scrollToHair()
    return figuresAll("beard") and headsInView()
end, "every beard row in view with its figure, and the Now / After heads")
local function tail(look) return look and look:match("#.*$") end
-- every beard row in view: the character's own hair, that row's beard
local function beardRows(what)
    local ids = figIds()
    local hair = hv:getHairModel()
    local n, badH, badB = 0, 0, 0
    for _, r in ipairs(rowsInView()) do
        local fr = ids[r.key]
        if r.part == "beard" and fr then
            n = n + 1
            if not fr.look:find("#" .. hair .. "/", 1, true) then badH = badH + 1; say("ERR hair off on " .. r.key .. ": " .. tail(fr.look)) end
            if not fr.look:find("/" .. tostring(r.style) .. "@S", 1, true) then badB = badB + 1; say("ERR beard off on " .. r.key .. ": " .. tail(fr.look)) end
        end
    end
    check(n > 0 and badH == 0, what .. ": every beard row's figure keeps the character's hair (" .. tostring(hair) .. ", " .. n .. " rows)")
    check(n > 0 and badB == 0, what .. ": every beard row's figure wears that row's beard (" .. n .. " rows)")
end
step(10, function()
    if female then return end
    local ids = figIds()
    local hair, curB = hv:getHairModel(), hv:getBeardModel() or ""
    check(hair == REAL, "the beard list runs on the character's own hair: " .. tostring(hair))
    beardRows("beard, under the heads")
    check(ids.now ~= nil and ids.now.look:find("#" .. hair .. "/" .. curB .. "@S", 1, true) ~= nil, "beard: Now shows the character as they are: " .. tostring(ids.now and tail(ids.now.look)))
    local sel = st().sel
    check(sel == beardKey, "the focused row is the picked one (" .. tostring(sel) .. ")")
    check(ids.after ~= nil and ids.after.look:find("#" .. hair .. "/" .. tostring(target) .. "@S", 1, true) ~= nil, "beard: After shows the picked row's result: " .. tostring(ids.after and tail(ids.after.look)))
    shot("pad_beard"); rects("pad_beard")
end)
step(5, function() if not female then halfHeads() end end)
until_(10, 60, function()
    if female then return true end
    halfHeads()
    local ids = figIds()
    return ids.now ~= nil and ids.after ~= nil and (ids.now.cut or 0) > 0
end, "beard: the heads half out of the view, Now and After show the part inside it")
step(20, function()
    if female then return end
    local ids = figIds()
    check(ids.now and ids.now.cut > 0 and ids.after and ids.after.cut > 0, "beard: Now and After cut by the view's edge, not left empty")
    shot("beard_cut"); rects("beard_cut")
    for _, f in pairs(ids) do
        say(string.format("fig %s y %d h %d cut %d zoom %.3f yoff %.4f", tostring(f.id), f.y, f.h, f.cut or 0, f.zoom or -1, f.yoff or -1))
    end
    scrollToRows()
end)
until_(10, 60, function() if female then return true end; scrollToRows(); return figuresAll("beard rows") end, "beard: the list scrolled, every row in view with its figure")
step(20, function()
    if female then return end
    beardRows("beard, the list")
    local f = beardKey and figIds()[beardKey]
    if not f then showRow(beardKey) end
end)
step(20, function()
    if female then return end
    local f = beardKey and figIds()[beardKey]
    check(f ~= nil and f.look:find("/" .. tostring(target) .. "@S", 1, true) ~= nil, "the picked beard row's figure wears that beard: " .. tostring(f and tail(f.look)))
    shot("beard_list"); rects("beard_list")
    for _, g in pairs(figIds()) do
        say(string.format("fig %s y %d h %d cut %d zoom %.3f yoff %.4f", tostring(g.id), g.y, g.h, g.cut or 0, g.zoom or -1, g.yoff or -1))
    end
    scrollToHair()
end)
step(20, function()
    if female then return end
    local e = beardKey and el("hb:row:" .. beardKey)
    if e then e.onActivate(win(), e) end
end)
until_(30, 60, function() return st().busy == nil and not ISTimedActionQueue.hasActionType(p, "ISTrimBeard") end, "the trim ends")
step(20, function()
    if female then return end
    check(hv:getBeardModel() == target, "the beard is now " .. tostring(target) .. ": " .. tostring(hv:getBeardModel()))
end)

-- 6. Out of reach (in the hint row since the cohesion pass: what the hair or beard cannot become, with the
-- verbs that need a tool); the Identity traits
step(20, function()
    DS.setOpen("hb:more:" .. tostring(st().part), false)   -- start from the hint row shut
    refresh()
end)
until_(5, 60, function() if female then return true end; local o = lay(); return o.more ~= nil and o.greyed == 0 end, "the hint row alone, shut")
step(10, function()
    if female then return end
    local o = lay()
    local g = o.more and o.more.groups
    local last = g and g[#g]
    check(last ~= nil and last.hint == ZeD.tr("UI_ZeD_Hair_HintMoreStyles"), "the hint row names the styles out of reach: " .. tostring(last and last.hint))
    local e = focusId("hb:more")
    check(e ~= nil, "Out of reach is a stop (the hint row, hb:more)")
    if e then e.onActivate(win(), e) end
end)
step(30, function()
    if female then return end
    check(DS.isOpen("hb:more:" .. tostring(st().part)), "A folds Out of reach open (the hint row opens)")
    local r = st().out[1]
    local e = r and focusId("hb:row:" .. r.key)
    check(e ~= nil and st().sel == r.key, "an out-of-reach row can be focused and says why")
    shot("out_of_reach")
    DS.setOpen("hb:more:" .. tostring(st().part), false)
end)
-- the trait cards (the mouse's through requestDetailCard after the shared pause, the focus's drawn at once)
local traitFocus, traitHover
step(20, function()
    local w = win()
    cardListen(true)
    cardSeen.req, cardSeen.drawn = {}, {}
    pcall(F.claimFocus, w)
    pcall(F.dispatchJoypadDir, w, "down")   -- a pad press: the controller's marks show
    local e = F.focusWhere(w, "charTabContent", function(x) return x.id and x.id:sub(1, 15) == "identity:trait:" end)
    traitFocus = e
    check(e ~= nil, "a trait is a controller stop: " .. tostring(e and e.id))
end)
step(40, function()
    local e = traitFocus
    local name = e and e.id and e.id:sub(16)
    check(name ~= nil and cardSeen.drawn[name] == true and cardSeen.req[e.id] == nil, "focus shows the description at once (no hover timer): " .. tostring(name))
    shot("trait_focus")
    pcall(F.releaseFocus)
end)
step(20, function()
    local w = win()
    local view = w._identityGridScrollZone
    local z
    for _, t in ipairs(w._idTraitZones or {}) do
        if not z and view and t.y >= view.y and t.y + t.h <= view.y + view.h then z = t end
    end
    traitHover = z
    cardSeen.req, cardSeen.drawn = {}, {}
    if z then cuesAway(true); pointAt(z.x + 30, z.y + 6) end
    check(z ~= nil, "trait zones are kept for hover")
end)
step(70, function()
    local z = traitHover
    local r = z and cardSeen.req[z.id]
    check(r ~= nil and r.title == z.name and (z.desc == nil or z.desc == "" or (r.lines ~= nil and r.lines[1] == z.desc)),
        "hover on a trait shows its description: " .. tostring(z and z.name))
    check(z ~= nil and cardSeen.drawn[z.name] == true, "the trait's card is drawn after the shared pause")
    shot("trait_hover")
    pointAt(nil)
    cuesAway(false)
    cardListen(false)
    park()
end)

-- 7. Large text; the hair mods
step(10, function() setLook(LONG, "Full"); HB.setPart(win(), "hair") end)
step(30, function() scrollToHair(); ZeD.applyTheme(base, accent, "large") end)
step(60, function() scrollToHair() end)
until_(10, 60, function() scrollToRows(); return figuresAll("Large text") end, "Large text: every row in view with its figure")
step(30, function() shot("large"); rects("large") end)
step(10, function() ZeD.applyTheme("light", accent, size) end)
step(30, function() scrollToHair() end)
until_(10, 60, function() scrollToRows(); return figuresAll("Light") end, "Light: every row in view with its figure")
step(30, function() shot("light"); rects("light") end)
step(10, function() ZeD.applyTheme(base, accent, size) end)
step(40, function()
    local s = st()
    if MODS.SpnHairAPI and not (MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler) then
        local tagged = rowWhere(function(r) return r.mod == "SpnHairAPI" end)
        check(tagged ~= nil, "Spongie's Hairstyle Unlocker: its extra rows carry its tag (" .. tostring(tagged and tagged.label) .. ")")
        scrollToHair()
    else
        say("Spongie's Hairstyle Unlocker on: " .. tostring(MODS.SpnHairAPI == true))
    end
    if MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler then
        check(#(s.pics or {}) > 0, "the picture mod's lists are read into rows (" .. #rows() .. " rows)")
        check(el("hb:pics") == nil, "no Pictures button: the mod's styles are rows with figures")
        scrollToHair()
    end
    if not mods().traitsAsSkills then check(CW._extTabs.traits == nil, "no Traits tab without Traits As Skills") end
end)
until_(10, 60, function() scrollToRows(); return figuresAll("after Large and Light") end, "every row in view with its figure")
step(30, function() if MODS.SpnHairAPI or MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler then shot("mod_rows"); rects("mod_rows") end end)
-- Spongie's tagged rows in view, for the crop
local function spongieRow() return MODS.SpnHairAPI and rowWhere(function(r) return r.mod == "SpnHairAPI" end) or nil end
step(10, function() local t = spongieRow(); if t then showRow(t.key) end end)
until_(10, 60, function()
    local t = spongieRow()
    if not t then return true end
    showRow(t.key)
    local ids = figIds()
    return ids[t.key] ~= nil
end, "Spongie's tagged row in view with its figure")
step(30, function() if spongieRow() then shot("spongie_tag"); rects("spongie_tag") end end)
-- the window closes: the figures go with it; it opens again with them back
step(10, function() CW.toggleBothPaired(0) end)
step(30, function()
    check(not CW.isOpen() and HB.poolSize(win()) == 0 and hbChildren() == 0, "the window closed: the figures left it (children " .. hbChildren() .. ")")
    CW.toggleBothPaired(0)
end)
until_(10, 90, function()
    local w = win()
    if not (w and CW.isOpen()) then return false end
    if w._activeTab ~= "identity" then switchTab("identity") end
    scrollToHair()
    return figuresAll("reopened")
end, "reopened: the figures come back")

-- B. a woman's hair list: the QA character is made a woman for a few seconds (the game's own
-- flag, body texture and a woman's long hair), the list, Now and After are checked, then she is
-- put back as she was
local femSave
step(10, function()
    if female then say("the QA character is a woman already: the hair list above was hers"); return end
    femSave = { f = p:isFemale(), df = p:getDescriptor():isFemale(), skin = hv:getSkinTexture(),
                hair = hv:getHairModel(), beard = hv:getBeardModel(), na = hv:getNonAttachedHair() }
    p:setFemale(true)
    p:getDescriptor():setFemale(true)
    local sk = tostring(femSave.skin or ""):gsub("^Male", "Female")
    if sk ~= "" then hv:setSkinTextureName(sk) end
    hv:setNonAttachedHair(nil)
    hv:setHairModel("Long2")
    hv:setBeardModel("")
    p:resetModel()
    local w = win(); if w then w._identityCache = nil end
    refresh()
    HB.setPart(w, "hair")
    say("made a woman for the check: " .. tostring(p:isFemale()) .. ", skin " .. tostring(hv:getSkinTexture()))
end)
until_(10, 90, function()
    if not femSave then return true end
    scrollToHair()
    local s = st()
    return s.female == true and s.part == "hair" and #(s.rows or {}) > 0 and figuresAll("a woman") and headsInView()
end, "a woman: her hair rows and Now show")
step(10, function()
    if not femSave then return end
    local s, ids = st(), figIds()
    check(s.female == true and (s.counts.beard or 0) == 0, "a woman: no beard half (" .. tostring(s.counts.beard) .. " beard rows)")
    check(s.av and s.av.desc and s.av.desc:isFemale(), "a woman: the figures' stand-in is a woman")
    local bad = 0
    for _, r in ipairs(s.rows) do
        if r.style and r.style ~= "" and getHairStylesInstance():FindFemaleStyle(r.style) == nil then bad = bad + 1; say("ERR not a woman's style: " .. tostring(r.style)) end
    end
    check(bad == 0, "a woman: every row is one of the game's women's styles (" .. #s.rows .. " rows)")
    check(ids.now ~= nil and ids.now.look:find("#Long2/", 1, true) ~= nil, "a woman: Now wears her hair: " .. tostring(ids.now and ids.now.look:match("#.*$")))
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    s.sel = cut and cut.key
    target = cut and cut.style
end)
until_(10, 60, function()
    if not femSave then return true end
    scrollToHair()
    local ids = figIds()
    return ids.after ~= nil
end, "a woman: After shows the picked cut")
step(10, function()
    if not femSave then return end
    local ids = figIds()
    check(ids.after ~= nil and ids.after.look:find("#" .. tostring(target) .. "/", 1, true) ~= nil, "a woman: After wears the picked cut: " .. tostring(ids.after and ids.after.look:match("#.*$")))
    shot("female_heads"); rects("female_heads")
    st().sel = nil
    scrollToRows()
end)
until_(10, 60, function() if not femSave then return true end; scrollToRows(); return figuresAll("a woman's list") end, "a woman's list: every row in view with its figure")
step(30, function() if femSave then shot("female_list"); rects("female_list") end end)
local function unWoman()
    if not femSave then return end
    p:setFemale(femSave.f)
    p:getDescriptor():setFemale(femSave.df)
    if femSave.skin then hv:setSkinTextureName(femSave.skin) end
    hv:setHairModel(femSave.hair)
    hv:setBeardModel(femSave.beard)
    hv:setNonAttachedHair(femSave.na)
    p:resetModel()
    femSave = nil
end
step(10, function()
    if not femSave then return end
    unWoman()
    refresh()
end)
step(30, function()
    check(p:isFemale() == female and p:getDescriptor():isFemale() == female, "the QA character is put back: female " .. tostring(p:isFemale()) .. ", skin " .. tostring(hv:getSkinTexture()))
end)

-- put everything back
step(20, function()
    pcall(unWoman)
    park()
    pcall(F.releaseFocus)
    pcall(pointAt, nil)
    -- Hidden actions and each hint row as they were found; the script's listeners off
    pcall(cuesAway, false)
    pcall(cardListen, false)
    pcall(function() if HO and SET0 ~= nil then HO:setValue(SET0) end end)
    pcall(function() DS.setOpen("hb:more:hair", OPEN0.hair); DS.setOpen("hb:more:beard", OPEN0.beard) end)
    ZeD.applyTheme(base, accent, size)
    pcall(ZeD.Settings.reapplyFromOptions)
    pcall(ISTimedActionQueue.clear, p)
    for _, it in ipairs(given) do
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        if p:isEquipped(it) then pcall(function() p:removeWornItem(it) end) end
        if it:getContainer() then it:getContainer():Remove(it) end
    end
    for _, t in ipairs(taken) do t.c:AddItem(t.it) end
    hv:setHairModel(orig.hair)
    if not female then hv:setBeardModel(orig.beard) end
    hv:setNonAttachedHair(orig.na)
    p:resetModel()
    local w = win(); if w then w._identityCache = nil; w._identityScroll:setScrollPos(0) end
    HB.setPart(w, "hair")
    refresh()
    say("put back: " .. tostring(hv:getHairModel()) .. " / " .. tostring(hv:getBeardModel()) .. ", " .. #taken .. " tools returned")
    check(not HO or SET0 == nil or HO:getValue() == SET0, "Hidden actions is back as it was found: " .. tostring(HO and HO:getValue()) .. " (was " .. tostring(SET0) .. ")")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local tries = 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    local ok, res = pcall(s.fn)
    if not ok then
        fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(res)); qi = qi + 1; tries = 0
    elseif s.tries and res ~= true then
        tries = tries + 1
        if tries >= s.tries then fails = fails + 1; say("FAIL timed out: " .. tostring(s.what)); qi = qi + 1; tries = 0 end
    else
        if s.what then say("PASS " .. s.what) end
        qi = qi + 1; tries = 0
    end
end
Events.OnRenderTick.Add(tick)
say("start")
