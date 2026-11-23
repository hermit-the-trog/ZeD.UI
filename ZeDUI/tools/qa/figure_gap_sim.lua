-- ZeDUI/tools/qa/figure_gap_sim.lua (Figure gap, Nov 22 2026, Build): the space between the body figure and its text
-- column is a token (T.sp.figureGap) and the column's width has a cap (T.sp.figureTextMax, 0 = none). Checks, on the
-- real Molecules.layoutZoneA and ZeD.setFigureSpacing source: the defaults give today's layout (gap 10, no cap), the
-- gap moves the column, the cap narrows it (spare room goes to the right), and the setter survives a theme rebuild.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/figure_gap_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\]tools[/\]qa[/\]figure_gap_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb"); if not f then return "" end
    local s = f:read("*a"); f:close(); return (string.gsub(s, "\r\n", "\n"))
end
-- pull one top-level function's source out of a file: from its "function NAME(" line to the next line "end"
local function grab(src, head)
    local a = src:find(head, 1, true)
    if not a then return nil end
    local b = src:find("\nend\n", a, true)
    return src:sub(a, b + 3)
end

local mol = readFile(ROOT .. "42/media/lua/client/ZeD/Molecules.lua")
local tok = readFile(ROOT .. "42/media/lua/shared/ZeD/Tokens.lua")
local medic = readFile(ROOT .. "42/media/lua/client/ZeD/ObjectCardMedic.lua")

-- a 1x look: T.px is the identity, the spacing built from the real design-unit table
ZeD = { Molecules = {}, Spacing = { figureW = 106, figureGap = 10, figureTextMax = 0 } }
ZeD.T = { px = function(u) return u end, sp = { figureW = 106, figureGap = 10, figureTextMax = 0 } }
local tokensDefault = tok:match("figureGap%s*=%s*(%d+)") and tonumber(tok:match("figureGap%s*=%s*(%d+)"))
local capDefault = tonumber(tok:match("figureTextMax%s*=%s*(%d+)"))
check("Tokens default gap is 10 (today's TAB_COL_GAP)", tokensDefault == 10, tokensDefault)
check("Tokens default cap is 0 (no cap)", capDefault == 0, capDefault)

local TAB_HEADER_PAD, TAB_COL_GAP = 8, 10
local zsrc = grab(mol, "function ZeD.Molecules.layoutZoneA(")
check("layoutZoneA source found", zsrc ~= nil)
local ssrc = grab(tok, "function ZeD.setFigureSpacing(")
check("setFigureSpacing source found", ssrc ~= nil)
local fn = loadstring("local TAB_HEADER_PAD, TAB_COL_GAP = 8, 10\n" .. (zsrc or "") .. "\n" .. (ssrc or ""))
check("the two functions compile", fn ~= nil)
if fn then fn() end

local function col(w) return ZeD.Molecules.layoutZoneA(0, 0, w, 106, 272) end
-- today: 8 + 106 + 10 = rightX 124; rightW = w - 8 - 124
local L = col(466)
check("default: rightX 124 (today)", L.rightX == 124, L.rightX)
check("default: rightW 334 at w 466 (today)", L.rightW == 334, L.rightW)
check("default: rightW 348 at w 480 (today)", col(480).rightW == 348, col(480).rightW)

ZeD.setFigureSpacing(20, 0)
L = col(466)
check("gap 20: rightX 134", L.rightX == 134, L.rightX)
check("gap 20: rightW 324 (the right edge stays put)", L.rightW == 324, L.rightW)
check("setter kept the gap in ZeD.Spacing (a re-theme rebuilds T.sp from it)", ZeD.Spacing.figureGap == 20)

ZeD.setFigureSpacing(14, 300)
L = col(466)
check("gap 14, cap 300: rightX 128", L.rightX == 128, L.rightX)
check("gap 14, cap 300: rightW 300 (cap bites at w 466: 330)", L.rightW == 300, L.rightW)
check("cap leaves a column already narrower alone", col(400).rightW == 400 - 8 - 128, col(400).rightW)

ZeD.setFigureSpacing(10, nil)
check("setter with no cap restores today's width", col(466).rightW == 334 and ZeD.T.sp.figureTextMax == 0)

-- the medical card reads the same two tokens
check("medic card uses T.sp.figureGap", medic:find("T.sp.figureGap", 1, true) ~= nil)
check("medic card uses T.sp.figureTextMax", medic:find("T.sp.figureTextMax", 1, true) ~= nil)

print(string.format("figure_gap_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
