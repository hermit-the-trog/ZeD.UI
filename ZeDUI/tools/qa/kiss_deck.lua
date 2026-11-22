-- ZeDUI/tools/qa/kiss_deck.lua  (Nov 22 2026, QA; tag kssd): the KISS audit's pictures on the Steam Deck's own screen
-- size. The KISS audit (Keep It Super Simple) ranked the places where ZeD-GUI costs a time-poor new player extra
-- steps; the director makes each design call from a report page, each with one honest picture of the friction as a
-- player meets it today. kiss_pics_run.ps1 -Part deck runs this in a 1280x800 window, mouse and keyboard, from the
-- manifest kiss_pics_deck.txt (the 1.0 gallery's staging: the story stage, gallery_unload.lua, G1, hfr_common.lua).
-- Pictures to Zomboid/Screenshots/kiss_<name>.png; the runner moves them to Screenshots/kiss_report/<name>.png:
--   12_deck_text_small   theme 12, text starts small and is smallest on a Deck: the whole 1280x800 screen at 1x with
--                        ZeD's Text size and UI scale at their defaults (Small and Auto; Auto draws at 0.75 here), a
--                        wooden crate of a dozen mixed things beside him, both windows open on Loot (the World list
--                        on the crate, the Character list full of rows), so the body text and the button words show
--                        at their true size. Its line names both settings and the scale measured in game
--   07_deck_strip        theme 7 on the Deck: the same size and defaults, ZeD's right-click strip (Context menu on
--                        Strip, its default; no pinned actions, also the default) open on a can of beans in his
--                        inventory, the first action lit and the one balloon naming it, so the small cells show at
--                        the Deck's true size. The right-click is the list's own (as a mouse player's): the can's
--                        row is selected and its item card opens in the Character window's drawer as well
-- How it stages: he stands on the open patch by the story's smoking spot (bxr_menus.lua's S.findPatch: bare squares
-- round him and open ground two deep toward the camera; first with no fence, wall or tree crown in front of him either),
-- facing the camera at zoom 1. A wooden crate (carpentry_01_16, as bxr_craft.lua's S.setCrate sets it) goes on the bare
-- square west of him (else north, else north west: never between him and the camera) with twelve things of twelve kinds
-- in it; light things of their own kinds are given to him (the can of beans first) while his load stays a kilo under
-- his limit, so his list runs past its view. Both windows at their default spread (the mod's own reset), on Loot, the
-- World list on the crate. At 1280x800 the spread stands over his head: a window that covers him goes to the screen's
-- edge (G1.clear), and the line says so. ZeD's input mode is locked to keyboard and mouse. The pointer the game's Lua
-- reads is parked off every window and menu (getMouseX / getMouseY swapped: Mouse.setXY does not move it), so no row,
-- cell or balloon is lit by wherever the real pointer rests; the real pointer is hidden (pzlaunchwin.ps1 parks it in
-- the window's bottom-right corner; a window under it would count as in use, and each line says how both windows are
-- drawn). For 07 the Character window stands a half card (the drawer's
-- item card, 220 units) in from the screen's left edge, still clear of him, so the card opens to its left without
-- pinning the window at the edge (pinned there, the window would widen to the right and slide the list out from under
-- the strip). The right-click is the Character list's own handler (content.onRightMouseDown / onRightMouseUp,
-- ZeD_CharacterWindow.lua:7419-7450, as the release test's rt_menus.lua drives it) at the can's row, the pointer the
-- game reads on the row: the row becomes the selection, its item card opens in the drawer and the game's inventory
-- menu is made at the pointer, which ZeD shows as its strip. The click lands where the strip lies level on the row
-- above (or, where the strip flips under the click near the screen's top, on the row below), so the selected row
-- itself stays in sight. The Character window is held "in use" meanwhile, as a player's pointer on the row holds it.
-- Every picture waits for the windows to keep still and for 3.6 s with no new Lua error (the debug build's red ERROR
-- box). Each picture prints "ZEDQA kssd SHOT <name> | what is in it" or "ZEDQA kssd SKIP <name> | why"; a screen
-- that is not the Deck's 1280x800 skips both.
-- What it puts back: the things given, the crate and what is in it, the Text size, UI scale and Context menu settings
-- (set in memory; the script never saves them, but ZeD's layout reset saves the options, so the put-back sets them
-- back first and its own layout reset then saves the found values; the runner also writes ModOptions.ini back), his
-- pinned actions (the same table), the input mode lock, the Character window's own pointer test, the row selection
-- and the item card, the opened stack and the list's scroll, the pointer the game reads, the bag's own list or grid
-- choice as stored, both windows' places, sizes and pins (ZEDQA_LAYOUT_BACK), the tabs (Loot), the zoom, game speed,
-- the glasses, the pair as found, the error watch; he ends at the story's stock spot, standing, alive and whole, out
-- of any car. grep "ZEDQA kssd".
local S = HFR and HFR.init and HFR.init("kssd")
if not S then return end
S.DIR = "kiss_"
local Q = S.Q
Q.maxMs = 600000   -- (the put-back starts after 10 min, well inside the manifest's 900 s)
S.Det = ZeD.Input and ZeD.Input.Detector
S.pic, S.stackWas, S.crateIts, S.given, S.st = {}, {}, {}, {}, {}
S.was.look = {}
S.DECK_W, S.DECK_H = 1280, 800
-- given to him: light things of their own kinds, each a row of its own (the can of beans first: the strip's)
S.INV = { "Base.TinnedBeans", "Base.Pencil", "Base.Notebook", "Base.Battery", "Base.Bandage", "Base.Candle", "Base.Spoon",
          "Base.Scissors", "Base.Twine", "Base.Crisps", "Base.Chocolate", "Base.Gum", "Base.Peanuts", "Base.Tissue", "Base.Comb",
          "Base.Toothbrush", "Base.Razor", "Base.Paperclip" }
-- the crate's dozen mixed things, twelve kinds
S.CRATE = { "Base.TinnedSoup", "Base.CannedCorn", "Base.CannedTomato", "Base.Pop", "Base.WaterBottle", "Base.Matches",
            "Base.DuctTape", "Base.Screwdriver", "Base.Socks_Ankle", "Base.Apple", "Base.Cereal", "Base.Rope" }
-- the crate's square from his: west, north, north west (the camera looks from the south east: behind him)
S.CRATE_AT = { { -1, 0, "west" }, { 0, -1, "north" }, { -1, -1, "north west" } }
S.CRATE_SPRITE = "carpentry_01_16"
-- the settings the pictures are about, at ZeD's own defaults (in memory only):
--   Text size     item 1, "small"  (Settings.lua:161-165, "default: small")
--   UI scale      item 1, "auto"   (Settings.lua:179-183, "default: Auto"; shared/ZeD/Scale.lua:130-135 and 182-196:
--                                   800 / 1080 clamped to 0.75, times the game's Font Size multiplier, 1.0 at the run's
--                                   pinned 19 px)
--   Context menu  item 1, the strip (Settings.lua:268-272, "default: the strip")
S.LOOK_DEF = { textSize = 1, uiScale = 1, contextStyle = 1 }
S.LOOK_NAME = { textSize = "Text size", uiScale = "UI scale", contextStyle = "Context menu" }

if not (S.Det and S.Det.setLockedMode and ZeD.Settings and ZeD.Settings.contextStyleOption and ZeD.Settings.uiScaleOption
        and ZeD.Settings.applyScale and ZeD.Settings.applyThemeNow and ZeD.Scale and ZeD.Scale.root and ZeD.T and ZeD.T.ctx
        and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu) then
    Q.say("ERR ZeD's settings, scale, input mode or context menu are not loaded")
    Q.start()
    return
end
-- (QA review, Nov 22: G1.make's queue, gallery_v1_a_common.lua:70-75, jumps to the put-back once the run is past
-- Q.maxMs, and again on every frame after it while the put-back's steps lie ahead, so the put-back never ran and the
-- manifest's timeout would stop the whole run before the story's teardown. Here the first jump lifts the limit, and
-- so does reaching the put-back on its own, so the put-back runs through once.)
S.tick0 = Q.tick
function Q.tick()
    if Q.backAt and Q.qi >= Q.backAt then
        Q.maxMs = 1e15
    elseif Q.backAt and getTimestampMs() - Q.t0 > Q.maxMs then
        Q.maxMs = 1e15
        Q.say("ERR ran too long at step " .. Q.qi .. ": jumping to the put-back")
        Q.qi = Q.backAt
        Q.wait = nil
        return
    end
    return S.tick0()
end

-- ===================================================================== helpers
function S.skip(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. tostring(why)) end
function S.fl(v) return math.floor(tonumber(v) or 0) end
function S.scr() return S.core:getScreenWidth(), S.core:getScreenHeight() end
function S.zoom()
    local z = 1
    pcall(function() z = S.core:getZoom(S.pn) end)
    if not z or z <= 0 then z = 1 end
    return z
end
function S.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
function S.count(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
function S.nm(it)
    if it == nil then return "nothing" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or it)
end
-- time, not frames (bxr_menus.lua): cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the camera has stopped after a move (bxr_menus.lua): his place on screen the same for 20 drawn frames (at most 900)
function S.settle(on)
    local st = { same = 0 }
    Q.waitFor(5, 900, function()
        if on and not on() then return true end
        if S.p:getCurrentSquare() == nil then return false end
        local v = math.floor(isoToScreenX(S.pn, S.p:getX(), S.p:getY(), 0)) .. "," .. math.floor(isoToScreenY(S.pn, S.p:getX(), S.p:getY(), 0))
        if v == st.last then st.same = st.same + 1 else st.last, st.same = v, 0 end
        return st.same >= 20
    end, function() end)
end
-- the camera's zoom to get() (nil: left as it is), a quarter step a frame (bxr_menus.lua), then the time it takes
function S.zoomDyn(get)
    local st = {}
    Q.waitFor(2, 1200, function()
        if st.left == nil then
            local z = get()
            st.left = z and math.floor((S.core:getZoom(S.pn) - z) / 0.25 + 0.5) or 0
            st.moved = st.left ~= 0
        end
        if st.left == 0 then return true end
        S.core:doZoomScroll(S.pn, (st.left > 0) and -1 or 1)
        st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
        return st.left == 0
    end, function() end)
    Q.waitFor(1, 200, function()
        if not st.moved then return true end
        st.n = (st.n or 0) + 1
        return st.n >= 100
    end, function() if st.moved then Q.say("zoom " .. tostring(S.core:getZoom(S.pn))) end end)
end

-- ----- the debug build's red "ERROR n" box (bxr_inv.lua): the game's ExceptionLogger draws it for 3 s after each
-- logged error, no UI element, so G1.hideErrors cannot hide it; a picture waits for 3.6 s with no new error
S.errN, S.errAt = nil, -100000
function S.errWatch()
    local n = getLuaDebuggerErrorCount and getLuaDebuggerErrorCount() or nil
    if n ~= nil and n ~= S.errN then
        if S.errN ~= nil then S.errAt = getTimestampMs() end
        S.errN = n
    end
end
function S.quiet() S.errWatch(); return getTimestampMs() - S.errAt > 3600 end
Events.OnPreUIDraw.Add(S.errWatch)
-- the kit's still (the windows the same for 30 frames, at most 900), with no new error for 3.6 s as well
function Q.still(n, fn)
    local st = { last = nil, same = 0 }
    Q.waitFor(n, 900, function()
        local s = G1.shape()
        if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
        return st.same >= 30 and S.quiet()
    end, fn)
end
-- no unread error on screen (bxr_inv.lua): the list read (ZeD_Messages.lua:635 readErrors), every message marked read
-- (:412 markAllRead, what opening Messages does for a player), the red error balloons dismissed (:276 dropToast);
-- nothing is taken out of Messages
function S.notesRead()
    local M = ZeD.Messages
    if not (M and M.unread and M.markAllRead) then return end
    if M.readErrors then pcall(M.readErrors) end
    local un, err = M.unread()
    if (un or 0) > 0 then M.markAllRead() end
    local gone = 0
    if M.toasts and M.dropToast then
        for i = #M.toasts, 1, -1 do
            local t = M.toasts[i]
            if t and t.kind == "crit" then M.dropToast(t); gone = gone + 1 end
        end
    end
    if (un or 0) > 0 or gone > 0 then
        Q.say("note: before the picture " .. tostring(un) .. " unread message(s) marked read (an error among them " .. tostring(err)
            .. "), " .. gone .. " error balloon(s) dismissed")
    end
end
function S.take(name, what, keepMenu)
    -- (Build is changing ZeD_Messages.lua this session: a Messages call that fails must not cost the picture)
    local okN, eN = pcall(S.notesRead)
    if not okN then Q.say("note: Messages could not be read before " .. name .. ": " .. tostring(eN)) end
    if not S.quiet() then
        Q.say("NOTE " .. name .. ": a Lua error came " .. tostring(getTimestampMs() - S.errAt) .. " ms before the picture: the game's red ERROR box may be in it")
    end
    S.shot(name, keepMenu)
    S.pic[#S.pic + 1] = name
    Q.say("SHOT " .. name .. " | " .. tostring(what))
end

-- ----- the squares (bxr_menus.lua)
-- a bare square in the open
function S.goodSq(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:isOutside()
            and sq:getRoom() == nil and sq:getObjects():size() <= 3 and sq:getWorldObjects():size() == 0
            and sq:getVehicleContainer() == nil and sq:getMovingObjects():size() == 0
    end)
    return good and sq or nil
end
-- the squares up to three deep on the camera side of (x, y): open sky (no roof, canopy or room), no tree, no car
S.AHEAD = { { 2, 0 }, { 0, 2 }, { 2, 1 }, { 1, 2 }, { 2, 2 }, { 3, 1 }, { 1, 3 }, { 3, 2 }, { 2, 3 }, { 3, 3 } }
function S.clearAhead(x, y)
    for _, o in ipairs(S.AHEAD) do
        local sq = S.sqAt(x + o[1], y + o[2])
        local ok = false
        if sq then
            pcall(function() ok = sq:isOutside() and sq:getRoom() == nil and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if not ok then return false end
    end
    return true
end
-- no fence, wall or solid thing on the square, its own north and west edges included (B42: sq:has(IsoFlagType.X))
function S.noEdge(sq)
    if not sq then return true end
    local ok, bad = pcall(function()
        return sq:has(IsoFlagType.collideW) or sq:has(IsoFlagType.collideN) or sq:has(IsoFlagType.HoppableW) or sq:has(IsoFlagType.HoppableN)
            or sq:has(IsoFlagType.WallW) or sq:has(IsoFlagType.WallN) or sq:has(IsoFlagType.WallNW) or sq:has(IsoFlagType.TallHoppableW)
            or sq:has(IsoFlagType.TallHoppableN) or sq:has(IsoFlagType.solid) or sq:has(IsoFlagType.solidtrans)
    end)
    if not ok then return true end
    return not bad
end
-- no tree whose crown reaches over a character on (x, y): ten squares out along the diagonal toward the camera, four
-- to either side of it (no remainder sign used: Kahlua's % keeps a minus)
function S.noTreesAhead(x, y)
    for dy = 0, 10 do
        for dx = 0, 10 do
            if dx + dy >= 1 and math.abs(dx - dy) <= 4 then
                local sq = S.sqAt(x + dx, y + dy)
                local t = false
                if sq then pcall(function() t = sq:HasTree() end) end
                if t then return false end
            end
        end
    end
    return true
end
-- nothing drawn over him on (x, y): clearAhead, no fence or wall on the squares in front of him, no tree crown
function S.clearFront(x, y)
    if not S.clearAhead(x, y) then return false end
    for _, o in ipairs({ { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
        if not S.noEdge(S.sqAt(x + o[1], y + o[2])) then return false end
    end
    for _, o in ipairs(S.AHEAD) do
        if not S.noEdge(S.sqAt(x + o[1], y + o[2])) then return false end
    end
    return S.noTreesAhead(x, y)
end
-- the open patch: every square from lo to hi round (x, y) bare
function S.patchAt(x, y, lo, hi)
    for dy = lo, hi do
        for dx = lo, hi do
            if not S.goodSq(S.sqAt(x + dx, y + dy)) then return false end
        end
    end
    return true
end
-- the nearest such patch to (cx, cy), the more south east the better: first with clearFront, then clearAhead alone
function S.findPatch(cx, cy)
    for pass = 1, 2 do
        for _, r in ipairs({ { -3, 2 }, { -2, 2 } }) do
            local best, bs = nil, 1e9
            for dy = -14, 14 do
                for dx = -14, 14 do
                    local x, y = cx + dx, cy + dy
                    local sc = math.abs(dx) + math.abs(dy) - (dx + dy) * 0.25
                    if sc < bs and S.patchAt(x, y, r[1], r[2]) then
                        local front = false
                        if pass == 1 then front = S.clearFront(x, y) else front = S.clearAhead(x, y) end
                        if front then best, bs = { x = x, y = y, lo = r[1], strict = pass == 1 }, sc end
                    end
                end
            end
            if best then return best end
        end
    end
    return nil
end

-- ----- the crate (bxr_craft.lua's S.setCrate, S.removeObj, S.crateBack)
function S.removeObj(obj)
    if not obj then return end
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if not sq then return end
    pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
    pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
end
function S.setCrate()
    local home = S.sqAt(S.c.x, S.c.y)
    for _, o in ipairs(S.CRATE_AT) do
        if not S.crate then
            local sq = S.goodSq(S.sqAt(S.c.x + o[1], S.c.y + o[2]))
            local reach = false
            if sq and home then pcall(function() reach = home:canReachTo(sq) and true or false end) end
            if sq and reach then
                pcall(function()
                    local obj = IsoObject.new(getCell(), sq, S.CRATE_SPRITE)
                    obj:createContainersFromSpriteProperties()
                    sq:AddTileObject(obj)
                    S.crateObj = obj
                    S.crate = obj:getContainer()
                end)
                if S.crateObj and not S.crate then S.removeObj(S.crateObj); S.crateObj = nil end
                if S.crate then S.crateSide, S.crateSq = o[3], { sq:getX(), sq:getY() } end
            end
        end
    end
    if not S.crate then return false end
    pcall(function() S.crate:setExplored(true) end)
    for _, ft in ipairs(S.CRATE) do
        local it = nil
        pcall(function() it = S.crate:AddItem(ft) end)
        if it then S.crateIts[#S.crateIts + 1] = it end
    end
    return true
end
function S.crateBack()
    for _, it in ipairs(S.crateIts) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.crateIts = {}
    if S.crateObj then S.removeObj(S.crateObj) end
    S.crateObj, S.crate = nil, nil
    local w = S.WW()
    if w then w._containersDirty = true end
end
function S.crateWords()
    local t = {}
    for _, it in ipairs(S.crateIts) do t[#t + 1] = S.nm(it) end
    return table.concat(t, ", ")
end

-- ----- his load (the gallery rule: no picture over the weight limit; gallery_unload.lua's sum, else the same sum here)
function S.load()
    if GAL_UNLOAD and GAL_UNLOAD.weight then return GAL_UNLOAD.weight() end
    local t = 0
    pcall(function()
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if S.p:isEquipped(it) then t = t + it:getEquippedWeight() else t = t + it:getUnequippedWeight() end
        end
    end)
    return t
end
function S.maxLoad()
    local max = 20
    pcall(function() max = S.p:getMaxWeight() end)
    return max
end
function S.drop(it)
    if not it then return end
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
-- the light things, one at a time while the load stays a kilo and a half under his limit (one that takes it past a
-- kilo under goes out again); the count given and held back
function S.giveInv()
    local max = S.maxLoad()
    local n, held = 0, 0
    for _, ft in ipairs(S.INV) do
        local it = nil
        if S.load() <= max - 1.5 then it = S.add(ft) end
        if it and S.load() > max - 1 then S.drop(it); it = nil end
        if it then
            n = n + 1
            S.given[#S.given + 1] = it
            if ft == "Base.TinnedBeans" then S.beans = it end
        else
            held = held + 1
        end
    end
    return n, held
end

-- ----- the pointer the game's Lua reads (Mouse.setXY does not move it): a spot while a menu is made, then off every
-- window and menu (-9000) until the pictures are done
function S.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    getMouseX = function() return S.fx end
    getMouseY = function() return S.fy end
end
function S.mouseOff()
    if not S.mouseSwapped then return end
    getMouseX, getMouseY = S.realMX, S.realMY
    S.mouseSwapped = false
end

-- ----- the input mode ZeD reads (bxr_menus.lua; Input/InputModeDetector.lua:312 getMode, :358 setLockedMode)
-- the lock as found: ZeD setup's Input lock ("auto" is no lock); the save's copy only when the setting cannot be read
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.opt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
-- mode "kbm" (a right-click menu anchors at the click, as a mouse player's does); nil or false puts back the lock found
function S.lock(mode)
    pcall(function()
        if S.lockWas == nil then S.lockWas = S.lockFound() end
        if mode then
            S.Det.setLockedMode(mode)
            S.locked = true
            return
        end
        if not S.locked then return end
        S.locked = false
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
end

-- ----- the settings at ZeD's defaults, and back (S.opt: hfr_common.lua:141, the ZeD_UI option by id; a combo's
-- setValue only sets its item, vanilla PZAPI/ModOptions.lua:137-142)
function S.lookWord(id, v)
    local St, k = ZeD.Settings, nil
    if id == "textSize" and St.sizeKeys then k = St.sizeKeys[v]
    elseif id == "uiScale" and St.scaleKeys then k = St.scaleKeys[v]
    elseif id == "contextStyle" then k = (v == 1) and "strip" or ((v == 2) and "list" or nil) end
    if type(k) == "number" then k = tostring(k) .. "x" end
    return tostring(k) .. " (item " .. tostring(v) .. ")"
end
-- put on screen: Settings.lua:1443 applyThemeNow() (the theme, text size and see-through from the options as they
-- stand); Settings.lua:186-198 applyScale(idx) (ZeD.Scale.userScale from the item, the root worked out again and the
-- re-theme run at once: a new root shuts both windows and opens them 3 ticks later, shared/ZeD/Scale.lua:1130-1160)
function S.lookApply(id, v)
    if id == "textSize" then pcall(ZeD.Settings.applyThemeNow)
    elseif id == "uiScale" then pcall(ZeD.Settings.applyScale, v) end
    S.lookAt = getTimestampMs()
end
function S.lookSet(id)
    local o = S.opt(id)
    local v = S.LOOK_DEF[id]
    if not (o and v) then return "NOTE no " .. tostring(S.LOOK_NAME[id]) .. " option to set" end
    local cur = o:getValue()
    if S.was.look[id] == nil then S.was.look[id] = cur end
    if cur ~= v then o:setValue(v); S.lookApply(id, v) end
    return tostring(S.LOOK_NAME[id]) .. " " .. S.lookWord(id, v) .. ", ZeD's default (found " .. S.lookWord(id, S.was.look[id]) .. ")"
end
function S.lookBack(id)
    local was = S.was.look[id]
    if was == nil then return end
    S.was.look[id] = nil
    local o = S.opt(id)
    if not o then return end
    if o:getValue() ~= was then o:setValue(was); S.lookApply(id, was) end
end
function S.lookNow(id)
    local o = S.opt(id)
    if not o then return "?" end
    return S.lookWord(id, o:getValue())
end
-- his pinned actions (ContextMenuRegistry.lua:925-956: player modData ZeD_PinnedContextIds, { id = true }; a pinned
-- action comes first in its group, applyPins at :963): none for the strip, ZeD's default; the same table back after
function S.pinsAside()
    if S.was.pinsAside then return end
    local md = S.p:getModData()
    if not md then return end
    S.was.ctxPins = md.ZeD_PinnedContextIds
    S.was.nPins = S.count(md.ZeD_PinnedContextIds)
    S.was.pinsAside = true
    md.ZeD_PinnedContextIds = {}
end
function S.pinsBack()
    if not S.was.pinsAside then return end
    local md = S.p:getModData()
    if md then md.ZeD_PinnedContextIds = S.was.ctxPins end
    S.was.pinsAside = nil
end

-- ----- the lists (InventoryRenderer.lua:2648 _flatItems, :2703 _scroll.visible, :2924 _rowView)
function S.inList(inv)
    local w = S.WW()
    if not (w and inv) then return false end
    for _, c in ipairs(w._containers or {}) do if c.inventory == inv then return true end end
    return false
end
-- a list's rows: how many, how many row zones stand whole in its view, whether it scrolls
function S.rowsLine(c)
    if not c then return "no list" end
    local rv = c._rowView
    local shown = 0
    for _, z in ipairs(c._hitZones or {}) do
        if type(z.id) ~= "string" and rv and rv.top and rv.bottom and z.y >= rv.top and z.y + z.h <= rv.bottom then shown = shown + 1 end
    end
    local sc = c._scroll
    return tostring(#(c._flatItems or {})) .. " rows, " .. shown .. " whole in its view, scroll bar " .. tostring(sc ~= nil and sc.visible == true)
end
function S.charListWord()
    local c = S.cc()
    local inv = c and c._inventory
    if inv ~= nil and inv == S.p:getInventory() then return "on his inventory" end
    local t = "?"
    if inv ~= nil then pcall(function() t = tostring(inv:getType()) end) end
    return "NOTE on " .. t .. ", not his main inventory"
end
function S.listTop()
    local c = S.cc()
    local sc = c and c._scroll
    if sc and sc.setScrollPos then pcall(function() sc:setScrollPos(0) end) end
    S.seekPos = nil
end
-- the row whole inside the list's view (bxr_inv.lua): a row past the view's foot still has its zone, cut off
function S.rowShown(c, item)
    local z = c and item and S.zone(c, item)
    local rv = c and c._rowView
    if not (z and rv and rv.top and rv.bottom) then return false end
    return z.y >= rv.top and z.y + z.h <= rv.bottom
end
-- hfr_common.lua's S.seekRow scroll steps until the row stands whole in the view
function S.seekShown(c, item)
    if S.rowShown(c, item) then return true end
    local sc = c and c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        sc:setScrollPos(S.seekPos)
    end
    return false
end
-- a stacked kind has no row of its own: its stack opened (bxr_menus.lua), shut again after
function S.openStackOf(it)
    local c, ft = S.cc(), nil
    pcall(function() ft = it:getFullType() end)
    if not (c and ft) then return end
    c._expandedStacks = c._expandedStacks or {}
    if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
    c._expandedStacks[ft] = true
    for _, cs in ipairs(c._colStates or {}) do cs.expandedStacks = cs.expandedStacks or c._expandedStacks; cs.expandedStacks[ft] = true end
end
function S.stacksBack()
    pcall(function()
        local c = S.cc()
        for ft, v in pairs(S.stackWas) do
            if c and c._expandedStacks then c._expandedStacks[ft] = (v ~= false) and v or nil end
            for _, cs in ipairs((c and c._colStates) or {}) do if cs.expandedStacks then cs.expandedStacks[ft] = (v ~= false) and v or nil end end
        end
    end)
    S.stackWas = {}
end
-- the Character window held "in use" while its row is right-clicked (bxr_menus.lua; Organisms.lua:418 ZeD_Window:_inUse
-- asks pointerOn, which reads the real pointer): as a player with his pointer on the row has it. false puts it back
function S.holdChar(on)
    if on then
        local w = S.CW()
        if w and not S.heldWin then S.heldWin = w; w.pointerOn = function() return true end end
    elseif S.heldWin then
        S.heldWin.pointerOn = nil
        S.heldWin = nil
    end
end
-- how a window is drawn now (Organisms.lua:418 _inUse, :435 _surfaceAlpha: solid while in use, else the theme's
-- see-through; nil _seeA is the theme's own alpha)
function S.drawnWord(w)
    if not w then return "not open" end
    local use = false
    pcall(function() use = w:_inUse() and true or false end)
    local a = w._seeA
    return (use and "in use" or "not in use") .. ", drawn " .. ((a == nil) and "at the theme's own alpha"
        or ((a >= 0.99) and "solid" or ("at alpha " .. tostring(math.floor(a * 100 + 0.5) / 100))))
end

-- ----- 07's right-click: the list's own, and its item card (ZeD_CharacterWindow.lua:552 _rmbMenuItems selects the
-- row, :5965 updateDrawer opens its card in the drawer at the half card, :154 ITEM_CARD_W = 220 units; the drawer
-- grows the window to the left of its right edge, :5197-5209)
S.CARD_U = 220
-- the Character window a half card in from the screen's left edge (G1.clear's margin, T.px(12)), clear of him
function S.placeForCard()
    local w = S.CW()
    if not w then return end
    local m, card = ZeD.T.px(12), ZeD.T.px(S.CARD_U)
    local x = m + card
    local r = G1.charRect()
    if x + w:getWidth() > r.x0 then x = math.max(m, r.x0 - w:getWidth() - 1) end
    S.st.room = x - m >= card
    if w:getX() ~= x then
        w:setX(x)
        if w._anchorRightEdge ~= nil then w._anchorRightEdge = x + w:getWidth() end
    end
end
-- the selection as found (its things), kept before the right-click
function S.selNow()
    local c = S.cc()
    local t = {}
    for it in pairs((c and c._selectedItems) or {}) do t[#t + 1] = it end
    return t
end
-- the selection emptied and the card shut (bxr_inv.lua's S.shutCard: emptied in place, the list binds its column's
-- own table again every frame), then the things selected before put back in the same table
function S.cardShut()
    if not S.st.clicked then return end
    S.st.clicked = nil
    local c, w = S.cc(), S.CW()
    if not (c and w) then return end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    c._selectedItems = sel
    c._lastClickedItem = nil
    for _, cs in ipairs(c._colStates or {}) do
        if cs.selectedItems and cs.selectedItems ~= sel then for k in pairs(cs.selectedItems) do cs.selectedItems[k] = nil end end
        cs.lastClickedItem = nil
    end
    if w._updateDrawer then pcall(w._updateDrawer, c) end
    -- (as found: normally nothing; a single list's column state holds the same selection)
    local one = (#(c._colStates or {}) == 1) and c._colStates[1] or nil
    for _, it in ipairs(S.st.selWas or {}) do
        sel[it] = true
        if one and one.selectedItems then one.selectedItems[it] = true end
    end
end

-- ----- the right-click menu (bxr_menus.lua)
function S.vmenu() return getPlayerContextMenu(S.pn) end
function S.menu() local v = S.vmenu(); return v and v._zedMenu or nil end
function S.closeMenu()
    local m = S.menu()
    if m then pcall(m.close, m) end
    local v = S.vmenu()
    pcall(function() if v and not v._zedMenu and v.closeAll and v:isVisible() then v:closeAll() end end)
    S.mouseOff()
end
function S.menuSettled()
    if S.menu() then return true end
    local v = S.vmenu()
    if not v then return true end
    return v._zedFailed == true
end
function S.over(x, y, w, h)
    local r = G1.charRect()
    return x < r.x1 and x + w > r.x0 and y < r.y1 and y + h > r.y0
end
function S.onScreen(x, y, w, h)
    local sw, sh = S.scr()
    return x >= -1 and y >= -1 and x + w <= sw + 1 and y + h <= sh + 1
end

-- ----- what the lines say
function S.box(w)
    if not w then return nil end
    return { x = S.fl(w:getX()), y = S.fl(w:getY()), w = S.fl(w:getWidth()), h = S.fl(w:getHeight()) }
end
function S.boxWord(b)
    if not b then return "none" end
    return b.x .. "," .. b.y .. " " .. b.w .. "x" .. b.h
end
-- the scale and sizes measured in game (Tokens.lua:1160-1181 T.fontPx, T.root, T.scale; :1225-1227 T.rowH, T.buttonH;
-- shared/ZeD/Scale.lua:55 userMul, :230 root, :996 ZeD.TM:getFontHeight)
function S.scaleLine()
    local T = ZeD.T
    local root, mul = nil, nil
    pcall(function() root = ZeD.Scale.root() end)
    pcall(function() mul = ZeD.Scale.userMul() end)
    local note = ""
    if type(root) == "number" and math.abs(root - 0.75) > 0.005 then note = " (NOTE: not the 0.75 that Auto gives this screen at the game's 19 px Font Size)" end
    local t = { "measured: root scale " .. tostring(root) .. note .. ", T.scale " .. tostring(T.scale) .. " (the game's Font Size multiplier " .. tostring(mul) .. ")" }
    for _, e in ipairs({ { "body text (F2 Body)", "fontF2" }, { "chrome words (F1 Chrome)", "fontF1" } }) do
        local f = T[e[2]]
        local px = (f ~= nil and T.fontPx) and T.fontPx[f] or nil
        local h = nil
        if f ~= nil then pcall(function() h = ZeD.TM:getFontHeight(f) end) end
        if px then
            t[#t + 1] = string.format("%s %d px at 1x drawn at %.1f px (line %.1f px)", e[1], S.fl(px), px * (T.root or 1), tonumber(h) or -1)
        else
            t[#t + 1] = e[1] .. " on the game's own font (fallback " .. tostring(T.fontFallback) .. ", line " .. tostring(h) .. " px)"
        end
    end
    t[#t + 1] = "rows " .. tostring(T.rowH) .. " px, buttons " .. tostring(T.buttonH) .. " px, strip cells " .. tostring(T.ctx and T.ctx.cellW) .. " px (22 at 1x)"
    return table.concat(t, ", ")
end
-- the strip as drawn (ZeD_ContextMenu.lua:56-112 _ctx and _layoutCache, :434-460 the balloon; Molecules.lua:4547: the
-- balloon's box in panel space, 0 wide when another balloon holds the slot; :548 the anchor slot when it scrolls)
function S.stripLine(m)
    local c, ctx, k = m._layoutCache, m._ctx, ZeD.T.ctx
    local items = ctx.items or {}
    local n = #items
    local sel = ctx.selected or 0
    local lit = items[sel]
    local ext = (k.gutter or 0) + (k.chevW or 0)
    local sx, sy = m:getX() + (c.stripX or 0), m:getY() + (c.stripY or 0)
    local sw, sh = c.stripW or 0, c.stripH or 0
    local bx, by = m:getX() + (c.balloonX or 0), m:getY() + (c.balloonY or 0)
    local bw, bh = c.balloonW or 0, c.balloonH or 0
    local shown = math.min(n, k.maxVisible or n)
    local slot = ctx.truncating and (math.floor((shown - 1) / 2) + 1) or sel
    local names = {}
    for i = 1, math.min(n, 12) do names[#names + 1] = tostring(items[i] and items[i].name) end
    local over = S.over(sx - ext, sy, sw + ext * 2, sh) or (bw > 0 and S.over(bx, by, bw, bh))
    -- where the strip lies against the clicked row (its middle against the row's: a row's height either way is the
    -- row above or below)
    local where = "?"
    if S.st.rowTop and S.st.rowH then
        local d = (sy + sh / 2) - (S.st.rowTop + S.st.rowH / 2)
        if d <= -S.st.rowH / 2 then where = "on the row above the clicked one"
        elseif d >= S.st.rowH / 2 then where = "on the row below the clicked one"
        else where = "NOTE over the clicked row" end
        where = where .. " (" .. S.fl(d) .. " px from its middle)"
    end
    local cw, cc = S.CW(), S.cc()
    local rowSel = cc ~= nil and cc._selectedItems ~= nil and S.beans ~= nil and cc._selectedItems[S.beans] == true
    local push = (cw and cw._drawerCapPush or 0) > 0
    return "ZeD's defaults: " .. tostring(S.lookLine) .. "; " .. tostring(S.st.look) .. "; no pinned actions, ZeD's default ("
        .. tostring(S.was.nPins or 0) .. " of his set aside); " .. S.scaleLine()
        .. " | a mouse right-click on " .. S.nm(S.beans) .. "'s row in the Character list at " .. tostring(S.st.x) .. "," .. tostring(S.st.y)
        .. " (the list's own right-click, the pointer the game reads on the row): the row selected " .. tostring(rowSel)
        .. ", its item card open in the drawer " .. tostring(S.cardOn(S.beans)) .. " (a right-click on a row does both)"
        .. "; the Character window " .. S.boxWord(S.st.box0) .. " before the right-click, " .. S.boxWord(S.box(cw)) .. " with the card"
        .. (push and " (NOTE the card pinned it at the screen's left edge: the list moved right under the strip)" or " (it opened to the left, the list in place)")
        .. ", " .. S.drawnWord(cw) .. (G1.covers(cw) and ", NOTE it covers him" or "")
        .. "; ZeD's strip of " .. n .. " actions" .. (ctx.truncating and (", " .. shown .. " cells shown at a time") or "")
        .. ", cells " .. tostring(k.cellW) .. "x" .. tostring(k.cellH) .. " px; "
        .. ((sel == 1) and "the first action lit" or ("NOTE action " .. tostring(sel) .. " lit, not the first"))
        .. " (\"" .. tostring(lit and lit.name) .. "\", cell " .. tostring(slot) .. " from the left of the " .. shown .. " shown)"
        .. ((bw > 0) and (" and the one balloon naming it, " .. S.fl(bw) .. "x" .. S.fl(bh) .. " at " .. S.fl(bx) .. "," .. S.fl(by))
            or " (NOTE no balloon drawn: another balloon held the slot)")
        .. "; the strip " .. S.fl(sx) .. "," .. S.fl(sy) .. " " .. S.fl(sw) .. "x" .. S.fl(sh) .. (m._flipped and ", under the click (no room above it)" or ", above the click")
        .. ", " .. where .. ", all on screen " .. tostring(S.onScreen(sx - ext, sy, sw + ext * 2, sh))
        .. (over and ", NOTE it lies over the character" or ", beside the character")
        .. "; its actions: " .. table.concat(names, ", ")
        .. "; the pointer the game reads then moved off the strip (no cell hovered), the Character window held in use as the pointer on its row holds it; the World window "
        .. S.drawnWord(S.WW()) .. "; zoom " .. tostring(S.zoom()) .. S.frontNote()
end
-- picture 12's line: the screen, the settings and scale, both lists, where the windows stand and how they are drawn
function S.line12(cw, ww)
    local W, H = S.scr()
    local where = ""
    if S.def and (S.def.cc or S.def.cw) then
        where = "; at the default spread (Character " .. S.boxWord(S.def.c) .. ", World " .. S.boxWord(S.def.w) .. ") "
            .. ((S.def.cc and S.def.cw) and "both windows" or (S.def.cc and "the Character window" or "the World window"))
            .. " covered him: moved to the screen's edge for the picture (Character " .. S.boxWord(S.box(cw)) .. ", World " .. S.boxWord(S.box(ww)) .. ")"
    else
        where = "; both windows at their default spread (Character " .. S.boxWord(S.box(cw)) .. ", World " .. S.boxWord(S.box(ww)) .. "), clear of him"
    end
    return "the whole " .. W .. "x" .. H .. " window at 1x, keyboard and mouse, he on the open patch by the store's smoking spot facing the camera"
        .. S.frontNote() .. "; " .. tostring(S.lookLine) .. "; " .. S.scaleLine()
        .. "; both windows open on Loot: the Character list " .. S.charListWord() .. ", " .. S.rowsLine(S.cc()) .. " (" .. #S.given .. " things given here)"
        .. ", the World list on a wooden crate set " .. tostring(S.crateSide) .. " of him on the open patch, " .. S.rowsLine(S.wc()) .. ": " .. S.crateWords()
        .. where .. "; the Character window " .. S.drawnWord(cw) .. ", the World window " .. S.drawnWord(ww)
        .. "; zoom " .. tostring(S.zoom()) .. ", load " .. string.format("%.1f of %.1f kg", S.load(), S.maxLoad())
        .. "; the pointer the game reads off every window (no row lit), the real one hidden"
end
-- what stands in front of him: none (the stricter test), or a note for the picture review
function S.frontNote()
    if S.c and not S.c.strict then return "; NOTE open ground in front of him, but a fence, wall or tree crown may be drawn there" end
    return ""
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    if getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
    S.was.zoom = S.zoom()
    -- keyboard and mouse: a right-click menu anchors at the click (a controller mode anchors it on the character);
    -- the lock as found comes back at the end
    S.lock("kbm")
    local W, H = S.scr()
    if not (W == S.DECK_W and H >= S.DECK_H - 40 and H <= S.DECK_H) then
        S.why = "the screen is " .. W .. "x" .. H .. ", not the Steam Deck's 1280x800 (kiss_pics_run.ps1 -Part deck opens a 1280x800 window)"
        Q.say("ERR " .. S.why .. ": every picture is skipped")
        return
    end
    local c = S.P.smoke or S.P.centre
    S.c = c and S.findPatch(c[1], c[2]) or nil
    if not S.c then
        S.why = "no open patch within 14 squares of the story's smoking spot"
        Q.say("ERR " .. S.why .. ": every picture is skipped")
        return
    end
    G1.tp({ S.c.x, S.c.y }, "SE")
    S.ok = true
    Q.say("the patch's middle " .. S.c.x .. "," .. S.c.y .. " (the smoking spot " .. c[1] .. "," .. c[2] .. "), bare from " .. S.c.lo .. " to 2 round it, "
        .. (S.c.strict and "no fence, wall or tree crown in front of him" or "NOTE open ground in front of him, but a fence, wall or tree crown may be drawn there (no patch passed the stricter test)")
        .. " | screen " .. W .. "x" .. H .. ", zoom was " .. tostring(S.was.zoom) .. ", input lock found " .. tostring(S.lockWas)
        .. " | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "?"))
end)
Q.zoomTo(1.0)
S.settle(function() return S.ok == true end)

-- ===================================================================== the scene: the settings, the windows, the crate
-- the pair open as it was and its places kept (zedqa_prelude.lua:93 ZEDQA_LAYOUT_SNAP: each window's place, size,
-- rolled state and pins), then the two settings at ZeD's defaults
Q.step(10, function() if S.ok then S.openPair() end end)
Q.waitFor(10, 600, function() return not S.ok or (S.CW() ~= nil and S.WW() ~= nil) end, function(ok)
    if not S.ok then return end
    if not ok then S.ok = false; S.why = "the windows did not open"; Q.say("ERR " .. S.why); return end
    pcall(function() S.was.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil end)
    -- (InventoryRenderer.lua:362-396: the bag's list or grid view, its own choice kept in modData ZeD_GridViews, else
    -- the Inventory option; the layout default below sets a grid bag to a list. The stored choice is kept as it is,
    -- none included, so the put-back writes no choice the bag did not have)
    pcall(function()
        local IR = ZeD.InventoryRenderer
        S.gridKey = IR.containerKey and IR.containerKey(S.p:getInventory(), S.p) or "player"
        S.was.grid = IR.isGridKey(S.gridKey)
        local gv = S.p:getModData().ZeD_GridViews
        S.was.gridRaw = gv and gv[S.gridKey]
        S.was.gridTaken = true
    end)
    S.lookLine = S.lookSet("textSize") .. "; " .. S.lookSet("uiScale")
    Q.say("for the pictures: " .. S.lookLine)
end)
-- (a new root scale shuts both windows and opens them again 3 ticks later: ZeD.Scale._reopenAt, Scale.lua:1128-1165)
S.wait(4000, function()
    if not S.ok then return true end
    return ZeD.Scale._reopenAt == nil and S.CW() ~= nil and S.WW() ~= nil and getTimestampMs() - (S.lookAt or 0) > 500
end, function(ok)
    if S.ok and not ok then Q.say("note: 4 s after the settings the windows are not both open (Character " .. tostring(S.CW() ~= nil) .. ", World " .. tostring(S.WW() ~= nil) .. ")") end
end)
Q.step(10, function()
    if not S.ok then return end
    S.openPair()
    -- zedqa_prelude.lua:108 ZEDQA_LAYOUT_DEFAULT: both windows at the default spread through the mod's own
    -- ZeD_Window.resetLayout (Organisms.lua:1607), on Loot, drawers shut, pinned; the bag as a list
    if ZEDQA_LAYOUT_DEFAULT then pcall(ZEDQA_LAYOUT_DEFAULT, "kssd") else pcall(function() ZeD_Window.resetLayout() end) end
    S.charTab("loot"); S.worldTab("loot")
    if not S.setCrate() then
        S.ok = false
        S.why = "no wooden crate could be set on a bare square west or north of him"
        Q.say("ERR " .. S.why)
        return
    end
    local n, held = S.giveInv()
    Q.say(string.format("a wooden crate (%s) set %s of him at %d,%d with %d of %d things; %d light things of their own kinds given to him, %d held back for the weight%s",
        S.CRATE_SPRITE, tostring(S.crateSide), S.fl(S.crateSq[1]), S.fl(S.crateSq[2]), #S.crateIts, #S.CRATE, n, held, S.beans and "" or " (NOTE: no can of beans)")
        .. " | load " .. string.format("%.1f of %.1f kg", S.load(), S.maxLoad()))
    local w = S.WW()
    if w then w._containersDirty = true end
end)
-- the World list on the crate (ZeD_WorldWindow.lua:6332 selectContainer(inv, tries, pn): the Loot pane on that one
-- container; the window scans the 3 x 3 round him itself, buildWorldContainers at :2794)
Q.waitFor(10, 900, function() return not S.ok or S.inList(S.crate) end, function(ok)
    if not S.ok then return end
    if not ok then S.ok = false; S.why = "the World window does not list the crate"; Q.say("ERR " .. S.why); return end
    pcall(S.WWm.selectContainer, S.crate, 120, S.pn)
end)
Q.waitFor(10, 900, function()
    if not S.ok then return true end
    local c = S.wc()
    return c ~= nil and c._inventory == S.crate and S.oneSource()
end, function(ok)
    if not S.ok then return end
    if not ok then
        local c = S.wc()
        local t = "?"
        if c and c._inventory then pcall(function() t = tostring(c._inventory:getType()) end) end
        Q.say("note: the World list is not on the crate alone (it shows " .. t .. ")")
    end
    S.listTop()
    -- the pointer the game reads off every window: no row, control or balloon lit by the resting real pointer
    S.mouseOn(-9000, -9000)
end)
-- the spread as the reset left it, then a window over him to the screen's edge (logged by G1.clear)
Q.still(10, function()
    if not S.ok then return end
    S.def = { c = S.box(S.CW()), w = S.box(S.WW()), cc = G1.covers(S.CW()), cw = G1.covers(S.WW()) }
    S.clearChar()
end)

-- ===================================================================== 12: the text at the Deck's size
Q.still(10, function()
    local name = "12_deck_text_small"
    if not S.ok then S.skip(name, S.why or "not staged"); return end
    local cw, ww = S.CW(), S.WW()
    if not (cw and ww and cw._activeTab == "loot" and ww._activeTab == "loot") then
        S.skip(name, "both windows are not open on Loot (Character " .. tostring(cw and cw._activeTab) .. ", World " .. tostring(ww and ww._activeTab) .. ")")
        return
    end
    -- (the line built under pcall: a read that fails still leaves the picture and a line saying so)
    local okL, what = pcall(S.line12, cw, ww)
    if not okL then what = "NOTE the picture's line could not be built: " .. tostring(what) end
    S.take(name, what)
end)

-- ===================================================================== 07: the strip on a can of beans
Q.step(10, function()
    if not (S.ok and S.beans) then return end
    S.st.on = true
    S.st.look = S.lookSet("contextStyle")
    S.pinsAside()
    S.holdChar(true)
    S.seekPos = nil
    S.openStackOf(S.beans)
    -- (room on its left for the card the right-click opens: the drawer grows the window left of its right edge)
    S.placeForCard()
    Q.say("07: " .. tostring(S.st.look) .. "; the Character window to " .. S.boxWord(S.box(S.CW())) .. " (room on its left for the half card "
        .. tostring(S.st.room) .. "), covering him " .. tostring(G1.covers(S.CW())))
end)
-- the window still in its new place (the frame at rest sets its right edge's anchor from it) before the right-click
Q.still(5, function() end)
Q.waitFor(5, 600, function() return not S.st.on or S.seekShown(S.cc(), S.beans) end, function(ok)
    if not S.st.on then return end
    local c = S.cc()
    local z = (ok and c) and S.zone(c, S.beans) or nil
    if not z then S.st.why = "the can's row never stood whole in the Character list's view"; return end
    -- where on the row (bxr_menus.lua W15): the strip opens with its bottom T.px(6) above the click
    -- (ZeD_ContextMenu.lua:1016 _positionAssembly), so a click near the row's top lays it level on the row above.
    -- With no room above for its balloon it flips under the click (the same test as :1038-1046): then a click near
    -- the row's foot lays it level on the row below. Either way the clicked row stays in sight
    local x, y = nil, nil
    pcall(function()
        local T = ZeD.T
        local k = T.ctx
        local stripH = k.cellH + k.drilledBorderTop + T.px(1)
        local top = c:getAbsoluteY() + z.y
        local pad, need, sh = T.px(8), T.px(160) + stripH + T.px(6), S.core:getScreenHeight()
        local lo, hi = top + 2, top + z.h - 2
        local yA = S.fl(math.max(lo, math.min(hi, top - z.h / 2 + stripH / 2 + T.px(6))))
        local yB = S.fl(math.max(lo, math.min(hi, top + z.h * 1.5 - stripH / 2 - T.px(6))))
        local flipA = (yA - pad) < need and (sh - yA - pad) > (yA - pad)
        local flipB = (yB - pad) < need and (sh - yB - pad) > (yB - pad)
        y = (flipA and flipB) and yB or yA
        x = S.fl(c:getAbsoluteX() + z.x + math.min(z.w / 2, T.px(110)))
        S.st.rowTop, S.st.rowH = top, z.h
    end)
    if not x then S.st.why = "the can's row has no place on screen"; return end
    S.st.x, S.st.y = x, y
    S.st.box0 = S.box(S.CW())
    S.st.selWas = S.selNow()
    S.mouseOn(x, y)
    -- the list's own right-click (ZeD_CharacterWindow.lua:7419-7450; rt_menus.lua's H.rightClick drives it the same
    -- way): the row becomes the selection and its card opens (:552 _rmbMenuItems, :5965 updateDrawer), then the game's
    -- inventory right-click (Overrides/ContextMenu.lua:233: with the mouse's input mode it anchors at getMouseX /
    -- getMouseY, the click's place here); the menu's first drawn frame makes ZeD's menu, the Context menu setting
    -- picking the strip (:388-392)
    local lx, ly = x - c:getAbsoluteX(), y - c:getAbsoluteY()
    S.st.clicked = true
    local okM, e = pcall(function() c:onRightMouseDown(lx, ly); c:onRightMouseUp(lx, ly) end)
    if not okM then S.st.why = "the right-click stopped: " .. tostring(e); return end
    S.st.asked = true
end)
-- the menu made: the pointer goes off every menu (a resting real pointer must not take a cell)
Q.waitFor(1, 300, function() return not S.st.asked or S.menuSettled() end, function()
    if S.st.asked then S.mouseOn(-9000, -9000) end
end)
-- drawn: the strip laid out, its cells' zones and its balloon
Q.waitFor(1, 120, function()
    if not S.st.asked then return true end
    local m = S.menu()
    local c = m and m._layoutCache
    return m == nil or (c ~= nil and (c.stripW or 0) > 0 and (c.balloonW or 0) > 0 and #(m._hitZones or {}) > 0)
end, function() end)
-- (any slide over: the strip's own transitions take 180 ms, T.ctx.animMs)
S.wait(400, function() return false end, function() end)
Q.still(2, function()
    local name = "07_deck_strip"
    if not S.ok then S.skip(name, S.why or "not staged"); return end
    if not S.beans then S.skip(name, "no can of beans could be given (his load)"); return end
    if not S.st.on then S.skip(name, "not staged"); return end
    local m = S.menu()
    if S.st.why or not m then
        local v, cc = S.vmenu(), S.cc()
        local rowSel = cc ~= nil and cc._selectedItems ~= nil and cc._selectedItems[S.beans] == true
        S.skip(name, S.st.why or ("ZeD's menu did not open after the row's right-click (the row selected " .. tostring(rowSel)
            .. ", the game's options " .. tostring(v and v.options and #v.options) .. ", ZeD's menu failed " .. tostring(v and v._zedFailed) .. ")"))
        return
    end
    if m.Type ~= "ZeD_ContextMenu" then S.skip(name, "the menu opened as " .. tostring(m.Type) .. ", not the strip"); return end
    local okL, what = pcall(S.stripLine, m)
    if not okL then what = "ZeD's strip open on " .. S.nm(S.beans) .. " (NOTE the picture's line could not be built: " .. tostring(what) .. ")" end
    S.take(name, what, true)
end)
Q.step(5, function()
    S.closeMenu()
    S.cardShut()
    S.holdChar(false)
    S.lookBack("contextStyle")
    S.pinsBack()
    S.stacksBack()
    S.listTop()
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.closeMenu()
    S.cardShut()
    S.mouseOff()
    S.holdChar(false)
    S.pinsBack()
    S.lookBack("contextStyle")
    S.stacksBack()
    S.takeMade()
    S.crateBack()
    S.lookBack("textSize")
    S.lookBack("uiScale")
    S.lock(false)
    G1.glassesBack(Q)
end)
-- (a root scale put back shuts both windows and opens them 3 ticks later)
S.wait(4000, function() return ZeD.Scale._reopenAt == nil and getTimestampMs() - (S.lookAt or 0) > 500 end, function() end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
end)
Q.step(20, function()
    -- zedqa_prelude.lua:151 ZEDQA_LAYOUT_BACK: the mod's reset, then each window's place, size and pins as found
    if ZEDQA_LAYOUT_BACK and S.was.snap then pcall(ZEDQA_LAYOUT_BACK, S.was.snap, "kssd") end
    -- (the bag's own list or grid choice as it was stored: none stays none, so it still follows the Inventory option)
    pcall(function()
        if not (S.gridKey and S.was.gridTaken) then return end
        local md = S.p:getModData()
        if S.was.gridRaw == nil then
            if md.ZeD_GridViews then md.ZeD_GridViews[S.gridKey] = nil end
        else
            md.ZeD_GridViews = md.ZeD_GridViews or {}
            md.ZeD_GridViews[S.gridKey] = S.was.gridRaw
        end
    end)
    S.listTop()
    local hurt = false
    pcall(function() hurt = S.p:getBodyDamage():getOverallBodyHealth() < 99 end)
    if hurt then pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end) end
    if S.P.stock then G1.tp(S.P.stock, "SE") end
    S.back0()
end)
S.zoomDyn(function() return S.was.zoom end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Events.OnPreUIDraw.Remove(S.errWatch)
    local mode, pins = "?", 0
    pcall(function() mode = tostring(S.Det.getMode(S.pn)) end)
    pcall(function() pins = S.count(S.p:getModData().ZeD_PinnedContextIds) end)
    Q.say("put back: things given taken away, the crate gone " .. tostring(S.crateObj == nil) .. ", Text size " .. S.lookNow("textSize")
        .. ", UI scale " .. S.lookNow("uiScale") .. ", Context menu " .. S.lookNow("contextStyle") .. ", pinned actions " .. pins
        .. " (found " .. tostring(S.was.nPins or pins) .. "), input lock as found (" .. tostring(S.lockWas) .. "; ZeD reads " .. mode
        .. "), mouse swap " .. tostring(S.mouseSwapped == true) .. ", Character window held " .. tostring(S.heldWin ~= nil)
        .. ", zoom " .. tostring(S.zoom()) .. " (found " .. tostring(S.was.zoom) .. "), pair open " .. tostring(S.CWm.isOpen() and S.WWm.isOpen())
        .. " (found " .. tostring(S.was.pairOpen) .. "), in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", alive " .. tostring(not S.p:isDead())
        .. "; pictures taken: " .. ((#S.pic > 0) and table.concat(S.pic, ", ") or "none"))
end)
Q.start()
