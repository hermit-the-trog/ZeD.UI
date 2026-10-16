-- ZeDUI/tools/qa/zedqa_print_typeset.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: a prototype of ZeD typesetting a newspaper page
-- itself instead of vanilla's zoomed page (director: "the headlines ... same
-- size as the article ... the messy zoom system is the crux"). Vanilla draws
-- the page as one picture and shrinks every text block by its own factor. Here
-- the page's art and places stay the game's (paper, pictures, rules, masthead,
-- the small print), but each story is set again in the game's own newspaper
-- faces (Old Standard TT, distance-field): its headline wrapped to the column
-- at headline size (the lead story larger), then the body justified at one
-- size for the whole page, the largest that fits every column. Draws in a plain
-- panel at the reader's size and shoots it beside vanilla's.
-- grep "ZEDQA ts"; Screenshots/zqa_ts_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA ts " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ts_" .. n .. ".png") end) end
local TM = getTextManager()
local BASE = 32                      -- the faces' size in their atlas
local WHITE = getTexture("media/ui/white.png")   -- (nil on 42.21.0: the tilted under-sheets are then left out)

-- ---------------------------------------------------------------------------
-- the layout string as elements (vanilla's own format, PrintMedia.lua)
-- ---------------------------------------------------------------------------
local function parse(s)
    local els, parent = {}, { width = 805, height = 910 }
    for _, val in ipairs(string.split(s, "<")) do
        if val ~= "" then
            local data = string.split(val, ">")
            local e = {}
            for _, kv in ipairs(string.split(data[1], ",")) do
                local t = string.split(kv, ":")
                if t[1] and t[2] then
                    local k, v = string.trim(t[1]), string.trim(t[2])
                    -- (a path keeps its colon-free text; numbers become numbers)
                    if k == "texture" then v = string.trim(string.sub(kv, string.find(kv, ":", 1, true) + 1)) end
                    e[k] = tonumber(v) or v
                end
            end
            e.text = data[2] and data[2]:gsub("%^", "\n") or nil
            if e.type == "parent" then parent.width, parent.height = e.width or 805, e.height or 910
            else els[#els + 1] = e end
        end
    end
    return els, parent
end

local function fontOf(name)
    local f = name and UIFont[name] or nil
    return f or UIFont.SdfOldRegular
end
local function wordW(font, w, size) return TM:MeasureStringX(font, w) * size / BASE end
local function lineH(font, size) return TM:getFontHeight(font) * size / BASE end

-- a text element's box at vanilla's own size
local function textBox(e)
    local f = fontOf(e.font)
    local s = e.scaleY or 1
    local lines, w = 0, 0
    for l in (e.text .. "\n"):gmatch("(.-)\n") do lines = lines + 1; w = math.max(w, TM:MeasureStringX(f, l) * (e.scaleX or 1)) end
    if e.autoWidth then w = e.autoWidth * (e.scaleX or 1) end
    local h = lines * TM:getFontHeight(f) * s
    return { x = (e.x or 0) - (e.pivotX or 0) * w, y = (e.y or 0) - (e.pivotY or 0) * h, w = w, h = h }
end

-- ---------------------------------------------------------------------------
-- stories: a body (regular face with a wrap width) and the bold headline over it
-- ---------------------------------------------------------------------------
local function stories(els, parent)
    local boxes = {}
    for _, e in ipairs(els) do
        if e.type == "text" then e.box = textBox(e)
        elseif e.x and e.y and e.width and e.height and (e.angle or 0) == 0 then
            e.box = { x = e.x - (e.pivotX or 0) * e.width, y = e.y - (e.pivotY or 0) * e.height, w = e.width, h = e.height }
        end
        if e.box then boxes[#boxes + 1] = e end
    end
    local function ov(a, b) return math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x) end
    local list = {}
    for _, e in ipairs(els) do
        if e.type == "text" and e.autoWidth and tostring(e.font):find("Regular", 1, true) and #e.text > 60 then
            local col = { x = e.x, w = e.autoWidth * (e.scaleX or 1) }
            local head, top, bottom = nil, e.box.y, parent.height - 24
            for _, o in ipairs(boxes) do
                if o ~= e and ov(col, o.box) > 2 then
                    if o.box.y + o.box.h <= e.box.y + 2 then
                        if o.type == "text" and tostring(o.font):find("Bold", 1, true) and e.box.y - (o.box.y + o.box.h) < 200 and (o.scaleY or 1) >= 0.6 then
                            if not head or o.box.y > head.box.y then head = o end
                        end
                    elseif o.box.y >= e.box.y + 2 then bottom = math.min(bottom, o.box.y - 10) end
                elseif o.type ~= "text" and o.box.w <= 6 and o.box.h > 60 and (math.abs(o.box.x - col.x) < 30 or math.abs(o.box.x - col.x - col.w) < 30) then
                    if o.box.y < e.box.y + 20 and o.box.y + o.box.h > e.box.y then bottom = math.min(bottom, o.box.y + o.box.h - 4) end
                end
            end
            if head then top = head.box.y end
            -- the column is the gap the body really has: anything beside it in its height narrows it
            for _, o in ipairs(boxes) do
                if o ~= e and o ~= head and o.box.w < parent.width * 0.8 and o.box.h > 4 and o.box.y < bottom and o.box.y + o.box.h > top then
                    local ox1, ox2 = o.box.x, o.box.x + o.box.w
                    if ox2 > col.x + 6 and ox1 < col.x + col.w - 6 then
                        if ox1 > col.x + 6 then col.w = ox1 - 10 - col.x
                        elseif ox2 < col.x + col.w - 6 then local r = col.x + col.w; col.x = ox2 + 10; col.w = r - col.x end
                    end
                end
            end
            -- the byline lines between the headline and the body ("By Molly Aoide", "Staff Writer")
            local bylines = {}
            if head then
                for _, o in ipairs(boxes) do
                    if o.type == "text" and o ~= e and o ~= head and not o.taken and ov(col, o.box) > 2
                        and o.box.y >= head.box.y + head.box.h - 4 and o.box.y + o.box.h <= e.box.y + 4 and #o.text < 60 then
                        bylines[#bylines + 1] = o
                        o.taken = true
                    end
                end
                table.sort(bylines, function(a, b2) return a.box.y < b2.box.y end)
            end
            list[#list + 1] = { body = e, head = head, bylines = bylines, x = col.x, w = col.w, hw = head and math.max(col.w, head.box.w) or col.w,
                                center = head and (head.pivotX or 0) == 0.5, cx = head and head.x, top = top, bottom = bottom, lead = head and (head.scaleY or 1) >= 1 }
            if head then head.taken = true end
            e.taken = true
        end
    end
    return list
end

-- ---------------------------------------------------------------------------
-- setting type: words to lines, lines to a column
-- ---------------------------------------------------------------------------
local function cleanBody(t)
    t = t:gsub("(%a)%- (%l)", "%1%2")                      -- vanilla's own hyphen breaks ("rebuild- ing")
    t = t:gsub("\n", " ")
    t = t:gsub("([%.%!%?\"%)])%s%s%s%s+", "%1\n")             -- a run of spaces after a sentence: its paragraph indent
    t = t:gsub("%s%s+", " ")                                    -- (elsewhere they were its justification)
    return t
end

-- paragraphs of words into lines at width w; each line { words, width, last }
local function wrap(text, font, size, w, indent)
    local lines = {}
    -- (a space measures next to nothing in these faces: at least a quarter of the size)
    local space = math.max(wordW(font, "a a", size) - wordW(font, "aa", size), size * ((font == UIFont.SdfOldBold) and 0.2 or 0.27))
    for para in (text .. "\n"):gmatch("(.-)\n") do
        local words = {}
        for wd in para:gmatch("%S+") do words[#words + 1] = wd end
        local cur, cw, first = {}, 0, true
        local function flush(last)
            if #cur > 0 then lines[#lines + 1] = { words = cur, width = cw, last = last, indent = first and indent or 0, space = space }; first = false end
            cur, cw = {}, 0
        end
        for _, wd in ipairs(words) do
            local ww = wordW(font, wd, size)
            local lim = w - (first and indent or 0)
            if #cur > 0 and cw + space + ww > lim then flush(false) end
            cw = cw + ((#cur > 0) and space or 0) + ww
            cur[#cur + 1] = wd
        end
        flush(true)
    end
    return lines, space
end

local SIZES = { lead = 52, head = 34 }
local LEAD = 1.0       -- the faces' own line height (41 at 32) is already newspaper-tight

-- one story's setting at body size b: its headline, then its lines; returns the height used
local function setStory(st, b, out)
    local y = st.top
    if st.head then
        local hs = st.lead and SIZES.lead or SIZES.head
        local hf = UIFont.SdfOldBold
        local lines = wrap(st.head.text:gsub("\n", " "), hf, hs, st.hw, 0)
        while #lines > (st.lead and 4 or 3) and hs > 20 do hs = hs - 1; lines = wrap(st.head.text:gsub("\n", " "), hf, hs, st.hw, 0) end
        for _, l in ipairs(lines) do
            -- (a headline the paper centred stays centred on its own middle)
            local hx = st.center and (st.cx - l.width / 2) or st.head.box.x
            if out then out[#out + 1] = { kind = "line", line = l, x = hx, y = y, size = hs, font = hf, w = st.hw, ragged = true } end
            y = y + lineH(hf, hs) * 0.86
        end
        y = y + b * 0.5
        -- the byline: small, under the headline
        for _, by in ipairs(st.bylines or {}) do
            local bs = math.max(14, b * 0.62)
            for _, l in ipairs(wrap(by.text:gsub("\n", " "), UIFont.SdfOldItalic, bs, st.w, 0)) do
                if out then out[#out + 1] = { kind = "line", line = l, x = st.x, y = y, size = bs, font = UIFont.SdfOldItalic, w = st.w, ragged = true } end
                y = y + lineH(UIFont.SdfOldItalic, bs)
            end
        end
        y = y + b * 0.5
    end
    local bf = UIFont.SdfOldRegular
    local lines = wrap(cleanBody(st.body.text), bf, b, st.w, b * 1.2)
    for _, l in ipairs(lines) do
        if out then out[#out + 1] = { kind = "line", line = l, x = st.x, y = y, size = b, font = bf, w = st.w, ragged = st.w / (b * 0.45) < 30 } end
        y = y + lineH(bf, b) * LEAD
    end
    return y - st.top
end

-- the page's body size: the largest that fits every story's column
local function typeset(els, parent)
    local list = stories(els, parent)
    -- (no narrower than about 30 letters a line: wide gaps open in a justified line below that)
    local b = 40
    for _, st in ipairs(list) do b = math.min(b, st.w / 6.5) end
    while b > 12 do
        local ok = true
        for _, st in ipairs(list) do if setStory(st, b, nil) > st.bottom - st.top then ok = false end end
        if ok then break end
        b = b - 0.5
    end
    local out = {}
    for _, st in ipairs(list) do setStory(st, b, out) end
    return out, b, #list
end

-- ---------------------------------------------------------------------------
-- the panel: the page at one scale, art as the game places it, our lines
-- ---------------------------------------------------------------------------
local Pane = ISPanel:derive("ZeDQA_TypesetPane")
function Pane:prerender()
    local k = self.k
    self:drawRect(0, 0, self.width, self.height, 1, 0.04, 0.05, 0.05)
    -- the paper itself under everything (the tilted under-sheets it shows at its edges are left out)
    self:drawRect(0, 0, self.pw * k, self.ph * k, 1, 0.86, 0.85, 0.83)
    for _, e in ipairs(self.els) do
        if e.type == "texture" and not e.taken then
            local w, h = (e.width or self.pw) * k, (e.height or self.ph) * k
            local x = ((e.x or 0) - (e.pivotX or 0) * (e.width or 0)) * k
            local y = ((e.y or 0) - (e.pivotY or 0) * (e.height or 0)) * k
            local tex = e.texture and getTexture(e.texture) or WHITE
            local a = e.a or 1
            if (e.angle or 0) ~= 0 and not e.texture then
                if WHITE then
                local r = math.rad(e.angle)
                local c, s = math.cos(r), math.sin(r)
                local function pt(px, py) return x + px * c - py * s, y + px * s + py * c end
                local x1, y1 = pt(0, 0); local x2, y2 = pt(w, 0); local x3, y3 = pt(w, h); local x4, y4 = pt(0, h)
                self:drawTextureAllPoint(tex, x1, y1, x2, y2, x3, y3, x4, y4, e.r or 1, e.g or 1, e.b or 1, a)
                end
            elseif e.texture and ((e.scaleX or 1) < 0 or (e.angle or 0) ~= 0) then
                self:drawTextureScaledAspect(tex, 0, 0, self.pw * k, self.ph * k, a * 0.6, e.r or 1, e.g or 1, e.b or 1)
            elseif not e.texture then
                self:drawRect(x, y, w, h, a, e.r or 1, e.g or 1, e.b or 1)   -- (a plain sheet: a fill, never a stretched picture)
            else
                self:drawTextureScaledAspect(tex, x, y, w, h, a, e.r or 1, e.g or 1, e.b or 1)
            end
        elseif e.type == "text" and not e.taken then
            -- the small print stays where and as large as the game prints it
            local f = fontOf(e.font)
            local s = (e.scaleY or 1) * k
            local yy = (e.box.y) * k
            if e.autoWidth then
                -- (a wrapped one: wrapped at its own width, as the game does)
                for _, l in ipairs(wrap(e.text:gsub("\n", " "), f, (e.scaleY or 1) * BASE, e.autoWidth * (e.scaleX or 1), 0)) do
                    self:drawTextZoomed(table.concat(l.words, " "), (e.x or 0) * k, yy, s, e.r or 0, e.g or 0, e.b or 0, e.a or 1, f)
                    yy = yy + TM:getFontHeight(f) * s
                end
            else
            for l in (e.text .. "\n"):gmatch("(.-)\n") do
                local lw = TM:MeasureStringX(f, l) * s
                local lx = ((e.x or 0) - (e.pivotX or 0) * TM:MeasureStringX(f, l) * (e.scaleX or 1)) * k
                self:drawTextZoomed(l, lx, yy, s, e.r or 0, e.g or 0, e.b or 0, e.a or 1, f)
                yy = yy + TM:getFontHeight(f) * s
            end
            end
        end
    end
    -- the stories, set again
    for _, o in ipairs(self.out) do
        local l = o.line
        local z = o.size / BASE * k
        local x = (o.x + l.indent) * k
        local gap = l.space * k
        if not o.ragged and not l.last and #l.words > 1 then
            gap = gap + ((o.w - l.indent - l.width) * k) / (#l.words - 1)
        end
        for _, wd in ipairs(l.words) do
            self:drawTextZoomed(wd, x, o.y * k, z, 0.08, 0.07, 0.06, 1, o.font)
            x = x + TM:MeasureStringX(o.font, wd) * z + gap
        end
    end
end

local function open(id)
    local els, parent = parse(getText("Print_Media_" .. id .. "_info"))
    local out, b, n = typeset(els, parent)
    local H = 852
    local k = H / parent.height
    local pane = Pane:new(0, 0, math.floor(parent.width * k), H)
    pane.els, pane.out, pane.k, pane.pw, pane.ph = els, out, k, parent.width, parent.height
    pane:initialise()
    pane:addToUIManager()
    pane:setX(math.floor((getCore():getScreenWidth() - pane.width) / 2)); pane:setY(95)
    say(id .. " stories " .. n .. " body " .. b .. " lines " .. #out)
    return pane
end

local PAGES = { "KnoxKnews_July1", "KnoxKnews_July2", "KentuckyHerald_July6", "NationalDispatch_July6" }
local t, i, pane = 0, 1, nil
local function onTick()
    t = t + 1
    local id = PAGES[i]
    if not id then Events.OnTick.Remove(onTick); say("DONE"); return end
    if t == 2 then
        local ui = UIManager.getUI()
        for q = 0, ui:size() - 1 do local e = ui:get(q); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
        local w = ZeD_CharacterWindow.getWindow(); if w and w:isVisible() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    end
    if t == 5 then local ok, r = pcall(open, id); if ok then pane = r else say("ERR " .. tostring(r)) end end
    if t == 40 then shot(i .. "_" .. id) end
    if t == 42 then if pane then pane:removeFromUIManager() end; pane = nil; i = i + 1; t = 3 end
end
Events.OnTick.Add(onTick)
say("start")
