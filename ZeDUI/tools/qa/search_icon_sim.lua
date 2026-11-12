-- ZeDUI/tools/qa/search_icon_sim.lua  (Nov 11 2026): the magnifier in the search boxes, with no game running.
-- It loads the real AtomExtensions.lua over a stub of the library and shows:
--   * the shared helper ZeD.Atoms.drawSearchIcon draws a 9-unit pixel magnifier in whole pixels, in the colour
--     it is given or T.textDim read fresh (so a theme change shows at once), at 1x, 1.75x and 2x;
--   * no source file draws the "/" stand-in any more, and the search fields (ZeD_SearchField:render, which the
--     Journal, Survival Guide, inventory Filter, Skills and Equipment Find, crafting and mod fields all use, and
--     the ticket card's find box shown while its field is off screen) call the helper.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/search_icon_sim.lua
-- It prints FAIL lines and a last line "search_icon_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]search_icon_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local function slurp(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- the stub library: only what AtomExtensions needs at load
local scale = 1
ZeD = { T = { textDim = { r = 0.5, g = 0.6, b = 0.7, a = 0.8 } } }
function ZeD.T.px(n) return math.floor(n * scale + 0.5) end
ZeD.Atoms = {}
local src = slurp(CLIENT .. "AtomExtensions.lua")
check("AtomExtensions.lua is readable", src ~= nil, CLIENT)
if src then
    local chunk, err = loadstring(src, "AtomExtensions")
    check("AtomExtensions.lua compiles", chunk ~= nil, err)
    if chunk then
        local ok, e = pcall(chunk)
        check("AtomExtensions.lua loads", ok, e)
    end
end
local A = ZeD.Atoms
check("the helper exists", type(A.drawSearchIcon) == "function")

local function recorder()
    local p = { rects = {} }
    function p:drawRect(x, y, w, h, a, r, g, b) self.rects[#self.rects + 1] = { x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b } end
    return p
end

if A.drawSearchIcon then
    for _, s in ipairs({ 1, 1.75, 2 }) do
        scale = s
        local cell = math.max(1, math.floor(s + 0.5))
        local p = recorder()
        local w = A.drawSearchIcon(p, 10, 0, 40)
        check("size " .. s .. ": returns 9 cells wide", w == 9 * cell, w)
        local minX, maxX, minY, maxY, whole = 1e9, -1e9, 1e9, -1e9, true
        for _, r in ipairs(p.rects) do
            minX = math.min(minX, r.x); maxX = math.max(maxX, r.x + r.w)
            minY = math.min(minY, r.y); maxY = math.max(maxY, r.y + r.h)
            if r.x ~= math.floor(r.x) or r.y ~= math.floor(r.y) or r.w ~= math.floor(r.w) or r.h ~= math.floor(r.h) then whole = false end
        end
        check("size " .. s .. ": whole pixels only", whole)
        check("size " .. s .. ": starts at x", minX == 10, minX)
        check("size " .. s .. ": spans its width", maxX - minX == 9 * cell, maxX - minX)
        check("size " .. s .. ": centred in the height", minY == math.floor((40 - 9 * cell) / 2) and maxY - minY == 9 * cell, minY)
        check("size " .. s .. ": draws something", #p.rects > 5, #p.rects)
        check("size " .. s .. ": text colour read fresh", p.rects[1].r == 0.5 and p.rects[1].a == 0.8)
    end
    -- a theme change shows on the next draw
    scale = 1
    ZeD.T.textDim = { r = 1, g = 0, b = 0, a = 1 }
    local p = recorder()
    A.drawSearchIcon(p, 0, 0, 20)
    check("a new T.textDim is used at once", p.rects[1].r == 1 and p.rects[1].g == 0)
    -- a given colour wins
    p = recorder()
    A.drawSearchIcon(p, 0, 0, 20, { r = 0, g = 1, b = 0 })
    check("a given colour wins, alpha defaults to 1", p.rects[1].g == 1 and p.rects[1].a == 1)
end

-- the sources
local mol = slurp(CLIENT .. "Molecules.lua")
check("Molecules.lua is readable", mol ~= nil)
if mol then
    local body = string.match(mol, "function ZeD_SearchField:render%(%)(.-)\r?\nend")
    check("ZeD_SearchField:render found", body ~= nil)
    if body then
        check("SearchField:render calls the shared icon", string.find(body, "drawSearchIcon", 1, true) ~= nil)
        check("SearchField:render no longer draws a slash", string.find(body, '"/"', 1, true) == nil)
    end
end
local tk = slurp(CLIENT .. "ZeD_TicketCards.lua")
check("ZeD_TicketCards.lua is readable", tk ~= nil)
if tk then
    local body = string.match(tk, "function D%.drawFind%(.-\r?\nend")
    check("D.drawFind found", body ~= nil)
    if body then check("D.drawFind (the off-screen box) draws the shared icon", string.find(body, "drawSearchIcon", 1, true) ~= nil) end
end
local filt = slurp(CLIENT .. "InventoryFilter.lua")
check("the inventory Filter bar is a ZeD_SearchField", filt ~= nil and string.find(filt, "ZeD_SearchField:new", 1, true) ~= nil)
local tf = slurp(CLIENT .. "TabFind.lua")
check("the Skills/Equipment Find field derives from ZeD_SearchField and draws its icon through it",
    tf ~= nil and string.find(tf, 'ZeD_SearchField:derive("ZeD_TabFindField")', 1, true) ~= nil
    and string.find(tf, "ZeD_SearchField.render(self)", 1, true) ~= nil)
local cw = slurp(CLIENT .. "ZeD_CharacterWindow.lua")
check("the Journal search is a ZeD_SearchField", cw ~= nil and string.find(cw, "ZeD_SearchField:new(0, 0, T.px(200), ZeD.tr(\"UI_ZeD_Char_JournalSearchEntries\"))", 1, true) ~= nil)

-- no file draws "/" as a glyph (a drawText whose text is the slash)
local list = io.popen('dir /b /s "' .. string.gsub(CLIENT, "/", "\\") .. '*.lua" 2>nul')
local hits = 0
if list then
    for path in list:lines() do
        local s = slurp(path)
        if s and string.find(s, 'drawText%("/"') then hits = hits + 1; print("FAIL slash glyph drawn in " .. path) end
    end
    list:close()
end
check("no file draws drawText(\"/\")", hits == 0, hits)

print("search_icon_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
