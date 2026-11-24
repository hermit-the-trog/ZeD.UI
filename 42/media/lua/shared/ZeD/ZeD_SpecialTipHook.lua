-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_SpecialTipHook.lua
-- ============================================================================
-- THE GAME'S TROUGH AND FARM PLOT HOVER BOXES, KEPT ASIDE (Nov 23 2026, the
-- director: "Redraw."). Shared, so it loads before the game's client files.
--
-- Pointing at a feeding trough or a planted farm plot, the game fires
-- Events.DoSpecialTooltip(tooltip, square) and two handlers of its own draw a
-- plain box there: CFeedingTroughSystem.lua's and CFarmingSystem.lua's. Both
-- are local functions, so they can't be removed by name later. Instead this
-- file wraps Events.DoSpecialTooltip.Add (a plain Lua table in Kahlua: the
-- game's Event.register makes it with rawset) before those files load, and
-- keeps those two handlers as they are added, without adding them:
--   ZeD.SpecialTip.gameTrough   the trough file's handler
--   ZeD.SpecialTip.gameFarm     the farm file's handler
-- Every other Add (any mod's, before or after) goes through unchanged, so a
-- mod's own lines still draw. ZeD_SpecialTip.lua (client) draws the same
-- facts in ZeD's balloon, and calls the kept handler when ZeD steps aside
-- (safe mode), so the game's box comes back.
--
-- How an Add is known as the game's: the file's class exists (the trough file's
-- Add is its last line, after CFeedingTroughSystem is made, and the file adds
-- nothing else; the same for CFarmingSystem), the handler is not taken yet, and
-- the function comes from that file (getFilenameOfClosure, when the game has it).
-- ============================================================================

ZeD = ZeD or {}
ZeD.SpecialTip = ZeD.SpecialTip or {}
local ST = ZeD.SpecialTip
ST.captured = ST.captured or 0

-- the game files whose handlers are kept (the end of their path)
ST.TROUGH_FILE = "FeedingTrough/CFeedingTroughSystem.lua"
ST.FARM_FILE = "Farming/CFarmingSystem.lua"

-- true when fn was written in the file whose path ends in tail; true too when the file can't be read
-- (then the order alone decides, see above)
function ST.fromFile(fn, tail)
    if not getFilenameOfClosure then return true end
    local ok, f = pcall(getFilenameOfClosure, fn)
    if not ok or type(f) ~= "string" then return true end
    f = string.gsub(f, "\\", "/")   -- (Windows paths: the separators as the tail has them)
    return string.find(f, tail, 1, true) ~= nil
end

-- the Add that stands in for the game's: keeps the two game handlers, passes everything else on
function ST.hookAdd()
    local ev = Events and Events.DoSpecialTooltip
    if not ev or not ev.Add then return false end
    if ev.Add == ST._addWrapper then return true end   -- (wrapped already: a reload of this file)
    local orig = ev.Add
    ST._origAdd = orig
    local function add(fn)
        if fn ~= nil and ST.gameTrough == nil and CFeedingTroughSystem ~= nil and ST.fromFile(fn, ST.TROUGH_FILE) then
            ST.gameTrough = fn
            ST.captured = ST.captured + 1
            return
        end
        if fn ~= nil and ST.gameFarm == nil and CFarmingSystem ~= nil and ST.fromFile(fn, ST.FARM_FILE) then
            ST.gameFarm = fn
            ST.captured = ST.captured + 1
            return
        end
        return orig(fn)
    end
    ST._addWrapper = add
    ev.Add = add
    return true
end

ST.hookAdd()
