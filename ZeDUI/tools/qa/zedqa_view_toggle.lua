-- ZeDUI/tools/qa/zedqa_view_toggle.lua  (Nov 11 2026, Build): the inventory heading's one view button in game (the
-- director, Nov 11: the List and Grid buttons are one; it shows the view you are in, lit in the accent, and a press
-- flips to the other). QA save only (Saves/Sandbox/ZeD-QA), the character on open ground (the drag strip). Copy to
-- Zomboid/Lua/zedqa.lua, bump zedqa.go, grep console.txt for "ZEDQA vtg". PASS / FAIL lines, ending DONE.
-- Screenshots/zqa_vtg_*.png: take the set at 4K 1.75x, then again at the Deck size (1280x800, Auto, Normal and Large
-- text); the script does not resize. In each picture, check the heading: one button right of the name (with the
-- Filter left of it), the list's picture in list view, the grid's in grid view, lit in the accent both times, and the
-- container's name longer than before (no second button).
--   1  things given and things on the floor (the World window's Ground column)
--   2  Character window: one view button per heading; a click at its middle flips the bag to the grid (saved on the
--      bag's key), a second click back to the list
--   3  World window: one view button per column (the Ground column too); a click on the first column's flips that
--      container only, the other columns keep theirs
--   4  controller: one view stop per heading in each window's ring, no old List / Grid stops; A flips, the stop keeps
--      its id (the focus stays on it); A again flips back
--   5  cleanup: every view as it was, the things taken away
local function say(s) print("ZEDQA vtg " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_vtg_" .. n .. ".png") end) end
local p = getPlayer()
local IR = ZeD.InventoryRenderer
local Det = ZeD.Input.Detector
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CC() local w = CWm.getWindow(); return w and w._mainContent end
local function WC() local w = WWm.getWindow(); return w and w._mainContent end
local GIVEN, FLOOR, WAS = {}, {}, {}

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

-- every heading rect of a list panel (the main list's and each column's)
local function rects(c)
    local out = {}
    if not c then return out end
    for _, r in ipairs(c._viewToggleRects or {}) do out[#out + 1] = r end
    for _, cs in ipairs(c._colStates or {}) do
        if cs.viewToggleRects ~= c._viewToggleRects then
            for _, r in ipairs(cs.viewToggleRects or {}) do out[#out + 1] = r end
        end
    end
    return out
end
-- the view buttons by container key; any old List / Grid rect counted apart
local function flips(c)
    local by, n, old = {}, 0, 0
    for _, r in ipairs(rects(c)) do
        if r.view == "flip" then
            if not by[r.key] then n = n + 1 end
            by[r.key] = (by[r.key] or 0) + 1
        elseif r.view == "list" or r.view == "grid" then old = old + 1 end
    end
    return by, n, old
end
-- (each container's view as it was, and its saved choice as it was: nil when it followed the ZeD option)
local function remember(key)
    if key == nil or WAS[key] ~= nil then return end
    local s = p:getModData().ZeD_GridViews or {}
    WAS[key] = { on = IR.isGridKey(key), raw = s[key] }
end
local function click(c, r)
    local ok, e = pcall(function() c:onMouseDown(r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)) end)
    if not ok then say("click error " .. tostring(e)) end
    pcall(function() c:onMouseUp(r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)) end)
end
local function ringStops(win)
    local out, old = {}, 0
    for _, z in ipairs(win and win._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do
            if type(e.id) == "string" then
                if e.id:sub(1, 10) == "view:flip:" then out[#out + 1] = { zone = z, el = e }
                elseif e.id:sub(1, 10) == "view:list:" or e.id:sub(1, 10) == "view:grid:" then old = old + 1 end
            end
        end
    end
    return out, old
end

-- 1  the things
add(300, function()
    p:setGodMod(true)
    for _, full in ipairs({ "Base.CannedCorn", "Base.Apple", "Base.Bandage" }) do
        local ok, it = pcall(function() return p:getInventory():AddItem(full) end)
        if ok and it then GIVEN[#GIVEN + 1] = it end
    end
    local sq = p:getCurrentSquare()
    for _, full in ipairs({ "Base.ScrapMetal", "Base.Rope" }) do
        local ok, it = pcall(function() return sq:AddWorldInventoryItem(full, 0.5, 0.5, 0) end)
        if ok and it then FLOOR[#FLOOR + 1] = it end
    end
    say("given " .. #GIVEN .. ", on the floor " .. #FLOOR)
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)

-- 2  the Character window
local bagRect
add(1500, function()
    local c = CC()
    check(c ~= nil, "the Character window's list is there")
    local by, n, old = flips(c)
    check(n >= 1, "a view button in the heading", n)
    local one = true
    for k, cnt in pairs(by) do remember(k); if cnt ~= 1 then one = false end end
    check(one, "one view button per heading (not a pair)")
    check(old == 0, "no List / Grid pair left", old)
    for _, r in ipairs(rects(c)) do if r.view == "flip" and r.key == "player" then bagRect = r end end
    check(bagRect ~= nil, "the bag's view button")
    IR.setGridKey("player", false)
end)
add(800, function()
    shot("01_char_list")   -- (the list's picture, lit)
    if bagRect then click(CC(), bagRect) end
end)
add(800, function()
    check(IR.isGridKey("player") == true, "a click flips the bag to the grid")
    check((p:getModData().ZeD_GridViews or {}).player == true, "saved on the bag's key")
    check(CC()._gridCell ~= nil, "the grid shows")
    local r2
    for _, r in ipairs(rects(CC())) do if r.view == "flip" and r.key == "player" then r2 = r end end
    check(r2 ~= nil and bagRect ~= nil and r2.x == bagRect.x, "the button stays where it was", r2 and r2.x)
    shot("02_char_grid")   -- (the grid's picture, lit)
    if r2 then click(CC(), r2) end
end)
add(800, function()
    check(IR.isGridKey("player") == false, "a second click flips back to the list")
end)

-- 3  the World window
local first, others
add(800, function()
    local c = WC()
    check(c ~= nil, "the World window's list is there")
    local by, n, old = flips(c)
    local one = true
    for k, cnt in pairs(by) do remember(k); if cnt ~= 1 then one = false end end
    check(n >= 1 and one, "one view button per column", n)
    check(old == 0, "no List / Grid pair left", old)
    for _, r in ipairs(rects(c)) do if r.view == "flip" and not first then first = r end end
    others = {}
    for k in pairs(by) do if first and k ~= first.key then others[k] = IR.isGridKey(k) end end
    say("world columns: " .. n .. ", first " .. tostring(first and first.key))
    shot("03_world_before")
    if first then click(c, first) end
end)
add(800, function()
    if first then check(IR.isGridKey(first.key) == not WAS[first.key].on, "a click flips that column's container", first.key) end
    local kept = true
    for k, v in pairs(others or {}) do if IR.isGridKey(k) ~= v then kept = false end end
    check(kept, "the other columns keep theirs")
    shot("04_world_flipped")
    if first then IR.setGridKey(first.key, WAS[first.key].on) end
end)

-- 4  the controller
add(500, function() Det.setLockedMode(Det.MODE_GAMEPAD) end)
local padStop
add(1200, function()
    local w = CWm.getWindow()
    local stops, old = ringStops(w)
    local seen, dup = {}, false
    for _, s in ipairs(stops) do if seen[s.el.id] then dup = true end; seen[s.el.id] = true end
    check(#stops >= 1 and not dup, "Character window: one view stop per heading", #stops)
    check(old == 0, "Character window: no old List / Grid stops", old)
    local wstops, wold = ringStops(WWm.getWindow())
    check(#wstops >= 1 and wold == 0, "World window: view stops, no old List / Grid stops", #wstops .. " / " .. wold)
    for _, s in ipairs(stops) do if s.el.key == "player" then padStop = s end end
    if padStop then
        for zi, z in ipairs(w._focusRing) do if z == padStop.zone then w._focusIdx = zi end end
        for ei, e in ipairs(padStop.zone.elements) do if e == padStop.el then padStop.zone.focusedElementIdx = ei end end
        shot("05_pad_on_button")
        padStop.el.onActivate(w, padStop.el)
    end
end)
add(800, function()
    check(IR.isGridKey("player") == true, "A flips the bag to the grid")
    local w = CWm.getWindow()
    local e = ZeD.Input.Focus.getFocusedElement(w)
    check(e ~= nil and e.id == "view:flip:player", "the focus stays on the view button", e and e.id)
    shot("06_pad_grid")
    if e and e.onActivate then e.onActivate(w, e) end
end)
add(800, function()
    check(IR.isGridKey("player") == false, "A again flips it back")
end)

-- 5  cleanup
add(600, function()
    Det.setLockedMode(nil)
    local s = p:getModData().ZeD_GridViews
    for k, v in pairs(WAS) do if s then s[k] = v.raw end end
    for _, it in ipairs(GIVEN) do pcall(function() p:getInventory():Remove(it) end) end
    for _, it in ipairs(FLOOR) do pcall(function()
        local wo = it:getWorldItem()
        if wo then wo:getSquare():transmitRemoveItemFromSquare(wo); wo:removeFromSquare() end
    end) end
    say("fails " .. fails)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
