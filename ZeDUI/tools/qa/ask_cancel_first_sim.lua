-- ZeDUI/tools/qa/ask_cancel_first_sim.lua
-- (Nov 16 2026, QA's audit) On a controller, A on the trash can's "Remove all" opened the question with the focus on
-- Remove, so a second A emptied the trash. CT.syncFocus now lands the focus on Cancel when a question opens and
-- gives it back to the button that asked when the question closes. Runs the real CT.syncFocus with a stub Focus.
-- Run from the repo root: lua51 ZeDUI/tools/qa/ask_cancel_first_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]ask_cancel_first_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/ContainerControls.lua", "rb"))
local src = f:read("*a"):gsub("\r\n", "\n")
f:close()
local body = src:match("\nfunction CT%.syncFocus%(.-\nend\n")
check("finds CT.syncFocus", body ~= nil)
if not body then print("ask_cancel_first_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end

-- the stub Focus: the same clamp-or-seat as FocusManager.setRingZoneElements
local function clamp(i, els) if #els == 0 then return 1 end if i < 1 then return 1 end if i > #els then return #els end return i end
ZeD = { Input = { Focus = {
    setRingZoneElements = function(w, zn, els, keep)
        for _, z in ipairs(w._focusRing) do
            if z.zone == zn then z.elements = els; z.focusedElementIdx = clamp(keep or z.focusedElementIdx, els) end
        end
    end,
    setZoneFocusable = function() end,
} } }
local CT = {}
local chunk = assert(loadstring("local CT, zoneName = ...\n" .. body))
chunk(CT, function() return "worldCtl" end)

local win = { _focusRing = {} }
local content = { getX = function() return 0 end, getWidth = function() return 400 end, _cc = { bottom = true } }
local cc = content._cc
local function hit(key, x) return { key = key, label = key, x = x, y = 0, w = 20, h = 20 } end
local ribbon = { hit("xfer", 0), hit("same", 20), hit("near", 40), hit("sort", 60), hit("trash", 80) }
local function zone() return win._focusRing[1] end
local function focused() local z = zone(); return z.elements[z.focusedElementIdx].ccKey end

cc.hits = ribbon
CT.syncFocus(win, content)
zone().focusedElementIdx = 5
check("the ribbon's last stop is the trash", focused() == "trash", focused())

-- A on the trash: the press sets the question; this frame still has the ribbon's hits (nothing moves)
cc.ask = { id = "trash" }
CT.syncFocus(win, content)
check("the question asked, band not drawn yet: focus stays on the trash", focused() == "trash", focused())

-- the band draws: Cancel and Remove
cc.hits = { hit("no", 200), hit("yes", 260) }
CT.syncFocus(win, content)
check("the question opens on Cancel, not Remove", focused() == "no", focused())

-- the band moves (a resize) while open: the player's pick stays where it is
zone().focusedElementIdx = 2
cc.hits = { hit("no", 210), hit("yes", 270) }
CT.syncFocus(win, content)
check("a band that moves keeps the player's pick", focused() == "yes", focused())

-- B or Cancel: the question closes, the focus goes back to the trash
cc.ask = nil
cc.hits = ribbon
CT.syncFocus(win, content)
check("the question closed: focus back on the trash", focused() == "trash", focused())

-- a second question from another button opens on Cancel too
zone().focusedElementIdx = 4
cc.ask = { id = "sort" }
cc.hits = { hit("no", 200), hit("yes", 260) }
CT.syncFocus(win, content)
check("the next question opens on Cancel too", focused() == "no", focused())
cc.ask = nil
cc.hits = { hit("xfer", 0), hit("same", 20), hit("near", 40), hit("sort", 61), hit("trash", 80) }
CT.syncFocus(win, content)
check("and closes back on the button that asked", focused() == "sort", focused())

print("ask_cancel_first_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
