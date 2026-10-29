-- ZeDUI/tools/qa/perf_now.lua  (Oct 29 2026)
-- The Oct 22 performance measurements (perf_bench_prof, perf_census, perf_bench_uie,
-- perf_bench_zed's frame recorder) on WHATEVER scene is loaded: no GAL, no gallery staging.
-- Meant for the ZeD-QA save after zedqa_prelude.lua (both windows open, a stocked character).
-- Eight scenes, in order: hud (both windows shut), pair_loot (both on Loot), card (item card
-- open on the first item of the main inventory), maps (World on Maps), craft (World on Craft),
-- health, skills, equip (Character on that tab, World on Loot).
-- Each scene: set up, wait 60 frames to settle (the windows widen for a moment after a tab
-- change), then three passes, each with only its own wrappers on so one does not skew another:
--   1. FRAME  600 frames, nothing wrapped: the scene's whole frame time
--             "FRAME|<scene>|frames=N|avgMs=X|p95=Y|worst=Z" (OnRenderTick getTimestampMs deltas)
--   2. TIMING 600 frames, prerender / render / update wrapped with getTimestampMs timers:
--             hud      = "UIE|..." every top-level element the Java UIManager holds, 16 costliest
--             the rest = "PROF|..." every element of both window trees, 14 costliest
--             (ms per frame, inclusive of what the function draws; wrappers are taken off after)
--   3. CENSUS 240 frames, ISUIElement draw calls and ZeD.TM measures counted (exact counts, they
--             do not depend on the clock): "CEN|..." calls per frame by element class, in TWO
--             buckets: LEAN (the ZeD classes' own copies in Overrides/TextScale.lua, ZeD.LeanDraw)
--             and UIE (ISUIElement's, and any class that holds a raw copy of it)
-- The whole run is about 12,000 frames: about 3.5 minutes at 60 fps, 8 at 25 fps.
-- At the end both windows are back on Loot, the card closed, the windows open.
-- Run: manifest "zedqa_prelude.lua | pre" then "perf_now.lua | pnow | timeout=600" (raise the
-- timeout to 900 if the game runs under 25 fps). By hand: both windows open, game unpaused,
-- copy to Lua/zedqa.lua and bump Lua/zedqa.go. grep "ZEDQA pnow". Ends "ZEDQA pnow DONE".

local TAG = "pnow"
-- every output line starts "ZEDQA pnow " (the runner finds a script's lines by that prefix)
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local function bail(msg) say("ERR " .. msg); say("DONE") end

local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
if not (ZeD and CWm and WWm) then bail("ZeD is not loaded"); return end
if not (CWm.getWindow() and WWm.getWindow()) then bail("open both ZeD windows first (zedqa_prelude.lua)"); return end
local p = getPlayer()
if not p then bail("no player"); return end
-- toggleBothPaired refuses to run while the game is paused
if getGameSpeed() <= 0 then setGameSpeed(1) end

-- how long each stage lasts, in frames
local SETTLE, FR_FRAME, FR_TIMING, FR_CENSUS = 60, 600, 600, 240

-- ---------------------------------------------------------------------------
-- the frame recorder (perf_bench_zed.lua's, trimmed): time between two OnRenderTick calls
-- ---------------------------------------------------------------------------
local B = { on = false, n = 0, last = 0, sum = 0, ds = {} }
function B.reset() B.n, B.sum, B.last, B.ds = 0, 0, 0, {} end
local function pct(a, q)                       -- a is a sorted array; q between 0 and 1
    local i = math.floor(#a * q + 0.5)
    if i < 1 then i = 1 end
    if i > #a then i = #a end
    return a[i]
end
function B.report(scene)
    if B.n < 2 then say("ERR no frames recorded for " .. scene); return end
    local avg = B.sum / B.n                    -- (taken before the sort; sorting does not change a sum, but it is clearer)
    table.sort(B.ds)
    say(string.format("FRAME|%s|frames=%d|avgMs=%.3f|p95=%.1f|worst=%d", scene, B.n, avg, pct(B.ds, 0.95), B.ds[B.n]))
end

-- ---------------------------------------------------------------------------
-- element timing (perf_bench_prof.lua and perf_bench_uie.lua: the wrap / unwrap code is theirs)
-- ---------------------------------------------------------------------------
local TIM = { acc = {}, cnt = {}, wrapped = {}, frames = 0, on = false, t0 = 0, nTop = 0, nAll = 0,
              mode = "prof", maxDepth = 8 }
-- the label an element is filed under: PROF's (class, function, size, depth) ...
local function profKey(o, how, depth)
    local nm = tostring(o.Type or "?")
    local w, h = 0, 0
    pcall(function() w, h = math.floor(o:getWidth()), math.floor(o:getHeight()) end)
    return string.format("%s %s %dx%d d%d", nm, how, w, h, depth)
end
-- ... and UIE's, which also tells visible from hidden and carries the element's own label
local function uieKey(o, how, depth)
    local w, h, vis = 0, 0, "?"
    pcall(function() w, h = math.floor(o:getWidth()), math.floor(o:getHeight()) end)
    pcall(function() vis = tostring(o:isVisible()) end)
    local lbl = tostring(o._zedLabel or o.title or o.name or "")
    if #lbl > 24 then lbl = lbl:sub(1, 24) end
    return string.format("%s %s %dx%d d%d vis=%s %s", tostring(o.Type or "?"), how, w, h, depth, vis, lbl)
end
-- Put a timer round o[how]. The wrapper goes on the INSTANCE, so undoing it means putting back
-- what the instance itself held (rawget: nil when the function was inherited from the class).
function TIM.wrap(o, how, depth)
    local orig = o[how]
    if type(orig) ~= "function" then return end
    local key = (TIM.mode == "uie") and uieKey(o, how, depth) or profKey(o, how, depth)
    TIM.wrapped[#TIM.wrapped + 1] = { o = o, how = how, mine = rawget(o, how) }
    o[how] = function(...)
        local t = getTimestampMs()
        local a, b, c = orig(...)              -- (three results is as many as these functions return)
        TIM.acc[key] = (TIM.acc[key] or 0) + (getTimestampMs() - t)
        TIM.cnt[key] = (TIM.cnt[key] or 0) + 1
        return a, b, c
    end
end
-- every element under o, once (seen), down to maxDepth
function TIM.walk(o, depth, seen)
    if type(o) ~= "table" or seen[o] or depth > TIM.maxDepth then return end
    seen[o] = true
    TIM.nAll = TIM.nAll + 1
    TIM.wrap(o, "prerender", depth)
    TIM.wrap(o, "render", depth)
    TIM.wrap(o, "update", depth)
    if type(o.children) == "table" then
        for _, ch in pairs(o.children) do TIM.walk(ch, depth + 1, seen) end
    end
end
function TIM.unwrapAll()
    for _, w in ipairs(TIM.wrapped) do w.o[w.how] = w.mine end
    TIM.wrapped = {}
end
-- hud: every top-level element the Java UIManager holds (belt, moodles, action bar, watch, vanilla)
function TIM.wrapAllTop()
    local seen = {}
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = nil
        pcall(function() t = ui:get(i):getTable() end)   -- the Lua table behind the Java element (nil for pure Java ones)
        if t then TIM.nTop = TIM.nTop + 1; TIM.walk(t, 0, seen) end
    end
end
function TIM.start(mode)
    TIM.mode = mode
    TIM.maxDepth = (mode == "uie") and 6 or 8
    TIM.acc, TIM.cnt, TIM.frames, TIM.nTop, TIM.nAll = {}, {}, 0, 0, 0
    if mode == "uie" then
        TIM.wrapAllTop()
    else
        local seen = {}
        TIM.walk(CWm.getWindow(), 0, seen); TIM.walk(WWm.getWindow(), 0, seen)
    end
    TIM.on, TIM.t0 = true, getTimestampMs()
end
function TIM.finish(scene)
    TIM.on = false
    local frames = math.max(TIM.frames, 1)
    local ft = (getTimestampMs() - TIM.t0) / frames    -- frame time WITH the timers on (the clean one is the FRAME line)
    TIM.unwrapAll()
    local rows, sum, sumRender = {}, 0, 0
    for k, v in pairs(TIM.acc) do
        local ms = v / frames
        rows[#rows + 1] = { k = k, ms = ms, n = TIM.cnt[k] / frames }
        sum = sum + ms
        if k:find("render", 1, true) then sumRender = sumRender + ms end   -- matches prerender and render
    end
    table.sort(rows, function(a, b) return a.ms > b.ms end)
    if TIM.mode == "uie" then
        say(string.format("UIE|%s|frames=%d|frameMs=%.2f|top-level=%d elements=%d|sum=%.2f ms/frame", scene, TIM.frames, ft, TIM.nTop, TIM.nAll, sum))
        for i = 1, math.min(16, #rows) do
            say(string.format("UIE|%s|%.3f ms/frame|%.2f calls/frame|%s", scene, rows[i].ms, rows[i].n, rows[i].k))
        end
    else
        say(string.format("PROF|%s|frames=%d|frameMs=%.2f|sumPreRender=%.2f", scene, TIM.frames, ft, sumRender))
        for i = 1, math.min(14, #rows) do
            say(string.format("PROF|%s|%.3f ms/frame|%.2f calls/frame|%s", scene, rows[i].ms, rows[i].n, rows[i].k))
        end
    end
end

-- ---------------------------------------------------------------------------
-- draw census (perf_census.lua's counters, plus the LeanDraw copies). Counts go in
-- bucket[class][function name]; the buckets are swapped for empty ones at the start of a pass.
-- ---------------------------------------------------------------------------
local CEN = { on = false, frames = 0, lean = {}, uie = {}, tm = {}, restore = {} }
local DRAW_NAMES = { "drawRect", "drawRectBorder", "drawText", "drawTextRight", "drawTextCentre", "drawTextZoomed",
                     "drawTexture", "drawTextureScaled", "drawTextureScaledAspect", "drawTextureScaledUniform",
                     "drawTextureTiled", "drawTextureTiledX", "drawTextureTiledY", "setStencilRect", "drawLine2" }
local LEAN_NAMES = { "drawRect", "drawRectBorder", "drawText", "drawTextureScaled", "drawTextureScaledAspect" }
local TM_NAMES = { "MeasureStringX", "MeasureStringY", "getFontHeight" }
-- a counting stand-in for orig. bk says which bucket ("lean" or "uie"); the bucket table is looked
-- up at call time through CEN so a new pass can swap it.
local function counter(bk, name, orig)
    return function(self, ...)
        if CEN.on then
            local cls = type(self) == "table" and self.Type or "?"
            local bucket = CEN[bk]
            local row = bucket[cls]
            if row == nil then row = {}; bucket[cls] = row end
            row[name] = (row[name] or 0) + 1
        end
        return orig(self, ...)
    end
end
function CEN.install()
    CEN.restore = {}
    local R = CEN.restore
    -- ONE stand-in per function, shared by the class tables. For LeanDraw this matters:
    -- LEAN.drawRectBorder tests "self.drawRect == LEAN.drawRect" to take its fast path, so the
    -- stand-in must sit on LeanDraw and on the classes alike or the test would fail and change what is measured.
    local lean, uie = {}, {}                   -- name -> { original, stand-in }
    local L = ZeD.LeanDraw
    if L then
        for _, n in ipairs(LEAN_NAMES) do
            local orig = rawget(L, n)
            if type(orig) == "function" then
                lean[n] = { orig, counter("lean", n, orig) }
                R[#R + 1] = { t = L, k = n, f = orig }
                L[n] = lean[n][2]
            end
        end
    end
    for _, n in ipairs(DRAW_NAMES) do
        local orig = rawget(ISUIElement, n)
        if type(orig) == "function" then uie[n] = { orig, counter("uie", n, orig) } end
    end
    -- every class table (ISUIElement itself included): swap in the stand-in wherever the class holds
    -- ISUIElement's function or the lean one as its OWN value (a raw copy). Inherited ones follow by themselves.
    local nCls = 0
    -- (ISUIElement first and by name, in case its own Type field does not match its global name)
    for n, pair in pairs(uie) do
        if rawget(ISUIElement, n) == pair[1] then R[#R + 1] = { t = ISUIElement, k = n, f = pair[1] }; ISUIElement[n] = pair[2] end
    end
    for k, v in pairs(_G) do
        if v ~= ISUIElement and type(v) == "table" and type(k) == "string" and rawget(v, "Type") == k then
            local hit = false
            for n, pair in pairs(uie) do
                if rawget(v, n) == pair[1] then R[#R + 1] = { t = v, k = n, f = pair[1] }; v[n] = pair[2]; hit = true end
            end
            for n, pair in pairs(lean) do
                if rawget(v, n) == pair[1] then R[#R + 1] = { t = v, k = n, f = pair[1] }; v[n] = pair[2]; hit = true end
            end
            if hit then nCls = nCls + 1 end
        end
    end
    -- ZeD.TM's measures
    local TM = ZeD.TM
    if TM then
        for _, n in ipairs(TM_NAMES) do
            local orig = rawget(TM, n)
            if type(orig) == "function" then
                R[#R + 1] = { t = TM, k = n, f = orig }
                TM[n] = function(self, ...)
                    if CEN.on then CEN.tm[n] = (CEN.tm[n] or 0) + 1 end
                    return orig(self, ...)
                end
            end
        end
    end
    return nCls, L ~= nil
end
function CEN.uninstall()
    CEN.on = false
    for i = #CEN.restore, 1, -1 do local r = CEN.restore[i]; r.t[r.k] = r.f end   -- last in, first out
    CEN.restore = {}
end
function CEN.start()
    CEN.lean, CEN.uie, CEN.tm, CEN.frames = {}, {}, {}, 0
    local nCls, hasLean = CEN.install()
    if not hasLean then say("NOTE ZeD.LeanDraw is missing: only the ISUIElement bucket is counted") end
    CEN.on = true
end
-- one bucket as rows { cls, calls per frame, "fn n, fn n" } biggest first, and the bucket's total
local function bucketRows(bucket, f)
    local rows, tot = {}, 0
    for cls, row in pairs(bucket) do
        local sum, names = 0, {}
        for n, c in pairs(row) do sum = sum + c; names[#names + 1] = { n = n, c = c } end
        table.sort(names, function(a, b) return a.c > b.c end)
        local parts = {}
        for i = 1, #names do parts[i] = string.format("%s %.1f", names[i].n, names[i].c / f) end
        rows[#rows + 1] = { cls = tostring(cls), v = sum / f, detail = table.concat(parts, ", ") }
        tot = tot + sum / f
    end
    table.sort(rows, function(a, b) return a.v > b.v end)
    return rows, tot
end
function CEN.finish(scene)
    CEN.on = false
    local f = math.max(CEN.frames, 1)
    CEN.uninstall()
    local leanRows, leanTot = bucketRows(CEN.lean, f)
    local uieRows, uieTot = bucketRows(CEN.uie, f)
    local tmTot = 0
    for _, c in pairs(CEN.tm) do tmTot = tmTot + c / f end
    say(string.format("CEN|%s|frames=%d|LEAN draw calls per frame=%.1f|ISUIElement draw calls per frame=%.1f|TM calls per frame=%.1f",
        scene, CEN.frames, leanTot, uieTot, tmTot))
    for i = 1, math.min(12, #leanRows) do
        say(string.format("CEN|%s|LEAN|%.1f|%s|%s", scene, leanRows[i].v, leanRows[i].cls, leanRows[i].detail))
    end
    for i = 1, math.min(12, #uieRows) do
        say(string.format("CEN|%s|UIE|%.1f|%s|%s", scene, uieRows[i].v, uieRows[i].cls, uieRows[i].detail))
    end
    for _, n in ipairs(TM_NAMES) do
        if CEN.tm[n] then say(string.format("CEN|%s|TM|%.1f|%s", scene, CEN.tm[n] / f, n)) end
    end
end

-- ---------------------------------------------------------------------------
-- the sequencer: a queue of steps, advanced one frame at a time from OnRenderTick (which, unlike
-- OnTick, keeps running under the pause menu). Steps never block; they only wait their turn.
-- ---------------------------------------------------------------------------
local Q, qi, finished = {}, 1, false      -- the steps, the one being waited on, "the run is over"
local S = {}
-- after n frames, run fn
function S.step(n, fn) Q[#Q + 1] = { left = n, fn = fn } end
-- every frame, ask pred; go on when it says true, or after maxFrames (with an ERR line)
function S.poll(pred, maxFrames) Q[#Q + 1] = { pred = pred, left = maxFrames or 600 } end

local onFrame                              -- forward declaration: finishRun needs the name before the function exists
local function finishRun()
    if finished then return end
    finished = true
    Events.OnRenderTick.Remove(onFrame)
    TIM.on = false; TIM.unwrapAll()        -- (normally already off; here in case a step failed halfway)
    CEN.uninstall()
    B.on = false
    say("DONE")
end

local function drive()
    local guard = 0                        -- steps of 0 frames run back to back; the guard stops a runaway
    while Q[qi] ~= nil and guard < 50 do
        guard = guard + 1
        local s = Q[qi]
        if s.pred then
            local ok, res = pcall(s.pred)
            if not ok then say("ERR wait " .. qi .. " " .. tostring(res)); res = true end
            if not res then
                s.left = s.left - 1
                if s.left > 0 then return end
                say("ERR step " .. qi .. " waited too long and moved on")
            end
            qi = qi + 1
        else
            if s.left > 0 then s.left = s.left - 1; return end
            local ok, e = pcall(s.fn)
            if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
            qi = qi + 1
        end
    end
    if Q[qi] == nil then finishRun() end
end

onFrame = function()
    if B.on then                           -- FRAME pass: the time since the last frame
        local now = getTimestampMs()
        if B.last > 0 then
            local d = now - B.last
            B.n = B.n + 1
            B.ds[B.n] = d
            B.sum = B.sum + d
        end
        B.last = now
    end
    if TIM.on then TIM.frames = TIM.frames + 1 end
    if CEN.on then CEN.frames = CEN.frames + 1 end
    drive()
end

-- ---------------------------------------------------------------------------
-- window helpers (copied from zedqa_prelude.lua, perf_census.lua and suite_perf.lua)
-- ---------------------------------------------------------------------------
local Z = {}
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)    -- both open: the pair key shuts both
    else
        if CWm.isOpen() then CWm.toggle(0) end                       -- toggle closes an open Character window
        if WWm.isOpen() then WWm.close() end
    end
end
function Z.openPair() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end end
-- click a tab on a strip exactly as the mouse does; true when the strip knows the tab. Does nothing
-- when that tab is already the active one (a click on the active tab may fold its drawer).
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
-- select exactly this item in the Character window's inventory list (nil: select nothing). The
-- window's drawer then shows the item card (or shuts it), the same path a mouse click takes.
function Z.selectItem(item)
    local w = Z.CW()
    local c = w and (w._mainContent or w._contentPanel)
    if not (c and w._updateDrawer) then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end   -- empty the selection table in place
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function Z.closeCard() return Z.selectItem(nil) end
-- the first item of the main inventory that is not worn or held (its card has the plain buttons);
-- the very first item when everything is worn
function Z.firstItem()
    local items = p:getInventory():getItems()
    local first = nil
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if first == nil then first = it end
        local eq = true
        pcall(function() eq = it:isEquipped() end)
        if not eq then return it end
    end
    return first
end

-- ---------------------------------------------------------------------------
-- the scenes
-- ---------------------------------------------------------------------------
local SCENES = {
    { id = "hud" },
    { id = "pair_loot", c = "loot",   w = "loot" },
    { id = "card",      c = "loot",   w = "loot", card = true },
    { id = "maps",      c = "loot",   w = "maps" },
    { id = "craft",     c = "loot",   w = "craft" },
    { id = "health",    c = "health", w = "loot" },
    { id = "skills",    c = "skills", w = "loot" },
    { id = "equip",     c = "equip",  w = "loot" },
}

-- open the pair and put both windows on their tabs (a poll: the strips need a frame or two after
-- the windows open before they know their tabs)
local function goTabs(cTab, wTab)
    S.poll(function()
        local cw, ww = Z.CW(), Z.WW()
        if not (cw and ww) then return false end
        local a = Z.goTab(cw, cw._tabStripPanel, cTab)
        local b = Z.goTab(ww, ww._actionTabStrip, wTab)
        return a and b and cw._activeTab == cTab and ww._activeTab == wTab
    end, 400)
end

local function addScene(sc)
    local id = sc.id
    if sc.c == nil then
        -- hud: card shut first (it needs the window), then both windows shut
        S.step(2, function() Z.closeCard(); Z.closePair() end)
    else
        S.step(2, function() Z.closeCard(); Z.openPair() end)
        goTabs(sc.c, sc.w)
        if sc.card then
            S.step(2, function()
                local it = Z.firstItem()
                if not it then say("ERR the main inventory is empty: no card"); return end
                say("NOTE card item " .. tostring(it:getDisplayName()))
                if not Z.selectItem(it) then say("ERR could not select the item") end
            end)
        end
    end
    -- settle, then pass 1: the whole frame time, nothing wrapped
    S.step(SETTLE, function()
        local w = Z.CW()
        if sc.card and not (w and w._drawerItem) then say("ERR the item card is not open in scene " .. id) end
        B.reset(); B.on = true
    end)
    S.poll(function() return B.n >= FR_FRAME end, FR_FRAME + 300)
    S.step(0, function() B.on = false; B.report(id) end)
    -- pass 2: element timers (hud: the UIManager's top-level elements; the rest: the window trees)
    S.step(0, function() TIM.start(sc.c == nil and "uie" or "prof") end)
    S.poll(function() return TIM.frames >= FR_TIMING end, FR_TIMING + 300)
    S.step(0, function() TIM.finish(id) end)
    -- pass 3: draw census
    S.step(0, function() CEN.start() end)
    S.poll(function() return CEN.frames >= FR_CENSUS end, FR_CENSUS + 300)
    S.step(0, function() CEN.finish(id) end)
end

say("START scenes=" .. #SCENES .. " settle=" .. SETTLE .. " frames=" .. FR_FRAME .. "/" .. FR_TIMING .. "/" .. FR_CENSUS)
for _, sc in ipairs(SCENES) do addScene(sc) end

-- the end state: card closed, windows open, both on Loot
S.step(2, function() Z.closeCard(); Z.openPair() end)
goTabs("loot", "loot")
S.step(10, function()
    local cw, ww = Z.CW(), Z.WW()
    say(string.format("END char=%s world=%s", tostring(cw and cw._activeTab), tostring(ww and ww._activeTab)))
end)

Events.OnRenderTick.Add(onFrame)
