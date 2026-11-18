-- ZeDUI/tools/qa/rt_kit.lua  (Nov 18 2026, QA): the shared kit of the ZeD release test (release_test.txt).
-- The director, Nov 18 2026: "We're not releasing the next beta until you build a new test." The old main run grew
-- one feature at a time since October and 26 of its 85 scripts checked nothing (pictures only). This test is new:
--   * every check prints PASS or FAIL, and ANY FAIL makes the script's own last line "ZEDQA <tag> VERDICT FAIL n",
--     which zedqa_run.ps1 scores as a FAIL (a FAIL line used to score only as a warning);
--   * no pictures (the gallery runs take pictures), and nothing tests a window the game draws itself;
--   * every script checks what ZeD ships, the way a player reaches it (mouse, and the pad where ZeD has a pad path);
--   * RT.bounds(Q, label) measures every ZeD window, card and pop-up on screen: each must sit fully inside the
--     screen (4K and a true 1280x800 Deck window).
-- Run it first in release_test.txt (after zedqa_prelude.lua). It only defines the global RT. grep "ZEDQA rtk".
--
-- A script:
--   local Q = RT.make("rt_inv")               -- tag (unique in the manifest)
--   Q.step(n, fn)                             -- after n drawn frames, run fn once
--   Q.waitFor(n, max, cond, fn)               -- after n frames, every frame until cond() (at most max), then fn(ok)
--   Q.waitMs(ms)                              -- real time
--   Q.check(ok, what, detail)                 -- PASS / FAIL line; a FAIL is counted
--   Q.skip(what, why)                         -- a check that cannot run here, said plainly (not a FAIL)
--   Q.mark()                                  -- the put-back starts here (a run too long jumps to it)
--   Q.start()                                 -- adds the verdict and DONE, starts the queue
-- Helpers: RT.cw(), RT.ww(), RT.pairOpen(), RT.charTab(id), RT.worldTab(id), RT.tabs(win) (the tab ids on a strip),
-- RT.pad(button, state) / RT.padDir(dir, w) / RT.padDown(Joypad.AButton, w) through FocusManager, RT.give(ft) / RT.takeBack() (things given are taken
-- back at the end), RT.bounds(Q, label), RT.find(pred) (a visible UI root whose lua table passes pred).

RT = RT or {}
RT.p = getPlayer()
RT.pn = RT.p and RT.p:getPlayerNum() or 0
RT.core = getCore()
RT.given = RT.given or {}
local function say(s) print("ZEDQA rtk " .. tostring(s)) end

-- ===================================================================== the queue
function RT.make(tag)
    local Q = { tag = tag, list = {}, qi = 1, wait = nil, t0 = getTimestampMs(), maxMs = 1200000, pass = 0, fail = 0, skips = 0, v = {} }
    function Q.say(s) print("ZEDQA " .. Q.tag .. " " .. tostring(s)) end
    function Q.step(n, fn) Q.list[#Q.list + 1] = { n = n, fn = fn } end
    function Q.waitFor(n, max, cond, fn) Q.list[#Q.list + 1] = { n = n, fn = fn, cond = cond, max = max } end
    function Q.waitMs(ms)
        local st = {}
        Q.waitFor(1, math.floor(ms / 3) + 900, function()
            st.t = st.t or getTimestampMs()
            return getTimestampMs() - st.t >= ms
        end, function() end)
    end
    function Q.check(ok, what, detail)
        if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
        Q.say((ok and "PASS " or "FAIL ") .. tostring(what) .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
        return ok and true or false
    end
    function Q.skip(what, why) Q.skips = Q.skips + 1; Q.say("SKIP " .. tostring(what) .. " (" .. tostring(why) .. ")") end
    function Q.mark() Q.backAt = #Q.list + 1 end
    function Q.tick()
        local s = Q.list[Q.qi]
        if not s then Events.OnPreUIDraw.Remove(Q.tick); return end
        if Q.backAt and Q.qi < Q.backAt and getTimestampMs() - Q.t0 > Q.maxMs then
            Q.check(false, "the script finished in time", "jumped to the put-back at step " .. Q.qi)
            Q.qi, Q.wait = Q.backAt, nil
            return
        end
        if not s.started then
            Q.wait = (Q.wait or s.n) - 1
            if Q.wait > 0 then return end
            Q.wait = nil
            s.started = true
        end
        local res = true
        if s.cond then
            s.left = (s.left or s.max) - 1
            local okc, done = pcall(s.cond)
            res = (okc and done) and true or false
            if not res and s.left > 0 then return end
        end
        Q.qi = Q.qi + 1
        local ok, err = pcall(s.fn, res)
        if not ok then Q.check(false, "step " .. (Q.qi - 1) .. " ran without an error", tostring(err)) end
    end
    function Q.start()
        Q.step(2, function() RT.takeBack() end)
        Q.step(2, function()
            Q.say(string.format("end: %d pass, %d fail, %d skipped", Q.pass, Q.fail, Q.skips))
            -- (zedqa_run.ps1 scores "VERDICT FAIL" as the script's FAIL)
            Q.say(Q.fail > 0 and ("VERDICT FAIL " .. Q.fail) or ("VERDICT PASS " .. Q.pass))
            Q.say("DONE")
        end)
        Events.OnPreUIDraw.Add(Q.tick)
        Q.say("start (" .. #Q.list .. " steps)")
    end
    return Q
end

-- ===================================================================== windows and tabs
function RT.cw() local w = nil; pcall(function() w = ZeD_CharacterWindow.getWindow(RT.pn) end); return w end
function RT.ww() local w = nil; pcall(function() w = ZeD_WorldWindow.getWindow(RT.pn) end); return w end
function RT.isOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(RT.pn) end); return o end
function RT.pairOpen() if not RT.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, RT.pn) end end
function RT.pairShut() if RT.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, RT.pn) end end
function RT.charStrip() local w = RT.cw(); return w and w._tabStripPanel end
function RT.worldStrip() local w = RT.ww(); return w and w._actionTabStrip end
-- the tab ids a strip offers now (its hit zones "tab:<id>")
function RT.tabs(strip)
    local out = {}
    for _, z in ipairs(strip and strip._hitZones or {}) do
        local id = type(z.id) == "string" and z.id:match("^tab:(.+)$")
        if id then out[#out + 1] = id end
    end
    return out
end
-- a tab pressed through the strip's own mouse handler (as a click does)
function RT.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and win._drawerOpen == false) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function RT.charTab(id) local w = RT.cw(); return (w and RT.goTab(w, w._tabStripPanel, id)) and true or false end
function RT.worldTab(id) local w = RT.ww(); return (w and RT.goTab(w, w._actionTabStrip, id)) and true or false end

-- ===================================================================== the pad (FocusManager's own presses)
-- the pad's buttons through FocusManager's QA hook: state true (down), false (up), nil (the hook let go). Press one
-- over a few frames: Q.step(1, RT.pad("A", true)) ... Q.step(4, RT.pad("A", false)) ... Q.step(4, RT.pad("A", nil)).
function RT.focus() return ZeD and ZeD.Input and ZeD.Input.Focus or nil end
function RT.pad(button, state)
    local F = RT.focus()
    if not (F and F.qaButton) then return false end
    return pcall(F.qaButton, button, state, RT.pn) and true or false
end
-- a D-pad step on window w (default: the Character window) through FocusManager's own dispatch
function RT.padDir(dir, w)
    local F = RT.focus()
    w = w or RT.cw()
    if not (F and F.dispatchJoypadDir and w) then return false end
    return pcall(F.dispatchJoypadDir, w, dir) and true or false
end
function RT.padDown(button, w)
    local F = RT.focus()
    w = w or RT.cw()
    if not (F and F.dispatchJoypadDown and w) then return false end
    return pcall(F.dispatchJoypadDown, w, button) and true or false
end

-- ===================================================================== things
function RT.give(ft)
    local it = nil
    pcall(function() it = RT.p:getInventory():AddItem(ft) end)
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        RT.given[#RT.given + 1] = it
    end
    return it
end
function RT.takeBack()
    for _, it in ipairs(RT.given) do
        pcall(function() if RT.p:getPrimaryHandItem() == it then RT.p:setPrimaryHandItem(nil) end end)
        pcall(function() if RT.p:getSecondaryHandItem() == it then RT.p:setSecondaryHandItem(nil) end end)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    RT.given = {}
end

-- ===================================================================== on screen
-- is a UI root ZeD's? its lua table's Type or class name says ZeD, or ZeD marked it
function RT.isZeD(t)
    if type(t) ~= "table" then return false end
    if t._zed or t.zed or t._zedOwned then return true end
    local ty = tostring(t.Type or "")
    return ty:find("ZeD", 1, true) ~= nil or ty:find("Zed", 1, true) ~= nil
end
function RT.roots()
    local out = {}
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            local t = nil
            pcall(function() t = e:getTable() end)
            out[#out + 1] = { e = e, t = t }
        end
    end)
    return out
end
function RT.find(pred)
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and r.t and pred(r.t, r.e) then return r.t, r.e end
    end
    return nil
end
-- every visible ZeD root fully on screen (1 px slack); a full-screen layer is skipped
function RT.bounds(Q, label)
    local W, H = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    local seen, bad = 0, {}
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and RT.isZeD(r.t) then
            local x, y, w, h = r.e:getX(), r.e:getY(), r.e:getWidth(), r.e:getHeight()
            if w > 2 and h > 2 and not (w >= W - 2 and h >= H - 2) then
                seen = seen + 1
                if x < -1 or y < -1 or x + w > W + 1 or y + h > H + 1 then
                    bad[#bad + 1] = string.format("%s %d,%d %dx%d", tostring(r.t.Type), math.floor(x), math.floor(y), math.floor(w), math.floor(h))
                end
            end
        end
    end
    return Q.check(#bad == 0, "on screen (" .. tostring(label) .. "): every ZeD window and pop-up inside " .. W .. "x" .. H,
        (#bad == 0) and (seen .. " seen") or table.concat(bad, "; "))
end

say("kit ready: player " .. tostring(RT.pn) .. ", screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight())
-- (Nov 18 2026, the first run: a DONE printed while the chunk still loads comes before the bridge's "run #n ok=true"
-- line, and the runner does not count it; so DONE waits for the next drawn frame)
local function doneLater()
    Events.OnPreUIDraw.Remove(doneLater)
    say("DONE")
end
Events.OnPreUIDraw.Add(doneLater)
