-- ZeDUI/tools/qa/perf_micro.lua  (Oct 22 2026)
-- What one draw call costs from Lua, by path (the drawing-cost work): a hidden-in-the-corner
-- panel draws N rects / texts / textures a frame through each path for 120 frames, timed with
-- getTimestampMs; prints microseconds per call. Paths: the ISUIElement wrapper, the Java method
-- called directly, and the cached Java method; since Nov 20 2026 also ZeD's lean paths and the small helpers a text draw
-- goes through. "ZEDQA pmic ... DONE".
local function say(s) print("ZEDQA pmic " .. tostring(s)) end
local N = 400
local FR = 120
local tex = getTexture("media/ui/white.png") or getTexture("media/textures/ZeD/belt/round/d40.png")
local font = ZeD and ZeD.T and ZeD.T.fontF2 or UIFont.Small
local tests = {
    { "rect wrapper", function(p) for i = 1, N do p:drawRect(0, 0, 1, 1, 0.01, 1, 1, 1) end end },
    { "rect java", function(p) local jo = p.javaObject; for i = 1, N do jo:DrawTextureScaledColor(nil, 0, 0, 1, 1, 1, 1, 1, 0.01) end end },
    { "rect java cached", function(p) local jo = p.javaObject; local f = jo.DrawTextureScaledColor; for i = 1, N do f(jo, nil, 0, 0, 1, 1, 1, 1, 1, 0.01) end end },
    { "text wrapper", function(p) for i = 1, N do p:drawText("Abc", 0, 0, 1, 1, 1, 0.01, font) end end },
    { "text java", function(p) local jo = p.javaObject; for i = 1, N do jo:DrawText(font, "Abc", 0, 0, 1, 1, 1, 1, 0.01) end end },
    { "tex aspect wrapper", function(p) for i = 1, N do p:drawTextureScaledAspect(tex, 0, 0, 1, 1, 0.01, 1, 1, 1) end end },
    { "tex aspect java", function(p) local jo = p.javaObject; for i = 1, N do jo:DrawTextureScaledAspect(tex, 0, 0, 1, 1, 1, 1, 1, 0.01) end end },
    { "measure TM", function(p) local tm = ZeD.TM; for i = 1, N do tm:MeasureStringX(font, "Abc def") end end },
    -- (Nov 20 2026, QA: the paths ZeD's own classes take, to see where a text draw's time goes now)
    { "text lean (ZeD classes)", function(p) local f = ZeD.LeanDraw and ZeD.LeanDraw.drawText; if not f then return end; for i = 1, N do f(p, "Abc", 0, 0, 1, 1, 1, 0.01, font) end end },
    { "text lean, 16 letters", function(p) local f = ZeD.LeanDraw and ZeD.LeanDraw.drawText; if not f then return end; for i = 1, N do f(p, "Claw Hammer (2) x", 0, 0, 1, 1, 1, 0.01, font) end end },
    { "rect lean (ZeD classes)", function(p) local f = ZeD.LeanDraw and ZeD.LeanDraw.drawRect; if not f then return end; for i = 1, N do f(p, 0, 0, 1, 1, 0.01, 1, 1, 1) end end },
    { "Text.zoomOf", function(p) local f = ZeD.Text.zoomOf; for i = 1, N do f(font) end end },
    { "Text.scriptSwap", function(p) local f = ZeD.Text.scriptSwap; if not f then return end; for i = 1, N do f("Claw Hammer (2) x", 1.2, 64) end end },
    { "Text.width", function(p) local f = ZeD.Text.width; if not f then return end; for i = 1, N do f(font, "Claw Hammer (2) x") end end },
    { "T.px", function(p) local f = ZeD.T.px; for i = 1, N do f(6) end end },
    { "ZeD.tr", function(p) local f = ZeD.tr; for i = 1, N do f("UI_ZeD_Settings_Lite") end end },
    { "Safe.on", function(p) local f = ZeD.Safe.on; for i = 1, N do f() end end },
    { "Safe.guard of an empty function", function(p) local f, e = ZeD.Safe.guard, function() end; for i = 1, N do f(p, e, "mic") end end },
    { "pcall of a new closure", function(p) local x = 0; for i = 1, N do pcall(function() x = x + 1 end) end end },
    { "empty loop", function(p) local x = 0; for i = 1, N do x = x + i end end },
}
local panel = ISPanel:new(0, 0, 2, 2)
panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
panel:initialise()
panel:addToUIManager()
local st = { i = 1, f = 0, acc = 0 }
panel.prerender = function(self)
    local t = tests[st.i]
    if not t then return end
    local t0 = getTimestampMs()
    t[2](self)
    st.acc = st.acc + (getTimestampMs() - t0)
    st.f = st.f + 1
    if st.f >= FR then
        say(string.format("MIC|%s|%.2f us per call", t[1], st.acc * 1000 / (FR * N)))
        st.i, st.f, st.acc = st.i + 1, 0, 0
        if not tests[st.i] then
            panel:removeFromUIManager()
            say("DONE")
        end
    end
end
say("start " .. #tests .. " tests, " .. N .. " calls x " .. FR .. " frames")
