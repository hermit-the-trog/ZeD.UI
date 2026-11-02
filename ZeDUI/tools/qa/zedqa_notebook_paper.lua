-- ZeDUI/tools/qa/zedqa_notebook_paper.lua  (Nov 1 2026; punch list 50, for t16)
-- The ruled paper of a notebook, as the real sheet: blue rules edge to edge through the red margin, the
-- margin the page's full height about a seventh of the width in, a blank band above the first rule (one
-- rule tall on the small page; the head band with the name and page number on the full page), nothing red
-- across, the binder holes on the full page.
-- On the Character window's Journal tab, Notebooks sub-tab, two notebooks carried (one blank, one written
-- through the tab's own quick note, ZeD.JournalReaders.writeNote; the item's addPage only if that fails)
-- and a pencil: the small page blank and written, then Open full (the sub-tab's own button) on each.
-- The page drawing's numbers are locals of its code (miniPage in ZeD_JournalReaders.lua, drawNotePage in
-- ZeD_Reader.lua), so the run reads what is drawn: for a few ticks it notes every drawRect / drawText in the
-- paper's colours (the paper, the rules, the margin, the holes, the ink) and measures them, then puts the
-- two draw functions back. Screenshots: zqa_nbp_small_blank.png, zqa_nbp_small_written.png,
-- zqa_nbp_full_blank.png, zqa_nbp_full_written.png. Puts back the notebooks, the pencil, the sub-tab, the
-- clock and the full page closed. grep "ZEDQA nbp".
local p = getPlayer()
local pn = p:getPlayerNum()
local T = ZeD.T
local J, N = ZeD.JournalReaders, ZeD.Notes
local gt = getGameTime()
local function say(s) print("ZEDQA nbp " .. tostring(s)) end
local fails, passes = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function reader() return ZeD.Reader and ZeD.Reader.get(pn) or nil end
local SW, SH = getCore():getScreenWidth(), getCore():getScreenHeight()
local S = { was = {}, added = {} }

-- ---- the step queue (as zedqa_two_widths.lua)
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end
local STILL, STILL_MAX = 30, 600
local function shape()
    local t = {}
    local w, r = cw(), reader()
    if w and w:isVisible() then t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)) end
    if r and r:isVisible() then t[#t + 1] = string.format("r%d,%d,%d,%d", r:getX(), r:getY(), r:getWidth(), r:getHeight()) end
    return table.concat(t, ";")
end
local function whenStill(fn)
    local last, same, waited = nil, 0, 0
    local function poll()
        local s = shape()
        if s == last then same = same + 1 else same, last = 0, s end
        waited = waited + 1
        if same >= STILL or waited >= STILL_MAX then
            if same < STILL then say("WARN the windows were still moving after " .. waited .. " ticks: checked anyway") end
            local ok, e = pcall(fn)
            if not ok then say("ERR " .. tostring(e)) end
        else
            insertNext(0, poll)
        end
    end
    insertNext(0, poll)
end
local function goTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end
local function charTab(id) local w = cw(); return w and goTab(w, w._tabStripPanel, id) end
local function rs(x, y, w, h) return string.format("%d,%d %dx%d", math.floor(x), math.floor(y), math.floor(w), math.floor(h)) end
local function shot(what, extra)
    local name = "zqa_nbp_" .. what .. ".png"
    pcall(function() getCore():TakeFullScreenshot(name) end)
    local w, r = cw(), reader()
    say(string.format("shot %s (%dx%d): Character %s, drawer %d px%s%s", name, SW, SH, rs(w:getX(), w:getY(), w:getWidth(), w:getHeight()),
        math.floor(w._drawerEffW or 0), (r and r:isVisible()) and (" | full page window " .. rs(r:getX(), r:getY(), r:getWidth(), r:getHeight())) or "", extra or ""))
end

-- ---- the draw capture: the paper's colours (ZeD_JournalReaders.lua and ZeD_Reader.lua)
local COL = {
    paper  = { r = 0.91, g = 0.886, b = 0.824 },
    rule   = { r = 0.725, g = 0.776, b = 0.839 },
    margin = { r = 0.827, g = 0.604, b = 0.573 },
    table  = { r = 0.035, g = 0.043, b = 0.039 },
    ink    = { r = 0.141, g = 0.133, b = 0.118 },
    dim    = { r = 0.424, g = 0.404, b = 0.361 },
}
local function kindOf(r, g, b)
    for k, c in pairs(COL) do
        if math.abs(r - c.r) < 0.004 and math.abs(g - c.g) < 0.004 and math.abs(b - c.b) < 0.004 then return k end
    end
    return nil
end
local CAP, origRect, origText = nil, nil, nil
local function capStart()
    if CAP then return end
    CAP = { rects = {}, texts = {}, seen = {}, all = 0, objs = {} }
    origRect, origText = ISUIElement.drawRect, ISUIElement.drawText
    ISUIElement.drawRect = function(self, x, y, w, h, a, r, g, b)
        if CAP then CAP.all = CAP.all + 1 end
        if CAP and r and g and b then
            local k = kindOf(r, g, b)
            if k and k ~= "ink" and k ~= "dim" then
                local key = tostring(self) .. k .. math.floor(x) .. ":" .. math.floor(y) .. ":" .. math.floor(w) .. ":" .. math.floor(h)
                if not CAP.seen[key] then CAP.seen[key] = true; CAP.rects[#CAP.rects + 1] = { panel = self, k = k, x = x, y = y, w = w, h = h } end
            end
        end
        return origRect(self, x, y, w, h, a, r, g, b)
    end
    ISUIElement.drawText = function(self, str, x, y, r, g, b, a, font)
        if CAP and r and g and b then
            local k = kindOf(r, g, b)
            if k == "ink" or k == "dim" then
                local key = tostring(self) .. k .. tostring(str) .. math.floor(x) .. ":" .. math.floor(y)
                if not CAP.seen[key] then
                    CAP.seen[key] = true
                    local fh = 0
                    pcall(function() fh = ZeD.TM:getFontHeight(font or UIFont.Small) end)
                    CAP.texts[#CAP.texts + 1] = { panel = self, k = k, s = tostring(str), x = x, y = y, h = fh }
                end
            end
        end
        return origText(self, str, x, y, r, g, b, a, font)
    end
    -- the two objects that draw the paper get the wrappers as their own fields too (Build, Nov 1 2026: the small
    -- page through the Character window's drawer panel, the full page on the reader window), in case a class in
    -- between carries its own drawRect; put back by capStop
    local w = cw()
    for _, o in ipairs({ w and w._drawerPanel, reader() }) do
        if o then
            CAP.objs[#CAP.objs + 1] = { o = o, rect = rawget(o, "drawRect"), text = rawget(o, "drawText") }
            o.drawRect, o.drawText = ISUIElement.drawRect, ISUIElement.drawText
        end
    end
end
local function capStop()
    for _, e in ipairs((CAP and CAP.objs) or {}) do e.o.drawRect, e.o.drawText = e.rect, e.text end
    if origRect then ISUIElement.drawRect = origRect end
    if origText then ISUIElement.drawText = origText end
    origRect, origText = nil, nil
    local c = CAP
    CAP = nil
    return c
end

-- measure one page: the largest paper rect drawn on a panel pred(panel) accepts, and what lies on it
local function measure(c, pred, label, full)
    local paper = nil
    for _, r in ipairs(c and c.rects or {}) do
        if r.k == "paper" and pred(r.panel) and (not paper or r.w * r.h > paper.w * paper.h) then paper = r end
    end
    if not check(paper ~= nil, label .. ": the paper was drawn (" .. tostring(c and c.all) .. " drawRect calls seen, " .. tostring(c and #c.rects) .. " in the paper's colours)") then return end
    local P = paper
    local ax, ay = P.panel:getAbsoluteX(), P.panel:getAbsoluteY()
    local function on(r) return r.panel == P.panel and r.x >= P.x - 1 and r.x <= P.x + P.w + 1 and r.y >= P.y - 1 and r.y <= P.y + P.h + 1 end
    local rules, margins, holes, ink, dim = {}, {}, {}, {}, {}
    for _, r in ipairs(c.rects) do
        if on(r) then
            if r.k == "rule" then rules[#rules + 1] = r
            elseif r.k == "margin" then margins[#margins + 1] = r
            elseif r.k == "table" and r.h <= T.px(2) then holes[#holes + 1] = r end
        end
    end
    for _, t in ipairs(c.texts) do
        if on(t) then if t.k == "ink" then ink[#ink + 1] = t else dim[#dim + 1] = t end end
    end
    table.sort(rules, function(a, b) return a.y < b.y end)
    local diffs = {}
    for i = 2, #rules do diffs[#diffs + 1] = rules[i].y - rules[i - 1].y end
    table.sort(diffs)
    local pitch = diffs[math.floor((#diffs + 1) / 2)] or 0
    local first = rules[1] and (rules[1].y - P.y) or -1
    say(string.format("%s: the paper %s on the screen (%.0f x %.0f design units at %.2f); %d rules, pitch %.1f px, the first %.1f px below the top (%.2f pitches)",
        label, rs(ax + P.x, ay + P.y, P.w, P.h), P.w / T.px(1), P.h / T.px(1), T.px(100) / 100, #rules, pitch, first, pitch > 0 and first / pitch or 0))
    -- the rules: edge to edge through the margin, under a blank band
    local edge = #rules > 0
    for _, r in ipairs(rules) do if math.abs(r.x - P.x) > 1 or math.abs(r.w - P.w) > 1 then edge = false end end
    check(edge, label .. ": every rule runs edge to edge through the margin (" .. #rules .. " rules, page x " .. math.floor(P.x) .. " w " .. math.floor(P.w)
        .. (rules[1] and (", the first x " .. math.floor(rules[1].x) .. " w " .. math.floor(rules[1].w)) or "") .. ")")
    check(#rules >= 2 and first >= pitch * 0.9, label .. ": the rules start below a blank band at least a rule tall (" .. string.format("%.1f px, pitch %.1f", first, pitch) .. ")")
    -- the margin: one, upright, about a seventh in, the page's full height; nothing red across
    local up, across = {}, {}
    for _, m in ipairs(margins) do if m.h > m.w then up[#up + 1] = m else across[#across + 1] = m end end
    local m = up[1]
    local frac = m and ((m.x - P.x) / P.w) or -1
    say(string.format("%s: the margin at x +%.0f px = %.3f of the width (a seventh is 0.143%s), %s, %.0f px wide; %d upright, %d across",
        label, m and (m.x - P.x) or -1, frac, full and "; the code's 104 of 760 is 0.137" or "", m and rs(ax + m.x, ay + m.y, m.w, m.h) or "none", m and m.w or 0, #up, #across))
    check(#up == 1, label .. ": one red margin (" .. #up .. ")")
    check(frac >= 0.12 and frac <= 0.165, label .. ": the margin about a seventh of the page's width in (" .. string.format("%.3f", frac) .. ")")
    check(m ~= nil and math.abs(m.y - P.y) <= 1 and math.abs(m.h - P.h) <= 1, label .. ": the margin runs the page's full height ("
        .. (m and string.format("y +%.0f, %.0f of %.0f px", m.y - P.y, m.h, P.h) or "none") .. ")")
    check(#across == 0, label .. ": nothing red runs across (" .. #across .. ")")
    -- the writing: in ink on the rules, right of the margin
    if #ink > 0 then
        local onRule, rightOf = 0, 0
        for _, t in ipairs(ink) do
            local bottom = t.y + t.h
            for _, r in ipairs(rules) do if math.abs(r.y - bottom) <= math.max(2, pitch * 0.5) then onRule = onRule + 1; break end end
            if m and t.x > m.x then rightOf = rightOf + 1 end
            say(string.format("%s: ink '%s' at y +%.0f, its foot %.0f px", label, t.s, t.y - P.y, bottom - P.y))
        end
        check(onRule == #ink, label .. ": each line of writing sits on a rule (" .. onRule .. " of " .. #ink .. ")")
        check(rightOf == #ink, label .. ": the writing starts right of the margin (" .. rightOf .. " of " .. #ink .. ")")
    end
    -- the head band's words (the full page's page number) above the first rule
    for _, t in ipairs(dim) do
        say(string.format("%s: '%s' at y +%.0f (the first rule at +%.0f)", label, t.s, t.y - P.y, first))
        -- (the text's y is on the screen, the first rule's is from the page's top: both relative here; the line
        -- counter sits at the foot, below the rules, by design)
        local rel = t.y - P.y
        if full then
            if rel < first then check(rel + t.h <= first + 1, label .. ": '" .. t.s .. "' sits in the head band, above the first rule")
            else say(string.format("%s: '%s' sits at the foot, below the rules (y +%.0f)", label, t.s, rel)) end
        end
    end
    -- the binder holes (discs of the table's colour in slices): grouped where the slices stop touching
    table.sort(holes, function(a, b) return a.y < b.y end)
    local groups, g = {}, nil
    for _, h in ipairs(holes) do
        if g and h.y - g.y1 <= T.px(2) + 1 then
            if h.y + h.h > g.y1 then g.y1 = h.y + h.h end
            if h.w > g.w then g.w, g.x = h.w, h.x end
        else
            g = { y0 = h.y, y1 = h.y + h.h, x = h.x, w = h.w }
            groups[#groups + 1] = g
        end
    end
    local hs = {}
    for _, hg in ipairs(groups) do hs[#hs + 1] = string.format("x +%.0f y +%.0f %.0fx%.0f", hg.x - P.x, hg.y0 - P.y, hg.w, hg.y1 - hg.y0) end
    say(label .. ": " .. #groups .. " binder holes" .. (#hs > 0 and (": " .. table.concat(hs, ", ")) or ""))
    if full then
        local leftOf = true
        for _, hg in ipairs(groups) do if m and hg.x + hg.w > m.x then leftOf = false end end
        check(#groups == 3 and leftOf, label .. ": the three binder holes stay, left of the margin (" .. #groups .. ")")
    end
    return { paper = P, rules = #rules, pitch = pitch, first = first, frac = frac }
end

-- ---- setup: noon (the game will not open a page in the dark), the notebooks, the pencil, the sub-tab
local blank, written, pencil
local LINE1 = "water from the creek, boil it first"
local LINE2 = "the truck needs a battery"
step(10, function()
    local w = cw()
    if not (w and w:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() Mouse.setXY(20, 20) end)
    pcall(function() setGameSpeed(1) end)
    w = cw()
    S.was.tab, S.was.sub = w._activeTab, w._journalSubTab
    S.was.nb = w._jr and w._jr.nbId
    S.was.tod = gt:getTimeOfDay()
    if p:tooDarkToRead() then gt:setTimeOfDay(12); S.setTime = true end
    local inv = p:getInventory()
    blank = inv:AddItem("Base.Notebook")
    written = inv:AddItem("Base.Notebook")
    pencil = inv:AddItem("Base.Pencil")
    for _, it in ipairs({ blank, written, pencil }) do if it then S.added[#S.added + 1] = it end end
    pcall(function() blank:setName("QA blank sheet"); blank:setCustomName(true) end)
    pcall(function() written:setName("QA written sheet"); written:setCustomName(true) end)
    charTab("journal")
    w._journalSubTab = 2
    say(string.format("screen %dx%d, root %.2f; Character tab was %s, Journal page %s; notebooks %s / %s, pencil %s; clock %.2f%s",
        SW, SH, ZeD.Scale.root(), tostring(S.was.tab), tostring(S.was.sub), tostring(blank ~= nil), tostring(written ~= nil), tostring(pencil ~= nil),
        S.was.tod, S.setTime and " -> 12 (too dark to read)" or ""))
end)
step(15, function()
    pcall(J.refresh, cw())
    local w = cw()
    check(w._activeTab == "journal" and w._journalSubTab == 2, "the Journal tab's Notebooks page is open (" .. tostring(w._activeTab) .. ", page " .. tostring(w._journalSubTab) .. ")")
end)

-- ---- the writing: the tab's own quick note, a line at a time (a short timed action each)
local function pick(b) local w = cw(); if w._jr and b then w._jr.nbId = b:getID(); w._jr.msg = nil end end
local function writeLine(text)
    local tries = 0
    step(10, function()
        pick(written)
        local w = cw()
        local f = w._jrNote
        if not f then say("WARN the quick note's field is not made yet"); return end
        f:setText(text)
        J.writeNote(w)
        say("quick note '" .. text .. "': " .. tostring(w._jr.pending ~= nil and "writing" or ("not started: " .. tostring(w._jr.msg))))
    end)
    local function poll()
        tries = tries + 1
        local w = cw()
        local done = written and string.find(N.page(written, 1), text, 1, true) ~= nil
        if done or tries > 60 or not (w._jr and w._jr.pending) then
            say("quick note '" .. text .. "': " .. (done and "on the page" or "not on the page") .. " after " .. tries .. " polls")
            return
        end
        insertNext(10, poll)
    end
    step(10, poll)
end
writeLine(LINE1)
writeLine(LINE2)
step(5, function()
    local pg = written and N.page(written, 1) or ""
    local both = string.find(pg, LINE1, 1, true) and string.find(pg, LINE2, 1, true)
    check(both ~= nil, "the written notebook has its two lines through the tab's own quick note ('" .. pg:gsub("\n", " / ") .. "')")
    if not both and written then
        written:addPage(1, LINE1 .. "\n" .. LINE2)
        say("written through the item's own addPage instead: '" .. N.page(written, 1):gsub("\n", " / ") .. "'")
    end
    check(blank and blank:isEmptyPages(), "the blank notebook is blank")
end)

-- ---- the small page: blank, then written
local function smallCase(b, what)
    step(5, function() pick(b) end)
    step(20, function() whenStill(function() capStart() end) end)
    step(10, function()
        local c = capStop()
        local r = reader()
        measure(c, function(panel) return panel ~= r end, "small page " .. what, false)
        shot("small_" .. what)
    end)
end
smallCase(blank, "blank")
smallCase(written, "written")

-- ---- Open full (the sub-tab's own button), the full page, back
local function fullCase(b, what)
    local tries = 0
    step(5, function() pick(b) end)
    step(20, function()
        local w = cw()
        local z = nil
        for _, zz in ipairs(w._jrZones or {}) do if zz.id == "full" then z = zz end end
        if check(z ~= nil and z.fn ~= nil, "full page " .. what .. ": the Open full button is there and live") then z.fn() end
    end)
    local function poll()
        tries = tries + 1
        local r = reader()
        if (r and r:isVisible() and r.mode == "notebook") or tries > 40 then
            check(r and r:isVisible() and r.mode == "notebook", "full page " .. what .. ": Open full opened the page (" .. tries .. " polls, mode " .. tostring(r and r.mode) .. ")")
            return
        end
        insertNext(10, poll)
    end
    step(10, poll)
    step(20, function() whenStill(function() capStart() end) end)
    step(10, function()
        local c = capStop()
        local r = reader()
        if not (r and r:isVisible()) then say("full page " .. what .. ": not open, nothing to measure"); return end
        local res = measure(c, function(panel) return panel == r end, "full page " .. what, true)
        local e = r.nbEntry
        local extra = ""
        if e and res then
            extra = string.format(" | the page's text box %s (x +%.0f, y +%.0f from the paper)", rs(r:getX() + e:getX(), r:getY() + e:getY(), e:getWidth(), e:getHeight()),
                e:getX() - res.paper.x, e:getY() - res.paper.y)
        end
        shot("full_" .. what, extra)
        say("full page " .. what .. ": read only " .. tostring(r.readOnly) .. ", page " .. tostring(r.pageIx) .. " of " .. tostring(r.nPages))
    end)
    step(10, function()
        local r = reader()
        if r and r:isVisible() then pcall(function() r:endWriting() end) end
    end)
    step(20, function()
        local r = reader()
        check(not (r and r:isVisible()), "full page " .. what .. ": Back closed it")
    end)
end
fullCase(blank, "blank")
fullCase(written, "written")

-- ---- put everything back
step(10, function()
    capStop()
    local r = reader()
    if r and r:isVisible() then pcall(function() r:endWriting() end) end
    local inv = p:getInventory()
    for _, it in ipairs(S.added) do
        local c = it:getContainer()
        if c then pcall(function() c:Remove(it) end) end
    end
    local w = cw()
    if w._jr then w._jr.nbId = S.was.nb end
    w._journalSubTab = S.was.sub or 1
    charTab(S.was.tab or "loot")
    if S.setTime then gt:setTimeOfDay(S.was.tod) end
    pcall(J.refresh, w)
end)
step(30, function() whenStill(function()
    local left = 0
    for _, it in ipairs(S.added) do if it:getContainer() then left = left + 1 end end
    check(left == 0, "put back: the notebooks and the pencil taken away (" .. left .. " left)")
    check(ISUIElement.drawRect ~= nil and CAP == nil, "put back: the draw functions are the game's again")
    say("put back: Character tab " .. tostring(cw()._activeTab) .. ", Journal page " .. tostring(cw()._journalSubTab) .. ", clock " .. string.format("%.2f", gt:getTimeOfDay()))
    say("for Design: the four shots show the paper; the lines above give each page's rect on the screen, the rule pitch, the band above the first rule, the margin's place and the holes")
    say(passes .. " passed")
    say(fails == 0 and "all passed" or (fails .. " FAILED"))
    say("DONE")
end) end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
say("start")
