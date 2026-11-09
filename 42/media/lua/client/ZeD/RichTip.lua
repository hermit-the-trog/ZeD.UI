-- ZeD-UI/42/media/lua/client/ZeD/RichTip.lua
-- ============================================================================
-- A GAME TOOLTIP'S RICH TEXT, READ AS A REQUIREMENT LIST (client; pure Lua).
-- The game writes some option tooltips as ISRichTextPanel rich text. The
-- requirement list on a greyed option (ISDisassembleMenu, the moveables) is two
-- columns: <RGB:r,g,b> label <SETX:n> <INDENT:n> <RGB:r,g,b> value <LINE>, green
-- for what the player has, red for what is missing; a line with an empty label
-- is one more tool for the row above; a line with no <SETX> ("- Has items in
-- container.") is a condition. ZeD's balloon (Balloon.lua) draws it as two
-- columns with a check or cross per row, so this turns the text into rows.
--   RichTip.parse(s, title)  { rows, conds, sig } or nil for text with no color
--                            and no column tag (it stays plain words)
--   RichTip.state(c)         "ok" (the game's good highlight), "bad" (its bad
--                            highlight), nil (white, greys, anything else)
-- ============================================================================

ZeD = ZeD or {}
local RT = ZeD.RichTip or {}
ZeD.RichTip = RT

local function hasRichTag(s)
    return s:find("<RGB:", 1, true) or s:find("<PUSHRGB:", 1, true) or s:find("<SETX:", 1, true)
        or s:find("<RED>", 1, true) or s:find("<GREEN>", 1, true) or s:find("<ORANGE>", 1, true)
        or s:find("<GHC>", 1, true) or s:find("<BHC>", 1, true)
end

local function rgbOf(body)
    local r, g, b = body:match("RGB:%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)")
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not (r and g and b) then return nil end
    return { r = r, g = g, b = b }
end

local function coreColor(getter)
    local ok, c = pcall(function()
        local core = getCore()
        local ci = core[getter](core)
        return { r = ci:getR(), g = ci:getG(), b = ci:getB() }
    end)
    if ok and type(c) == "table" then return c end
    return nil
end

local GOOD_DEF, BAD_DEF = { r = 0, g = 1, b = 0 }, { r = 1, g = 0, b = 0 }
local function near(a, b, tol)
    return math.abs(a.r - b.r) <= tol and math.abs(a.g - b.g) <= tol and math.abs(a.b - b.b) <= tol
end
local function dist2(a, b)
    local dr, dg, db = a.r - b.r, a.g - b.g, a.b - b.b
    return dr * dr + dg * dg + db * db
end

--- A run's color as the game meant it: "ok" when it is the game's good highlight color, "bad" for
--- its bad one, nil for white and greys. The game prints the color with two decimals, so a match is
--- within 0.03. A strong red or green that is neither (a mod's pure <RGB:1,0,0>, <RED>) goes to the nearer;
--- any other color (the game's magenta debug line, a mod's blue) is neutral.
function RT.state(c)
    if not c then return nil end
    local good = coreColor("getGoodHighlitedColor") or GOOD_DEF
    local bad = coreColor("getBadHighlitedColor") or BAD_DEF
    if near(c, good, 0.03) then return "ok" end
    if near(c, bad, 0.03) then return "bad" end
    -- (red or green leads the other two by a clear margin; magenta, cyan, yellow, blue and greys do not)
    local redish = c.r - math.max(c.g, c.b) >= 0.3
    local greenish = c.g - math.max(c.r, c.b) >= 0.3
    if not (redish or greenish) then return nil end
    if dist2(c, good) <= dist2(c, bad) then return "ok" end
    return "bad"
end

-- a label in a color of its own (white and greys are the game's labels): the game's debug line ("SCRIPT NAME:", in
-- magenta, added only with debug on) and lines like it are information, not requirements
local function coloredLabel(runs)
    for _, r in ipairs(runs) do
        if r.c then
            local mx, mn = math.max(r.c.r, r.c.g, r.c.b), math.min(r.c.r, r.c.g, r.c.b)
            return mx - mn >= 0.2
        end
    end
    return false
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function lower(s) return string.lower(trim(tostring(s or ""))) end

-- the text's lines: { setx, label = { runs }, value = { runs } }, each run { t, c }
local function scan(s)
    local lines, cur, color = {}, nil, nil
    local stack = {}
    local function newLine()
        cur = { setx = false, label = {}, value = {} }
        lines[#lines + 1] = cur
    end
    newLine()
    local function add(t)
        t = t:gsub("%s+", " ")
        if t:find("%S") == nil then return end
        local col = cur.setx and cur.value or cur.label
        col[#col + 1] = { t = t, c = color }
    end
    local pos, n = 1, #s
    while pos <= n do
        local a = s:find("<", pos, true)
        local b = a and s:find(">", a + 1, true)
        if not (a and b) then add(s:sub(pos)); break end
        add(s:sub(pos, a - 1))
        local tag = s:sub(a + 1, b - 1)
        local up = string.upper(tag)
        if up == "LINE" or up == "BR" then
            newLine()
        elseif up:sub(1, 5) == "SETX:" then
            cur.setx = true
        elseif up:sub(1, 8) == "PUSHRGB:" then
            stack[#stack + 1] = color or false
            color = rgbOf(up) or color
        elseif up == "POPRGB" then
            if #stack > 0 then color = stack[#stack] or nil; stack[#stack] = nil end
        elseif up:sub(1, 4) == "RGB:" then
            color = rgbOf(up) or color
        elseif up == "RED" then color = { r = 1, g = 0, b = 0 }
        elseif up == "GREEN" then color = { r = 0, g = 1, b = 0 }
        elseif up == "ORANGE" then color = { r = 0.9, g = 0.3, b = 0 }
        elseif up == "GHC" then color = coreColor("getGoodHighlitedColor") or GOOD_DEF
        elseif up == "BHC" then color = coreColor("getBadHighlitedColor") or BAD_DEF
        end
        -- (INDENT, SIZE, TEXT, H1, H2, CENTRE, IMAGE ...: no words of their own; dropped)
        pos = b + 1
    end
    return lines
end

local function join(runs)
    local t = {}
    for i, r in ipairs(runs) do t[i] = trim(r.t) end
    return trim(table.concat(t, " "))
end

-- the state of a column of runs: the first colored run decides
local function stOf(runs)
    for _, r in ipairs(runs) do
        if r.c then return RT.state(r.c) end
    end
    return nil
end

local function rowState(row)
    local any = nil
    for _, v in ipairs(row.values) do
        if v.st == "ok" then return "ok" end
        if v.st == "bad" then any = "bad" end
    end
    return any
end

--- The requirement list in a tooltip's rich text, or nil when the text has no color and no column tag.
--- title = the option's name: a row whose only value repeats it (the game's Name row) is left out.
--- Rows keep the game's order. { rows = { { label, values = { { t, st } }, st } }, conds = { { t, st } },
--- sig = the text (the balloon's layout is kept by it) }
function RT.parse(s, title)
    s = tostring(s or "")
    if not hasRichTag(s) then return nil end
    local lines = scan(s)
    local anySetx = false
    for _, l in ipairs(lines) do if l.setx then anySetx = true end end
    local rows, conds = {}, {}
    local tl = lower(title)
    for _, l in ipairs(lines) do
        local label = join(l.label)
        if anySetx and l.setx and label ~= "" and coloredLabel(l.label) then
            -- an information line (the game's debug "SCRIPT NAME: furniture_storage_02_0"): plain words, no
            -- column and no mark, as the game shows it (only with debug on: the game adds it only then)
            local value = join(l.value)
            conds[#conds + 1] = { t = (value ~= "") and (label .. " " .. value) or label, st = nil, info = true }
        elseif anySetx and l.setx then
            local value = join(l.value)
            local st = stOf(l.value) or stOf(l.label)
            if label == "" then
                -- one more value for the row above (the game lists each tool that does)
                local last = rows[#rows]
                if last and value ~= "" then
                    last.values[#last.values + 1] = { t = value, st = st }
                    last.st = rowState(last)
                elseif value ~= "" then
                    rows[#rows + 1] = { label = "", values = { { t = value, st = st } }, st = st }
                end
            elseif value ~= "" or label ~= "" then
                local lab = label:gsub("%s*:$", "")
                rows[#rows + 1] = { label = lab, values = { { t = value, st = st } }, st = st }
            end
        elseif label ~= "" then
            -- a condition, or (no column anywhere) a plain line; the game's leading "- " goes
            local t = label:gsub("^%-%s*", "")
            if t ~= "" then conds[#conds + 1] = { t = t, st = stOf(l.label) } end
        end
    end
    -- the Name row says what the title says
    if tl ~= "" then
        for i = #rows, 1, -1 do
            local r = rows[i]
            if #r.values == 1 and lower(r.values[1].t) == tl then table.remove(rows, i) end
        end
    end
    if #rows == 0 and #conds == 0 then return nil end
    return { rows = rows, conds = conds, sig = s .. "\1" .. tostring(title or "") }
end

return RT
