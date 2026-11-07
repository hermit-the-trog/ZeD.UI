-- ZeDUI/tools/qa/mp_clip_hook.lua  (Nov 7 2026, QA; merge 1, clips): counts, for each window's drawer, the frames that end with more
-- clips than they began with (ZEDQA_CLIPS), until mp_clip_report.lua prints them. grep "ZEDQA mch".
ZEDQA_CLIPS = { char = 0, world = 0, frames = 0, worst = {} }
local function hook(w, key)
    local d = w and w._drawerPanel
    if not d or d._mchHooked then return end
    local orig = d.prerender
    d._mchHooked = true
    d.prerender = function(self)
        local a = self._zedStencilN or 0
        orig(self)
        ZEDQA_CLIPS.frames = ZEDQA_CLIPS.frames + 1
        local dd = (self._zedStencilN or 0) - a
        if dd ~= 0 then
            ZEDQA_CLIPS[key] = ZEDQA_CLIPS[key] + 1
            ZEDQA_CLIPS.worst[key .. ":" .. tostring(w._activeTab) .. ":" .. tostring(w._drawerMode)] = dd
        end
    end
end
local n = 0
local function tick()
    n = n + 1
    if n == 30 and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    if n == 90 then
        hook(ZeD_CharacterWindow.getWindow(), "char")
        hook(ZeD_WorldWindow.getWindow(), "world")
        print("ZEDQA mch hooked")
        print("ZEDQA mch DONE")
        Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
