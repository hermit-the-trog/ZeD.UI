-- ZeDUI/tools/qa/entry_font_sim.lua  (Nov 10 2026, Build; punch list 142, a Pastie's typed words at 1.75x)
-- QA's Mac runs, Nov 10 2026: a note's typed words came out far larger than its hint at 1.75x (right at 1x). The probe
-- of each entry slot's line height, at 4K with ZeD at 1.75x: Small 65 px, Large 76, Dialogue 23, Intro 33. With no
-- game running, the entry face picker (Scale.lua, from ENTRY_SLOTS to X.entryFontAt) runs on stub fonts. It checks:
--   4K      QA's heights: at 1.75x the typing is in Intro (ZeD's 26 px face), never Small or Large; at 2x Intro; at 1x
--           Dialogue (Small there is the game's 49 px face)
--   1080p   ZeD's own faces in every slot (17, 20, 23, 33): 1x Small, 1.25x Large or Dialogue, 1.75x and 2x Intro
--   ODD     a slot that reports no height (still loading) is left out; a slot holding a far larger face than its
--           baked size is read at its measured size
-- Run from the repo root:  lua51 ZeDUI/tools/qa/entry_font_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]entry_font_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local f = io.open(ROOT .. "42/media/lua/shared/ZeD/Scale.lua", "rb"); local src = f:read("*a"); f:close()
local a = src:find("local ENTRY_SLOTS", 1, true)
local b = src:find("--- Keep a ZeD text entry on the scaled face", 1, true)
check("the picker is found in Scale.lua", a and b)
if not (a and b) then print("entry_font_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local chunk = src:sub(a, b - 1)

local function pickWith(H, root)
    UIFont = { Small = "Small", Large = "Large", Dialogue = "Dialogue", Intro = "Intro", Medium = "Medium" }
    local S = { root = function() return root end }
    local X = { realTM = function() return { getFontHeight = function(_, fo) return H[fo] end } end, _fontsSettled = true }
    ZeD = { T = { fontPx = { body = 13 }, fontF2 = "body" } }
    local fn = assert(loadstring("local X, S = ...\n" .. chunk))
    fn(X, S)
    return X.entryFont()
end

local K4 = { Small = 65, Large = 76, Dialogue = 23, Intro = 33 }
check("4K: 1.75x types in Intro", pickWith(K4, 1.75) == "Intro", pickWith(K4, 1.75))
check("4K: 2x types in Intro", pickWith(K4, 2) == "Intro", pickWith(K4, 2))
check("4K: 1x types in Dialogue, not the game's 49 px Small", pickWith(K4, 1) == "Dialogue", pickWith(K4, 1))
for _, r in ipairs({ 0.75, 1, 1.25, 1.5, 1.75, 2 }) do
    local p = pickWith(K4, r)
    check(("4K: %.2fx never Small or Large"):format(r), p ~= "Small" and p ~= "Large", p)
end
local HD = { Small = 17, Large = 20, Dialogue = 23, Intro = 33 }
check("1080p: 1x types in Small", pickWith(HD, 1) == "Small", pickWith(HD, 1))
local p125 = pickWith(HD, 1.25)
check("1080p: 1.25x in Large or Dialogue", p125 == "Large" or p125 == "Dialogue", p125)
check("1080p: 1.75x in Intro", pickWith(HD, 1.75) == "Intro", pickWith(HD, 1.75))
check("1080p: 2x in Intro", pickWith(HD, 2) == "Intro", pickWith(HD, 2))
check("ODD: a slot with no height is left out", pickWith({ Small = 17, Large = 20, Dialogue = nil, Intro = 33 }, 1.4) ~= "Dialogue")
check("ODD: an Intro far larger than 26 px is read at its size", pickWith({ Small = 17, Large = 20, Dialogue = 23, Intro = 76 }, 1.75) == "Dialogue",
      pickWith({ Small = 17, Large = 20, Dialogue = 23, Intro = 76 }, 1.75))
print("entry_font_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
