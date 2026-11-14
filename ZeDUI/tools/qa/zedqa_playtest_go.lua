-- ZeDUI/tools/qa/zedqa_playtest_go.lua  (Nov 14 2026, QA): pushed once into the director's ZeD-Playtest save. Lightens
-- the carried load (keeps worn things, keys, the test items), sets daytime, ZeD's setup for the checks (Put things back
-- on, moodles above the belt, hint strip Always), then leaves a logger running: pad presses with their focus, focus
-- changes, game cursors (drag), ZeD_Prompt focus and Lua errors. grep "ZEDQA ptl".
local function say(s) print("ZEDQA ptl " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
-- the load
local keep = { Saucepan = 1, MugWhite = 1, FirstAidKit = 1, Notebook = 1, Newspaper = 1, BookBlacksmith1 = 1,
    BookBlacksmith2 = 1, BookButchering1 = 1, BookButchering2 = 1, KeyRing = 1, Key1 = 1 }
local inv = p:getInventory()
local items, removed = inv:getItems(), 0
for i = items:size() - 1, 0, -1 do
    local it = items:get(i)
    local t = it:getType()
    local worn = false; pcall(function() worn = p:isEquipped(it) or p:isEquippedClothing(it) end)
    if not keep[t] and not worn and not t:find("Key") then inv:Remove(it); removed = removed + 1 end
end
if not inv:getFirstType("MugWhite") then inv:AddItem("Base.MugWhite") end
say("load: removed " .. removed .. " items; now " .. inv:getItems():size() .. " items, " .. string.format("%.1f", inv:getCapacityWeight()) .. " kg")
pcall(function() local gt = getGameTime(); gt:setTimeOfDay(10.0) end)
pcall(function() ZeD.Settings.putBackOption:setValue(2) end)
pcall(function() ZeD.Settings.moodlePlaceOption:setValue(3) end)
pcall(function() ZeD.Settings.hintStripOption:setValue(1) end)
pcall(function() if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.save then PZAPI.ModOptions:save() end end)
say("setup: put back " .. tostring(ZeD.Settings.putBackOn()) .. ", moodles " .. tostring(ZeD.Settings.moodlePlaceOption:getValue()) ..
    ", hint strip " .. tostring(ZeD.Settings.hintStripMode()))
pcall(function() p:setGodMod(false); p:setInvincible(false) end)
-- the logger
local function desc(o)
    if o == nil then return "nil" end
    local s = tostring(o._zedLabel or o.Type or o)
    local ok, v = pcall(function() return o:isReallyVisible() end)
    return s .. ((ok and v) and "" or " (hidden)")
end
local names = {}
for k, v in pairs(Joypad) do if type(v) == "number" then names[v] = k end end
if not ZEDQA_PTL_WRAPPED then
    ZEDQA_PTL_WRAPPED = true
    local origPress = JoypadControllerData.onPressButton
    JoypadControllerData.onPressButton = function(self, b, ...)
        local jd = self.joypad
        local d = getCell() and getCell():getDrag(0)
        say("press " .. tostring(names[b] or b) .. " | focus " .. desc(jd and jd.focus) .. " | cursor " .. tostring(d and (d.Type or "yes")) .. " | paused " .. tostring(isGamePaused()))
        return origPress(self, b, ...)
    end
    local origNoFocus = JoypadControllerData.onPressButtonNoFocus
    JoypadControllerData.onPressButtonNoFocus = function(self, b, ...)
        say("  no-focus path got " .. tostring(names[b] or b))
        return origNoFocus(self, b, ...)
    end
    Events.OnTick.Add(function() end)
end
local last = ""
local function tick()
    local jd = JoypadState.players[1]
    local pl = getPlayer()
    local d = getCell() and getCell():getDrag(0)
    local m = "?"; pcall(function() m = tostring(wasMouseActiveMoreRecentlyThanJoypad()) end)
    local s = "focus " .. desc(jd and jd.focus) .. " | cursor " .. tostring(d and (d.Type or "yes")) .. " | pad bound " ..
        tostring(pl and pl:getJoypadBind()) .. " | paused " .. tostring(isGamePaused()) .. " | mouse more recent " .. m ..
        " | dead " .. tostring(pl and pl:isDead())
    if s ~= last then say("state: " .. s); last = s end
end
Events.OnRenderTick.Add(tick)
say("logger running; the director can play")
