-- ZeDUI/tools/qa/world_refresh_sim.lua  (Nov 8 2026, Build): the performance review's World window items, with no game
-- running (ZeDUI/qa/REVIEW_PERF_20261107.md, 5, 12 and 14) and two code flags in the same files.
--   CLOCK    the World window's container list, radios and vehicles by the clock (ZeD_WorldWindow.lua, the strip's
--            refresh) against the 30-frame rule it replaced: the same list, selection, columns, view and radio index
--            after a refresh (random lists); a refresh at once (WREF.soonMs) on a new square or OnContainerUpdate,
--            _containerTimer = 30 still a refresh on the next frame and 0 on the frame of one; calls in 10 s at 60,
--            144 and 240 fps, standing and walking, with the Radio or Vehicle tab open or not; how late a radio's tab
--            can show after a step next to it
--   CHAR     the Character window's container timer by the clock: the same counts at 60 fps, fewer above, 30 still
--            a refresh on the next frame
--   STOPS    the tab's stops (content._tabStopsRefresh in both windows): the moved block is the old one word for word
--            (given the old file); with the mouse in use they wait, and a controller press, a landing (focusByIdSoon)
--            or a named target (card jump, breadcrumb, vehicle target) sees the same stops and the same focus as
--            rebuilding them every frame did; builder calls counted
--   GONE     (code flag 1) the World window's two item-gone checks keep their own counts: the mouse's check closes
--            the card within 10 frames, the controller's still does with the pad
--   RADIO    (code flag 2) RadioTab.renderDrawer clears every module's click rects first: a ValuTech after a
--            Premium has no CD rects, a module the height leaves out has none
-- What it can't show: the game's own timing (OnContainerUpdate's rate, the frame pacing), or how it feels in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/world_refresh_sim.lua [old ZeD_WorldWindow.lua] [old ZeD_CharacterWindow.lua]
--   (with the old files, e.g. from git show 7f17686e:..., the 30-frame blocks are cut from them, not the copies below)
-- It prints FAIL lines, the numbers, and a last line "world_refresh_sim: N checks, M failed"; exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]world_refresh_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
-- the text from `from` up to (not with) `to`; nil when either is missing
local function cutTo(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a + #from, true)
    if not b then return nil end
    return string.sub(src, a, b - 1)
end
local function compile(name, prelude, body)
    local chunk, err = loadstring(prelude .. "\n" .. (body or "") .. "\nend")
    check(name .. " compiles", chunk ~= nil, err)
    return chunk
end

local WW = readFile(Z .. "ZeD_WorldWindow.lua")
local CW = readFile(Z .. "ZeD_CharacterWindow.lua")
local FM = readFile(Z .. "Input/FocusManager.lua")
local RT = readFile(Z .. "RadioTab.lua")
local OLD_WW = arg and arg[1] and readFile(arg[1]) or nil
local OLD_CW = arg and arg[2] and readFile(arg[2]) or nil

-- The 30-frame rules as they were on main at 7f17686e (used when the old files are not given)
local OLD_WORLD_BLOCK = [[
    -- Periodic container refresh (~every 30 frames)
    win._containerTimer = (win._containerTimer or 0) + 1
    if win._containerTimer >= 30 then
        win._containerTimer = 0
        local oldContainers = win._containers
        win._containers = buildWorldContainers(win._playerObj)
]]   -- (the rest of the block is the same text as today's, from the active container's remap on: appended below)
local OLD_CHAR_HEAD = [[
    win._containerTimer = (win._containerTimer or 0) + 1
    if win._containerTimer >= 30 then
        win._containerTimer = 0
]]

-- ---------------------------------------------------------------------------
-- The world: squares, containers, radios, vehicles; the clock
-- ---------------------------------------------------------------------------
local clock = { ms = 1700000000000 }
local function getTimestampMs() return clock.ms end
local calls = { build = 0, radios = 0, vehicles = 0 }
local INV = {}
local function inv(name) INV[name] = INV[name] or { name = name }; return INV[name] end
local world = { lists = {}, radios = {}, bump = 0 }
local function sqObj(x, y) return { key = x .. "," .. y } end
local SQ = {}
local function square(x, y) local k = x .. "," .. y; SQ[k] = SQ[k] or sqObj(x, y); return SQ[k] end
local player = { sq = square(0, 0) }
function player:getCurrentSquare() return self.sq end
local function truth()
    local key = player.sq.key
    local base = world.lists[key] or { "crate", "shelf" }
    local out = {}
    for _, n in ipairs(base) do out[#out + 1] = { inventory = inv(n), isFloor = false, name = n } end
    if world.bump % 2 == 1 then out[#out + 1] = { inventory = inv("bag" .. world.bump), isFloor = false } end
    out[#out + 1] = { inventory = inv("floor"), isFloor = true }
    return out
end
local function buildWorldContainers(p)
    calls.build = calls.build + 1
    return truth()
end
local ZeD = {
    RadioTab = { buildWorldRadios = function(p)
        calls.radios = calls.radios + 1
        local out = {}
        for _, r in ipairs(world.radios[p.sq.key] or {}) do out[#out + 1] = { cacheKey = r } end
        return out
    end },
    MechanicsTab = { refresh = function(win)
        calls.vehicles = calls.vehicles + 1
        win._mech = { vehicles = {} }
    end },
}
local WREF = { ms = 500, soonMs = 200, sideMs = 1000, phaseMs = 250 }
do
    local w = WW and string.match(WW, "local WREF = (%b{})")
    check("CLOCK: WREF found in the World window", w ~= nil)
    if w then
        local f = loadstring("return " .. w)
        if f then WREF = f() end
    end
end

-- ---------------------------------------------------------------------------
section("CLOCK: the World window's container list")
-- ---------------------------------------------------------------------------
local NEW_W = WW and cutTo(WW, "    local nowMs = getTimestampMs()\n", "\n    local containers = win._containers")
check("CLOCK: today's block found", NEW_W ~= nil)
local tail = NEW_W and cutTo(NEW_W, "        -- Remap _activeContainer by inventory identity", "        -- S115: refresh world radios")
check("CLOCK: the remap is in today's block", tail ~= nil)
local OLD_W
if OLD_WW then
    OLD_W = cutTo(OLD_WW, "    -- Periodic container refresh (~every 30 frames)", "\n    local containers = win._containers")
    check("CLOCK: the old block found in the old file", OLD_W ~= nil)
    check("CLOCK: the remap is the old text word for word", OLD_W ~= nil and tail ~= nil and string.find(OLD_W, tail, 1, true) ~= nil)
else
    OLD_W = OLD_WORLD_BLOCK .. "\n" .. (tail or "") .. [[
        win._radios = ZeD.RadioTab.buildWorldRadios(win._playerObj)
        if ZeD.MechanicsTab and ZeD.MechanicsTab.refresh then pcall(ZeD.MechanicsTab.refresh, win) end
        if #win._radios == 0 then
            win._radioIdx = 1
        elseif win._radioIdx > #win._radios then
            win._radioIdx = #win._radios
        end
        if win._radioWaveCache then
            local stillPresent = {}
            for _, entry in ipairs(win._radios) do
                if entry.cacheKey then stillPresent[entry.cacheKey] = true end
            end
            for k in pairs(win._radioWaveCache) do
                if not stillPresent[k] then win._radioWaveCache[k] = nil end
            end
        end
    end
]]
end
local PRE = "local buildWorldContainers, ZeD, WREF, getTimestampMs = ...\nreturn function(win, content)"
local newF = compile("CLOCK: today's block", PRE, NEW_W)
local oldF = compile("CLOCK: the old block", PRE, OLD_W)
newF = newF and newF(buildWorldContainers, ZeD, WREF, getTimestampMs)
oldF = oldF and oldF(buildWorldContainers, ZeD, WREF, getTimestampMs)

local function newWin()
    local list = truth()
    return { _playerObj = player, _containers = list, _activeContainer = #list, _containerTimer = 0,
             _radios = {}, _radioIdx = 1, _radioWaveCache = {}, _mcSelected = {},
             _containerAtMs = clock.ms, _containerDueMs = clock.ms + WREF.ms + WREF.phaseMs, _containerSq = player.sq,
             _sideScanAtMs = clock.ms, _sideScanSq = player.sq, _radioSq = player.sq }
end
local function snapshot(win, content)
    local t = { win._activeContainer, tostring(win._viewedContainer), tostring(win._mainVisible), win._radioIdx,
                content._inventory and content._inventory.name or "-", content._lastClickedItem and "c" or "-" }
    for _, i in ipairs(win._mcSelected or {}) do t[#t + 1] = "m" .. i end
    for _, c in ipairs(win._containers or {}) do t[#t + 1] = c.inventory.name end
    local keys = {}
    for k in pairs(win._radioWaveCache or {}) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[#t + 1] = "w" .. k end
    return table.concat(t, "|")
end

-- 1. the same result from a refresh: random lists before and after, random selection, columns and view
if newF and oldF then
    math.randomseed(8)
    local names = { "crate", "shelf", "fridge", "oven", "bag1", "bag3", "corpse", "trunk" }
    local same, n = 0, 400
    for trial = 1, n do
        local function randList()
            local l = {}
            for _, nm in ipairs(names) do if math.random() < 0.5 then l[#l + 1] = nm end end
            return l
        end
        local before, after = randList(), randList()
        world.lists[player.sq.key] = before
        world.bump = 0
        local function setup()
            local w = newWin()
            w._activeContainer = math.random(1, #w._containers)
            local mc = {}
            for i = 1, #w._containers - 1 do if math.random() < 0.3 then mc[#mc + 1] = i end end
            w._mcSelected = mc
            if math.random() < 0.3 then w._viewedContainer = math.random(1, #w._containers) end
            w._radioIdx = math.random(1, 3)
            w._radioWaveCache = { a = 1, b = 1 }
            local c = { _selectedItems = { x = true }, _lastClickedItem = "x" }
            return w, c
        end
        local seed = math.random(1, 1e6)
        math.randomseed(seed); local wo, co = setup()
        math.randomseed(seed); local wn, cn = setup()
        world.lists[player.sq.key] = after
        world.radios[player.sq.key] = (trial % 3 == 0) and { "a" } or nil
        wo._containerTimer = 29          -- the old rule: this frame is the 30th
        wn._containerTimer = 30          -- today's: a refresh asked for (the same body runs)
        oldF(wo, co); newF(wn, cn)
        if snapshot(wo, co) == snapshot(wn, cn) then same = same + 1 else
            if same == trial - 1 then print("  first difference: " .. snapshot(wo, co) .. "  vs  " .. snapshot(wn, cn)) end
        end
        check("CLOCK: the frame of a refresh is marked 0", wn._containerTimer == 0 and wo._containerTimer == 0)
    end
    check("CLOCK: the same list, selection, columns, view and radios after a refresh, " .. n .. " random lists", same == n, same .. "/" .. n)
    world.lists[player.sq.key] = nil
    world.radios[player.sq.key] = nil
end

-- 2. calls in 10 s, and how stale the list can get
local function run(fn, fps, opts)
    calls.build, calls.radios, calls.vehicles = 0, 0, 0
    world.bump = 0
    player.sq = square(0, 0)
    clock.ms = 1700000000000
    local win = newWin()
    win._activeTab = opts.tab
    local content = {}
    local frameMs = 1000 / fps
    local t, lastChange, maxLag, pendingSince = 0, 0, 0, nil
    local radioSeen, radioAt = nil, nil
    local refreshFrames, zeroFrames = 0, 0
    while t < 10000 do
        clock.ms = 1700000000000 + math.floor(t)
        -- the world moves: a step every opts.stepMs, a container change every 1.3 s (OnContainerUpdate)
        if opts.stepMs and math.floor(t / opts.stepMs) ~= math.floor((t - frameMs) / opts.stepMs) and t > 0 then
            local k = math.floor(t / opts.stepMs)
            player.sq = square(k, 0)
            if opts.radioAt and k == opts.radioAt then world.radios[player.sq.key] = { "r" .. k }; radioAt = t end
            pendingSince = pendingSince or t
        end
        if math.floor(t / 1300) ~= math.floor((t - frameMs) / 1300) and t > 0 then
            world.bump = world.bump + 1
            win._containersDirty = true            -- (the OnContainerUpdate handler)
            pendingSince = pendingSince or t
        end
        if opts.force and math.floor(t / 2700) ~= math.floor((t - frameMs) / 2700) and t > 0 then
            win._containerTimer = 30
            pendingSince = pendingSince or t
        end
        local before = calls.build
        fn(win, content)
        if calls.build > before then
            refreshFrames = refreshFrames + 1
            if pendingSince then maxLag = math.max(maxLag, t - pendingSince); pendingSince = nil end
        end
        if win._containerTimer == 0 then zeroFrames = zeroFrames + 1 end
        if radioAt and not radioSeen and win._radios and #win._radios > 0 then radioSeen = t - radioAt end
        t = t + frameMs
    end
    for k in pairs(world.radios) do world.radios[k] = nil end
    return { build = calls.build, radios = calls.radios, vehicles = calls.vehicles, lag = maxLag,
             radioLag = radioSeen, refresh = refreshFrames, zero = zeroFrames }
end

if newF and oldF then
    local rows = {}
    local cases = {
        { "standing, tabs shut", {} },
        { "walking (a step each 300 ms)", { stepMs = 300 } },
        { "walking, Radio tab open", { stepMs = 300, tab = "radio" } },
        { "standing, Vehicle tab open", { tab = "vehicle" } },
        { "standing, refresh asked for (30)", { force = true } },
    }
    for _, fps in ipairs({ 60, 144, 240 }) do
        for _, c in ipairs(cases) do
            local o = run(oldF, fps, c[2])
            local n = run(newF, fps, c[2])
            rows[#rows + 1] = string.format("  %3d fps  %-34s old list %3d radios %3d vehicles %3d | new list %3d radios %3d vehicles %3d | lag old %4d ms new %4d ms",
                fps, c[1], o.build, o.radios, o.vehicles, n.build, n.radios, n.vehicles, o.lag, n.lag)
            check("CLOCK: a refresh frame is marked 0, " .. fps .. " fps, " .. c[1], n.zero == n.refresh, n.zero .. " vs " .. n.refresh)
            check("CLOCK: never staler than the old rule at 60 fps (" .. fps .. " fps, " .. c[1] .. ")", n.lag <= 500 + 1000 / fps, n.lag)
            if not c[2].stepMs then
                check("CLOCK: no more list reads than the old rule at 60 fps standing (" .. fps .. " fps, " .. c[1] .. ")",
                    n.build <= 22 + (c[2].force and 4 or 0) + 8, n.build)
            end
            if c[2].tab == "radio" then check("CLOCK: radios with each list read while the Radio tab is open", n.radios == n.build) end
            if c[2].tab == "vehicle" then check("CLOCK: vehicles with each list read while the Vehicle tab is open", n.vehicles == n.build) end
            if not c[2].tab then
                check("CLOCK: vehicles no more than once a second standing, twice walking (" .. fps .. ", " .. c[1] .. ")",
                    n.vehicles <= (c[2].stepMs and 21 or 11) + (c[2].force and 4 or 0), n.vehicles)
                check("CLOCK: radios with the vehicles standing, with each new square walking (" .. fps .. ", " .. c[1] .. ")",
                    (c[2].stepMs and n.radios <= n.build) or (not c[2].stepMs and n.radios == n.vehicles), n.radios)
            end
            if fps > 60 and not c[2].stepMs and not c[2].tab then
                check("CLOCK: fewer list reads than before at " .. fps .. " fps (" .. c[1] .. ")", n.build < o.build, n.build .. " vs " .. o.build)
            end
        end
    end
    for _, r in ipairs(rows) do print(r) end
    -- a radio next to the new square: its tab shows (the list has it) no later than the old rule at 60 fps
    for _, fps in ipairs({ 60, 144 }) do
        local o = run(oldF, fps, { stepMs = 700, radioAt = 5 })
        local n = run(newF, fps, { stepMs = 700, radioAt = 5 })
        print(string.format("  %3d fps  a radio's tab shows after the step: old %s ms, new %s ms", fps, tostring(o.radioLag), tostring(n.radioLag)))
        check("CLOCK: the radio is found (" .. fps .. " fps)", n.radioLag ~= nil)
        check("CLOCK: the Radio tab shows no later than 500 ms after the step (" .. fps .. " fps)", (n.radioLag or 1e9) <= 500 + 1000 / fps, n.radioLag)
    end
end

-- 3. 30 still means the next frame; between refreshes the timer is never 30 by itself
if newF then
    clock.ms = 1700000000000
    player.sq = square(0, 0)
    local win = newWin()
    local content = {}
    calls.build = 0
    for _ = 1, 3 do newF(win, content) end
    check("CLOCK: no read in the first frames after opening (the phase)", calls.build == 0, calls.build)
    win._containerTimer = 30
    newF(win, content)
    check("CLOCK: _containerTimer = 30 reads the list on the next frame", calls.build == 1 and win._containerTimer == 0)
    for _ = 1, 100 do newF(win, content) end
    check("CLOCK: the timer never reaches 30 on its own", win._containerTimer == 1)
end

-- ---------------------------------------------------------------------------
section("CHAR: the Character window's container timer")
-- ---------------------------------------------------------------------------
local NEW_C = CW and cutTo(CW, "    local nowMs = getTimestampMs()\n    if (win._containerTimer or 0) < 30", "\n    -- Build display order")
check("CHAR: today's block found", NEW_C ~= nil)
local cTail = NEW_C and cutTo(NEW_C, "        remapCharContainers(", "\n    end\n") or ""
local OLD_C
if OLD_CW then
    OLD_C = cutTo(OLD_CW, "    win._containerTimer = (win._containerTimer or 0) + 1\n    if win._containerTimer >= 30 then", "\n    -- Build display order")
    check("CHAR: the old block found in the old file", OLD_C ~= nil)
    check("CHAR: what a refresh does is the old text word for word", OLD_C ~= nil and string.find(OLD_C, cTail, 1, true) ~= nil)
else
    OLD_C = OLD_CHAR_HEAD .. cTail .. "\n    end\n"
end
local remaps = 0
local CPRE = "local remapCharContainers, buildContainers, ZeD, getTimestampMs = ...\nreturn function(win, content)"
local function remap(win, content, o, n) remaps = remaps + 1; win._containers = n end
local function buildC() return {} end
local ZC = { RadioTab = { buildEquippedRadios = function() return {} end } }
local cNew = compile("CHAR: today's block", CPRE, NEW_C)
local cOld = compile("CHAR: the old block", CPRE, OLD_C)
cNew = cNew and cNew(remap, buildC, ZC, getTimestampMs)
cOld = cOld and cOld(remap, buildC, ZC, getTimestampMs)
if cNew and cOld then
    for _, fps in ipairs({ 60, 144, 240 }) do
        local counts = {}
        for which, f in pairs({ old = cOld, new = cNew }) do
            remaps = 0
            clock.ms = 1700000000000
            local win = { _containerTimer = 0, _containerDueMs = clock.ms + 500, _radios = {}, _radioIdx = 1 }
            local t, zero = 0, 0
            while t < 10000 do
                clock.ms = 1700000000000 + math.floor(t)
                local before = remaps
                f(win, {})
                if win._containerTimer == 0 then zero = zero + 1 end
                check("CHAR: 0 marks the frames of a refresh (" .. which .. ", " .. fps .. ")", (win._containerTimer == 0) == (remaps > before))
                t = t + 1000 / fps
            end
            counts[which] = remaps
        end
        print(string.format("  %3d fps  container reads in 10 s: old %3d, new %3d", fps, counts.old, counts.new))
        check("CHAR: about as many reads as the old rule at 60 fps, never more (" .. fps .. ")", counts.new <= 20 and counts.new >= 19, counts.new)
    end
    clock.ms = 1700000000000
    local win = { _containerTimer = 0, _containerDueMs = clock.ms + 500, _radios = {}, _radioIdx = 1 }
    remaps = 0
    cNew(win, {})
    win._containerTimer = 30
    cNew(win, {})
    check("CHAR: 30 reads the bags on the next frame", remaps == 1 and win._containerTimer == 0)
end

-- ---------------------------------------------------------------------------
section("STOPS: the tab's stops wait for the controller")
-- ---------------------------------------------------------------------------
-- FocusManager's own zone setters, its stopsMayWait / soonPending and _fresh, cut from its source
local Focus = {}
local FS = { cues = false, mode = "gamepad", soon = {} }
local fmParts = {}
for _, m in ipairs({ "local function _resolveZoneIdx(", "local function _clampIdx(", "function Focus.setRingZoneElements(",
                     "function Focus.setZoneFocusable(", "function Focus.soonPending(", "function Focus.stopsMayWait(",
                     "local function _fresh(" }) do
    local part = FM and cutTo(FM, m, "\nend\n")
    check("STOPS: FocusManager's " .. m .. " found", part ~= nil)
    fmParts[#fmParts + 1] = (part or "") .. "\nend\n"
end
local fmEnv = [[
local Focus, ZeD, FS = ...
local _focusSoon = FS.soon
local _cuesOn
local function _zonePanel() return nil end
local function _fireCb(n, fn, w, a) local ok, e = pcall(fn, w, a); if not ok then print("cb " .. tostring(e)) end end
]]
local DET = { getMode = function() return FS.mode end }
local ZF = { Input = { Detector = DET, Focus = Focus } }
do
    -- _cuesOn is FocusManager's local: the sim keeps it in step with FS.cues through a getter
    local body = fmEnv .. table.concat(fmParts, "\n") .. "\nreturn _fresh, function(v) _cuesOn = v end"
    local chunk, err = loadstring(body)
    check("STOPS: FocusManager's pieces compile", chunk ~= nil, err)
    if chunk then FS.fresh, FS.setCues = chunk(Focus, ZF, FS) end
end
local function setCues(v) FS.cues = v; if FS.setCues then FS.setCues(v) end end

-- the windows' tab stops, their refresh gate and their _focusFresh, cut from today's sources
local function windowParts(src, label)
    local trs = src and cutTo(src, "    content._tabStopsRefresh = function(self, Focus)\n", "\n    -- What the controller reads between frames")
    local fresh = src and cutTo(src, "    win._focusFresh = function(w)\n", "\n    -- The ")
    local gate = src and cutTo(src, "        if Focus and win._focusRing then\n            if not (Focus.stopsMayWait", "\n        -- S99 per-frame refresh for ")
    check("STOPS: " .. label .. " pieces found", trs ~= nil and fresh ~= nil and gate ~= nil)
    return trs, fresh, gate
end

local builds = 0
local function scenario(label, src, oldSrc, zoneName, builderName, tabs)
    local trs, fresh, gate = windowParts(src, label)
    if not (trs and fresh and gate) then return end
    if oldSrc then
        local body = string.match(trs, "^    content._tabStopsRefresh = function%(self, Focus%)\n(.*)\n    end\n?$")
        check("STOPS: " .. label .. ": the block is the old per-frame block word for word", body ~= nil and string.find(oldSrc, body, 1, true) ~= nil)
    end
    -- the builder: stops from the tab's state, the y with its scroll
    local S = { n = 12, scroll = 0, tab = tabs[1] }
    local function builder(win, content, tab)
        builds = builds + 1
        local els = {}
        for i = 1, S.n do
            els[i] = { id = tab .. ":" .. i, x = 0, y = i * 20 - S.scroll, w = 100, h = 18,
                       isBreadcrumb = (i == 1), craftKind = (i == S.n and "actBuild" or nil) }
        end
        return els
    end
    local PREP = "local win, content, ZeD, " .. builderName .. ", ZeD_WorldWindow, ZeD_CharacterWindow = ...\n"
    local mk = function()
        local w = { _activeTab = S.tab, _focusRing = { { zone = "inv", elements = { { id = "row" } }, focusable = true },
                                                       { zone = zoneName, elements = {}, focusable = false } },
                    _focusIdx = 2, _craftState = { scroll = { scrollPos = 0 } }, _buildState = {}, _journalSubTab = 1 }
        local c = {}
        local ZW = { _extTabs = {} }
        local ZCW = { _extTabs = {}, extScrollKey = function() return nil end }
        local ZZ = { Input = { Focus = Focus, Detector = DET }, MechanicsTab = { focusTargetIndex = function(win, els)
            win._mechFocusTarget = nil; return 2 end }, IdentityTab = {} }
        local f1 = loadstring(PREP .. trs .. "\n    return content._tabStopsRefresh")
        local f2 = loadstring(PREP .. "local w0 = win\n" .. fresh .. "\n return win._focusFresh")
        local f3 = loadstring(PREP .. "return function(self, Focus)\n" .. gate .. "\nend")
        check("STOPS: " .. label .. " pieces compile", f1 and f2 and f3)
        if not (f1 and f2 and f3) then return nil end
        local tsr = f1(w, c, ZZ, builder, ZW, ZCW)
        c._tabStopsRefresh = tsr
        f2(w, c, ZZ, builder, ZW, ZCW)
        local gateF = f3(w, c, ZZ, builder, ZW, ZCW)
        return w, c, tsr, gateF
    end
    local wo, co, tsrO = mk()       -- the old way: the block every frame
    local wn, cn, _, gateN = mk()   -- today's: the gate
    if not wo then return end
    local function zone(w) return w._focusRing[2] end
    local function sig(w)
        local z = zone(w)
        local t = { tostring(z.focusable), tostring(z.focusedElementIdx), tostring(w._focusIdx) }
        for _, e in ipairs(z.elements or {}) do t[#t + 1] = e.id .. "@" .. e.y end
        return table.concat(t, " ")
    end
    local oldBuilds, newBuilds = 0, 0
    local function frame()
        wo._activeTab, wn._activeTab = S.tab, S.tab
        wo._craftState.scroll.scrollPos, wn._craftState.scroll.scrollPos = S.scroll, S.scroll
        setCues(FS.cues)
        local b = builds
        tsrO(co, Focus)
        oldBuilds = oldBuilds + (builds - b)
        b = builds
        gateN(cn, Focus)
        newBuilds = newBuilds + (builds - b)
    end
    local function press()           -- a controller press: FocusManager brings the stops up to date first
        FS.fresh(wn)
        -- (the old window's were rebuilt on the last frame)
        local zo, zn = zone(wo), zone(wn)
        zo.focusedElementIdx = math.min((zo.focusedElementIdx or 1) + 1, #zo.elements)
        zn.focusedElementIdx = math.min((zn.focusedElementIdx or 1) + 1, #zn.elements)
    end
    -- the pad in use: the same every frame
    FS.mode = "gamepad"; setCues(true)
    for i = 1, 20 do frame(); if i == 5 then press() end end
    check("STOPS: " .. label .. ": with the pad, the same stops every frame", sig(wo) == sig(wn), sig(wo) .. " / " .. sig(wn))
    -- the mouse takes over: the stops wait while the tab scrolls, grows and switches
    FS.mode = "kbm"; setCues(false)
    local before = newBuilds
    for i = 1, 300 do
        if i % 7 == 0 then S.scroll = S.scroll + 3 end
        if i == 120 then S.n = 30 end
        if i == 200 then S.tab = tabs[2] end
        frame()
    end
    check("STOPS: " .. label .. ": no rebuilds while the mouse is in use", newBuilds == before, newBuilds - before)
    -- the first press of the pad, before any frame: the same stops and the same move
    press()
    check("STOPS: " .. label .. ": the first press sees the same stops and lands on the same one", sig(wo) == sig(wn), sig(wo) .. " / " .. sig(wn))
    FS.mode = "gamepad"; setCues(true)
    for _ = 1, 10 do S.scroll = S.scroll + 1; frame() end
    check("STOPS: " .. label .. ": then every frame the same", sig(wo) == sig(wn))
    -- mouse again; a landing waits (focusByIdSoon): rebuilt that frame as before
    FS.mode = "kbm"; setCues(false)
    for _ = 1, 30 do S.scroll = S.scroll + 2; frame() end
    FS.soon[1] = { w = wn }
    frame()
    check("STOPS: " .. label .. ": a waiting landing rebuilds the stops that frame", sig(wo) == sig(wn))
    FS.soon[1] = nil
    -- a target named for the next rebuild (World: card jump, breadcrumb, vehicle) is honored that frame
    if zoneName == "worldTabContent" then
        for _, t in ipairs({ { "_craftState", "craft" }, { "_animalsNavFocusTarget", "animals" }, { "_mechFocusTarget", "vehicle" } }) do
            for _ = 1, 20 do S.scroll = S.scroll + 1; frame() end
            S.tab = t[2]
            if t[1] == "_craftState" then
                wo._craftState._gpPendingCardJump, wn._craftState._gpPendingCardJump = true, true
            elseif t[1] == "_animalsNavFocusTarget" then
                wo._animalsNavFocusTarget, wn._animalsNavFocusTarget = "breadcrumb", "breadcrumb"
            else
                wo._mechFocusTarget, wn._mechFocusTarget = "card", "card"
            end
            frame()
            check("STOPS: " .. label .. ": " .. t[1] .. " lands on the same frame", sig(wo) == sig(wn), sig(wo) .. " / " .. sig(wn))
            local function left(w) if t[1] == "_craftState" then return tostring(w._craftState._gpPendingCardJump) end return tostring(w[t[1]]) end
            check("STOPS: " .. label .. ": " .. t[1] .. " is used up the same", left(wo) == left(wn), left(wo) .. " / " .. left(wn))
        end
    end
    -- the detector not sure yet ("unknown"): rebuilt every frame, as before
    FS.mode = "unknown"
    local b0 = newBuilds
    for _ = 1, 10 do frame() end
    check("STOPS: " .. label .. ": with no mode yet the stops rebuild every frame", newBuilds - b0 == 10)
    print(string.format("  %s: builder calls, old %d, new %d (330 mouse frames of 400)", label, oldBuilds, newBuilds))
end
scenario("World window", WW, OLD_WW, "worldTabContent", "_buildWorldPanelFocusables", { "craft", "build" })
scenario("Character window", CW, OLD_CW, "charTabContent", "_buildPanelFocusables", { "skills", "health" })

-- ---------------------------------------------------------------------------
section("GONE: the item card closes when its item is gone (code flag 1)")
-- ---------------------------------------------------------------------------
do
    local a = WW and cutTo(WW, "local function closeCardIfItemGone(win, content)", "\nend\n")
    local b = WW and cutTo(WW, "local function _closeCardIfItemGone(win)", "\nend\n")
    check("GONE: both checks found", a ~= nil and b ~= nil)
    if a and b then
        local chunk, err = loadstring("local ZeD = ...\n" .. a .. "\nend\n" .. b .. "\nend\nreturn closeCardIfItemGone, _closeCardIfItemGone")
        check("GONE: the checks compile", chunk ~= nil, err)
        local mode = "kbm"
        local Zg = { Input = { Detector = { getMode = function() return mode end } } }
        local mouseF, padF = chunk(Zg)
        for _, m in ipairs({ "kbm", "gamepad" }) do
            mode = m
            local closed = 0
            local gone = { getContainer = function() return nil end }
            local win = { _containers = {}, _drawerItem = gone }
            win._updateDrawer = function() closed = closed + 1; win._drawerItem = nil end
            local content = { _selectedItems = {}, _colStates = {} }
            win._mainContent = content
            for _ = 1, 10 do
                mouseF(win, content)        -- the content's prerender
                padF(win)                   -- then _focusRefresh, the same frame
            end
            check("GONE: with " .. m .. ", the card closes within 10 frames", closed == 1, closed)
            -- an item still there keeps its card
            closed = 0
            local crate = { getType = function() return "crate" end }
            local here = { getContainer = function() return crate end }
            win._drawerItem = here
            win._containers = { { inventory = crate } }
            for _ = 1, 30 do mouseF(win, content); padF(win) end
            check("GONE: with " .. m .. ", an item in a crate keeps its card", closed == 0, closed)
        end
    end
end

-- ---------------------------------------------------------------------------
section("RADIO: the chassis' click rects start empty each frame (code flag 2)")
-- ---------------------------------------------------------------------------
do
    local rd = RT and cutTo(RT, "function renderDrawer(panel, x, y, w, h, win, radioEntry)", "\nend\n")
    check("RADIO: renderDrawer found", rd ~= nil)
    if rd then
        local env = {}
        local chunk, err = loadstring("local _safeGet, renderPremium, renderValutech = ...\n" .. rd .. "\nend\nreturn renderDrawer")
        check("RADIO: renderDrawer compiles", chunk ~= nil, err)
        local tall = true
        local function premium(panel, x, y, w, h, win)
            if not tall then return end      -- (the height leaves every module out)
            win._radioPwrZone = { w = 1 }; win._radioSeekBtnZones = { { w = 1 }, { w = 1 } }
            win._radioPresetZones = { { w = 1 } }; win._radioCDZones = { { w = 1 }, { w = 1 } }
        end
        local function valutech(panel, x, y, w, h, win)
            win._radioPwrZone = { w = 1 }; win._radioPresetZones = { { w = 1 } }
        end
        local hi = true
        local function safeGet() return hi end
        local renderDrawer = chunk(safeGet, premium, valutech)
        local win = {}
        renderDrawer(nil, 0, 0, 100, 100, win, { deviceData = {} })
        check("RADIO: a Premium has its CD rects", win._radioCDZones and #win._radioCDZones == 2)
        hi = false
        renderDrawer(nil, 0, 0, 100, 100, win, { deviceData = {} })
        check("RADIO: a ValuTech browsed to after it has none", win._radioCDZones == nil and win._radioSeekBtnZones == nil)
        check("RADIO: the ValuTech's own rects stay", win._radioPwrZone ~= nil and win._radioPresetZones ~= nil)
        hi, tall = true, false
        renderDrawer(nil, 0, 0, 100, 10, win, { deviceData = {} })
        check("RADIO: modules the height leaves out have no rects", win._radioPwrZone == nil and win._radioPresetZones == nil and win._radioCDZones == nil)
    end
end

print(string.format("world_refresh_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
