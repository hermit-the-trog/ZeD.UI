-- ZeDUI/tools/qa/zedqa_shade_probe.lua  (Nov 4 2026, Build; a diagnostic, no pass or fail)
-- The rolled-up Character window keeps its full height (QA on d9297868: "char 735 (title 46)" with windowShaded
-- true). This finds what sets the height back. No mouse needed: it rolls the Character
-- window up by calling setWindowShaded(true) itself (its auto roll-up off meanwhile; pins untouched), and logs for 6 frames:
--   - the height right after setWindowShaded, and on each frame after
--   - every Lua setHeight on the window while it is rolled up, with a traceback
--   - every onResize on the window (height and minimumHeight before and after)
-- Then rolls it down and unwraps everything. grep "ZEDQA shp".
local function say(s) print("ZEDQA shp " .. tostring(s)) end
local c = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
if not (c and c:getIsVisible()) then say("open the Character window first"); return end
local oldAuto = c.autoCollapse
c.autoCollapse = false   -- (the auto roll-up and roll-down stay out of the way)

local tbH = c:titleBarHeight()
local origSetHeight = c.setHeight
local origOnResize = c.onResize
local ownSetHeight, ownOnResize = rawget(c, "setHeight"), rawget(c, "onResize")
local setHeightCalls = 0
c.setHeight = function(self, h)
    if self.windowShaded and h and h > tbH + 2 then
        setHeightCalls = setHeightCalls + 1
        say("setHeight(" .. tostring(h) .. ") while rolled up:\n" .. tostring(debug and debug.traceback and debug.traceback() or "(no traceback)"))
    end
    return origSetHeight(self, h)
end
c.onResize = function(self, ...)
    local h0, m0 = self:getHeight(), self.minimumHeight
    local r = origOnResize(self, ...)
    if self.windowShaded then
        say(string.format("onResize: height %s -> %s, minimumHeight %s -> %s", tostring(h0), tostring(self:getHeight()), tostring(m0), tostring(self.minimumHeight)))
    end
    return r
end

say(string.format("before: height %d, title %d, minimumHeight %s, windowShaded %s", c:getHeight(), tbH, tostring(c.minimumHeight), tostring(c.windowShaded)))
c:setWindowShaded(true)
say(string.format("right after setWindowShaded(true): height %d, self.height %s, minimumHeight %s", c:getHeight(), tostring(c.height), tostring(c.minimumHeight)))

local frame = 0
local function tick()
    frame = frame + 1
    say(string.format("frame %d: height %d, self.height %s, minimumHeight %s, windowShaded %s", frame, c:getHeight(), tostring(c.height), tostring(c.minimumHeight), tostring(c.windowShaded)))
    if frame >= 6 then
        Events.OnTick.Remove(tick)
        c.setHeight = ownSetHeight
        c.onResize = ownOnResize
        c:setWindowShaded(false)
        c.autoCollapse = oldAuto
        say(string.format("done: Lua setHeight calls while rolled up %d; height after roll-down %d", setHeightCalls, c:getHeight()))
    end
end
Events.OnTick.Add(tick)
