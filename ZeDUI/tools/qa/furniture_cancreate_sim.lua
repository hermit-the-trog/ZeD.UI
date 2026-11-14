-- ZeDUI/tools/qa/furniture_cancreate_sim.lua  (Nov 13 2026; the Furniture tab's "can be taken apart" with the tools)
-- The game's furniture cursor keeps its yes or no in canCreate, and the game treats any value but nil and false as
-- yes. Disassemble on wood (hammer and saw) leaves the saw item there, not true: vanilla's canScrapObject ends
-- "canScrap and result.haveTool and result.haveTool2", and hasScrapTool hands back the tool it found. ZeD's
-- REAL FT.capture (cut out of FurnitureTab.lua) must read that as yes, as the game's own click does.
--   YES    true, a tool item (a table here) and a number read as yes
--   NO     false and nil read as no
-- What it can't show: the game's own cursor (zedqa_cov_equipfurn.lua, "with the tools in your inventory").
-- Run from the repo root:  lua51 ZeDUI/tools/qa/furniture_cancreate_sim.lua
-- It prints FAIL lines and a last line "furniture_cancreate_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]furniture_cancreate_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local f = io.open(ROOT .. "42/media/lua/client/ZeD/FurnitureTab.lua", "rb")
local src = f and f:read("*a") or ""
if f then f:close() end
local a = string.find(src, "function FT.capture(", 1, true)
local b = a and string.find(src, "\n-- ok / bad / plain", a, true)
check("FT.capture found in FurnitureTab.lua", a ~= nil and b ~= nil)

local FT = { cap = {} }
ISMoveableCursor = { mode = { [0] = "scrap" } }
local chunk, err = nil, "not found"
if a and b then chunk, err = loadstring("local FT = ...\n" .. string.sub(src, a, b), "=FurnitureTab.lua (cut)") end
check("FT.capture compiles", chunk ~= nil, err)
if chunk then chunk(FT) end

local function read(v)
    if not FT.capture then return "no capture" end
    FT.cap[0] = nil
    FT.capture({ player = 0, canCreate = v }, "sq", "obj", nil, nil, nil)
    return FT.cap[0] and FT.cap[0].canCreate
end

local saw = { getType = function() return "Saw" end }
check("YES: true reads as yes", read(true) == true, tostring(read(true)))
check("YES: the second tool item (hammer and saw on wood) reads as yes", read(saw) == true, tostring(read(saw)))
check("YES: a number reads as yes", read(1) == true, tostring(read(1)))
check("NO: false reads as no", read(false) == false, tostring(read(false)))
check("NO: nil reads as no", read(nil) == false, tostring(read(nil)))

print("furniture_cancreate_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
