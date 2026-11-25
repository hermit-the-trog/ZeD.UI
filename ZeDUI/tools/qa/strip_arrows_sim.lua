-- ZeDUI/tools/qa/strip_arrows_sim.lua  (Nov 25 2026, Build; the director: "the scroll buttons on the container strip
-- are not on center")
--   HALVES  ZeD.Atoms.stripArrowHalves / stripArrowX (cut from AtomExtensions.lua): the row's inside between the
--           strip's lines, two equal halves, each arrow centred in its half; the pair centred on the inside
--   WIRED   both container strips (the Character window's and the World window's) use them
-- Run from the repo root:  lua51 ZeDUI/tools/qa/strip_arrows_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]strip_arrows_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    return b and string.sub(src, a, b + #to - 1) .. "\n" or nil
end
local function has(s, x) return string.find(s, x, 1, true) ~= nil end

local AX = readFile(Z .. "AtomExtensions.lua")
local src = cut(AX, "local function stripInset(kind)", "\nend\n")
local srcH = cut(AX, "function ZeD.Atoms.stripArrowHalves(w, kindL, kindR)", "\nend\n")
local src2 = cut(AX, "function ZeD.Atoms.stripArrowX(a, b, s)", "\nend\n")
check("HALVES: found", src ~= nil and srcH ~= nil and src2 ~= nil)
for _, sc in ipairs({ 1, 1.75, 2 }) do
  for _, bw in ipairs({ 1, 2 }) do
    for _, sides in ipairs({ { "frame", "own" }, { "own", "own+edge" }, { "own", "edge" } }) do
    local function px(n) return math.floor(n * sc + 0.5) end
    ZeD = { Atoms = {}, T = { px = px, borderW = bw, line = function(u) return u * px(1) end } }
    if src and srcH and src2 then
        assert(loadstring(src .. srcH .. src2))()
        local A, T = ZeD.Atoms, ZeD.T
        local w = T.px(36)
        local L, M, M2, R = A.stripArrowHalves(w, sides[1], sides[2])
        local s = T.px(5)
        local ux, dx = A.stripArrowX(L, M, s), A.stripArrowX(M2, R, s)
        local function inset(k) if k == "own" then return px(1) elseif k == "frame" then return bw * px(1) elseif k == "own+edge" then return px(1) + (bw - 1) * px(1) end return (bw - 1) * px(1) end
        local tag = "scale " .. sc .. " bw " .. bw .. " " .. sides[1] .. "/" .. sides[2]
        check("HALVES " .. tag .. ": the inside is inside the lines by their weight", L == inset(sides[1]) and R == w - inset(sides[2]), L .. "," .. R)
        check("HALVES " .. tag .. ": the dividing line a hairline wide", M2 - M == T.px(1))
        check("HALVES " .. tag .. ": two equal halves (within a pixel)", math.abs((M - L) - (R - M2)) <= 1)
        local pairC = ((ux + s / 2) + (dx + s / 2)) / 2
        check("HALVES " .. tag .. ": the pair centred on the inside (within a pixel)", math.abs(pairC - (L + R) / 2) <= 1)
    end
    end
  end
end
local CW = readFile(Z .. "ZeD_CharacterWindow.lua")
local WW = readFile(Z .. "ZeD_WorldWindow.lua")
check("WIRED: the Character window's container strip", has(CW, 'self:addHitZone("strip_scroll_down", M2, arrowY, w - M2, scrollArrowH)'))
check("WIRED: the Character window's tab strip", has(CW, 'self:addHitZone("tab_scroll_down", M2, rowY, w - M2, arrowRowH)'))
check("WIRED: the World window's tab strip", has(WW, 'self:addHitZone("tab_scroll_down", M2, rowY, w - M2, arrowRowH)'))
check("WIRED: the line between up and down on all four", select(2, string.gsub(CW .. WW, "A.stripArrowLine%(self, M, M2, ", "")) == 4)
check("WIRED: each strip's sides (QA's measures)", has(CW, 'A.stripArrowHalves(w, "frame", "own")') and has(CW, 'A.stripArrowHalves(w, "own", "own+edge")') and has(WW, 'A.stripArrowHalves(w, "own", "edge")') and has(WW, 'A.stripArrowHalves(w, "frame", "own")'))
check("WIRED: the World window's container strip", has(WW, 'A.drawTriangleUp(self, A.stripArrowX(L, M, aS), arY, aS, arrowColor)') and not has(WW, "local upX = math.floor(w / 4)"))

print("strip_arrows_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
