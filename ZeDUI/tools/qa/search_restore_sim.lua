-- ZeDUI/tools/qa/search_restore_sim.lua  (Nov 24 2026, Build; QA's finding, the director: "Both (1 and 2)")
-- The game's search window (Investigate This Area) registers with the game's layout manager, and a layout.ini line
-- saved as visible=true put it back on screen at every load, past ZeD's route to the World window's Foraging tab.
-- The restore hook in Overrides/Wheels.lua (cut from the real file) runs here against a stand-in of the game's restore
-- (ISLayoutManager.DefaultRestoreWindow's visible rule, through ISLayoutManager.CallRestoreLayout's lookup):
--   RESTORE  a saved visible=true: the place and size are the game's, the window stays hidden; visible=false hidden;
--            Safe mode ("wheels"): the game's own restore, shown as saved; the hook goes in once
--   WIRED    the hook sits in hookRoutes beside the toggleWindow route
-- Run from the repo root:  lua51 ZeDUI/tools/qa/search_restore_sim.lua
-- It prints FAIL lines and a last line "search_restore_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]search_restore_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1) .. "\n"
end

local W = readFile(Z .. "Overrides/Wheels.lua") or ""
check("SOURCE: Overrides/Wheels.lua read", #W > 0)

-- the game's classes, as far as the restore goes
local safe = false
ZeD = { Safe = { on = function(k) return k == "wheels" and safe end } }
local ISCollapsableWindow = {}
function ISCollapsableWindow:RestoreLayout(name, layout)
    -- ISLayoutManager.DefaultRestoreWindow: the place and size, then visible as saved
    self.x, self.y = tonumber(layout.x), tonumber(layout.y)
    if layout.visible == "true" then self.added = true; self:setVisible(true)
    elseif layout.visible == "false" then self:setVisible(false) end
end
ISSearchWindow = setmetatable({ toggleWindow = function() end }, { __index = ISCollapsableWindow })
ISSearchWindow.__index = ISSearchWindow
local function newWindow()
    local o = setmetatable({ visible = false }, ISSearchWindow)
    function o:setVisible(v) self.visible = v end
    return o
end
-- ISLayoutManager.CallRestoreLayout: w.funcs.RestoreLayout(w.target, name, layout), funcs = the class
local function restore(win, layout) ISSearchWindow.RestoreLayout(win, "ISSearchWindow", layout) end

print("-- RESTORE: the saved layout on load")
local block = cut(W, "    if ISSearchWindow and not ISSearchWindow._zedRestore then", "\n    end\n")
check("RESTORE: the restore hook found in Overrides/Wheels.lua", block ~= nil)
if block then
    local fn, e = loadstring(block, "searchRestore")
    check("RESTORE: the hook loads", fn ~= nil, e)
    if fn then
        fn()
        local hooked = rawget(ISSearchWindow, "RestoreLayout")
        check("RESTORE: the hook is on the search window's class", type(hooked) == "function")
        fn()
        check("RESTORE: the hook goes in once (a second run changes nothing)", rawget(ISSearchWindow, "RestoreLayout") == hooked)

        local w = newWindow()
        restore(w, { x = "120", y = "340", visible = "true" })
        check("RESTORE: saved visible=true: hidden", w.visible == false, w.visible)
        check("RESTORE: saved visible=true: the game's place kept", w.x == 120 and w.y == 340, tostring(w.x) .. "," .. tostring(w.y))

        w = newWindow()
        restore(w, { x = "1", y = "2", visible = "false" })
        check("RESTORE: saved visible=false: hidden", w.visible == false)

        w = newWindow()
        restore(w, { x = "1", y = "2" })
        check("RESTORE: no visible in the line: hidden", w.visible == false)

        safe = true
        w = newWindow()
        restore(w, { x = "5", y = "6", visible = "true" })
        check("RESTORE: Safe mode: the game's own restore shows it as saved", w.visible == true)
        safe = false
    end
end

print("-- WIRED")
local routes = cut(W, "local function hookRoutes()", "\nend\n") or ""
check("WIRED: the restore hook is in hookRoutes", routes:find("ISSearchWindow._zedRestore", 1, true) ~= nil)
check("WIRED: the toggleWindow route is still there", routes:find("ISSearchWindow.toggleWindow = function", 1, true) ~= nil)

print("search_restore_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
