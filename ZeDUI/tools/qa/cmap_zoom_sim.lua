-- ZeDUI/tools/qa/cmap_zoom_sim.lua  (Nov 12 2026, G7): the Controller map's bumper lines say the zoom the code does.
-- BumperChord.lua: hold LB, tap RB zooms IN (doZoomScroll -1); hold RB, tap LB zooms OUT (+1). The Controller map's
-- UI_ZeD_CMap_LB said "LB + RB zooms out" and UI_ZeD_CMap_RB "RB + LB zooms in", the other way round, in all 28
-- languages. This reads every UI.json and checks the phrase after "LB + RB" is the language's zoom-in phrase, and the
-- one after "RB + LB" is not.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/cmap_zoom_sim.lua
-- It prints FAIL lines and a last line "cmap_zoom_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]cmap_zoom_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- each language's zoom-in phrase, as its UI.json words it (UTF-8 bytes; the .lua files keep to ASCII)
local ZOOM_IN = {
    AR = "acerca el zoom",
    CA = "apropa",
    CH = "\230\148\190\229\164\167\232\166\150\233\135\142",
    CN = "\230\148\190\229\164\167\232\167\134\233\135\142",
    CS = "p\197\153ibl\195\173\197\190\195\173",
    DA = "zoomer ind",
    DE = "zoomt hinein",
    EN = "zooms in",
    ES = "acerca el zoom",
    ES_CL = "acerca el zoom",
    ES_MX = "acerca el zoom",
    FI = "l\195\164hent\195\164\195\164",
    FR = "zoome",
    HU = "nagy\195\173t",
    ID = "memperbesar",
    IT = "aumenta lo zoom",
    JP = "\227\129\167\230\139\161\229\164\167",
    KO = "\235\161\156 \237\153\149\235\140\128",
    NL = "zoomt in",
    NO = "zoomer inn",
    PL = "przybli\197\188a",
    PT = "aproxima o zoom",
    PTBR = "aproxima o zoom",
    RO = "m\196\131re\200\153te",
    RU = "\208\191\209\128\208\184\208\177\208\187\208\184\208\182\208\176\208\181\209\130",
    TH = "\224\184\139\224\184\185\224\184\161\224\185\128\224\184\130\224\185\137\224\184\178",
    TR = "yak\196\177nla\197\159t\196\177r\196\177r",
    UA = "\208\189\208\176\208\177\208\187\208\184\208\182\208\176\209\148",
}

-- the code first: hold LB + tap RB is the zoom-in step
local bc = readFile("42/media/lua/client/ZeD/Input/BumperChord.lua") or ""
check("BumperChord: hold LB, tap RB zooms in", bc:find("Hold LB, tap RB  -> one zoom-IN", 1, true) ~= nil
    and bc:find("_fire(c, -1) -- LB-then-RB = zoom-in", 1, true) ~= nil)

local function value(json, key)
    local a = json:find('"' .. key .. '": "', 1, true)
    if not a then return nil end
    local s = a + #key + 5
    local e = json:find('",', s, true) or json:find('"\r?\n', s)
    return e and json:sub(s, e - 1) or nil
end

local n = 0
for lang, zin in pairs(ZOOM_IN) do
    n = n + 1
    local json = readFile("42/media/lua/shared/Translate/" .. lang .. "/UI.json")
    check(lang .. ": UI.json read", json ~= nil)
    if json then
        local lb, rb = value(json, "UI_ZeD_CMap_LB"), value(json, "UI_ZeD_CMap_RB")
        check(lang .. ": both bumper lines found", lb and rb)
        if lb and rb then
            local inLB = lb:find("LB + RB " .. zin, 1, true) or lb:find("LB + RB" .. zin, 1, true)
            local inRB = rb:find("RB + LB " .. zin, 1, true) or rb:find("RB + LB" .. zin, 1, true)
            check(lang .. ": LB + RB zooms in", inLB ~= nil, lang)
            check(lang .. ": RB + LB does not say zoom in", inRB == nil, lang)
        end
    end
end
check("all 28 languages listed", n == 28, n)

print("cmap_zoom_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
