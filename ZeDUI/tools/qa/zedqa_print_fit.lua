-- ZeDUI/tools/qa/zedqa_print_fit.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: a prototype of fitting a newspaper's stories to
-- their columns (director: "layout, text small, can we fix this"). Vanilla sets
-- every story's body at 40% in a fixed spot, so the words sit as a small block
-- inside a big empty column. The fit works on the page vanilla's own window
-- built (PZAPI PrintMedia): for each body text (SdfOldRegular with a wrap
-- width) it keeps the column's width, moves the text up under whatever sits
-- above it in that column (the headline), and grows it to the largest size
-- that still ends above whatever sits below (or the page's foot), measured on
-- the node itself (setScale, setAutoWidth, getTextHeight). Shoots each page
-- as vanilla sets it and fitted. grep "ZEDQA pf"; Screenshots/zqa_pf_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA pf " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_pf_" .. n .. ".png") end) end

local GAP, FOOT, SBODY, HEAD, LINE = 10, 24, 0.64, 1.7, 26

local function media(id) return { id = id, title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" } end
local function openPM(id)
    local val = media(id)
    local w = PZAPI.UI.PrintMedia{ x = 730, y = 100 }
    w.media_id = val.id
    w.data = getText(val.info)
    w.children.bar.children.name.text = getText(val.title)
    w.textTitle = getText(val.title)
    w.textData = string.gsub(getText(val.text) or "", "\\n", "\n")
    w:instantiate()
    w.javaObj:setAlwaysOnTop(false)
    w:centerOnScreen(pn)
    return w
end

-- every element's box on the page (page units), and which are story bodies
local function boxes(page)
    local out = {}
    for k, n in pairs(page.children or {}) do
        if type(k) == "string" and k:sub(1, 8) == "element_" and n.javaObj then
            local j = n.javaObj
            local e = { node = n, key = k }
            if n._ATOM_UI_CLASS == AtomUIText or (j.getTextHeight ~= nil and n.text ~= nil) then
                local sx, sy = j:getScaleX(), j:getScaleY()
                e.text = true
                e.w = j:getTextWidth() * sx
                e.h = j:getTextHeight() * sy
                e.x = (n.x or 0) - (n.pivotX or 0) * e.w
                e.y = (n.y or 0) - (n.pivotY or 0) * e.h
                e.body = (n.autoWidth ~= nil) and tostring(n.font):find("SdfOldRegular", 1, true) ~= nil
            elseif n.x and n.y and n.width and n.height and (n.angle == nil or n.angle == 0) then
                e.w, e.h = n.width, n.height
                e.x = n.x - (n.pivotX or 0) * n.width   -- (pictures and rules are often placed by their centre)
                e.y = n.y - (n.pivotY or 0) * n.height
            end
            if e.x and e.w then out[#out + 1] = e end
        end
    end
    return out
end

local function overlapX(a, b)
    local l = math.max(a.x, b.x)
    local r = math.min(a.x + a.w, b.x + b.w)
    return r - l
end

local function bold(e) return e.text and tostring(e.node.font):find("SdfOldBold", 1, true) ~= nil end

-- a text's height at scale s with the column's width kept (the node reports one line short)
local function heightAt(j, colW, s)
    j:setScaleX(s); j:setScaleY(s); j:setAutoWidth(colW / s)
    return (j:getTextHeight() + LINE) * s
end

local function fit(page)
    local bs = boxes(page)
    local pageH = page.height or 900
    local report = {}
    -- the story bodies worth fitting (one or two lines are bylines, "Staff Writer", "(See ...)")
    local bodies = {}
    for _, b in ipairs(bs) do
        if b.body and b.h >= LINE * b.node.javaObj:getScaleY() * 2.5 then bodies[#bodies + 1] = b end
    end
    for _, b in ipairs(bodies) do
        local n, j = b.node, b.node.javaObj
        b.s0 = j:getScaleX()
        b.colW = n.autoWidth * b.s0
        b.col = { x = n.x, w = b.colW }
        -- what sits above (its foot) and below (its head) in this column; rules beside it end it too
        local above, bottom = nil, pageH - FOOT
        for _, o in ipairs(bs) do
            if o ~= b then
                if overlapX(b.col, o) > 2 then
                    if o.y + o.h <= b.y + 2 then if not above or o.y + o.h > above.y + above.h then above = o end
                    elseif o.y >= b.y + 2 then bottom = math.min(bottom, o.y - GAP) end
                elseif not o.text and o.w <= 6 and o.h > 60 and math.abs(o.x - b.col.x) < 30 or (not o.text and o.w <= 6 and o.h > 60 and math.abs(o.x - (b.col.x + b.colW)) < 30) then
                    if o.y < b.y + 20 and o.y + o.h > b.y then bottom = math.min(bottom, o.y + o.h - 4) end
                end
            end
        end
        b.above, b.bottom = above, bottom
        -- a small headline right above grows with its story
        if above and bold(above) and above.y + above.h > b.y - 70 then
            local ja = above.node.javaObj
            local hs0 = ja:getScaleX()
            if hs0 < SBODY * 1.3 then
                local hs = math.min(SBODY * HEAD, b.colW / math.max(1, ja:getTextWidth()))
                if hs > hs0 then
                    ja:setScaleX(hs); ja:setScaleY(hs)
                    above.h = ja:getTextHeight() * hs
                    above.grown = string.format("head %.2f->%.2f", hs0, hs)
                end
            end
        end
        local top = above and math.min(b.y, above.y + above.h + GAP) or b.y
        if above and above.y + above.h + GAP > b.y then top = above.y + above.h + GAP end
        b.top, b.room = top, bottom - top
        local lo, hi, best = b.s0, SBODY, b.s0
        for _ = 1, 12 do
            local s = (lo + hi) / 2
            if heightAt(j, b.colW, s) <= b.room then best = s; lo = s else hi = s end
        end
        b.best = best
    end
    -- a row of columns at one height is one story running on: one size for all of them
    for _, b in ipairs(bodies) do
        for _, o in ipairs(bodies) do
            if o ~= b and math.abs(o.y - b.y) <= 6 then b.best = math.min(b.best, o.best); b.top = math.max(b.top, o.top) end
        end
    end
    -- the short end of a row (a column with a line or two) takes the row's size too
    for _, s in ipairs(bs) do
        if s.body and not s.s0 then
            for _, b in ipairs(bodies) do
                if math.abs(s.y - b.y) <= 6 then
                    local j, w0 = s.node.javaObj, b.colW   -- (its own wrap width can be wider than its column: it never wrapped)
                    heightAt(j, w0, b.best); j:setY(b.top)
                end
            end
        end
    end
    for _, b in ipairs(bodies) do
        local j = b.node.javaObj
        local h = heightAt(j, b.colW, b.best)
        j:setY(b.top)
        report[#report + 1] = string.format("%s y %d->%d room %d scale %.2f->%.2f h %d %s", b.key, b.y, b.top, b.room, b.s0, b.best, h, b.above and b.above.grown or "")
    end
    return report
end

local PAGES = { "KnoxKnews_July1", "KnoxKnews_July2", "KentuckyHerald_July6", "NationalDispatch_July6" }
local t, i, win = 0, 1, nil
local function onTick()
    t = t + 1
    local id = PAGES[i]
    if not id then Events.OnTick.Remove(onTick); say("DONE"); return end
    if t == 2 then
        local ui = UIManager.getUI()
        for k = 0, ui:size() - 1 do local e = ui:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
        local w = ZeD_CharacterWindow.getWindow(); if w and w:isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    end
    if t == 5 then win = openPM(id) end
    if t == 40 then shot(i .. "a_" .. id .. "_vanilla") end
    if t == 42 then
        local ok, rep = pcall(function() return fit(win.children.body.children.printMedia) end)
        if ok then for _, r in ipairs(rep) do say(id .. " " .. r) end else say("ERR " .. tostring(rep)) end
    end
    if t == 70 then shot(i .. "b_" .. id .. "_fitted") end
    if t == 72 then pcall(function() UIManager.RemoveElement(win.javaObj) end); win = nil; i = i + 1; t = 3 end
end
Events.OnTick.Add(onTick)
say("start")
