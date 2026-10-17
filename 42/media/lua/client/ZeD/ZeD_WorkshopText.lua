-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WorkshopText.lua
-- ============================================================================
-- A WORKSHOP DESCRIPTION AS BLOCKS (director, Oct 16 2026: "edit descriptions
-- with modern layout controls for building communications that people will
-- read")
--
-- Steam stores a description as plain text with its own formatting codes
-- ([h1], [b], [list], [table], ...; 8,000 characters at most). The editor works
-- on blocks instead and writes the codes back out:
--
--   { kind = "h1" | "h2" | "h3" | "text" | "list" | "olist" | "quote" | "code"
--            | "table" | "divider" | "img" | "url" | "spoiler", text = "..." }
--
--   * list / olist: one item per line
--   * table: one row per line, cells split by " | " (the first row is the header)
--   * url: the address on the first line, the words to show on the second
--   * img: the picture's address
--   * text, quote, spoiler, list items and table cells keep inline codes:
--     [b] [i] [u] [strike] [url=...]
--
-- BB.parse reads any description into blocks (what it does not know stays as
-- text, nothing is lost); BB.write writes blocks as Steam's codes; BB.draw*
-- show blocks the way Steam's page does, in the ZeD faces.
-- ============================================================================

ZeD = ZeD or {}
ZeD.BB = ZeD.BB or {}
local BB = ZeD.BB

BB.LIMIT = 8000

-- the blocks the editor offers, in its palette's order: kind, name, a starting text
BB.KINDS = {
    { "h1", "Heading", "Heading" },
    { "text", "Text", "" },
    { "list", "List", "First point\nSecond point" },
    { "olist", "Numbered", "First step\nSecond step" },
    { "img", "Picture", "https://" },
    { "quote", "Quote", "" },
    { "code", "Code", "" },
    { "table", "Table", "Works with | Notes\nAnother mod | How they get along" },
    { "divider", "Divider", "" },
    { "url", "Link", "https://\nWhere it goes" },
    { "spoiler", "Spoiler", "" },
}
BB.NAME = {}
for _, k in ipairs(BB.KINDS) do BB.NAME[k[1]] = k[2] end
BB.NAME.h2, BB.NAME.h3 = "Heading", "Heading"

-- the sections readers look for: a heading and what goes under it
BB.SECTIONS = {
    { "Features", "list", "What it does\nWhat else it does" },
    { "Requirements", "list", "Build 42" },
    { "Load order", "olist", "This mod\nMods that patch it" },
    { "Compatibility", "table", "Works with | Notes\nAnother mod | How they get along" },
    { "Known issues", "list", "" },
    { "Changelog", "list", "1.0: first release" },
    { "Credits", "text", "" },
}

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
BB.trim = trim

local function lines(s)
    local out = {}
    for l in (tostring(s or "") .. "\n"):gmatch("(.-)\r?\n") do out[#out + 1] = l end
    return out
end
BB.lines = lines

local function cells(row)
    local out = {}
    for c in (row .. " | "):gmatch("(.-) | ") do out[#out + 1] = trim(c) end
    if #out == 0 then out[1] = trim(row) end
    return out
end
BB.cells = cells

-- ----------------------------------------------------------------------------
-- BLOCKS TO STEAM'S CODES
-- ----------------------------------------------------------------------------
local function writeBlock(b)
    local k, t = b.kind, tostring(b.text or "")
    if k == "h1" or k == "h2" or k == "h3" then return "[" .. k .. "]" .. trim(t) .. "[/" .. k .. "]" end
    if k == "list" or k == "olist" then
        local out = { "[" .. k .. "]" }
        for _, l in ipairs(lines(t)) do if trim(l) ~= "" then out[#out + 1] = "[*]" .. trim(l) end end
        out[#out + 1] = "[/" .. k .. "]"
        return table.concat(out, "\n")
    end
    if k == "quote" or k == "code" or k == "spoiler" then return "[" .. k .. "]" .. t .. "[/" .. k .. "]" end
    if k == "table" then
        local out = { "[table]" }
        for i, row in ipairs(lines(t)) do
            if trim(row) ~= "" then
                local tag = (i == 1) and "th" or "td"
                local r = "[tr]"
                for _, c in ipairs(cells(row)) do r = r .. "[" .. tag .. "]" .. c .. "[/" .. tag .. "]" end
                out[#out + 1] = r .. "[/tr]"
            end
        end
        out[#out + 1] = "[/table]"
        return table.concat(out, "\n")
    end
    if k == "divider" then return "[hr][/hr]" end
    if k == "img" then return "[img]" .. trim(t) .. "[/img]" end
    if k == "url" then
        local l = lines(t)
        local addr, words = trim(l[1]), trim(l[2] or "")
        if words == "" then words = addr end
        return "[url=" .. addr .. "]" .. words .. "[/url]"
    end
    return t
end

function BB.write(blocks)
    local out = {}
    for _, b in ipairs(blocks or {}) do
        local s = writeBlock(b)
        if s ~= "" then out[#out + 1] = s end
    end
    return table.concat(out, "\n\n")
end

-- ----------------------------------------------------------------------------
-- STEAM'S CODES TO BLOCKS
-- ----------------------------------------------------------------------------
local BLOCK_TAGS = { h1 = true, h2 = true, h3 = true, list = true, olist = true, quote = true, code = true,
                     table = true, hr = true, img = true, spoiler = true }

local function addText(blocks, s)
    -- paragraphs split on blank lines; a [url] alone on its paragraph becomes a link block
    for para in (s .. "\n\n"):gmatch("(.-)\n%s*\n") do
        local p = trim(para)
        if p ~= "" then
            local addr, words = p:match("^%[url=([^%]]+)%](.-)%[/url%]$")
            if addr and not words:find("[", 1, true) then blocks[#blocks + 1] = { kind = "url", text = addr .. "\n" .. words }
            else blocks[#blocks + 1] = { kind = "text", text = p } end
        end
    end
end

function BB.parse(s)
    s = tostring(s or ""):gsub("\r\n", "\n")
    local blocks = {}
    local pos = 1
    while pos <= #s do
        -- the next block-level opening tag
        local a, b, tag = nil, nil, nil
        local from = pos
        while true do
            a, b, tag = s:find("%[(%a+%d?)[^%]]*%]", from)
            if not a then break end
            tag = string.lower(tag)
            if BLOCK_TAGS[tag] then break end
            from = b + 1
        end
        if not a then addText(blocks, s:sub(pos)); break end
        addText(blocks, s:sub(pos, a - 1))
        local close = "[/" .. tag .. "]"
        local ca, cb = string.find(string.lower(s), close, b + 1, true)
        if tag == "hr" then
            blocks[#blocks + 1] = { kind = "divider", text = "" }
            pos = (ca and ca == b + 1) and (cb + 1) or (b + 1)
        elseif not ca then
            addText(blocks, s:sub(a)); break   -- (an unclosed tag: kept as text)
        else
            local inner = s:sub(b + 1, ca - 1)
            if tag == "list" or tag == "olist" then
                local items = {}
                for part in (inner .. "[*]"):gmatch("(.-)%[%*%]") do
                    local t = trim(part)
                    if t ~= "" then items[#items + 1] = (t:gsub("%s*\n%s*", " ")) end
                end
                blocks[#blocks + 1] = { kind = tag, text = table.concat(items, "\n") }
            elseif tag == "table" then
                local rows = {}
                for tr in inner:gmatch("%[tr%](.-)%[/tr%]") do
                    local cs = {}
                    for _, c in tr:gmatch("%[(t[hd])%](.-)%[/t[hd]%]") do cs[#cs + 1] = trim(c) end
                    rows[#rows + 1] = table.concat(cs, " | ")
                end
                blocks[#blocks + 1] = { kind = "table", text = table.concat(rows, "\n") }
            elseif tag == "img" then
                blocks[#blocks + 1] = { kind = "img", text = trim(inner) }
            else
                blocks[#blocks + 1] = { kind = tag, text = (tag == "code") and inner or trim(inner) }
            end
            pos = cb + 1
        end
    end
    return blocks
end

-- the plain words of a description (codes out), for a short preview
function BB.plain(s)
    return trim(tostring(s or ""):gsub("%[img%].-%[/img%]", " "):gsub("%[/?[%a%d%*]+[^%]]*%]", " "):gsub("%s+", " "))
end

-- ----------------------------------------------------------------------------
-- SHOWING IT THE WAY STEAM DOES
-- ----------------------------------------------------------------------------
-- inline codes as runs: { word, bold, italic, under, strike, link }
local function runs(text)
    local out = {}
    local st = { b = 0, i = 0, u = 0, s = 0, url = 0 }
    local pos = 1
    local s = tostring(text or "")
    while pos <= #s do
        local a, b, close, tag = s:find("%[(/?)(%a+)[^%]]*%]", pos)
        local chunk = s:sub(pos, (a or (#s + 1)) - 1)
        for word, space in chunk:gmatch("(%S+)(%s*)") do
            out[#out + 1] = { w = word, b = st.b > 0, i = st.i > 0, u = st.u > 0, s = st.s > 0, link = st.url > 0, sp = space ~= "", nl = space:find("\n", 1, true) ~= nil }
        end
        if chunk:match("^%s") and #out > 0 then out[#out].sp = true end
        if not a then break end
        tag = string.lower(tag)
        local d = (close == "/") and -1 or 1
        if tag == "b" then st.b = math.max(0, st.b + d)
        elseif tag == "i" then st.i = math.max(0, st.i + d)
        elseif tag == "u" then st.u = math.max(0, st.u + d)
        elseif tag == "strike" then st.s = math.max(0, st.s + d)
        elseif tag == "url" then st.url = math.max(0, st.url + d) end
        pos = b + 1
    end
    return out
end

-- inline text, wrapped to w; draws when p is given; returns the height
function BB.rich(p, text, x, y, w, font, color)
    local T = ZeD.T
    local tm = ZeD.TM
    local lh = tm:getFontHeight(font) + T.px(3)
    local spW = tm:MeasureStringX(font, "a a") - tm:MeasureStringX(font, "aa")   -- (a lone space measures 0)
    local cx, cy = x, y
    local rs = runs(text)
    for i, r in ipairs(rs) do
        local ww = tm:MeasureStringX(font, r.w) + (r.b and 1 or 0)
        if cx > x and cx + ww > x + w then cx = x; cy = cy + lh end
        if p then
            local c = color
            if r.link then c = T.info elseif r.i then c = T.textDim elseif r.b then c = T.textHead end
            p:drawText(r.w, cx, cy, c.r, c.g, c.b, c.a or 1, font)
            if r.b then p:drawText(r.w, cx + 1, cy, c.r, c.g, c.b, c.a or 1, font) end   -- (no bold face: drawn twice, a pixel apart)
            local fh = tm:getFontHeight(font)
            if r.u or r.link then p:drawRect(cx, cy + fh - 1, ww, 1, c.a or 1, c.r, c.g, c.b) end
            if r.s then p:drawRect(cx, cy + math.floor(fh / 2) + 1, ww, 1, c.a or 1, c.r, c.g, c.b) end
        end
        cx = cx + ww
        if r.nl then cx = x; cy = cy + lh
        elseif r.sp and i < #rs then cx = cx + spW end
    end
    return (cy - y) + lh
end

-- one block as Steam shows it; draws when p is given; returns its height
function BB.drawBlock(p, b, x, y, w)
    local T = ZeD.T
    local tm = ZeD.TM
    local f2, f3, f1 = T.fontF2, T.fontF3, T.fontF1
    local k, t = b.kind, tostring(b.text or "")
    local txt, dim, head, bs = T.text, T.textDim, T.textHead, T.borderS
    if k == "h1" then
        local hf = ZeD.Font.sdf.head
        local z = 20 * (T.scale or 1) / (hf.face or 64)
        local h = math.floor(ZeD.Text.height(hf, z))
        local yy = y
        for _, l in ipairs(ZeD.Atoms.wrapText(trim(t), T.fontF4, w)) do
            if p then ZeD.Text.draw(p, hf, l, x, yy, z, head.r, head.g, head.b, head.a or 1, "l") end
            yy = yy + h
        end
        return yy - y + T.px(4)
    end
    if k == "h2" or k == "h3" then
        local f = (k == "h2") and T.fontF4 or f1
        local c = (k == "h2") and head or T.accent
        local yy = y
        for _, l in ipairs(ZeD.Atoms.wrapText(trim(t), f, w)) do
            if p then p:drawText(l, x, yy, c.r, c.g, c.b, c.a or 1, f) end
            yy = yy + tm:getFontHeight(f) + T.px(2)
        end
        return yy - y + T.px(2)
    end
    if k == "list" or k == "olist" then
        local yy = y
        local n = 0
        local ind = T.px(18)
        for _, l in ipairs(lines(t)) do
            if trim(l) ~= "" then
                n = n + 1
                if p then
                    if k == "list" then
                        local sq = T.px(4)
                        p:drawRect(x + T.px(6), yy + math.floor((tm:getFontHeight(f2) - sq) / 2), sq, sq, txt.a or 1, txt.r, txt.g, txt.b)
                    else
                        p:drawText(n .. ".", x, yy, txt.r, txt.g, txt.b, txt.a or 1, f2)
                    end
                end
                yy = yy + BB.rich(p, trim(l), x + ind, yy, w - ind, f2, txt)
            end
        end
        return yy - y
    end
    if k == "quote" or k == "spoiler" or k == "code" then
        local pad = T.px(8)
        local font = (k == "code") and f3 or f2
        local inner
        if k == "code" then
            inner = 0
            for _, l in ipairs(lines(t)) do inner = inner + tm:getFontHeight(f3) + T.px(2) end
        else inner = BB.rich(nil, t, 0, 0, w - pad * 2, font, txt) end
        local h = inner + pad * 2
        if p then
            local s2 = (k == "spoiler") and { r = 0, g = 0, b = 0 } or T.surf2
            p:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
            p:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
            if k == "code" then
                local yy = y + pad
                for _, l in ipairs(lines(t)) do
                    p:drawText(ZeD.Atoms.truncateText(l, f3, w - pad * 2), x + pad, yy, txt.r, txt.g, txt.b, txt.a or 1, f3)
                    yy = yy + tm:getFontHeight(f3) + T.px(2)
                end
            elseif k == "spoiler" then
                -- Steam hides it until the pointer is over it: the words drawn faint on black
                BB.rich(p, t, x + pad, y + pad, w - pad * 2, font, { r = 0.22, g = 0.22, b = 0.22, a = 1 })
            else
                BB.rich(p, t, x + pad, y + pad, w - pad * 2, font, txt)
            end
        end
        return h
    end
    if k == "table" then
        local rows = {}
        for _, l in ipairs(lines(t)) do if trim(l) ~= "" then rows[#rows + 1] = cells(l) end end
        local ncol = 1
        for _, r in ipairs(rows) do ncol = math.max(ncol, #r) end
        local cw = math.floor(w / ncol)
        local pad = T.px(5)
        local yy = y
        for i, r in ipairs(rows) do
            local rh = 0
            for c = 1, ncol do rh = math.max(rh, BB.rich(nil, r[c] or "", 0, 0, cw - pad * 2, f2, txt)) end
            rh = rh + pad * 2
            if p then
                if i == 1 then local s2 = T.surf2; p:drawRect(x, yy, w, rh, 1, s2.r, s2.g, s2.b) end
                for c = 1, ncol do
                    local cx = x + (c - 1) * cw
                    p:drawRectBorder(cx, yy, (c == ncol) and (w - (c - 1) * cw) or cw, rh, bs.a, bs.r, bs.g, bs.b)
                    BB.rich(p, (i == 1) and ("[b]" .. (r[c] or "") .. "[/b]") or (r[c] or ""), cx + pad, yy + pad, cw - pad * 2, f2, txt)
                end
            end
            yy = yy + rh - T.px(1)
        end
        return yy - y + T.px(1)
    end
    if k == "divider" then
        if p then p:drawRect(x, y + T.px(6), w, T.px(1), bs.a, bs.r, bs.g, bs.b) end
        return T.px(13)
    end
    if k == "img" then
        -- (Steam fetches the picture from its address; the screen shows where it comes from)
        local h = T.px(56)
        if p then
            p:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
            local name = trim(t):match("([^/]+)$") or trim(t)
            local s = "Picture: " .. ((name ~= "" and name ~= "https:") and name or "no address yet")
            p:drawText(ZeD.Atoms.truncateText(s, f3, w - T.px(16)), x + T.px(8), y + math.floor((h - tm:getFontHeight(f3)) / 2), dim.r, dim.g, dim.b, dim.a or 1, f3)
        end
        return h
    end
    if k == "url" then
        local l = lines(t)
        local words = trim(l[2] or "")
        if words == "" then words = trim(l[1]) end
        return BB.rich(p, "[url=" .. trim(l[1]) .. "]" .. words .. "[/url]", x, y, w, f2, txt)
    end
    return BB.rich(p, t, x, y, w, f2, txt)
end

-- the space Steam leaves after a block
function BB.gap(b)
    local T = ZeD.T
    if b.kind == "h1" or b.kind == "h2" or b.kind == "h3" then return T.px(4) end
    return T.px(10)
end

-- 8000 as "8,000"
function BB.count(n)
    local s = tostring(math.floor(n or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if out:sub(1, 1) == "," then out = out:sub(2) end
    return out
end
