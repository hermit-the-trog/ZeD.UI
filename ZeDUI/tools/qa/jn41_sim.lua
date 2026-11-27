-- ZeDUI/tools/qa/jn41_sim.lua
-- (QA J41, Nov 27 2026) The pad on a long log: with 80 entries and a view of about 12 rows, Down from the
-- first entry's cross went del:1, del:2, then Save (Save in the band sits nearer than the next row out of
-- view). Runs the real rowStep, the rows' D-pad handler and inPadReach, cut from JournalTab.lua, on a model
-- of the log: the stops near the view (as the Character window builds them), the plain pick for what the
-- handler leaves, and the Journal's scroll-follow after each move. Fails on the code before the fix.
-- Run from the repo root: lua51 ZeDUI/tools/qa/jn41_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]jn41_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readSrc(p) local fh = assert(io.open(ROOT .. p, "rb")); local s = fh:read("*a"):gsub("\r\n", "\n"); fh:close(); return s end
local function fnBody(src, head) return src:match("\n(" .. head .. ".-\nend)\n") end

local Z = "42/media/lua/client/ZeD/"
local jt = readSrc(Z .. "JournalTab.lua")
local cw = readSrc(Z .. "ZeD_CharacterWindow.lua")
local sn = readSrc(Z .. "Input/SpatialNav.lua")

ZeD = { JournalTab = {} }
assert(loadstring(sn))()
local SN = ZeD.SpatialNav

local block = jt:match("\n(local ROW_KINDS = .-\nlocal function tagDpad%(.-\nend)\n")
local reachBody = fnBody(jt, "function ZeD%.JournalTab%.inPadReach")
check("finds rowStep, the rows' D-pad and inPadReach", block ~= nil and reachBody ~= nil)
if not (block and reachBody) then
    print("jn41_sim: " .. checks .. " checks, " .. failed .. " failed")
    return
end
assert(loadstring(reachBody))()
local focusedId = nil
ZeD.Input = { Focus = { focusWhere = function(w, zone, pred)
    for _, z in ipairs(w._focusRing) do
        if z.zone == zone then for _, el in ipairs(z.elements) do if pred(el) then focusedId = el.id; return el end end end
    end
    return nil
end } }
ZeD.uiSound = function() end
local rowDpad = assert(loadstring(block .. "\nreturn tagDpad"))()

-- ---------------------------------------------------------------------------
-- The model: the log's view (12 rows of 70 px), the header above it, Save in the band under it.
-- Content: the write box, then four month heads of 20 entries each; every third entry has a tag.
-- ---------------------------------------------------------------------------
local VY, VH, PITCH, N = 100, 840, 70, 80
local content = {}   -- { id, kind, x, cy, w, h, entry }
content[#content + 1] = { id = "journal:__write", kind = "write", x = 18, cy = 0, w = 760, h = 30 }
local cy = 40
for i = 1, N do
    if (i - 1) % 20 == 0 then
        content[#content + 1] = { id = "journal:group:" .. ((i - 1) / 20 + 1), kind = "group", x = 18, cy = cy, w = 760, h = 15 }
        cy = cy + 20
    end
    if i % 3 == 0 then
        content[#content + 1] = { id = "journal:tag:" .. i .. ":food", kind = "tag", x = 600, cy = cy, w = 60, h = 24, entry = i }
    end
    content[#content + 1] = { id = "journal:del:" .. i, kind = "delete", x = 758, cy = cy + 2, w = 20, h = 20, entry = i }
    cy = cy + PITCH
end
local TOTAL = cy
local fixed = {
    { id = "jtab:1", journalKind = "pageTab", x = 18, y = 40, w = 80, h = 24 },
    { id = "journal:__find", journalKind = "find", x = 600, y = 40, w = 180, h = 24 },
    { id = "journal:__save", journalKind = "save", x = 700, y = VY + VH + 5, w = 70, h = 24 },
}
local win = { _journalView = { x = 18, y = VY, w = 760, h = VH } }
local off = 0

-- the stops as the Character window builds them at scroll off: the crosses and tags near the view only
local function build()
    local out = {}
    for _, f in ipairs(fixed) do out[#out + 1] = f end
    for _, c in ipairs(content) do
        local r = { x = c.x, y = VY + c.cy - off, w = c.w, h = c.h }
        local near = (c.kind ~= "delete" and c.kind ~= "tag") or ZeD.JournalTab.inPadReach(win, r)
        if near then
            r.id, r.journalKind, r.entryIdx = c.id, c.kind, c.entry
            if c.kind == "delete" or c.kind == "tag" or c.kind == "group" then r.onDpadDir = rowDpad end
            out[#out + 1] = r
        end
    end
    return out
end
local function byId(els, id) for _, e in ipairs(els) do if e.id == id then return e end end end
local function contentOf(id) for _, c in ipairs(content) do if c.id == id then return c end end end

-- one press: the stop's own handler first, else the plain pick; then the Journal's scroll-follow
local function press(id, dir)
    local els = build()
    win._focusRing = { { zone = "journalSub", focusable = true, elements = els } }
    local el = byId(els, id)
    if not el then return nil end
    focusedId = nil
    local to = nil
    if el.onDpadDir and el.onDpadDir(win, el, dir) ~= false then
        to = focusedId
    else
        local others = {}
        for _, e in ipairs(els) do if e ~= el then others[#others + 1] = e end end
        local p = SN.pick(el, others, dir)
        to = p and p.id
    end
    local c = to and contentOf(to)
    if c then
        local top, bot = c.cy - off, c.cy - off + c.h
        if top < 8 then off = math.max(0, c.cy - 8)
        elseif bot > VH - 8 then off = math.min(TOTAL - VH, c.cy + c.h - VH + 8) end
    end
    return to
end

-- Down from the first entry's cross to Save
local seen, order, last, steps = {}, {}, "journal:del:1", 0
local entryOf = function(id) return tonumber(id:match("^journal:del:(%d+)$") or id:match("^journal:tag:(%d+):")) end
local okOrder, bad = true, nil
local prev = 1
seen[1] = true
while steps < 400 do
    local to = press(last, "down")
    steps = steps + 1
    if not to or to == "journal:__save" then last = to; break end
    local n = entryOf(to)
    if n then
        if n < prev then okOrder = false; bad = bad or (last .. " -> " .. to) end
        seen[n] = true; prev = n
    end
    order[#order + 1] = to
    last = to
end
local missing = nil
for i = 1, N do if not seen[i] then missing = missing or i end end
check("J41 Down from the first cross walks every entry, 1 to 80, before Save", missing == nil and okOrder,
    "first missed " .. tostring(missing) .. ", stopped at " .. tostring(order[#order]) .. " then " .. tostring(last) .. (bad and (", backwards " .. bad) or ""))
check("J41 the walk ends on Save after the last entry", last == "journal:__save" and entryOf(order[#order] or "") == N, tostring(order[#order]) .. " -> " .. tostring(last))
local heads = 0
for _, id in ipairs(order) do if id:find("^journal:group:") then heads = heads + 1 end end
check("J41 the month heads on the way are stops of the walk (2, 3, 4)", heads == 3, heads)
local c80 = contentOf("journal:del:" .. N)
check("J41 the scroll-follow brought entry 80's cross into view", c80.cy - off >= 0 and c80.cy - off + c80.h <= VH, c80.cy - off)

-- Up from Save comes back to row 80, then on up the whole log
local up = press("journal:__save", "up")
check("J41 Up from Save comes back to entry 80", up ~= nil and entryOf(up) == N, up)
local seenUp, prevUp, okUp, cur, ups = {}, N + 1, true, up, 0
while cur and entryOf(cur) or (cur and cur:find("^journal:group:")) do
    local n = entryOf(cur)
    if n then
        if n > prevUp then okUp = false end
        seenUp[n] = true; prevUp = n
    end
    cur = press(cur, "up")
    ups = ups + 1
    if ups > 400 then break end
end
local missUp = nil
for i = 1, N do if not seenUp[i] then missUp = missUp or i end end
check("J41 Up walks every entry back, 80 to 1", missUp == nil and okUp, "first missed " .. tostring(missUp) .. ", left the log at " .. tostring(cur))
check("J41 above entry 1 (and its month head) comes the write box, not the header", cur == "journal:__write", cur)

-- the Character window gives the crosses and month heads the rows' handler
check("J41 the crosses carry the rows' D-pad handler", cw:find('journalKind = "delete",\n%s*entryIdx = z.entryIdx,\n%s*onDpadDir = rowDpad,') ~= nil)
check("J41 the month heads carry it too", cw:find('groupKey = z.id,\n%s*onDpadDir = rowDpad,') ~= nil)
check("J41 JournalTab shares the handler", jt:find("\nZeD.JournalTab.rowDpad = tagDpad\n", 1, true) ~= nil)

print("jn41_sim: " .. checks .. " checks, " .. failed .. " failed")
