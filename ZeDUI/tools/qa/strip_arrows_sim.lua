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
local src = cut(AX, "function ZeD.Atoms.stripArrowHalves(w)", "\nend\n")
local src2 = cut(AX, "function ZeD.Atoms.stripArrowX(a, b, s)", "\nend\n")
check("HALVES: found", src ~= nil and src2 ~= nil)
for _, sc in ipairs({ 1, 1.75, 2 }) do
    ZeD = { Atoms = {}, T = { px = function(n) return math.floor(n * sc + 0.5) end } }
    if src and src2 then
        assert(loadstring(src .. src2))()
        local A, T = ZeD.Atoms, ZeD.T
        local w = T.px(36)
        local L, M, R = A.stripArrowHalves(w)
        local s = T.px(5)
        local ux, dx = A.stripArrowX(L, M, s), A.stripArrowX(M, R, s)
        local tag = "scale " .. sc
        check("HALVES " .. tag .. ": the inside is between the lines", L == T.px(1) and R == w - T.px(1))
        check("HALVES " .. tag .. ": two equal halves (within a pixel)", math.abs((M - L) - (R - M)) <= 1)
        local pairC = ((ux + s / 2) + (dx + s / 2)) / 2
        local inC = (L + R) / 2
        check("HALVES " .. tag .. ": the pair centred on the inside (within a pixel)", math.abs(pairC - inC) <= 1, pairC .. " vs " .. inC)
        check("HALVES " .. tag .. ": each arrow in its half's middle", math.abs((ux + s / 2) - (L + M) / 2) <= 1 and math.abs((dx + s / 2) - (M + R) / 2) <= 1)
    end
end
local CW = readFile(Z .. "ZeD_CharacterWindow.lua")
local WW = readFile(Z .. "ZeD_WorldWindow.lua")
check("WIRED: the Character window's container strip", has(CW, 'A.drawTriangleUp(self, A.stripArrowX(L, M, aS), arY, aS, upC)') and has(CW, 'self:addHitZone("strip_scroll_down", M, arrowY, w - M, scrollArrowH)'))
check("WIRED: the World window's container strip", has(WW, 'A.drawTriangleUp(self, A.stripArrowX(L, M, aS), arY, aS, arrowColor)') and not has(WW, "local upX = math.floor(w / 4)"))

print("strip_arrows_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
