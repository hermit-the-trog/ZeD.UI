-- ZeDUI/tools/qa/safe_notice_sim.lua  (Nov 8 2026, Build, QA round 1 faults 5 and 6), no game running.
--   SAFE    ZeD.Safe.reread() clears the per-screen read time too: a screen's switch (pieceOff) is read on the very next
--           call, never held for up to READ_MS (500 ms; QA saw about 3 s) by the last read. Safe mode itself the same.
--   NOTICE  the first Messages balloon is held while the belt has not drawn its Messages note (no tail), for
--           NOTICE_HOLD_MS at most, then shown as it is; once shown, or once the tail is there, never held again.
--           Cut from ZeD_MessagesWindow.lua: W.noticeHold and ZeD_MessagesToasts:prerender, over fakes.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/safe_notice_sim.lua
-- It prints FAIL lines and a last line "safe_notice_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]safe_notice_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end

local NOW = 100000
function getTimestampMs() return NOW end
print = (function(p) return function(s) if not tostring(s):find("^%[ZeD%]") then p(s) end end end)(print)
function require() end

-- ---------------------------------------------------------------------------
-- SAFE
-- ---------------------------------------------------------------------------
ZeD = { tr = function(k) return k end }
local VALUE = 1
local option = { getValue = function() return VALUE end }
ZeD.Settings = { safeModeOption = option, screenOptions = {} }
local PIECE = 1
local piece = { getValue = function() return PIECE end }
ZeD.Settings.screenOptions.radio = piece
assert(loadfile(Z .. "SafeMode.lua"))()
local S = ZeD.Safe
check("Safe loads", S and S.reread and S.pieceOff and S.on)

check("SAFE a screen starts ZeD's", S.pieceOff("radio") == false)
PIECE = 2
check("SAFE the switch moved: the cached read still says ZeD's (the 500 ms hold)", S.pieceOff("radio") == false)
NOW = NOW + 100
check("SAFE 100 ms later: still held", S.pieceOff("radio") == false)
S.reread()
check("SAFE after reread: the very next call hands the screen back", S.pieceOff("radio") == true)
PIECE = 1
check("SAFE the switch back: held until the next read", S.pieceOff("radio") == true)
S.reread()
check("SAFE after reread: ZeD's again at once", S.pieceOff("radio") == false)
-- a piece never read yet and one read at another time
ZeD.Settings.screenOptions.map = { getValue = function() return 2 end }
check("SAFE a screen first read after a reread", (S.reread() or true) and S.pieceOff("map") == true)
-- safe mode itself
VALUE = 2
check("SAFE mode switched on: held until reread", S.on() == false)
S.reread()
check("SAFE mode on after reread", S.on() == true)
VALUE = 1
S.reread()
check("SAFE mode off after reread", S.on() == false)

-- ---------------------------------------------------------------------------
-- NOTICE
-- ---------------------------------------------------------------------------
local src = readFile(Z .. "ZeD_MessagesWindow.lua")
local function cut(from)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local _, b = string.find(src, "\nend\r?\n", a)
    return string.sub(src, a, b)
end
local hold = cut("function W.noticeHold(")
local pre = cut("function ZeD_MessagesToasts:prerender()")
check("NOTICE pieces found", hold ~= nil and pre ~= nil)
check("NOTICE the hold has its cap", src:find("W.NOTICE_HOLD_MS = ", 1, true) ~= nil)

local W = {}
local MS = { toasts = {} }
local TAIL = false
local T = { danger = {}, info = {}, warning = {}, accent = {} }
ZeD = { T = T, Bubbles = {
    syncColours = function() end,
    noticeLines = function() return {}, 10 end,
    layoutNoticeBalloons = function(items) for _, it in ipairs(items) do it.x, it.y, it.w, it.h = 0, 0, 10, 10 end return 0, 0, 10, 10 end,
} }
function getPlayer() return {} end
function getPlayerScreenLeft() return 0 end
function getPlayerScreenWidth() return 1000 end
function getSpecificPlayer() return {} end
function W.noticeAnchor() return 500, 900, TAIL end
function W.toastsFor(pn, all) return all end
local function noticeK() return 1 end
local el = { playerNum = 0, x = 0, y = 0, width = 1, height = 1 }
function el:setX(v) self.x = v end
function el:setY(v) self.y = v end
function el:setWidth(v) self.width = v end
function el:setHeight(v) self.height = v end
local ZeD_MessagesToasts = el
local chunk = "local W, MS, noticeK, ZeD_MessagesToasts = ...\n" .. hold
    .. "\n" .. pre .. "\nreturn ZeD_MessagesToasts.prerender"
W.NOTICE_HOLD_MS = 400
local prerender = assert(loadstring(chunk))(W, MS, noticeK, el)
local function frame() el._list_prev = el._list; prerender(el); return el._list and #el._list or 0 end

NOW = 200000
MS.toasts = { { head = "Controller", source = "Controller", text = "unplugged", kind = "info" } }
TAIL = false
check("NOTICE no tail, frame 1: held (nothing drawn)", frame() == 0 and el.width == 1)
NOW = NOW + 16
check("NOTICE no tail, frame 2: still held", frame() == 0)
TAIL = true
NOW = NOW + 16
check("NOTICE the note drew (tail): shown at once", frame() == 1 and el.width > 1)
TAIL = false
NOW = NOW + 16
check("NOTICE shown once: never pulled back when the tail goes", frame() == 1)
-- gone, then a new first balloon
MS.toasts = {}
check("NOTICE emptied", frame() == 0)
MS.toasts = { { head = "x", source = "x", text = "y", kind = "info" } }
NOW = NOW + 1000
check("NOTICE a new first balloon with no tail: held again", frame() == 0)
NOW = NOW + 399
check("NOTICE 399 ms: still held", frame() == 0)
NOW = NOW + 2
check("NOTICE past the cap (401 ms): shown as it is, no tail", frame() == 1)
NOW = NOW + 16
check("NOTICE stays shown", frame() == 1)
MS.toasts = {}
frame()
MS.toasts = { { head = "x", source = "x", text = "y", kind = "info" } }
TAIL = true
check("NOTICE a balloon with the tail there is never held", frame() == 1)

print(string.format("safe_notice_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
