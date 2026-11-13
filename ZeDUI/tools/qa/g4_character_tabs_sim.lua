-- ZeDUI/tools/qa/g4_character_tabs_sim.lua  (Nov 12 2026, Build; punch list 175 a, b, f and the leftovers): the
-- Character window's tabs (Health, Protection, Equipped, Loadouts, Identity, Thermal, Skills, Hair) checked with no
-- game running, on the real files.
--   PROTECT  a part's defense adds its worn layers, at most 100, as the game counts it
--            (IsoGameCharacter.getBodyPartClothingDefense); a garment held in a hand is not worn (the worn list, not
--            item:isEquipped(), which is true for the hands too).
--   HEALTH   the figure zone's measure counts the game's word for Overall on its own lines (drawOverall), so the
--            scroll range is right on the frame it changes, not one frame late.
--   TRAITS   a trait row is the icon, then the name: no colored square (the design review's A4).
--   HEADS    one section style (the design review's D6): the tab's title, and under it the tab fill's small mono
--            line (drawCategoryRow, 20u); no band-strip section head (drawSectionHeader), no large title but the
--            tab's own.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/g4_character_tabs_sim.lua
-- It prints FAIL lines and a last line "g4_character_tabs_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]g4_character_tabs_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
local DIR = "42/media/lua/client/ZeD/"

-- the stand-ins: tokens at 1x, a text manager 7 px a letter
require = function() return nil end
getText = function(k) return k end
local col = function() return { r = 1, g = 1, b = 1, a = 1 } end
ZeD = {
    T = setmetatable({ px = function(n) return n end, fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", fillBarH = 10,
                       sp = { scrollbarW = 10, rowGap = 2, xs = 4, sm = 8, figureW = 0, figureH = 0, afterGroove = 6 } },
                     { __index = function(t, k) local c = col(); rawset(t, k, c); return c end }),
    TM = { getFontHeight = function(_, f) return (f == "F1") and 14 or 19 end,
           MeasureStringX = function(_, f, s) return #tostring(s) * 7 end },
    tr = function(k) return k end,
    partAbbrev = function(s) return s end,
}

-- ---------------------------------------------------------------------------
section("PROTECT: the layers add up, at most 100; a garment in a hand is not worn")
-- ---------------------------------------------------------------------------
do
    local okLoad, err = pcall(dofile, ROOT .. DIR .. "ProtectionTab.lua")
    check("ProtectionTab.lua loads", okLoad, err)
    local P = ZeD.ProtectionTab
    if okLoad and P and P.gatherData then
        instanceof = function(o, cls) return cls == "Clothing" and type(o) == "table" and o._clothing == true end
        local function list(t)
            return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
        end
        -- a garment: its parts and its bite / scratch / bullet defense on each
        local function garment(name, parts, bite, scratch, bullet, equipped)
            local ps = {}
            for i, p in ipairs(parts) do ps[i] = setmetatable({}, { __tostring = function() return p end }) end
            return { _clothing = true,
                getName = function() return name end, getTex = function() return nil end,
                getCoveredParts = function() return list(ps) end,
                isEquipped = function() return equipped end,
                getDefForPart = function(_, part, isBite, isBullet)
                    if isBullet then return bullet end
                    if isBite then return bite end
                    return scratch
                end }
        end
        local function player(wornItems, inventoryOnly)
            local inv = {}
            for _, g in ipairs(wornItems) do inv[#inv + 1] = g end
            for _, g in ipairs(inventoryOnly) do inv[#inv + 1] = g end
            local worn = {}
            for i, g in ipairs(wornItems) do worn[i] = { getItem = function() return g end } end
            return {
                getInventory = function() return { getItems = function() return list(inv) end } end,
                getWornItems = function() return list(worn) end,
                isFemale = function() return false end,
            }
        end
        local shirt  = garment("T-shirt", { "Torso_Upper", "Torso_Lower" }, 10, 20, 0, true)
        local jacket = garment("Leather jacket", { "Torso_Upper", "Torso_Lower", "UpperArm_L" }, 30, 40, 5, true)
        local vest   = garment("Vest", { "Torso_Upper" }, 80, 90, 60, true)
        -- (a stowed sprayer in the main hand: item:isEquipped() is true, it is no worn item)
        local held   = garment("Sprayer", { "Back" }, 20, 20, 0, true)

        local d = P.gatherData(player({ shirt, jacket }, { held }))
        local up = d.partStats.Torso_Upper
        check("two layers add up: bite", d.partDefense.Torso_Upper == 40, d.partDefense.Torso_Upper)
        check("two layers add up: scratch and bullet", up.scratch == 60 and up.bullet == 5, up.scratch .. "/" .. up.bullet)
        check("two layers counted", up.layers == 2, up.layers)
        check("one layer is its own defense", d.partDefense.UpperArm_L == 30, d.partDefense.UpperArm_L)
        check("an uncovered part stays -1", d.partDefense.Head == -1, d.partDefense.Head)
        check("a garment held in a hand is not worn: the part stays uncovered", d.partDefense.Back == -1
            and d.partStats.Back.layers == 0, d.partDefense.Back)
        check("a garment held in a hand is no garment", d.totalGarments == 2, d.totalGarments)
        local backOpen = false
        for _, u in ipairs(d.uncoveredParts) do if u == "BACK" then backOpen = true end end
        check("the back still reads uncovered", backOpen)

        local d2 = P.gatherData(player({ shirt, jacket, vest }, {}))
        check("three layers cap at 100 (bite)", d2.partDefense.Torso_Upper == 100, d2.partDefense.Torso_Upper)
        check("three layers cap at 100 (scratch)", d2.partStats.Torso_Upper.scratch == 100, d2.partStats.Torso_Upper.scratch)
        check("the best part is the capped one", d2.bestPart.biteDef == 100, d2.bestPart.biteDef)
        -- the average reads the summed parts: (100 + 40 + 30) / 18, floored
        check("the average reads the summed layers", d2.avgBiteDef == math.floor(170 / 18), d2.avgBiteDef)
    end
end

-- ---------------------------------------------------------------------------
section("HEALTH: the figure zone's measure counts Overall's word lines")
-- ---------------------------------------------------------------------------
do
    local src = readFile(DIR .. "HealthTab.lua") or ""
    local a = src:find("--- The word for a read of the body", 1, true)
    local b = src:find("-- opts (the medical check of another player", 1, true)
    local c = src:find("function ZeD.HealthTab._measureZoneA(", 1, true)
    local e = c and src:find("\nend\n", c, true)
    check("the Overall pieces are in the file", a and b and c and e)
    if a and b and c and e then
        ZeD.HealthTab = { _measureExerciseInfo = function() return 0 end }
        ZeD.Atoms = {
            wrapText = function(text, font, w)
                local out, line = {}, ""
                for word in tostring(text):gmatch("%S+") do
                    local try = (line == "") and word or (line .. " " .. word)
                    if #try * 7 > w and line ~= "" then out[#out + 1] = line; line = word else line = try end
                end
                if line ~= "" or #out == 0 then out[#out + 1] = line end
                return out
            end,
            pctText = function(f) return tostring(math.floor(f * 100)) .. "%" end,
            statusColor = function() return col() end,
            drawBody = noop,
        }
        -- the stat row and the bar as the library draws them: the row is its font's height and 4, the bar fillBarH
        ZeD.Molecules = {
            drawStatRowDot = function() return 19 + 4 end,
            drawFillBar = function() return ZeD.T.fillBarH end,
            layoutZoneA = function(x, y, w) return { rightW = w - 238 - 8 } end,
        }
        local chunk, err = loadstring(src:sub(a, b - 1) .. src:sub(c, e + 4), "=HealthTab.lua (cut)")
        check("the Overall pieces cut and load", chunk ~= nil, err)
        if chunk then
            chunk()
            local H = ZeD.HealthTab
            local T = ZeD.T
            -- a word that wraps to several lines in the column ("Highly Critical damage" in a long language)
            local data = { overall = 5, overallWord = "Highly critical damage to the whole body, see a doctor at once please" }
            local w = 480
            local rightW = ZeD.Molecules.layoutZoneA(0, 0, w - T.sp.scrollbarW).rightW
            local yEnd = H.drawOverall(nil, 0, 0, rightW, data)
            -- the right column as _renderHeader draws it: drawOverall, then the summary line
            local drawn = yEnd + 14 + T.sp.sm
            local lines = #H.overallLines(data, T.fontF2, rightW)
            check("the word takes more than one line here", lines > 1, lines)
            local measured = H._measureZoneA(data, w, {})
            check("the measure is the draw (the word's lines counted)", measured == drawn, measured .. " vs " .. drawn)
            -- wider (no scroll bar): the draw never runs past the measure
            local wide = ZeD.Molecules.layoutZoneA(0, 0, w).rightW
            local drawnWide = H.drawOverall(nil, 0, 0, wide, data) + 14 + T.sp.sm
            check("without the scroll bar the draw stays inside the measure", drawnWide <= measured, drawnWide .. " vs " .. measured)
            -- a short word: one line
            local short = { overall = 100, overallWord = "OK" }
            check("a one-line word is one line", H._measureZoneA(short, w, {}) == H.drawOverall(nil, 0, 0, rightW, short) + 14 + T.sp.sm)
        end
    end
end

-- ---------------------------------------------------------------------------
section("TRAITS: the icon, then the name")
-- ---------------------------------------------------------------------------
do
    local src = readFile(DIR .. "IdentityTab.lua") or ""
    local a = src:find("local _traitLay = {}", 1, true)
    local e = a and src:find("\nend\n", a, true)
    check("traitRowLayout is in the file", a and e)
    if a and e then
        ZeD.IdentityTab = ZeD.IdentityTab or {}
        local chunk, err = loadstring(src:sub(a, e + 4), "=IdentityTab.lua (cut)")
        check("traitRowLayout cuts and loads", chunk ~= nil, err)
        if chunk then
            chunk()
            local L = ZeD.IdentityTab.traitRowLayout(23)
            check("no square in the row's places", L.dot == nil and L.dotX == nil, tostring(L.dotX))
            check("the name follows the icon", L.nameX == L.icon + 8, L.nameX)
        end
    end
    local r = src:find("local function renderTraitRow(", 1, true)
    local re = r and src:find("\nend\n", r, true)
    local body = (r and re) and src:sub(r, re) or ""
    check("the trait row draws no colored square", body ~= "" and not body:find("drawRect(tx + lay.dotX", 1, true)
        and not body:find("color.r", 1, true))
end

-- ---------------------------------------------------------------------------
section("HEADS: the tab's title and one section style")
-- ---------------------------------------------------------------------------
do
    local files = { "HealthTab.lua", "ProtectionTab.lua", "EquipmentTab.lua", "ZeD_EquipLoadout.lua", "IdentityTab.lua",
                    "ThermalTab.lua", "ZeD_HairBeard.lua", "SkillsTab.lua" }
    local src = {}
    for _, f in ipairs(files) do
        src[f] = readFile(DIR .. f) or ""
        -- (comments out: only the code is checked)
        src[f] = src[f]:gsub("%-%-[^\n]*", "")
        check(f .. ": no band-strip section head", not src[f]:find("drawSectionHeader(", 1, true))
        local n = select(2, src[f]:gsub("drawTabHeader%(", ""))
        check(f .. ": at most one title (the tab's own)", n <= 1, n)
    end
    check("Loadouts: the fold is no second title under Equipped", not src["ZeD_EquipLoadout.lua"]:find("drawTabHeader(", 1, true))
    check("Loadouts: the fold's head is the 20u mono line",
        src["ZeD_EquipLoadout.lua"]:find("local function headH() return ZeD.T.px(20) end", 1, true) ~= nil)
    check("Loadouts: the to-do's sections are the mono line",
        select(2, src["ZeD_EquipLoadout.lua"]:gsub("drawCategoryRow%(", "")) >= 2)
    check("Equipped: no large-title section (fontF4 heading)", not src["EquipmentTab.lua"]:find("T.fontF4, nil, pad, headerH", 1, true))
    check("Equipped: a group's row is at least the fold head's 20u",
        src["EquipmentTab.lua"]:find("local GROUP_H    = 20", 1, true) ~= nil)
    check("Traits: the mono line", src["IdentityTab.lua"]:find('drawCategoryRow(panel, x + pad, curY, contentW, getText("IGUI_char_Traits")', 1, true) ~= nil)
    check("Thermal: the region head is the mono line", src["ThermalTab.lua"]:find('M.drawCategoryRow(panel, listX, drawY, listW,', 1, true) ~= nil)
    check("Hair and beard: the mono line", src["ZeD_HairBeard.lua"]:find("drawCategoryRow(panel, ix, y, it.w, it.text, nil, true, ho)", 1, true) ~= nil)
    check("Skills: the section heads are the mono line", select(2, src["SkillsTab.lua"]:gsub("sectionHeadOpts%(%)%)", "")) == 2)
end

print(string.format("g4_character_tabs_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
