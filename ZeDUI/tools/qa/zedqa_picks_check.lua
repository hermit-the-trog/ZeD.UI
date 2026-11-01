-- ZeDUI/tools/qa/zedqa_picks_check.lua  (Oct 31 2026, QA; the director's layout picks, punch list 28, 29, 35, 36)
-- At the run's size and text (run it in the small windows with Large text, and at 4K):
--   Craft: with a recipe open, whether the band's amount is the one box; its pad stop (craft:actQty): A steps
--     up, Right steps up, Left steps down; shot. Build the same shot.
--   Equip (list), Skills, Maps: shots.
--   Identity: as the width picks it, then forced tall and forced wide (ZeD.IdentityTab.qaLayout), each with the
--     bust and the full-body photo, at the top and scrolled to the bottom; win._idTall printed; the photo's
--     rect against the tab's view (win._idView) printed.
-- ZEDQA_PICK_TEXT = "large" (set by zedqa_picks_large.lua before it) sets Large text for the run (put back at the end). Shots zqa_pick_<what>.png. grep "ZEDQA pick".
local TEXT = ZEDQA_PICK_TEXT or "small"; ZEDQA_PICK_TEXT = nil
local TAG = TEXT .. "_" .. tostring(getCore():getScreenHeight())
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local F = ZeD.Input.Focus
local p = getPlayer()
local function say(s) print("ZEDQA pick " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_pick_" .. n .. ".png") end) end
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function tab(win, key, id) local s = win and win[key]; for _, z in ipairs((s and s._hitZones) or {}) do if z.id == "tab:" .. id and win._activeTab ~= id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local function zone(w, name) for _, z in ipairs(w._focusRing or {}) do if z.zone == name then return z end end end
local function stop(w, zn, id) local z = zone(w, zn); for _, e in ipairs((z and z.elements) or {}) do if tostring(e.id) == id then return e end end end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local sizeWas = ZeD.currentSize
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    if TEXT == "large" then ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, "large") end
end)
step(30, function() pcall(ZeD_Window.resetLayout) end)
-- Craft with a recipe, the amount box
step(20, function()
    tab(WW(), "_actionTabStrip", "craft")
end)
step(40, function()
    local st = WW()._craftState
    local data = ZeD.CraftingTab.gatherData(p, WW())
    local pick
    for _, rd in ipairs(data and data.recipes or {}) do if rd.status == "unlocked" then pick = rd; break end end
    pick = pick or (data and data.recipes and data.recipes[1])
    if pick then ZeD.CraftingCore.openCraft(st, pick.entry.name) end
end)
step(40, function()
    local st = WW()._craftState
    local qb = st and st._qtyBox
    say("craft: the one amount box " .. tostring(qb and qb.on) .. ", max " .. tostring(st and st._maxQty))
    shot("craft_" .. TAG)
    local e = stop(WW(), "worldTabContent", "craft:actQty")
    if qb and qb.on then
        check(e ~= nil, "craft: the one box is one pad stop (craft:actQty)")
        if e then
            st.qty = 1
            e.onActivate(WW(), e); local a = st.qty
            local r = e.onDpadDir(WW(), e, "right"); local b = st.qty
            local l = e.onDpadDir(WW(), e, "left"); local c = st.qty
            say(string.format("craft: A 1->%s, Right ->%s (%s), Left ->%s (%s), max %s", tostring(a), tostring(b), tostring(r), tostring(c), tostring(l), tostring(st._maxQty)))
            local max = st._maxQty or 99
            check((max <= 1) or (a == 2 and b == math.min(3, max) and c == b - 1), "craft: A steps up, Right up, Left down")
            st.qty = 1
        end
    else
        say("craft: the band has room here: the - n + keys (no single box)")
    end
    pcall(function() ZeD.CraftingCore.closeCraft(st) end)
end)
step(10, function() tab(WW(), "_actionTabStrip", "build") end)
step(40, function() shot("build_" .. TAG) end)
step(5, function() tab(WW(), "_actionTabStrip", "maps") end)
step(60, function() shot("maps_" .. TAG) end)
step(5, function() tab(WW(), "_actionTabStrip", "loot") end)
-- Equip list, Skills
step(5, function() ZeD.EquipDoll.setView("list"); tab(CW(), "_tabStripPanel", "equip") end)
step(40, function() shot("equip_" .. TAG) end)
step(5, function() tab(CW(), "_tabStripPanel", "skills") end)
step(40, function() shot("skills_" .. TAG) end)
-- Identity: natural, tall, wide; bust and full body; top and bottom
local function idShot(layout, expanded, bottom)
    step(5, function()
        ZeD.IdentityTab.qaLayout = layout
        CW()._identityPhotoExpanded = expanded
        tab(CW(), "_tabStripPanel", "identity")
    end)
    step(30, function()
        local sc = CW()._identityScroll
        if sc then pcall(function() sc:setScrollPos(bottom and 1 or 0) end) end
    end)
    step(30, function()
        local w = CW()
        local name = string.format("id_%s_%s_%s_%s", tostring(layout or "auto"), expanded and "full" or "bust", bottom and "bottom" or "top", TAG)
        local pr, v = w._idTallPhoto or w._identityPhotoRect, w._idView
        say(string.format("%s: drawn tall %s; photo %s; view %s", name, tostring(w._idTall),
            pr and pr.x and string.format("%d,%d %dx%d", pr.x, pr.y or 0, pr.w or 0, pr.h or 0) or "-",
            v and string.format("%d,%d %dx%d", v.x, v.y, v.w, v.h) or "-"))
        shot(name)
    end)
end
for _, lay in ipairs({ false, "tall", "wide" }) do
    for _, ex in ipairs({ false, true }) do
        idShot(lay or nil, ex, false)
        idShot(lay or nil, ex, true)
    end
end
step(5, function()
    ZeD.IdentityTab.qaLayout = nil; CW()._identityPhotoExpanded = false
    tab(CW(), "_tabStripPanel", "loot")
    if TEXT == "large" then ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, sizeWas) end
end)
step(20, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start " .. TEXT)
