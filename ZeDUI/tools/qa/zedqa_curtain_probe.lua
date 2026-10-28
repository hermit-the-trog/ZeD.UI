-- ZeDUI/tools/qa/zedqa_curtain_probe.lua  (Oct 27 2026)
-- Why a rolled Character window ignores a press on its Loot tab (zedqa_curtain.lua's
-- "Loot Character side down with the press"): rolls the Character window on Health, then
-- reports whether its update runs, which child holds the "tab:loot" zone, what hitZoneAt
-- finds at that zone, and the window after a press made through the update (as the curtain
-- test does) and after a direct press. grep "ZEDQA cpr".
local function say(s) print("ZEDQA cpr " .. tostring(s)) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local Q = {}
local function step(fn, wait) Q[#Q + 1] = { fn = fn, wait = wait or 30 } end
local function zonesOf(w, id)
    local out = {}
    for _, ch in pairs(w:getChildren() or {}) do
        for _, z in ipairs(ch._hitZones or {}) do
            if z.id == id then out[#out + 1] = { ch = ch, z = z } end
        end
    end
    return out
end
local function state(label)
    local w = cw()
    say(label .. ": rolled " .. tostring(w._rolled) .. " tab " .. tostring(w._activeTab) .. " visible " .. tostring(w:isVisible())
        .. " x " .. w:getX() .. " w " .. w:getWidth() .. " strip " .. tostring(w._tabStripPanel and w._tabStripPanel:isVisible()))
end
local ran = 0
-- a press the way the engine delivers it (zedqa_curtain.lua's viaUpdate)
local function viaUpdate(el, fn)
    local own = rawget(el, "update")
    el.update = function(self)
        self.update = own
        self:update()
        fn(self)
        self:onResize()
    end
end
step(function()
    if not (ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end, 60)
step(function()
    local w = cw()
    for _, f in ipairs(zonesOf(w, "tab:health")) do f.ch:onMouseDown(f.z.x + 2, f.z.y + 2); break end
end, 60)
step(function()
    state("on Health")
    local w = cw()
    local r = w._rollBtn
    say("roll button " .. tostring(r ~= nil))
    if r then viaUpdate(w, function(self) self:onMouseDown(r.x + 2, r.y + 2); self:onMouseUp(r.x + 2, r.y + 2) end) end
end, 40)
step(function()
    state("rolled")
    local w = cw()
    local own = rawget(w, "update")
    w.update = function(self) ran = ran + 1; self.update = own; self:update() end
    local zs = zonesOf(w, "tab:loot")
    say("children with tab:loot " .. #zs)
    for i, f in ipairs(zs) do
        local hit = f.ch:hitZoneAt(f.z.x + 2, f.z.y + 2)
        say(string.format("  %d: child %s visible %s zone %d,%d %dx%d -> hitZoneAt %s", i, tostring(f.ch.Type or f.ch), tostring(f.ch:isVisible()),
            f.z.x, f.z.y, f.z.w or -1, f.z.h or -1, tostring(hit and hit.id)))
    end
end, 0)
step(function()
    say("window update ran " .. ran .. " times in 10 frames")
    local w = cw()
    local zs = zonesOf(w, "tab:loot")
    say("rod height " .. tostring(w._rod and w._rod._h) .. " target " .. tostring(w._rod and w._rod._target))
    if zs[1] then viaUpdate(w, function(self) zs[1].ch:onMouseDown(zs[1].z.x + 2, zs[1].z.y + 2); state("  inside the update, after the press") end) end
end, 10)
step(function()
    state("10 frames after the press through the update")
    say("DONE")
end, 1)

local i, wait = 1, 30
local function tick()
    if wait > 0 then wait = wait - 1; return end
    local s = Q[i]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. i .. ": " .. tostring(e)) end
    wait = s.wait
    i = i + 1
end
Events.OnRenderTick.Add(tick)
say("start")
