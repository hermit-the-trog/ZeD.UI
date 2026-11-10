-- ZeDUI/tools/qa/strip_page_sim.lua  (Nov 10 2026, Build; punch list 133, the strip pages by whole icons)
-- With no game running, the real ZeD_ContextMenu.lua runs on stubs (a panel base, a clock, the strip's tokens at 1x
-- and 1.75x). It checks, for strips of 11 to 31 cells (10 show at once):
--   WHOLE  once a slide ends the window holds whole cells: the track's offset is a whole number of cells, the window
--          starts on a cell's left edge and ends on one's right edge (it used to centre the anchor cell, which with
--          10 showing left half a cell at each end)
--   PAGE   an arrow click moves the window by 10 cells, the selection to the cell in the anchor's slot; the cells
--          shown after a page are the 10 after the ones shown before (none skipped, none repeated); 3 pages forward
--          and 3 back return to the first window; two clicks before a slide settles stay inside the track's three
--          copies; the left arrow pages back the same way
--   STEP   the keyboard's and pad's one step still moves one cell, the window still whole
--   SHORT  a strip that doesn't overflow (10 or fewer) steps one cell per arrow, as before
-- What it can't show: the slide on screen (QA: click an overflowing strip's arrows at 1x and 1.75x).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/strip_page_sim.lua
-- It prints FAIL lines and a last line "strip_page_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]strip_page_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
local NOW = 0
getTimestampMs = function() return NOW end
ZeD_Panel = { derive = function(self, name) return setmetatable({ Type = name }, { __index = self }) end, update = function() end }
ZeD = setmetatable({ ContextMenu = { Registry = { getPinnedIds = function() return {} end } } }, { __index = function() return stub end })

local fn, err = loadfile(CLIENT .. "ZeD_ContextMenu.lua")
check("ZeD_ContextMenu.lua compiles", fn, err)
if not fn then print("strip_page_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
setmetatable(_G, { __index = function() return stub end })
local okL, errL = pcall(fn)
setmetatable(_G, nil)
check("ZeD_ContextMenu.lua loads on the stubs", okL, errL)
local CM = ZeD_ContextMenu

local function tokens(scale)
    local px = function(v) return math.floor(v * scale + 0.5) end
    return { px = px, ctx = { cellW = px(22), cellH = px(22), gap = px(1), maxVisible = 10, animMs = 180, drilledBorderTop = px(2),
                              gutter = px(3), bumperMinW = px(28), chevW = px(12), labelMarginV = px(28), targetCardMarginV = px(10) } }
end

local function menu(N, T)
    ZeD.T = T
    local items = {}
    for i = 1, N do items[i] = { name = "item" .. i, id = "i" .. i, category = "ACTION" } end
    local o = setmetatable({
        width = 1200, height = 400,
        _ctx = { open = true, actions = items, path = {}, selected = 1, pos = 1, truncating = false, trackOriginX = 0 },
        _animFromOriginX = 0, _animToOriginX = 0, _animStartMs = 0, _animFromLabelX = 0, _animToLabelX = 0,
        _animFromStripW = 0, _animToStripW = 0, _currentOriginX = 0, _currentLabelX = 0, _currentStripW = 0,
        _suppressFrames = 0, _layoutCache = {},
    }, { __index = CM })
    o._currentItems = function(self) return items end
    o:_rebuildTrack()
    return o
end

-- run the slide to its end (and the settle after it), as frames would
local function settle(o, T)
    o:_layout(T)
    NOW = NOW + 1000
    o:_layout(T)
    if o._settleAt and NOW >= o._settleAt then o._settleAt = nil; o:_settleCarousel() end
    o:_layout(T)
    o:_layout(T)
end

-- the items the window shows once settled: the track indices in [0, innerW)
local function shown(o, T)
    local ctx = T.ctx
    local step = ctx.cellW + ctx.gap
    local N = #o._ctx.items
    local V = math.min(N, ctx.maxVisible)
    local innerW = V * ctx.cellW + (V - 1) * ctx.gap
    local origin = o._ctx.trackOriginX
    local list, whole = {}, true
    for i = 1, #o._ctx.trackItems do
        local x0 = origin + (i - 1) * step
        local x1 = x0 + ctx.cellW
        if x1 > 0 and x0 < innerW then
            if x0 < 0 or x1 > innerW then whole = false end
            list[#list + 1] = ((i - 1) % N) + 1
        end
    end
    return list, whole, origin % step == 0
end
local function same(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

for _, scale in ipairs({ 1, 1.75 }) do
    local T = tokens(scale)
    for _, N in ipairs({ 11, 12, 15, 20, 25, 31 }) do
        local tag = ("%sx N=%d: "):format(tostring(scale), N)
        local o = menu(N, T)
        o._suppressFrames = 1
        settle(o, T)
        local first, whole, aligned = shown(o, T)
        check(tag .. "WHOLE: 10 cells show on opening", #first == 10, #first)
        check(tag .. "WHOLE: no cell cut on opening", whole and aligned, o._ctx.trackOriginX)
        check(tag .. "WHOLE: the selection is in the window", (function() for _, v in ipairs(first) do if v == o._ctx.selected then return true end end end)())

        -- PAGE forward three times, then back three times
        local windows = { first }
        for k = 1, 3 do
            o:nextPage(); settle(o, T)
            local w, wh, al = shown(o, T)
            check(tag .. "PAGE " .. k .. ": whole cells", wh and al and #w == 10, #w)
            local prev = windows[#windows]
            local expect = {}
            for i = 1, 10 do expect[i] = ((prev[i] + 10 - 1) % N) + 1 end
            check(tag .. "PAGE " .. k .. ": the next 10 cells, none skipped or repeated", same(w, expect), table.concat(w, ","))
            check(tag .. "PAGE " .. k .. ": the selection is the anchor's cell", o._ctx.selected == w[o:_anchorSlot(10) + 1], o._ctx.selected)
            check(tag .. "PAGE " .. k .. ": the anchor stays in the middle copy once settled", o._ctx.pos >= N + 1 and o._ctx.pos <= 2 * N, o._ctx.pos)
            windows[#windows + 1] = w
        end
        for k = 1, 3 do
            o:prevPage(); settle(o, T)
            local w, wh, al = shown(o, T)
            check(tag .. "PAGE back " .. k .. ": whole cells", wh and al and #w == 10, #w)
            check(tag .. "PAGE back " .. k .. ": the window before", same(w, windows[#windows - k]), table.concat(w, ","))
        end

        -- two clicks before the slide settles
        o:nextPage(); o:_layout(T); NOW = NOW + 50; o:nextPage()
        local track = #o._ctx.trackItems
        check(tag .. "PAGE twice fast: the window stays inside the track", o._ctx.pos - o:_anchorSlot(10) >= 1
              and o._ctx.pos - o:_anchorSlot(10) + 9 <= track, o._ctx.pos)
        settle(o, T)
        local w2, wh2 = shown(o, T)
        local expect = {}
        for i = 1, 10 do expect[i] = ((first[i] + 20 - 1) % N) + 1 end
        check(tag .. "PAGE twice fast: two pages on", wh2 and same(w2, expect), table.concat(w2, ","))

        -- STEP: one cell, still whole
        local o2 = menu(N, T); o2._suppressFrames = 1; settle(o2, T)
        local before = shown(o2, T)
        o2:next(); settle(o2, T)
        local after, whS = shown(o2, T)
        check(tag .. "STEP: one cell on, whole", whS and after[1] == ((before[1]) % N) + 1, table.concat(after, ","))
        o2:prev(); o2:prev(); settle(o2, T)
        local back, whB = shown(o2, T)
        check(tag .. "STEP: back two, whole", whB and back[1] == ((before[1] - 2 + N) % N) + 1, table.concat(back, ","))
    end

    -- SHORT
    local s = menu(8, T); settle(s, T)
    check(scale .. "x SHORT: 8 cells don't overflow", not s._ctx.truncating)
    s:nextPage()
    check(scale .. "x SHORT: an arrow steps one cell", s._ctx.selected == 2, s._ctx.selected)
    s:prevPage(); s:prevPage()
    check(scale .. "x SHORT: and back, wrapping", s._ctx.selected == 8, s._ctx.selected)
end

print("strip_page_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
