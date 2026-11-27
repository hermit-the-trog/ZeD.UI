-- ZeDUI/tools/qa/oc_medic_layout_sim.lua (the director, Nov 26 2026): "The medical treatment card for other players
-- ... does not have the treatments on the right column next to the image. You have to scroll down to see them."
-- Runs the real ObjectCardMedic.lua body on the real figureFrame (Molecules.lua) with the rest stubbed, and checks:
-- on a card wide enough for halves the first injury row starts beside the figure (its top inside the frame's span,
-- its left past the frame); on the 220 drawer card the rows start under the frame, full width, as before; no row runs
-- past the card's width; a row under the pointer keeps the rows where they are; a figure part under the pointer
-- shows its detail beside the figure; every figure part and every row is still a stop.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_medic_layout_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_medic_layout_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb"); if not f then return "" end
    local s = f:read("*a"); f:close(); return (string.gsub(s, "\r\n", "\n"))
end
local function done()
    print(string.format("oc_medic_layout_sim: %d checks, %d failed", checks, failed))
    if failed > 0 then os.exit(1) end
end

-- the stubs: what the body draws with, recorded where it matters
local DETAIL, SUMMARY = {}, {}
local FH = 16
ZeD = {
    Molecules = {},
    Atoms = {
        frame = function() end, drawStatusDot = function() end, drawBody = function() end,
        drawTextRight = function() end, drawDividerH = function() end,
        pctText = function(f) return tostring(math.floor(f * 100)) .. "%" end, statusColor = function() return {} end,
    },
    TM = { getFontHeight = function(self, f) return FH end },
    Focus = { mark = function() return false end },
    partLabel = function(n) return n end,
    Safe = nil,
}
local function look(sc)
    local art = math.max(1, math.floor(sc + 0.5 + 1e-6))
    ZeD.T = { px = function(u) return math.floor(u * sc + 0.5) end, art = art, borderS = {}, fontF1 = 1, fontF2 = 2,
              stripe = { a = 1, r = 0, g = 0, b = 0 }, text = {}, textOnFocus = {}, danger = {}, warning = {},
              sp = { figureW = 106 * art, figureH = 254 * art, scrollbarW = math.floor(14 * sc + 0.5),
                     afterGroove = math.floor(8 * sc + 0.5), afterLine = math.floor(10 * sc + 0.5),
                     xs = math.floor(2 * sc + 0.5), sm = math.floor(4 * sc + 0.5) } }
end
look(1)
ZeD.HealthTab = {
    drawOverall = function(p, x, y, w, d) return y + 3 * FH end,
    drawSummary = function(p, d, x, y) SUMMARY[#SUMMARY + 1] = { x = x, y = y }; return y + FH end,
    tagHang = function() return 0 end,
    condTags = function(p, conds, x, y, w, hang) return (conds and #conds > 0) and FH or 0 end,
    sevColor = function() return {} end,
    tintPart = function() end,
    _renderDetailView = function(p, win, d, part, rx, ry, rw) DETAIL[#DETAIL + 1] = { part = part, x = rx, y = ry, w = rw }; return ry + 6 * FH end,
}
local FIGRECTS = {}
ZeD_BodyFigure = {}
function ZeD_BodyFigure:new()
    local f = {}
    function f:initialise() end
    function f:loadTextures() end
    function f:setSex() end
    function f:setSkinTone() end
    function f:setPartWounds() end
    function f:drawChart() end
    function f:drawAt(p, x, y, w, h) FIGRECTS = { { name = "Upper Torso", x = x + 30, y = y + 60, w = 40, h = 40 },
                                                  { name = "Left Hand", x = x + 2, y = y + 120, w = 12, h = 12 } } end
    function f:getPartRects() return FIGRECTS end
    return f
end
local DEF
ZeD.ObjectCards = { ui = { warn = function() return 0 end }, call = function() return nil end, kinds = {},
                    register = function(d) DEF = d end }
require = function() end
getText = function(k) return k end

-- the real figure frame code (as figure_frame_sim loads it)
local mol = readFile(CLIENT .. "Molecules.lua")
local a = mol:find("local FIG_FRAME_INSET", 1, true)
local b = a and mol:find("\n-- 11. STAT ROW", a, true)
local fn = a and b and loadstring("local TAB_HEADER_PAD, TAB_COL_GAP = 8, 10\n" .. mol:sub(a, b), "=Molecules.lua (figure frame)")
check("the figure frame code loads", fn ~= nil)
if not fn then done() return end
fn()
local medicSrc = readFile(CLIENT .. "ObjectCardMedic.lua")
local mfn, err = loadstring(medicSrc, "=ObjectCardMedic.lua")
check("ObjectCardMedic.lua compiles", mfn ~= nil, err)
if not mfn then done() return end
local okRun, runErr = pcall(mfn)
check("ObjectCardMedic.lua runs and registers its card", okRun and DEF and DEF.body, runErr)
if not (okRun and DEF) then done() return end

-- a patient with four injuries (one with tags) and the parts the figure maps
local function patientData()
    local entries = {}
    local names = { "Left Hand", "Right Forearm", "Left Thigh", "Head" }
    for i, n in ipairs(names) do
        entries[i] = { name = n, figure = n, bodyPart = { n = n }, health = 60 + i, worstSev = 2,
                       conditions = (i == 1) and { { label = "Deep wound" } } or {} }
    end
    return { entries = entries, overall = 80, isFemale = false, skinTone = 1,
             partHealth = { ["Upper Torso"] = 100, ["Left Hand"] = 50 }, partByFigure = {} }
end
local function newCard()
    local c = { zones = {} }
    function c:zone(z) self.zones[#self.zones + 1] = z end
    function c:focusOf() return nil end
    function c:drawRect() end
    function c:pointerOver() return false end
    return c
end
local function render(card, x, w)
    card.zones = {}
    local t = card.t
    local h = DEF.body(card, x, 0, w, t, nil)
    local rows, figs = {}, {}
    for _, z in ipairs(card.zones) do
        if z.fid:match("^mc:part:") then rows[#rows + 1] = z
        elseif z.fid:match("^mc:fig:") then figs[#figs + 1] = z end
    end
    return h, rows, figs
end

local SCREENS = { { "1080p", 1.0 }, { "4K", 1.75 }, { "1280x800", 0.75 } }
for _, sc in ipairs(SCREENS) do
    look(sc[2])
    local T = ZeD.T
    local pad = T.px(10)
    -- the full card (OC.CARD_W, 480): halves; the half card (220): stacked
    for _, cw in ipairs({ 480 }) do
        local name = sc[1] .. " " .. cw
        local x, w = pad, T.px(cw) - pad * 2
        local L = ZeD.Molecules.figureFrame(x, 0, w)
        check(name .. ": wide enough for halves", L.two == true)
        local card = newCard()
        card.t = { d = patientData(), fakeWin = {}, level = 0 }
        local h, rows, figs = render(card, x, w)
        local r1 = rows[1]
        check(name .. ": every injury is a row stop", #rows == 4, #rows)
        check(name .. ": the figure parts are still stops", #figs == 2, #figs)
        check(name .. ": the first row starts inside the frame's span",
            r1 and r1.y >= L.frameY and r1.y < L.frameY + L.frameH, r1 and (r1.y .. " vs frame " .. L.frameY .. ".." .. (L.frameY + L.frameH)))
        check(name .. ": the first row sits right of the figure", r1 and r1.x >= L.frameX + L.frameW, r1 and r1.x)
        local last = rows[#rows]
        local within = true
        for _, r in ipairs(rows) do if r.x < x or r.x + r.w > x + w then within = false end end
        check(name .. ": no row runs past the card's width", within)
        check(name .. ": the body's height reaches the last row and the frame's foot",
            last and h >= last.y + last.h and h >= L.frameH, h)
        -- the pointer on a row: the rows stay where they were (no detail pushes them under the pointer)
        card._hoverFid = r1 and r1.fid
        DETAIL = {}
        local _, rows2 = render(card, x, w)
        check(name .. ": a row under the pointer keeps the rows in place", rows2[1] and r1 and rows2[1].y == r1.y and rows2[4].y == last.y)
        check(name .. ": a row under the pointer brings no detail over the list", #DETAIL == 0)
        -- the pointer on a figure part: its detail beside the figure, the rows under it, still in the column
        card._hoverFid = "mc:fig:Left Hand"
        DETAIL = {}
        local _, rows3 = render(card, x, w)
        check(name .. ": a figure part under the pointer shows its detail beside the figure",
            #DETAIL == 1 and DETAIL[1].part == "Left Hand" and DETAIL[1].x == L.rightX)
        check(name .. ": with the detail shown the rows stay in the column", rows3[1] and rows3[1].x == L.rightX and rows3[1].y > L.frameY)
        -- the controller on a row wins over the pointer, as before
        card._hoverFid = nil
        card._fid = r1 and r1.fid
        DETAIL = {}
        render(card, x, w)
        check(name .. ": the controller on a row: no detail, the list stays put", #DETAIL == 0)
    end
    -- the 220 drawer card: stacked as before
    do
        local name = sc[1] .. " 220"
        local x, w = pad, T.px(220) - pad * 2
        local L = ZeD.Molecules.figureFrame(x, 0, w)
        check(name .. ": too narrow for halves", L.two == false)
        local card = newCard()
        card.t = { d = patientData(), fakeWin = {}, level = 0 }
        SUMMARY = {}
        local h, rows, figs = render(card, x, w)
        check(name .. ": every injury is a row stop", #rows == 4, #rows)
        check(name .. ": the figure parts are still stops", #figs == 2, #figs)
        check(name .. ": the summary under the frame", SUMMARY[1] and SUMMARY[1].y >= L.frameY + L.frameH)
        check(name .. ": the rows start under the frame", rows[1] and rows[1].y >= L.frameY + L.frameH)
        check(name .. ": the rows take the card's width", rows[1] and rows[1].x == x and rows[1].w == w)
        local within = true
        for _, r in ipairs(rows) do if r.x < x or r.x + r.w > x + w then within = false end end
        check(name .. ": no row runs past the card's width", within)
        -- a row under the pointer still shows its part's detail under the frame (the stacked card, unchanged)
        card._hoverFid = rows[1] and rows[1].fid
        DETAIL = {}
        render(card, x, w)
        check(name .. ": a row in hand still shows its detail", #DETAIL == 1 and DETAIL[1].part == "Left Hand")
    end
end
done()
