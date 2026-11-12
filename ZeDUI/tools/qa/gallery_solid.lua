-- ZeDUI/tools/qa/gallery_solid.lua  (Nov 12 2026, QA; the gallery plan v2 retakes): solid windows and no hint strip for
-- the cinema pictures. Run right after gallery_b11_look.lua (it keeps the options it changes in GAL_T14.optWas, so
-- gallery_t14_end.lua puts them back with the rest and saves; zedqa_run.ps1 also writes the director's ModOptions.ini back
-- once the game has closed).
--   see-through 100 (option 1), as zedqa_director_review.lua does: with the director's 90 and "Solid while in use" on,
--     the window the pointer was not over drew see-through
--   the hint strip above the belt ("Right Click | More", ZeD_HintStrip.lua) Off (option 3)
-- grep "ZEDQA gsol".
local function say(s) print("ZEDQA gsol " .. tostring(s)) end
GAL_T14 = GAL_T14 or {}
local G = GAL_T14
G.optWas = G.optWas or {}
local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
local SET = { seeThrough = 1, hintStrip = 3 }
if opts then
    for id, v in pairs(SET) do
        local o = opts:getOption(id)
        if o then
            if G.optWas[id] == nil then G.optWas[id] = o:getValue() end
            pcall(function() o:setValue(v) end)
        end
    end
    pcall(function() ZeD.Settings.reapplyFromOptions() end)
    pcall(function() PZAPI.ModOptions:save() end)
end
-- (Nov 12 2026) the mouse's help words in the window footers, not the pad's: a controller left connected put ZeD in pad
-- mode during the first retake (the World window's footer read "L Sort R Grid A Choose Y Windows"). The mode is locked
-- to keyboard and mouse for the run (the lock lives only in this game session)
pcall(function() ZeD.Input.Detector.setLockedMode("kbm") end)
say("input mode " .. tostring(ZeD.Input and ZeD.Input.Detector and ZeD.Input.Detector.getMode and ZeD.Input.Detector.getMode()) .. " (locked)")
say(string.format("see-through %s (was option %s) | hint strip %s (was option %s)",
    tostring(ZeD.Settings.seeThrough and ZeD.Settings.seeThrough()), tostring(G.optWas.seeThrough),
    tostring(ZeD.Settings.hintStripMode and ZeD.Settings.hintStripMode()), tostring(G.optWas.hintStrip)))
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); say("DONE") end
Events.OnTick.Add(later)
