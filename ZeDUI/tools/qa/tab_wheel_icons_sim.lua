-- ZeDUI/tools/qa/tab_wheel_icons_sim.lua (Nov 2026, beta 12 merge checks): every window tab has a wheel picture.
-- The wheels' Tabs slices name a tab by its icon (W.TAB_ICONS in ZeD_Wheel.lua, tab iconName -> pixel icon id).
-- A tab added without an entry shows no picture on the wheel (the Fishing tab did: zedqa_wheel_icons step 4).
-- Reads the source: every iconName = "<x>-tab-white" in the client Lua must be a key of W.TAB_ICONS, and the id it
-- maps to must have its 16 px drawing (media/textures/ZeD/wheel/16/zw_<id>.png).
-- Run from the repo root:  lua.exe ZeDUI/tools/qa/tab_wheel_icons_sim.lua   (prints FAIL lines and a last summary line)

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. m) end end

local function read(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a"); f:close(); return s
end
local function exists(path) local f = io.open(path, "rb"); if f then f:close(); return true end; return false end

local CLIENT = "42/media/lua/client/ZeD/"
local wheel = read(CLIENT .. "ZeD_Wheel.lua")
ok(wheel ~= nil, "ZeD_Wheel.lua reads (run from the repo root)")
if not wheel then print(string.format("tab_wheel_icons_sim: %d pass, %d fail", pass, fail)); return end

-- W.TAB_ICONS, from the source
local block = wheel:match("W%.TAB_ICONS%s*=%s*(%b{})")
ok(block ~= nil, "W.TAB_ICONS is found in ZeD_Wheel.lua")
local MAP = {}
for k, v in (block or ""):gmatch('%["([%w%-]+)"%]%s*=%s*"([%w_]+)"') do MAP[k] = v end

-- every tab's iconName in the client Lua (the windows' TABS lists, addTab calls in the tab files and mod support)
local FILES = { "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua", "FishingTab.lua", "CookingTab.lua", "AdminTab.lua",
                "ServerTab.lua", "ModSupport/traitsAsSkills.lua", "ModSupport/SPNCC.lua", "ModSupport/EvolvingTraitsWorld.lua" }
local seen = {}
for _, fn in ipairs(FILES) do
    local src = read(CLIENT .. fn)
    ok(src ~= nil, fn .. " reads")
    for name in (src or ""):gmatch('iconName%s*=%s*"([%w%-]+%-tab%-white)"') do seen[name] = fn end
end
ok(seen["fishing-tab-white"] ~= nil, "the Fishing tab's icon name is found")

for name, fn in pairs(seen) do
    local id = MAP[name]
    ok(id ~= nil, name .. " (" .. fn .. ") has a wheel icon in W.TAB_ICONS")
    if id then
        ok(exists("42/media/textures/ZeD/wheel/16/zw_" .. id .. ".png"), name .. " -> " .. id .. " has its 16 px drawing")
    end
end
ok(MAP["fishing-tab-white"] == "rod", "the Fishing tab's slice shows the rod (got " .. tostring(MAP["fishing-tab-white"]) .. ")")

print(string.format("tab_wheel_icons_sim: %d pass, %d fail", pass, fail))
