-- ZeDUI/tools/qa/pp_close.lua  (Nov 23 2026, QA; tag pp_close): pop-up lists shut when they are not in use, Build's
-- fix/popclose (2624e9444, ZeD_Popups.lua). The director, Nov 23 2026: "Drop-down list selection boxes should disappear
-- if they aren't used. Too often they get stuck on the screen when something else is clicked on, another action is
-- started." Run after zedqa_prelude.lua and rt_kit.lua (pp_close.txt). grep "ZEDQA pp_close".
--
-- How: each list is opened by its own opener (the function its box's click runs) on its own tab, and the run waits until
-- the list has drawn and told ZeD.Popups (its key in openKeys()). Then each way out is fired through the path Build
-- hooked: ZeD.Popups.onPress(button, x, y) (what ZeD_MouseTick's per-frame sample calls; Mouse.setXY is not seen),
-- ZeD.Popups.onKey(key) (what OnKeyStartPressed calls), ISTimedActionQueue.add (the wrapped queue) and
-- ZeD.Popups.onPlayerUpdate (what OnPlayerUpdate calls). The list is opened again before each way.
-- Checks, for each list (one line per list per way, the details with openKeys() and lastWhy):
--   press      a left press in the world (a screen point outside both windows and the list) shuts it, lastWhy "press";
--              a left press inside the other window the same; a right press in the world the same
--   keep       its own keys (Up, Down, Enter, Esc) through onKey keep it, nothing shut by a key
--   key        a game key (E) through onKey shuts it, lastWhy "key"
--   action     a timed action queued for the player (a pencil moved into a school bag the run gave, or out of it; the
--              character does not move) shuts it, lastWhy "action"; the queue is cleared after
--   move       the walk rule told the player started moving (onPlayerUpdate with a stand-in that answers
--              isPlayerMoving true: a real walk would take the character off the strip) shuts it, lastWhy "move"
--   hidden     its tab changed (Equipment on the Character window, Loot on the World window) shuts it within a few
--              frames, lastWhy "hidden"; for the health exercise list and the craft Sort list also the window pair
--              shut (then opened again)
--   pick       a row picked through the list's own pick (the click's path on that row) shuts it, openCount() == 0
--   end        nothing left open: openCount() == 0 and the list's own open field off
--   lists      health exercise and health Treat (a scratch staged on the right hand, hg_injury's way, god mode off and
--              invincible on while it is there), Temperature view, Journal recipes Sort, Show and Category, Papers
--              Show, Loadouts filter (Loadouts and outfits turned on for it when off), Cooking dish, base and Sort (a
--              pot of water, bread, a bowl and vegetables given), Craft Sort, Show, Category and the Station select,
--              Build Sort, Show and Category, Mechanics Sort, Maps style, Foraging focus, and a ZeD_ContextList (two
--              QA rows): rule c only for it (action, key, keep keys, a walk start left to its own walk-off rule,
--              noMove), a row that keeps the list open queues an action and the list stays (firing), a pick
--   SKIP       the main menu lists (mm, palette): main menu only; the Tickets, Logs and Admin card pickers: the Server
--              and Admin tabs are multiplayer only; any list whose box is not there at this size or with what the
--              QA character has (no vehicle inspected, no station in reach, the map styles fitting as radio buttons)
--              says why
--   put back   the windows, their tabs and the Journal page as found; the hand as found; god mode and invincible;
--              the Loadouts option; no list open; no new Lua error
-- Puts back: the window pair open or shut and both windows' tabs as found, the Journal page, every list's pick (sort,
-- show, category, filter, exercise, Treat part, view, dish, base, style, focus) as found, the scratch taken off the right
-- hand (every flag and clock as found), god mode and invincible, the Loadouts and outfits option, the action queue
-- cleared, the context list closed, the windows' pointer hold let go; the pencil, the bag and the cooking things are
-- taken back by rt_kit at the end.
if not RT then print("ZEDQA pp_close ERR rt_kit.lua did not run first"); print("ZEDQA pp_close DONE"); return end
local Q = RT.make("pp_close")
Q.maxMs = 1320000                    -- (the runner gives this script 1500 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, held = {}, lists = {}, t0 = getTimestampMs() }
local Z = ZeD

S.RO = { readOnly = true }
S.HAND = "Hand_R"

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.Pp() return Z and Z.Popups or nil end
function S.fr() local P = S.Pp(); return (P and P._frame) or 0 end
function S.keys()
    local P, ks = S.Pp(), {}
    if P and P.openKeys then pcall(function() ks = P.openKeys() end) end
    return ks
end
function S.count()
    local P, n = S.Pp(), -1
    if P and P.openCount then pcall(function() n = P.openCount() end) end
    return n
end
function S.has(key) for _, k in ipairs(S.keys()) do if k == key then return true end end; return false end
function S.entry(key) local P = S.Pp(); if not (P and P._list) then return nil end; return P._list[key] end
-- every list ZeD.Popups holds is this one (a list let go a frame ago is gone first, so its late shut cannot set lastWhy)
function S.alone(key)
    local P = S.Pp()
    if not (P and P._list) then return true end
    for k in pairs(P._list) do if k ~= key then return false end end
    return true
end
function S.flag(L) local ok, v = pcall(L.isOpen, L); return ok and v == true end
function S.w(L)
    if L.win == "cw" then return RT.cw() end
    if L.win == "ww" then return RT.ww() end
    return nil
end
function S.mid(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end
function S.zoneBy(zones, id) for _, z in ipairs(zones or {}) do if z.id == id then return z end end; return nil end
function S.ccZone(st, ty) for _, z in ipairs((st and st.zones) or {}) do if z.type == ty then return z end end; return nil end
-- the row to pick: the one now chosen (a pick that changes nothing), else the first that can be picked
function S.zonePick(zones, want)
    for _, z in ipairs(zones or {}) do if want ~= nil and z.id == want and not z.disabled then return z end end
    for _, z in ipairs(zones or {}) do if not z.disabled then return z end end
    return nil
end
function S.clearQueue() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function S.bd() local b = nil; pcall(function() b = S.p:getBodyDamage() end); return b end
function S.part(name)
    local bd, t = S.bd(), BodyPartType[name]
    if not (bd and t) then return nil end
    local bp = nil
    pcall(function() bp = bd:getBodyPart(t) end)
    return bp
end
function S.detail(L, t)
    local P = S.Pp()
    local s = "keys [" .. table.concat(S.keys(), ",") .. "], lastWhy " .. tostring(P and P.lastWhy) .. ", lastClosed "
        .. tostring(P and P.lastClosed) .. ", own flag " .. tostring(S.flag(L))
    if t and t.at then s = s .. ", " .. tostring(t.at) end
    return s
end

-- ===================================================================== windows
function S.hold(w)
    if not w then return end
    for _, h in ipairs(S.held) do if h.w == w then return end end
    S.held[#S.held + 1] = { w = w, own = rawget(w, "pointerOn") }
    w.pointerOn = function() return true end
end
function S.unholdAll()
    for _, h in ipairs(S.held) do h.w.pointerOn = h.own end
    S.held = {}
end
function S.wrect(w)
    if not w then return nil end
    local r = nil
    pcall(function()
        if w:isReallyVisible() then r = { x = w:getAbsoluteX(), y = w:getAbsoluteY(), w = w:getWidth(), h = w:getHeight() } end
    end)
    return r
end
function S.inR(r, x, y) return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
function S.inList(key, x, y)
    local e = S.entry(key)
    if not e then return false end
    for i = 1, (e.n or 0) do if S.inR(e.rects[i], x, y) then return true end end
    return false
end
-- a screen point outside both windows and the list (the world)
function S.worldPt(L)
    local W, H = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    local a, b = S.wrect(RT.cw()), S.wrect(RT.ww())
    local pts = { { W * 0.5, H - 8 }, { 8, H - 8 }, { W - 8, H - 8 }, { W * 0.5, 8 }, { 8, 8 }, { W - 8, 8 }, { W * 0.5, H * 0.5 } }
    for _, pt in ipairs(pts) do
        local x, y = math.floor(pt[1]), math.floor(pt[2])
        if not S.inR(a, x, y) and not S.inR(b, x, y) and not S.inList(L.key, x, y) then return x, y end
    end
    return nil, nil
end
-- a point inside the other window, outside the list
function S.otherPt(L)
    local ow = nil
    if L.win == "cw" then ow = RT.ww() else ow = RT.cw() end
    local r = S.wrect(ow)
    if not r then return nil, nil end
    for _, f in ipairs({ 0.5, 0.25, 0.75 }) do
        local x, y = math.floor(r.x + r.w * f), math.floor(r.y + r.h * f)
        if not S.inList(L.key, x, y) then return x, y end
    end
    return nil, nil
end
function S.offered(L)
    local strip = nil
    if L.win == "cw" then strip = RT.charStrip() else strip = RT.worldStrip() end
    for _, id in ipairs(RT.tabs(strip)) do if id == L.tab then return true end end
    return false
end
-- the list's window open, on its tab (and Journal page), drawer open; pressed toward it at most every 20 frames
function S.onTab(L)
    if not L.win then return true end
    local w = S.w(L)
    local vis = false
    if w then pcall(function() vis = w:isReallyVisible() end) end
    if not vis then
        if S.fr() - (S.pairAt or -99) >= 30 then S.pairAt = S.fr(); RT.pairOpen() end
        return false
    end
    S.hold(w)
    if w._activeTab ~= L.tab or w._drawerOpen == false then
        if S.fr() - (L.goAt or -99) >= 20 then
            L.goAt = S.fr()
            if L.win == "cw" then RT.charTab(L.tab) else RT.worldTab(L.tab) end
        end
        return false
    end
    if L.page and w._journalSubTab ~= L.page then
        pcall(Z.JournalTab.setPage, w, L.page)
        return false
    end
    if L.readyCond then
        local ok, r = pcall(L.readyCond, L)
        if not (ok and r) then return false end
    end
    return true
end
-- why a list cannot be opened here (a SKIP), or nil
function S.why(L)
    if L.win and not S.offered(L) then return L.noTab or ("the " .. tostring(L.tab) .. " tab is not on the strip") end
    if L.whyNot then
        local ok, r = pcall(L.whyNot, L)
        if ok and type(r) == "string" then return r end
    end
    return nil
end
-- open the list again (its own opener) and wait until it drew and told ZeD.Popups, alone
function S.reopen(L)
    if not S.onTab(L) then return false end
    if S.flag(L) and S.has(L.key) and S.alone(L.key) then return true end
    if not S.flag(L) and S.fr() - (L.openAt or -99) >= 4 then
        L.openAt = S.fr()
        local P = S.Pp()
        -- (another list still open from before: shut, so this one is alone)
        if S.count() > 0 and not S.has(L.key) then pcall(P.closeAll, "pp_close") end
        local ok, err = pcall(L.open, L)
        if not ok then L.openErr = tostring(err) end
    end
    return false
end
function S.closedNow(L) return not S.flag(L) and S.count() == 0 and not S.has(L.key) end
function S.goneNow(L) return S.closedNow(L) and S.entry(L.key) == nil end

-- ===================================================================== the triggers
S.PADWHY = "player " .. tostring(RT.pn) .. " plays with a controller here: keys never shut a controller player's lists"
function S.padKeys()
    local P = S.Pp()
    local ok, v = pcall(P._padPlayer, S.pn)
    return ok and v == true
end
function S.press(L, t, button, other)
    local x, y
    if other then x, y = S.otherPt(L) else x, y = S.worldPt(L) end
    if not x then
        if other then return "the other window is not open" end
        return "no screen point outside both windows and the list"
    end
    t.at = "at " .. x .. "," .. y
    S.Pp().onPress(button, x, y)
    return nil
end
function S.keepKeys() return { Keyboard.KEY_UP, Keyboard.KEY_DOWN, Keyboard.KEY_RETURN, Keyboard.KEY_ESCAPE } end
-- the harmless timed action: the pencil moved into the run's bag, or out of it (the character stays put)
function S.queueAction(t)
    local it, bag, inv = S.pencil, S.bagInv, nil
    pcall(function() inv = S.p:getInventory() end)
    if not (it and inv and bag) then return "the pencil or the bag was not given" end
    local src = nil
    pcall(function() src = it:getContainer() end)
    if not src then return "the pencil is in no container" end
    local dst = bag
    if src == bag then dst = inv end
    local ok, err = pcall(function() ISTimedActionQueue.add(ISInventoryTransferAction:new(S.p, it, src, dst)) end)
    if not ok then t.fail = "the transfer could not be queued: " .. tostring(err); return nil end
    t.qd = true
    t.at = "the pencil " .. ((dst == bag) and "into the bag" or "out of the bag")
    return nil
end
-- the walk rule told a walk started: ZeD.Popups.onPlayerUpdate with a stand-in answering isPlayerMoving true (a real
-- walk would take the character off the strip); the walk state put back after
function S.walkStart(L, t)
    local P = S.Pp()
    local pn = S.pn
    P._moving = P._moving or {}
    local was = P._moving[pn]
    if was == true then return "the character is walking now: a start cannot be told" end
    local stand = { getPlayerNum = function() return pn end, isPlayerMoving = function() return true end }
    P.onPlayerUpdate(stand)
    P._moving[pn] = was
    t.at = "a walk start told to onPlayerUpdate"
    return nil
end
function S.leaveTab(L, t)
    local ok
    if L.win == "cw" then ok = RT.charTab("equip"); t.at = "to Equipment"
    else ok = RT.worldTab("loot"); t.at = "to Loot" end
    if not ok then return "the other tab is not on the strip" end
    return nil
end
function S.pickFire(L, t)
    local ok, r = pcall(L.pick, L)
    if not ok then t.fail = "the pick threw: " .. tostring(r); return nil end
    if type(r) == "string" then return r end
    t.picked = (r == true)
    if not t.picked then t.fail = "no row to pick; " .. S.detail(L, t) end
    return nil
end
function S.restoreL(L) if L.saved and L.restore then pcall(L.restore, L) end end

-- the ways out, in order (keep comes before key: the list kept open is used for the next way)
S.WAYS = {
    { id = "pressWorld", notCtx = true, why = "press", what = "a left press in the world shuts it (press)",
      fire = function(L, t) return S.press(L, t, 0, false) end },
    { id = "pressOther", notCtx = true, why = "press",
      fire = function(L, t) return S.press(L, t, 0, true) end },
    { id = "pressRight", notCtx = true, why = "press", what = "a right press in the world shuts it (press)",
      fire = function(L, t) return S.press(L, t, 1, false) end },
    { id = "keep", keep = true, what = "its own keys (Up, Down, Enter, Esc) keep it, nothing shut by a key",
      fire = function(L, t)
          if S.padKeys() then return S.PADWHY end
          for _, k in ipairs(S.keepKeys()) do S.Pp().onKey(k) end
          return nil
      end },
    { id = "key", why = "key", what = "a game key (E) shuts it (key)",
      fire = function(L, t)
          if S.padKeys() then return S.PADWHY end
          S.Pp().onKey(Keyboard.KEY_E)
          return nil
      end },
    { id = "action", why = "action", what = "a timed action queued for the player shuts it (action)",
      fire = function(L, t) return S.queueAction(t) end, after = function() S.clearQueue() end },
    { id = "keepOpen", ctxOnly = true, keepOpen = true,
      what = "a row that keeps the list open queues an action and the list stays (firing)",
      fire = function(L, t) return S.ctxKeepRow(t) end, after = function() S.clearQueue() end },
    { id = "move", why = "move", what = "a walk start shuts it (move)",
      ctxWhat = "a walk start leaves it to its own walk-off rule (noMove)",
      fire = function(L, t) return S.walkStart(L, t) end },
    { id = "tab", notCtx = true, wait = true, why = "hidden", what = "its tab changed shuts it (hidden)",
      fire = function(L, t) return S.leaveTab(L, t) end },
    { id = "pair", notCtx = true, only = "pairHide", wait = true, why = "hidden", what = "the windows shut shut it (hidden)",
      fire = function(L, t) RT.pairShut(); t.at = "the window pair shut"; return nil end,
      after = function() RT.pairOpen() end },
    { id = "pick", pick = true, what = "a pick through its own rows shuts it, openCount() == 0",
      fire = function(L, t) return S.pickFire(L, t) end, after = function(L) S.restoreL(L) end },
}
function S.whatOf(L, wy)
    if L.ctx and wy.ctxWhat then return wy.ctxWhat end
    if wy.id == "pressOther" then
        return "a left press in the " .. ((L.win == "cw") and "World" or "Character") .. " window shuts it (press)"
    end
    return wy.what
end

-- ===================================================================== one list, every way
function S.wayCheck(L, wy, t)
    local P = S.Pp()
    local what = L.name .. ": " .. S.whatOf(L, wy)
    local d = S.detail(L, t)
    if wy.keepOpen then
        Q.check(S.flag(L) and S.has(L.key) and P.lastWhy == nil and S.ctxKeepFired == true and t.qd == true, what,
            d .. ", the row fired " .. tostring(S.ctxKeepFired) .. ", queued " .. tostring(t.qd))
    elseif wy.keep then
        Q.check(S.flag(L) and S.has(L.key) and P.lastWhy ~= "key", what, d)
    elseif L.ctx and wy.id == "move" then
        Q.check(S.flag(L) and S.has(L.key) and P.lastWhy ~= "move", what, d)
    elseif wy.pick then
        Q.check(t.picked == true and not S.flag(L) and S.count() == 0, what, d)
    elseif wy.why == "hidden" then
        -- (Build, fix/popnotes: a list its owner shut itself, as the window does on a tab change, leaves lastWhy as it
        -- was; either way the list must be shut with nothing left)
        Q.check(S.closedNow(L) and ((P.lastWhy == "hidden" and P.lastClosed == L.key) or P.lastClosed ~= L.key), what, d)
    else
        Q.check(S.closedNow(L) and P.lastWhy == wy.why and P.lastClosed == L.key, what, d)
    end
    if wy.after then pcall(wy.after, L, t) end
end
function S.wayStart(L, wy, t, ok)
    local what = L.name .. ": " .. S.whatOf(L, wy)
    if L.ctx and wy.notCtx then
        if not L.ctxSkipSaid then
            L.ctxSkipSaid = true
            Q.skip(L.name .. ": a press outside, a tab changed or the windows shut",
                "ZeD_ContextList shuts itself on a press outside and when hidden (selfClosing): ZeD.Popups leaves those to it")
        end
        return false
    end
    if not ok then
        local why = S.why(L)
        L.skip = why or "it did not open"
        if why then Q.skip(L.name, why)
        else
            Q.check(false, what, "it did not open and draw in 150 frames; " .. S.detail(L, t)
                .. (L.openErr and (", the opener threw " .. L.openErr) or ""))
        end
        return false
    end
    local P = S.Pp()
    P.lastWhy, P.lastClosed = nil, nil
    local okF, r = pcall(wy.fire, L, t)
    if not okF then Q.check(false, what, "the trigger threw: " .. tostring(r)); return false end
    if type(r) == "string" then Q.skip(what, r); return false end
    if t.fail then Q.check(false, what, t.fail); if wy.after then pcall(wy.after, L, t) end; return false end
    if wy.wait then return true end
    S.wayCheck(L, wy, t)
    return false
end
function S.buildWay(L, wy)
    if wy.only and not L[wy.only] then return end
    if wy.ctxOnly and not L.ctx then return end
    local t = {}
    Q.waitFor(1, 150, function()
        return L.skip ~= nil or S.dead or (L.ctx and wy.notCtx) or S.reopen(L)
    end, function(ok)
        if L.skip or S.dead then return end
        t.go = S.wayStart(L, wy, t, ok)
    end)
    if wy.wait then
        Q.waitFor(1, 40, function() return not t.go or S.goneNow(L) end, function()
            if t.go then S.wayCheck(L, wy, t) end
        end)
    end
end
function S.endList(L)
    if L.ran then
        Q.check(S.count() == 0 and not S.flag(L), L.name .. ": nothing left open at the end (openCount() == 0, its own flag off)",
            S.detail(L, nil))
        if S.flag(L) and L.close then pcall(L.close, L) end
        local P = S.Pp()
        if S.count() > 0 then pcall(P.closeAll, "pp_close") end
    end
    S.restoreL(L)
    if L.after then
        local ok, err = pcall(L.after, L)
        if not ok then Q.check(false, L.name .. ": its staging put back", tostring(err)) end
    end
end
function S.buildList(L)
    S.lists[#S.lists + 1] = L
    Q.step(2, function()
        if S.dead then L.skip = "ZeD.Popups is not loaded"; return end
        if L.prep then
            local ok, why = pcall(L.prep, L)
            if not ok then L.skip = "its staging threw: " .. tostring(why); L.prepFailed = true
            elseif type(why) == "string" then L.skip = why end
        end
    end)
    Q.waitFor(1, L.readyMax or 300, function() return L.skip ~= nil or S.onTab(L) end, function(ok)
        if S.dead then return end
        if L.skip then
            if L.prepFailed then Q.check(false, L.name .. ": staged", L.skip) else Q.skip(L.name, L.skip) end
            return
        end
        if not ok then
            local why = S.why(L)
            L.skip = why or "its tab did not come up"
            if why then Q.skip(L.name, why)
            else
                local w = S.w(L)
                Q.check(false, L.name .. ": its tab (" .. tostring(L.tab) .. ") comes up", "on " .. tostring(w and w._activeTab)
                    .. ", page " .. tostring(w and w._journalSubTab))
            end
            return
        end
        L.ran = true
        if L.save then pcall(L.save, L); L.saved = true end
    end)
    for _, wy in ipairs(S.WAYS) do S.buildWay(L, wy) end
    Q.step(1, function() S.endList(L) end)
    -- (the list let go: its entry gone before the next list starts)
    Q.waitFor(1, 10, function() return S.entry(L.key) == nil end, function() end)
end

-- ===================================================================== the lists
-- Health: the exercise list (no wound listed) and the Treat list (a part to treat), key "health:<pn>"
function S.healthSpec(kind)
    local L = { name = "health " .. kind, win = "cw", tab = "health", key = "health:" .. S.pn, pairHide = (kind == "exercise") }
    L.isOpen = function() local w = RT.cw(); return w ~= nil and w._healthMenuOpen == true end
    L.open = function() local w = RT.cw(); if w and w._healthFooterMode == kind then Z.HealthTab.openMenu(w) end end
    L.close = function() local w = RT.cw(); if w then Z.HealthTab.closeMenu(w) end end
    L.readyCond = function() local w = RT.cw(); return w ~= nil and w._healthFooterMode == kind end
    L.whyNot = function()
        local w = RT.cw()
        local m = w and w._healthFooterMode
        if m == kind then return nil end
        if kind == "exercise" then return "a wound is listed: the footer is Treat, not the exercise's" end
        return "the footer did not turn to Treat with a scratch on the right hand (footer " .. tostring(m) .. ")"
    end
    L.save = function() local w = RT.cw(); if w then L.was = { ex = w._healthExerciseSel, tr = w._healthTreatSel } end end
    L.restore = function() local w = RT.cw(); if w and L.was then w._healthExerciseSel, w._healthTreatSel = L.was.ex, L.was.tr end end
    L.pick = function()
        local w = RT.cw()
        if not w then return false end
        local want = nil
        if kind == "treat" then
            local r = Z.HealthTab.selectedTreatPart(w)
            want = r and r.name or nil
        else
            want = Z.HealthTab.selectedExercise(w)
        end
        local z = S.zonePick(w._healthMenuZones, want)
        if not z then return false end
        local x, y = S.mid(z)
        Z.HealthTab.onClick(w, x, y)
        return true
    end
    if kind == "treat" then
        L.prep = function() return S.stage() end
        L.after = function() S.unstage(true) end
    end
    return L
end
-- Temperature's View list, key "thermal:<pn>"
function S.thermalSpec()
    local L = { name = "temperature view", win = "cw", tab = "thermal", key = "thermal:" .. S.pn }
    L.isOpen = function() local w = RT.cw(); return w ~= nil and w._thermalMenuOpen == true end
    L.open = function() local w = RT.cw(); if w then Z.ThermalTab.openMenu(w) end end
    L.close = function() local w = RT.cw(); if w then Z.ThermalTab.closeMenu(w) end end
    L.whyNot = function() local w = RT.cw(); if not (w and w._thermalBand) then return "the Temperature tab drew no band" end; return nil end
    L.save = function() local w = RT.cw(); if w then L.was = w._thermalView end end
    L.restore = function() local w = RT.cw(); if w then w._thermalView = L.was end end
    L.pick = function()
        local w = RT.cw()
        if not w then return false end
        local z = S.zonePick(w._thermalMenuZones, w._thermalView or 1)
        if not z then return false end
        local x, y = S.mid(z)
        Z.ThermalTab.onClick(w, x, y)
        return true
    end
    return L
end
-- CraftingCore's band lists (Journal recipes, Craft, Build), keys "<prefix>:sort|show|cat:<pn>"
S.CCK = { sort = { open = "sortMenuOpen", zones = "_sortMenuZones", geo = "_sortMenuGeo", word = "Sort" },
          show = { open = "showMenuOpen", zones = "_showMenuZones", geo = "_showMenuGeo", word = "Show" },
          cat = { open = "catDropdownOpen", word = "Category" } }
function S.ccSpec(base, win, tab, page, field, prefix, kind, click, readOnly)
    local K = S.CCK[kind]
    local L = { name = base .. " " .. kind, win = win, tab = tab, page = page, key = prefix .. ":" .. kind .. ":" .. S.pn }
    L.st = function() local w = S.w(L); return w and w[field] end
    L.isOpen = function() local st = L.st(); return st ~= nil and st[K.open] == true end
    L.open = function()
        local st, w = L.st(), S.w(L)
        if not (st and w) then return end
        if kind == "cat" then
            local z = S.ccZone(st, "catDropdown")
            if z then
                local x, y = S.mid(z)
                click(w, x, y)
            end
        else
            Z.CraftingCore.openPopMenu(st, kind)
        end
    end
    L.close = function()
        local st = L.st()
        if not st then return end
        if kind == "cat" then Z.CraftingCore.closeCatDropdown(st) else Z.CraftingCore.closePopMenu(st, kind) end
    end
    L.whyNot = function()
        local st = L.st()
        if prefix == "craft" and Z.Stations and Z.Stations.current and Z.Stations.current(S.p) then
            return "a station is bound: the Craft tab shows its own view"
        end
        if not st then return "the tab's recipe state is not made" end
        if kind == "cat" and not S.ccZone(st, "catDropdown") then return "no Category select on the page at this size" end
        if kind ~= "cat" and not st[K.geo] then return "no " .. K.word .. " box in the band at this size" end
        return nil
    end
    L.pick = function()
        local st, w = L.st(), S.w(L)
        if not (st and w) then return false end
        if kind == "cat" then
            local g = st._ddGeo
            if not (g and g.x and g.y) then return false end
            click(w, g.x + 2, g.y + 2)   -- (the first category row)
            return true
        end
        local want
        if kind == "sort" then want = Z.CraftingCore.sortOf(st) else want = Z.CraftingCore.showMode(st, readOnly and S.RO or nil) end
        local z = S.zonePick(st[K.zones], want)
        if not z then return false end
        local x, y = S.mid(z)
        click(w, x, y)
        return true
    end
    L.save = function()
        local st = L.st()
        if st then L.was = { sort = st.sort, show = st.show, showAll = st.showAll, activeCat = st.activeCat } end
    end
    L.restore = function()
        local st, v = L.st(), L.was
        if not (st and v) then return end
        st.sort, st.show, st.showAll, st.activeCat = v.sort, v.show, v.showAll, v.activeCat
        st.filterDirty = true
    end
    return L
end
function S.clickJR(w, x, y) return Z.JournalTab.onRecipeClick(w, x, y) end
function S.clickCraft(w, x, y) return Z.CraftingTab.onClick(w, x, y) end
function S.clickBuild(w, x, y) return Z.BuildingTab.onClick(w, x, y) end
-- the Craft tab's Station select, key "station:<pn>"
function S.stationSpec()
    local L = { name = "craft station", win = "ww", tab = "craft", key = "station:" .. S.pn }
    L.st = function() local w = RT.ww(); return w and w._craftState end
    L.isOpen = function() local st = L.st(); return st ~= nil and st.stDropdownOpen == true end
    L.open = function()
        local st, w = L.st(), RT.ww()
        local z = S.ccZone(st, "stationDropdown")
        if w and z then
            local x, y = S.mid(z)
            S.clickCraft(w, x, y)
        end
    end
    L.close = function() local st = L.st(); if st then Z.Stations.closeDropdown(st) end end
    L.whyNot = function()
        if not S.ccZone(L.st(), "stationDropdown") then return "no station in reach of the QA character (the Station select shows only near one)" end
        return nil
    end
    L.pick = function()
        local st = L.st()
        if not st then return false end
        if Z.Stations.current(S.p) then return "a station is bound: a pick would change what the Craft tab shows" end
        for _, l in ipairs(st._stLayout or {}) do
            if l.row and l.row.kind ~= "hdr" and l.row.kind ~= "station" then
                Z.Stations.pickRow(st, S.p, l.row)
                return true
            end
        end
        return false
    end
    L.save = function() local st = L.st(); if st then L.was = st.activeCat end end
    L.restore = function() local st = L.st(); if st and L.was ~= nil then st.activeCat = L.was; st.filterDirty = true end end
    return L
end
-- the Journal pages' band lists (Papers Show, Loadouts filter): opened and picked by their zones' own functions
function S.bandSpec(name, page, stField, zField, openField, boxId, rowPre, slot, shut)
    local L = { name = name, win = "cw", tab = "journal", page = page, key = slot .. ":" .. S.pn }
    L.st = function() local w = RT.cw(); return w and w[stField] end
    L.zones = function() local w = RT.cw(); return (w and w[zField]) or {} end
    L.isOpen = function() local s = L.st(); return s ~= nil and s[openField] == true end
    L.open = function() local z = S.zoneBy(L.zones(), boxId); if z and z.fn then z.fn() end end
    L.close = function() local w = RT.cw(); if w then shut(w) end end
    L.whyNot = function()
        if not S.zoneBy(L.zones(), boxId) then return "no " .. boxId .. " box in the page's band (a paper or a question holds it)" end
        return nil
    end
    L.pick = function()
        local s = L.st()
        local z = S.zoneBy(L.zones(), rowPre .. tostring(s and s.filter))
        if not z then
            for _, q in ipairs(L.zones()) do
                if type(q.id) == "string" and string.sub(q.id, 1, #rowPre) == rowPre then z = q; break end
            end
        end
        if not (z and z.fn) then return false end
        z.fn()
        return true
    end
    L.save = function() local s = L.st(); if s then L.was = s.filter end end
    L.restore = function() local s = L.st(); if s and L.was ~= nil then s.filter = L.was end end
    return L
end
-- Cooking's three lists (dish, base, sort), key "cook:<which>:<pn>"
function S.cookSpec(which)
    local L = { name = "cooking " .. which, win = "cw", tab = "cooking", key = "cook:" .. which .. ":" .. S.pn, readyMax = 600,
                noTab = "the Cooking tab did not show with a pot of water, bread, a bowl and vegetables carried" }
    L.st = function() local w = RT.cw(); return w and w._cook end
    L.box = function() local s = L.st(); return s and s.byId and s.byId["cook:" .. which] end
    L.isOpen = function() local s = L.st(); return s ~= nil and s.popup == which end
    L.open = function() local s, z = L.st(), L.box(); if s and z and z.fn and s.popup ~= which then z.fn() end end
    L.close = function() local s = L.st(); if s then Z.CookingTab.closePopup(s) end end
    L.whyNot = function()
        local s = L.st()
        if not s then return "the Cooking tab was not drawn" end
        if not L.box() then return "no " .. which .. " box on the Cooking tab with what is carried" end
        local g = s[which .. "Geo"]
        if not (g and g.modes and #g.modes > 0) then return "the " .. which .. " list has no rows with what is carried" end
        return nil
    end
    L.pick = function()
        local s = L.st()
        local g = s and s[which .. "Geo"]
        if not (g and s.byId) then return false end
        local z = s.byId["cook:pop:" .. tostring(g.cur)]
        if not z or z.disabled then
            z = nil
            for _, q in ipairs(s.zones or {}) do if q.popRow and not q.disabled then z = q; break end end
        end
        if not (z and z.fn) then return false end
        z.fn()
        return true
    end
    L.save = function()
        local s = L.st()
        if s then L.was = { dish = s.dish, baseIdx = s.baseIdx, plan = s.plan, qty = s.qty, ingCache = s.ingCache, sort = s.sort,
                            listScroll = s.listScroll } end
    end
    L.restore = function()
        local s, v = L.st(), L.was
        if not (s and v) then return end
        s.dish, s.baseIdx, s.plan, s.qty, s.ingCache, s.sort, s.listScroll = v.dish, v.baseIdx, v.plan, v.qty, v.ingCache, v.sort, v.listScroll
    end
    if which == "dish" then L.prep = function() return S.cookStage() end end
    return L
end
-- Mechanics' Sort list (an inspected vehicle only), key "mech:sort:<pn>"
function S.mechSpec()
    local L = { name = "mechanics sort", win = "ww", tab = "vehicle", key = "mech:sort:" .. S.pn,
                noTab = "no vehicle in reach of the QA character (the Vehicle tab shows only near one)" }
    L.st = function() local w = RT.ww(); return w and w._mech end
    L.box = function() local s = L.st(); return s and s.byId and s.byId["mech:sortMenu"] end
    L.isOpen = function() local s = L.st(); return s ~= nil and s.sortOpen == true end
    L.open = function() local s, z = L.st(), L.box(); if s and z and z.fn and not s.sortOpen then z.fn() end end
    L.close = function() local s = L.st(); if s then Z.MechanicsTab.closeSort(s) end end
    L.whyNot = function()
        if not L.box() then return "the vehicle in reach is not inspected: Sort shows on an inspected vehicle only" end
        return nil
    end
    L.pick = function()
        local s = L.st()
        if not (s and s.byId) then return false end
        local z = s.byId["mech:sortRow:" .. tostring(s.sort)]
        if not z or z.disabled then
            z = nil
            for _, q in ipairs(s.zones or {}) do if q.sortRow and not q.disabled then z = q; break end end
        end
        if not (z and z.fn) then return false end
        z.fn()
        return true
    end
    L.save = function() local s = L.st(); if s then L.was = { sort = s.sort, scrollY = s.scrollY } end end
    L.restore = function() local s, v = L.st(), L.was; if s and v then s.sort, s.scrollY = v.sort, v.scrollY end end
    return L
end
-- Maps' style list (only when the choices do not fit as radio buttons), key "maps:style:<pn>"
function S.mapsSpec()
    local L = { name = "maps style", win = "ww", tab = "maps", key = "maps:style:" .. S.pn }
    L.isOpen = function() local w = RT.ww(); return w ~= nil and w._mapStyleMenuOpen == true end
    L.open = function()
        local w = RT.ww()
        local z = w and w._mapStyleMenuZone
        if z then
            local x, y = S.mid(z)
            Z.MapsTab.onClick(w, x, y)
        end
    end
    L.close = function() local w = RT.ww(); if w then Z.MapsTab.closeStyleMenu(w) end end
    L.whyNot = function()
        local w = RT.ww()
        if not w then return "no World window" end
        if w._mapBlocked then return "no map here or too dark to read it" end
        if w._mapPaperItem then return "a paper map is open: it has no style choice" end
        if w._mapStyleMenuZone == nil and #(w._mapStyleZones or {}) > 0 then
            return "the style choices fit as radio buttons at this width: there is no list"
        end
        if w._mapStyleMenuZone == nil then return "no style box (the paper style is not made here)" end
        return nil
    end
    L.style = function() local w = RT.ww(); local mp = w and w._worldMapPanel; return mp and mp.style end
    L.pick = function()
        local w = RT.ww()
        if not w then return false end
        local z = S.zonePick(w._mapStyleMenuZones, L.style() or "survey")
        if not z then return false end
        local x, y = S.mid(z)
        Z.MapsTab.onClick(w, x, y)
        return true
    end
    L.save = function() L.was = L.style() end
    L.restore = function()
        local w = RT.ww()
        if w and L.was and L.style() ~= L.was then pcall(Z.MapsTab.setStyle, w, L.was) end
    end
    return L
end
-- Foraging's focus select (a ZeD_Dropdown, popKey "forage:focus"), key "forage:focus:<pn>"
function S.forageSpec()
    local L = { name = "foraging focus", win = "ww", tab = "forage", key = "forage:focus:" .. S.pn }
    L.dd = function() local w = RT.ww(); return w and w._forageDropdown end
    L.isOpen = function() local dd = L.dd(); return dd ~= nil and dd.isOpen == true end
    L.open = function() local dd = L.dd(); if dd and not dd.isOpen then dd:onMouseDown(2, 2) end end
    L.close = function() local dd = L.dd(); if dd then dd:onOtherBodyClick() end end
    L.whyNot = function()
        local dd = L.dd()
        if not dd then return "the Foraging tab made no focus select" end
        if dd.disabled then return "the focus select is off" end
        return nil
    end
    L.pick = function()
        local dd = L.dd()
        if not (dd and dd.isOpen) then return false end
        local idx = 1
        for i, o in ipairs(dd.options or {}) do if o.id == dd.selectedId then idx = i end end
        local vis = idx - (dd.scrollOffset or 0)
        if vis < 1 then vis = 1 end
        dd:onMouseDown(2, Z.T.inputH + Z.T.rowH * (vis - 1) + 1)
        return true
    end
    L.save = function() local dd = L.dd(); if dd then L.was = dd.selectedId; L.saved0 = true end end
    L.restore = function()
        local dd = L.dd()
        if dd and L.saved0 and dd.selectedId ~= L.was then
            dd.selectedId = L.was
            if dd.onChange then pcall(dd.onChange, dd, L.was) end
        end
    end
    return L
end
-- a ZeD_ContextList with two QA rows (rule c only: selfClosing, noMove), key "ctx:<pn>"
function S.ctxSpec()
    local L = { name = "context list", ctx = true, key = "ctx:" .. S.pn }
    S.ctxRows = {
        { name = "QA: a row that keeps the list open", keepOpen = true,
          onFire = function() S.ctxKeepFired = true; S.queueAction(S.ctxT or {}) end },
        { name = "QA: a row that picks", onFire = function() S.ctxFired = true end },
    }
    L.isOpen = function() local m = S.ctxM; return m ~= nil and m._ctx ~= nil and m._ctx.open == true end
    L.open = function()
        local W, H = RT.core:getScreenWidth(), RT.core:getScreenHeight()
        local m = ZeD_ContextList:new(S.pn, "cursor", math.floor(W * 0.5) + 60, math.floor(H * 0.5) - 120, nil, S.ctxRows, nil)
        m.noHead = true
        m:initialise()
        m:open()
        S.ctxM = m
    end
    L.close = function() S.ctxShut() end
    L.whyNot = function() if not ZeD_ContextList then return "ZeD_ContextList is not loaded" end; return nil end
    L.pick = function()
        local m = S.ctxM
        local lv = m and m._levels and m._levels[1]
        if not lv then return false end
        S.ctxFired = false
        lv.sel = 2
        m:confirm(1)
        return S.ctxFired == true
    end
    return L
end
function S.ctxKeepRow(t)
    local m = S.ctxM
    local lv = m and m._levels and m._levels[1]
    if not lv then t.fail = "the context list has no level"; return nil end
    S.ctxKeepFired, S.ctxT = false, t
    lv.sel = 1
    m:confirm(1)
    S.ctxT = nil
    t.at = "the row fired through ZeD.Popups.firing"
    return nil
end
function S.ctxShut()
    local m = S.ctxM
    if m and m._ctx and m._ctx.open then pcall(function() m:close() end) end
end

-- ===================================================================== staging
-- (hg_injury's and hg_treat's read and put-back of a body part)
S.GETS = { { "scratched", "scratched" }, { "scratchTime", "getScratchTime" }, { "cut", "isCut" }, { "cutTime", "getCutTime" },
           { "bleeding", "bleeding" }, { "bleedingTime", "getBleedingTime" }, { "deep", "deepWounded" },
           { "deepTime", "getDeepWoundTime" }, { "glass", "haveGlass" }, { "bullet", "haveBullet" },
           { "bandaged", "bandaged" }, { "bandageLife", "getBandageLife" }, { "bandageType", "getBandageType" },
           { "splint", "isSplint" }, { "splintFactor", "getSplintFactor" }, { "splintItem", "getSplintItem" },
           { "fractureTime", "getFractureTime" }, { "stitched", "stitched" }, { "stitchTime", "getStitchTime" },
           { "infectedWound", "isInfectedWound" }, { "woundInfection", "getWoundInfectionLevel" },
           { "burnTime", "getBurnTime" }, { "burnWash", "isNeedBurnWash" }, { "lastBurnWash", "getLastTimeBurnWash" },
           { "alcohol", "getAlcoholLevel" }, { "plantain", "getPlantainFactor" }, { "comfrey", "getComfreyFactor" },
           { "garlic", "getGarlicFactor" }, { "health", "getHealth" }, { "stiffness", "getStiffness" },
           { "addPain", "getAdditionalPain" }, { "bitten", "bitten" }, { "biteTime", "getBiteTime" },
           { "infected", "IsInfected" } }
S.SETS = { { "setScratchTime", "scratchTime" }, { "setCutTime", "cutTime" }, { "setDeepWoundTime", "deepTime" },
           { "setBleedingTime", "bleedingTime" }, { "setStitchTime", "stitchTime" }, { "setSplintFactor", "splintFactor" },
           { "setFractureTime", "fractureTime" }, { "setBandageLife", "bandageLife" },
           { "setWoundInfectionLevel", "woundInfection" }, { "setBurnTime", "burnTime" },
           { "setLastTimeBurnWash", "lastBurnWash" }, { "setAlcoholLevel", "alcohol" }, { "setPlantainFactor", "plantain" },
           { "setComfreyFactor", "comfrey" }, { "setGarlicFactor", "garlic" }, { "setBiteTime", "biteTime" },
           { "setStiffness", "stiffness" }, { "setAdditionalPain", "addPain" }, { "SetHealth", "health" } }
function S.snap(bp)
    local f = {}
    if not bp then return f end
    for _, g in ipairs(S.GETS) do
        local m = g[2]
        pcall(function() f[g[1]] = bp[m](bp) end)
    end
    return f
end
function S.snapDiff(a, b)
    local diff = {}
    for _, g in ipairs(S.GETS) do
        local k = g[1]
        local x, y = a[k], b[k]
        local same
        if type(x) == "number" and type(y) == "number" then same = math.abs(x - y) < ((k == "health") and 0.5 or 0.01)
        elseif k == "bandageType" and not a.bandaged and not b.bandaged then same = true
        elseif k == "bandageType" or k == "splintItem" then same = tostring(x or "") == tostring(y or "")
        else same = (x == y) end
        if not same then diff[#diff + 1] = k .. " " .. tostring(y) .. " (was " .. tostring(x) .. ")" end
    end
    return diff
end
function S.restore(bp, f)
    if not (bp and f) then return end
    local yes = false
    pcall(function() yes = bp:haveBullet() end)
    if yes then pcall(function() bp:setHaveBullet(false, 0) end) end
    yes = false
    pcall(function() yes = bp:bandaged() end)
    if yes then pcall(function() bp:setBandaged(false, 0) end) end
    yes = false
    pcall(function() yes = bp:bitten() end)
    if yes and not f.bitten then
        pcall(function() bp:SetBitten(false) end)
        pcall(function() bp:SetInfected(false) end)
        pcall(function() bp:SetFakeInfected(false) end)
    end
    pcall(function() bp:setStitched(false) end)
    pcall(function() bp:setSplint(false, 0) end)
    pcall(function() bp:setDeepWounded(false) end)
    pcall(function() bp:setHaveGlass(false) end)
    pcall(function() bp:setScratched(false, true) end)
    pcall(function() bp:setCut(false) end)
    pcall(function() bp:setBleeding(false) end)
    pcall(function() bp:setInfectedWound(false) end)
    pcall(function() bp:setNeedBurnWash(false) end)
    if not f.infected then pcall(function() bp:SetInfected(false) end) end
    if f.scratched then pcall(function() bp:setScratched(true, true) end) end
    if f.cut then pcall(function() bp:setCut(true) end) end
    if f.deep then pcall(function() bp:setDeepWounded(true) end) end
    if f.glass then pcall(function() bp:setHaveGlass(true) end) end
    if f.bullet then pcall(function() bp:setHaveBullet(true, 0) end) end
    if f.bitten then pcall(function() bp:SetBitten(true) end) end
    if f.bleeding then pcall(function() bp:setBleeding(true) end) end
    if f.stitched then pcall(function() bp:setStitched(true) end) end
    if f.splint then pcall(function() bp:setSplint(true, f.splintFactor or 0) end) end
    pcall(function() bp:setSplintItem(f.splintItem) end)
    if f.infectedWound then pcall(function() bp:setInfectedWound(true) end) end
    if f.burnWash then pcall(function() bp:setNeedBurnWash(true) end) end
    if f.bandaged then pcall(function() S.bd():SetBandaged(bp:getIndex(), true, f.bandageLife or 0, false, f.bandageType) end) end
    for _, s in ipairs(S.SETS) do
        local v, m = f[s[2]], s[1]
        if type(v) == "number" then pcall(function() bp[m](bp, v) end) end
    end
end
function S.noInfection(bd)
    if not bd then return end
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:IsInfected() then b:SetInfected(false) end
        if b:IsFakeInfected() then b:SetFakeInfected(false) end
    end
    if bd:isInfected() then bd:setInfected(false) end
    if bd:isIsFakeInfected() then bd:setIsFakeInfected(false) end
    local st = S.p:getStats()
    if st:get(CharacterStat.ZOMBIE_INFECTION) > 0 then st:set(CharacterStat.ZOMBIE_INFECTION, 0) end
    if st:get(CharacterStat.ZOMBIE_FEVER) > 0 then st:set(CharacterStat.ZOMBIE_FEVER, 0) end
    if bd:getInfectionTime() >= 0 then bd:setInfectionTime(-1) end
    if bd:getInfectionMortalityDuration() >= 0 then bd:setInfectionMortalityDuration(-1) end
end
-- while the scratch is on (god mode off, it would heal it at once): no zombie infection, health topped up
function S.safety()
    if not S.staged then return end
    pcall(function()
        local bd = S.bd()
        if not bd then return end
        if S.found.zInf == false then S.noInfection(bd) end
        if bd:getOverallBodyHealth() < 75 then
            local parts = bd:getBodyParts()
            for i = 0, parts:size() - 1 do parts:get(i):SetHealth(100) end
        end
    end)
end
-- the Treat list's wound: a scratch on the right hand (hg_injury's), god mode off, invincible on. A wound already
-- listed (the footer already Treat) is used as it is.
function S.stage()
    local w = RT.cw()
    if w and w._healthFooterMode == "treat" then S.stagedNote = "a wound was already listed: used as it is"; return nil end
    local bp = S.part(S.HAND)
    if not bp then return "the right hand could not be read" end
    S.found.hand = S.snap(bp)
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    S.staged = true
    pcall(function() bp:setScratched(true, false); bp:setScratchTime(19) end)
    local yes = false
    pcall(function() yes = bp:scratched() end)
    if not yes then return "the scratch did not take" end
    return nil
end
function S.unstage(say)
    if not S.staged then return end
    S.staged = false
    local f = S.found
    local bp = S.part(S.HAND)
    S.restore(bp, f.hand)
    pcall(function() S.p:setGodMod(f.god and true or false) end)
    if f.inv ~= nil then pcall(function() S.p:setInvincible(f.inv) end) end
    local d = S.snapDiff(f.hand or {}, S.snap(bp))
    S.handDiff = d
    if say then
        Q.check(#d == 0, "health treat: the scratch taken off, the right hand exactly as found", #d == 0 and "every flag and clock" or table.concat(d, "; "))
    end
end
-- Loadouts and outfits on for the Loadouts page (off for a new player), put back after
function S.loadOpt()
    local o = nil
    pcall(function()
        local zo = PZAPI.ModOptions:getOptions("ZeD_UI")
        o = zo and zo.dict and zo.dict.loadouts
    end)
    return o
end
function S.loadOn()
    local o = S.loadOpt()
    if not o then return "the Loadouts and outfits option could not be read" end
    if S.found.loadSel == nil then S.found.loadSel = o.selected end
    if o.selected ~= 2 then o.selected = 2 end
    if not (Z.Lists and Z.Lists.on and Z.Lists.on()) then return "Loadouts and outfits could not be turned on for the run" end
    return nil
end
function S.loadOff()
    local o = S.loadOpt()
    if o and S.found.loadSel ~= nil then o.selected = S.found.loadSel end
end
-- the cooking things (bx_cook's): a pot of water, bread slices, a bowl, carrots and a tomato; the tab looks again at once
function S.cookStage()
    S.pot = RT.give("Base.Pot")
    if S.pot then pcall(function() local fc = S.pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
    for _, ft in ipairs({ "Base.BreadSlices", "Base.Bowl", "Base.Carrots", "Base.Tomato", "Base.Potato" }) do RT.give(ft) end
    local w = RT.cw()
    local s = w and w._cook
    if s then s.scanAt, s.visAt, s.ingCache = -1, nil, nil end
    if not S.pot then return "the pot could not be given" end
    return nil
end

-- ===================================================================== the run
function S.start()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "pp_close") end
    S.err0 = S.errN()
    local P = S.Pp()
    local ready = P ~= nil and P.openCount ~= nil and P.openKeys ~= nil and P.closeAll ~= nil and P.onPress ~= nil
        and P.onKey ~= nil and P.onPlayerUpdate ~= nil and P._list ~= nil and P._padPlayer ~= nil
    if not Q.check(ready, "ZeD.Popups is loaded (openCount, openKeys, closeAll, onPress, onKey, onPlayerUpdate)") then
        S.dead = true
        return
    end
    Q.check(ISTimedActionQueue ~= nil and ISTimedActionQueue._zedPopups == true,
        "the game's action queue tells ZeD.Popups (ISTimedActionQueue.add wrapped once)")
    local n = 0
    pcall(function() n = #Z.MouseTick._listeners end)
    Q.check(n >= 1, "ZeD_MouseTick tells its listeners of each press (ZeD.Popups listens)", n .. " listeners")
    local f = S.found
    f.pair = RT.isOpen()
    local cw, ww = RT.cw(), RT.ww()
    f.cwTab = cw and cw._activeTab or nil
    f.wwTab = ww and ww._activeTab or nil
    f.page = cw and cw._journalSubTab or nil
    pcall(function() f.god = S.p:isGodMod() end)
    pcall(function() f.inv = S.p:isInvincible() end)
    local bd = S.bd()
    f.zInf = false
    pcall(function() f.zInf = bd:isInfected() end)
    f.open0 = table.concat(S.keys(), ",")
    if S.count() > 0 then pcall(P.closeAll, "pp_close") end
    S.clearQueue()
    S.pencil = RT.give("Base.Pencil")
    S.bag = RT.give("Base.Bag_Schoolbag")
    if S.bag then pcall(function() S.bagInv = S.bag:getInventory() end) end
    Q.check(S.pencil ~= nil and S.bagInv ~= nil, "a pencil and a school bag given (the harmless action: the pencil into the bag and out)")
    Events.OnTick.Add(S.safety)
    S.ticking = true
    RT.pairOpen()
    Q.say("found: windows " .. (f.pair and "open" or "shut") .. ", Character on " .. tostring(f.cwTab) .. ", World on "
        .. tostring(f.wwTab) .. ", Journal page " .. tostring(f.page) .. ", lists open [" .. f.open0 .. "], god " .. tostring(f.god))
    Q.say("NOTE the walk start is told to ZeD.Popups' walk rule (onPlayerUpdate, a stand-in moving): a real walk would take the character off the strip")
end
function S.skips()
    Q.skip("main menu lists (mm:menu, palette:<kind>, palette:mods)", "main menu only: covered by a main-menu script")
    Q.skip("Tickets, Logs and Admin card pickers (tk:<prefix>)",
        "the Server and Admin tabs are multiplayer only: not in a single player game (mp_ticket_cards opens the cards)")
end
function S.makeLists()
    local out = {}
    out[#out + 1] = S.healthSpec("exercise")
    out[#out + 1] = S.healthSpec("treat")
    out[#out + 1] = S.thermalSpec()
    for _, k in ipairs({ "sort", "show", "cat" }) do
        out[#out + 1] = S.ccSpec("journal recipes", "cw", "journal", 4, "_jrecipeState", "jrecipe", k, S.clickJR, true)
    end
    out[#out + 1] = S.bandSpec("journal papers show", 3, "_jr", "_jrZones", "showOpen", "show", "showRow:", "papers",
        function(w) Z.JournalReaders.shutList(w) end)
    local lo = S.bandSpec("journal loadouts filter", 5, "_jl", "_jlZones", "filterOpen", "filter", "filterRow:", "loadouts",
        function(w) Z.JournalLists.shutList(w) end)
    lo.prep = function() return S.loadOn() end
    lo.after = function() S.loadOff() end
    out[#out + 1] = lo
    for _, k in ipairs({ "dish", "base", "sort" }) do out[#out + 1] = S.cookSpec(k) end
    for _, k in ipairs({ "sort", "show", "cat" }) do
        local L = S.ccSpec("craft", "ww", "craft", nil, "_craftState", "craft", k, S.clickCraft, false)
        if k == "sort" then L.pairHide = true end
        out[#out + 1] = L
    end
    out[#out + 1] = S.stationSpec()
    for _, k in ipairs({ "sort", "show", "cat" }) do
        out[#out + 1] = S.ccSpec("build", "ww", "build", nil, "_buildState", "build", k, S.clickBuild, false)
    end
    out[#out + 1] = S.mechSpec()
    out[#out + 1] = S.mapsSpec()
    out[#out + 1] = S.forageSpec()
    out[#out + 1] = S.ctxSpec()
    return out
end
function S.build()
    Q.step(10, S.start)
    Q.waitFor(5, 180, function()
        local w = RT.cw()
        local v = false
        if w then pcall(function() v = w:isReallyVisible() end) end
        return S.dead or v
    end, function(ok)
        if S.dead then return end
        Q.check(ok, "the Character and World windows open")
        S.skips()
    end)
    for _, L in ipairs(S.makeLists()) do S.buildList(L) end
end

-- ===================================================================== put back
function S.putBack()
    if S.backDone then return end
    S.backDone = true
    local P = S.Pp()
    S.ctxShut()
    S.clearQueue()
    S.leftOpen = table.concat(S.keys(), ",")
    if P and P.closeAll and S.count() > 0 then pcall(P.closeAll, "pp_close") end
    for _, L in ipairs(S.lists) do S.restoreL(L) end
    S.unstage(false)
    S.loadOff()
    if S.ticking then pcall(function() Events.OnTick.Remove(S.safety) end); S.ticking = false end
    local f = S.found
    if f.god ~= nil then pcall(function() S.p:setGodMod(f.god and true or false) end) end
    if f.inv ~= nil then pcall(function() S.p:setInvincible(f.inv) end) end
    RT.pairOpen()
end
function S.buildPutBack()
    Q.mark()
    Q.step(3, function() S.putBack() end)
    Q.waitFor(3, 120, function()
        local w = RT.cw()
        local v = false
        if w then pcall(function() v = w:isReallyVisible() end) end
        return v
    end, function()
        local f, cw, ww = S.found, RT.cw(), RT.ww()
        if cw and f.page and cw._journalSubTab ~= f.page then pcall(Z.JournalTab.setPage, cw, f.page) end
        if f.cwTab then RT.charTab(f.cwTab) end
        if f.wwTab and ww then RT.worldTab(f.wwTab) end
    end)
    Q.step(20, function()
        S.unholdAll()
        if not S.found.pair then RT.pairShut() end
    end)
    Q.waitFor(5, 120, function() return RT.isOpen() == (S.found.pair == true) end, function(ok)
        local f = S.found
        Q.check(ok, "put back: the window pair " .. (f.pair and "open" or "shut") .. " as found")
        if f.pair then
            local cw, ww = RT.cw(), RT.ww()
            Q.check(cw ~= nil and cw._activeTab == f.cwTab and (f.page == nil or cw._journalSubTab == f.page)
                and (ww == nil or f.wwTab == nil or ww._activeTab == f.wwTab),
                "put back: both windows' tabs and the Journal page as found",
                "Character " .. tostring(cw and cw._activeTab) .. " (was " .. tostring(f.cwTab) .. "), page "
                    .. tostring(cw and cw._journalSubTab) .. " (was " .. tostring(f.page) .. "), World "
                    .. tostring(ww and ww._activeTab) .. " (was " .. tostring(f.wwTab) .. ")")
        end
        Q.check(S.count() == 0 and #S.held == 0 and not (S.ctxM and S.ctxM._ctx and S.ctxM._ctx.open),
            "put back: no list open (openCount() == 0), the context list closed, no window held",
            "open at the put-back [" .. tostring(S.leftOpen) .. "], now [" .. table.concat(S.keys(), ",") .. "]")
        local o = S.loadOpt()
        if f.loadSel ~= nil then
            Q.check(o ~= nil and o.selected == f.loadSel, "put back: the Loadouts and outfits option as found", tostring(o and o.selected))
        end
        if f.hand then
            local d = S.handDiff or {}
            Q.check(#d == 0 and not S.staged, "put back: the right hand exactly as found", #d == 0 and "every flag and clock" or table.concat(d, "; "))
        end
        local god, inv = nil, nil
        pcall(function() god = S.p:isGodMod() end)
        pcall(function() inv = S.p:isInvincible() end)
        Q.check(god == f.god and (f.inv == nil or inv == f.inv), "put back: god mode and invincible as found",
            "god " .. tostring(god) .. " (was " .. tostring(f.god) .. "), invincible " .. tostring(inv) .. " (was " .. tostring(f.inv) .. ")")
        Q.check(S.p:isDead() == false, "put back: the character is alive")
        local e1 = S.errN()
        if S.err0 and e1 then
            Q.check(e1 == S.err0, "the pop-up run ran with no Lua error", (e1 - S.err0) .. " new")
        else
            Q.skip("the pop-up run's Lua error count", "the game's Lua error count cannot be read here")
        end
    end)
    -- (rt_kit takes the pencil, the bag and the cooking things back after this, in Q.start's own step)
end

S.build()
S.buildPutBack()
Q.start()
