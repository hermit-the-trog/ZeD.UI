-- ZeDUI/tools/qa/bx_context.lua  (Nov 21 2026, QA beast day): right-click and left-click everything through ZeD's menus.
-- The menu ZeD draws for the game's own options (Overrides/ContextMenu.lua, ZeD_ContextMenu.lua the strip,
-- ZeD_ContextList.lua the list, ContextMenuRegistry.lua), in both styles of the ZeD setting "Context menu", opened
-- the way the game opens it (ISInventoryPaneContextMenu.createMenu, the world click's ISContextManager createWorldMenu, the
-- mechanics window's part menu, the animal menu), with the pointer the game reads pointed where the test wants it
-- (getMouseX / getMouseY answer the spot while a menu is being worked; Mouse.setXY does not move what the game reads).
--   1. every item kind: food, a weapon, a gun, a tool, carried and worn clothing, a bag, a book, a fluid container,
--      ammo, a key, three things selected at once;
--   2. world objects: bare ground, a door, a window, a curtain, a sink, a stove, a fridge, a generator, a light
--      switch, a bed, a chair, a crate, a trash can (the nearest one within 45 squares of the drag strip, else one
--      placed beside the character and removed at the end), a corpse, four parts of a car, and a hen on the farm field;
--   3. each menu: it opens on its target, no duplicate rows, then EVERY row and submenu is walked one a frame through
--      the menu's own navigation (the strip's next / confirm / cancel, the list's D-pad), each state drawn; every
--      row's state functions answer; the strip, its arrows and balloon, and every level of the list sit on screen;
--   4. things that vanish while their menu is up: a crate, a corpse, the car, an item, the hen;
--   5. the menu opened at every screen corner and edge and past the screen, in both styles; the list's submenus opened
--      by a resting pointer and every submenu row hovered (the player's report: a submenu drawn over its parent reset
--      when hovered), once with the submenu laid over its parent as a narrow screen places it;
--   6. 30 quick right-clicks in a row (two in one frame, a second click over an open menu, five ways to close);
--   7. the keyboard and the pad in both styles, 300 random navigation presses, a wheel spun for 45 frames each way;
--   8. menus opened by the pad; a right-click during a timed action; a right-click while dragging; walking away.
-- Everything is put back: items, placed objects, the corpse, the car, the hen, the setting, the hands, the place.
-- Safety: god mode and invincible are ON for the whole run (a zombie is made for the corpse, he stands in the open and
-- goes to the farm); the put-back heals him first, and the last check says he is alive and healed (health 100, no
-- wound or fracture, not infected) before god mode and invincible go back as found.
-- Run after zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA bx_ctx".

local Q = RT.make("bx_ctx")
Q.maxMs = 430000
local S = { p = RT.p, pn = RT.pn, dead = false, T = {}, placed = {}, used = {}, sqN = {}, found = {}, closeBad = {},
            menus = 0, scroll = {}, seed = 4242, heads = { n = 0, bad = {} } }
local H = {}

local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
local function waitFor(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end

-- ===================================================================== small helpers
function H.scr() return getCore():getScreenWidth(), getCore():getScreenHeight() end
function H.fl(v) return math.floor(tonumber(v) or 0) end
function H.mod(a, n) return a - math.floor(a / n) * n end
function H.opt() return ZeD.Settings and ZeD.Settings.contextStyleOption end
function H.vmenu() return getPlayerContextMenu(S.pn) end
function H.menu() local v = H.vmenu(); return v and v._zedMenu or nil end
function H.cc() local w = RT.cw(); return w and w._mainContent end
function H.exists(ft) return getScriptManager():FindItem(ft) ~= nil end
function H.queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(S.p)
    return not q or not q.queue or #q.queue == 0
end
function H.join(t, max)
    max = max or 5
    local out = {}
    for i = 1, math.min(#t, max) do out[#out + 1] = tostring(t[i]) end
    local s = table.concat(out, "; ")
    if #t > max then s = s .. " (+" .. (#t - max) .. " more)" end
    return s
end
-- one line per kind of fault on a walk (a menu off screen is said once, not once a row)
function H.note(W, key, text)
    W.seen = W.seen or {}
    if W.seen[key] then return end
    W.seen[key] = true
    W.bad[#W.bad + 1] = text
end
function H.rnd(n)
    local x = S.seed * 75 + 74
    S.seed = x - math.floor(x / 65537) * 65537
    return H.mod(S.seed, n)
end
function H.stand(x, y)
    S.p:setX(x); S.p:setY(y); S.p:setLastX(x); S.p:setLastY(y)
end
-- a part of the put-back, said when it throws (the rest still runs)
function H.try(what, fn)
    local ok, err = pcall(fn)
    if not ok then Q.say("NOTE put back, " .. what .. " threw: " .. tostring(err)) end
end
-- the body made whole (the game's own full heal, no argument: BodyDamage.RestoreToFullHealth())
function H.heal()
    pcall(function() if S.p and not S.p:isDead() then S.p:getBodyDamage():RestoreToFullHealth() end end)
end
-- what is still wrong with him: {} when alive, health 100, no wound, no fracture, not infected
function H.hurt()
    local out = {}
    local ok, err = pcall(function()
        local p = S.p
        if p:isDead() then out[#out + 1] = "he is dead" end
        local bd = p:getBodyDamage()
        S.hp = bd:getOverallBodyHealth()
        if S.hp < 99.5 then out[#out + 1] = "health " .. tostring(S.hp) end
        if bd:isInfected() then out[#out + 1] = "infected" end
        if bd:IsFakeInfected() then out[#out + 1] = "fake infection" end
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            local w = {}
            if bp:scratched() then w[#w + 1] = "scratch" end
            if bp:isCut() then w[#w + 1] = "cut" end
            if bp:deepWounded() then w[#w + 1] = "deep wound" end
            if bp:bitten() then w[#w + 1] = "bite" end
            if bp:bleeding() then w[#w + 1] = "bleeding" end
            if bp:getFractureTime() > 0 then w[#w + 1] = "fracture" end
            if bp:getBurnTime() > 0 then w[#w + 1] = "burn" end
            if bp:haveGlass() then w[#w + 1] = "glass" end
            if bp:haveBullet() then w[#w + 1] = "bullet" end
            if bp:IsInfected() or bp:isInfectedWound() then w[#w + 1] = "infected" end
            if #w > 0 then out[#out + 1] = tostring(bp:getType()) .. ": " .. table.concat(w, ", ") end
        end
    end)
    if not ok then out[#out + 1] = "the health check threw: " .. tostring(err) end
    return out
end
function H.zoneOf(m, id)
    for _, z in ipairs(m and m._hitZones or {}) do if z.id == id then return z end end
    return nil
end

-- ===================================================================== the pointer the game reads
function H.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    getMouseX = function() return S.fx end
    getMouseY = function() return S.fy end
end
function H.mouseOff()
    if not S.mouseSwapped then return end
    getMouseX, getMouseY = S.realMX, S.realMY
    S.mouseSwapped = false
end
-- the pointer moved to a spot, and the menu's own update run on it (the game runs it every 100 ms)
function H.point(m, x, y)
    H.mouseOn(x, y)
    m:update()
end

-- ===================================================================== a menu's draw and update, watched
function H.wrap(m)
    if not m or S.wrapM == m then return end
    H.unwrap()
    S.wrapM, S.drawErr, S.drawN = m, nil, 0
    S.wrapPre, S.wrapUpd = rawget(m, "prerender"), rawget(m, "update")
    local pre, upd = m.prerender, m.update
    m.prerender = function(self)
        S.drawN = S.drawN + 1
        local ok, e = pcall(pre, self)
        if not ok and not S.drawErr then S.drawErr = "its draw threw: " .. tostring(e) end
    end
    m.update = function(self)
        local ok, e = pcall(upd, self)
        if not ok and not S.drawErr then S.drawErr = "its update threw: " .. tostring(e) end
    end
end
function H.unwrap()
    local m = S.wrapM
    if m then m.prerender, m.update = S.wrapPre, S.wrapUpd end
    S.wrapM = nil
end
-- ZeD's menus among the UI roots (a menu left behind stays there)
function H.menuRoots()
    local n = 0
    for _, r in ipairs(RT.roots()) do
        local ty = r.t and r.t.Type
        if ty == "ZeD_ContextMenu" or ty == "ZeD_ContextList" then n = n + 1 end
    end
    return n
end
function H.closeMenu()
    local m = H.menu()
    if m then
        local ok, err = pcall(m.close, m)
        if not ok then S.closeBad[#S.closeBad + 1] = "close threw: " .. tostring(err) end
    end
    local v = H.vmenu()
    if v and not v._zedMenu and v.closeAll and v:isVisible() then v:closeAll() end
    H.unwrap()
    H.mouseOff()
end
function H.afterClose(lbl)
    S.menus = S.menus + 1
    if H.menu() ~= nil then S.closeBad[#S.closeBad + 1] = lbl .. ": the game's menu still holds ZeD's menu" end
    local n = H.menuRoots()
    if n ~= S.rootsBase then S.closeBad[#S.closeBad + 1] = lbl .. ": " .. n .. " ZeD menus left on screen (" .. tostring(S.rootsBase) .. " before)" end
end

-- ===================================================================== opening
S.SPOTS = { { 0.5, 0.45 }, { 0.32, 0.3 }, { 0.68, 0.62 }, { 0.3, 0.68 }, { 0.7, 0.28 } }
function H.spot()
    S.spotI = H.mod(S.spotI or 0, #S.SPOTS) + 1
    local w, h = H.scr()
    local s = S.SPOTS[S.spotI]
    return math.floor(w * s[1]), math.floor(h * s[2])
end
S.ANCH = {
    { 0.5, 0.45, "the middle of the screen" }, { 0, 0, "the top left corner" }, { 1, 0, "the top right corner" },
    { 0, 1, "the bottom left corner" }, { 1, 1, "the bottom right corner" }, { 0.5, 0, "the top edge" },
    { 0.5, 1, "the bottom edge" }, { 0, 0.5, "the left edge" }, { 1, 0.5, "the right edge" },
    { 1.15, 1.15, "a point past the bottom right corner" }, { -0.1, -0.1, "a point past the top left corner" },
}
function H.anchor(i)
    local w, h = H.scr()
    local a = S.ANCH[i]
    return math.floor((w - 1) * a[1]), math.floor((h - 1) * a[2]), a[3]
end
-- staged once, the first time a target is asked for
function H.ready(T)
    if T.ok == nil then
        local ok, a, b = pcall(T.prep, T)
        if ok and a then
            T.ok = true
        else
            T.ok = false
            Q.skip(T.label, ok and tostring(b) or ("its staging threw: " .. tostring(a)))
        end
    end
    return T.ok
end
function H.open(T, x, y)
    H.closeMenu()
    S.cur, S.openErr, S.ret, S.noOpen = T, nil, nil, false
    H.mouseOn(x, y)
    local ok, r = pcall(T.make, T, x, y)
    if ok then S.ret = r else S.openErr = tostring(r) end
end
-- ZeD's menu is up, or the game made none, or ZeD could not make its own
function H.opened()
    if S.noOpen or S.openErr then return true end
    if H.menu() then return true end
    local v = H.vmenu()
    if not v then return true end
    if v._zedFailed or v._zedSpawned then return true end
    return not v:isVisible()
end
function H.count(defs, seen)
    local n = 0
    for _, d in ipairs(defs or {}) do
        if type(d) == "table" and not seen[d] then seen[d] = true; n = n + 1 + H.count(d.children, seen) end
    end
    return n
end
-- duplicate rows among siblings: the same game option twice, or one name from two of the game's menus (ZeD folds
-- the game's "More" submenu into its parent); two rows of one name in one game menu are the game's own (a note)
function H.dups(defs, out, notes, seen, path)
    local refs, names = {}, {}
    for _, d in ipairs(defs or {}) do
        if type(d) == "table" and not seen[d] then
            seen[d] = true
            local nm = tostring(d.name)
            if d.vanillaRef ~= nil then
                if refs[d.vanillaRef] then out[#out + 1] = path .. nm .. " (the same option twice)" end
                refs[d.vanillaRef] = true
            end
            local was = names[nm]
            if was ~= nil then
                if was == (d._vanillaMenu or false) then notes[#notes + 1] = path .. nm
                else out[#out + 1] = path .. nm .. " (twice, from two of the game's menus)" end
            end
            names[nm] = d._vanillaMenu or false
            H.dups(d.children, out, notes, seen, path .. nm .. " > ")
        end
    end
end
function H.tree(T, m, lbl)
    local out, notes = {}, {}
    local defs = m._ctx.actions or {}
    H.dups(defs, out, notes, {}, "")
    Q.check(#defs > 0 and #out == 0, lbl .. ": no duplicate rows", H.count(defs, {}) .. " rows with their submenus" .. ((#out > 0) and ("; " .. H.join(out, 6)) or ""))
    if #notes > 0 and not T.dupNoted then
        T.dupNoted = true
        Q.say("NOTE " .. T.label .. ": the game's own menu has two rows of one name: " .. H.join(notes, 6))
    end
end
-- the list's heading on a world right-click names what was clicked (gathered, one check for all)
function H.heading(T, m)
    local name = ZeD.ContextMenu.Registry.getTargetDisplay(m._ctx.target)
    S.heads.n = S.heads.n + 1
    if type(name) ~= "string" or name == "" or name == "null" or name == ZeD.tr("IGUI_Item") then
        S.heads.bad[#S.heads.bad + 1] = T.label .. " reads \"" .. tostring(name) .. "\""
    else
        S.heads.ok = (S.heads.ok or "") .. T.label .. " = \"" .. name .. "\", "
    end
end
function H.checkOpen(T, style, lbl)
    if S.noOpen then return false end
    if S.openErr then Q.check(false, lbl .. ": the right-click runs without an error", S.openErr); return false end
    local m, v = H.menu(), H.vmenu()
    if not m then
        local n = (v and v.options) and #v.options or 0
        if not (v and v:isVisible()) or n == 0 then Q.skip(lbl, "the game offers no option here"); return false end
        Q.check(false, lbl .. ": ZeD's menu opens for the game's " .. n .. " options", "ZeD's menu could not be made: " .. tostring(v._zedFailed))
        return false
    end
    H.wrap(m)
    local want = (style == 2) and "ZeD_ContextList" or "ZeD_ContextMenu"
    -- (a world click with nothing of its own to offer gets a fresh menu from the game: no target is stamped on it)
    local onIt = T.target == nil or m._ctx.target == T.target or (T.world and m._ctx.target == nil)
    Q.check(m.Type == want and onIt, lbl .. ": the right-click opens ZeD's menu on it",
        tostring(m.Type) .. ", " .. #(m._ctx.actions or {}) .. " top rows" .. (T.how and (", " .. T.how) or ""))
    H.tree(T, m, lbl)
    if T.world and m._levels then H.heading(T, m) end
    H.mouseOn(-9000, -9000)   -- (off every menu: the walk's selection is its own, not the pointer's)
    return true
end

-- ===================================================================== on screen
function H.listOnScreen(W, m)
    local sw, sh = H.scr()
    for i, lv in ipairs(m._levels or {}) do
        if lv.x < -1 or lv.y < -1 or lv.x + lv.w > sw + 1 or lv.y + lv.h > sh + 1 then
            H.note(W, "lv" .. i .. ":" .. tostring(lv.parentRow), string.format("level %d (%d rows) at %d,%d %dx%d is off the %dx%d screen",
                i, #lv.rows, H.fl(lv.x), H.fl(lv.y), H.fl(lv.w), H.fl(lv.h), sw, sh))
        end
    end
end
function H.stripOnScreen(W, m)
    local sw, sh = H.scr()
    local x, y, w, h = m:getX(), m:getY(), m:getWidth(), m:getHeight()
    if x < -1 or y < -1 or x + w > sw + 1 or y + h > sh + 1 then
        H.note(W, "panel", string.format("the strip's panel at %d,%d %dx%d is off the %dx%d screen", H.fl(x), H.fl(y), H.fl(w), H.fl(h), sw, sh))
    end
    local c = m._layoutCache
    if not c or (c.stripW or 0) <= 0 then return end
    local ctx = ZeD.T.ctx
    local ext = m._ctx.truncating and (ctx.gutter + ctx.chevW) or 0
    local l, r, t, b = x + c.stripX, x + c.stripX + c.stripW, y + c.stripY, y + c.stripY + c.stripH
    if l - ext < -1 or t < -1 or r + ext > sw + 1 or b > sh + 1 then
        H.note(W, "strip", string.format("the strip with its arrows spans %d to %d, %d to %d on the %dx%d screen", H.fl(l - ext), H.fl(r + ext), H.fl(t), H.fl(b), sw, sh))
    end
    if (c.balloonW or 0) <= 0 then return end
    local bx, by = x + c.balloonX, y + c.balloonY
    if bx < -1 or by < -1 or bx + c.balloonW > sw + 1 or by + c.balloonH > sh + 1 then
        H.note(W, "balloon", string.format("the strip's balloon at %d,%d %dx%d is off the %dx%d screen", H.fl(bx), H.fl(by), H.fl(c.balloonW), H.fl(c.balloonH), sw, sh))
    end
    local ox = math.min(bx + c.balloonW, r) - math.max(bx, l)
    local oy = math.min(by + c.balloonH, b) - math.max(by, t)
    if ox > 4 and oy > 4 then H.note(W, "cover", "the strip's balloon lies over the strip (" .. H.fl(ox) .. " by " .. H.fl(oy) .. " px)") end
end

-- ===================================================================== the walk: every row, every submenu
function H.kids(m, def)
    if type(def) ~= "table" or def.isBack or def.heading then return 0 end
    local k = ZeD.ContextMenu.Registry.childrenOf(def, m._ctx.target)
    return k and #k or 0
end
function H.off(m, def) return def.disabled ~= nil and def.disabled(m._ctx.target) and true or false end
function H.liveCount(lv)
    local n = 0
    for _, r in ipairs(lv and lv.rows or {}) do if r.def and not r.def.heading then n = n + 1 end end
    return n
end
function H.visit(W, m, def)
    W.n = W.n + 1
    if type(def) ~= "table" then W.bad[#W.bad + 1] = "no option at step " .. W.n; return end
    if def.isBack then return end
    local nm = def.name
    if type(nm) ~= "string" or nm == "" then H.note(W, "name" .. W.n, "a row with no name (id " .. tostring(def.id) .. ")") end
    local t = m._ctx.target
    if def.disabled then def.disabled(t) end
    if def.state and type(def.state(t)) ~= "string" then H.note(W, "state" .. W.n, tostring(nm) .. ": its state is not words") end
    local sk = def.stateKind and def.stateKind(t)
    if sk ~= nil and sk ~= "ok" and sk ~= "bad" then H.note(W, "kind" .. W.n, tostring(nm) .. ": state kind " .. tostring(sk)) end
    if not (def.heading or def.pxIcon or def.iconTexture or def.check ~= nil) then W.noIcon[#W.noIcon + 1] = tostring(nm) end
end
function H.walkStart(lbl)
    local m = H.menu()
    local W = { m = m, lbl = lbl, n = 0, bad = {}, noIcon = {}, subs = 0, deep = 1, stack = {}, cap = 90 }
    S.W = W
    if not m then W.done = true; return end
    if m._levels then
        local lv = m._levels[1]
        lv.sel = m:_firstLive(lv, 1, 1) or 1
        W.stack[1] = { n = H.liveCount(lv), i = 0 }
    else
        m._ctx.selected = 1
        m:_rebuildTrack()
        W.stack[1] = { n = #m._ctx.items, i = 0 }
    end
end
function H.walkStrip(W, m)
    local c = m._ctx
    local top = W.stack[#W.stack]
    if top.i >= top.n or W.n >= W.cap then
        if #W.stack == 1 then W.done = true; W.capped = W.n >= W.cap; return end
        local d0 = #c.path
        m:cancel()
        if #c.path ~= d0 - 1 or not c.open then W.bad[#W.bad + 1] = "Back did not step out of a submenu"; W.done = true; return end
        W.stack[#W.stack] = nil
        return
    end
    top.i = top.i + 1
    if top.i > 1 then m:next() end
    local want = (#c.path == 0) and top.i or (top.i + 1)
    if c.selected ~= want then H.note(W, "sel", "the selection is on cell " .. tostring(c.selected) .. ", not " .. want .. ", after a step right") end
    local def = c.items[c.selected]
    H.visit(W, m, def)
    H.stripOnScreen(W, m)
    if type(def) == "table" and #c.path < 3 and H.kids(m, def) > 0 and not H.off(m, def) then
        local d0 = #c.path
        m:confirm()
        if not c.open then W.bad[#W.bad + 1] = "a press on " .. tostring(def.name) .. " (it has a submenu) closed the menu"; W.done = true; return end
        if #c.path == d0 + 1 then
            W.subs = W.subs + 1
            W.stack[#W.stack + 1] = { n = #c.items - 1, i = 0 }
            if #W.stack > W.deep then W.deep = #W.stack end
        else
            H.note(W, "sub" .. W.n, tostring(def.name) .. " did not open its submenu")
        end
    end
end
function H.walkList(W, m)
    local li = #m._levels
    local lv = m._levels[li]
    local top = W.stack[#W.stack]
    if #W.stack ~= li then W.bad[#W.bad + 1] = "the list shows " .. li .. " levels, the walk is " .. #W.stack .. " deep"; W.done = true; return end
    if top.i >= top.n or W.n >= W.cap then
        if li == 1 then W.done = true; W.capped = W.n >= W.cap; return end
        m:onJoypadDirLeft()
        if #m._levels ~= li - 1 then W.bad[#W.bad + 1] = "D-pad Left did not close a submenu"; W.done = true; return end
        W.stack[#W.stack] = nil
        return
    end
    top.i = top.i + 1
    if top.i > 1 then
        local s0 = lv.sel
        m:onJoypadDirDown()
        if lv.sel == nil or lv.sel <= (s0 or 0) then H.note(W, "down", "D-pad Down from row " .. tostring(s0) .. " went to " .. tostring(lv.sel)) end
    end
    local r = lv.sel and lv.rows[lv.sel]
    local def = r and r.def
    H.visit(W, m, def)
    H.listOnScreen(W, m)
    if type(def) == "table" and li < 4 and H.kids(m, def) > 0 and not H.off(m, def) then
        m:onJoypadDirRight()
        if #m._levels == li + 1 then
            W.subs = W.subs + 1
            W.stack[#W.stack + 1] = { n = H.liveCount(m._levels[li + 1]), i = 0 }
            if #W.stack > W.deep then W.deep = #W.stack end
            H.listOnScreen(W, m)
        else
            H.note(W, "sub" .. W.n, tostring(def.name) .. " did not open its submenu")
        end
    end
end
-- one row a frame; true when the walk is over
function H.walkTick()
    local W = S.W
    if not W or W.done then return true end
    local m = W.m
    if H.menu() ~= m or not m._ctx.open then
        W.bad[#W.bad + 1] = "the menu closed during the walk (at step " .. W.n .. ")"
        W.done = true
        return true
    end
    if S.drawErr then W.done = true; return true end
    -- (two rows a frame: every other state is drawn, the run stays inside its time)
    for _ = 1, 2 do
        if not W.done then
            local ok, err = pcall(m._levels and H.walkList or H.walkStrip, W, m)
            if not ok then W.bad[#W.bad + 1] = "the walk threw at step " .. W.n .. ": " .. tostring(err); W.done = true end
        end
    end
    return W.done == true
end
function H.walkWords(W)
    local d = W.n .. " rows walked, " .. W.subs .. " submenus, " .. W.deep .. " deep, " .. tostring(S.drawN) .. " frames drawn"
    if S.drawErr then d = d .. "; " .. S.drawErr end
    if #W.bad > 0 then d = d .. "; " .. H.join(W.bad, 5) end
    return d
end
function H.walkEnd(T, lbl)
    local W = S.W
    if not W.done then W.bad[#W.bad + 1] = "the walk did not finish in its frames" end
    Q.check(#W.bad == 0 and not S.drawErr, lbl .. ": every row and submenu walked, on screen, no error", H.walkWords(W))
    if W.capped then Q.say("NOTE " .. lbl .. ": the walk stopped at " .. W.cap .. " rows (a very long menu)") end
    if #W.noIcon > 0 and not T.iconNoted then
        T.iconNoted = true
        Q.say("NOTE " .. T.label .. ": rows with no icon: " .. H.join(W.noIcon, 8))
    end
    T.rows = math.max(T.rows or 0, #(W.m._ctx.actions or {}))
    T.subs = math.max(T.subs or 0, W.subs)
end
-- the steps for one target in one style
function H.seq(T, style)
    local lbl = ((style == 2) and "list, " or "strip, ") .. T.label
    step(2, function()
        S.live = false
        if not H.ready(T) then S.noOpen = true; return end
        H.opt():setValue(style)
        local x, y = H.spot()
        H.open(T, x, y)
    end)
    waitFor(1, 90, H.opened, function()
        S.live = H.checkOpen(T, style, lbl)
        if S.live then H.walkStart(lbl) end
    end)
    waitFor(1, 320, function() return not S.live or H.walkTick() end, function()
        if S.live then H.walkEnd(T, lbl) end
    end)
    step(1, function()
        if S.live and T.after then T.after(T, lbl) end
        H.closeMenu()
    end)
    step(1, function()
        if S.live then H.afterClose(lbl) end
        S.live = false
    end)
end

-- ===================================================================== the things: items
S.INV = {
    { key = "food", label = "food (an apple)", ft = { "Base.Apple" } },
    { key = "weapon", label = "a weapon (an axe)", ft = { "Base.Axe", "Base.BaseballBat" } },
    { key = "gun", label = "a gun (a pistol)", ft = { "Base.Pistol" } },
    { key = "tool", label = "a tool (a screwdriver)", ft = { "Base.Screwdriver", "Base.Hammer" } },
    { key = "cloth", label = "carried clothing", ft = { "Base.Tshirt_DefaultTEXTURE", "Base.Hat_BaseballCap", "Base.Vest_DefaultTEXTURE" } },
    { key = "worn", label = "worn clothing", worn = true },
    { key = "bag", label = "a bag", ft = { "Base.Bag_Schoolbag", "Base.Bag_Satchel" } },
    { key = "book", label = "a book", ft = { "Base.Book", "Base.BookCarpentry1" } },
    { key = "fluid", label = "a fluid container (a bottle)", ft = { "Base.WaterBottle", "Base.PopBottle", "Base.Bucket" } },
    { key = "ammo", label = "ammo (a box of bullets)", ft = { "Base.Bullets9mmBox", "Base.Bullets9mm" } },
    { key = "key", label = "a key", ft = { "Base.Key1", "Base.CarKey" } },
    { key = "multi", label = "three different things selected", multi = { "food", "tool", "bag" } },
}
function H.wornItem()
    local worn = S.p:getWornItems()
    for i = 0, worn:size() - 1 do
        local it = worn:get(i):getItem()
        if it and not it:IsInventoryContainer() then return it end
    end
    return nil
end
function H.invPrep(T)
    local d = T.d
    if d.multi then
        T.target = {}
        for _, k in ipairs(d.multi) do
            local o = S.T[k]
            if o and o.item then T.target[#T.target + 1] = o.item end
        end
        if #T.target < 2 then return false, "fewer than two of its things could be given" end
        return true
    end
    if d.worn then
        T.item = H.wornItem()
        if not T.item then return false, "the character wears no clothing" end
    else
        for _, ft in ipairs(d.ft) do
            if not T.item and H.exists(ft) then T.item = RT.give(ft) end
        end
        if not T.item then return false, "none of its item types is in this game: " .. table.concat(d.ft, ", ") end
    end
    T.target = { T.item }
    return true
end
function H.invMake(T, x, y) return ISInventoryPaneContextMenu.createMenu(S.pn, true, T.target, x, y) end

-- ===================================================================== the things: world objects
S.WORLD = {
    { key = "ground", label = "bare ground" }, { key = "door", label = "a door" }, { key = "window", label = "a window" },
    { key = "curtain", label = "a curtain" }, { key = "sink", label = "a sink" }, { key = "stove", label = "a stove" },
    { key = "fridge", label = "a fridge" }, { key = "generator", label = "a generator" }, { key = "switch", label = "a light switch" },
    { key = "bed", label = "a bed" }, { key = "chair", label = "a chair" }, { key = "crate", label = "a crate" },
    { key = "trash", label = "a trash can" },
}
S.TILES = {
    sink = { "fixtures_sinks_01_0", "fixtures_sinks_01_8", "fixtures_sinks_01_16" },
    bed = { "furniture_bedding_01_0", "furniture_bedding_01_8" },
    chair = { "furniture_seating_indoor_01_0", "furniture_seating_indoor_02_0", "furniture_seating_outdoor_01_0" },
    crate = { "carpentry_01_16" },
    trash = { "trashcontainers_01_0", "trashcontainers_01_8", "trashcontainers_01_16" },
    fridge = { "appliances_refrigeration_01_0", "appliances_refrigeration_01_4" },
}
S.RING = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, 2 }, { 2, -2 }, { -2, -2 }, { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 },
           { 3, 2 }, { -3, 2 }, { 3, -2 }, { -3, -2 }, { 2, 3 }, { -2, 3 }, { 2, -3 }, { -2, -3 }, { 3, 3 }, { -3, -3 }, { 3, -3 }, { -3, 3 } }
function H.nameKind(nm)
    if nm:find("sink", 1, true) then return "sink" end
    if nm:find("bed", 1, true) then return "bed" end
    if nm:find("chair", 1, true) or nm:find("seat", 1, true) or nm:find("bench", 1, true) or nm:find("stool", 1, true) then return "chair" end
    if nm:find("trash", 1, true) or nm:find("garbage", 1, true) or nm:find("dumpster", 1, true) then return "trash" end
    return nil
end
function H.kindOf(o)
    if instanceof(o, "IsoWorldInventoryObject") then return nil end
    if instanceof(o, "IsoDoor") then return "door" end
    if instanceof(o, "IsoThumpable") then return o:isDoor() and "door" or nil end
    if instanceof(o, "IsoWindow") then return "window" end
    if instanceof(o, "IsoCurtain") then return "curtain" end
    if instanceof(o, "IsoLightSwitch") then return "switch" end
    if instanceof(o, "IsoStove") then return "stove" end
    if instanceof(o, "IsoGenerator") then return "generator" end
    local c = o:getContainer()
    local ct = c and string.lower(tostring(c:getType())) or ""
    if ct == "fridge" then return "fridge" end
    if ct == "crate" then return "crate" end
    if ct == "bin" or ct == "dumpster" then return "trash" end
    local spr = o:getSprite()
    local props = spr and spr:getProperties()
    if props and props:has("CustomName") then return H.nameKind(string.lower(tostring(props:get("CustomName")))) end
    return nil
end
function H.scanSq(sq, d2)
    local objs = sq:getObjects()
    local n = objs:size()
    if n < 2 then return end
    for i = 1, n - 1 do
        local o = objs:get(i)
        local k = H.kindOf(o)
        if k and (not S.found[k] or d2 < S.found[k].d2) then S.found[k] = { o = o, d2 = d2 } end
    end
end
-- the nearest thing of each kind within 45 squares of home (the grandstands' fixtures, where they are loaded)
function H.scan()
    local cell = getCell()
    local px, py = math.floor(S.home.x), math.floor(S.home.y)
    for dx = -45, 45 do
        for dy = -45, 45 do
            local sq = cell:getGridSquare(px + dx, py + dy, 0)
            if sq then H.scanSq(sq, dx * dx + dy * dy) end
        end
    end
    local got = {}
    for _, d in ipairs(S.WORLD) do
        if S.found[d.key] then got[#got + 1] = d.key .. " " .. math.floor(math.sqrt(S.found[d.key].d2)) .. " away" end
    end
    Q.say("found near the drag strip: " .. ((#got > 0) and table.concat(got, ", ") or "nothing (each kind is placed beside the character)"))
end
function H.sqKey(sq) return sq:getX() .. "," .. sq:getY() end
function H.sqOpen(sq)
    if not sq:isFree(false) or sq:HasTree() or sq:getVehicleContainer() ~= nil or sq:getRoom() ~= nil then return false end
    if S.car and math.abs(S.car:getX() - (sq:getX() + 0.5)) < 3 and math.abs(S.car:getY() - (sq:getY() + 0.5)) < 5 then return false end
    return true
end
function H.freeSq()
    local bx, by = math.floor(S.p:getX()), math.floor(S.p:getY())
    for _, o in ipairs(S.RING) do
        local sq = getCell():getGridSquare(bx + o[1], by + o[2], 0)
        if sq and not S.used[H.sqKey(sq)] and H.sqOpen(sq) then return sq end
    end
    return nil
end
function H.mkTile(sq, names)
    for _, name in ipairs(names) do
        if getSprite(name) then
            local o = IsoObject.new(sq, name, nil, false)
            sq:AddTileObject(o)
            o:createContainersFromSpriteProperties()
            return o
        end
    end
    return nil
end
function H.mkSpecial(sq, o)
    sq:AddSpecialObject(o)
    if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
    return o
end
function H.mkStove(sq)
    for _, name in ipairs({ "appliances_cooking_01_0", "appliances_cooking_01_8" }) do
        local spr = getSprite(name)
        if spr then
            local o = IsoStove.new(getCell(), sq, spr)
            o:createContainersFromSpriteProperties()
            return H.mkSpecial(sq, o)
        end
    end
    return nil
end
function H.mkGen(sq)
    local g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq)
    g:setConnected(false); g:setFuel(60); g:setCondition(90)
    return g
end
function H.mkDoor(sq)
    local spr = getSprite("fixtures_doors_01_1")
    if not spr then return nil end
    return H.mkSpecial(sq, IsoDoor.new(getCell(), sq, spr, true))
end
function H.mkWindow(sq)
    local spr = getSprite("fixtures_windows_01_1")
    if not spr then return nil end
    return H.mkSpecial(sq, IsoWindow.new(getCell(), sq, spr, true))
end
function H.mkCurtain(sq)
    for _, name in ipairs({ "fixtures_windows_curtains_01_16", "fixtures_windows_curtains_01_0" }) do
        if getSprite(name) then return H.mkSpecial(sq, IsoCurtain.new(getCell(), sq, name, true)) end
    end
    return nil
end
function H.place(key)
    local sq = (key == "curtain" and S.winSq) or H.freeSq()
    if not sq then return nil end
    local n0 = sq:getObjects():size()
    local o = nil
    if key == "stove" then o = H.mkStove(sq)
    elseif key == "generator" then o = H.mkGen(sq)
    elseif key == "door" then o = H.mkDoor(sq)
    elseif key == "window" then o = H.mkWindow(sq); if o then S.winSq = sq end
    elseif key == "curtain" then o = H.mkCurtain(sq)
    elseif S.TILES[key] then o = H.mkTile(sq, S.TILES[key]) end
    if o then
        local k = H.sqKey(sq)
        S.placed[#S.placed + 1] = { o = o, sq = sq, key = key }
        if S.sqN[k] == nil then S.sqN[k] = { x = sq:getX(), y = sq:getY(), n = n0 } end
        S.used[k] = true
    end
    return o
end
-- (rt_cards.lua's removal: the square's own remove, then the tile list, a generator's own remove)
function H.removeObj(o)
    local sq = o:getSquare()
    if sq then
        sq:transmitRemoveItemFromSquare(o)
        if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end
    end
    if instanceof(o, "IsoGenerator") then pcall(function() o:remove() end) end
end
function H.unplace(e)
    if e.gone then return end
    e.gone = true
    H.removeObj(e.o)
end
-- a world right-click as the game makes it (ISObjectClickHandler.doRClick): the clicked object, the list holding it,
-- and the object's own place on screen (the game reads the square under that spot too)
function H.screenOf(sq)
    local x, y, z = sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ()
    return math.floor(isoToScreenX(S.pn, x, y, z)), math.floor(isoToScreenY(S.pn, x, y, z))
end
function H.worldPrep(T)
    local k = T.d.key
    local o, how = nil, "the nearest one on the map"
    if k == "ground" then
        local sq = H.freeSq()
        o = sq and sq:getFloor() or nil
        how = "open ground two squares off"
    else
        o = S.found[k] and S.found[k].o or nil
        if not o then o = H.place(k); how = "placed beside the character" end
    end
    if not o then return false, "none within 45 squares of the drag strip, and one could not be placed here" end
    T.obj, T.how, T.world = o, how, true
    T.target = { o }
    return true
end
function H.worldMake(T, x, y)
    local sx, sy = H.screenOf(T.obj:getSquare())
    return ISContextManager.getInstance().createWorldMenu(S.pn, T.obj, T.target, sx, sy)
end

-- a corpse: a zombie made and turned into a body (zedqa_deep_run.lua's way); the game picks a corpse by the screen
-- spot passed to createMenu, so the menu is asked for at the body's own place on screen
function H.corpsePrep(T)
    local sq = H.freeSq()
    if not sq then return false, "no free square beside the character" end
    local z = createZombie(sq:getX() + 0.5, sq:getY() + 0.5, 0, nil, 0, IsoDirections.S)
    if not z then return false, "the game made no zombie" end
    -- (the zombie never stays: whatever the body's making does, it is taken out of the world in this same call)
    local okB, body = pcall(function()
        z:dressInRandomOutfit()
        return IsoDeadBody.new(z, false)
    end)
    pcall(function() z:removeFromWorld() end)
    pcall(function() z:removeFromSquare() end)
    if not okB then return false, "making the body threw: " .. tostring(body) end
    if not body then return false, "the game made no body" end
    S.body, T.obj, T.world = body, body, true
    S.used[H.sqKey(sq)] = true
    T.floor = sq:getFloor()
    T.target = { T.floor }
    T.how = "a body made two squares off"
    return true
end
function H.corpseMake(T, x, y)
    local b = T.obj
    local sx = math.floor(isoToScreenX(S.pn, b:getX(), b:getY(), b:getZ()))
    local sy = math.floor(isoToScreenY(S.pn, b:getX(), b:getY(), b:getZ()))
    H.mouseOn(sx, sy)
    local r = ISContextManager.getInstance().createWorldMenu(S.pn, T.floor, T.target, sx, sy)
    local fv = ISWorldObjectContextMenu.fetchVars
    T.picked = fv ~= nil and fv.body == b
    return r
end
function H.corpseAfter(T, lbl)
    if T.pickSaid then return end
    T.pickSaid = true
    if T.picked then Q.say("NOTE corpse: the game's own pick found the body under the pointer; the menu is the corpse's")
    else Q.skip("corpse: the menu is the corpse's own", "the game's pick found no body at its screen spot; the menu walked is the ground's under it") end
end
function H.bodyAway()
    local b = S.body
    S.body = nil
    if not b then return end
    local sq = b:getSquare()
    if sq then sq:removeCorpse(b, false) end
end

-- the car's parts: the game's own part menu (the mechanics window's doPartContextMenu, as ZeD's Vehicle tab calls it)
S.PARTS = { { id = "Engine", label = "the car's engine" }, { id = "TireFrontLeft", label = "a car tire" },
            { id = "DoorFrontLeft", label = "a car door" }, { id = "GasTank", label = "the car's gas tank" } }
function H.partPrep(T)
    if not S.car then return false, "no car on the drag strip (" .. tostring(S.carWhy) .. ")" end
    T.part = S.car:getPartById(T.d.id)
    if not T.part then return false, "this car has no part " .. T.d.id end
    if not getPlayerMechanicsUI(S.pn) then return false, "the game's mechanics window is not made" end
    T.how = "the game's own part menu"
    return true
end
function H.partMake(T, x, y)
    local ui = getPlayerMechanicsUI(S.pn)
    ui.vehicle, ui.chr = S.car, S.p
    ui:doPartContextMenu(T.part, x - ui:getAbsoluteX(), y - ui:getAbsoluteY())
    return ui.context
end
function H.carAway()
    if not S.car then return end
    ZEDQA_CAR_AWAY(S.car, S.carKey)
    S.car, S.carKey = nil, nil
end

-- the hen (on the farm field only): the game's own animal menu on a fresh menu
function H.animalPrep(T)
    if not S.hen then return false, "no hen is on the farm field (see the farm lines above)" end
    T.obj, T.how = S.hen, "the game's own animal menu"
    return true
end
function H.animalMake(T, x, y)
    local ctx = ISContextMenu.get(S.pn, x, y)
    AnimalContextMenu.doMenu(S.pn, ctx, T.obj, false)
    return ctx
end
function H.henAway()
    local h = S.hen
    S.hen = nil
    if h and not S.henGone then S.henGone = true; h:remove() end
end

-- everything this script put on the drag strip, taken away (called again at the put-back: each part runs once)
function H.cleanStrip()
    H.closeMenu()
    local ok, err = pcall(H.bodyAway)
    if not ok then Q.say("NOTE the corpse's removal threw: " .. tostring(err)) end
    for _, e in ipairs(S.placed) do
        local okP, errP = pcall(H.unplace, e)
        if not okP then Q.say("NOTE removing the placed " .. tostring(e.key) .. " threw: " .. tostring(errP)) end
    end
    H.carAway()
end

-- ===================================================================== a thing gone while its menu is open
function H.vanishSeq(what, getT, style, gone, still)
    local lbl = what .. " gone while its menu is open"
    step(2, function()
        S.live = false
        local T = getT()
        if not T then S.noOpen = true; Q.skip(lbl, "it could not be staged"); return end
        if not H.ready(T) then S.noOpen = true; Q.skip(lbl, "its thing was not staged (said above)"); return end
        H.opt():setValue(style)
        local x, y = H.spot()
        H.open(T, x, y)
    end)
    waitFor(1, 90, H.opened, function()
        if S.noOpen then return end
        local m = H.menu()
        if not m then Q.skip(lbl, "no menu opened on it" .. (S.openErr and (": " .. S.openErr) or "")); return end
        S.live = true
        H.wrap(m)
        H.mouseOn(-9000, -9000)
        local ok, err = pcall(gone)
        if not ok then Q.check(false, lbl .. ": it is taken away without an error", tostring(err)) end
    end)
    step(6, function()
        if not S.live then return end
        if still then S.W = { m = H.menu(), n = 0, bad = {}, noIcon = {}, subs = 0, deep = 1, stack = {}, done = true }
        else H.walkStart(lbl) end
    end)
    waitFor(1, 320, function() return not S.live or H.walkTick() end, function()
        if not S.live then return end
        local W = S.W
        local m = H.menu()
        Q.check(m ~= nil and m._ctx.open and #W.bad == 0 and not S.drawErr,
            lbl .. ": the menu still draws" .. (still and "" or " and every row answers") .. ", no error", H.walkWords(W))
    end)
    step(1, function() H.closeMenu() end)
    step(1, function()
        if S.live then H.afterClose(lbl) end
        S.live = false
    end)
end

-- ===================================================================== edges: where the menu and its submenus land
function H.richT()
    local best = nil
    for _, d in ipairs(S.INV) do
        local T = S.T[d.key]
        if T and T.ok and not d.multi and ((not best) or (T.subs or 0) > (best.subs or 0)
            or ((T.subs or 0) == (best.subs or 0) and (T.rows or 0) > (best.rows or 0))) then best = T end
    end
    return best
end
function H.bigT()
    local best = nil
    for _, d in ipairs(S.INV) do
        local T = S.T[d.key]
        if T and T.ok and not d.multi and ((not best) or (T.rows or 0) > (best.rows or 0)) then best = T end
    end
    return best
end
function H.parentRows(m, cap)
    local out = {}
    local lv = m._levels[1]
    for ri, r in ipairs(lv and lv.rows or {}) do
        if #out < cap and r.def and H.kids(m, r.def) > 0 and not H.off(m, r.def) then out[#out + 1] = ri end
    end
    return out
end
function H.liveRows(lv, cap)
    local out = {}
    for ri, r in ipairs(lv and lv.rows or {}) do
        if #out < cap and r.def and not r.def.heading then out[#out + 1] = ri end
    end
    return out
end
-- the list: a resting pointer opens a row's submenu; every row of the submenu hovered keeps it open and selects it
function H.hoverNext(V, m)
    V.pi = V.pi + 1
    if V.pi > #V.parents then V.done = true; return end
    while #m._levels > 1 do m:cancel() end
    local ri = V.parents[V.pi]
    local z = H.zoneOf(m, "row:1:" .. ri)
    if not z then H.note(V, "noz" .. ri, "row " .. ri .. " of the list has no place this frame"); return end
    V.pr = ri
    V.prevDef = nil
    H.point(m, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    V.t0 = getTimestampMs()
    V.phase = "rest"
end
function H.hoverRest(V, m)
    m:update()
    local name = tostring(m._levels[1].rows[V.pr].def.name)
    if m._levels[2] then
        if m._levels[2].parentRow ~= V.pr then H.note(V, "wrong" .. V.pr, "the submenu that opened is not " .. name .. "'s") end
        V.sub = m._levels[2]
        V.opened = V.opened + 1
        V.phase = V.force and "lay" or "rows"
        V.rowsOf = nil
    elseif getTimestampMs() - V.t0 > 1500 then
        H.note(V, "rest" .. V.pr, "the pointer rested 1.5 s on " .. name .. " and its submenu did not open")
        V.phase = "next"
    end
end
-- (the submenu laid over its parent, as a narrow screen places it)
function H.hoverLay(V, m)
    local sw, sh = H.scr()
    local top, sub = m._levels[1], V.sub
    sub.x = math.max(8, math.min(top.x + math.floor(top.w * 0.3), sw - 8 - sub.w))
    sub.y = math.max(8, math.min(top.y + math.floor(ZeD.T.px(10)), sh - 8 - sub.h))
    V.phase = "rows"
end
function H.hoverRows(V, m)
    local top, sub = m._levels[1], V.sub
    if V.prevDef and m._hlDef ~= V.prevDef then
        H.note(V, "light", "the lit option is " .. tostring(m._hlDef and m._hlDef.name) .. " while the pointer is on " .. tostring(V.prevDef.name))
    end
    if not V.rowsOf then
        V.rowsOf, V.ri = H.liveRows(sub, 4), 0
        H.listOnScreen(V, m)
        return   -- (one frame: the submenu's rows get their places)
    end
    V.ri = V.ri + 1
    if V.ri > #V.rowsOf then V.phase = "next"; return end
    local ri = V.rowsOf[V.ri]
    local z = H.zoneOf(m, "row:2:" .. ri)
    if not z then H.note(V, "nosub" .. ri, "row " .. ri .. " of a submenu has no place"); return end
    local ox0, ox1 = math.max(top.x, sub.x), math.min(top.x + top.w, sub.x + sub.w)
    local px = (ox1 > ox0 + 4) and math.floor((ox0 + ox1) / 2) or (z.x + math.floor(z.w / 2))
    local py = z.y + math.floor(z.h / 2)
    local inParent = px >= top.x and px < top.x + top.w and py >= top.y and py < top.y + top.h
    H.point(m, px, py)
    V.rows = V.rows + 1
    if inParent then V.over = V.over + 1 end
    local name = tostring(sub.rows[ri].def.name)
    if m._levels[2] ~= sub then
        H.note(V, "reset" .. V.pr, "hovering " .. name .. (inParent and " (drawn over its parent)" or "") .. " closed or reset the submenu: " .. #m._levels .. " levels")
        V.phase = "next"
        return
    end
    if sub.sel ~= ri then H.note(V, "subsel" .. V.pr, "the pointer on " .. name .. " selects row " .. tostring(sub.sel) .. ", not " .. ri) end
    if top.sel ~= V.pr then H.note(V, "topsel" .. V.pr, "the pointer on " .. name .. (inParent and " (over its parent)" or "") .. " moved the parent's selection to row " .. tostring(top.sel)) end
    V.prevDef = sub.rows[ri].def
end
-- the strip: a cell with a submenu hovered and clicked, Escape back, a right-click on the strip closes it
function H.stripCell(V, m)
    local c = m._layoutCache
    local N = #m._ctx.items
    for _, z in ipairs(m._hitZones or {}) do
        local k = type(z.id) == "string" and z.id:sub(1, 8) == "ctxcell_" and tonumber(z.id:sub(9))
        if k and not V.cell and z.x >= c.stripX and z.x + z.w <= c.stripX + c.stripW then
            local idx = H.mod(k - 1, N) + 1
            local def = m._ctx.items[idx]
            if H.kids(m, def) > 0 and not H.off(m, def) then V.cell, V.idx = z, idx end
        end
    end
    if not V.cell then V.phase = "rc"; return end
    local z = V.cell
    V.lx, V.ly = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    H.point(m, m:getAbsoluteX() + V.lx, m:getAbsoluteY() + V.ly)
    -- (a strip the pad holds does not follow the pointer: ZeD_ContextMenu:update, "never while the pad has the menu",
    -- beast W14. The pad holds it when the game has a pad on this player, JoypadState, as a Deck has: then the hover
    -- is said not checked, once, and the click below still is)
    if m._joyfocus then
        if not S.joyHoverSaid then
            S.joyHoverSaid = true
            Q.say("NOTE strip: the pad holds the strip (the game has a pad on this player), so the pointer takes no cell by design (W14); the hover is not checked here, the click is")
        end
    elseif m._ctx.selected ~= V.idx then
        H.note(V, "hover", "the pointer on cell " .. V.idx .. " selects cell " .. tostring(m._ctx.selected))
    end
    V.phase = "click"
end
function H.stripClick(V, m)
    -- The cell found a frame ago must still be under the spot. (Nov 21 2026, the first run: a strip of 11 or more
    -- slid on its own as it opened, sweep W15, another cell came under the resting pointer and the click ran that
    -- cell's action and closed the menu. No click is made on a cell that moved: it would run something.)
    local z0 = m:hitZoneAt(V.lx, V.ly)
    local k0 = z0 and type(z0.id) == "string" and z0.id:sub(1, 8) == "ctxcell_" and tonumber(z0.id:sub(9))
    local now = k0 and (H.mod(k0 - 1, #m._ctx.items) + 1) or nil
    if now ~= V.idx then
        H.note(V, "slid", "the strip moved under a resting pointer between two frames: cell " .. V.idx .. " was there, now " .. tostring(now and ("cell " .. now) or "no cell") .. " (no click made)")
        V.phase = "rc"
        return
    end
    m:onMouseDown(V.lx, V.ly)
    m:onMouseUp(V.lx, V.ly)
    H.mouseOn(-9000, -9000)
    if #m._ctx.path ~= 1 or not m._ctx.open then H.note(V, "click", "a click on a cell with a submenu did not open it") else V.opened = V.opened + 1 end
    V.phase = "sub"
end
function H.stripSub(V, m)
    H.stripOnScreen(V, m)
    if #m._ctx.path > 0 then
        m:onKeyPress(Keyboard.KEY_ESCAPE)
        if #m._ctx.path ~= 0 or not m._ctx.open then H.note(V, "esc", "Escape in a submenu did not step back to the top") end
    end
    V.phase = "rc"
end
function H.stripRc(V, m)
    H.stripOnScreen(V, m)
    V.flipped = m._flipped
    m:onRightMouseDown(5, 5)
    if m._ctx.open then H.note(V, "rc", "a right-click on the open strip did not close it") end
    V.done = true
end
function H.edgeStep(V, m)
    if V.strip then
        if V.phase == "cell" then H.stripCell(V, m)
        elseif V.phase == "click" then H.stripClick(V, m)
        elseif V.phase == "sub" then H.stripSub(V, m)
        else H.stripRc(V, m) end
        return
    end
    if V.phase == "next" then H.hoverNext(V, m)
    elseif V.phase == "rest" then H.hoverRest(V, m)
    elseif V.phase == "lay" then H.hoverLay(V, m)
    else H.hoverRows(V, m) end
end
function H.edgeBegin()
    local m = H.menu()
    local V = S.E
    V.m, V.opened, V.rows, V.over, V.pi = m, 0, 0, 0, 0
    if not m then V.done = true; return end
    if m._levels then
        V.phase = "next"
        V.parents = H.parentRows(m, V.force and 1 or 2)
        H.listOnScreen(V, m)
    else
        V.strip, V.phase = true, "cell"
        H.stripOnScreen(V, m)
    end
end
function H.edgeTick()
    local V = S.E
    if not V or V.done then return true end
    local m = V.m
    if V.strip and V.phase == "rc" and not m._ctx.open then V.done = true; return true end
    if H.menu() ~= m or not m._ctx.open then V.bad[#V.bad + 1] = "the menu closed in the middle (" .. tostring(V.phase) .. ")"; V.done = true; return true end
    if S.drawErr then V.done = true; return true end
    local ok, err = pcall(H.edgeStep, V, m)
    if not ok then V.bad[#V.bad + 1] = "it threw (" .. tostring(V.phase) .. "): " .. tostring(err); V.done = true end
    return V.done == true
end
function H.edgeEnd()
    local V = S.E
    local d
    if V.strip then
        d = (V.flipped and "the strip under the pointer, its balloon below" or "the strip over the pointer, its balloon above")
            .. ((V.m and V.m._zedGuessIdx) and " (opened on its best guess: that cell on the pointer)" or "")
            .. ", " .. V.opened .. " submenu opened by a click"
    else
        d = V.opened .. " submenus opened by a resting pointer, " .. V.rows .. " submenu rows hovered, " .. V.over .. " of them over the parent"
    end
    if S.drawErr then d = d .. "; " .. S.drawErr end
    if #V.bad > 0 then d = d .. "; " .. H.join(V.bad, 5) end
    Q.check(#V.bad == 0 and not S.drawErr, V.lbl .. ": all on screen, its submenus open and stay open under the pointer", d)
    if not V.strip and not V.force and V.ai == 1 and #(V.parents or {}) == 0 then
        Q.skip("list: a submenu opened by a resting pointer", "this menu has no row with a submenu")
    end
end
function H.edgeSeq(style, ai, force)
    step(2, function()
        S.live = false
        local T = H.richT()
        if not T then S.noOpen = true; return end
        local x, y, nm = H.anchor(ai)
        S.E = { bad = {}, ai = ai, force = force,
                lbl = ((style == 2) and "list" or "strip") .. " opened at " .. nm .. (force and ", its submenu laid over it" or "") }
        H.opt():setValue(style)
        H.open(T, x, y)
    end)
    waitFor(1, 90, H.opened, function()
        if S.noOpen then return end
        local m = H.menu()
        if not m then Q.check(false, S.E.lbl .. ": ZeD's menu opens", tostring(S.openErr)); return end
        S.live = true
        H.wrap(m)
    end)
    step(3, function() if S.live then H.edgeBegin() end end)
    waitFor(1, 600, function() return not S.live or H.edgeTick() end, function() end)
    step(2, function()
        if S.live then H.edgeEnd() end
        H.closeMenu()
    end)
    step(1, function()
        if S.live then H.afterClose(S.E.lbl) end
        S.live = false
    end)
end

-- ===================================================================== 30 quick right-clicks
function H.quickOpen(K, x, y)
    K.n = K.n + 1
    K.T = K.list[H.mod(K.n, #K.list) + 1]
    H.mouseOn(x, y)
    K.T.make(K.T, x, y)
end
function H.quickGot(K, m)
    K.opened = K.opened + 1
    if K.w > K.maxWait then K.maxWait = K.w end
    local want = (K.style == 2) and "ZeD_ContextList" or "ZeD_ContextMenu"
    if m.Type ~= want then K.bad[#K.bad + 1] = "click " .. K.i .. ": " .. tostring(m.Type) .. " with the setting on " .. want end
    if m._ctx.target ~= K.T.target and not (K.T.world and m._ctx.target == nil) then
        K.bad[#K.bad + 1] = "click " .. K.i .. ": the menu is not on the last thing clicked (" .. K.T.label .. ")"
    end
    -- every sixth: a second right-click somewhere else while this one is up
    if H.mod(K.i, 6) == 3 and not K.old then
        K.old = m
        local x, y = H.anchor(H.mod(K.i, 9) + 1)
        H.quickOpen(K, x, y)
        K.w = 0
        return
    end
    K.phase = "close"
end
-- a spot on screen that no level of the list covers (a corner), or nil: a click on a row would run its action
function H.offList(m)
    local sw, sh = H.scr()
    for _, c in ipairs({ { 2, 2 }, { sw - 3, 2 }, { 2, sh - 3 }, { sw - 3, sh - 3 }, { math.floor(sw / 2), 2 }, { math.floor(sw / 2), sh - 3 } }) do
        if m:_levelAt(c[1], c[2]) == nil then return c[1], c[2] end
    end
    return nil
end
function H.quickClose(K)
    local m = H.menu()
    if K.old then
        if K.old._ctx.open then K.bad[#K.bad + 1] = "click " .. K.i .. ": the first menu stayed open under the second" end
        K.old = nil
    end
    if m then
        local how = H.mod(K.i, 5)
        if how == 0 then m:close()
        elseif how == 1 then m:onRightMouseDown(1, 1)
        elseif how == 2 then m:onKeyPress(Keyboard.KEY_ESCAPE)
        elseif how == 3 then
            if m._levels then
                -- (the list's panel is the whole screen, ZeD_ContextList:new: "a click outside closes" is a left
                -- click off its rows, there is no press outside the panel; Nov 21 2026, the first run asked the
                -- list for the strip's onMouseDownOutside and it stayed open)
                local ox, oy = H.offList(m)
                if ox then
                    m:onMouseDown(ox, oy)
                    m:onMouseUp(ox, oy)
                else
                    K.bad[#K.bad + 1] = "click " .. K.i .. ": every probe spot lies on the list (no click made)"
                    m:close()
                end
            else
                m:onMouseDownOutside(-5, -5)
            end
        else m:cancel() end
        if m._ctx.open then K.bad[#K.bad + 1] = "click " .. K.i .. ": the menu did not close (way " .. how .. ")" end
    end
    local v = H.vmenu()
    if not m and v and v.closeAll and v:isVisible() then v:closeAll() end
    H.mouseOff()
    K.phase = "verify"
end
function H.quickStep(K)
    if K.phase == "open" then
        K.i = K.i + 1
        if K.i > 30 then K.done = true; return end
        K.style = H.mod(K.i, 2) + 1
        H.opt():setValue(K.style)
        local x, y = H.anchor(H.mod(K.i * 4, 9) + 1)
        H.quickOpen(K, x, y)
        -- every fifth: two right-clicks in the same frame
        if H.mod(K.i, 5) == 0 then H.quickOpen(K, H.spot()) end
        K.w, K.phase = 0, "wait"
    elseif K.phase == "wait" then
        K.w = K.w + 1
        local m = H.menu()
        if m and m ~= K.old then H.quickGot(K, m)
        elseif K.w > 40 then
            K.bad[#K.bad + 1] = "click " .. K.i .. ": no menu after 40 frames"
            K.phase = "close"
        end
    elseif K.phase == "close" then
        H.quickClose(K)
    else
        local n = H.menuRoots()
        if H.menu() ~= nil or n ~= S.rootsBase then K.bad[#K.bad + 1] = "click " .. K.i .. ": " .. n .. " ZeD menus on screen after the close" end
        K.phase = "open"
    end
end
function H.quickBegin()
    H.closeMenu()
    local K = { i = 0, n = 0, phase = "open", bad = {}, maxWait = 0, opened = 0, list = {} }
    for _, k in ipairs({ "food", "ground", "tool", "bag", "crate" }) do
        local T = S.T[k]
        if T and T.ok and (T.rows or 0) > 0 then K.list[#K.list + 1] = T end   -- (the things whose menus opened in the walks)
    end
    if #K.list == 0 then K.done = true end
    S.K = K
end
function H.quickTick()
    local K = S.K
    if K.done then return true end
    local ok, err = pcall(H.quickStep, K)
    if not ok then K.bad[#K.bad + 1] = "click " .. K.i .. " threw: " .. tostring(err); K.done = true end
    return K.done == true
end

-- ===================================================================== keys, pad, random presses, the wheel
function H.firstParent(m)
    for i, def in ipairs(m._ctx.items or {}) do
        if H.kids(m, def) > 0 and not H.off(m, def) then return i end
    end
    return nil
end
function H.stripTop(m)
    while #m._ctx.path > 0 and m._ctx.open do m:cancel() end
    m._ctx.selected = 1
    m:_rebuildTrack()
end
function H.stripKeys()
    local m = H.menu()
    if not (m and not m._levels and m._ctx.open) then Q.check(false, "strip, keys: the strip is open for the keys"); return end
    local c = m._ctx
    H.stripTop(m)
    local N = #c.items
    m:onKeyPress(Keyboard.KEY_LEFT)
    local a = c.selected
    m:onKeyPress(Keyboard.KEY_RIGHT)
    Q.check(N > 1 and a == N and c.selected == 1, "strip, keys: Left from the first cell wraps to the last, Right comes back", "1 -> " .. tostring(a) .. " -> " .. tostring(c.selected) .. " of " .. N)
    Q.check(m:isKeyConsumed(Keyboard.KEY_ESCAPE) and m:isKeyConsumed(Keyboard.KEY_RETURN) and m:isKeyConsumed(Keyboard.KEY_LEFT) and not m:isKeyConsumed(Keyboard.KEY_W),
        "strip, keys: the strip takes its own keys (Escape, Return, arrows) and leaves W to the game")
    m:onKeyPress(Keyboard.KEY_W)
    Q.check(c.selected == 1 and c.open, "strip, keys: a key the strip does not use changes nothing")
    local pi = H.firstParent(m)
    if not pi then Q.skip("strip, keys: Return opens a submenu, Escape steps back", "this menu has no submenu"); return end
    c.selected = pi
    m:_rebuildTrack()
    m:onKeyPress(Keyboard.KEY_RETURN)
    local d1 = #c.path
    m:onKeyPress(Keyboard.KEY_ESCAPE)
    Q.check(d1 == 1 and #c.path == 0 and c.selected == pi and c.open, "strip, keys: Return opens the submenu, Escape steps back to its cell",
        "depth " .. d1 .. " -> " .. #c.path .. ", cell " .. tostring(c.selected) .. " (was " .. pi .. ")")
end
function H.stripPadKeys()
    local m = H.menu()
    if not (m and not m._levels and m._ctx.open) then Q.check(false, "strip, pad: the strip is open for the pad"); return end
    local c = m._ctx
    H.stripTop(m)
    local N = #c.items
    for _ = 1, N do m:onJoypadDirRight() end
    local round = c.selected
    m:onJoypadDirLeft()
    local last = c.selected
    m:onJoypadDirUp()
    m:onJoypadDirDown()
    Q.check(round == 1 and last == N and c.selected == N and c.open, "strip, pad: D-pad Right through all " .. N .. " cells comes round to the first, Left wraps to the last, Up and Down do nothing",
        tostring(round) .. ", " .. tostring(last) .. ", " .. tostring(c.selected))
    local pi = H.firstParent(m)
    if not pi then Q.skip("strip, pad: A opens a submenu, B steps back", "this menu has no submenu"); return end
    c.selected = pi
    m:_rebuildTrack()
    m:onJoypadDown(Joypad.AButton)
    local d1 = #c.path
    m:onJoypadDown(Joypad.XButton)
    m:onJoypadDown(Joypad.YButton)
    local dx = #c.path
    m:onJoypadDown(Joypad.BButton)
    Q.check(d1 == 1 and dx == 1 and #c.path == 0 and c.selected == pi and c.open, "strip, pad: A opens the submenu, X and Y do nothing, B steps back to its cell",
        "depth " .. d1 .. " -> " .. dx .. " -> " .. #c.path)
end
function H.listTop(m)
    while #m._levels > 1 do m:cancel() end
    local lv = m._levels[1]
    lv.sel = m:_firstLive(lv, 1, 1)
    return lv
end
function H.listKeys()
    local m = H.menu()
    if not (m and m._levels and m._ctx.open) then Q.check(false, "list, keys: the list is open for the keys"); return end
    local lv = H.listTop(m)
    local first, last = lv.sel, m:_firstLive(lv, #lv.rows, -1)
    m:onKeyPress(Keyboard.KEY_UP)
    local a = lv.sel
    m:onKeyPress(Keyboard.KEY_DOWN)
    Q.check(a == last and lv.sel == first and m._nav == "key", "list, keys: Up from the first row wraps to the last, Down comes back; the keys hold the selection",
        tostring(first) .. " -> " .. tostring(a) .. " -> " .. tostring(lv.sel) .. ", nav " .. tostring(m._nav))
    m:onMouseWheel(1)
    local w1 = lv.sel
    m:onMouseWheel(-1)
    Q.check(w1 ~= first and lv.sel == first, "list: a wheel notch moves the selection a row, a notch back returns", tostring(first) .. " -> " .. tostring(w1) .. " -> " .. tostring(lv.sel))
    Q.check(m:isKeyConsumed(Keyboard.KEY_ESCAPE) and m:isKeyConsumed(Keyboard.KEY_UP) and not m:isKeyConsumed(Keyboard.KEY_W), "list, keys: the list takes its own keys and leaves W to the game")
    local pr = H.parentRows(m, 1)[1]
    if not pr then Q.skip("list, keys: Right and Return open a submenu, Left and Escape close it", "this menu has no submenu"); return end
    lv.sel = pr
    m:onKeyPress(Keyboard.KEY_RIGHT)
    local l1, s1 = #m._levels, m._levels[2] and m._levels[2].sel
    m:onKeyPress(Keyboard.KEY_LEFT)
    local l2 = #m._levels
    m:onKeyPress(Keyboard.KEY_RETURN)
    local l3 = #m._levels
    m:onKeyPress(Keyboard.KEY_ESCAPE)
    Q.check(l1 == 2 and s1 ~= nil and l2 == 1 and l3 == 2 and #m._levels == 1 and lv.sel == pr and m._ctx.open,
        "list, keys: Right opens the submenu on its first row, Left closes it; Return opens it, Escape closes it; the menu stays",
        l1 .. ", " .. l2 .. ", " .. l3 .. ", " .. #m._levels)
end
function H.listPadKeys()
    local m = H.menu()
    if not (m and m._levels and m._ctx.open) then Q.check(false, "list, pad: the list is open for the pad"); return end
    local lv = H.listTop(m)
    local first, last = lv.sel, m:_firstLive(lv, #lv.rows, -1)
    local n = H.liveCount(lv)
    for _ = 1, n do m:onJoypadDirDown() end
    local round = lv.sel
    m:onJoypadDirUp()
    Q.check(round == first and lv.sel == last and m._nav == "pad", "list, pad: D-pad Down through all " .. n .. " rows comes round to the first, Up wraps to the last",
        tostring(round) .. ", " .. tostring(lv.sel) .. ", nav " .. tostring(m._nav))
    local pr = H.parentRows(m, 1)[1]
    if not pr then Q.skip("list, pad: A opens a submenu, B closes it", "this menu has no submenu"); S.padRow = nil; return end
    lv.sel = pr
    m:onJoypadDown(Joypad.AButton)
    local l1, s1 = #m._levels, m._levels[2] and m._levels[2].sel
    m:onJoypadDown(Joypad.BButton)
    Q.check(l1 == 2 and s1 ~= nil and #m._levels == 1 and lv.sel == pr and m._ctx.open, "list, pad: A opens the submenu on its first row, B closes it", l1 .. " -> " .. #m._levels)
    -- the pad's row for the balloon next: D-pad Down to the first row with words to show, once round at most
    -- (Nov 21 2026, the first run: one step down landed on Place Item, which has none, and the balloon went unchecked)
    for _ = 1, math.max(1, n) do
        m:onJoypadDirDown()
        local r = lv.rows[lv.sel]
        if r and H.rowWords(m, r.def) then break end
    end
    -- (the balloon's last place is QA's read-only mark, Balloon.lua: cleared so the check reads this balloon, not an older one)
    pcall(function() if ZeD.Balloon then ZeD.Balloon.lastPlace = nil end end)
end
-- the words a list row shows in its balloon (ZeD_ContextList:prerender makes a balloon only for these)
function H.rowWords(m, def)
    if type(def) ~= "table" then return false end
    if (def.body and def.body ~= "") or def.bodyRich then return true end
    if not def.state then return false end
    local ok, st = pcall(def.state, m._ctx.target)
    return ok and type(st) == "string" and st ~= ""
end
-- the list's balloon for the pad's row: beside it, on screen
function H.listBalloon()
    local m = H.menu()
    local lv = m and m._levels and m._levels[1]
    if not (lv and lv.sel) then return end
    local def = lv.rows[lv.sel] and lv.rows[lv.sel].def
    if not H.rowWords(m, def) then Q.skip("list, pad: the balloon for the pad's row sits on screen", "no top row of this menu has words to show (the pad is on " .. tostring(def and def.name) .. ")"); return end
    local pl = ZeD.Balloon and ZeD.Balloon.lastPlace
    local sw, sh = H.scr()
    Q.check(m._bl ~= nil and m._bl.def == def and pl ~= nil and pl.x >= -1 and pl.y >= -1 and pl.x < sw and pl.y < sh,
        "list, pad: the balloon for the pad's row is up, its corner on screen", pl and (H.fl(pl.x) .. "," .. H.fl(pl.y)) or "no balloon placed")
end
function H.stripOp(m, k)
    local c = m._ctx
    if k == 0 then m:next() elseif k == 1 then m:prev() elseif k == 2 then m:nextPage() elseif k == 3 then m:prevPage()
    elseif k == 4 then m:nextGroup() elseif k == 5 then m:prevGroup() elseif k == 6 then m:onMouseWheel(1) elseif k == 7 then m:onMouseWheel(-1)
    elseif k == 8 then
        local def = c.items[c.selected]
        if #c.path < 3 and H.kids(m, def) > 0 and not H.off(m, def) then m:confirm() end
    elseif k == 9 then
        if #c.path > 0 then m:cancel() end
    elseif k == 10 then m:onKeyPress(Keyboard.KEY_TAB)
    else m:onJoypadDown(Joypad.RBumper) end
end
function H.stripInv(m)
    local c = m._ctx
    local N = #(c.items or {})
    if not c.open then return "the strip closed" end
    if N == 0 then return "no cells left" end
    if type(c.selected) ~= "number" or c.selected < 1 or c.selected > N or c.selected ~= math.floor(c.selected) then return "the selection is cell " .. tostring(c.selected) .. " of " .. N end
    if c.items[c.selected] == nil then return "no option at the selection" end
    return nil
end
function H.listOp(m, k)
    if k <= 1 then m:onKeyPress(Keyboard.KEY_DOWN) elseif k <= 3 then m:onKeyPress(Keyboard.KEY_UP)
    elseif k == 4 then m:onKeyPress(Keyboard.KEY_RIGHT) elseif k == 5 then m:onKeyPress(Keyboard.KEY_LEFT)
    elseif k == 6 then m:onMouseWheel(1) elseif k == 7 then m:onMouseWheel(-1)
    elseif k == 8 then m:onJoypadDirRight() elseif k == 9 then m:onJoypadDirLeft()
    elseif k == 10 then
        if #m._levels > 1 then m:onKeyPress(Keyboard.KEY_ESCAPE) end
    else
        local lv = m._levels[#m._levels]
        local r = lv and lv.sel and lv.rows[lv.sel]
        if r and r.def and H.kids(m, r.def) > 0 and not H.off(m, r.def) then m:onKeyPress(Keyboard.KEY_RETURN) end
    end
end
function H.listInv(m)
    if not m._ctx.open then return "the list closed" end
    if #m._levels < 1 then return "no level left" end
    for li, lv in ipairs(m._levels) do
        if lv.sel ~= nil then
            local r = lv.rows[lv.sel]
            if not (r and r.def and not r.def.heading) then return "level " .. li .. ": the selection (" .. tostring(lv.sel) .. ") is not a row" end
        end
        if li > 1 and m._levels[li - 1].sel ~= lv.parentRow then
            return "submenu " .. li .. " hangs off row " .. tostring(lv.parentRow) .. " while its parent's selection is row " .. tostring(m._levels[li - 1].sel)
        end
    end
    return nil
end
-- 300 presses, 25 a frame for 12 frames, the state checked after every one
function H.stressTick()
    local m = H.menu()
    local X = S.X
    if not m or X.bad or X.f >= 12 then return true end
    X.f = X.f + 1
    local ok, err = pcall(function()
        for _ = 1, 25 do
            local k = H.rnd(12)
            X.n = X.n + 1
            if m._levels then H.listOp(m, k) else H.stripOp(m, k) end
            -- (Nov 21 2026, the first run: "a and f() or g()" ran the strip's test on a healthy list, whose nil answer
            -- fell through to it, and failed press 1 with "no cells left"; each look has its own test)
            local why
            if m._levels then why = H.listInv(m) else why = H.stripInv(m) end
            if why then X.bad = "press " .. X.n .. " (kind " .. k .. "): " .. why; return end
        end
    end)
    if not ok then X.bad = "press " .. X.n .. " threw: " .. tostring(err) end
    return X.bad ~= nil
end
function H.cellsShown(m)
    local c = m._layoutCache
    local n = 0
    for _, z in ipairs(m._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 8) == "ctxcell_" and z.x + z.w > c.stripX + 1 and z.x < c.stripX + c.stripW - 1 then n = n + 1 end
    end
    return n
end
function H.stressEnd(sname)
    local m = H.menu()
    local X = S.X
    local d = X.n .. " presses"
    if X.bad then d = d .. "; " .. X.bad end
    if S.drawErr then d = d .. "; " .. S.drawErr end
    local settled = true
    if m and not m._levels and m._ctx.open then
        local c = m._ctx
        local N = #c.items
        local V = math.min(N, ZeD.T.ctx.maxVisible)
        local shown = H.cellsShown(m)
        if c.truncating then settled = c.pos >= N + 1 and c.pos <= 2 * N and shown >= V else settled = shown >= V end
        d = d .. "; at rest " .. shown .. " cells show of " .. V .. ", carousel place " .. tostring(c.pos) .. " of " .. N
    end
    Q.check(m ~= nil and not X.bad and not S.drawErr and settled, sname .. ": 300 random presses (keys, pad, wheel, pages, groups, submenus in and out) leave the menu whole", d)
end
-- the wheel turned a notch a frame for 45 frames, then let go, once down and once up (the strip scrolls a looping
-- track of three copies). Each spin is watched from its third frame until half a second after its last notch, when
-- the strip is at rest. (Nov 21 2026, the second run's review: the count used to stop 3 frames after the last notch.
-- The committed code's blank strip comes later: after the wheel the strip slides on past the end of its track and
-- shows no cells until the settle, from about 50 to 250 ms after the last notch, so the check passed on that code at
-- the 64 and 90 frames a second of these runs. A wheel rolled up runs off the other end of the track: both ways turn.)
S.SPIN_N, S.SPIN_REST = 45, 500
function H.spinStart(m, dir)
    H.stripTop(m)
    return { dir = dir, f = 0, min = 999 }
end
function H.spinTick()
    local m = H.menu()
    local B = S.B
    if not (m and not m._levels and m._ctx.open) or S.drawErr then return true end
    if not m._ctx.truncating then B.skip = true; return true end
    local R = B[#B]
    R.f = R.f + 1
    if R.f > 2 then
        local n = H.cellsShown(m)
        if n < R.min then
            R.min, R.at, R.pos = n, R.f, m._ctx.pos
            R.after = (R.f > S.SPIN_N) and (getTimestampMs() - R.lastMs) or nil
            -- how far the drawn strip is from the place it is sliding to, in cells (Nov 21 2026, the second run: a
            -- notch every drawn frame restarts the slide each frame, so the view stands still while the place runs on,
            -- and each trip round the track then carries the still view a whole copy further out: 0 of 10 cells)
            local stepW = ZeD.T.ctx.cellW + ZeD.T.ctx.gap
            if stepW > 0 then R.lag = ((m._animToOriginX or 0) - (m._currentOriginX or 0)) / stepW end
        end
    end
    if R.f <= S.SPIN_N then
        m:onMouseWheel(R.dir)
        R.lastMs = getTimestampMs()
        return false
    end
    if R.f < S.SPIN_N + 3 or getTimestampMs() - R.lastMs < S.SPIN_REST then return false end
    -- half a second after the last notch: the strip at rest; then the same spin up
    R.restShown, R.restPos = H.cellsShown(m), m._ctx.pos
    if #B < 2 then B[#B + 1] = H.spinStart(m, -1); return false end
    return true
end
function H.spinWords(R, V)
    if not (R and R.at) then return "not spun" end
    return "fewest cells in the strip's box " .. R.min .. " of " .. V .. " (frame " .. R.at .. " of the spin, "
        .. (R.after and ("about " .. R.after .. " ms after the last notch") or "while it turned") .. ", carousel place " .. tostring(R.pos)
        .. (R.lag and string.format(", the drawn strip %.1f cells from where it is sliding to", R.lag) or "") .. ")"
end
function H.restWords(R, V, N)
    if not (R and R.restShown) then return "not read (the spin did not come to rest in the frames allowed)" end
    return R.restShown .. " cells of " .. V .. ", carousel place " .. tostring(R.restPos) .. " of " .. N
end
function H.spinEnd()
    local m = H.menu()
    local B = S.B
    local what = "strip: the wheel spun a notch a frame for 45 frames, down and then up, never leaves cells missing from the strip, while it turns or comes to rest"
    if B.skip then Q.skip(what, "this menu fits the strip (10 cells or fewer), nothing scrolls"); return end
    if not (m and m._ctx.open) then Q.check(false, "strip: the strip is still open after the wheel"); return end
    local N = #m._ctx.items
    local V = math.min(N, ZeD.T.ctx.maxVisible)
    local down, up = B[1], B[2]
    Q.check(down ~= nil and up ~= nil and down.at ~= nil and up.at ~= nil and down.min >= V and up.min >= V and not S.drawErr, what,
        "down: " .. H.spinWords(down, V) .. "; up: " .. H.spinWords(up, V) .. "; its track holds " .. (3 * N) .. " cells" .. (S.drawErr and ("; " .. S.drawErr) or ""))
    local okD = down ~= nil and down.restShown ~= nil and down.restShown >= V and down.restPos >= N + 1 and down.restPos <= 2 * N
    local okU = up ~= nil and up.restShown ~= nil and up.restShown >= V and up.restPos >= N + 1 and up.restPos <= 2 * N
    Q.check(okD and okU, "strip: half a second after the wheel stops the strip is whole again",
        "down: " .. H.restWords(down, V, N) .. "; up: " .. H.restWords(up, V, N))
end
function H.keySeq(style)
    local sname = (style == 2) and "list" or "strip"
    step(2, function()
        S.live = false
        local T = H.bigT()
        if not T then S.noOpen = true; return end
        H.opt():setValue(style)
        local x, y = H.anchor(1)
        H.open(T, x, y)
    end)
    waitFor(1, 90, H.opened, function()
        if S.noOpen then return end
        local m = H.menu()
        if not m then Q.check(false, sname .. ", keys: ZeD's menu opens", tostring(S.openErr)); return end
        S.live = true
        H.wrap(m)
        H.mouseOn(-9000, -9000)
    end)
    step(3, function()
        if not S.live then return end
        if style == 2 then H.listKeys() else H.stripKeys() end
        S.X = { f = 0, n = 0 }
    end)
    waitFor(1, 40, function() return not S.live or H.stressTick() end, function() end)
    Q.waitMs(450)
    step(2, function() if S.live then H.stressEnd(sname) end end)
    if style == 1 then
        -- (the spin down, then the spin up, in one wait: each runs about 45 frames and half a second)
        step(1, function() if S.live and H.menu() then S.B = { H.spinStart(H.menu(), 1) } end end)
        waitFor(2, 900, function() return not S.live or not S.B or H.spinTick() end, function() if S.live and S.B then H.spinEnd() end end)
        step(2, function() if S.live then H.stripPadKeys() end end)
    else
        step(2, function() if S.live then H.listPadKeys() end end)
        step(4, function() if S.live then H.listBalloon() end end)
    end
    step(2, function()
        if not S.live then return end
        local m = H.menu()
        if not m then Q.check(false, sname .. ": the menu is still open at the end of the keys"); return end
        for _ = 1, 6 do if m._ctx.open then m:onKeyPress(Keyboard.KEY_ESCAPE) end end
        Q.check(not m._ctx.open and not S.drawErr, sname .. ", keys: Escape, level by level, closes the menu", tostring(S.drawErr or ""))
        H.closeMenu()
    end)
    step(1, function()
        if S.live then H.afterClose(sname .. " after the keys") end
        S.live = false
    end)
end

-- ===================================================================== menus opened by the pad
function H.padLock(on)
    local Dt = ZeD.Input and ZeD.Input.Detector
    if not Dt then return false end
    if on then
        Dt.setLockedMode("gamepad")
        S.padLocked = true
    elseif S.padLocked then
        S.padLocked = nil
        Dt.setLockedMode("kbm")
    end
    return true
end
function H.padSeq(style, world)
    local lbl = ((style == 2) and "list" or "strip") .. " opened by the pad on " .. (world and "the ground" or "an item")
    step(3, function()
        S.live = false
        local T = world and S.T.ground or S.T.tool
        if not (T and T.ok and H.padLock(true)) then Q.skip(lbl, "the thing or ZeD's input detector is not there"); return end
        H.closeMenu()
        H.opt():setValue(style)
        S.live = true
        S.openErr, S.noOpen = nil, false
        H.mouseOn(-9000, -9000)   -- (the pad's menu takes no place from the pointer; the real one must not hover a cell)
        -- (the pad's own calls: X on a row asks at 0, 0, ZeD finds the place; the world's menu opens at the character)
        local ok, err
        if world then ok, err = pcall(ISContextManager.getInstance().createWorldMenu, S.pn, nil, T.target, 0, 0)
        else ok, err = pcall(ISInventoryPaneContextMenu.createMenu, S.pn, true, T.target, 0, 0) end
        if not ok then S.openErr = tostring(err) end
    end)
    waitFor(1, 90, function() return not S.live or H.opened() end, function()
        if not S.live then return end
        local m = H.menu()
        if not m then Q.check(false, lbl .. ": ZeD's menu opens", tostring(S.openErr)); S.live = false; return end
        H.wrap(m)
        S.padV = { bad = {} }
    end)
    step(4, function()
        if not S.live then return end
        local m = H.menu()
        if not m then Q.check(false, lbl .. ": the menu stays open"); S.live = false; return end
        if m._levels then H.listOnScreen(S.padV, m) else H.stripOnScreen(S.padV, m) end
        -- (smart menu, c6dafe460, Nov 24 2026: an item menu opens on its best guess, m._zedGuessIdx, the def's index in
        -- the top level's items; without a guess, the first live row as before. ZeD_ContextList open, ZeD_ContextMenu:open)
        local first
        if m._levels then
            local L1 = m._levels[1]
            local want = m:_firstLive(L1, 1, 1)
            local gDef = m._zedGuessIdx and L1.items and L1.items[m._zedGuessIdx]
            if gDef then for ri, r in ipairs(L1.rows or {}) do if r.def == gDef then want = ri; break end end end
            first = L1.sel == want and m._nav == "pad"
        else
            first = m._ctx.selected == (m._zedGuessIdx or 1)
        end
        Q.check(#S.padV.bad == 0 and first and not S.drawErr, lbl .. ": on screen, the first row (or the menu's best guess, "
            .. tostring(m._zedGuessRule or "none") .. ") marked for the pad",
            "anchor " .. tostring(m.anchorMode) .. " at " .. H.fl(m._anchorX) .. "," .. H.fl(m._anchorY) .. ((#S.padV.bad > 0) and ("; " .. H.join(S.padV.bad, 3)) or "") .. (S.drawErr and ("; " .. S.drawErr) or ""))
        RT.bounds(Q, lbl)
        m:onJoypadDown(Joypad.BButton)
        Q.check(not m._ctx.open, lbl .. ": B closes it")
        H.closeMenu()
    end)
    step(1, function()
        if S.live then H.afterClose(lbl) end
        S.live = false
        H.padLock(false)
    end)
end

-- ===================================================================== the bag list's row (the real right-click, a drag)
function H.reveal(c, item)
    local s = c and c._scroll
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not (s and y) then return end
    if S.scroll[c] == nil then S.scroll[c] = s.scrollPos or 0 end
    if not (s.visible and s.barSizeRatio and s.barSizeRatio > 0 and s.barSizeRatio < 1) then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    s:setScrollPos(math.max(0, math.min(1, (logical - math.floor(vis / 3)) / range)))
end
function H.rowSpot()
    local D = S.dg
    local z = D and H.zoneOf(D.c, D.item)
    if not z then return false end
    D.x, D.y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    D.sx, D.sy = D.c:getAbsoluteX() + D.x, D.c:getAbsoluteY() + D.y
    return true
end
function H.hasItem(m, item)
    for _, t in ipairs((m and type(m._ctx.target) == "table") and m._ctx.target or {}) do if t == item then return true end end
    return false
end
function H.dragStart(D, x, y)
    D.c._drag:beginPending({ D.item }, D.item, x, y)
    D.c._drag:checkThreshold(x + ZeD.T.px(30), y + ZeD.T.px(30))
    return D.c._drag:isActive() and ISMouseDrag.dragging ~= nil
end
function H.dragOff(D) return not D.c._drag:isActive() and not D.c._drag:isPending() and ISMouseDrag.dragging == nil end

-- ===================================================================== THE RUN: setup
Q.step(1, function()
    if not S.p or S.p:isDead() then Q.check(false, "the character is alive for the run"); S.dead = true; return end
    -- nothing may hurt him: a zombie is made for the corpse, he stands in the open for minutes and goes to the farm.
    -- God mode and invincible are on for the whole run, and put back as found after the healed check at the end.
    pcall(function() S.godWas = S.p:isGodMod() end)
    pcall(function() S.invWas = S.p:isInvincible() end)
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    S.guard = true
    Q.say("safety: god mode " .. tostring(S.p:isGodMod()) .. ", invincible " .. tostring(S.p:isInvincible()) .. " for the run (found " .. tostring(S.godWas) .. ", " .. tostring(S.invWas) .. ")")
    if ZeD.Safe and ZeD.Safe.on() then Q.skip("the whole script", "safe mode is on: the menus are the game's own"); S.dead = true; return end
    if not Q.check(H.opt() ~= nil and ZeD.ContextMenu ~= nil and ZeD.ContextMenu.Registry ~= nil, "ZeD's Context menu setting and its registry are there") then S.dead = true; return end
    if ZEDQA_HOME then ZEDQA_HOME("bx_ctx") end
    S.home = { x = S.p:getX(), y = S.p:getY() }
    S.styleWas = H.opt():getValue()
    S.ph, S.sh = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    S.inv0 = S.p:getInventory():getItems():size()
    S.speedWas = getGameSpeed()
    S.pairWas = RT.isOpen()
    H.closeMenu()
    S.rootsBase = H.menuRoots()
    local md = S.p:getModData().ZeD_Gamepad
    S.lockWas = md and md.inputModeLock
    if ZeD.Input and ZeD.Input.Detector then ZeD.Input.Detector.setLockedMode("kbm") end   -- (these right-clicks are the mouse's)
    RT.pairOpen()
end)
step(30, function()
    local cw = RT.cw()
    if not Q.check(cw ~= nil and H.cc() ~= nil, "the Character window is open") then S.dead = true; return end
    S.tabWas = cw._activeTab
    RT.charTab("loot")
    local c = H.cc()
    if c and c._scroll then S.scroll[c] = c._scroll.scrollPos or 0 end
    -- the car first: its spot is the helper's pick, the placed things then keep clear of it
    if ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_AWAY then
        ZEDQA_CAR_WAIT("Base.CarNormal", "bx_ctx", function(v)
            S.car = v
            S.carKey = ZEDQA_CAR_PREP(v)
            S.carDone = true
        end, function(why) S.carWhy = why; S.carDone = true end)
    else
        S.carWhy, S.carDone = "the prelude's car helpers are not loaded", true
    end
end)
waitFor(2, 2400, function() return S.carDone end, function(ok)
    if not ok then S.carWhy = "the car helper did not answer in time" end
    Q.say("car: " .. (S.car and "a car stands ready on the strip" or ("none (" .. tostring(S.carWhy) .. ")")))
    H.scan()
end)

-- ===================================================================== 1. every item kind, both styles
for _, d in ipairs(S.INV) do
    local T = { d = d, label = d.label, prep = H.invPrep, make = H.invMake }
    S.T[d.key] = T
    H.seq(T, 1)
    H.seq(T, 2)
end

-- ===================================================================== 2. world objects, both styles
for _, d in ipairs(S.WORLD) do
    local T = { d = d, label = d.label, prep = H.worldPrep, make = H.worldMake }
    S.T[d.key] = T
    H.seq(T, 1)
    H.seq(T, 2)
end
S.T.corpse = { d = { key = "corpse" }, label = "a corpse", prep = H.corpsePrep, make = H.corpseMake, after = H.corpseAfter }
H.seq(S.T.corpse, 1)
H.seq(S.T.corpse, 2)
for _, d in ipairs(S.PARTS) do
    local T = { d = d, label = d.label, prep = H.partPrep, make = H.partMake }
    S.T["part" .. d.id] = T
    H.seq(T, 1)
    H.seq(T, 2)
end
step(2, function()
    local hd = S.heads
    if hd.n == 0 then Q.skip("world menus: the list's heading names what was clicked", "no world menu opened as a list"); return end
    Q.check(#hd.bad == 0, "world menus: the list's heading names what was clicked (" .. hd.n .. " menus)",
        (#hd.bad > 0) and H.join(hd.bad, 8) or tostring(hd.ok))
end)

-- ===================================================================== 3. gone while the menu is open
S.T.vcrate = { d = { key = "crate" }, label = "a second crate (to be destroyed)", make = H.worldMake, prep = function(T)
    local o = H.place("crate")
    if not o then return false, "a crate could not be placed" end
    T.obj, T.world, T.target = o, true, { o }
    return true
end }
H.vanishSeq("a crate", function() return S.T.vcrate end, 2, function()
    for _, e in ipairs(S.placed) do if e.o == S.T.vcrate.obj then H.unplace(e) end end
end)
H.vanishSeq("a corpse", function() return S.T.corpse.ok and S.body and S.T.corpse or nil end, 1, function() H.bodyAway() end)
H.vanishSeq("the car", function() return S.car and S.T.partEngine or nil end, 2, function() H.carAway() end)
Q.waitMs(400)   -- (the car leaves two ticks after it is asked to)
S.T.vapple = { d = {}, label = "a second apple (to be taken away)", make = H.invMake, prep = function(T)
    T.item = RT.give("Base.Apple")
    if not T.item then return false, "no apple could be given" end
    T.target = { T.item }
    return true
end }
H.vanishSeq("an item", function() return S.T.vapple end, 1, function() S.p:getInventory():Remove(S.T.vapple.item) end)

-- ===================================================================== 4. every corner and edge, both styles
for ai = 1, #S.ANCH do
    H.edgeSeq(1, ai, false)
    H.edgeSeq(2, ai, false)
end
H.edgeSeq(2, 1, true)

-- ===================================================================== 5. 30 quick right-clicks
step(2, function() H.quickBegin() end)
waitFor(1, 1500, function() return H.quickTick() end, function(ok)
    local K = S.K
    H.closeMenu()
    if #K.list == 0 then Q.skip("30 quick right-clicks", "nothing was staged to click"); return end
    Q.check(ok and #K.bad == 0 and K.opened >= 30, "30 quick right-clicks (items and world, both styles, two in one frame, a second click over an open menu, five ways to close): each opened the right menu and closed clean",
        K.opened .. " menus opened, the slowest " .. K.maxWait .. " frames after its click" .. ((#K.bad > 0) and ("; " .. H.join(K.bad, 6)) or ""))
end)

-- ===================================================================== 6. keys, pad, random presses, the wheel
H.keySeq(1)
H.keySeq(2)

-- ===================================================================== 7. menus opened by the pad
H.padSeq(1, false)
H.padSeq(2, false)
H.padSeq(1, true)
H.padSeq(2, true)

-- ===================================================================== 8. a right-click during a timed action
step(4, function()
    local T = S.T.tool
    S.ta = false
    if not (T and T.ok and T.item) then Q.skip("a right-click during a timed action", "no tool was given"); return end
    S.ta = true
    ISTimedActionQueue.add(ISEquipWeaponAction:new(S.p, T.item, 600, true, false))
end)
step(4, function()
    if not S.ta then return end
    if H.queueEmpty() then S.ta = false; Q.skip("a right-click during a timed action", "the equip action ended at once (instant actions are on)"); return end
    H.opt():setValue(2)
    local x, y = H.spot()
    H.open(S.T.tool, x, y)
end)
waitFor(1, 90, function() return not S.ta or H.opened() end, function()
    if not S.ta then return end
    local m = H.menu()
    Q.check(m ~= nil and H.hasItem(m, S.T.tool.item) and not H.queueEmpty(), "timed action: a right-click on the tool being equipped opens its menu, and the action goes on",
        "menu " .. tostring(m and m.Type) .. ", action running " .. tostring(not H.queueEmpty()) .. (S.openErr and ("; " .. S.openErr) or ""))
    if m then H.wrap(m); H.tree(S.T.tool, m, "timed action, the tool's menu") end
    RT.bounds(Q, "the menu opened during a timed action")
end)
step(3, function()
    if not S.ta then return end
    local T2 = S.T.food
    if not (T2 and T2.ok) then return end
    H.opt():setValue(1)
    local x, y = H.spot()
    H.open(T2, x, y)
end)
waitFor(1, 90, function() return not S.ta or H.opened() end, function()
    if not S.ta then return end
    local m = H.menu()
    local T2 = S.T.food
    if not (T2 and T2.ok) then return end
    Q.check(m ~= nil and m.Type == "ZeD_ContextMenu" and H.hasItem(m, T2.item) and not H.queueEmpty(),
        "timed action: a second right-click on other food mid-action swaps the menu (the strip now), the action still goes on",
        "menu " .. tostring(m and m.Type) .. ", action running " .. tostring(not H.queueEmpty()))
    if m then H.wrap(m) end
end)
step(2, function()
    if not S.ta then return end
    ISTimedActionQueue.clear(S.p)   -- (the action interrupted while the menu is up)
end)
step(4, function()
    if not S.ta then return end
    local m = H.menu()
    Q.check(m ~= nil and m._ctx.open and H.queueEmpty() and not S.drawErr, "timed action: the action cancelled while the menu is up leaves the menu open and drawing",
        tostring(S.drawErr or ""))
    H.closeMenu()
end)
step(1, function()
    if S.ta then H.afterClose("timed action") end
    S.ta = false
end)

-- ===================================================================== 9. the bag list's row: a right-click, then during a drag
step(4, function()
    S.dg = nil
    local c, T = H.cc(), S.T.tool
    if not (c and c._drag and T and T.ok and T.item) then Q.skip("a right-click on the bag list's row, and while dragging", "the bag list or the tool is not there"); return end
    H.opt():setValue(2)
    RT.charTab("loot")
    S.dg = { c = c, item = T.item }
    H.reveal(c, T.item)
end)
step(8, function()
    local D = S.dg
    if not D then return end
    if not H.rowSpot() then Q.skip("a right-click on the bag list's row, and while dragging", "the tool's row is not drawn in the bag list"); S.dg = nil; return end
    H.mouseOn(D.sx, D.sy)
    D.c:onRightMouseDown(D.x, D.y)
    D.c:onRightMouseUp(D.x, D.y)
end)
waitFor(1, 60, function() return S.dg == nil or H.menu() ~= nil end, function(ok)
    local D = S.dg
    if not D then return end
    local m = H.menu()
    Q.check(ok and H.hasItem(m, D.item) and m.Type == "ZeD_ContextList", "bag list: a right-click on the tool's row opens ZeD's list on the tool", tostring(m and m.Type))
    if m then H.wrap(m) end
    RT.bounds(Q, "the menu from the row's right-click")
    H.closeMenu()
end)
step(4, function()
    local D = S.dg
    if not D then return end
    if not H.rowSpot() then S.dg = nil; return end
    H.mouseOn(D.sx, D.sy)
    if not Q.check(H.dragStart(D, D.sx, D.sy), "drag: a drag of the tool is under way (the list's own drag state, past its threshold)") then
        D.c._drag:cancel()
        H.mouseOff()
        S.dg = nil
        return
    end
    D.c:onRightMouseDown(D.x, D.y)
    D.c:onRightMouseUp(D.x, D.y)
    Q.check(H.dragOff(D), "drag: a right-click during the drag cancels the drag, nothing left on the pointer")
end)
waitFor(1, 30, function() return S.dg == nil or H.menu() ~= nil end, function()
    local D = S.dg
    if not D then return end
    local m = H.menu()
    Q.say("NOTE drag: that same right-click " .. (m and "also opened the item's menu" or "opened no menu (the click only cancels the drag)"))
    if m then
        H.wrap(m)
        Q.check(H.hasItem(m, D.item) and not S.drawErr, "drag: the menu that right-click opened is the dragged tool's", tostring(S.drawErr or ""))
        RT.bounds(Q, "the menu opened by a right-click during a drag")
    end
end)
step(3, function()
    local D = S.dg
    if not D then return end
    -- a drag begun with the menu still up, then a right-click outside the window
    local on = H.dragStart(D, D.sx, D.sy)
    D.c:onRightMouseDownOutside(-5, -5)
    Q.check(on and H.dragOff(D), "drag: a right-click outside the window cancels a drag too")
    H.closeMenu()
end)
step(2, function()
    if S.dg then H.afterClose("the bag list's row") end
    S.dg = nil
end)

-- ===================================================================== 10. walking away closes the menu
step(3, function()
    local T = S.T.ground
    S.wo = false
    if not (T and T.ok) then Q.skip("walking away closes the menu", "no ground target"); return end
    S.wo = true
    H.opt():setValue(2)
    local x, y = H.spot()
    H.open(T, x, y)
end)
waitFor(1, 90, function() return not S.wo or H.opened() end, function()
    if not S.wo then return end
    S.woM = H.menu()
    if not S.woM then S.wo = false; Q.skip("walking away closes the menu", "no menu opened on the ground"); return end
    H.stand(S.home.x - 1.5, S.home.y - 1.9)   -- (2.4 squares off: more than the two the menu allows)
end)
waitFor(1, 90, function() return not S.wo or H.menu() == nil end, function(ok)
    if not S.wo then return end
    Q.check(ok and S.woM._ctx.open == false, "walk off: the menu closes once the character is more than two squares from where it opened")
    H.stand(S.home.x, S.home.y)
    H.closeMenu()
    S.wo = false
end)
step(2, function()
    Q.check(#S.closeBad == 0, "every menu closed clean so far: nothing left on screen, the game's menu let go (" .. S.menus .. " menus)", H.join(S.closeBad, 6))
    S.closeSaid = #S.closeBad
end)

-- ===================================================================== 11. the farm field: a hen
step(4, function()
    S.farm = nil
    if getTimestampMs() - Q.t0 > 330000 then Q.skip("an animal's menu (a hen on the farm field)", "the run is near its time limit"); return end
    if not (addAnimal and AnimalDefinitions and AnimalContextMenu) then Q.skip("an animal's menu (a hen on the farm field)", "the game's animal functions are not there"); return end
    H.cleanStrip()   -- (nothing of this script stays on the strip while the character is away)
    S.farm = { x = 1635.5, y = 14221.5 }
end)
Q.waitMs(300)
step(2, function()
    if S.farm then H.stand(S.farm.x, S.farm.y) end
end)
waitFor(150, 900, function()
    return not S.farm or (getCell():getGridSquare(math.floor(S.farm.x), math.floor(S.farm.y), 0) ~= nil and S.p:getCurrentSquare() ~= nil)
end, function(ok)
    if not S.farm then return end
    if not ok then Q.skip("an animal's menu (a hen on the farm field)", "the farm field did not load in time"); return end
    local sq = H.freeSq()
    if not sq then Q.skip("an animal's menu (a hen on the farm field)", "no open square beside the character on the field"); return end
    local breed = AnimalDefinitions.getDef("hen"):getBreeds():get(0)
    S.hen = addAnimal(getCell(), sq:getX(), sq:getY(), 0, "hen", breed)
    if S.hen then S.hen:addToWorld() end
    S.henGone = false
    Q.say("farm: a hen " .. (S.hen and "stands two squares from the character" or "could not be made"))
end)
S.T.animal = { d = { key = "animal" }, label = "an animal (a hen)", prep = H.animalPrep, make = H.animalMake }
step(20, function() if not S.hen then S.T.animal.ok = false end end)
H.seq(S.T.animal, 1)
H.seq(S.T.animal, 2)
H.vanishSeq("an animal", function() return S.hen and S.T.animal.ok and S.T.animal or nil end, 2, function() H.henAway() end, true)
step(2, function()
    if not S.farm then return end
    local ok, err = pcall(H.henAway)
    if not ok then Q.say("NOTE the hen's removal threw: " .. tostring(err)) end
end)

-- ===================================================================== put back
Q.mark()
-- healed first, in a step of its own: nothing before or after it in the put-back can stop it
Q.step(1, function() H.heal() end)
Q.step(2, function()
    if not S.home then return end
    -- (each part on its own: one that throws does not stop the rest)
    H.try("closing the menu", H.closeMenu)
    H.try("the pointer", H.mouseOff)
    H.try("the menu's watch", H.unwrap)
    pcall(H.henAway)
    H.try("clearing the strip", H.cleanStrip)
    pcall(function() local c = H.cc(); if c and c._drag then c._drag:cancel() end end)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    H.try("the pad lock", function()
        H.padLock(false)
        local Dt = ZeD.Input and ZeD.Input.Detector
        if Dt then
            Dt.setLockedMode(nil)
            if S.lockWas == "kbm" or S.lockWas == "gamepad" then Dt.setLockedMode(S.lockWas) end
        end
    end)
    H.try("the Context menu setting", function() if S.styleWas ~= nil then H.opt():setValue(S.styleWas) end end)
    pcall(function() S.p:setPrimaryHandItem(S.ph) end)
    pcall(function() S.p:setSecondaryHandItem(S.sh) end)
    pcall(function() if getGameSpeed() ~= S.speedWas and ZEDQA_SPEED then ZEDQA_SPEED(S.speedWas) end end)
    H.try("the way home", function() H.stand(S.home.x, S.home.y) end)
    H.try("taking the given things back", RT.takeBack)
end)
Q.waitFor(20, 1200, function()
    return not S.home or (S.p:getCurrentSquare() ~= nil and getCell():getGridSquare(math.floor(S.home.x), math.floor(S.home.y), 0) ~= nil)
end, function(ok)
    if not S.home then return end
    Q.check(ok and math.abs(S.p:getX() - S.home.x) < 0.6 and math.abs(S.p:getY() - S.home.y) < 0.6, "the character is back on the home square, the strip loaded",
        H.fl(S.p:getX()) .. "," .. H.fl(S.p:getY()))
    H.heal()
    local c = H.cc()
    if c then
        local sel = c._selectedItems or {}
        for k in pairs(sel) do sel[k] = nil end
        c._lastClickedItem = nil
        local w = RT.cw()
        if w and w._updateDrawer then pcall(w._updateDrawer, c) end
    end
end)
Q.step(10, function()
    if not S.home then return end
    for c, pos in pairs(S.scroll) do pcall(function() c._scroll:setScrollPos(pos) end) end
    if S.tabWas and S.tabWas ~= "loot" then RT.charTab(S.tabWas) end
    local left = {}
    for k, e in pairs(S.sqN) do
        local sq = getCell():getGridSquare(e.x, e.y, 0)
        local n = sq and sq:getObjects():size() or e.n
        if n ~= e.n then left[#left + 1] = k .. " holds " .. n .. " objects (" .. e.n .. " before)" end
    end
    Q.check(#left == 0, "every placed object is off its square (" .. #S.placed .. " placed)", table.concat(left, "; "))
    Q.check(S.car == nil and S.body == nil and S.hen == nil, "the car, the corpse and the hen are gone")
    Q.check(H.opt():getValue() == S.styleWas, "the Context menu setting is back as it was", tostring(H.opt():getValue()))
    Q.check(S.p:getPrimaryHandItem() == S.ph and S.p:getSecondaryHandItem() == S.sh, "the hands hold what they held")
    local n = S.p:getInventory():getItems():size()
    Q.check(n == S.inv0, "the bag holds as many things as before", n .. " now, " .. tostring(S.inv0) .. " before")
    Q.check(H.menu() == nil and H.menuRoots() == S.rootsBase and not S.mouseSwapped and H.queueEmpty(), "no menu is left open, the pointer is the game's again, no action is queued",
        H.menuRoots() .. " ZeD menus on screen")
    if #S.closeBad > (S.closeSaid or 0) then Q.check(false, "every menu closed clean to the end", H.join(S.closeBad, 6)) end
    RT.bounds(Q, "the end")
end)
Q.step(10, function()
    if S.pairWas == false then RT.pairShut() end
end)
-- the last word: he is alive and healed (said even when the run never got past its first step), then god mode and
-- invincible go back as found
Q.step(4, function()
    if not S.p then Q.check(false, "put back: the character is alive and healed", "no character"); return end
    H.heal()
    local bad = H.hurt()
    Q.check(#bad == 0, "put back: the character is alive and healed (health 100, no wound or fracture on any part, not infected)",
        (#bad == 0) and ("health " .. tostring(S.hp)) or H.join(bad, 8))
    if not S.guard then return end
    S.guard = nil
    if #bad > 0 then
        Q.say("NOTE god mode and invincible are left ON: the character is not healed")
        return
    end
    if S.godWas ~= nil then pcall(function() S.p:setGodMod(S.godWas and true or false) end) end
    if S.invWas ~= nil then pcall(function() S.p:setInvincible(S.invWas and true or false) end) end
    Q.check((S.godWas == nil or S.p:isGodMod() == (S.godWas and true or false)) and (S.invWas == nil or S.p:isInvincible() == (S.invWas and true or false)),
        "put back: god mode and invincible as found", "god mode " .. tostring(S.p:isGodMod()) .. ", invincible " .. tostring(S.p:isInvincible()))
end)
Q.start()
