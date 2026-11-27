-- ZeDUI/tools/qa/oc_track_half_sim.lua  (Nov 26 2026, Build; the director: the tracks card as a half card)
-- The real ObjectCardTrack.lua on stubs: def.half is set, and at the half card's body width every fact (label,
-- value, the dim "Tracking N") ends inside the card, the long ones cut (QA TK2: they clipped at the card edge).
-- On the full card the facts still sit beside the picture.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_track_half_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_track_half_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

local CW = 7   -- every character 7 px wide in every font
local function measure(_, s) return #tostring(s) * CW end
local registered = nil
ZeD = {
    T = { px = function(n) return math.floor(n * 1.75 + 0.5) end, fontF1 = 1, fontF2 = 2, fontF5 = 5,
          accent = { r = 1, g = 0.6, b = 0.2 }, text = { r = 1, g = 1, b = 1 }, textDim = { r = 0.6, g = 0.6, b = 0.6 },
          surf2 = {}, border = {}, borderS = {}, positive = {} },
    TM = { MeasureStringX = measure, getFontHeight = function() return 14 end },
    tr = function(k, a) return (k == "UI_ZeD_Track_TrackingLevel") and ("Tracking level " .. tostring(a)) or "N" end,
    Atoms = {
        frame = function() end, drawStatusDot = function() end,
        truncateText = function(text, font, maxW)
            text = tostring(text)
            if #text * CW <= maxW then return text end
            local n = math.floor(maxW / CW) - 3
            if n < 1 then return "" end
            return string.sub(text, 1, n) .. "..."
        end,
    },
    ObjectCards = {
        ui = { fill = function() end, disc = function() end, run = function() end },
        call = function() return nil end, DOT = "|", cap = function(s) return s end,
        register = function(d) registered = d end,
    },
}
require = function() end
getText = function(k) return "Label:" end
getTextOrNull = function() return nil end
local ok, err = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ObjectCardTrack.lua")
check("ObjectCardTrack.lua loads on the stubs", ok, err)
local def = registered
check("the track card is a half card (def.half)", def and def.half == true)

local function draw(w)
    local texts = {}
    local card = { drawText = function(_, s, x) texts[#texts + 1] = { s = s, x = x } end,
                   drawTextureScaledAspect = function() end }
    local t = { d = { level = 2, type = "Footsteps of a very long animal name here", species = "Medium-sized animal tracks of a deer",
                      fresh = "A few hours old, still clearly visible", dir = "NE" } }
    local h = def.body(card, 0, 0, w, t, {})
    return texts, h
end

local half = ZeD.T.px(200)
local texts, h = draw(half)
local over = nil
for _, e in ipairs(texts) do
    if e.s ~= "N" and e.x + #e.s * CW > half then over = e.s .. " at " .. e.x end
end
check("half card: every fact ends inside the card", over == nil, over)
local cut = false
for _, e in ipairs(texts) do if string.find(e.s, "...", 1, true) then cut = true end end
check("half card: a long value is cut with ...", cut)
check("half card: the body has height", h and h > 0, h)

local full = ZeD.T.px(480)
texts = draw(full)
local firstFactX = nil
for _, e in ipairs(texts) do if e.s == "Label" then firstFactX = e.x; break end end
check("full card: the facts sit beside the picture", firstFactX and firstFactX >= ZeD.T.px(140), firstFactX)

print("oc_track_half_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
