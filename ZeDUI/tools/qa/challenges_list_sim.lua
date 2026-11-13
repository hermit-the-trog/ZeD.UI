-- ZeD's New game > Challenges list reads the game's challenge list (a player found it empty on beta 12, Nov 13 2026:
-- 42.22 renamed LastStandChallenge to ChallengeList). Runs the real ZeD_MMNewGame:items() over the game's own
-- ChallengeList.lua and challenge files, so a rename shows up here instead of on a player's screen.
-- Set PZ_LUA to the game's media/lua folder if it is not at E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua.
local PZ = os.getenv("PZ_LUA") or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua"
local ROOT = (debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/ZeDUI/tools/qa/") or ".") .. "/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

-- the game's list and its challenges (each file adds itself to ChallengeList with table.insert)
local function run(path)
    local f = io.open(path, "rb"); if not f then return false end
    local s = f:read("*a"); f:close()
    local fn = loadstring(s, "@" .. path)
    if not fn then return false end
    return pcall(fn)
end
check("the game has OptionScreens/ChallengeList.lua", run(PZ .. "/client/OptionScreens/ChallengeList.lua"))
local env_ok = type(ChallengeList) == "table"
check("ChallengeList is the game's challenge table", env_ok)
-- challenges call game functions at load: stub what they touch, then add them
local stub = setmetatable({}, { __index = function() return function() end end })
getText = function(k) return k end
getTextOrNull = getText
-- (each challenge file adds itself when the game fires OnChallengeQuery)
local queries = {}
Events = setmetatable({ OnChallengeQuery = { Add = function(fn) queries[#queries + 1] = fn end } },
    { __index = function() return { Add = function() end, Remove = function() end } end })
local dir = PZ .. "/client/Challenge/"
local p = io.popen('dir /b "' .. dir:gsub("/", "\\") .. '*.lua" 2>nul')
local n = 0
if p then
    for name in p:lines() do
        if name ~= "ChallengeData.lua" then setmetatable(_G, { __index = function() return stub end }); if run(dir .. name) then n = n + 1 end; setmetatable(_G, nil) end
    end
    p:close()
end
for _, fn in ipairs(queries) do pcall(fn) end
check("the game's challenges load into ChallengeList", env_ok and #ChallengeList > 0, env_ok and #ChallengeList)

-- ZeD's list over it: the real items() from ZeD_MainMenuSaves.lua, cut out of the file
local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuSaves.lua", "rb"))
local src = f:read("*a"); f:close()
local body = src:match("(function ZeD_MMNewGame:items%(%).-\nend%s)")
check("ZeD_MMNewGame:items() found", body ~= nil)
ZeD_MMNewGame = {}
NewGameScreen = { defaultGameModeData = {} }
assert(loadstring(body or "", "@items"))()
local items = ZeD_MMNewGame.items({ challenges = true })
check("ZeD's Challenges list has every challenge", #items == (env_ok and #ChallengeList or -1), #items)
local first = items[1]
check("each item carries its challenge, name and picture", first and first.challenge and first.title == first.challenge.name and first.thumb == first.challenge.image)
print(string.format("challenges_list_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
