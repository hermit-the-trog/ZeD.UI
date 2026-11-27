-- ZeDUI/tools/qa/rtv_battery_sim.lua  (Nov 27 2026, Build; QA B4 / R30)
-- A radio and a TV on one square: the battery pressed on the radio's tab must go to the radio. The game's action
-- names a placed set by its square, and the square answered for the TV, so the action failed its isValid (a TV
-- takes no battery) and was dropped. The actions block is cut from RtvFace.lua and run on stubs.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/rtv_battery_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]rtv_battery_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/RtvFace.lua", "rb"))
local src = f:read("*a"):gsub("\r\n", "\n"); f:close()
local a = src:find("local function param(chr, dev)", 1, true)
local b = src:find("R.queueBattery, R.queueMedia = battery, media", 1, true)
check("the actions block is found", a ~= nil and b ~= nil)
if not (a and b) then print("rtv_battery_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local block = src:sub(a, b + #"R.queueBattery, R.queueMedia = battery, media")

local TV_DD = { name = "tv" }
local RADIO_DD = { name = "radio" }
local queued = {}
instanceof = function() return false end
ISInventoryPaneContextMenu = { transferIfNeeded = function() end }
ISTimedActionQueue = { add = function(x) queued[#queued + 1] = x end }
-- the game's action: the device data from the square, which answers for the TV
ISDeviceBatteryAction = {
    getDeviceDataParameter = function() return { square = true } end,
    new = function(_, chr, isRemove, item, param) return { deviceData = TV_DD, isRemove = isRemove, item = item } end,
}
ISDeviceMediaAction = { new = function(_, chr, isRemove, item, param) return { deviceData = TV_DD } end }
local R = {}
local fn = assert(loadstring("local R = ...\n" .. block))
fn(R)
local radio = { getDeviceData = function() return RADIO_DD end }
R.queueBattery({}, radio, false, { battery = true })
check("one action queued", #queued == 1, #queued)
check("the battery goes to the radio the tab shows, not the TV on its square", queued[1] and queued[1].deviceData == RADIO_DD,
    queued[1] and queued[1].deviceData and queued[1].deviceData.name)
queued = {}
R.queueMedia({}, radio, false, { disc = true })
check("the media action too", queued[1] and queued[1].deviceData == RADIO_DD)
print("rtv_battery_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
