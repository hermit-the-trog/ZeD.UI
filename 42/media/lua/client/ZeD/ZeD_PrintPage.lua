-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PrintPage.lua
-- ============================================================================
-- A PRINTED PIECE, SET BY ZeD (HOOK_MAP row 13; mockup zed_reader_v2; director,
-- Oct 16 2026: "the headlines ... same size as the article ... the messy zoom
-- system is the crux")
--
-- Vanilla draws a newspaper or flyer as one picture (PZAPI PrintMedia, from the
-- Print_Media_<id>_info layout) and shrinks every text block by its own factor,
-- so a headline can come out the size of the story under it. ZeD keeps the
-- page's art and places (the paper, the pictures, the rules, the masthead, the
-- small print) and sets each story again, in the paper's own faces (Old
-- Standard TT, distance-field):
--   * the headline wrapped to its column (the lead story's larger; a headline the
--     paper centred stays centred), the byline small under it;
--   * the body in one size for the whole page, the largest that fits every
--     column, ragged-right (narrow columns never open gaps).
-- The page is laid out once in page units; P.draw paints it at any scale and
-- offset, so the reader's zoom is one number for everything.
--
-- Also here: the piece's words for the reader's Words view (Print_Text_<id>_info
-- as headings, paragraphs, picture captions), and its places
-- (PrintMediaDefinitions.MiscDetails: up to five, each a set of squares) with
-- vanilla's own Show on map (the squares marked known, then its read-map
-- action, which opens ZeD's map there).
-- ============================================================================

ZeD = ZeD or {}
ZeD.Print = ZeD.Print or {}
local P = ZeD.Print

local BASE = 32                                    -- the faces' size in their atlas
local SIZES = { lead = 52, head = 34 }
local GAP, FOOT = 10, 24
local TM = getTextManager()

local function fontOf(name) return (name and UIFont[name]) or UIFont.SdfOldRegular end
local function wordW(font, w, size) return TM:MeasureStringX(font, w) * size / BASE end
local function lineH(font, size) return TM:getFontHeight(font) * size / BASE end

-- ---------------------------------------------------------------------------
-- the piece's data (an item's modData.printMedia, or an id)
-- ---------------------------------------------------------------------------
function P.media(item)
    local md = item and item.getModData and item:getModData()
    return md and md.printMedia or nil
end
function P.ofId(id)
    local m = { id = id, title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" }
    -- the game's own keys from its registry (a piece's keys use its proper name,
    -- "Print_Media_SunstarMotel_title" for sunstarmotel), as vanilla's world map
    pcall(function()
        local loc = ResourceLocation.of(id)
        local v = Brochure.get(loc) or Flier.get(loc)
        if v then m.title, m.info, m.text = v:getTranslationKey(), v:getTranslationInfoKey(), v:getTranslationTextKey() end
    end)
    return m
end
function P.title(m) return m and (getTextOrNull(m.title) or m.id) or "" end

-- what kind of paper it is, by the item that carries it
function P.kind(item)
    local t = item and item:getType() or ""
    if t:find("Newspaper", 1, true) then return "Newspaper" end
    if t:find("Brochure", 1, true) then return "Brochure" end
    if t:find("Flier", 1, true) or t:find("Flyer", 1, true) then return "Flyer" end
    if t:find("Magazine", 1, true) then return "Magazine" end
    return "Paper"
end

-- what P.kind answered, in the player's language (the answer itself is an id, compared in code)
function P.kindName(kind)
    if kind == "Newspaper" then return getText("IGUI_NewUI_Newspaper") end
    if kind == "Brochure" then return getText("IGUI_NewUI_Brochure") end
    if kind == "Flyer" then return ZeD.tr("UI_ZeD_Print_Flyer") end
    if kind == "Magazine" then return getText("ContextMenu_Magazine") end
    return ZeD.tr("UI_ZeD_Print_Paper")
end

-- ---------------------------------------------------------------------------
-- the layout string (vanilla's own format, PrintMedia.lua)
-- ---------------------------------------------------------------------------
local function parse(s)
    local els, parent = {}, { width = 805, height = 910 }
    for _, val in ipairs(string.split(s or "", "<")) do
        if val ~= "" then
            local data = string.split(val, ">")
            local e = {}
            for _, kv in ipairs(string.split(data[1], ",")) do
                local t = string.split(kv, ":")
                if t[1] and t[2] then
                    local k = string.trim(t[1])
                    local v = string.trim(string.sub(kv, string.find(kv, ":", 1, true) + 1))
                    e[k] = tonumber(v) or v
                end
            end
            e.text = data[2] and (data[2]:gsub("%^", "\n")) or nil
            if e.type == "parent" then parent.width, parent.height = e.width or 805, e.height or 910
            elseif e.type then els[#els + 1] = e end
        end
    end
    return els, parent
end

local function textBox(e)
    local f = fontOf(e.font)
    local lines, w = 0, 0
    for l in (e.text .. "\n"):gmatch("(.-)\n") do lines = lines + 1; w = math.max(w, TM:MeasureStringX(f, l) * (e.scaleX or 1)) end
    if e.autoWidth then w = e.autoWidth * (e.scaleX or 1) end
    local h = lines * TM:getFontHeight(f) * (e.scaleY or 1)
    return { x = (e.x or 0) - (e.pivotX or 0) * w, y = (e.y or 0) - (e.pivotY or 0) * h, w = w, h = h }
end

local function ov(a, b) return math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x) end
local function isBold(e) return e.type == "text" and tostring(e.font):find("Bold", 1, true) ~= nil end

-- ---------------------------------------------------------------------------
-- stories: a body (a regular face with a wrap width), the bold headline over it,
-- the byline lines between them, the column it really has
-- ---------------------------------------------------------------------------
local function stories(els, parent)
    local boxes = {}
    for _, e in ipairs(els) do
        if e.type == "text" and e.text then e.box = textBox(e)
        elseif e.x and e.y and e.width and e.height and (e.angle or 0) == 0 then
            e.box = { x = e.x - (e.pivotX or 0) * e.width, y = e.y - (e.pivotY or 0) * e.height, w = e.width, h = e.height }
        end
        if e.box then boxes[#boxes + 1] = e end
    end
    local list = {}
    for _, e in ipairs(els) do
        if e.type == "text" and e.text and e.autoWidth and tostring(e.font):find("Regular", 1, true) and #e.text > 60 then
            local col = { x = e.x, w = e.autoWidth * (e.scaleX or 1) }
            local head, bottom = nil, parent.height - FOOT
            for _, o in ipairs(boxes) do
                if o ~= e and ov(col, o.box) > 2 then
                    if o.box.y + o.box.h <= e.box.y + 2 then
                        if isBold(o) and e.box.y - (o.box.y + o.box.h) < 200 and (o.scaleY or 1) >= 0.6 then
                            if not head or o.box.y > head.box.y then head = o end
                        end
                    elseif o.box.y >= e.box.y + 2 then bottom = math.min(bottom, o.box.y - GAP) end
                elseif o.type ~= "text" and o.box.w <= 6 and o.box.h > 60 and (math.abs(o.box.x - col.x) < 30 or math.abs(o.box.x - col.x - col.w) < 30) then
                    if o.box.y < e.box.y + 20 and o.box.y + o.box.h > e.box.y then bottom = math.min(bottom, o.box.y + o.box.h - 4) end
                end
            end
            local top = head and head.box.y or e.box.y
            -- the column is the gap the body really has: anything beside it narrows it
            for _, o in ipairs(boxes) do
                if o ~= e and o ~= head and o.box.w < parent.width * 0.8 and o.box.h > 4 and o.box.y < bottom and o.box.y + o.box.h > top then
                    local ox1, ox2 = o.box.x, o.box.x + o.box.w
                    if ox2 > col.x + 6 and ox1 < col.x + col.w - 6 then
                        if ox1 > col.x + 6 then col.w = ox1 - 10 - col.x
                        elseif ox2 < col.x + col.w - 6 then local r = col.x + col.w; col.x = ox2 + 10; col.w = r - col.x end
                    end
                end
            end
            local bylines = {}
            if head then
                for _, o in ipairs(boxes) do
                    if o.type == "text" and o ~= e and o ~= head and not o.taken and ov(col, o.box) > 2
                        and o.box.y >= head.box.y + head.box.h - 4 and o.box.y + o.box.h <= e.box.y + 4 and #o.text < 60 then
                        bylines[#bylines + 1] = o
                        o.taken = true
                    end
                end
                table.sort(bylines, function(a, b) return a.box.y < b.box.y end)
                head.taken = true
            end
            e.taken = true
            list[#list + 1] = { body = e, head = head, bylines = bylines, x = col.x, w = col.w,
                                hw = head and math.max(col.w, head.box.w) or col.w,
                                center = head and (head.pivotX or 0) == 0.5, cx = head and head.x,
                                top = top, bottom = bottom, lead = head and (head.scaleY or 1) >= 1 }
        end
    end
    return list
end

-- ---------------------------------------------------------------------------
-- setting type
-- ---------------------------------------------------------------------------
local function cleanBody(t)
    t = t:gsub("(%a)%- (%l)", "%1%2")                            -- vanilla's own hyphen breaks ("rebuild- ing")
    t = t:gsub("\n", " ")
    t = t:gsub("([%.%!%?\"%)])%s%s%s%s+", "%1\n")                  -- spaces after a sentence: a paragraph's indent
    t = t:gsub("%s%s+", " ")                                       -- (elsewhere they justified vanilla's lines)
    return t
end

-- words into lines at width w; each line { words, width, last, indent, space }
local function wrap(text, font, size, w, indent)
    local lines = {}
    -- (a space measures next to nothing in these faces)
    local space = math.max(wordW(font, "a a", size) - wordW(font, "aa", size), size * ((font == UIFont.SdfOldBold) and 0.2 or 0.27))
    for para in (text .. "\n"):gmatch("(.-)\n") do
        local cur, cw, first = {}, 0, true
        local function flush(last)
            if #cur > 0 then lines[#lines + 1] = { words = cur, width = cw, last = last, indent = first and indent or 0, space = space }; first = false end
            cur, cw = {}, 0
        end
        for wd in para:gmatch("%S+") do
            local ww = wordW(font, wd, size)
            local lim = w - (first and indent or 0)
            if #cur > 0 and cw + space + ww > lim then flush(false) end
            cw = cw + ((#cur > 0) and space or 0) + ww
            cur[#cur + 1] = wd
        end
        flush(true)
    end
    return lines
end
P.wrap = wrap

-- one story at body size b: its headline, byline and body; returns the height used
local function setStory(st, b, out)
    local y = st.top
    if st.head then
        local hs = st.lead and SIZES.lead or SIZES.head
        local hf = UIFont.SdfOldBold
        local htext = st.head.text:gsub("\n", " ")
        local lines = wrap(htext, hf, hs, st.hw, 0)
        while #lines > (st.lead and 4 or 3) and hs > 20 do hs = hs - 1; lines = wrap(htext, hf, hs, st.hw, 0) end
        for _, l in ipairs(lines) do
            local hx = st.center and (st.cx - l.width / 2) or st.head.box.x
            if out then out[#out + 1] = { line = l, x = hx, y = y, size = hs, font = hf, ragged = true } end
            y = y + lineH(hf, hs) * 0.86
        end
        y = y + b * 0.5
        for _, by in ipairs(st.bylines) do
            local bs = math.max(14, b * 0.62)
            for _, l in ipairs(wrap(by.text:gsub("\n", " "), UIFont.SdfOldItalic, bs, st.w, 0)) do
                if out then out[#out + 1] = { line = l, x = st.x, y = y, size = bs, font = UIFont.SdfOldItalic, ragged = true } end
                y = y + lineH(UIFont.SdfOldItalic, bs)
            end
        end
        y = y + b * 0.5
    end
    local bf = UIFont.SdfOldRegular
    for _, l in ipairs(wrap(cleanBody(st.body.text), bf, b, st.w, b * 1.2)) do
        if out then out[#out + 1] = { line = l, x = st.x, y = y, size = b, font = bf, ragged = true } end
        y = y + lineH(bf, b)
    end
    return y - st.top
end

-- the page, laid out once per piece (and per face set: a theme change cannot move it)
local cache = {}
function P.page(m)
    if not m then return nil end
    local c = cache[m.id]
    if c then return c end
    local info = getTextOrNull(m.info)
    if not info then return nil end
    local els, parent = parse(info)
    local list = stories(els, parent)
    -- the body: no larger than about 25 letters to a column's line, then the largest that fits every column
    local b = 40
    for _, st in ipairs(list) do b = math.min(b, st.w / 6.5) end
    while b > 12 do
        local ok = true
        for _, st in ipairs(list) do if setStory(st, b, nil) > st.bottom - st.top then ok = false; break end end
        if ok then break end
        b = b - 0.5
    end
    local out = {}
    for _, st in ipairs(list) do setStory(st, b, out) end
    c = { els = els, w = parent.width, h = parent.height, lines = out, stories = list, body = b }
    cache[m.id] = c
    return c
end

-- the page painted at scale k with its top-left at (ox, oy) in the panel
function P.draw(panel, pg, ox, oy, k)
    panel:drawRect(ox, oy, pg.w * k, pg.h * k, 1, 0.86, 0.85, 0.83)   -- the paper itself, under everything
    for _, e in ipairs(pg.els) do
        if e.type == "texture" and not e.taken then
            -- (the tilted under-sheets and the mirrored wrinkle overlays are left out: the paper is drawn plain)
            if (e.angle or 0) == 0 and (e.scaleX or 1) > 0 and (e.scaleY or 1) > 0 then
                local w, h = (e.width or pg.w) * k, (e.height or pg.h) * k
                local x = ox + ((e.x or 0) - (e.pivotX or 0) * (e.width or 0)) * k
                local y = oy + ((e.y or 0) - (e.pivotY or 0) * (e.height or 0)) * k
                if e.texture then
                    local tex = getTexture(e.texture)
                    if tex then panel:drawTextureScaledAspect(tex, x, y, w, h, e.a or 1, e.r or 1, e.g or 1, e.b or 1) end
                else
                    panel:drawRect(x, y, w, h, e.a or 1, e.r or 1, e.g or 1, e.b or 1)
                end
            end
        elseif e.type == "text" and e.text and not e.taken then
            -- the small print stays where, and as large as, the game prints it
            local f = fontOf(e.font)
            local z = (e.scaleY or 1) * k
            local yy = oy + e.box.y * k
            if e.autoWidth then
                for _, l in ipairs(wrap(e.text:gsub("\n", " "), f, (e.scaleY or 1) * BASE, e.autoWidth * (e.scaleX or 1), 0)) do
                    panel:drawTextZoomed(table.concat(l.words, " "), ox + (e.x or 0) * k, yy, z, e.r or 0, e.g or 0, e.b or 0, e.a or 1, f)
                    yy = yy + TM:getFontHeight(f) * z
                end
            else
                for l in (e.text .. "\n"):gmatch("(.-)\n") do
                    local lx = ox + ((e.x or 0) - (e.pivotX or 0) * TM:MeasureStringX(f, l) * (e.scaleX or 1)) * k
                    panel:drawTextZoomed(l, lx, yy, z, e.r or 0, e.g or 0, e.b or 0, e.a or 1, f)
                    yy = yy + TM:getFontHeight(f) * z
                end
            end
        end
    end
    -- the stories, set by ZeD
    for _, o in ipairs(pg.lines) do
        local l = o.line
        local z = o.size / BASE * k
        local x = ox + (o.x + l.indent) * k
        local gap = l.space * k
        local y = oy + o.y * k
        for _, wd in ipairs(l.words) do
            panel:drawTextZoomed(wd, x, y, z, 0.08, 0.07, 0.06, 1, o.font)
            x = x + TM:MeasureStringX(o.font, wd) * z + gap
        end
    end
end

-- the page's paper and pictures only, no words: a list's thumbnail, and a piece not
-- read yet (reading it is vanilla's timed action; the tab never gives the words away)
function P.drawArt(panel, pg, ox, oy, k, a)
    a = a or 1
    panel:drawRect(ox, oy, pg.w * k, pg.h * k, a, 0.86, 0.85, 0.83)
    for _, e in ipairs(pg.els) do
        if e.type == "texture" and not e.taken and (e.angle or 0) == 0 and (e.scaleX or 1) > 0 and (e.scaleY or 1) > 0 then
            local w, h = (e.width or pg.w) * k, (e.height or pg.h) * k
            local x = ox + ((e.x or 0) - (e.pivotX or 0) * (e.width or 0)) * k
            local y = oy + ((e.y or 0) - (e.pivotY or 0) * (e.height or 0)) * k
            if e.texture then
                local tex = getTexture(e.texture)
                if tex then panel:drawTextureScaledAspect(tex, x, y, w, h, (e.a or 1) * a, e.r or 1, e.g or 1, e.b or 1) end
            else
                panel:drawRect(x, y, w, h, (e.a or 1) * a, e.r or 1, e.g or 1, e.b or 1)
            end
        end
    end
end

-- the stories' headlines, for the reader's side column
function P.headlines(pg)
    local out = {}
    for _, st in ipairs(pg and pg.stories or {}) do
        if st.head then out[#out + 1] = (st.head.text:gsub("\n", " "):gsub("%s+", " ")) end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- THE WORDS (Print_Text_<id>_info): the same piece as headings and paragraphs
-- ---------------------------------------------------------------------------
-- an all-capitals line in the text is a headline; the page's own bold text
-- gives its proper case where one matches
local function properCase(line, pg)
    local key = line:lower():gsub("[^%a%d]", "")
    for _, e in ipairs(pg and pg.els or {}) do
        if isBold(e) and e.text then
            local t = e.text:gsub("\n", " ")
            if t:lower():gsub("[^%a%d]", "") == key then return (t:gsub("%s+", " ")) end
        end
    end
    local s = line:lower()
    return ZeD.upper(s:sub(1, 1)) .. s:sub(2)
end

-- blocks: { kind = "head" | "kicker" | "pic" | "para" | "cont", text }
function P.words(m)
    local raw = m and getTextOrNull(m.text)
    if not raw then return {} end
    raw = raw:gsub("\\n", "\n")
    local pg = P.page(m)
    local blocks = {}
    for line in (raw .. "\n"):gmatch("(.-)\n") do
        local t = line:gsub("^%s+", ""):gsub("%s+$", "")
        if t ~= "" then
            local letters = t:gsub("[^%a]", "")
            if #letters >= 6 and letters == letters:upper() and #t < 90 then
                blocks[#blocks + 1] = { kind = "head", text = properCase(t, pg) }
            elseif t:find("^%[image%]") then
                blocks[#blocks + 1] = { kind = "pic", text = (t:gsub("^%[image%]%s*%-?%s*", "")) }
            elseif t:find("^%(continued") or t:find("^%(See ") then
                blocks[#blocks + 1] = { kind = "cont", text = t }
            elseif t:find("see page %d+$") and #t < 80 then
                blocks[#blocks + 1] = { kind = "kicker", text = t }
            else
                -- a dateline ("FRANKFORT - ...") is set in bold at the paragraph's start
                local d, rest = t:match("^([%u][%u%s,%.']+) %- (.+)$")
                blocks[#blocks + 1] = { kind = "para", text = d and rest or t, dateline = d }
            end
        end
    end
    return blocks
end

-- ---------------------------------------------------------------------------
-- PLACES (vanilla's reveal-on-map, up to five)
-- ---------------------------------------------------------------------------
function P.places(m)
    local out = {}
    local d = m and PrintMediaDefinitions and PrintMediaDefinitions.MiscDetails and PrintMediaDefinitions.MiscDetails[m.id]
    if not d then return out end
    for i = 1, 5 do
        local loc = d["location" .. i]
        if not loc then break end
        out[#out + 1] = loc
    end
    return out
end

local function mapZoom(len)
    if len < 75 then return 17 end
    if len < 75 * 3 then return 16.5 end
    if len < 75 * 9 then return 16.0 end
    if len < 75 * 27 then return 15.5 end
    if len < 75 * 81 then return 14.5 end
    return 14
end

-- vanilla's own Show on map: the squares become known, then its read-map action opens the map there
function P.showOnMap(playerObj, loc)
    local xx, yy, maxLen = 0, 0, 0
    for _, sq in ipairs(loc) do
        WorldMapVisited.getInstance():setKnownInSquares(sq.x1, sq.y1, sq.x2, sq.y2)
        if isClient() then sendClientCommand(playerObj, "map", "setKnownInSquares", { x1 = sq.x1, y1 = sq.y1, x2 = sq.x2, y2 = sq.y2 }) end
        xx = xx + sq.x1 + sq.x2
        yy = yy + sq.y1 + sq.y2
        maxLen = math.max(sq.x2 - sq.x1, sq.y2 - sq.y1, maxLen)
    end
    playerObj:setJoypadIgnoreAimUntilCentered(true)
    ISTimedActionQueue.clear(playerObj)
    ISTimedActionQueue.add(ISReadWorldMap:new(playerObj, xx / (#loc * 2), yy / (#loc * 2), mapZoom(maxLen)))
end
