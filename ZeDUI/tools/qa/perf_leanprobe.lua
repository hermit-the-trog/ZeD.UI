-- ZeDUI/tools/qa/perf_leanprobe.lua  (Oct 22 2026)
-- Are the lean draw calls (Overrides/TextScale.lua) on the ZeD classes? Prints, per class, whether
-- its drawRect / drawText / drawTextureScaledAspect are ZeD.LeanDraw's, and what a belt and a
-- window resolve to. "ZEDQA plp ... DONE".
local function say(s) print("ZEDQA plp " .. tostring(s)) end
local function probe()
local L = ZeD.LeanDraw
say("LeanDraw " .. tostring(L ~= nil))
for _, cn in ipairs({ "ZeD_Panel", "ZeD_Window", "ZeD_BeltHUD", "ZeD_Dashboard", "ZeD_ItemCard" }) do
    local c = _G[cn]
    if type(c) == "table" then
        local parts = {}
        for _, m in ipairs({ "drawRect", "drawText", "drawTextureScaledAspect", "drawRectBorder" }) do
            local raw = rawget(c, m)
            local res = c[m]
            parts[#parts + 1] = m .. ": raw=" .. (raw == nil and "nil" or (L and raw == L[m] and "LEAN" or "other"))
                .. " resolved=" .. ((L and res == L[m]) and "LEAN" or (res == ISUIElement[m] and "ISUIElement" or "other"))
        end
        say(cn .. " zedScaled=" .. tostring(c.zedScaled) .. " | " .. table.concat(parts, " | "))
    else
        say(cn .. " missing")
    end
end
local function inst(name, o)
    if not o then say(name .. " instance: none"); return end
    local parts = {}
    for _, m in ipairs({ "drawRect", "drawText", "drawTextureScaledAspect" }) do
        local raw = rawget(o, m)
        local res = o[m]
        parts[#parts + 1] = m .. ": raw=" .. tostring(raw ~= nil) .. " resolved=" .. ((L and res == L[m]) and "LEAN" or (res == ISUIElement[m] and "ISUIElement" or "other"))
    end
    say(name .. " instance | " .. table.concat(parts, " | "))
end
inst("belt", ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD())
inst("char window", ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow())
local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
inst("char content", cw and cw._mainContent)
end
-- (DONE on a later frame: the runner counts a script's lines only after the bridge has said it ran it)
local waitN = 0
local function later()
    waitN = waitN + 1
    if waitN < 30 then return end
    Events.OnRenderTick.Remove(later)
    probe()
    say("DONE")
end
Events.OnRenderTick.Add(later)
