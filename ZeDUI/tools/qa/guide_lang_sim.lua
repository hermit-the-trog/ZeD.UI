-- ZeDUI/tools/qa/guide_lang_sim.lua  (Nov 11 2026, Build; punch list 154)
-- Which survival guide a game's language gets: the book, or the plain window where the book's faces can't draw the
-- language (Chinese, Japanese, Korean, Thai). AR is the game's Argentine Spanish, not Arabic: it gets the book (it was
-- on the window's list by that misreading, so Argentine players got the window). With no game running, the list and
-- W.useBook cut from the real ZeD_SurvivalGuide.lua, on stubs.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/guide_lang_sim.lua
-- It prints FAIL lines and a last line "guide_lang_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]guide_lang_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_SurvivalGuide.lua", "rb"); local src = f:read("*a"); f:close()
local a = src:find("local NO_BOOK_LANGS", 1, true)
local b = a and src:find("\nend\n", src:find("function W.useBook()", a, true), true)
check("the language list and useBook are found in ZeD_SurvivalGuide.lua", a and b)
if not (a and b) then print("guide_lang_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local W = {}
local LANG = "EN"
ZeD = { GuideBook = { open = function() end }, Settings = { guideSimple = function() return false end } }
Translator = { getLanguage = function() return { name = function() return LANG end } end }
assert(loadstring("local W = ...\n" .. src:sub(a, b + 4)))(W)
for _, L in ipairs({ "EN", "ES", "AR", "PTBR", "RU", "UA", "PL", "DE" }) do
    LANG = L
    check(L .. " gets the book" .. (L == "AR" and " (Argentine Spanish)" or ""), W.useBook() == true)
end
for _, L in ipairs({ "CN", "CH", "JP", "KO", "TH" }) do
    LANG = L
    check(L .. " gets the window (the book's faces can't draw it)", W.useBook() == false)
end
LANG = "AR"
ZeD.Settings.guideSimple = function() return true end
check("Simple set: the window, whatever the language", W.useBook() == false)

print("guide_lang_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
