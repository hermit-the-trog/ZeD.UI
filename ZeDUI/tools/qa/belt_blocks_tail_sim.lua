-- ZeDUI/tools/qa/belt_blocks_tail_sim.lua  (Nov 24 2026, Build; the director: "the ammunition clip and message icon
-- did not receive the updated background and framing")
-- The ammo tab (ZeD_Belt.lua _drawAmmo) and the Messages notice (ZeD_ErrorBox.lua ZeD_ErrorNotice:prerender) are the
-- belt row's white block too, as the slots, hands, bag, speed keys and chat key have been since Nov 23 (WHITE BLOCKS):
-- System 7's hard shadow, the paper, a one-unit ink edge; ink words on the paper. Source checks.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/belt_blocks_tail_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]belt_blocks_tail_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name) end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    if not a then return "" end
    local b = string.find(src, to, a, true)
    return b and string.sub(src, a, b) or ""
end
local function has(s, x) return string.find(s, x, 1, true) ~= nil end

local ammo = cut(readFile(Z .. "ZeD_Belt.lua"), "function ZeD_BeltHUD:_drawAmmo(t, a)", "\nend\n")
check("AMMO: _drawAmmo found", #ammo > 0)
check("AMMO: hard shadow", has(ammo, "blockShadow(self, t.x, t.y, t.w, t.h, false)"))
check("AMMO: paper", has(ammo, "PAPER.r, PAPER.g, PAPER.b"))
check("AMMO: ink edge", has(ammo, "inkEdge(self, t.x, t.y, t.w, t.h)"))
check("AMMO: ink words", has(ammo, "local tc = INK") and has(ammo, "INK_DIM"))
check("AMMO: no old dark fill or two-unit frame", not has(ammo, "T.surf2") and not has(ammo, "T.frameS"))

local note = cut(readFile(Z .. "ZeD_ErrorBox.lua"), "function ZeD_ErrorNotice:prerender()", "\nend\n")
check("NOTICE: prerender found", #note > 0)
check("NOTICE: hard shadow", has(note, "ZeD.Atoms.drawHardShadow(self, 0, 0, w, h)"))
check("NOTICE: the belt's paper and ink", has(note, "BL.PAPER") and has(note, "BL.INK"))
check("NOTICE: one-unit ink edge", has(note, "for i = 0, (T.hair or 1) - 1 do self:drawRectBorder(i, i, w - 2 * i, h - 2 * i, 1, bd.r, bd.g, bd.b) end"))
check("NOTICE: no old surf1 fill", not has(note, "T.surf1"))

print("belt_blocks_tail_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
