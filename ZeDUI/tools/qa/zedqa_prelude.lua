-- ZeDUI/tools/qa/zedqa_prelude.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the first line of the unattended regression
-- (zedqa_run.ps1, regression.txt). Opens the window pair if it is shut (the
-- suites need both windows), unpauses, turns on god mode (the QA character
-- once starved at speed), waits about 60 ticks for the windows to settle and
-- prints "ZEDQA pre DONE". If OnTick never ran (the game is still paused) it
-- says so as an ERR line, so the run reads WARN instead of timing out.
-- grep "ZEDQA pre".
-- Nov 12 2026 (test cleanup, phase 2): it also puts every ZeD window at its default layout with the console
-- closed, and defines the shared helpers the scripts call: ZEDQA_HOME, ZEDQA_LAYOUT_* (the window rule) and
-- ZEDQA_CAR_* (one car spawn on the strip's marked stretch).
local function say(s) print("ZEDQA pre " .. tostring(s)) end

-- Nov 8 2026: the windows let their controller stops wait while the mouse is in use (Focus.stopsMayWait);
-- QA scripts read w._focusRing directly, so keep them fresh every frame. Set it to nil to test the waiting itself.
ZEDQA_FRESH_STOPS = true

-- (punch list 47, Nov 2 2026) the vehicle probe for the 1280x720 bisect: where the character stands, how wide
-- the loaded chunk grid is and what it covers, and whether a spawn square and its car lie inside it. The
-- vehicle scripts call it right after their spawn when it exists (a script run alone skips it). One line
-- each; grep "ZEDQA vp".
function ZEDQA_VPROBE(tag, sq, v)
    local ok, line = pcall(function()
        local pl, cell = getPlayer(), getCell()
        local cm = cell:getChunkMap(0)
        local wt = cm:getWidthInTiles()
        local px, py = pl:getX(), pl:getY()
        local out = string.format("ZEDQA vp %s player=%d,%d grid=%d chunks (%d tiles) loaded x %d-%d y %d-%d",
            tostring(tag), math.floor(px), math.floor(py), math.floor(wt / 8), wt,
            cm:getWorldXMinTiles(), cm:getWorldXMaxTiles(), cm:getWorldYMinTiles(), cm:getWorldYMaxTiles())
        if sq then
            local sx, sy = sq:getX(), sq:getY()
            out = out .. string.format(" sq=%d,%d dist=%.1f chunk=%s inMap=%s", sx, sy,
                math.sqrt((sx - px) ^ 2 + (sy - py) ^ 2), tostring(sq:getChunk() ~= nil), tostring(cell:isInChunkMap(sx, sy)))
        else
            out = out .. " sq=nil"
        end
        if v then
            out = out .. string.format(" car=%s at %.1f,%.1f dist=%.1f", tostring(v:getScriptName()), v:getX(), v:getY(),
                math.sqrt((v:getX() - px) ^ 2 + (v:getY() - py) ^ 2))
        else
            out = out .. " car=nil"
        end
        local vs = cell:getVehicles()
        return out .. " vehicles=" .. tostring(vs and vs:size())
    end)
    print(ok and line or ("ZEDQA vp " .. tostring(tag) .. " ERR " .. tostring(line)))
end
-- ============================================================================
-- (Nov 12 2026, test cleanup plan rule 5 and amendment 8: the window rule) The run starts from the default window
-- layout with the console closed, and a script that moves, folds, pins or resizes a window puts the layout back
-- when it ends, on an error too. The helpers, used by this prelude and by the scripts:
--   ZEDQA_LAYOUT_DEFAULT(tag)   the console, the guide, Messages and the studio closed; both windows at the default
--                               spread through the mod's own ZeD_Window.resetLayout (unrolled, unfolded, on Loot,
--                               drawers shut); both pinned (what zedqa_pin_windows.lua did); the bag as a list
--   local snap = ZEDQA_LAYOUT_SNAP()        each window's place, size, rolled state and pins
--   ZEDQA_LAYOUT_BACK(snap, tag)            puts that back; never throws; with no snap it is ZEDQA_LAYOUT_DEFAULT
--   ZEDQA_LAYOUT_IS_DEFAULT()               true when both windows stand where this prelude left them
-- A script run without the prelude finds them nil: call them as "if ZEDQA_LAYOUT_BACK then ... end".
-- ============================================================================
local QA_KEYS = { "char", "world" }
local function qaWin(k)
    if k == "char" then return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() or nil end
    return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() or nil
end
local function pinHalves(w, inv, drawer)
    if not w then return end
    if w._halves and ZeD.Halves and ZeD.Halves.setPin then
        ZeD.Halves.setPin(w, "inv", inv); ZeD.Halves.setPin(w, "drawer", drawer)
    elseif w.setPinned then w:setPinned(inv and drawer)
    else w.pinned = (inv and drawer) and true or false end
end

function ZEDQA_LAYOUT_SNAP()
    local snap = {}
    for _, k in ipairs(QA_KEYS) do
        local w = qaWin(k)
        if w then
            local h = w._halves
            local pi, pd = w.pinned == true, w.pinned == true
            if h then pi, pd = (h.inv and h.inv.pinned == true) or false, (h.drawer and h.drawer.pinned == true) or false end
            snap[k] = { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight(), rolled = w._rolled and true or false,
                        pinInv = pi, pinDrawer = pd }
        end
    end
    return snap
end

function ZEDQA_LAYOUT_DEFAULT(tag)
    local notes = {}
    pcall(function()
        if ZeD.DebugConsole and ZeD.DebugConsole.isOpen and ZeD.DebugConsole.isOpen() then ZeD.DebugConsole.close(); notes[#notes + 1] = "console closed" end
    end)
    pcall(function()
        local jc = UIManager.getDebugConsole()
        if jc and jc:isVisible() then jc:setVisible(false); notes[#notes + 1] = "game console closed" end
    end)
    pcall(function() if ZeD.GuideBook and ZeD.GuideBook.isOpen and ZeD.GuideBook.isOpen(0) then ZeD.GuideBook.close(0); notes[#notes + 1] = "guide book closed" end end)
    pcall(function() if ZeD.Studio and ZeD.Studio.isOpen and ZeD.Studio.isOpen() then ZeD.Studio.close(); notes[#notes + 1] = "studio closed" end end)
    for _, name in ipairs({ "Guide", "MessagesWindow" }) do
        pcall(function()
            local t = ZeD[name]
            local win = t and t.windows and t.windows[0]
            if win and win:isVisible() then win:close(); notes[#notes + 1] = name .. " closed" end
        end)
    end
    local ok, e = pcall(function()
        if not (ZeD_Window and ZeD_Window.resetLayout) then error("ZeD_Window.resetLayout is missing") end
        ZeD_Window.resetLayout()
    end)
    if not ok then print("ZEDQA layout " .. tostring(tag) .. " ERR reset: " .. tostring(e)) end
    pcall(function()
        local md = getPlayer():getModData()
        md.ZeD_WinPinned = md.ZeD_WinPinned or {}
        md.ZeD_WinPinned.char, md.ZeD_WinPinned.world = true, true
    end)
    for _, k in ipairs(QA_KEYS) do
        local w = qaWin(k)
        if w then pcall(function() pinHalves(w, true, true); if w.windowShaded then w:setWindowShaded(false) end end) end
    end
    pcall(function()
        local IR = ZeD.InventoryRenderer
        local pl = getPlayer()
        local key = IR and IR.containerKey and pl and IR.containerKey(pl:getInventory(), pl)
        if key and IR.isGridKey(key) then IR.setGridKey(key, false); notes[#notes + 1] = "bag back to a list" end
    end)
    if tag then print("ZEDQA layout " .. tostring(tag) .. " default" .. (#notes > 0 and (" (" .. table.concat(notes, ", ") .. ")") or "")) end
    return ok
end

function ZEDQA_LAYOUT_BACK(snap, tag)
    local ok, e = pcall(function()
        -- first the mod's own reset (unrolls, unfolds, Loot, drawers shut), then whatever the snapshot had that differs
        ZEDQA_LAYOUT_DEFAULT(nil)
        if type(snap) ~= "table" then return end
        for _, k in ipairs(QA_KEYS) do
            local w, s = qaWin(k), snap[k]
            if w and s then
                if not s.rolled then
                    if w:getWidth() ~= s.w then w:setWidth(s.w) end
                    if w:getHeight() ~= s.h then w:setHeight(s.h) end
                end
                if w:getX() ~= s.x then w:setX(s.x) end
                if w:getY() ~= s.y then w:setY(s.y) end
                pinHalves(w, s.pinInv, s.pinDrawer)
                if s.rolled and ZeD.Curtain and ZeD.Curtain.roll then ZeD.Curtain.roll(w) end
            end
        end
    end)
    if tag then print("ZEDQA layout " .. tostring(tag) .. (ok and " put back" or (" ERR put back: " .. tostring(e)))) end
    return ok
end

function ZEDQA_LAYOUT_IS_DEFAULT()
    local d = ZEDQA_LAYOUT_DEF
    if type(d) ~= "table" then return false end
    for _, k in ipairs(QA_KEYS) do
        local w, s = qaWin(k), d[k]
        if not (w and s) then return false end
        if w._rolled or w:getX() ~= s.x or w:getY() ~= s.y or w:getWidth() ~= s.w or w:getHeight() ~= s.h then return false end
    end
    return true
end

local p = getPlayer()
-- (Oct 27 2026, the director: the QA character stood in thick woods, with no open ground to
-- spawn things and the view often blocked, and runs drifted into night) every run starts on
-- Irvington Speedway's drag strip, open asphalt, in daylight. The save keeps the move.
local HOME = { x = 925.5, y = 13040.5, z = 0 }
local moved = false

-- (punch list 47, Nov 2 2026) the drag strip for every script that needs open ground. Scripts 57, 61 and 63
-- (cb, bg, ws) leave the character in the grandstand at about 964,13079; a car spawned beside it then stands
-- indoors and its physics never wakes (QA's moved-sl run at 720), and at 720 the grandstand's
-- west end (892) is outside the loaded grid, so rst's fixture is not found. The vehicle scripts and rst call
-- this first; it moves the character (out of any car) to the strip when it is elsewhere and says so.
-- Returns true when it moved. A script run without the prelude skips it.
function ZEDQA_HOME(tag)
    local pl = getPlayer()
    if not pl then return false end
    local car = pl:getVehicle()
    if car then car:exit(pl); triggerEvent("OnExitVehicle", pl) end
    if math.abs(pl:getX() - HOME.x) <= 3 and math.abs(pl:getY() - HOME.y) <= 3 and math.floor(pl:getZ()) == HOME.z then return false end
    print("ZEDQA home " .. tostring(tag) .. " moved from " .. math.floor(pl:getX()) .. "," .. math.floor(pl:getY()) .. "," .. math.floor(pl:getZ()) .. " to the drag strip")
    pl:setX(HOME.x); pl:setY(HOME.y); pl:setZ(HOME.z); pl:setLastX(HOME.x); pl:setLastY(HOME.y); pl:setLastZ(HOME.z)
    return true
end
local ok, e = pcall(function()
    if getGameSpeed and getGameSpeed() == 0 and setGameSpeed then setGameSpeed(1) end
    if p then p:setGodMod(true) end
    if p and p:getVehicle() then p:getVehicle():exit(p) end
    if p and (math.abs(p:getX() - HOME.x) > 3 or math.abs(p:getY() - HOME.y) > 3 or math.floor(p:getZ()) ~= HOME.z) then
        say(string.format("moved from %d,%d,%d to the drag strip", math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())))
        p:setX(HOME.x); p:setY(HOME.y); p:setZ(HOME.z); p:setLastX(HOME.x); p:setLastY(HOME.y); p:setLastZ(HOME.z)
        moved = true
    end
    local gt = getGameTime()
    local hour = gt:getTimeOfDay()
    if hour < 8 or hour > 17 then gt:setTimeOfDay(11.0); say(string.format("clock %.2f -> 11.00 (daylight)", hour)) end
    -- (Nov 12 2026) ZeD's Lua console follows the game's console flag, and a saved position left it open at the bottom
    -- left of every capture: close it. The console scripts (zedqa_console_*.lua, zedqa_b8_console.lua) set the flag themselves.
    local okC = pcall(function()
        local jc = UIManager.getDebugConsole()
        if jc and jc:isVisible() then jc:setVisible(false); say("the Lua console was open: closed") end
    end)
    if not okC then say("no debug console to close") end
    -- (and a speed left above 1 by an earlier script)
    if getGameSpeed and getGameSpeed() > 1 and setGameSpeed then setGameSpeed(1); say("speed was above 1: set to 1") end
    local cw = ZeD_CharacterWindow.getWindow()
    if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
if not ok then say("ERR setup " .. tostring(e)) end
-- counted on OnRenderTick (it runs even while paused); OnTick is counted
-- beside it to tell a paused game from a running one
local frames, ticks = 0, 0
local function onTick() ticks = ticks + 1 end
local function onFrame()
    frames = frames + 1
    if frames < (moved and 300 or 60) then return end   -- (after the move: the strip's cells load)
    if ticks < 60 and frames < 600 then return end
    Events.OnRenderTick.Remove(onFrame)
    Events.OnTick.Remove(onTick)
    local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    say("char " .. tostring(cw and cw:isVisible()) .. " world " .. tostring(ww and ww:isVisible())
        .. " speed " .. tostring(getGameSpeed and getGameSpeed()) .. " ticks " .. ticks .. " frames " .. frames)
    if ticks == 0 then say("ERR OnTick never ran: the game is paused") end
    -- (Oct 25 2026) search mode off: its overlay blurs everything outside a ring round the
    -- character, and the gallery's reshoot came out soft with it on
    local sm = p and ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(p)
    if sm and sm.isSearchMode then pcall(function() sm:toggleSearchMode(false) end); say("search mode was on: turned off") end
    local okE, eng = pcall(getSearchMode)
    if okE and eng and p then
        local pn = p:getPlayerNum()
        local en, ov = eng:isEnabled(pn), eng:isOverride(pn)
        say(string.format("search overlay: enabled %s, override %s, manager %s", tostring(en), tostring(ov), tostring(sm and sm.isSearchMode)))
        if en or ov then pcall(function() eng:setOverride(pn, false); eng:setEnabled(pn, false) end); say("search overlay turned off") end
    end
    -- (Nov 12 2026, the window rule) the pair is open by now: every window to its default layout, pinned, on Loot,
    -- the console closed (zedqa_pin_windows.lua and zedqa_loot_tabs.lua are this step now). The layout this leaves
    -- is kept as ZEDQA_LAYOUT_DEF for ZEDQA_LAYOUT_IS_DEFAULT.
    if not ZEDQA_LAYOUT_DEFAULT("pre") then say("ERR the windows could not be put at their default layout") end
    ZEDQA_LAYOUT_DEF = ZEDQA_LAYOUT_SNAP()
    for _, k in ipairs(QA_KEYS) do
        local s = ZEDQA_LAYOUT_DEF[k]
        if s then say(string.format("layout %s %d,%d %dx%d rolled %s pinned %s/%s", k, s.x, s.y, s.w, s.h, tostring(s.rolled), tostring(s.pinInv), tostring(s.pinDrawer)))
        else say("ERR layout: no " .. k .. " window to place") end
    end
    -- which copy of ZeD the game loaded (zedqa_staged_ver.lua's line): no ZeD_UI mod info is an ERR
    local okV, mi = pcall(function() return getModInfoByID("ZeD_UI") end)
    if okV and mi then say("ZeD version=" .. tostring(mi:getModVersion()) .. " dir=" .. tostring(mi:getDir()))
    else say("ERR no mod info for ZeD_UI: which copy is loaded is not known") end
    cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    say("tabs: Character " .. tostring(cw and cw._activeTab) .. " | World " .. tostring(ww and ww._activeTab))
    say("DONE")
end
Events.OnTick.Add(onTick)
Events.OnRenderTick.Add(onFrame)
say("start")
