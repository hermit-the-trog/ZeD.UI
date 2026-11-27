-- ZeDUI/tools/qa/oc_leash_sim.lua  (Nov 26 2026, Build; QA PL1/OC2, PL3/OC5, TK1, TK3, PV3)
-- The object card host's leash and upkeep, and the placement, track and preview kinds, on Lua 5.1 stubs: the lines
-- cut out of ObjectCards.lua / ZeD_WorldWindow.lua and the real kind files, each beside the code before the fix
-- (git show BASE), so every check below fails on the old code where the old code can be run.
--   PL1/OC2  closing the World window drops the card, so the placement card ends the game's placement; a card
--            not drawn (a rolled-up window) still gets its leash from OC.upkeep
--   PL3      the placement card closes past the game's DistToProper 3 (3.16 closes, 3.0 stays)
--   PL3/OC5  only an action the card queued (OC.ownRun) holds the leash; a walk the card never started does not
--   OC5      the laundry's card (leash 6) closes 8 tiles off during a walk it never started
--   TK1      a track's freshness tag carries no green mark
--   TK3      a track item he picked up has no leash (the leash follows the item)
--   PV3      the build preview's strength follows a Carpentry level gained while it is open
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_leash_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_leash_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local BASE = "ccd43c64e"   -- the branch these fixes went on
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function note(s) print("  " .. s) end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
local function baseFile(name)
    local p = io.popen('git -C "' .. (ROOT ~= "" and (ROOT:gsub("[/\\]+$", "")) or ".") .. '" show ' .. BASE .. ':42/media/lua/client/ZeD/' .. name .. ' 2>NUL')
    local s = p and p:read("*a") or ""
    if p then p:close() end
    return s ~= "" and (s:gsub("\r\n", "\n")) or nil
end
local function cut(src, from, to)
    if not src then return nil end
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a + #from, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src
    return string.sub(src, a, e)
end
local function run(src, name, env)
    local f, err = loadstring(src, "=" .. name)
    assert(f, err)
    setfenv(f, setmetatable(env, { __index = _G }))
    return f()
end
local function noop() end
local function realCall(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end

local OCN, OCO = readFile(Z .. "ObjectCards.lua"), baseFile("ObjectCards.lua")
local WWN, WWO = readFile(Z .. "ZeD_WorldWindow.lua"), baseFile("ZeD_WorldWindow.lua")
check("the new ObjectCards.lua and ZeD_WorldWindow.lua read", OCN and WWN)
if not (OCO and WWO) then note("no git base " .. BASE .. ": the old-code checks are skipped") end

-- ---------------------------------------------------------------------------
-- the world: squares, a player, the action queue
-- ---------------------------------------------------------------------------
local function square(x, y, z)
    return { x = x, y = y, z = z or 0,
             getX = function(s) return s.x end, getY = function(s) return s.y end, getZ = function(s) return s.z end,
             DistToProper = function(s, o) local dx, dy = s.x - o.x, s.y - o.y; return math.sqrt(dx * dx + dy * dy) end }
end
local function player(px, py)
    local p = { x = px, y = py, z = 0, num = 0 }
    p.getX = function(s) return s.x end
    p.getY = function(s) return s.y end
    p.getZ = function(s) return s.z end
    p.getVehicle = function() return nil end
    p.isDead = function() return false end
    p.getPlayerNum = function(s) return s.num end
    p.getCurrentSquare = function(s) return square(math.floor(s.x), math.floor(s.y), s.z) end
    return p
end
local QUEUES = {}
local TAQ = { getTimedActionQueue = function(p) QUEUES[p] = QUEUES[p] or { queue = {} }; return QUEUES[p] end }
local function queue(p) return TAQ.getTimedActionQueue(p).queue end

-- OC.tick (and OC.ownRun / OC.squareDist) cut from a source, on one env
local function loadTick(src)
    local tick = cut(src, "function OC.tick(e, player)", "    return true\nend")
    local dist = cut(src, "function OC.squareDist(player, sq)", "\nend")
    local own = cut(src, "function OC.ownRun(e, player, fn, a, b)", "\n    return r\nend") or ""
    if not (tick and dist) then return nil end
    local OC = { REFRESH = 15, BROWSE_EVERY = 60, LEASH = 6 }
    local env = { OC = OC, ZeD = { logOnce = noop }, ISTimedActionQueue = TAQ,
                  sixtieths = function() return 1 end, beat = function() return 0 end, browsePhase = function() return 0 end,
                  getTimestampMs = function() return 1000 end }
    run(dist .. "\n" .. own .. "\n" .. tick, "OC.tick", env)
    return OC
end
local NEW, OLD = loadTick(OCN), OCO and loadTick(OCO)
check("OC.tick, OC.squareDist and OC.ownRun cut from the new file", NEW and NEW.tick and NEW.ownRun)

-- a plain kind on a square (leash: the kind's, else OC.LEASH)
local function kind(fields)
    local def = { valid = function() return true end, refresh = function(t) t.d = {} end,
                  nearby = function() return nil end }
    for k, v in pairs(fields or {}) do def[k] = v end
    return def
end
local function entry(def, sq) return { def = def, t = { key = "k", sq = sq, d = {} } } end
-- tick once: alive (true / false)
local function tick(OC, e, p) local ok, r = pcall(OC.tick, e, p); if not ok then return "threw: " .. tostring(r) end; return r end

-- ---------------------------------------------------------------------------
-- placement kind, the real file
-- ---------------------------------------------------------------------------
local function loadKind(src, extraEnv)
    if not src then return nil end
    local reg
    local env = { require = noop,
                  ZeD = { ObjectCards = { ui = {}, call = realCall, DOT = "|", cap = function(s) return s end,
                                          register = function(d) reg = d end }, tr = function(k, a) return k .. (a and (" " .. tostring(a)) or "") end,
                          T = { textDim = { dim = true }, positive = { green = true }, text = {} } },
                  getText = function(k) return k end, getTextOrNull = function() return nil end,
                  print = noop }
    for k, v in pairs(extraEnv or {}) do env[k] = v end
    local ok, err = pcall(run, src, "kind", env)
    if not ok then return nil, err end
    return reg, env
end
local PLN, plErr = loadKind(readFile(Z .. "ObjectCardPlacement.lua"))
local PLO = loadKind(baseFile("ObjectCardPlacement.lua"))
check("ObjectCardPlacement.lua loads on the stubs", PLN ~= nil, plErr)

local GIZ = {}
Gizmos = { getInstance = function() return { setGizmo = function(_, pn, g) GIZ[pn] = g or "none" end } end }
local function placeT(sq)
    local item = { doing = true }
    item.setDoingExtendedPlacement = function(s, v) s.doing = v end
    item.getDisplayName = function() return "Mug" end
    item.getTex = function() return nil end
    local obj = { synced = false }
    obj.getItem = function() return item end
    obj.isExistInTheWorld = function() return true end
    obj.syncExtendedPlacement = function(s) s.synced = true end
    return { obj = obj, item = item, sq = sq, key = "p3:1", pn = 0, d = {} }
end

-- PL3: the game's 3 by DistToProper
do
    local sq = square(10, 10)
    for _, c in ipairs({ { which = "new", OC = NEW, def = PLN }, { which = "old", OC = OLD, def = PLO } }) do
        if c.OC and c.def then
            local e = { def = c.def, t = placeT(sq) }
            local at316 = tick(c.OC, e, player(13.5, 11.5))   -- his square 13,11: DistToProper sqrt(10) = 3.16
            local e2 = { def = c.def, t = placeT(sq) }
            local at3 = tick(c.OC, e2, player(13.9, 10.9))     -- his square 13,10: 3.0, the game keeps it open
            if c.which == "new" then
                check("PL3: the placement card closes at the game's DistToProper 3.16", at316 == false, at316)
                check("PL3: the placement card stays open at 3.0, as the game's", at3 == true, at3)
            else
                check("PL3 (old code shows the bug): open at 3.16", at316 == true, at316)
            end
        end
    end
end

-- PL3/OC5 and OC5: the hold is the card's own actions only
do
    local laundry = kind({ id = "laundry" })   -- no leash of its own: OC.LEASH 6
    for _, c in ipairs({ { which = "new", OC = NEW }, { which = "old", OC = OLD } }) do
        if c.OC then
            -- open idle beside the washer, then a walk the card never started, 8 tiles off
            local p = player(10.5, 10.5)
            QUEUES[p] = nil
            local e = entry(laundry, square(10, 10))
            local a0 = tick(c.OC, e, p)
            queue(p)[1] = { name = "walk" }
            p.x = 18.5
            local a1 = tick(c.OC, e, p)
            if c.which == "new" then
                check("OC5: the laundry card opens beside the washer", a0 == true, a0)
                check("OC5: a walk the card never started does not hold it 8 tiles off", a1 == false, a1)
            else
                check("OC5 (old code shows the bug): held open 8 tiles off by any walk", a1 == true, a1)
            end
            -- the placement card: a far walk the card did not queue, 6 tiles off
            if c.which == "new" and PLN then
                local pp = player(10.5, 10.5)
                QUEUES[pp] = nil
                local ep = { def = PLN, t = placeT(square(10, 10)) }
                tick(c.OC, ep, pp)
                queue(pp)[1] = { name = "walk" }
                pp.x = 16.5
                check("PL3: a walk he started himself does not hold the placement card at 6", tick(c.OC, ep, pp) == false)
            end
        end
    end
    -- the card's own press holds it until its actions leave the queue
    local p = player(10.5, 10.5)
    QUEUES[p] = nil
    local e = entry(laundry, square(10, 10))
    tick(NEW, e, p)
    queue(p)[1] = { name = "someone else's" }   -- (in the queue before the press: not the card's)
    NEW.ownRun(e, p, function(card, pl)
        local q = queue(pl)
        q[#q + 1] = { name = "walk" }
        q[#q + 1] = { name = "toggle" }
    end, nil, p)
    local q = queue(p)
    check("ownRun: the press's two actions are the card's", q[2]._zedCard == e and q[3]._zedCard == e)
    check("ownRun: what was queued before the press is not", q[1]._zedCard == nil)
    p.x = 18.5
    check("ownRun: the card's own walk holds the leash 8 tiles off", tick(NEW, e, p) == true)
    table.remove(q, 1)
    check("ownRun: still held while one of its own is queued", tick(NEW, e, p) == true)
    while #q > 0 do table.remove(q, 1) end
    check("ownRun: with its actions done the leash applies again", tick(NEW, e, p) == false)
    -- another card's actions do not hold this one
    local e2 = entry(laundry, square(10, 10))
    p.x = 10.5
    tick(NEW, e2, p)
    q[1] = { name = "old card's", _zedCard = e }
    e2._ownQ = true
    p.x = 18.5
    check("ownRun: an action another card queued does not hold this one", tick(NEW, e2, p) == false)
    -- the press's own result and arguments pass through
    check("ownRun: passes the press's arguments and result", NEW.ownRun(e, p, function(a, b) return a + b end, 2, 3) == 5)
    check("ownRun: with no card just runs", NEW.ownRun(nil, p, function() return "ran" end) == "ran")
end

-- ---------------------------------------------------------------------------
-- PL1/OC2: the window's close drops the card; the upkeep off the draw
-- ---------------------------------------------------------------------------
local function loadClose(src, ocSrc)
    local drop = cut(src, "local function dropObjectCard(win, why)", "\nend")
    local close = cut(src, "local function _closeWorldWindow(w)", "\nend")
    local setEntry = cut(ocSrc, "function ZeD_ObjectCard:setEntry(entry)", "\nend")
    if not (drop and close and setEntry) then return nil end
    local env = { ZeD_WorldWindow = { _endZoneDraw = noop, _unlightAll = noop }, saveWorldState = noop,
                  ZeD = {}, _worldWins = {}, _floorContainers = {}, ZeD_ObjectCard = {}, OC = { REFRESH = 15 },
                  print = noop }
    local fn = run(setEntry .. "\n" .. drop .. "\n" .. close .. "\nreturn _closeWorldWindow", "close", env)
    return fn, env
end
do
    for _, c in ipairs({ { which = "new", ws = WWN, os = OCN, def = PLN }, { which = "old", ws = WWO, os = OCO, def = PLO } }) do
        if c.ws and c.def then
            local closeFn, env = loadClose(c.ws, c.os)
            if c.which == "new" then check("PL1: _closeWorldWindow, dropObjectCard and setEntry cut", closeFn ~= nil) end
            if closeFn then
                GIZ = {}
                local t = placeT(square(10, 10))
                local card = setmetatable({ scroll = { setScrollPos = noop }, entry = nil }, { __index = env.ZeD_ObjectCard })
                local e = { def = c.def, t = t }
                card:setEntry(e)
                local win = { playerNum = 0, removeFromUIManager = noop, _drawerObject = e, _objectCard = card, _drawerMode = "object" }
                env._worldWins[0] = win
                local ok, err = pcall(closeFn, win)
                if c.which == "new" then
                    check("PL1: the window's close runs", ok, err)
                    check("PL1: closing the window ends the game's placement (isDoingExtendedPlacement false)", t.item.doing == false, tostring(t.item.doing))
                    check("PL1: closing the window saves the placement (syncExtendedPlacement)", t.obj.synced == true)
                    check("PL1: closing the window puts the gizmo away", GIZ[0] == "none", tostring(GIZ[0]))
                    check("PL1: the card is out of the drawer", win._drawerObject == nil and card.entry == nil)
                    -- a pinned trade stays pinned, as on a tab switch
                    local tr = { def = { pinned = function() return true end, onClose = function() error("closed a pinned card") end }, t = {} }
                    local card2 = setmetatable({ scroll = { setScrollPos = noop }, entry = tr }, { __index = env.ZeD_ObjectCard })
                    local win2 = { playerNum = 1, removeFromUIManager = noop, _drawerObject = tr, _objectCard = card2 }
                    check("PL1: a pinned card is left pinned by the window's close", pcall(closeFn, win2) and win2._drawerObject == tr)
                else
                    check("PL1 (old code shows the bug): the window's close leaves the placement on", t.item.doing == true)
                end
            end
        end
    end
end
-- the upkeep off the draw
do
    local up = cut(OCN, "function OC.upkeep()", "\nend")
    local keep = cut(OCN, "function ZeD_ObjectCard:keep(e, player)", "\nend")
    check("OC2: OC.upkeep and ZeD_ObjectCard:keep exist (none in the old code)", up and keep)
    check("OC2: OC.upkeep runs on the game's tick", OCN and string.find(OCN, "Events.OnTick.Add(OC._upkeepHook)", 1, true) ~= nil)
    if up and keep and NEW then
        local CLOCK = 10000
        local cards = {}
        local env = { OC = NEW, ZeD_ObjectCard = {}, ZeD = { logOnce = noop },
                      ZeD_WorldWindow = { getObjectCard = function(pn) return cards[pn] end },
                      getTimestampMs = function() return CLOCK end }
        local P = player(10.5, 10.5)
        env.getSpecificPlayer = function(pn) return pn == 0 and P or nil end
        run(keep .. "\n" .. up, "upkeep", env)
        local closed = 0
        local laundry = kind({ id = "laundry" })
        local e = entry(laundry, square(10, 10))
        local card = setmetatable({ entry = e, _drawnAt = CLOCK, close = function() closed = closed + 1 end },
            { __index = env.ZeD_ObjectCard })
        cards[0] = card
        P.x = 30.5
        NEW._upkeepAt = nil
        NEW.UPKEEP_MS = tonumber(OCN:match("OC%.UPKEEP_MS = (%d+)"))
        NEW.UNDRAWN_MS = tonumber(OCN:match("OC%.UNDRAWN_MS = (%d+)")) or NEW.UPKEEP_MS
        NEW.upkeep()
        check("OC2: a card drawn this frame is left to its own draw", closed == 0, closed)
        CLOCK = CLOCK + 1000          -- (rolled up: a second with no draw)
        NEW.upkeep()
        check("OC2: a card not drawn for a second gets its leash from the upkeep", closed == 1, closed)
        local n0 = closed
        CLOCK = CLOCK + 100
        NEW.upkeep()
        -- (QA PL3 second pass: the upkeep now runs every tick, so a walk at fast-forward cannot outrun the leash)
        check("OC2: the upkeep runs again on the next tick (every tick now)", closed == n0 + 1, closed)
        -- (the placement card through the upkeep: the card's close ends its placement as the window's does)
    end
end

-- ---------------------------------------------------------------------------
-- TK1 / TK3: the track card
-- ---------------------------------------------------------------------------
local trackEnv = { instanceof = function(o, cls) return type(o) == "table" and o._cls == cls end,
                   getTexture = function() return nil end }
local TKN, tkErr = loadKind(readFile(Z .. "ObjectCardTrack.lua"), trackEnv)
local TKO = loadKind(baseFile("ObjectCardTrack.lua"), trackEnv)
check("ObjectCardTrack.lua loads on the stubs", TKN ~= nil, tkErr)
local function green(def)
    local _, c, m = def.pill({ d = { fresh = "More than 4 days" } })
    local s = m or c
    return s ~= nil and s.green == true
end
if TKN then check("TK1: an old track's freshness tag has no green mark", not green(TKN)) end
if TKO then check("TK1 (old code shows the bug): the tag was green", green(TKO)) end
do
    for _, c in ipairs({ { which = "new", def = TKN, OC = NEW }, { which = "old", def = TKO, OC = OLD } }) do
        if c.def and c.OC then
            local ground = square(10, 10)
            local wi = { getSquare = function() return ground end }
            local inBag = false
            local item = { getAnimalTracks = function() return {} end,
                           getWorldItem = function() return (not inBag) and wi or nil end,
                           isInPlayerInventory = function() return inBag end,
                           getContainer = function() return nil end }
            local p = player(10.5, 10.5)
            local t = c.def.resolve(p, item)
            local e = { def = c.def, t = t }
            t.d = {}
            t.at = { getTrackType = function() return "footstep" end }
            local a0 = t and t.sq == ground and tick(c.OC, e, p)
            inBag = true            -- he picks it up and walks 7 tiles
            p.x = 17.5
            local a1 = tick(c.OC, e, p)
            if c.which == "new" then
                check("TK3: a track on the ground counts from its square", a0 == true, a0)
                check("TK3: one he carries keeps its card 7 tiles from where it lay", a1 == true, a1)
                check("TK3: one he carries has no square (no leash)", t.sq == nil)
                inBag = false
                ground = square(17, 10)
                check("TK3: one he drops again counts from where it lies now", tick(c.OC, e, p) == true and t.sq == ground)
            else
                check("TK3 (old code shows the bug): the carried track's card closed at 7 tiles", a1 == false, a1)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- PV3: the build preview's strength and the skill level
-- ---------------------------------------------------------------------------
local LVL = 2
local script = { getIsThumpable = function() return true end, getHealth = function() return 200 end,
                 getSkillBaseHealth = function() return 50 end, getBonusHealth = function() return 0 end }
local info = { getScript = function() return script end, isSingleFace = function() return true end,
               getFace = function() return nil end, getMainSpriteNameUI = function() return nil end }
local pvEnv = { BuildLogic = { new = function() return { setRecipes = noop, getAllBuildableRecipes = function() return {} end,
                setRecipe = noop, getSelectedBuildObject = function() return info end } end },
                getTexture = function() return nil end, Perks = {} }
local PVN, pvErr = loadKind(readFile(Z .. "ObjectCardPreview.lua"), pvEnv)
local PVO = loadKind(baseFile("ObjectCardPreview.lua"), pvEnv)
check("ObjectCardPreview.lua loads on the stubs", PVN ~= nil, pvErr)
local function strengths(def)
    LVL = 2
    local recipe = { getHighestRelevantSkillLevel = function() return LVL end, getHighestRelevantSkill = function() return nil end }
    local entry = { name = "Log Wall", recipe = recipe, skillDefs = { { name = "Carpentry", required = 2 } }, iconTex = {} }
    local t = { entry = entry, obj = { config = { prefix = "build" }, state = { selected = "Log Wall" } }, face = 1 }
    local ok1, e1 = pcall(def.refresh, t, {})
    local s1 = ok1 and t.d and t.d.strength
    LVL = 4
    local ok2, e2 = pcall(def.refresh, t, {})
    local s2 = ok2 and t.d and t.d.strength
    return tonumber(tostring(s1):match("^%d+")), tonumber(tostring(s2):match("^%d+")), (ok1 and ok2) or (e1 or e2)
end
if PVN then
    local a, b, ok = strengths(PVN)
    check("PV3: the refresh runs", ok == true, ok)
    check("PV3: strength 300 at Carpentry 2", a == 300, a)
    check("PV3: strength 400 once Carpentry is 4, with the card open", b == 400, b)
end
if PVO then
    local _, b = strengths(PVO)
    check("PV3 (old code shows the bug): it stayed at 300", b == 300, b)
end

print("oc_leash_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
