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

-- (QA's beta 17 run) the Journal's delete question swapped the zone's stops for Cancel and Delete and the clamped
-- index landed on Delete. FocusManager now seats a stop marked land = true when the focused stop is gone.
local function readSrc(p) local fh = assert(io.open(ROOT .. p, "rb")); local s = fh:read("*a"):gsub("\r\n", "\n"); fh:close(); return s end
local fm = readSrc("42/media/lua/client/ZeD/Input/FocusManager.lua")
local setBody = fm:match("\nfunction Focus%.setRingZoneElements%(.-\nend\n")
check("finds Focus.setRingZoneElements", setBody ~= nil)
local Focus = {}
local resolve = function(w, zn) for i, z in ipairs(w._focusRing) do if z.zone == zn then return i end end end
local clampIdx = function(i, els) if #els == 0 then return 1 end return math.max(1, math.min(i or 1, #els)) end
assert(loadstring("local Focus, _resolveZoneIdx, _clampIdx = ...\n" .. (setBody or "")))(Focus, resolve, clampIdx)
local jw = { _focusRing = { { zone = "jr", focusedElementIdx = 5, elements = {} } } }
local jz = jw._focusRing[1]
for i = 1, 6 do jz.elements[i] = { id = "journal:del:" .. i } end
local jt = readSrc("42/media/lua/client/ZeD/JournalTab.lua")
check("the Journal's Cancel is marked to take the focus", jt:find('id = "journal:ask:cancel", land = true', 1, true) ~= nil)
Focus.setRingZoneElements(jw, "jr", { { id = "journal:ask:cancel", land = true }, { id = "journal:ask:verb" } })
check("the Journal's delete question opens on Cancel", jz.elements[jz.focusedElementIdx].id == "journal:ask:cancel", jz.focusedElementIdx)
jz.focusedElementIdx = 2
Focus.setRingZoneElements(jw, "jr", { { id = "journal:ask:cancel", land = true }, { id = "journal:ask:verb" } })
check("a rebuild while the question is up keeps the player's pick", jz.focusedElementIdx == 2, jz.focusedElementIdx)
Focus.setRingZoneElements(jw, "jr", { { id = "a" }, { id = "b" }, { id = "c" } }, 3)
check("an asked-for index still wins", jz.focusedElementIdx == 3, jz.focusedElementIdx)

-- the machine cards' questions (dig up a crop, take a grill apart, empty) open on Cancel
local oc = readSrc("42/media/lua/client/ZeD/ObjectCards.lua")
check("an object card's question opens on Cancel", oc:find('self._pendingFocus = "oc:confirm:no"', 1, true) ~= nil
    and oc:find('self._pendingFocus = "oc:confirm:yes"', 1, true) == nil)

print("ask_cancel_first_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
