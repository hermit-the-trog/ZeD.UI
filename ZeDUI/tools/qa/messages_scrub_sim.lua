-- ZeDUI/tools/qa/messages_scrub_sim.lua  (Nov 8 2026, hotfix beta 8a): a copied bug report never names the account.
-- Loads the real ZeD_Messages.lua on small stubs, files an error whose text carries the Zomboid folder and a Windows user
-- folder in both slash styles and mixed case, and checks every report text (one error, one source, all) has neither path,
-- keeps the rest of the path, and ends with the line saying the name was taken out.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/messages_scrub_sim.lua
-- It prints FAIL lines and a last line "messages_scrub_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]messages_scrub_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the game's side, as little as the file needs to load
local function hook() return { Add = function() end, Remove = function() end } end
Events = setmetatable({}, { __index = function(t, k) local e = hook(); rawset(t, k, e); return e end })
function require() end
DOC = "C:\\Users\\Danie Q\\Zomboid"
function getMyDocumentFolder() return DOC end
function getModInfoByID() return nil end
function getActivatedMods() return { size = function() return 0 end } end
function getCore() return { getVersion = function() return "42.21.0" end } end
function getTimestampMs() return 1000 end
ZeD = { tr = function(k) return k end }

assert(loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_Messages.lua"))()
local M = ZeD.Messages
check("the file loads with its scrub", M and M.scrub and M.SCRUB_NOTE)

local ERR = table.concat({
    "attempted index: x of non-table: null",
    "function: tick -- file: Foo.lua line # 12 | MOD: Foo",
    "at C:\\Users\\Danie Q\\Zomboid\\Workshop\\Foo\\Contents\\mods\\Foo\\42\\media\\lua\\client\\Foo.lua:12",
    "at c:/users/danie q/zomboid/Lua/foo_settings.txt",
    "at C:\\USERS\\Danie Q\\AppData\\Local\\Temp\\x.tmp",
    "at C:/Users/Danie Q/Downloads/thing.lua",
    "Steam at E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/shared/x.lua",
}, "\n")
M.sources.Foo = { name = "Foo", kind = "err", items = { { k = "err", count = 1, texts = { ERR }, whens = { "10:02" } } } }

local function verify(label, text)
    check(label .. ": no user folder name", not string.find(string.lower(text), "danie q", 1, true), text)
    check(label .. ": no Users folder", not string.find(string.lower(text), ":\\users\\", 1, true) and not string.find(string.lower(text), ":/users/", 1, true))
    check(label .. ": the Zomboid folder reads ~/Zomboid", string.find(text, "~/Zomboid\\Workshop\\Foo", 1, true) and string.find(text, "~/Zomboid/Lua/foo_settings.txt", 1, true))
    check(label .. ": another folder reads ~\\ or ~/", string.find(text, "~\\AppData\\Local", 1, true) and string.find(text, "~/Downloads/thing.lua", 1, true))
    check(label .. ": other paths stay", string.find(text, "E:/Project Zomboid/steamapps", 1, true))
    local tail = string.sub(text, -#M.SCRUB_NOTE)
    check(label .. ": the line is the last line", tail == M.SCRUB_NOTE and string.sub(text, -#M.SCRUB_NOTE - 1, -#M.SCRUB_NOTE - 1) == "\n")
end
verify("one error", M.reportOne("Foo", 1))
verify("the source", M.report("Foo"))
local all, n = M.reportAll()
verify("all", all)
check("all still counts the errors", n == 1, n)

-- forward slashes in the game's own folder, and a folder off the Users tree
DOC = "D:/Games/Zomboid"
local t = M.scrub("at D:\\Games\\Zomboid\\console.txt and d:/games/zomboid/Lua/x")
check("a Zomboid folder anywhere reads ~/Zomboid", t:find("~/Zomboid\\console.txt", 1, true) and t:find("~/Zomboid/Lua/x", 1, true), t)
check("nothing to take out: the line still goes on", M.scrub("plain"):sub(-#M.SCRUB_NOTE) == M.SCRUB_NOTE)
-- the account's own folder with nothing after it
DOC = "C:\\Users\\Kade\\Zomboid"
local h = M.scrub("home is C:\\Users\\Kade and C:/Users/kade")
check("the bare user folder reads ~", not h:lower():find("kade", 1, true), h)

print("messages_scrub_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
