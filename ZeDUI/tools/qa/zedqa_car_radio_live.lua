-- ZeDUI/tools/qa/zedqa_car_radio_live.lua  (Oct 15 2026)
-- Real mouse and keys on the car radio: sets the pickup up (radio fitted and
-- switched off, a CD with a recording in the bag, the radio up close), then
-- watches. Every change of the radio's state is logged ("ZEDQA lv"); writing a
-- name into Zomboid/Lua/zedqa_shot.txt takes a screenshot (zqa_lv_<name>.png).
-- Drive it with gin.ps1 (click / hold / rclick / wheel / keys). Reloads
-- ZeD_CarRadio.lua from Zomboid/Lua/zed_reload_cr.lua when present. Writing
-- "stop" ends it, puts the radio back as it was and takes the CDs away.
-- TARGET "police" runs it on the sheriff car's two-way set instead (its
-- stored channels are put back as they were on "stop").

local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA lv " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_lv_" .. n .. ".png") end) end
local RO, CR = ZeD.RadioOps, ZeD.CarRadio
local TARGET = "pickup"
local pickup, savedP6, savedAll
local function near(pred, maxD)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if pred(v) then local d = v:DistTo(p); if d < maxD and (not bd or d < bd) then best, bd = v, d end end
    end
    return best
end
local function part() return pickup and pickup:getPartById("Radio") end
local function readShotFile()
    local r = getFileReader("zedqa_shot.txt", false)
    if not r then return nil end
    local l = r:readLine(); r:close()
    return l
end

-- reload the prop's code (a copy in Zomboid/Lua) so this run uses the latest
local r = getFileReader("zed_reload_cr.lua", false)
if r then
    local lines, l = {}, r:readLine()
    while l do lines[#lines + 1] = l; l = r:readLine() end
    r:close()
    CR.closeFor(pn); CR.props[pn] = nil
    local fn, err = loadstring(table.concat(lines, "\n"))
    if fn then local ok, e = pcall(fn); say("reloaded ZeD_CarRadio ok=" .. tostring(ok) .. " " .. tostring(e)) else say("reload parse " .. tostring(err)) end
end

if TARGET == "police" then pickup = near(function(v) return v:hasLightbar() end, 25)
else pickup = near(function(v) return v:getScriptName() == "Base.PickUpTruck" end, 25) end
if p:getVehicle() ~= pickup then
    if p:getVehicle() then p:getVehicle():exit(p) end
    pickup:enter(0, p); triggerEvent("OnEnterVehicle", p)
end
local dd = part():getDeviceData()
if dd:getIsTurnedOn() then dd:setIsTurnedOn(false) end
local l6 = dd:getDevicePresets():getPresets()
if l6:size() >= 6 then savedP6 = { l6:get(5):getName(), l6:get(5):getFrequency() } end
savedAll = {}
for i = 0, l6:size() - 1 do savedAll[#savedAll + 1] = { l6:get(i):getName(), l6:get(i):getFrequency() } end
dd:setChannel(93200)
local cd = p:getInventory():AddItem("Base.Disc_Retail")
local list = getZomboidRadio():getRecordedMedia():getAllMediaForCategory("CDs")
cd:setRecordedMediaData(list:get(3))
say("cd: " .. cd:getDisplayName())

local last, lastShot, tick = "", readShotFile(), 0
local opened = false
local function t()
    tick = tick + 1
    if tick == 20 and not opened then opened = true; ISVehicleMenu.onSignalDevice(p, part()) end
    if tick % 10 ~= 0 then return end
    local st = part() and RO.read(part())
    local pr = CR.props[pn]
    local ctx = getPlayerContextMenu(pn)
    local zm = ctx and ctx._zedMenu
    local allp = {}
    if st then for i, q in ipairs(st.presets) do allp[#allp + 1] = string.format("%.3f %s", q.freq / 1000, q.name) end end
    local line = st and string.format("presets=[%s] on=%s ch=%s vol=%.1f preset=%s p6=%s media=%s playing=%s flash=%s scan=%s | prop=%s focus=%s top=%s | list=%s",
        table.concat(allp, "; "), tostring(st.on), tostring(st.channel), st.volume or -1, tostring(st.presetIdx), st.presets[6] and string.format("%.1f %s", st.presets[6].freq / 1000, st.presets[6].name) or "-",
        tostring(st.hasMedia), tostring(st.playing), tostring(st.flash), tostring(st.scanning),
        tostring(pr and pr:isReallyVisible()), tostring(pr and pr.focusId), tostring(pr and pr.javaObject and pr.javaObject:isAlwaysOnTop()),
        tostring(zm and zm._ctx and zm._ctx.open)) or "no radio"
    if line ~= last then last = line; say(line) end
    local sf = readShotFile()
    if sf and sf ~= lastShot then
        lastShot = sf
        if sf == "stop" then
            Events.OnTick.Remove(t)
            CR.takeEscape()
            local d2 = part():getDeviceData()
            if d2:hasMedia() then d2:removeMediaItem(p:getInventory()) end
            d2:setIsTurnedOn(false)
            local l = d2:getDevicePresets():getPresets()
            l:clear()
            for _, e in ipairs(savedAll) do l:add(PresetEntry.new(e[1], e[2])) end
            pcall(function() d2:transmitPresets() end)
            local inv = p:getInventory()
            local discs = inv:getAllType("Base.Disc_Retail")
            for i = discs:size() - 1, 0, -1 do inv:Remove(discs:get(i)) end
            say("stopped; radio restored")
        else
            shot(sf); say("shot " .. sf)
            if pr then say(string.format("   prop at %d,%d %dx%d", pr:getX(), pr:getY(), pr:getWidth(), pr:getHeight())) end
            local dash = ZeD.Dashboard.getInstance()
            if dash and sf == "dash" then
                for _, h in ipairs(dash._hit or {}) do if h.id == "radio" or h.id == "vol" or h.id == "preset1" then say(string.format("   dash %s at %d,%d %dx%d", h.id, dash:getX() + h.x, dash:getY() + h.y, h.w, h.h)) end end
            end
            if zm and zm.getX then say(string.format("   list at %d,%d %dx%d", zm:getX(), zm:getY(), zm:getWidth(), zm:getHeight())) end
        end
    end
end
Events.OnTick.Add(t)
say("watching")
