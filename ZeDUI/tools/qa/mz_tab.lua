-- ZeDUI/tools/qa/mz_tab.lua  (Nov 27 2026, QA; tag mz_tab): the World window's Maps tab, the gamut sweep: the drawer
-- map, its unfolded window, the marks and notes, the three styles and Survey's colors, the key, the flyer pins, paper
-- maps read from the inventory. Its spec is the map ZeDUI/qa/audits/2026-11-27_map_maps.md (cases MP1-MP66, suspicions
-- B1-B15). Run after zedqa_prelude.lua and rt_kit.lua (mz.txt). grep "ZEDQA mz_tab". Built on mt_tab.lua and
-- oca_tab.lua (the helpers, the pad, the pictures, the put-back).
-- HOW IT JUDGES: against the game's own answers: the world map's store (MapItem.getSingleton()'s symbols through
-- ZeD.MapNotes.api(): ids, words, places, colors), the map engine (getCenterWorldX/Y, getZoomF, getBoolean, the style
-- layers' fills and line heights), the game's rules (ISWorldMap.IsAllowed, NeedsLight, checkKey, ToggleWorldMap's own
-- refusal, tooDarkToRead, ISWorldMapSymbols' pens by type or tag, the inventory's eraser), its queue (ISReadWorldMap,
-- ISReadMapItem, the transfer), its menus (the inventory's Read Map), its paper windows (ISMapWrapper) and its sets
-- (getReadPrintMedia, StashSystem.getAlreadyReadMap, PrintMediaDefinitions). What the tab drew is read from its draw
-- (the words drawn on the drawer, the unfolded window and the map; the icon buttons' greyed look; Survey's printed
-- additions counted as they draw). A FAIL carries both sides.
-- HOW IT PRESSES: a click is the drawer's (or the unfolded window's) own mouse handler at a zone's middle, or the map
-- panel's own handler at a map point; the pointer over the map (the wheel, a drag, the hover card) is the map's
-- getMouseX/Y answered for the leg. The pad goes through FocusManager's QA hook and dispatch (focus by focusWhere in
-- worldTabContent or popMapContent), the input mode locked to the controller and put back; the stick and the triggers
-- are their own steps (gpMoveCursor, gpZoom: no pad is bound on the rig).
-- WHAT IS NEVER CHANGED FOR GOOD: the areas he has seen. A paper's reveal (MapUtils.revealKnownArea) and Show on map's
-- known squares (WorldMapVisited, the Lua callers) are recorded with their bounds and held back for the whole run; no
-- stash map is read. The world map's marks: the list is saved at the start (each mark itself and what it is), every
-- mark the run adds is taken off after each case and at the end, and none of his is touched (a menu is used only on
-- the run's own mark under the pointer).
-- Cases (MP<n>: the map's cases; B<n>: its suspicions, each a check that proves or clears it; mouse and pad):
--   MP1  the tab: a fresh map on him at zoom 18 in his style (mouse: the strip; pad: the D-pad World wheel's Tabs > Maps)
--   MP15 fog of war on all three styles (HideUnvisited); MapAllKnown SKIP (a new game). MP16 the player dots; remote SKIP
--   MP2  the Map key (the game's key handlers): ISReadWorldMap queued, ZeD's map unfolded, the game's map shut
--   MP3  put away by M, Escape, the pad's B and the close box, the World window shut and open before
--   MP5  the key held 500 ms: the game's radial with World map, no mini-map slice; letting go as the game's key toggle option says
--   MP6  paused: the Map key folds ZeD's map (B11), Escape; a paper up and the world map off keep the game's refusal
--   MP7  the World wheel's Map slice; greyed "No world map" with AllowWorldMap off
--   MP8  the HUD's map button (ISEquippedItem's MAP press)
--   MP12 AllowWorldMap off: "Map unavailable", no stops, M does nothing; unfolded, the one stop and A folds
--   MP14 the Tutorial SKIP; MP11 split screen SKIP
--   MP17 Survey, Color, Paper by the mouse and the pad: style kept, three frames off screen, center kept, Paper's zoom,
--        the engine's ground; the old ZeD_MapPaper opens on Paper
--   MP18 the style box (half card, Large text): mouse, pad (A, B), a press elsewhere, a walk
--   MP19 the light map switch: shown on Survey under Dark only; mouse and pad flip it (the water layer's color)
--   MP20 theme and status colors: one restyle each, the palette key, building-Medical's color blind fill
--   MP21 the game's colorblind patterns option (a NOTE of what follows it)
--   MP22 Survey's printed additions at 12, 13.5, 15, 17.5, 20; B4 badges over unseen ground. Picture mz_survey_<WxH>
--   MP23 stash map icons (SKIP when he has read none) and a click on one
--   MP24 flyer pins: the pin at its place, the hover card, a visit within a second, the click and A open the reader
--   MP25 the labels: line heights against the UI scale, Paper's names hidden, notes kept
--   MP9  Show on map from the reader (mouse; pad A): known squares asked, the read, the landing, the pulse; B5 (Paper)
--   MP26 the key: pages, the page inside the map (its columns a NOTE), close box (mouse; pad); on Color, Show survey
--   MP27 zoom: the wheel to 24 and back, the trigger's step, the drawer's wheel
--   MP28 pan: a drag, a release off the map, a drag under 4 units; the stick's cursor at the margins
--   MP29 opening again: the drawer map kept, the unfolded one on him at 18
--   MP30 no pen: greyed marks and Aa, the game's "can't write" (mouse; pad)
--   MP31 the 15 marks in the 5 inks: the game's symbol, the pen's color, its scale, the tool kept (mouse); a pad mark.
--        Picture mz_world_<WxH>
--   MP32 the ink rules (only a pencil, a pen put away, the last pen put away); MP33 the first ink against the game's
--   MP34 a note (the box's words, spaces only, illiterate); MP35 the pad's note (B3: the map:note stop, its keyboard, the typed words; Edit note by the pad)
--   MP36 pins: right-click and X in the full set; the header at the half card
--   MP37 Delete (a note, a symbol; no eraser; the pad's X); MP38 Change color (B10; illiterate); MP39 Edit note
--   MP40 the hit test (two marks 10 px apart, a town's name, the pad's X 15 px off); MP42 the old marks carried over
--   MP43, MP44, MP45 SKIP (multiplayer)
--   MP46 unfold and fold every way (button, placeholder, A, B, Escape, close box) and the drawer map kept
--   MP47 Escape with the note box focused; MP48 unfolded with the World window on Loot (B9: drawing; the drawer's wheel taken while unfolded, zooming folded)
--   MP49 the World window shut while unfolded; MP50 the unfolded window at 600 by 400 and full screen; MP51 SKIP
--   MP52 Read Map (B1: the game's read action whole, the window at its end), the window, the reveal asked, the paper's band and key. Picture
--        mz_paper_<WxH>
--   MP53 a map in a bag and on the floor; MP54 marks on a paper (B2 SKIP: multiplayer); MP55 the paper dropped or bagged
--   MP56 paper over paper, M with a paper up, Read Map over the world map; MP57 every town and Louisville map drawn;
--   MP58 SKIP (a stash map places its stash for good)
--   MP60 the drawer's stop order, the D-pad walk, the cursor's B; MP61 the unfolded window's stops
--   MP62 the side list (a test extension the run adds and takes away): rows, X, Cancel and Delete, B6, the wheel, docked
--   MP63 other mods' extensions (SKIP each not loaded); MP65 Lite; MP66 the game's mini-map hidden
--   night: MP4 the key in the dark, MP13 the tab in the dark (MapNeedsLight off, the light back), B12 a lit open map stays open into the
--        dark; a map opened in the dark refused, A folds it, back with the light; MP59 a paper in the dark and the game's greyed Read Map (a debug game stages ZeD's rule, said so)
--   MP4's car legs at night: a live battery, a flat one, a torch (SKIP in a debug game); admin SKIP
--   B13 a map that failed to build (one build made to fail: made again within about 2 s, the failed mark cleared)
--   MP10 safe mode (the game's map, its paper window, the mini-map) with MP41 (ZeD's marks on the game's map)
--   MP64 small screens: UI scale 1.5 and 2 with Large text at the half card (and MP25's label heights at each)
--   B7, B8 SKIP (split screen); B14, B15 and the FEATURE_MAP rows: NOTEs
--   every case: no Lua error over it, none of the run's marks left
-- Puts back: every mark the run made on the world map (his own as found, checked by place and color), every area of
-- the map held back (nothing revealed or forgotten), every item given (the pens, the eraser, the maps, the bags, the
-- torch) and his own pens and erasers set aside, the pieces counted read, the flyer visits (ZeD_FlyerSeen), the pinned
-- marks, the map style (ZeD_MapStyle, ZeD_MapPaper), the old marks (ZeD_MapAnnotations, ZeD_MapNotesMoved), literacy,
-- the sandbox's AllowWorldMap and MapNeedsLight, the theme, text size, status colors, the light map switch, Lite, safe
-- mode, the UI scale, the game's colorblind patterns option, the input lock, the pointer, the World window's tab, width
-- cap, fold, key, list, tool, ink, note words and the drawer map's view and style, the hooks (the draw watchers, the
-- halo, the context menu, the reveal hold, the extension), the car (the prelude's removal), the clock, instant actions,
-- game speed 1, where he stood, god mode and invincible as found.

if not (RT and RT.make) then
    print("ZEDQA mz_tab ERR rt_kit.lua did not run first")
    print("ZEDQA mz_tab VERDICT FAIL 1")
    print("ZEDQA mz_tab DONE")
    return
end
local Q = RT.make("mz_tab")
Q.maxMs = 2250000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, shots = {}, errs = 0, dead = false,
            said = {}, texts = {}, tNow = {}, btns = {}, bNow = {}, halo = {}, ctxCalls = {}, reveals = {}, known = {},
            hooked = {}, frame = 0, restyles = 0, stash = {}, keep = {}, readAdded = {} }
local H = {}
local C = {}
S.MT = ZeD and ZeD.MapsTab
S.N = ZeD and ZeD.MapNotes
S.E = ZeD and ZeD.MapsTabExt
S.F = RT.focus()
S.PENS = { "Base.Pencil", "Base.Pen", "Base.BluePen", "Base.RedPen", "Base.GreenPen" }
S.PEN_TYPES = { "Pencil", "Pen", "BluePen", "RedPen", "GreenPen" }
S.ERASER = "Base.Eraser"
S.ICONS = { "house", "target", "skull", "star", "cross", "heart", "exclamation", "question", "fire", "gun", "burger",
            "axe", "gears", "x", "checkmark" }
S.DEFAULT_PINS = { "house", "target", "skull", "star", "cross", "checkmark" }
-- the game's order for the first pen at hand (ISWorldMapSymbols:createChildren, colorButtonInfo)
S.GAME_PEN_ORDER = { "Pen", "Pencil", "RedPen", "BluePen", "GreenPen" }
S.TOWN_MAPS = { "Base.MuldraughMap", "Base.WestpointMap", "Base.RosewoodMap", "Base.RiversideMap", "Base.MarchRidgeMap",
                "Base.LouisvilleMap1", "Base.LouisvilleMap2", "Base.LouisvilleMap3", "Base.LouisvilleMap4", "Base.LouisvilleMap5",
                "Base.LouisvilleMap6", "Base.LouisvilleMap7", "Base.LouisvilleMap8", "Base.LouisvilleMap9" }

if not (S.p and S.MT and S.N and S.E and ZeD_WorldWindow and ZeD.Molecules and ISWorldMap and S.F) then
    Q.check(false, "the player, ZeD's Maps tab, its marks, its extensions, the World window and the pad's focus manager are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers (mt_tab's)
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.note(s) Q.say("NOTE " .. tostring(s)) end
-- time, not frames: cond asked every drawn frame until it holds, at most ms; fn(ok)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 4000000, function()
        if S.dead then return true end
        local now = getTimestampMs()
        st.t = st.t or now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() if S.dead then return end; fn(st.ok == true) end)
end
function H.pause(ms) Q.waitMs(ms) end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.list(t, max)
    local o = {}
    for i, v in ipairs(t or {}) do
        if max and i > max then o[#o + 1] = "..."; break end
        o[#o + 1] = tostring(v)
    end
    return (#o > 0) and table.concat(o, ", ") or "none"
end
function H.n1(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.1f", x) end
function H.n2(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.2f", x) end
function H.n3(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.3f", x) end
function H.screen() local w, h = 0, 0; pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end); return math.floor(w), math.floor(h) end
function H.sizeTag() local w, h = H.screen(); return w .. "x" .. h end
function H.isDeck() local w, h = H.screen(); return w == 1280 and h == 800 end
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z or 0)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z or 0)
    end)
end
function H.home() local f = S.found; if f.pos then H.goTo(f.pos.x, f.pos.y, f.pos.z) end; if f.dir then pcall(function() S.p:setDir(f.dir) end) end end
function H.zcall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.has(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(s, sub, 1, true) ~= nil end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.txt(k) local s = nil; pcall(function() s = getText(k) end); return s or k end
function H.tr(k, ...) local s = k; local a = { ... }; pcall(function() s = ZeD.tr(k, a[1], a[2], a[3]) end); return s end
function H.debug() local d = false; pcall(function() d = getCore():getDebug() and true or false end); return d end
function H.sizeCheck(ok, what, detail)
    if H.isDeck() then return Q.check(ok, what, detail) end
    H.note(what .. ": " .. (ok and "holds" or "does not hold") .. " at " .. H.sizeTag() .. " (checked only at 1280x800): " .. tostring(detail))
    return ok
end
function H.px(n) local v = n; pcall(function() v = ZeD.T.px(n) end); return v end

-- ===================================================================== the game's queue
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 10) end
function H.qfirst(ty) for _, a in ipairs(H.queue()) do if a.Type == ty then return a end end; return nil end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.instant(on) pcall(function() S.p:setTimedActionInstantCheat(on and true or false) end) end

-- ===================================================================== things (mt_tab's)
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.inv() return S.p:getInventory() end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.walkInv(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walkInv(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walkInv, H.inv(), out, 0); return out end
function H.count(ft) local n = 0; for _, it in ipairs(H.all()) do if H.ft(it) == ft then n = n + 1 end end; return n end
function H.mark(it, keep)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    if keep then S.keep[it] = true else S.caseMade[#S.caseMade + 1] = it end
    return it
end
function H.give(ft, keep) if not ft then return nil end; local it = nil; pcall(function() it = H.inv():AddItem(ft) end); return H.mark(it, keep) end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
function H.loose(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
end
function H.removeItem(it)
    if not H.isItem(it) then return end
    H.loose(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.gone(it) local wo = nil; pcall(function() wo = it:getWorldItem() end); return H.where(it) == nil and wo == nil end
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.found.inv0[it] and not S.keep[it] then H.removeItem(it); n = n + 1 end
    end
    return n
end
function H.hands()
    local f = S.found
    if not f.hands then return end
    pcall(function()
        local a, b = f.hands.p, f.hands.s
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
end
-- a pen, a pencil or an eraser by the game's own tests (the type, or the tag ISWorldMapSymbols looks for)
function H.penLike(it)
    local t = ""
    pcall(function() t = tostring(it:getType()) end)
    for _, p in ipairs(S.PEN_TYPES) do if t == p then return true end end
    if t == "Eraser" then return true end
    local yes = false
    pcall(function()
        for _, p in ipairs(S.PEN_TYPES) do if it:hasTag(ItemTag.get(ResourceLocation.of(p))) then yes = true end end
        if it:hasTag(ItemTag.ERASER) then yes = true end
    end)
    return yes
end
-- his own pens, pencils and erasers set aside (the ink rules are staged with the run's own), back at the end
function H.stashPens()
    local kept = 0
    for _, it in ipairs(H.all()) do
        if S.found.inv0[it] and H.penLike(it) then
            local c, free = nil, false
            pcall(function()
                c = it:getContainer()
                free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
                    and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
            end)
            if c and free and pcall(function() c:Remove(it) end) then S.stash[#S.stash + 1] = { it = it, c = c }
            else kept = kept + 1 end
        end
    end
    return #S.stash, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
-- the pens and the eraser he carries for a leg: want = { Pencil = true, ... , Eraser = true } (only the run's own move)
function H.kit(want)
    want = want or {}
    local all = {}
    for _, t in ipairs(S.PEN_TYPES) do all[#all + 1] = t end
    all[#all + 1] = "Eraser"
    for _, t in ipairs(all) do
        local ft = "Base." .. t
        local mine = {}
        for _, it in ipairs(H.all()) do if H.ft(it) == ft and not S.found.inv0[it] then mine[#mine + 1] = it end end
        if want[t] and #mine == 0 then H.give(ft) end
        if not want[t] then for _, it in ipairs(mine) do H.removeItem(it) end end
        if want[t] and #mine > 1 then for i = 2, #mine do H.removeItem(mine[i]) end end
    end
end
function H.fullKit() H.kit({ Pencil = true, Pen = true, BluePen = true, RedPen = true, GreenPen = true, Eraser = true }) end
function H.penOf(t) for _, it in ipairs(H.all()) do if H.ft(it) == "Base." .. t and not S.found.inv0[it] then return it end end; return nil end
-- what the game itself says he can write and erase with (ISWorldMapSymbols canWrite / canErase, by type or tag)
function H.gameCanWrite()
    local yes = false
    pcall(function()
        local inv = H.inv()
        for _, p in ipairs(S.PEN_TYPES) do
            if inv:containsTagRecurse(ItemTag.get(ResourceLocation.of(p))) or inv:containsTypeRecurse(p) then yes = true end
        end
    end)
    return yes
end
function H.gameHasPen(t)
    local yes = false
    pcall(function() local inv = H.inv(); yes = inv:containsTagRecurse(ItemTag.get(ResourceLocation.of(t))) or inv:containsTypeRecurse(t) end)
    return yes and true or false
end
function H.gameCanErase()
    local yes = false
    pcall(function() local inv = H.inv(); yes = inv:containsTypeRecurse("Eraser") or inv:containsTagRecurse(ItemTag.ERASER) end)
    return yes and true or false
end
function H.hasTrait(key) local h = false; pcall(function() h = S.p:hasTrait(CharacterTrait[key]) and true or false end); return h end
function H.traitSet(key, on)
    pcall(function()
        local ct = CharacterTrait[key]
        if not ct then return end
        if on and not S.p:hasTrait(ct) then S.p:getCharacterTraits():add(ct) end
        if not on and S.p:hasTrait(ct) then S.p:getCharacterTraits():remove(ct) end
    end)
end

-- ===================================================================== the world map's store (the game's own marks)
-- the store is MapItem.getSingleton()'s symbols, through ZeD.MapNotes.api() (one wrapper for the run, as the map's
-- own notes); only the player's marks (isUserDefined) are counted, the map's own labels are not
function H.store() local a = nil; pcall(function() a = S.N.api() end); return a end
function H.userSyms(api)
    local o = {}
    api = api or H.store()
    if not api then return o end
    pcall(function()
        for i = 0, api:getSymbolCount() - 1 do
            local s = api:getSymbolByIndex(i)
            if s and s:isUserDefined() then o[#o + 1] = s end
        end
    end)
    return o
end
function H.sig(s)
    local t = "?"
    pcall(function()
        local what = s:isText() and ("note '" .. tostring(s:getTranslatedText()) .. "'") or tostring(s:getSymbolID())
        t = what .. string.format(" at %.1f,%.1f rgb %.3f,%.3f,%.3f", s:getWorldX(), s:getWorldY(), s:getRed(), s:getGreen(), s:getBlue())
    end)
    return t
end
function H.marks() return #H.userSyms() end
function H.newSyms() local o = {}; for _, s in ipairs(H.userSyms()) do if not S.found.symSet[s] then o[#o + 1] = s end end; return o end
function H.lastNew() local n = H.newSyms(); return n[#n] end
function H.inStore(sym) for _, s in ipairs(H.userSyms()) do if s == sym then return true end end; return false end
-- every mark the run made, taken off the store (the player's own, found at the start, are never touched)
function H.removeNew()
    local api = H.store()
    if not (api and S.found.symSet) then return 0 end
    local n = 0
    pcall(function()
        for i = api:getSymbolCount() - 1, 0, -1 do
            local s = api:getSymbolByIndex(i)
            if s and s:isUserDefined() and not S.found.symSet[s] then api:removeSymbolByIndex(i); n = n + 1 end
        end
    end)
    return n
end
function H.rgbOf(s) local r, g, b = -1, -1, -1; pcall(function() r, g, b = s:getRed(), s:getGreen(), s:getBlue() end); return r, g, b end
function H.inkIs(s, idx)
    local k = S.N.INKS[idx]
    if not k then return false end
    local r, g, b = H.rgbOf(s)
    return math.abs(r - k.r) < 0.01 and math.abs(g - k.g) < 0.01 and math.abs(b - k.b) < 0.01
end
function H.inkName(s) local i = nil; pcall(function() i = S.N.inkOf(s) end); local k = i and S.N.INKS[i]; return k and k.item or "?" end

-- ===================================================================== the windows and the map
function H.ww() return RT.ww() end
function H.pop() local w = RT.ww(); return w and w._mapPopout or nil end
function H.mp() local w = RT.ww(); return w and w._worldMapPanel or nil end
function H.vis(e) local v = false; if e then pcall(function() v = e:isReallyVisible() and true or false end) end; return v end
function H.onMaps() local w = RT.ww(); return w ~= nil and w._activeTab == "maps" end
function H.mapUp() local mp = H.mp(); return H.onMaps() and mp ~= nil and H.vis(mp) and mp._styleWanted == nil end
function H.popUp() local pop = H.pop(); local mp = H.mp(); return pop ~= nil and H.vis(pop) and mp ~= nil and H.vis(mp) and mp._isPopoutMap == true end
function H.wwOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) and true or false end); return o end
function H.api() local mp = H.mp(); return mp and mp.mapAPI end
function H.cxy() local x, y = nil, nil; pcall(function() local a = H.api(); x, y = a:getCenterWorldX(), a:getCenterWorldY() end); return x, y end
function H.zoom() local z = nil; pcall(function() z = H.api():getZoomF() end); return z end
function H.mpWH() local w, h = 0, 0; pcall(function() local mp = H.mp(); w, h = mp:getWidth(), mp:getHeight() end); return w, h end
function H.toUI(wx, wy) local x, y = nil, nil; pcall(function() local a = H.api(); x, y = a:worldToUIX(wx, wy), a:worldToUIY(wx, wy) end); return x, y end
function H.toWorld(x, y) local wx, wy = nil, nil; pcall(function() local a = H.api(); wx, wy = a:uiToWorldX(x, y), a:uiToWorldY(x, y) end); return wx, wy end
function H.symUI(s) local x, y = nil, nil; pcall(function() x, y = H.toUI(s:getWorldX(), s:getWorldY()) end); return x, y end
function H.style() local mp = H.mp(); return mp and mp.style or nil end
function H.md() return S.p:getModData() end
function H.gameMapUp() local up = false; pcall(function() up = ISWorldMap_instance ~= nil and ISWorldMap_instance:isVisible() and true or false end); return up end
function H.tabState()
    local w, mp = RT.ww(), H.mp()
    local cx, cy = H.cxy()
    return "World " .. tostring(H.wwOpen()) .. ", tab " .. tostring(w and w._activeTab) .. ", unfolded " .. tostring(H.pop() ~= nil)
        .. ", map " .. tostring(mp ~= nil) .. " (seen " .. tostring(H.vis(mp)) .. ", style " .. tostring(mp and mp.style) .. ", zoom " .. H.n1(H.zoom())
        .. ", center " .. H.n1(cx) .. "," .. H.n1(cy) .. "), tool " .. tostring(w and w._mapActiveTool) .. ", queue " .. H.qkinds()
end
function H.blocked() local w = RT.ww(); return w ~= nil and w._mapBlocked == true end
-- a fresh map on the player: the map is made on the tab's first draw and kept for the window's life, so the World window
-- is shut and opened again (the pair as found otherwise)
function H.freshWindow()
    local w = RT.ww()
    if w and w._mapPopout then pcall(S.MT.closePopout, w, true) end
    pcall(ZeD_WorldWindow.close, S.pn)
    pcall(ZeD_WorldWindow.open, S.pn)
end
-- queue: the pair open on the Maps tab, nothing unfolded, the drawer map seen and settled (T.ok)
function H.tabQ(T, fresh)
    H.step(2, function()
        T.ok = nil
        if T.off then return end
        RT.pairOpen()
        local w = RT.ww()
        if w and w._mapPopout then pcall(S.MT.closePopout, w, true) end
        if fresh then H.freshWindow() end
        T.tq0 = getTimestampMs()
    end)
    H.wait(6000, function()
        if T.off then return true end
        if not H.onMaps() then RT.worldTab("maps") end
        return H.mapUp() and getTimestampMs() - (T.tq0 or 0) > 250
    end, function(ok)
        if T.off then return end
        T.ok = ok
        if not ok then T.off = true; Q.check(false, T.L .. ": the Maps tab opens with its map", H.tabState()) end
    end)
end
-- queue: the map unfolded by its header button (T.ok)
function H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        local w = RT.ww()
        if not (w and w._mapPopout) then H.click("map:popout", T.L) end
    end)
    H.wait(4000, function() return T.off or H.popUp() end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the header's unfold button opens the unfolded map", H.tabState()) then T.off = true end
    end)
end
-- a zone of the tab by its stop id, as the render left it this frame (tab or unfolded window coordinates)
function H.zone(fid)
    local w = RT.ww()
    if not (w and fid) then return nil end
    if fid == "map:disclosure" then return w._mapDisclosureZone end
    if fid == "map:popout" then return w._mapPopoutZone end
    if fid == "map:fold" then return w._mapFoldZone end
    if fid == "map:blocked" then return w._mapBlockedZone end
    if fid == "map:style:menu" then return w._mapStyleMenuZone end
    local id = fid:match("^map:tool:(.+)$")
    if id then for _, z in ipairs(w._mapToolZones or {}) do if z.id == id and not z.isGrid then return z end end; return nil end
    id = fid:match("^map:gridtool:(.+)$")
    if id then for _, z in ipairs(w._mapToolZones or {}) do if z.id == id and z.isGrid then return z end end; return nil end
    id = fid:match("^map:color:(%d+)$")
    if id then for _, z in ipairs(w._mapColorZones or {}) do if z.idx == tonumber(id) then return z end end; return nil end
    id = fid:match("^map:styleRow:(.+)$")
    if id then for _, z in ipairs(w._mapStyleMenuZones or {}) do if z.id == id then return z end end; return nil end
    id = fid:match("^map:style:(.+)$")
    if id then for _, z in ipairs(w._mapStyleZones or {}) do if z.id == id then return z end end; return nil end
    for _, z in ipairs(w._mapExtZones or {}) do if z.id == fid then return z end end
    return nil
end
function H.zoneIds()
    local w = RT.ww()
    local o = {}
    if not w then return o end
    for _, z in ipairs(w._mapToolZones or {}) do o[#o + 1] = (z.isGrid and "map:gridtool:" or "map:tool:") .. tostring(z.id) end
    for _, z in ipairs(w._mapColorZones or {}) do o[#o + 1] = "map:color:" .. tostring(z.idx) end
    for _, z in ipairs(w._mapStyleZones or {}) do o[#o + 1] = "map:style:" .. tostring(z.id) end
    if w._mapStyleMenuZone then o[#o + 1] = "map:style:menu" end
    for _, z in ipairs(w._mapExtZones or {}) do o[#o + 1] = tostring(z.id) end
    return o
end
-- a press where a player's click lands: the unfolded window's body while it is up (unless drawer), else the drawer
function H.press(x, y, drawer, right)
    local w = RT.ww()
    if not w then return false end
    local pop = w._mapPopout
    local panel = (pop and not drawer) and pop._contentPanel or w._drawerPanel
    if not panel then return false end
    return H.zcall(function()
        if right then panel:onRightMouseDown(x, y)
        else
            panel:onMouseDown(x, y)
            panel:onMouseUp(x, y)
        end
    end)
end
-- a click on a zone at its middle (the tab's own mouse path)
function H.click(fid, what, right)
    local z = H.zone(fid)
    if not z then
        if not S.said["nozone:" .. fid] then S.said["nozone:" .. fid] = true; H.note(tostring(what) .. ": " .. fid .. " is not drawn here (" .. H.list(H.zoneIds(), 30) .. ")") end
        return false
    end
    return H.press(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2), fid == "map:fold", right)
end
-- a press on the map itself (map-local), as the engine hands a click on the map to it
function H.mapClick(x, y)
    local mp = H.mp()
    if not mp then return false end
    return H.zcall(function() mp:onMouseDown(x, y); mp:onMouseUp(x, y) end)
end
function H.mapRight(x, y) local mp = H.mp(); if not mp then return false end; return H.zcall(function() mp:onRightMouseDown(x, y) end) end
-- the pointer over the map at (x, y) (map-local), for the wheel, the drag and the hover card
function H.fake(x, y)
    local mp = H.mp()
    if not mp then return end
    S.faked = S.faked or {}
    S.faked[mp] = true
    mp.getMouseX = function() return x end
    mp.getMouseY = function() return y end
    mp.isMouseOver = function() return true end
end
function H.fakeOff()
    for mp in pairs(S.faked or {}) do pcall(function() mp.getMouseX = nil; mp.getMouseY = nil; mp.isMouseOver = nil end) end
    S.faked = {}
end
-- a free spot for a mark in the map's middle: no mark of his within 30 px of it
function H.freeSpot(i)
    local w, h = H.mpWH()
    local cols = 6
    local k = (i or 1) - 1
    local col = k - math.floor(k / cols) * cols
    local row = math.floor(k / cols)
    local x = math.floor(w * 0.2 + col * (w * 0.6 / cols))
    local y = math.floor(h * 0.3 + (row - math.floor(row / 4) * 4) * (h * 0.4 / 4))
    for _ = 1, 24 do
        local clear = true
        for _, s in ipairs(H.userSyms()) do
            local sx, sy = H.symUI(s)
            -- (a note's words reach well to each side of its anchor: the engine's hit test takes the whole line)
            local isText = false
            pcall(function() isText = s:isText() and true or false end)
            local reach = isText and H.px(160) or H.px(30)
            if sx and math.abs(sx - x) < reach and math.abs(sy - y) < H.px(30) then clear = false end
        end
        if clear then return x, y end
        x = x + H.px(37)
        if x > w * 0.85 then x = math.floor(w * 0.15); y = y + H.px(31) end
    end
    return x, y
end

-- ===================================================================== the pad (mt_tab's, on the World window or the unfolded map)
function H.lockFound()
    local key = nil
    pcall(function()
        local o = H.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function H.padHome() local w = RT.ww(); if w and w._mapPopout then return w._mapPopout, "popMapContent" end; return w, "worldTabContent" end
function H.padOn()
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode and S.F) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    local hw = H.padHome()
    if hw then pcall(S.F.claimFocus, hw) end
    return true
end
function H.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function H.stops()
    local hw, zn = H.padHome()
    for _, z in ipairs((hw and hw._focusRing) or {}) do if z.zone == zn then return z.elements or {} end end
    return {}
end
function H.stopIds(pre)
    local o = {}
    for _, e in ipairs(H.stops()) do
        local id = tostring(e.id)
        if pre == nil or string.sub(id, 1, #pre) == pre then o[#o + 1] = id end
    end
    return o
end
function H.hasStop(id) for _, e in ipairs(H.stops()) do if e.id == id then return true end end; return false end
function H.focusedId() local el = nil; pcall(function() el = S.F.getFocusedElement((H.padHome())) end); return el and el.id or nil end
function H.focusEl(id)
    local hw, zn = H.padHome()
    if not (hw and id) then return false end
    pcall(S.F.claimFocus, hw)
    if hw._focusFresh then pcall(hw._focusFresh, hw) end
    local e = nil
    pcall(function() e = S.F.focusWhere(hw, zn, function(el) return el.id == id end) end)
    return e ~= nil
end
-- a tap queued on the window that holds the map's stops: down through the QA hook and FocusManager's dispatch, up 4
-- frames later, then the hook lets go (nothing is pressed when gate says no)
function H.tap(name, joy, gate)
    local st = {}
    H.step(1, function()
        local hw = H.padHome()
        if not hw then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], hw) end
    end)
    H.step(4, function() if st.on then RT.pad(name, false) end end)
    H.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function H.tapA(gate) H.tap("A", "AButton", gate) end
function H.tapB(gate) H.tap("B", "BButton", gate) end
function H.tapX(gate) H.tap("X", "XButton", gate) end
-- queue: the stop fid (or what fid() names when it runs) focused with the pad on, then A (T.focusOk)
function H.padPress(T, fid, gate, button)
    H.step(1, function()
        T.focusOk = nil
        if T.off or (gate and not gate()) then return end
        local id = fid
        if type(fid) == "function" then id = fid() end
        H.padOn()
        T.focusOk = H.focusEl(id)
        if not T.focusOk and not S.said["nostop:" .. tostring(id)] then
            S.said["nostop:" .. tostring(id)] = true
            H.note(T.L .. ": the pad's stop " .. tostring(id) .. " is not in the ring (" .. H.list(H.stopIds(), 24) .. ")")
        end
    end)
    H.tap(button or "A", (button == "X" and "XButton") or (button == "B" and "BButton") or "AButton", function() return not T.off and T.focusOk == true end)
end
-- the canvas's cursor placed at (x, y) of the map, the pad's focus on it
function H.cursorAt(x, y)
    local mp = H.mp()
    if not mp then return false end
    H.padOn()
    local ok = H.focusEl("map:canvas:cursor")
    pcall(function() mp:seedGpCursor() end)
    mp._gpCursorX, mp._gpCursorY = x, y
    return ok
end

-- ===================================================================== what the tab drew and said, watched (on for the run)
-- S.texts: the words drawn last frame on the drawer, the unfolded window's body and the map panel { s, x, y, p };
-- S.btns: the icon buttons drawn last frame by stop id { dis, act }; S.halo: words over his head; S.ctxCalls: the
-- game's context menu asked for (by whom); S.reveals: the map's areas the game was asked to make known (held back,
-- so the areas he has seen stay exactly as found); S.restyles: Survey's restyles; S.drawLast: what Survey's printed
-- additions drew in the last frame they were counted (S.drawRec on)
function H.hookPanel(p)
    if not p or S.hooked[p] then return end
    local orig = p.drawText
    if type(orig) ~= "function" then return end
    local own = nil
    pcall(function() own = rawget(p, "drawText") end)
    S.hooked[p] = { own = own }
    p.drawText = function(self, text, x, y, ...)
        local t = S.tNow
        if t and #t < 600 then t[#t + 1] = { s = tostring(text), x = x or 0, y = y or 0, p = self } end
        return orig(self, text, x, y, ...)
    end
end
function H.unhookPanels()
    for p, h in pairs(S.hooked) do pcall(function() p.drawText = h.own end) end
    S.hooked = {}
end
function H.hold(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded then pcall(function() w:setWindowShaded(false) end) end
    w._outSince = getTimestampMs() + 600000
end
function H.frameTick()
    pcall(function()
        S.frame = S.frame + 1
        S.texts, S.tNow = S.tNow, {}
        S.btns, S.bNow = S.bNow, {}
        -- (MP17: the frames the map is off the screen, counted every frame from the press, the pad's included)
        local hw = S.hidWatch
        if hw then
            local mp = H.mp()
            if mp and mp.isVisible and not mp:isVisible() then hw.n = hw.n + 1 end
        end
        if S.holdOn then H.hold(RT.ww()); H.hold(RT.cw()) end
        local w = RT.ww()
        if w then
            H.hookPanel(w._drawerPanel)
            if w._mapPopout then H.hookPanel(w._mapPopout._contentPanel) end
            H.hookPanel(w._worldMapPanel)
        end
        if S.guard and not S.p:isDead() then
            if not S.p:isGodMod() then S.p:setGodMod(true) end
            if not S.p:isInvincible() then S.p:setInvincible(true) end
        end
    end)
end
function H.drew(sub) for _, t in ipairs(S.texts or {}) do if H.has(t.s, sub) then return t end end; return nil end
function H.drewOn(p, sub) for _, t in ipairs(S.texts or {}) do if t.p == p and H.has(t.s, sub) then return t end end; return nil end
function H.textsLike(sub, max) local o = {}; for _, t in ipairs(S.texts or {}) do if H.has(t.s, sub) then o[#o + 1] = t.s end end; return H.list(o, max or 6) end
function H.btn(id) return (S.btns or {})[id] end
function H.saidSince(t0) local o = {}; for _, h in ipairs(S.halo) do if h.t >= (t0 or 0) then o[#o + 1] = h.text end end; return o end
function H.said(t0, key) local w = H.txt(key); for _, s in ipairs(H.saidSince(t0)) do if s == w or H.has(s, w) then return true end end; return false end
function H.ctxSince(t0) local n = 0; for _, c in ipairs(S.ctxCalls) do if c.t >= (t0 or 0) then n = n + 1 end end; return n end

function H.hooksOn()
    if S.w0 then return end
    local W = { dib = ZeD.Molecules.drawIconButton, halo = {} }
    S.w0 = W
    S.realWMV = WorldMapVisited
    S.realRKA = MapUtils and MapUtils.revealKnownArea
    W.dibFn = function(panel, x, y, s, pic, o, ...)
        if type(o) == "table" and o.id and S.bNow then S.bNow[o.id] = { dis = o.disabled == true, act = o.active == true } end
        return W.dib(panel, x, y, s, pic, o, ...)
    end
    ZeD.Molecules.drawIconButton = W.dibFn
    if HaloTextHelper then
        for _, k in ipairs({ "addText", "addBadText", "addGoodText" }) do
            local orig = HaloTextHelper[k]
            if orig then
                local fn = function(pl, text, ...)
                    S.halo[#S.halo + 1] = { text = tostring(text), t = getTimestampMs() }
                    return orig(pl, text, ...)
                end
                W.halo[k] = { orig = orig, fn = fn }
                HaloTextHelper[k] = fn
            end
        end
    end
    -- the game's context menu: who asked for it (B7)
    W.ctx = ISContextMenu and ISContextMenu.get
    if W.ctx then
        W.ctxFn = function(player, x, y, ...)
            S.ctxCalls[#S.ctxCalls + 1] = { pn = player, t = getTimestampMs() }
            return W.ctx(player, x, y, ...)
        end
        ISContextMenu.get = W.ctxFn
    end
    -- the paper's reveal (MapUtils.revealKnownArea, the game's): recorded with its bounds, NOT done, so the areas the
    -- character has seen come back exactly as found
    W.rka = MapUtils and MapUtils.revealKnownArea
    if W.rka then
        W.rkaFn = function(mapUI)
            local r = { t = getTimestampMs() }
            pcall(function()
                local a = mapUI.javaObject:getAPIv1()
                r.x1, r.y1, r.x2, r.y2 = a:getMinXInSquares(), a:getMinYInSquares(), a:getMaxXInSquares(), a:getMaxYInSquares()
            end)
            S.reveals[#S.reveals + 1] = r
        end
        MapUtils.revealKnownArea = W.rkaFn
    end
    -- WorldMapVisited for the Lua callers (Show on map): setKnownInSquares and forget recorded, NOT done; every other
    -- call goes to the game's own
    W.wmv = WorldMapVisited
    if W.wmv then
        local real = nil
        pcall(function() real = W.wmv.getInstance() end)
        local inst = {
            setKnownInSquares = function(_, x1, y1, x2, y2) S.known[#S.known + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, t = getTimestampMs() } end,
            setVisitedInSquares = function(_, x1, y1, x2, y2) S.known[#S.known + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, visited = true, t = getTimestampMs() } end,
            forget = function() S.known[#S.known + 1] = { forget = true, t = getTimestampMs() } end,
        }
        setmetatable(inst, { __index = function(_, k)
            return function(_, ...) local f = real and real[k]; if f then return f(real, ...) end; return nil end
        end })
        local cls = { getInstance = function() return inst end, Reset = function() S.known[#S.known + 1] = { reset = true } end }
        setmetatable(cls, { __index = W.wmv })
        W.real = real
        W.wmvFake = cls
        WorldMapVisited = cls
    end
    -- Survey's restyles counted; its printed additions counted while S.drawRec is set
    local MS = ZeD.MapsSurvey
    if MS then
        W.rs, W.dm = MS.restyle, MS.drawMap
        W.rsFn = function(mp, ...) S.restyles = S.restyles + 1; return W.rs(mp, ...) end
        W.dmFn = function(mp, win, ...)
            if not S.drawRec then return W.dm(mp, win, ...) end
            local oT, oR = nil, nil
            pcall(function() oT, oR = rawget(mp, "drawTextureScaled"), rawget(mp, "drawRect") end)
            local bT, bR = mp.drawTextureScaled, mp.drawRect
            local n = { tex = 0, shield = 0, rect = 0, at = {} }
            mp.drawTextureScaled = function(self, t, x, y, w, h, ...)
                local nm = ""
                pcall(function() nm = tostring(t:getName()) end)
                if H.has(nm, "shield_") then n.shield = n.shield + 1
                else
                    n.tex = n.tex + 1
                    if #n.at < 200 then n.at[#n.at + 1] = { x = (x or 0) + (w or 0) / 2, y = (y or 0) + (h or 0) / 2 } end
                end
                return bT(self, t, x, y, w, h, ...)
            end
            mp.drawRect = function(self, ...) n.rect = n.rect + 1; return bR(self, ...) end
            local ok, err = pcall(W.dm, mp, win, ...)
            mp.drawTextureScaled, mp.drawRect = oT, oR
            n.z = H.zoom()
            S.drawLast = n
            if not ok then error(err, 0) end
        end
        MS.restyle, MS.drawMap = W.rsFn, W.dmFn
    end
    W.tick = H.frameTick
    Events.OnPreUIDraw.Add(W.tick)
end
function H.hooksOff()
    local W = S.w0
    if not W then return end
    if ZeD.Molecules.drawIconButton == W.dibFn then ZeD.Molecules.drawIconButton = W.dib end
    for k, e in pairs(W.halo or {}) do if HaloTextHelper[k] == e.fn then HaloTextHelper[k] = e.orig end end
    if W.ctxFn and ISContextMenu.get == W.ctxFn then ISContextMenu.get = W.ctx end
    if W.rkaFn and MapUtils.revealKnownArea == W.rkaFn then MapUtils.revealKnownArea = W.rka end
    if W.wmvFake and WorldMapVisited == W.wmvFake then WorldMapVisited = W.wmv end
    local MS = ZeD.MapsSurvey
    if MS and W.rsFn then
        if MS.restyle == W.rsFn then MS.restyle = W.rs end
        if MS.drawMap == W.dmFn then MS.drawMap = W.dm end
    end
    pcall(function() Events.OnPreUIDraw.Remove(W.tick) end)
    H.unhookPanels()
    S.w0 = nil
end
function H.hooksBack()
    local W = S.w0
    if not W then return true end
    return ZeD.Molecules.drawIconButton == W.dib
end

-- ===================================================================== settings (cr_tab's and oca_tab's), the game's options
function H.theme(key)
    local o = H.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function H.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = H.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function H.status(key)
    local o = ZeD.Settings and ZeD.Settings.statusColorsOption
    local i = nil
    for k, v in ipairs((ZeD.Settings and ZeD.Settings.statusKeys) or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    ZeD.currentStatus = key
    S.back.status = true
end
function H.statusBack()
    if not S.back.status then return end
    S.back.status = nil
    local o = ZeD.Settings and ZeD.Settings.statusColorsOption
    if o and S.found.statusIdx then pcall(function() o:setValue(S.found.statusIdx) end) end
    ZeD.currentStatus = S.found.status
end
function H.sizeSet(key)
    local o = H.zopt("textSize")
    local i = nil
    for k, v in ipairs(ZeD.Settings.sizeKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function H.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local o = H.zopt("textSize")
    if o and S.found.sizeIdx then pcall(function() o:setValue(S.found.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, S.found.size)
end
function H.scaleIdx(v)
    for i, k in ipairs((ZeD.Settings and ZeD.Settings.scaleKeys) or {}) do if type(k) == "number" and math.abs(k - v) < 0.001 then return i end end
    return nil
end
function H.scaleSet(i)
    local o = ZeD.Settings and ZeD.Settings.uiScaleOption
    if not (o and i) then return false end
    pcall(function() o:setValue(i) end)
    pcall(function() if o.onChange then o.onChange(o, i) end end)
    pcall(function() if o.onChangeApply then o.onChangeApply(o, i) end end)
    S.scaleAt = getTimestampMs()
    S.back.scale = true
    return true
end
function H.scaleSettled()
    local Sc = ZeD.Scale
    if not Sc then return true end
    if getTimestampMs() - (S.scaleAt or 0) < 600 then return false end
    if Sc._reopenAt ~= nil then return false end
    local ok = true
    pcall(function()
        local a = Sc._appliedRoot
        ok = a ~= nil and math.abs(a - Sc.compute()) < 0.001 and math.abs(Sc.root() - a) < 0.001
    end)
    return ok
end
function H.root() local r = 1; pcall(function() r = ZeD.Scale.root() end); return r end
function H.lightSet(on)
    local o = ZeD.Settings and ZeD.Settings.mapLightOption
    if not o then return end
    pcall(function() o:setValue(on and 2 or 1) end)
    S.back.light = true
end
function H.lightOn() local v = false; pcall(function() v = ZeD.Settings.mapLight() and true or false end); return v end
function H.lite(on)
    local o = ZeD.Settings and ZeD.Settings.lookStyleOption
    if not o then return false end
    pcall(function() o:setValue(on and 2 or 1) end)
    S.back.lite = true
    return true
end
function H.safeSet(on)
    local o = ZeD.Settings and ZeD.Settings.safeModeOption
    if not o then return false end
    pcall(function() o:setValue(on and 2 or 1) end)
    pcall(function() ZeD.Safe.reread() end)
    S.back.safe = true
    return true
end
function H.safeOn() local v = false; pcall(function() v = ZeD.Safe.on() and true or false end); return v end
-- the sandbox's map rules (the game reads SandboxVars.Map each time: ISWorldMap.IsAllowed / NeedsLight)
function H.sbx(allow, light)
    pcall(function()
        if allow ~= nil then SandboxVars.Map.AllowWorldMap = allow end
        if light ~= nil then SandboxVars.Map.MapNeedsLight = light end
    end)
end
function H.sbxBack()
    local f = S.found.sbx
    if not f then return end
    pcall(function() SandboxVars.Map.AllowWorldMap = f.allow; SandboxVars.Map.MapNeedsLight = f.light end)
end
function H.day() pcall(function() getGameTime():setTimeOfDay(12.0) end) end
function H.dark() local d = false; pcall(function() d = S.p:tooDarkToRead() and true or false end); return d end
function H.mapKey() local k = nil; pcall(function() k = getCore():getKey(KeybindId.MAP) end); if k == nil then pcall(function() k = Keyboard.KEY_M end) end; return k end
-- the Map key tapped as the game's key handlers hear it (ISWorldMap.onKeyStartPressed, then onKeyReleased)
function H.keyM()
    local k = H.mapKey()
    H.zcall(function() ISWorldMap.onKeyStartPressed(k) end)
    H.zcall(function() ISWorldMap.onKeyReleased(k) end)
end
function H.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function H.shot(name, what, gate)
    Q.step(1, function() if not S.dead and (gate == nil or gate()) then H.park(true) end end)
    Q.step(6, function()
        if S.dead or not (gate == nil or gate()) then H.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; H.note("picture Zomboid/Screenshots/" .. file .. " : " .. what)
        else H.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(1200)
end
function H.drawerW() local w = RT.ww(); return math.floor((w and w._drawerEffW) or 0) end
function H.isHalf() local w = RT.ww(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
-- queue: the drawer held in to the half card (the World window's width cap made too narrow: cr_tab's way); T.half
function H.halfOn(T)
    H.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.ww()
        if w and not H.isHalf() then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            w._maxWinW = ZeD.T.px(700)
        end
        T.hs = { last = -1, n = 0 }
    end)
    H.wait(5000, function()
        if T.off then return true end
        local e = H.drawerW()
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and H.isHalf()
    end, function(ok) if not T.off then T.half = ok end end)
end
function H.halfBack()
    if not S.back.maxW then return end
    local w = RT.ww()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end
-- the game's menus and windows a leg may have left up
function H.ctx() local c = nil; pcall(function() c = getPlayerContextMenu(S.pn) end); return c end
function H.ctxShut() local c = H.ctx(); if c then pcall(function() c:hideAndChildren() end); pcall(function() c:setVisible(false) end) end end
function H.ctxOpts()
    local c = H.ctx()
    local o = {}
    if not c then return o end
    pcall(function() for i = 1, (c.numOptions or 1) - 1 do local op = c.options[i]; if op then o[#o + 1] = op end end end)
    return o
end
function H.ctxOpt(name) for _, op in ipairs(H.ctxOpts()) do if op.name == name then return op end end; return nil end
function H.ctxNames() local o = {}; for _, op in ipairs(H.ctxOpts()) do o[#o + 1] = tostring(op.name) .. (op.notAvailable and "(grey)" or "") end; return H.list(o) end
-- an option taken as the menu takes it (its onSelect with its target and params), the menu shut after
function H.ctxPick(op)
    if not op then return false end
    local ok = H.zcall(function() op.onSelect(op.target, op.param1, op.param2, op.param3, op.param4) end)
    H.ctxShut()
    return ok
end
function H.optTip(op) local d = nil; pcall(function() d = op.toolTip and op.toolTip.description end); return d end
function H.reader() local r = nil; pcall(function() r = ZeD.Reader.get(S.pn) end); return r end
function H.readerUp() local r = H.reader(); local v = false; if r then pcall(function() v = r:getIsVisible() and true or false end) end; return v end
function H.readerShut() local r = H.reader(); if r and H.readerUp() then pcall(function() r:close() end) end end
function H.radialShut() pcall(function() local m = getPlayerRadialMenu(S.pn); if m and m:isReallyVisible() then m:removeFromUIManager() end end) end
function H.gameMapShut()
    pcall(function() if ISWorldMap_instance and ISWorldMap_instance:isVisible() then (ISWorldMap._zedOrigHide or ISWorldMap.HideWorldMap)(S.pn) end end)
    for _, w in ipairs(S.gameWins or {}) do pcall(function() w:setVisible(false); w:removeFromUIManager() end) end
    S.gameWins = {}
end

-- ===================================================================== a case's start and end
-- the tab as every case stages it: Survey, nothing picked up, the fold shut, the key shut, ink 1, the note box's own
-- words, the five pens and an eraser in his main inventory, literate, daylight, the sandbox's map rules on
function H.tabBaseline()
    local w = RT.ww()
    if not w then return end
    if w._mapPopout then pcall(S.MT.closePopout, w, true) end
    w._mapActiveTool, w._mapEdit, w._mapStyleMenuOpen, w._mapSideAsk = nil, nil, nil, nil
    w._mapToolsExpanded = false
    w._mapKeyOpen = false
    w._mapKeyPage = "colors"
    w._mapActiveColor = 1
    local te = w._mapTextEntry
    if te then pcall(function() te:setText(S.noteDefault or "") end); pcall(function() te:unfocus() end) end
    local md = H.md()
    md.ZeD_MapStyle = "survey"
    md.ZeD_MapPaper = nil
    local mp = w._worldMapPanel
    if mp and mp.style ~= "survey" then pcall(function() mp:requestStyle("survey") end) end
end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.park(false)
    H.fakeOff()
    H.ctxShut()
    H.readerShut()
    H.radialShut()
    H.gameMapShut()
    S.drawRec = nil
    S.hidWatch = nil
    H.tabBaseline()
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    H.removeNew()
    H.sbx(true, true)
    H.traitSet("ILLITERATE", false)
    if S.night then S.night = nil; H.day() end
    H.halfBack()
    H.hands()
    H.fullKit()
    H.qstop()
end
-- (inside a step) the case begins clean
function H.caseStart(T)
    S.caseMade = {}
    S.halo = {}
    H.legClean()
    T.t0 = getTimestampMs()
    return true
end
function H.caseEnd(label)
    H.step(2, function()
        H.legClean()
        H.sizeBack()
        H.home()
    end)
    H.step(8, function()
        local left = H.newSyms()
        if #left > 0 then
            local o = {}
            for _, s in ipairs(left) do o[#o + 1] = H.sig(s) end
            Q.check(false, label .. ": every mark the case made is off the world map's store", H.list(o, 6))
            H.removeNew()
        end
        local e1 = H.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
    end)
end
function H.skipCase(label, why) H.step(1, function() Q.skip(label, why) end) end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "mz_tab") end
        H.speed(1)
        H.qstop()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.inv0, f.types = {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat() end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        pcall(function() f.sbx = { allow = SandboxVars.Map.AllowWorldMap, light = SandboxVars.Map.MapNeedsLight, all = SandboxVars.Map.MapAllKnown, mini = SandboxVars.Map.AllowMiniMap } end)
        local md = H.md()
        f.md = { style = md.ZeD_MapStyle, paper = md.ZeD_MapPaper, ann = md.ZeD_MapAnnotations, moved = md.ZeD_MapNotesMoved }
        if type(md.ZeD_MapPinnedIcons) == "table" then f.pins = {}; for i, v in ipairs(md.ZeD_MapPinnedIcons) do f.pins[i] = v end end
        if type(md.ZeD_FlyerSeen) == "table" then f.seen = {}; for k, v in pairs(md.ZeD_FlyerSeen) do f.seen[k] = v end end
        f.illit = H.hasTrait("ILLITERATE")
        f.base, f.size, f.status = ZeD.currentBase, ZeD.currentSize, ZeD.currentStatus
        f.baseIdx = H.optVal(H.zopt("baseTheme"))
        f.sizeIdx = H.optVal(H.zopt("textSize"))
        f.statusIdx = H.optVal(ZeD.Settings and ZeD.Settings.statusColorsOption)
        f.scaleIdx = H.optVal(ZeD.Settings and ZeD.Settings.uiScaleOption)
        f.lightIdx = H.optVal(ZeD.Settings and ZeD.Settings.mapLightOption)
        f.liteIdx = H.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)
        f.safeIdx = H.optVal(ZeD.Settings and ZeD.Settings.safeModeOption)
        f.safe = H.safeOn()
        S.lockWas = H.lockFound()
        f.pair = RT.isOpen()
        f.wwOpen = H.wwOpen()
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = ww and ww._maxWinW
        f.mini = nil
        pcall(function() local mm = getPlayerMiniMap(S.pn); if mm then f.mini = mm:isReallyVisible() and true or false end end)
        -- the World window's map as found (the window's map, its view, its fold, key, list, tool and ink)
        if ww then
            local mp = ww._worldMapPanel
            f.win = { expanded = ww._mapToolsExpanded, key = ww._mapKeyOpen, page = ww._mapKeyPage, side = ww._mapSideOpen,
                      tool = ww._mapActiveTool, color = ww._mapActiveColor, pop = ww._mapPopout ~= nil }
            if ww._mapTextEntry then pcall(function() f.win.note = ww._mapTextEntry:getText() end) end
            if mp then
                pcall(function() f.view = { mp = mp, x = mp.mapAPI:getCenterWorldX(), y = mp.mapAPI:getCenterWorldY(), z = mp.mapAPI:getZoomF(), style = mp.style } end)
            end
        end
        -- the world map's store: every mark of his as found (by the symbol itself and by what it is)
        local api = H.store()
        f.symSet, f.sigs = {}, {}
        for _, s in ipairs(H.userSyms(api)) do f.symSet[s] = true; f.sigs[#f.sigs + 1] = H.sig(s) end
        f.marks = #f.sigs
        S.noteDefault = H.tr("UI_ZeD_Map_NoteDefault")
        f.recorded = true
        S.back.on = true
        S.guard = true
        S.holdOn = true
        H.instant(true)
        H.hooksOn()
        local aside, kept = H.stashPens()
        if H.debug() then H.note("setup: a debug game: the game's map reads in the dark here (ISWorldMap.ToggleWorldMap's debug pass), so the dark legs use a night only where the game's rule allows it") end
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", debug " .. tostring(H.debug()) .. ", theme " .. tostring(f.base) .. ", text " .. tostring(f.size) .. ", status colors " .. tostring(f.status)
            .. ", UI scale " .. H.n2(H.root()) .. ", map style " .. tostring(f.md.style) .. ", his marks on the world map " .. f.marks
            .. ", sandbox AllowWorldMap " .. tostring(f.sbx and f.sbx.allow) .. ", MapNeedsLight " .. tostring(f.sbx and f.sbx.light)
            .. ", MapAllKnown " .. tostring(f.sbx and f.sbx.all) .. ", World tab " .. tostring(f.wtab) .. ", input lock " .. tostring(S.lockWas)
            .. ", his pens and erasers set aside " .. aside .. (kept > 0 and (" (" .. kept .. " worn or held stay)") or ""))
        S.penKept = kept
        local miss = {}
        for _, ft in ipairs(S.PENS) do if not H.known(ft) then miss[#miss + 1] = ft end end
        if not H.known(S.ERASER) then miss[#miss + 1] = S.ERASER end
        Q.check(#miss == 0, "setup: the five pens and the eraser are known to this game", "unknown: " .. H.list(miss))
        if f.illit then H.traitSet("ILLITERATE", false); H.note("setup: he is illiterate: the trait is off for the run (put back)") end
        if f.base ~= "dark" then H.theme("dark") end
        if f.status ~= "standard" then H.status("standard") end
        if H.lightOn() then H.lightSet(false) end
        H.sbx(true, true)
        H.day()
        H.fullKit()
        H.tabBaseline()
    end)
    local T = { L = "setup" }
    H.tabQ(T)
    H.step(2, function()
        S.found.drawer = H.mp()
        local w = RT.ww()
        if w and w._mapTextEntry and not S.found.noteSeen then
            S.found.noteSeen = true
            local t = nil
            pcall(function() t = w._mapTextEntry:getText() end)
            if S.found.win and S.found.win.note == nil then S.found.win.note = t end
        end
        Q.say("NOTE setup: " .. H.tabState() .. "; the extensions loaded: " .. H.extIds())
    end)
end
function H.extIds() local o = {}; for _, d in ipairs(S.E.list or {}) do o[#o + 1] = tostring(d.id) end; return H.list(o) end

-- ===================================================================== the D-pad World wheel (ZeD_DpadWheels: B.world)
function H.wheelWorld() local list = nil; pcall(function() list = ZeD.DpadWheels.B.world(S.p, S.pn) end); return list or {} end
function H.wheelSlice(key) local name = H.tr(key); for _, e in ipairs(H.wheelWorld()) do if e.name == name then return e end end; return nil end
function H.wheelTab(id)
    local tabs = H.wheelSlice("UI_ZeD_Wheel_Tabs")
    local list = nil
    if tabs and type(tabs.sub) == "function" then pcall(function() list = tabs.sub(S.p, S.pn) end) end
    for _, e in ipairs(list or {}) do if e.key == id then return e end end
    return nil
end
-- a UI root by its lua table, shown or not
function H.findRoot(pred)
    local found = nil
    for _, r in ipairs(RT.roots()) do
        if not found and r.t then
            local ok, yes = pcall(pred, r.t)
            if ok and yes then found = r.t end
        end
    end
    return found
end

-- ===================================================================== MP1 the tab
function C.mp1()
    local T = { L = "MP1 the tab" }
    H.step(2, function()
        H.caseStart(T)
        RT.pairOpen()
        H.freshWindow()
        T.px, T.py = S.p:getX(), S.p:getY()
    end)
    H.wait(4000, function() return #RT.tabs(RT.worldStrip()) > 0 end, function() end)
    H.step(2, function() T.clicked = RT.worldTab("maps") end)
    H.wait(5000, function() return H.mapUp() end, function(ok)
        local cx, cy = H.cxy()
        local z = H.zoom()
        local md = H.md()
        local want = md.ZeD_MapStyle or ((md.ZeD_MapPaper == true) and "paper" or "survey")
        local w = RT.ww()
        Q.check(ok and T.clicked and w ~= nil and w._activeTab == "maps", T.L .. ": a click on the Maps tab shows its map (the game allows a map here: ISWorldMap.IsAllowed "
            .. tostring(ISWorldMap.IsAllowed()) .. ")", H.tabState())
        Q.check(cx ~= nil and math.abs(cx - T.px) <= 1 and math.abs(cy - T.py) <= 1, T.L .. ": a new map opens on him (getCenterWorldX/Y against his square)",
            "center " .. H.n1(cx) .. "," .. H.n1(cy) .. "; he stands at " .. H.n1(T.px) .. "," .. H.n1(T.py))
        Q.check(z ~= nil and math.abs(z - 18) < 0.01, T.L .. ": a new Survey map opens at zoom 18", "zoom " .. H.n2(z))
        Q.check(H.style() == want, T.L .. ": the map's style is his own (modData.ZeD_MapStyle)", "the map " .. tostring(H.style()) .. ", his " .. tostring(want))
    end)
    -- the pad's way to a tab: the D-pad World wheel's Tabs > Maps, run as its slice runs it
    H.step(2, function()
        RT.worldTab("loot")
        T.entry = H.wheelTab("maps")
    end)
    H.step(3, function()
        if not T.entry then Q.skip(T.L .. " (pad)", "the D-pad World wheel's Tabs list has no Maps entry here"); return end
        H.zcall(function() T.entry.run(S.p, S.pn) end)
    end)
    H.wait(3000, function() return not T.entry or H.mapUp() end, function(ok)
        if not T.entry then return end
        Q.check(ok and T.entry.off == nil, T.L .. " (pad): the D-pad World wheel's Tabs > Maps opens the tab and its map", "the entry greyed " .. tostring(T.entry.off) .. "; " .. H.tabState())
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP15 fog of war, MP16 the player dots
function C.mp15()
    local T = { L = "MP15 fog of war" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    for _, st in ipairs({ "survey", "color", "paper" }) do
        H.step(2, function()
            T.st = nil
            if T.off then return end
            if st == "paper" and not S.MT.hasPaper() then Q.skip(T.L .. " (paper)", "this map has no illustration (getMapInfo spawnSelectImagePyramid)"); return end
            T.st = st
            if H.style() ~= st then S.MT.setStyle(RT.ww(), st) end
        end)
        H.wait(3000, function() return T.off or not T.st or (H.style() == st and H.mapUp()) end, function(ok)
            if T.off or not T.st then return end
            local hide = nil
            pcall(function() hide = H.api():getBoolean("HideUnvisited") end)
            Q.check(ok and hide == true, T.L .. " (" .. st .. "): the map hides the ground he has not seen (the engine's HideUnvisited, as the game's map sets it)", "HideUnvisited " .. tostring(hide) .. "; " .. H.tabState())
        end)
    end
    H.step(2, function()
        if T.off then return end
        Q.skip(T.L .. ": the sandbox's MapAllKnown on shows the whole county", "needs a new game with MapAllKnown on (a running game has made its known ground already)")
        local players, remote = nil, nil
        pcall(function() players = H.api():getBoolean("Players") end)
        pcall(function() remote = H.api():getBoolean("RemotePlayers") end)
        Q.check(players == true, "MP16 the player dots: the map draws the game's own player dots (the engine's Players)", "Players " .. tostring(players) .. ", RemotePlayers " .. tostring(remote))
        Q.skip("MP16 the player dots: another player's dot (RemotePlayers)", "multiplayer: a server and a second player")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP2 the Map key
function C.mp2()
    local T = { L = "MP2 the Map key" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        RT.worldTab("loot")
        H.qstop()
        T.key = H.mapKey()
        H.keyM()
        T.q = H.qkinds()
        T.read = H.qfirst("ISReadWorldMap") ~= nil
    end)
    H.wait(5000, function() return T.off or H.popUp() end, function(ok)
        if T.off then return end
        Q.check(T.read, T.L .. ": a tap of the Map key queues the game's own read (ISReadWorldMap, its 50 ticks)", "key " .. tostring(T.key) .. "; the queue right after: " .. tostring(T.q))
        Q.check(ok and H.onMaps(), T.L .. ": the read's end unfolds ZeD's map, the World window on Maps", H.tabState())
        Q.check(not H.gameMapUp(), T.L .. ": the game's full-screen map stays shut", "ISWorldMap_instance up " .. tostring(H.gameMapUp()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP3 putting the map away
function C.mp3leg(T, shut, how)
    local L = T.L .. " (" .. how .. ", the World window " .. (shut and "shut" or "open") .. " before)"
    local st = {}
    H.step(2, function()
        H.legClean()
        if shut then RT.pairShut(); pcall(ZeD_WorldWindow.close, S.pn) else RT.pairOpen() end
    end)
    H.step(6, function()
        st.before = H.wwOpen()
        H.zcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
    end)
    H.wait(6000, function() return H.popUp() end, function(ok)
        if not ok then Q.check(false, L .. ": the Map key unfolds the map first", H.tabState()); return end
        st.go = true
        local w = RT.ww()
        st.owns = w and w._mapOwnsWindow
        if how == "M" then H.zcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
        elseif how == "Escape" then st.took = ZeD.EscapeTakers and ZeD.EscapeTakers.mapPopout and ZeD.EscapeTakers.mapPopout()
        elseif how == "close box" then local pop = H.pop(); if pop then H.zcall(function() pop:close() end) end
        elseif how == "B" then H.padOn(); st.bOk = H.focusEl("map:canvas:cursor") end
    end)
    if how == "B" then H.tapB(function() return st.go and st.bOk end) end
    H.wait(2500, function() return not st.go or H.pop() == nil end, function(ok)
        H.padOff()
        if not st.go then return end
        local open = H.wwOpen()
        Q.check(ok and open == st.before, L .. ": the map folds and the World window is as it was before the map (" .. (st.before and "open" or "shut") .. ")",
            "unfolded " .. tostring(H.pop() ~= nil) .. ", World open " .. tostring(open) .. ", the map's own-window mark " .. tostring(st.owns)
            .. (how == "Escape" and (", Escape taken " .. tostring(st.took)) or "") .. (how == "B" and (", the pad on the map " .. tostring(st.bOk)) or ""))
    end)
    H.step(2, function() RT.pairOpen() end)
end
function C.mp3()
    local T = { L = "MP3 putting the map away" }
    H.step(2, function() H.caseStart(T) end)
    for _, shut in ipairs({ true, false }) do
        for _, how in ipairs({ "M", "Escape", "B", "close box" }) do C.mp3leg(T, shut, how) end
    end
    H.caseEnd(T.L)
end

-- ===================================================================== MP5 the Map key held
function C.mp5()
    local T = { L = "MP5 the Map key held" }
    H.step(2, function()
        H.caseStart(T)
        RT.worldTab("loot")
        H.radialShut()
        T.k = H.mapKey()
        H.zcall(function() ISWorldMap.onKeyStartPressed(T.k) end)
    end)
    H.pause(650)
    H.step(1, function() H.zcall(function() ISWorldMap.onKeyKeepPressed(T.k) end) end)
    H.step(3, function()
        local m = nil
        pcall(function() m = getPlayerRadialMenu(S.pn) end)
        local vis = H.vis(m)
        local world, mini, names = false, false, {}
        for _, sl in ipairs((m and m.slices) or {}) do
            local cmd = type(sl.command) == "table" and sl.command[1] or nil
            names[#names + 1] = tostring(sl.text)
            if cmd == ISWorldMap.ToggleWorldMap then world = true end
            if ISMiniMap and cmd == ISMiniMap.ToggleMiniMap then mini = true end
        end
        local gameMini = false
        pcall(function() gameMini = getPlayerMiniMap(S.pn) ~= nil end)
        Q.check(vis and world, T.L .. ": held 500 ms, the game's radial offers World map", "radial up " .. tostring(vis) .. ", slices " .. H.list(names))
        if gameMini then Q.check(not mini, T.L .. ": no mini-map slice (the game adds one: a mini-map exists for him)", "slices " .. H.list(names))
        else H.note(T.L .. ": the game would add no mini-map slice here (no mini-map for him: the sandbox's AllowMiniMap " .. tostring(S.found.sbx and S.found.sbx.mini) .. "); ZeD's wheel leaves it out where it does (Overrides/Wheels.lua)") end
        H.zcall(function() ISWorldMap.onKeyReleased(T.k) end)
    end)
    H.step(4, function()
        local m = nil
        pcall(function() m = getPlayerRadialMenu(S.pn) end)
        -- the game's own rule (ISWorldMap.onKeyReleased): the radial stays up only with its "radial menu key toggles" option
        local toggles = false
        pcall(function() toggles = getCore():getOptionRadialMenuKeyToggle() and true or false end)
        Q.check(H.vis(m) == toggles and H.pop() == nil and H.qcount("ISReadWorldMap") == 0, T.L .. ": letting go leaves the radial as the game's key handler does (shut, or up with the toggle option) and opens nothing",
            "radial up " .. tostring(H.vis(m)) .. ", the game's radial key toggle option " .. tostring(toggles) .. "; unfolded " .. tostring(H.pop() ~= nil) .. ", queued " .. H.qkinds())
        H.radialShut()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP6 the Map key paused (B11)
function C.mp6()
    local T = { L = "MP6 the Map key paused" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        H.speed(0)
    end)
    H.step(4, function()
        if T.off then return end
        T.speed = getGameSpeed()
        T.ck, T.ck0 = nil, nil
        pcall(function() T.ck = ISWorldMap.checkKey(H.mapKey()) end)
        pcall(function() T.ck0 = ISWorldMap._zedOrigCheckKey(H.mapKey()) end)
        H.keyM()
    end)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        Q.check(T.speed == 0 and H.pop() == nil and H.wwOpen(), T.L .. " (B11): the Map key folds ZeD's unfolded world map while the game is paused",
            "game speed " .. tostring(T.speed) .. "; after the key the map unfolded " .. tostring(H.pop() ~= nil) .. ", World open " .. tostring(H.wwOpen())
            .. "; the key check answered " .. tostring(T.ck) .. " (the game's own " .. tostring(T.ck0) .. ": it passes a paused key only for its own map)")
        -- unfolded again, still paused, for Escape
        H.zcall(function() S.MT.openPopout(RT.ww()) end)
    end)
    H.wait(1500, function() return T.off or H.popUp() end, function(ok)
        if T.off then return end
        T.up2 = ok
        T.took = ZeD.EscapeTakers and ZeD.EscapeTakers.mapPopout and ZeD.EscapeTakers.mapPopout()
    end)
    H.wait(1500, function() return T.off or H.pop() == nil end, function(ok)
        if T.off then return end
        Q.check(T.up2 and ok, T.L .. ": Escape folds it while paused", "unfolded again " .. tostring(T.up2) .. ", Escape taken " .. tostring(T.took) .. "; " .. H.tabState())
    end)
    -- the game's other rules still decide: a paper map up (the key is the game's answer: refused while paused), and
    -- no world map in this game (the sandbox)
    H.step(2, function()
        if T.off then return end
        T.paper = H.townMap()
        if T.paper then H.zcall(function() S.MT.openPopout(RT.ww(), T.paper) end) end
    end)
    H.wait(2000, function() return T.off or not T.paper or H.paperUp(T.paper) end, function(ok)
        if T.off or not T.paper then return end
        T.ckP = nil
        pcall(function() T.ckP = ISWorldMap.checkKey(H.mapKey()) end)
        H.keyM()
    end)
    H.pause(500)
    H.step(1, function()
        if T.off or not T.paper then return end
        Q.check(T.ckP == false and H.paperUp(T.paper), T.L .. " (B11): with a paper map up, the paused key stays the game's answer (refused) and the paper stays",
            "the key check " .. tostring(T.ckP) .. ", the paper up " .. tostring(H.paperUp(T.paper)))
        pcall(S.MT.closePopout, RT.ww(), true)
        H.zcall(function() S.MT.openPopout(RT.ww()) end)
    end)
    H.wait(1500, function() return T.off or H.popUp() end, function(ok)
        if T.off then return end
        H.sbx(false, nil)
        T.ckA = nil
        pcall(function() T.ckA = ISWorldMap.checkKey(H.mapKey()) end)
        H.sbx(true, nil)
        Q.check(ok and T.ckA == false, T.L .. " (B11): with the world map off in the sandbox, the paused key is refused (the game's IsAllowed still applies)", "unfolded " .. tostring(ok) .. ", the key check " .. tostring(T.ckA))
        H.speed(1)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP7 the D-pad World wheel's Map slice
function C.mp7()
    local T = { L = "MP7 the D-pad World wheel" }
    H.step(2, function()
        H.caseStart(T)
        RT.worldTab("loot")
        T.slice = H.wheelSlice("UI_ZeD_Wheel_Map")
        if not T.slice then T.off = true; Q.check(false, T.L .. ": the World wheel has its Map slice", "slices: " .. H.list((function() local o = {}; for _, e in ipairs(H.wheelWorld()) do o[#o + 1] = tostring(e.name) end; return o end)())); return end
        Q.check(T.slice.off == nil, T.L .. ": the Map slice is lit where the game allows a map", "greyed " .. tostring(T.slice.off) .. ", ISWorldMap.IsAllowed " .. tostring(ISWorldMap.IsAllowed()))
        H.qstop()
        H.zcall(function() T.slice.run(S.p, S.pn) end)
        T.read = H.qfirst("ISReadWorldMap") ~= nil
        T.q = H.qkinds()
    end)
    H.wait(5000, function() return T.off or H.popUp() end, function(ok)
        if T.off then return end
        Q.check(T.read and ok, T.L .. ": the Map slice runs the game's read, then ZeD's map unfolds", "the queue right after " .. tostring(T.q) .. "; " .. H.tabState())
    end)
    H.step(2, function()
        if T.off then return end
        H.legClean()
        H.sbx(false, nil)
        local sl = H.wheelSlice("UI_ZeD_Wheel_Map")
        local want = H.tr("UI_ZeD_Wheel_NoWorldMap")
        Q.check(sl ~= nil and sl.off == want, T.L .. ": with the sandbox's AllowWorldMap off the Map slice reads \"" .. want .. "\"",
            "greyed " .. tostring(sl and sl.off) .. "; the game's IsAllowed " .. tostring(ISWorldMap.IsAllowed()))
        H.sbx(true, nil)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP8 the HUD's map button
function C.mp8()
    local T = { L = "MP8 the HUD's map button" }
    H.step(2, function()
        H.caseStart(T)
        RT.worldTab("loot")
        T.eq = H.findRoot(function(t) return t.Type == "ISEquippedItem" and t.chr == S.p end)
        if not T.eq then T.off = true; Q.skip(T.L, "the game's equipped-item HUD (ISEquippedItem) is not made here"); return end
        H.qstop()
        H.zcall(function() T.eq:onOptionMouseDown({ internal = "MAP" }, 0, 0) end)
        T.read = H.qfirst("ISReadWorldMap") ~= nil
        T.q = H.qkinds()
    end)
    H.wait(5000, function() return T.off or H.popUp() end, function(ok)
        if T.off then return end
        Q.check(T.read and ok and not H.gameMapUp(), T.L .. ": the HUD's map button (its MAP press, ISEquippedItem:onOptionMouseDown) opens the same as the Map key",
            "the queue right after " .. tostring(T.q) .. "; " .. H.tabState())
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP12 no world map (the sandbox), MP14 the Tutorial, MP11 split screen
function C.mp12()
    local T = { L = "MP12 no world map" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        H.sbx(false, nil)
    end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        local word = H.tr("UI_ZeD_Map_Unavailable")
        Q.check(H.blocked() and H.drew(word) ~= nil and not H.vis(H.mp()), T.L .. ": the tab reads \"" .. word .. "\" in place of the map (the game's IsAllowed " .. tostring(ISWorldMap.IsAllowed()) .. ")",
            "blocked " .. tostring(H.blocked()) .. ", drawn " .. H.textsLike(word) .. ", the map seen " .. tostring(H.vis(H.mp())))
        H.padOn()
        Q.check(#H.stops() == 0, T.L .. " (pad): the drawer offers no stops", H.list(H.stopIds(), 12))
        H.padOff()
        H.qstop()
        H.keyM()
        T.q = H.qkinds()
    end)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        Q.check(H.pop() == nil and H.qcount("ISReadWorldMap") == 0, T.L .. ": the Map key does nothing", "the queue " .. tostring(T.q) .. "; " .. H.tabState())
        H.sbx(true, nil)
    end)
    -- unfolded, then the rule turns: the window keeps one stop over the refusal, and A folds it
    H.unfoldQ(T)
    H.step(2, function() if not T.off then H.sbx(false, nil) end end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        H.padOn()
        T.go = H.focusEl("map:blocked")
        Q.check(T.go and #H.stops() == 1, T.L .. " (pad): unfolded, the refusal is the window's one stop", H.list(H.stopIds(), 8))
    end)
    H.tapA(function() return T.go and not T.off end)
    H.wait(1500, function() return T.off or not T.go or H.pop() == nil end, function(ok)
        H.padOff()
        H.sbx(true, nil)
        if T.off or not T.go then return end
        Q.check(ok, T.L .. " (pad): A on the refusal folds the map", H.tabState())
    end)
    H.caseEnd(T.L)
    H.skipCase("MP14 the Tutorial", "the Tutorial is its own game mode (getCore():isTutorial()); the tab reads ISWorldMap.IsAllowed, which refuses there")
    H.skipCase("MP11 split screen", "a second local player: player 2's map (with and without ZeD.splitWindows) cannot be staged in this run")
end

-- ===================================================================== the engine's layers (the truth for the colors)
function H.layerRGB(name, i)
    local r, g, b = nil, nil, nil
    pcall(function()
        local l = H.api():getStyleAPI():getLayerByName(name)
        r, g, b = l:getFillRed(i or 0), l:getFillGreen(i or 0), l:getFillBlue(i or 0)
    end)
    if r and r <= 1.0 and g <= 1.0 and b <= 1.0 then r, g, b = r * 255, g * 255, b * 255 end
    return r, g, b
end
function H.hexIs(hex, r, g, b)
    if not (hex and r) then return false end
    local hr, hg, hb = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
    return math.abs(hr - r) <= 2 and math.abs(hg - g) <= 2 and math.abs(hb - b) <= 2
end
function H.rgbTxt(r, g, b) return H.n1(r) .. "," .. H.n1(g) .. "," .. H.n1(b) end

-- ===================================================================== MP17 the three styles
-- queue: a style picked (by: "mouse" its radio, "pad" A on its stop), then the map seen in it; the frames it was off
-- the screen counted, the center and zoom before and after
function C.styleQ(T, st, by)
    local L = T.L .. " (" .. st .. ", " .. by .. ")"
    local s = { hid = 0 }
    H.step(2, function()
        s.go = nil
        if T.off then return end
        if st == "paper" and not S.MT.hasPaper() then Q.skip(L, "this map has no illustration"); return end
        s.cx, s.cy = H.cxy()
        s.z = H.zoom()
        s.go = true
        -- (the frames off the screen are counted every frame from here, the pad's tap frames included: H.frameTick)
        s.watch = { n = 0 }
        S.hidWatch = s.watch
        if by == "mouse" then
            if not H.click("map:style:" .. st, L) then s.go = nil; Q.check(false, L .. ": the band's " .. st .. " radio is drawn", H.list(H.zoneIds(), 30)) end
        else
            H.padOn()
            s.f = H.focusEl("map:style:" .. st)
        end
    end)
    if by == "pad" then H.tapA(function() return s.go and s.f end) end
    H.wait(4000, function()
        if not s.go then return true end
        return H.style() == st and H.mapUp() and s.watch.n > 0
    end, function(ok)
        H.padOff()
        S.hidWatch = nil
        if not s.go then return end
        s.hid = s.watch.n
        local a = H.api()
        local pyr, imgs, data, water = nil, nil, nil, nil
        pcall(function() pyr = a:getBoolean("ImagePyramid") end)
        pcall(function() imgs = a:getImagesCount() end)
        pcall(function() data = a:getDataCount() end)
        pcall(function() water = a:getStyleAPI():getLayerByName("water") end)
        local cx, cy = H.cxy()
        local z = H.zoom()
        Q.check(ok and H.md().ZeD_MapStyle == st, L .. ": the map takes the style and his modData keeps it", "map " .. tostring(H.style()) .. ", modData " .. tostring(H.md().ZeD_MapStyle))
        Q.check(s.hid >= 3, L .. ": the map is off the screen three frames before the restyle (the render thread's guard)", s.hid .. " frames off")
        Q.check(cx ~= nil and s.cx ~= nil and math.abs(cx - s.cx) <= 1 and math.abs(cy - s.cy) <= 1, L .. ": the center is kept", H.n1(s.cx) .. "," .. H.n1(s.cy) .. " -> " .. H.n1(cx) .. "," .. H.n1(cy))
        if st == "paper" then Q.check(z ~= nil and z <= 16.01, L .. ": Paper's zoom is at most 16", H.n2(s.z) .. " -> " .. H.n2(z)) end
        -- Survey: the map's data drawn in the game's style layers (its forest picture is a pyramid too, so ImagePyramid
        -- is on there as on the game's map); Color and Paper: a picture with no polygon layers (MapsTab initColor, initPaper)
        local good
        if st == "survey" then good = (data or 0) > 0 and water ~= nil
        else good = pyr == true and (imgs or 0) > 0 and water == nil end
        Q.check(good, L .. ": the engine draws the style's own ground (Survey the map's data in the game's style layers; Color and Paper a picture with no style layers)",
            "ImagePyramid " .. tostring(pyr) .. ", pictures " .. tostring(imgs) .. ", data " .. tostring(data) .. ", the water layer " .. tostring(water ~= nil))
    end)
end
function C.mp17()
    local T = { L = "MP17 the styles" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    C.styleQ(T, "color", "mouse")
    C.styleQ(T, "paper", "mouse")
    C.styleQ(T, "survey", "mouse")
    C.styleQ(T, "color", "pad")
    C.styleQ(T, "survey", "pad")
    -- an older character's ZeD_MapPaper alone: a new map opens on Paper
    H.step(2, function()
        if T.off then return end
        if not S.MT.hasPaper() then T.noPaper = true; Q.skip(T.L .. ": the old ZeD_MapPaper carries over", "this map has no illustration"); return end
        local md = H.md()
        md.ZeD_MapStyle = nil
        md.ZeD_MapPaper = true
        H.freshWindow()
    end)
    H.wait(4000, function() return T.off or T.noPaper or #RT.tabs(RT.worldStrip()) > 0 end, function() end)
    H.wait(5000, function()
        if T.off or T.noPaper then return true end
        if not H.onMaps() then RT.worldTab("maps") end
        return H.mapUp()
    end, function(ok)
        if T.off or T.noPaper then return end
        local z = H.zoom()
        Q.check(ok and H.style() == "paper" and z ~= nil and math.abs(z - 15) < 0.01, T.L .. ": a character with only the old ZeD_MapPaper true opens on Paper, at zoom 15",
            "style " .. tostring(H.style()) .. ", zoom " .. H.n2(z))
        local md = H.md()
        md.ZeD_MapStyle = "survey"
        md.ZeD_MapPaper = nil
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP18 the style box (the radios give way)
function C.mp18()
    local T = { L = "MP18 the style box" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.halfOn(T)
    H.step(3, function()
        if T.off then return end
        if not H.zone("map:style:menu") then H.sizeSet("large") end
    end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.box = H.zone("map:style:menu") ~= nil
        if not T.box then
            T.off = true
            Q.skip(T.L, "the radios still fit at " .. H.sizeTag() .. " with the half card (" .. tostring(T.half) .. ") and Large text: " .. H.list(H.zoneIds(), 20))
            return
        end
        H.note(T.L .. ": the box stands in for the radios at " .. H.sizeTag() .. ", the drawer " .. H.drawerW() .. " px, text " .. tostring(ZeD.currentSize))
        H.click("map:style:menu", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(RT.ww()._mapStyleMenuOpen == true and H.zone("map:styleRow:color") ~= nil, T.L .. ": a click on the box opens its list", "open " .. tostring(RT.ww()._mapStyleMenuOpen) .. "; " .. H.list(H.zoneIds(), 20))
        H.click("map:styleRow:color", T.L)
    end)
    H.wait(3000, function() return T.off or (H.style() == "color" and H.mapUp()) end, function(ok)
        if T.off then return end
        Q.check(ok and not RT.ww()._mapStyleMenuOpen, T.L .. ": a click on Color in the list takes it and shuts the list", "style " .. tostring(H.style()) .. ", open " .. tostring(RT.ww()._mapStyleMenuOpen))
    end)
    -- the pad: A opens the list on the current row, A on another takes it and lands back on the box
    H.padPress(T, "map:style:menu")
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        Q.check(RT.ww()._mapStyleMenuOpen == true and H.focusedId() == "map:styleRow:color", T.L .. " (pad): A on the box opens the list, the focus on the current choice",
            "open " .. tostring(RT.ww()._mapStyleMenuOpen) .. ", focus " .. tostring(H.focusedId()) .. ", stops " .. H.list(H.stopIds(), 8))
        T.f = H.focusEl("map:styleRow:survey")
    end)
    H.tapA(function() return T.f and not T.off end)
    H.wait(3000, function() return T.off or (H.style() == "survey" and H.mapUp()) end, function(ok)
        if T.off then return end
        Q.check(ok and not RT.ww()._mapStyleMenuOpen, T.L .. " (pad): A on Survey takes it and shuts the list", "style " .. tostring(H.style()) .. ", focus " .. tostring(H.focusedId()))
    end)
    H.pause(300)
    H.step(1, function() if not T.off then Q.check(H.focusedId() == "map:style:menu", T.L .. " (pad): the focus goes back to the box", tostring(H.focusedId())) end end)
    -- B shuts it
    H.padPress(T, "map:style:menu")
    H.pause(300)
    H.tapB(function() return not T.off and RT.ww()._mapStyleMenuOpen == true end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        Q.check(not RT.ww()._mapStyleMenuOpen and H.style() == "survey", T.L .. " (pad): B shuts the list and keeps the style", "open " .. tostring(RT.ww()._mapStyleMenuOpen) .. ", style " .. tostring(H.style()) .. ", focus " .. tostring(H.focusedId()))
        H.padOff()
        H.click("map:style:menu", T.L)
    end)
    -- a press elsewhere, then a walk, shut it (ZeD.Popups)
    H.step(3, function()
        if T.off then return end
        T.open1 = RT.ww()._mapStyleMenuOpen == true
        pcall(function() ZeD.Popups.onPress(0, 2, 2) end)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.open1 and not RT.ww()._mapStyleMenuOpen, T.L .. ": a press elsewhere on the screen shuts the list (ZeD.Popups)", "open before " .. tostring(T.open1) .. ", after " .. tostring(RT.ww()._mapStyleMenuOpen))
        H.click("map:style:menu", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        T.open2 = RT.ww()._mapStyleMenuOpen == true
        local sq = nil
        pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + 1, math.floor(S.p:getY()), math.floor(S.p:getZ())) end)
        if sq and ISWalkToTimedAction then H.zcall(function() ISTimedActionQueue.add(ISWalkToTimedAction:new(S.p, sq)) end) end
    end)
    H.pause(800)
    H.step(1, function()
        if T.off then return end
        Q.check(T.open2 and not RT.ww()._mapStyleMenuOpen, T.L .. ": a walk shuts the list (an action queued: ZeD.Popups)", "open before " .. tostring(T.open2) .. ", after " .. tostring(RT.ww()._mapStyleMenuOpen) .. ", queue " .. H.qkinds())
        H.qstop()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP19 the light map switch
function C.lightShownQ(T, theme, st, want)
    if st == "paper" and not S.MT.hasPaper() then
        H.step(1, function() Q.skip(T.L .. ": the switch on Paper", "this map has no illustration") end)
        return
    end
    H.step(2, function()
        if T.off then return end
        if ZeD.currentBase ~= theme then H.theme(theme) end
        if H.style() ~= st then S.MT.setStyle(RT.ww(), st) end
    end)
    H.wait(3000, function() return T.off or (H.style() == st and H.mapUp() and ZeD.currentBase == theme) end, function(ok)
        if T.off then return end
        local shown = H.zone("map:style:light") ~= nil
        Q.check(ok and shown == want, T.L .. ": the switch shows on " .. st .. " under " .. theme .. ": " .. tostring(want), "drawn " .. tostring(shown) .. "; band: " .. H.list(H.zoneIds(), 20))
    end)
end
function C.mp19()
    local T = { L = "MP19 the light map switch" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    C.lightShownQ(T, "dark", "survey", true)
    C.lightShownQ(T, "dark", "color", false)
    C.lightShownQ(T, "dark", "paper", false)
    C.lightShownQ(T, "light", "survey", false)
    C.lightShownQ(T, "hicon", "survey", false)
    C.lightShownQ(T, "dark", "survey", true)
    H.step(2, function()
        if T.off then return end
        T.was = H.lightOn()
        S.back.light = true
        H.click("map:style:light", T.L)
    end)
    H.wait(3000, function() return T.off or (H.lightOn() ~= T.was and H.mp() and H.mp()._zedSurveyKey == "light") end, function(ok)
        if T.off then return end
        local r, g, b = H.layerRGB("water", 0)
        local pal = ZeD.MapsSurvey.PALETTES.light
        Q.check(ok and H.hexIs(pal.water, r, g, b), T.L .. ": a click turns the map to the Light palette (the engine's water layer against the Light palette's)",
            "switch " .. tostring(T.was) .. " -> " .. tostring(H.lightOn()) .. ", key " .. tostring(H.mp() and H.mp()._zedSurveyKey) .. ", water " .. H.rgbTxt(r, g, b) .. " (Light " .. pal.water .. ")")
    end)
    H.padPress(T, "map:style:light")
    H.wait(3000, function() return T.off or (H.lightOn() == T.was and H.mp() and H.mp()._zedSurveyKey == "dark") end, function(ok)
        H.padOff()
        if T.off then return end
        local r, g, b = H.layerRGB("water", 0)
        Q.check(ok and H.hexIs(ZeD.MapsSurvey.PALETTES.dark.water, r, g, b), T.L .. " (pad): A on the switch turns it back (the Dark palette's water)", "switch " .. tostring(H.lightOn()) .. ", water " .. H.rgbTxt(r, g, b))
    end)
    H.step(2, function() H.theme("dark") end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP20 the theme and the status colors restyle Survey once each
function C.restyleQ(T, label, fn, wantKey, check)
    H.step(2, function()
        if T.off then return end
        T.r0 = S.restyles
        fn()
    end)
    H.pause(900)
    H.step(1, function()
        if T.off then return end
        local mp = H.mp()
        local n = S.restyles - (T.r0 or 0)
        Q.check(n == 1 and mp ~= nil and mp._zedSurveyKey == wantKey, T.L .. " (" .. label .. "): one restyle, the map's palette key " .. wantKey,
            n .. " restyles in 0.9 s, key " .. tostring(mp and mp._zedSurveyKey))
        if check then check() end
    end)
end
function C.mp20()
    local T = { L = "MP20 theme and status colors" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    C.restyleQ(T, "Dark to Light", function() H.theme("light") end, "light")
    C.restyleQ(T, "Light to High contrast", function() H.theme("hicon") end, "hicon")
    C.restyleQ(T, "High contrast to Dark", function() H.theme("dark") end, "dark")
    C.restyleQ(T, "status colors color blind", function() H.status("cb") end, "dark:cb", function()
        local r, g, b = H.layerRGB("building-Medical", 1)
        local want = ZeD.MapsSurvey.PALETTES.dark.cb.Medical
        Q.check(H.hexIs(want, r, g, b), T.L .. ": color blind, the engine's building-Medical layer takes the color blind set", H.rgbTxt(r, g, b) .. " (want " .. want .. ")")
    end)
    C.restyleQ(T, "status colors standard", function() H.status("standard") end, "dark", function()
        local r, g, b = H.layerRGB("building-Medical", 1)
        local want = ZeD.MapsSurvey.PALETTES.dark.b.Medical
        Q.check(H.hexIs(want, r, g, b), T.L .. ": standard, building-Medical back to the Dark set", H.rgbTxt(r, g, b) .. " (want " .. want .. ")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP21 the game's colorblind patterns
function C.mp21()
    local T = { L = "MP21 the game's colorblind patterns" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        local core = getCore()
        T.was = nil
        pcall(function() T.was = core:getOptionColorblindPatterns() end)
        if T.was == nil or not core.setOptionColorblindPatterns then T.off = true; Q.skip(T.L, "the game's colorblind patterns option cannot be set from Lua here"); return end
        T.r0 = S.restyles
        T.b0r, T.b0g, T.b0b = H.layerRGB("building-Medical", 1)
        pcall(function() core:setOptionColorblindPatterns(not T.was) end)
        S.back.cbp = T.was
    end)
    H.pause(1000)
    H.step(1, function()
        if T.off then return end
        local r, g, b = H.layerRGB("building-Medical", 1)
        H.note(T.L .. ": the game's option turned " .. tostring(not T.was) .. ": Survey restyled " .. (S.restyles - T.r0) .. " times in 1 s, building-Medical "
            .. H.rgbTxt(T.b0r, T.b0g, T.b0b) .. " -> " .. H.rgbTxt(r, g, b) .. " (the game's own map re-inits for it, ISWorldMap; the paper key's pictures follow it: MapsTabKey keyTex)")
        pcall(function() getCore():setOptionColorblindPatterns(T.was) end)
        S.back.cbp = nil
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP22 Survey's printed additions (B4)
-- what Survey's data puts on the visible map: { towns, shields, places, bridges }
function H.sdOnScreen()
    local d = ZeD.MapsSurveyData or {}
    local w, h = H.mpWH()
    local n = { towns = 0, shields = 0, places = 0, iconPlaces = 0, bridges = 0 }
    local function on(x, y) local sx, sy = H.toUI(x, y); return sx and sx >= 0 and sy >= 0 and sx < w and sy < h end
    for _, t in ipairs(d.towns or {}) do if on(t.x, t.y) then n.towns = n.towns + 1 end end
    for _, t in ipairs(d.shields or {}) do if on(t.x, t.y) then n.shields = n.shields + 1 end end
    for _, t in ipairs(d.places or {}) do
        if on(t.x, t.y) then
            n.places = n.places + 1
            if ZeD.MapsSurvey.PLACE_ICON and ZeD.MapsSurvey.PLACE_ICON[t.kind] then n.iconPlaces = n.iconPlaces + 1 end
        end
    end
    for _, t in ipairs(d.bridges or {}) do if t.x and on(t.x, t.y) then n.bridges = n.bridges + 1 end end
    return n
end
function C.zoomLeg(T, z)
    H.step(2, function()
        if T.off then return end
        pcall(function() H.api():centerOn(S.p:getX(), S.p:getY()) end)
        pcall(function() H.api():setZoom(z) end)
        S.drawLast = nil
        S.drawRec = true
    end)
    H.wait(1500, function() return T.off or (S.drawLast ~= nil and S.drawLast.z ~= nil and math.abs(S.drawLast.z - z) < 0.05) end, function(ok)
        if T.off then return end
        local d = S.drawLast or {}
        local sd = H.sdOnScreen()
        local shieldsWant = z >= 12.5 and z <= 17.5 and sd.shields > 0
        local placesWant = z >= 15 and sd.iconPlaces > 0
        Q.check(ok and (((d.shield or 0) > 0) == shieldsWant),T.L .. " (zoom " .. z .. "): route shields drawn only from 12.5 to 17.5",
            "shields drawn " .. tostring(d.shield) .. ", on screen in Survey's data " .. sd.shields)
        Q.check(ok and (((d.tex or 0) > 0) == placesWant),T.L .. " (zoom " .. z .. "): place badges drawn only from 15",
            "place pictures drawn " .. tostring(d.tex) .. ", places on screen " .. sd.places .. " (" .. sd.iconPlaces .. " with a picture)")
        Q.check(ok and (d.rect or 0) > 0, T.L .. " (zoom " .. z .. "): the grid and the scale bar draw at every zoom", tostring(d.rect) .. " rectangles")
        H.note(T.L .. " (zoom " .. z .. "): towns on screen " .. sd.towns .. " (dots under 13.5), bridges " .. sd.bridges .. "; drawn: " .. tostring(d.rect) .. " rectangles, " .. tostring(d.tex) .. " pictures, " .. tostring(d.shield) .. " shields")
    end)
end
function H.knownAt(x, y)
    local real = S.w0 and S.w0.real
    local k, v = nil, nil
    if real then
        pcall(function() k = real:isKnown(math.floor(x), math.floor(y)) end)
        pcall(function() v = real:isVisited(math.floor(x), math.floor(y)) end)
    end
    return k, v
end
function C.mp22()
    local T = { L = "MP22 Survey's printed additions" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    for _, z in ipairs({ 12, 13.5, 15, 17.5, 20 }) do C.zoomLeg(T, z) end
    H.step(2, function()
        if T.off then return end
        pcall(function() H.api():centerOn(S.p:getX(), S.p:getY()) end)
        pcall(function() H.api():setZoom(15) end)
    end)
    H.shot("mz_survey_" .. H.sizeTag(), "Survey at zoom 15 on him: the grid, place badges, route shields, scale bar and north arrow (MP22)", function() return not T.off end)
    -- B4: a place far from where he has been, at zoom 15
    H.step(2, function()
        if T.off then return end
        -- the farthest place with a picture on ground the game calls neither known nor visited (the farthest at all when
        -- none reads so: then the check says what it found)
        local far, fd, unseen, ud = nil, -1, nil, -1
        local hx, hy = S.p:getX(), S.p:getY()
        for _, p in ipairs((ZeD.MapsSurveyData or {}).places or {}) do
            if ZeD.MapsSurvey.PLACE_ICON[p.kind] then
                local d = (p.x - hx) * (p.x - hx) + (p.y - hy) * (p.y - hy)
                if d > fd then far, fd = p, d end
                local k, v = H.knownAt(p.x, p.y)
                if k == false and v == false and d > ud then unseen, ud = p, d end
            end
        end
        if unseen then far = unseen end
        T.far = far
        if not far then T.off = true; Q.skip(T.L .. " (B4)", "Survey's data has no place with a picture"); return end
        pcall(function() H.api():centerOn(far.x, far.y) end)
        pcall(function() H.api():setZoom(15) end)
        S.drawLast = nil
        S.drawRec = true
    end)
    H.wait(1500, function() return T.off or (S.drawLast ~= nil and S.drawLast.z ~= nil and math.abs(S.drawLast.z - 15) < 0.05) end, function(ok)
        if T.off then return end
        local d = S.drawLast or {}
        local kHome, vHome = H.knownAt(S.p:getX(), S.p:getY())
        local kFar, vFar = H.knownAt(T.far.x, T.far.y)
        local sane = kHome == true or vHome == true
        local detail = "at " .. T.far.x .. "," .. T.far.y .. " (" .. tostring(T.far.kind) .. "): place pictures drawn " .. tostring(d.tex) .. "; WorldMapVisited isKnown/isVisited there "
            .. tostring(kFar) .. "/" .. tostring(vFar) .. ", on his own square " .. tostring(kHome) .. "/" .. tostring(vHome)
        if sane and kFar ~= nil then
            local unseen = not (kFar or vFar)
            Q.check(not (unseen and (d.tex or 0) > 0), T.L .. " (B4): no place badge over ground he has not seen", detail)
        else
            H.note(T.L .. " (B4): whether that ground is known cannot be read here (WorldMapVisited's isKnown answers no square reliably): " .. detail)
        end
        S.drawRec = nil
        pcall(function() H.api():centerOn(S.p:getX(), S.p:getY()) end)
        pcall(function() H.api():setZoom(18) end)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP23 stash map icons
function C.mp23()
    local T = { L = "MP23 stash map icons" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        local list = nil
        pcall(function() list = StashSystem.getAlreadyReadMap() end)
        local n = 0
        pcall(function() n = list:size() end)
        if n == 0 then T.off = true; Q.skip(T.L, "he has read no stash map (reading one places its stash for good, so the run reads none)"); return end
        T.name = list:get(0)
        local b = H.mp():getStashMapBounds(T.name)
        if not (b and b.x1) then T.off = true; Q.skip(T.L, "the stash map " .. tostring(T.name) .. " has no area here (LootMaps.Init)"); return end
        T.cx, T.cy = b.x1 / 2 + b.x2 / 2, b.y1 / 2 + b.y2 / 2
        H.note(T.L .. ": " .. n .. " stash maps read; " .. tostring(T.name) .. " centers at " .. H.n1(T.cx) .. "," .. H.n1(T.cy))
    end)
    for _, st in ipairs({ "survey", "color", "paper" }) do
        H.step(2, function()
            if T.off then return end
            if st == "paper" and not S.MT.hasPaper() then return end
            if H.style() ~= st then S.MT.setStyle(RT.ww(), st) end
        end)
        H.wait(3000, function() return T.off or (H.style() == st and H.mapUp()) or (st == "paper" and not S.MT.hasPaper()) end, function()
            if T.off or H.style() ~= st then return end
            local mp = H.mp()
            pcall(function() mp.mapAPI:centerOn(T.cx, T.cy) end)
            pcall(function() mp.mapAPI:setZoom(math.min(16, mp.mapAPI:getZoomF() + 0)) end)
            T.icons = 0
            local base = mp.drawTextureScaledAspect
            local own = nil
            pcall(function() own = rawget(mp, "drawTextureScaledAspect") end)
            T.dtsa = { mp = mp, own = own }
            mp.drawTextureScaledAspect = function(self, t, ...)
                local nm = ""
                pcall(function() nm = tostring(t:getName()) end)
                if H.has(nm, "Item_Map") then T.icons = T.icons + 1 end
                return base(self, t, ...)
            end
        end)
        H.step(4, function()
            if not T.dtsa then return end
            local mp = T.dtsa.mp
            pcall(function() mp.drawTextureScaledAspect = T.dtsa.own end)
            T.dtsa = nil
            if T.off then return end
            local sx, sy = H.toUI(T.cx, T.cy)
            Q.check(T.icons > 0, T.L .. " (" .. st .. "): the stash map's icon draws at its center (StashSystem.getAlreadyReadMap)", T.icons .. " icons drawn over 4 frames; the center at " .. H.n1(sx) .. "," .. H.n1(sy) .. " on the map")
            if st == "survey" and sx then
                T.c0 = H.ctxSince(0)
                H.mapClick(sx, sy)
                Q.check(not H.readerUp() and H.ctxSince(0) == T.c0 and H.style() == st, T.L .. ": a click on the icon does nothing (no reader, no menu)", "reader " .. tostring(H.readerUp()))
            end
        end)
    end
    H.caseEnd(T.L)
end

-- ===================================================================== flyers: one the game defines with places
function H.flyerPick()
    local defs = PrintMediaDefinitions and PrintMediaDefinitions.MiscDetails
    if not defs then return nil end
    local keys = {}
    for id, d in pairs(defs) do if type(d) == "table" and d.location1 and d.location1[1] then keys[#keys + 1] = tostring(id) end end
    table.sort(keys)
    local read = nil
    pcall(function() read = S.p:getReadPrintMedia() end)
    for _, id in ipairs(keys) do
        local has = false
        pcall(function() has = read:contains(id) end)
        if not has then return id, defs[id] end
    end
    return keys[1], keys[1] and defs[keys[1]]
end
-- the piece counted as read (the game's own set), taken back at the case's end
function H.readAdd(id)
    local ok = false
    pcall(function()
        local set = S.p:getReadPrintMedia()
        if not set:contains(id) then set:add(id); S.readAdded[#S.readAdded + 1] = id end
        ok = S.p:getReadPrintMedia():contains(id)
    end)
    return ok
end
function H.readBack()
    for _, id in ipairs(S.readAdded) do pcall(function() S.p:getReadPrintMedia():remove(id) end) end
    S.readAdded = {}
end
function H.rectMid(r) return (r.x1 + r.x2) / 2, (r.y1 + r.y2) / 2 end

-- ===================================================================== MP24 flyer pins
function C.mp24()
    local T = { L = "MP24 flyer pins" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        T.id, T.def = H.flyerPick()
        if not T.id then T.off = true; Q.skip(T.L, "the game defines no piece with places (PrintMediaDefinitions.MiscDetails)"); return end
        if not H.readAdd(T.id) then T.off = true; Q.skip(T.L, "the game's set of read pieces cannot take one here (getReadPrintMedia)"); return end
        T.wx, T.wy = H.rectMid(T.def.location1[1])
        pcall(function() H.api():centerOn(T.wx, T.wy) end)
        pcall(function() H.api():setZoom(17) end)
    end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        local mp = H.mp()
        T.pin = nil
        for _, p in ipairs(mp._flyerPins or {}) do if p.id == T.id and p.j == 1 and p.k == 1 then T.pin = p end end
        local tx, ty = H.toUI(T.wx, T.wy)
        local ok = T.pin ~= nil and math.abs(T.pin.x + T.pin.w / 2 - tx) <= 2
        Q.check(ok, T.L .. ": a read piece's place gets its pin at the place (the definition's first place, his read set)", "piece " .. tostring(T.id) .. "; pin "
            .. (T.pin and (H.n1(T.pin.x) .. "," .. H.n1(T.pin.y) .. " " .. T.pin.w .. "x" .. T.pin.h) or "none") .. "; the place on the map at " .. H.n1(tx) .. "," .. H.n1(ty)
            .. "; pins " .. #(mp._flyerPins or {}))
        if not T.pin then T.off = true; return end
        T.mx, T.my = T.pin.x + math.floor(T.pin.w / 2), T.pin.y + math.floor(T.pin.h / 2)
        H.fake(T.mx, T.my)
    end)
    H.pause(1300)
    H.step(1, function()
        if T.off then return end
        local mp = H.mp()
        local title = ZeD.FlyerMap.meta(T.id).title
        local hov = mp._flyerHover
        Q.check(hov ~= nil and hov.id == T.id and H.drewOn(mp, title) ~= nil, T.L .. ": the pointer resting on the pin shows its card, titled \"" .. tostring(title) .. "\"",
            "hovered " .. tostring(hov and hov.id) .. "; drawn on the map: " .. H.textsLike(string.sub(tostring(title), 1, 12)))
        H.fakeOff()
        H.mapClick(T.mx, T.my)
    end)
    H.wait(2000, function() return T.off or H.readerUp() end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": a click on the pin opens the piece in ZeD's reader", "reader up " .. tostring(H.readerUp()))
        H.readerShut()
    end)
    H.step(3, function()
        if T.off then return end
        T.go = H.cursorAt(T.mx, T.my)
    end)
    H.tapA(function() return T.go and not T.off end)
    H.wait(2000, function() return T.off or not T.go or H.readerUp() end, function(ok)
        H.padOff()
        if T.off or not T.go then return end
        Q.check(ok, T.L .. " (pad): A with the map's cursor on the pin opens the reader", "reader up " .. tostring(H.readerUp()) .. ", focus " .. tostring(H.focusedId()))
        H.readerShut()
    end)
    -- a visit: a place of the run's own under his feet (the definitions copied, one place added, put back), within 1 s
    H.step(2, function()
        if T.off then return end
        local defs = PrintMediaDefinitions.MiscDetails
        local copy = {}
        for k, v in pairs(defs) do copy[k] = v end
        local x, y = math.floor(S.p:getX()), math.floor(S.p:getY())
        copy.zedqa_mz_place = { location1 = { { x1 = x - 2, y1 = y - 2, x2 = x + 2, y2 = y + 2 } } }
        S.defs0 = defs
        PrintMediaDefinitions.MiscDetails = copy
        T.v0 = getTimestampMs()
    end)
    H.wait(2500, function() local s = H.md().ZeD_FlyerSeen; return T.off or (s ~= nil and s["zedqa_mz_place:1:1"] == true) end, function(ok)
        if S.defs0 then PrintMediaDefinitions.MiscDetails = S.defs0; S.defs0 = nil end
        if T.off then return end
        Q.check(ok, T.L .. ": standing in a place marks it visited within a second or so (modData.ZeD_FlyerSeen)", "in " .. (getTimestampMs() - T.v0) .. " ms: " .. tostring(ok))
        pcall(function() H.md().ZeD_FlyerSeen["zedqa_mz_place:1:1"] = nil end)
        H.note(T.L .. ": the pin's been-there tick follows ZeD.FlyerMap.visited; the piece's real place stays unvisited here (the run moves him nowhere new)")
    end)
    H.step(2, function() H.readBack() end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP25 the map's labels
function H.lineH(name) local v = nil; pcall(function() v = H.api():getStyleAPI():getLayerByName(name):getLineHeight() end); return v end
function H.labelAlpha(name)
    local mx = nil
    local ok = pcall(function()
        local l = H.api():getStyleAPI():getLayerByName(name)
        mx = 0
        for i = 0, l:getFillStops() - 1 do mx = math.max(mx, l:getFillAlpha(i)) end
    end)
    if not ok then return nil end
    return mx
end
function C.labelsQ(T, tag)
    H.step(2, function()
        if T.off then return end
        local root = H.root()
        local want = math.floor(48 * root + 0.5)
        local got = H.lineH("text-town")
        if got == nil then H.note(T.L .. " (" .. tag .. "): the label layers' line height cannot be read here (getLineHeight)")
        else Q.check(got == want, T.L .. " (" .. tag .. "): the town names' line height follows the UI scale (48 x " .. H.n2(root) .. ")", tostring(got) .. " (want " .. want .. ")") end
    end)
end
function C.mp25()
    local T = { L = "MP25 the map's labels" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    C.labelsQ(T, "UI scale as found")
    H.step(2, function()
        if T.off then return end
        local a = H.labelAlpha("text-town")
        local sn, pn2 = nil, nil
        pcall(function() sn, pn2 = H.api():getBoolean("ShowStreetNames"), H.api():getBoolean("PlaceNames") end)
        Q.check((a == nil or a > 0) and sn == true and pn2 == true, T.L .. ": Survey shows the town, street and place names", "town fill alpha " .. tostring(a) .. ", street names " .. tostring(sn) .. ", place names " .. tostring(pn2))
        if not S.MT.hasPaper() then T.noPaper = true; return end
        S.MT.setStyle(RT.ww(), "paper")
    end)
    H.wait(3000, function() return T.off or T.noPaper or (H.style() == "paper" and H.mapUp()) end, function(ok)
        if T.off or T.noPaper then return end
        local o, bad = {}, 0
        for _, nm in ipairs(S.MT.LABEL_LAYERS or {}) do
            local a = H.labelAlpha(nm)
            o[#o + 1] = nm .. " " .. tostring(a)
            if a ~= nil and a > 0 then bad = bad + 1 end
        end
        local note = H.labelAlpha("text-note")
        if note == nil then H.note(T.L .. ": the label layers' fill alpha cannot be read here (getFillAlpha)") else Q.check(ok and bad == 0 and note > 0, T.L .. ": Paper hides the map's own names (it prints its own) and keeps the player's notes", H.list(o) .. "; text-note " .. tostring(note)) end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP9 Show on map from the reader (B5)
function C.showQ(T, by)
    local L = T.L .. " (" .. by .. ")"
    H.step(2, function()
        if T.off then return end
        H.legClean()
        S.known = {}
        T.e0 = H.errN()
        RT.worldTab("loot")
        T.opened = ZeD.Reader.openPrintId(S.p, T.id)
    end)
    H.wait(2000, function() return T.off or H.readerUp() end, function(ok)
        if T.off then return end
        local r = H.reader()
        if not (ok and r and r.places and #r.places > 0) then Q.check(false, L .. ": the reader opens the piece with its places", "reader up " .. tostring(ok) .. ", places " .. tostring(r and r.places and #r.places)); T.skipLeg = true; return end
        T.skipLeg = nil
        H.qstop()
        if by == "mouse" then H.zcall(function() r:showPlace(1) end) else H.zcall(function() r:onJoypadDown(Joypad.AButton, nil) end) end
        local a = H.qfirst("ISReadWorldMap")
        T.act = a and { x = a.centerX, y = a.centerY, z = a.zoom } or nil
    end)
    H.wait(6000, function() return T.off or T.skipLeg or H.popUp() end, function(ok)
        if T.off or T.skipLeg then return end
        local loc = T.def.location1
        local xx, yy = 0, 0
        for _, r in ipairs(loc) do xx = xx + r.x1 + r.x2; yy = yy + r.y1 + r.y2 end
        local cx0, cy0 = xx / (#loc * 2), yy / (#loc * 2)
        local same = #S.known == #loc
        for i, r in ipairs(loc) do local k = S.known[i]; if not (k and k.x1 == r.x1 and k.y1 == r.y1 and k.x2 == r.x2 and k.y2 == r.y2) then same = false end end
        Q.check(same, L .. ": the place's squares are made known (WorldMapVisited setKnownInSquares, held back by the run)", #S.known .. " asked, " .. #loc .. " in the definition")
        Q.check(T.act ~= nil and math.abs((T.act.x or 0) - cx0) < 0.6 and math.abs((T.act.y or 0) - cy0) < 0.6, L .. ": the game's read is queued on the place's middle",
            "the action's center " .. H.n1(T.act and T.act.x) .. "," .. H.n1(T.act and T.act.y) .. ", the place's " .. H.n1(cx0) .. "," .. H.n1(cy0))
    end)
    H.pause(400)
    H.step(1, function()
        if T.off or T.skipLeg then return end
        local cx, cy = H.cxy()
        local z = H.zoom()
        local f = ZeD.FlyerMap._flash
        Q.check(cx ~= nil and T.act ~= nil and math.abs(cx - T.act.x) <= 1 and math.abs(cy - T.act.y) <= 1 and z ~= nil and math.abs(z - (T.act.z or z)) < 0.05,
            T.L .. " (" .. by .. "): the unfolded map lands centered and zoomed as the read asked", "center " .. H.n1(cx) .. "," .. H.n1(cy) .. ", zoom " .. H.n2(z) .. " (asked " .. H.n2(T.act and T.act.z) .. ")")
        Q.check(f ~= nil and math.abs(f.x - T.act.x) < 0.6, T.L .. " (" .. by .. "): the place pulses (ZeD.FlyerMap._flash)", f and (H.n1(f.x) .. "," .. H.n1(f.y)) or "no pulse")
        T.e1 = H.errN()
    end)
    H.pause(2800)
    H.step(1, function()
        if T.off or T.skipLeg then return end
        Q.check(ZeD.FlyerMap._flash == nil, T.L .. " (" .. by .. "): the pulse ends after 2.6 s", tostring(ZeD.FlyerMap._flash ~= nil))
        if T.b5 then
            local n = (T.e0 and T.e1) and (T.e1 - T.e0) or nil
            Q.check(n == 0, T.L .. " (B5): landing on a map he keeps on Paper, made fresh, throws nothing", tostring(n) .. " Lua errors over the landing (the landing's setZoom runs unguarded in OnTick)")
        end
    end)
end
function C.mp9()
    local T = { L = "MP9 Show on map" }
    H.step(2, function()
        H.caseStart(T)
        T.id, T.def = H.flyerPick()
        if not (T.id and ZeD.Reader and ZeD.Reader.openPrintId and ZeD.Print and ZeD.Print.showOnMap) then T.off = true; Q.skip(T.L, "no piece with places, or no reader"); return end
    end)
    C.showQ(T, "mouse")
    C.showQ(T, "pad")
    -- B5: the map on Paper, the World window shut, so the landing meets a map made that moment
    H.step(2, function()
        if T.off then return end
        if not S.MT.hasPaper() then Q.skip(T.L .. " (B5)", "this map has no illustration"); T.off = true; return end
        H.md().ZeD_MapStyle = "paper"
        RT.pairShut()
        pcall(ZeD_WorldWindow.close, S.pn)
        T.b5 = true
    end)
    C.showQ(T, "mouse, Paper, a fresh map")
    H.step(2, function() H.md().ZeD_MapStyle = "survey"; RT.pairOpen() end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP26 the map key
function H.keyCols()
    local rows = {}
    pcall(function() rows = ZeD.MapsSurvey.keyColors() end)
    local words = {}
    for _, r in ipairs(rows or {}) do if r.text then words[tostring(r.text)] = true end end
    local xs, n = {}, 0
    local mp = H.mp()
    for _, t in ipairs(S.texts or {}) do
        if t.p == mp and words[t.s] then
            local k = math.floor(t.x / 6)
            if not xs[k] and not xs[k - 1] and not xs[k + 1] then n = n + 1 end
            xs[k] = true
        end
    end
    return n
end
function C.mp26()
    local T = { L = "MP26 the map key" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function() if not T.off then H.click("map:ext:key", T.L) end end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        local w = RT.ww()
        Q.check(w._mapKeyOpen == true and H.zone("map:key:page:colors") ~= nil and H.zone("map:key:page:symbols") ~= nil and H.zone("map:key:close") ~= nil,
            T.L .. ": Key on the band opens Survey's key with its two pages and its close box", "open " .. tostring(w._mapKeyOpen) .. "; " .. H.list(H.zoneIds(), 30))
        -- the columns follow the map's height, not the screen (MapsTabKey surveyBody: two, a third only when two run
        -- taller than the map): the check is that the key's panel stays inside the map; the columns are a NOTE
        local cols = H.keyCols()
        local pz = H.zone("map:key:panel")
        local mp = H.mp()
        local inside, rect = false, "?"
        pcall(function()
            local mx, my, mw, mh = mp:getX(), mp:getY(), mp:getWidth(), mp:getHeight()
            inside = pz ~= nil and pz.x >= mx - 1 and pz.y >= my - 1 and pz.x + pz.w <= mx + mw + 1 and pz.y + pz.h <= my + mh + 1
            rect = "key " .. math.floor(pz.x) .. "," .. math.floor(pz.y) .. " " .. math.floor(pz.w) .. "x" .. math.floor(pz.h) .. " in the map " .. math.floor(mx) .. "," .. math.floor(my) .. " " .. math.floor(mw) .. "x" .. math.floor(mh)
        end)
        Q.check(inside, T.L .. ": the Colors page fits inside the map (its columns as many as the map's height asks)", rect .. "; " .. cols .. " columns drawn")
        H.note(T.L .. ": the Colors page in " .. cols .. " columns at " .. H.sizeTag() .. " (a third column only when two would run taller than the map)")
        H.click("map:key:page:symbols", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(RT.ww()._mapKeyPage == "symbols", T.L .. ": Symbols turns the page", tostring(RT.ww()._mapKeyPage))
        H.click("map:key:close", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(RT.ww()._mapKeyOpen ~= true, T.L .. ": the close box shuts it", tostring(RT.ww()._mapKeyOpen))
    end)
    -- the pad: Key, Symbols, Colors, the close box
    H.padPress(T, "map:ext:key")
    H.pause(300)
    H.padPress(T, "map:key:page:symbols")
    H.pause(300)
    H.step(1, function() if not T.off then Q.check(RT.ww()._mapKeyOpen == true and RT.ww()._mapKeyPage == "symbols", T.L .. " (pad): A on Key and on Symbols", "open " .. tostring(RT.ww()._mapKeyOpen) .. ", page " .. tostring(RT.ww()._mapKeyPage)) end end)
    H.padPress(T, "map:key:page:colors")
    H.pause(300)
    H.padPress(T, "map:key:close")
    H.pause(300)
    H.step(1, function()
        H.padOff()
        if T.off then return end
        Q.check(RT.ww()._mapKeyOpen ~= true and RT.ww()._mapKeyPage == "colors", T.L .. " (pad): A on Colors, then on the close box", "open " .. tostring(RT.ww()._mapKeyOpen) .. ", page " .. tostring(RT.ww()._mapKeyPage))
        S.MT.setStyle(RT.ww(), "color")
    end)
    -- on Color: the line and Show survey, which switches the style
    H.wait(3000, function() return T.off or (H.style() == "color" and H.mapUp()) end, function() if not T.off then H.click("map:ext:key", T.L) end end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        Q.check(H.zone("map:key:survey") ~= nil and H.zone("map:key:page:colors") == nil, T.L .. ": on Color the key is one line and Show survey", H.list(H.zoneIds(), 30))
        H.click("map:key:survey", T.L)
    end)
    H.wait(3000, function() return T.off or (H.style() == "survey" and H.mapUp()) end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": Show survey switches the map to Survey", "style " .. tostring(H.style()) .. ", key open " .. tostring(RT.ww()._mapKeyOpen))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP27 zoom
function C.mp27()
    local T = { L = "MP27 zoom" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        local w, h = H.mpWH()
        H.fake(math.floor(w / 2), math.floor(h / 2))
        T.z0 = H.zoom()
        T.mx = 0
    end)
    for _ = 1, 16 do
        H.step(2, function()
            if T.off then return end
            H.zcall(function() H.mp():onMouseWheel(-1) end)
            T.mx = math.max(T.mx, H.zoom() or 0)
        end)
    end
    H.pause(700)
    H.step(1, function()
        if T.off then return end
        local z = H.zoom()
        T.mx = math.max(T.mx, z or 0)
        local maxZ = nil
        pcall(function() maxZ = H.api():getMaxZoom() end)
        Q.check(z ~= nil and z >= 23.9 and T.mx <= 24.01, T.L .. ": the wheel zooms in to 24 and no further (the game's closest)", H.n2(T.z0) .. " -> " .. H.n2(z) .. ", the most " .. H.n2(T.mx) .. ", the map's max " .. tostring(maxZ))
        T.zIn = z
    end)
    for _ = 1, 8 do H.step(2, function() if not T.off then H.zcall(function() H.mp():onMouseWheel(1) end) end end) end
    H.pause(700)
    H.step(1, function()
        if T.off then return end
        local z = H.zoom()
        Q.check(z ~= nil and T.zIn ~= nil and z < T.zIn - 1, T.L .. ": the wheel zooms back out", H.n2(T.zIn) .. " -> " .. H.n2(z))
        H.fakeOff()
        -- the pad's triggers: the step they take on the cursor (gpZoom, what _mapPadTick calls every 110 ms while held)
        T.zp = z
        local w = RT.ww()
        for _ = 1, 3 do H.zcall(function() S.MT.gpZoom(w, -1) end) end
    end)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        local z = H.zoom()
        Q.check(z ~= nil and T.zp ~= nil and z > T.zp, T.L .. " (pad): RT's step zooms in on the cursor (ZeD.MapsTab.gpZoom)", H.n2(T.zp) .. " -> " .. H.n2(z))
        local jd = nil
        pcall(function() jd = getJoypadData(S.pn) end)
        if not jd then H.note(T.L .. " (pad): no pad is bound on this rig, so the triggers' reading and their 110 ms step are not driven (the trigger's step is)") end
        -- the drawer's wheel (the pointer on the band): the drawer hands it to the map
        T.zd = z
        local w = RT.ww()
        local dr = w and w._drawerPanel
        if dr then H.zcall(function() dr:onMouseWheel(1) end) end
    end)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        local z = H.zoom()
        Q.check(z ~= nil and T.zd ~= nil and z < T.zd, T.L .. ": the drawer's wheel (the pointer on the band) zooms the map", H.n2(T.zd) .. " -> " .. H.n2(z))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP28 pan
function C.mp28()
    local T = { L = "MP28 pan" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        local w, h = H.mpWH()
        T.x0, T.y0 = math.floor(w / 2), math.floor(h / 2)
        T.c0x, T.c0y = H.cxy()
        local mp = H.mp()
        H.fake(T.x0, T.y0)
        H.zcall(function() mp:onMouseDown(T.x0, T.y0) end)
        H.fake(T.x0 + H.px(100), T.y0)
        H.zcall(function() mp:onMouseMove(H.px(100), 0) end)
        T.c1x, T.c1y = H.cxy()
        -- released off the map: the map stops panning
        H.zcall(function() mp:onMouseUpOutside(T.x0 + H.px(2000), T.y0) end)
        H.fake(T.x0 + H.px(200), T.y0)
        H.zcall(function() mp:onMouseMove(H.px(100), 0) end)
        T.c2x, T.c2y = H.cxy()
        T.drag = mp.dragging
        -- a drag shorter than 4 units: no pan
        H.fake(T.x0, T.y0)
        H.zcall(function() mp:onMouseDown(T.x0, T.y0) end)
        H.fake(T.x0 + H.px(3), T.y0)
        H.zcall(function() mp:onMouseMove(H.px(3), 0) end)
        T.c3x, T.c3y = H.cxy()
        H.zcall(function() mp:onMouseUp(T.x0 + H.px(3), T.y0) end)
        H.fakeOff()
        Q.check(T.c1x ~= nil and T.c0x ~= nil and T.c1x < T.c0x - 0.5, T.L .. ": a drag pans the map (the center moves against the pointer)", H.n1(T.c0x) .. " -> " .. H.n1(T.c1x))
        Q.check(T.c2x ~= nil and math.abs(T.c2x - T.c1x) < 0.01 and not T.drag, T.L .. ": released off the map, it stops panning", "after the release " .. H.n1(T.c1x) .. " -> " .. H.n1(T.c2x) .. ", still dragging " .. tostring(T.drag))
        Q.check(T.c3x ~= nil and math.abs(T.c3x - T.c2x) < 0.01, T.L .. ": a drag under 4 units does not pan", H.n1(T.c2x) .. " -> " .. H.n1(T.c3x))
        -- the pad's stick: the cursor pushed to each edge holds at the margin and the map scrolls under it
        local win = RT.ww()
        local o = {}
        local good = true
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            mp._gpCursorX, mp._gpCursorY = T.x0, T.y0
            local ax, ay = H.cxy()
            H.zcall(function() S.MT.gpMoveCursor(win, d[1] * w, d[2] * h) end)
            local bx, by = H.cxy()
            local m = H.px(48)
            local atEdge = (d[1] == 1 and mp._gpCursorX == w - m) or (d[1] == -1 and mp._gpCursorX == m) or (d[2] == 1 and mp._gpCursorY == h - m) or (d[2] == -1 and mp._gpCursorY == m)
            local moved = (d[1] ~= 0 and math.abs((bx or 0) - (ax or 0)) > 0.5) or (d[2] ~= 0 and math.abs((by or 0) - (ay or 0)) > 0.5)
            if not (atEdge and moved) then good = false end
            o[#o + 1] = d[1] .. "," .. d[2] .. ": cursor " .. tostring(mp._gpCursorX) .. "," .. tostring(mp._gpCursorY) .. ", center moved " .. tostring(moved)
        end
        Q.check(good, T.L .. " (pad): the stick's cursor holds at the 48-unit margin and the map scrolls (ZeD.MapsTab.gpMoveCursor)", H.list(o))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP29 the view when the map opens again
function C.mp29()
    local T = { L = "MP29 opening again" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        T.dx, T.dy = H.cxy()
        T.drawer = H.mp()
    end)
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        pcall(function() H.api():centerOn(S.p:getX() + 2500, S.p:getY() - 2500) end)
        H.click("map:popout", T.L)
    end)
    H.wait(2000, function() return T.off or (H.pop() == nil and H.mapUp()) end, function(ok)
        if T.off then return end
        local x, y = H.cxy()
        Q.check(ok and H.mp() == T.drawer and x ~= nil and math.abs(x - T.dx) < 0.5 and math.abs(y - T.dy) < 0.5, T.L .. ": folded, the drawer's map is where it was left",
            H.n1(T.dx) .. "," .. H.n1(T.dy) .. " -> " .. H.n1(x) .. "," .. H.n1(y) .. ", the same map " .. tostring(H.mp() == T.drawer))
    end)
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        local x, y = H.cxy()
        local z = H.zoom()
        Q.check(x ~= nil and math.abs(x - S.p:getX()) <= 1 and math.abs(y - S.p:getY()) <= 1 and z ~= nil and math.abs(z - 18) < 0.01,
            T.L .. ": unfolded again, the map opens on him at zoom 18 (the pan is not kept)", "center " .. H.n1(x) .. "," .. H.n1(y) .. ", zoom " .. H.n2(z))
        H.note(T.L .. ": the game's own map keeps its center, zoom and toggles between openings (ISWorldMap's saved settings); ZeD's unfolded map starts on him each time")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== marks: the tool's stop on the header or in the full set
function H.toolFid(id)
    if H.zone("map:tool:" .. id) then return "map:tool:" .. id end
    return "map:gridtool:" .. id
end
function H.armed() local w = RT.ww(); return w and w._mapActiveTool or nil end
-- queue: the tool id picked up by a click (the fold opened first when it is not on the header)
function H.armQ(T, id)
    H.step(2, function()
        if T.off then return end
        local w = RT.ww()
        if w._mapActiveTool == id then return end
        if id ~= "text" and not H.zone("map:tool:" .. id) then w._mapToolsExpanded = true end
    end)
    H.step(2, function()
        if T.off then return end
        if RT.ww()._mapActiveTool ~= id then H.click(H.toolFid(id), T.L) end
    end)
    H.step(2, function() end)
end
-- a mark placed by a click at (x, y) of the map; the new mark returned (nil when none)
function H.placeAt(x, y)
    local before = {}
    for _, s in ipairs(H.userSyms()) do before[s] = true end
    H.mapClick(x, y)
    local made = nil
    for _, s in ipairs(H.userSyms()) do if not before[s] then made = s end end
    return made
end
function H.scaleOf(s) local v = nil; pcall(function() v = s:getScale() end); return v end

-- ===================================================================== MP30 no pen
function C.mp30()
    local T = { L = "MP30 no pen" }
    H.step(2, function() H.caseStart(T); H.kit({}) end)
    H.tabQ(T)
    H.step(3, function()
        if T.off then return end
        RT.ww()._mapToolsExpanded = true
    end)
    H.step(3, function()
        if T.off then return end
        local lit = {}
        local n = 0
        for _, id in ipairs(S.ICONS) do
            for _, pre in ipairs({ "map:tool:", "map:gridtool:" }) do
                local b = H.btn(pre .. id)
                if b then n = n + 1; if not b.dis then lit[#lit + 1] = pre .. id end end
            end
        end
        local aa = H.btn("map:tool:text")
        if aa and not aa.dis then lit[#lit + 1] = "map:tool:text" end
        Q.check(not H.gameCanWrite() and n > 0 and #lit == 0, T.L .. ": with no pen every mark and Aa take the greyed look (the game: nothing to write with)",
            n .. " mark buttons drawn; lit: " .. H.list(lit, 8) .. "; the game's canWrite " .. tostring(H.gameCanWrite()))
        T.t1 = getTimestampMs()
        H.click(H.toolFid("house"), T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.armed() == nil and H.said(T.t1, "Tooltip_Map_CantWrite"), T.L .. ": a press on a mark says the game's \"" .. H.txt("Tooltip_Map_CantWrite") .. "\" over his head, no tool up",
            "tool " .. tostring(H.armed()) .. "; said " .. H.list(H.saidSince(T.t1)))
        T.t2 = getTimestampMs()
        H.click("map:tool:text", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.armed() == nil and H.said(T.t2, "Tooltip_Map_CantWrite"), T.L .. ": Aa the same", "tool " .. tostring(H.armed()) .. "; said " .. H.list(H.saidSince(T.t2)))
        T.t3 = getTimestampMs()
    end)
    H.padPress(T, function() return H.toolFid("star") end)
    H.pause(300)
    H.step(1, function()
        H.padOff()
        if T.off then return end
        Q.check(H.armed() == nil and H.said(T.t3, "Tooltip_Map_CantWrite"), T.L .. " (pad): A on a mark says it too", "tool " .. tostring(H.armed()) .. "; said " .. H.list(H.saidSince(T.t3)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP31 each mark in each ink
function C.mp31icon(T, i, id)
    H.armQ(T, id)
    H.step(1, function()
        if T.off then return end
        T.row = { ok = 0, bad = {} }
        T.armedOk = H.armed() == id
        if not T.armedOk then T.row.bad[#T.row.bad + 1] = "not picked up (tool " .. tostring(H.armed()) .. ")" end
    end)
    for k = 1, 5 do
        H.step(2, function()
            if T.off or not T.armedOk then return end
            H.click("map:color:" .. k, T.L)
        end)
        H.step(2, function()
            if T.off or not T.armedOk then return end
            local x, y = H.freeSpot((i - 1) * 5 + k)
            local n0 = H.marks()
            local s = H.placeAt(x, y)
            local want = S.N.SYMBOL_BY_ICON[id]
            local sid, sc = nil, H.scaleOf(s)
            pcall(function() sid = s:getSymbolID() end)
            local scaleOk = sc == nil or math.abs(sc - ((ISMap and ISMap.SCALE) or 0.666)) < 0.01
            if s and H.marks() == n0 + 1 and sid == want and H.inkIs(s, k) and scaleOk and H.armed() == id then T.row.ok = T.row.ok + 1
            else T.row.bad[#T.row.bad + 1] = "ink " .. k .. ": " .. (s and H.sig(s) or "no mark") .. " scale " .. tostring(sc) .. ", count " .. n0 .. " -> " .. H.marks() .. ", tool " .. tostring(H.armed()) end
        end)
    end
    H.step(1, function()
        if T.off then return end
        Q.check(T.row.ok == 5, T.L .. " (" .. id .. "): one mark in each of the five inks, each the game's symbol " .. tostring(S.N.SYMBOL_BY_ICON[id])
            .. " in the pen's color at the game's scale (ISMap.SCALE), the tool still up", T.row.ok .. " of 5; " .. H.list(T.row.bad, 3))
        if i == 1 then T.shotNow = true end
    end)
    if i == 1 then H.shot("mz_world_" .. H.sizeTag(), "the drawer's Survey map: the full set of marks open, House picked up with its five inks on the header, five houses placed (MP31)", function() return not T.off end) end
    H.step(2, function() if not T.off then H.removeNew() end end)
end
function C.mp31()
    local T = { L = "MP31 the marks in every ink" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    for i, id in ipairs(S.ICONS) do C.mp31icon(T, i, id) end
    -- the pad: a mark, an ink and A on the canvas
    H.step(2, function() if not T.off then RT.ww()._mapActiveTool = nil end end)
    H.padPress(T, function() return H.toolFid("skull") end)
    H.pause(200)
    H.padPress(T, "map:color:3")
    H.pause(200)
    H.step(1, function()
        if T.off then return end
        T.px, T.py = H.freeSpot(3)
        T.n0 = H.marks()
        T.go = H.cursorAt(T.px, T.py)
    end)
    H.tapA(function() return T.go and not T.off end)
    H.pause(300)
    H.step(1, function()
        H.padOff()
        if T.off then return end
        local s = H.lastNew()
        local sid = nil
        pcall(function() sid = s:getSymbolID() end)
        Q.check(s ~= nil and H.marks() == T.n0 + 1 and sid == "Skull" and H.inkIs(s, 3) and H.armed() == "skull", T.L .. " (pad): A on Skull, on the blue ink, then A on the map's cursor places a blue Skull there, the tool still up",
            (s and H.sig(s) or "no mark") .. ", count " .. tostring(T.n0) .. " -> " .. H.marks() .. ", tool " .. tostring(H.armed()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP32 the ink rules
function C.mp32()
    local T = { L = "MP32 the ink rules" }
    H.step(2, function() H.caseStart(T); H.kit({ Pencil = true }) end)
    H.tabQ(T)
    H.armQ(T, "house")
    H.step(2, function()
        if T.off then return end
        local ink = S.MT.ink(RT.ww(), true)
        local o, same = {}, true
        for i, t in ipairs(S.PEN_TYPES) do
            local g = H.gameHasPen(t)
            o[#o + 1] = t .. " " .. tostring(ink.pen[i] and true or false) .. "/" .. tostring(g)
            if (ink.pen[i] and true or false) ~= g then same = false end
        end
        Q.check(same and #(RT.ww()._mapColorZones or {}) > 0, T.L .. ": only a Pencil: the inks ZeD lights are the game's pens at hand", "ZeD/game: " .. H.list(o))
        T.t1 = getTimestampMs()
        H.click("map:color:4", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(RT.ww()._mapActiveColor == 1 and H.said(T.t1, "Tooltip_Map_NeedRedPen"), T.L .. ": a press on the red ink says the game's \"" .. H.txt("Tooltip_Map_NeedRedPen") .. "\" and keeps the pencil",
            "ink " .. tostring(RT.ww()._mapActiveColor) .. "; said " .. H.list(H.saidSince(T.t1)))
        H.kit({ Pencil = true, RedPen = true })
    end)
    H.step(3, function() if not T.off then H.click("map:color:4", T.L) end end)
    H.step(3, function()
        if T.off then return end
        T.picked = RT.ww()._mapActiveColor
        H.kit({ Pencil = true })
    end)
    -- (ZeD reads the pens at most four times a second, MapsTab _mapInk's 250 ms cache: the read after 600 ms)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        Q.check(T.picked == 4 and RT.ww()._mapActiveColor == 1 and H.armed() == "house", T.L .. ": the red pen put away with the tool up: the ink moves to the next pen at hand (the pencil)",
            "picked " .. tostring(T.picked) .. ", now " .. tostring(RT.ww()._mapActiveColor) .. ", tool " .. tostring(H.armed()))
        H.kit({})
    end)
    H.pause(600)
    H.step(1, function()
        if T.off then return end
        Q.check(H.armed() == nil, T.L .. ": the last pen put away: the tool goes down", "tool " .. tostring(H.armed()) .. ", the game's canWrite " .. tostring(H.gameCanWrite()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP33 the first ink
function C.mp33()
    local T = { L = "MP33 the first ink" }
    H.step(2, function() H.caseStart(T); H.kit({ Pencil = true, Pen = true }) end)
    H.tabQ(T)
    H.step(2, function() if not T.off then RT.ww()._mapActiveColor = nil end end)
    H.armQ(T, "star")
    H.step(2, function()
        if T.off then return end
        local x, y = H.freeSpot(2)
        local s = H.placeAt(x, y)
        local game = nil
        for _, t in ipairs(S.GAME_PEN_ORDER) do if not game and H.gameHasPen(t) then game = t end end
        local gi = nil
        for i, k in ipairs(S.N.INKS) do if k.item == game then gi = i end end
        Q.check(s ~= nil and gi ~= nil and H.inkIs(s, gi), T.L .. ": with a Pen and a Pencil and no ink chosen, ZeD marks with the pen the game would take first",
            "ZeD's mark in " .. (s and H.inkName(s) or "nothing") .. "; the game's first pen at hand (ISWorldMapSymbols: Pen, Pencil, Red, Blue, Green) " .. tostring(game))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP34 a note (MP35 the pad's note: B3)
function C.mp34()
    local T = { L = "MP34 a note" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.armQ(T, "text")
    H.step(2, function()
        if T.off then return end
        local te = RT.ww()._mapTextEntry
        if not (te and H.armed() == "text") then T.off = true; Q.check(false, T.L .. ": Aa picks up the note and shows its box", "tool " .. tostring(H.armed()) .. ", box " .. tostring(te ~= nil)); return end
        local fifty = "ZEDQA fifty abcdefghijabcdefghijabcdefghijabcdefghij"
        pcall(function() te:setText(fifty) end)
        local kept = ""
        pcall(function() kept = te:getText() end)
        local x, y = H.freeSpot(1)
        local n0 = H.marks()
        local s = H.placeAt(x, y)
        local words = nil
        pcall(function() words = s:getTranslatedText() end)
        Q.check(s ~= nil and H.marks() == n0 + 1 and words == kept, T.L .. ": a click puts the box's words on the map as one note", "note \"" .. tostring(words) .. "\", the box \"" .. tostring(kept) .. "\"")
        H.note(T.L .. ": 50 characters handed to the box keep " .. string.len(kept) .. " (ZeD's box takes the game's 45-character limit, setMaxTextLength; the run sets the words as one block)")
        pcall(function() te:setText("    ") end)
        local n1 = H.marks()
        local x2, y2 = H.freeSpot(2)
        H.placeAt(x2, y2)
        Q.check(H.marks() == n1, T.L .. ": words of spaces only add nothing (as the game's)", n1 .. " -> " .. H.marks())
        pcall(function() te:setText("ZEDQA note") end)
        RT.ww()._mapActiveTool = nil
        H.traitSet("ILLITERATE", true)
        T.t1 = getTimestampMs()
        H.click("map:tool:text", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.armed() == nil and H.said(T.t1, "ContextMenu_Illiterate"), T.L .. ": illiterate, Aa is refused with the game's \"" .. H.txt("ContextMenu_Illiterate") .. "\"",
            "tool " .. tostring(H.armed()) .. ", said " .. H.list(H.saidSince(T.t1)) .. ", the game's trait " .. tostring(H.hasTrait("ILLITERATE")))
        H.click(H.toolFid("house"), T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.armed() == "house", T.L .. ": illiterate, the marks are still allowed (as the game's)", "tool " .. tostring(H.armed()))
        RT.ww()._mapActiveTool = nil
        H.traitSet("ILLITERATE", false)
    end)
    -- MP35: the pad's note (B3): the note box's stop (map:note) while the note is in hand, its A opens the pad's
    -- keyboard (ZeD.MapsTab.noteKeyboard, counted); the run types into the box as the keyboard does (setText); A on the
    -- map's cursor places those words. Edit note by the pad opens the keyboard on the note's words.
    H.step(1, function() H.noteKbOn() end)
    H.padPress(T, "map:tool:text")
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        local ids = H.stopIds()
        local iN = H.idx(ids, function(v) return v == "map:note" end)
        local iC = H.idx(ids, function(v) return v == "map:canvas:cursor" end)
        Q.check(H.armed() == "text" and iN ~= nil and iC ~= nil and iN < iC, "MP35 the pad's note (B3): with the note in hand the note box is a pad stop (map:note), before the map's cursor", "stops " .. H.list(ids, 30))
        T.k0 = S.nkN
        T.go = H.focusEl("map:note")
    end)
    H.tapA(function() return T.go and not T.off end)
    H.pause(300)
    H.step(1, function()
        if T.off or not T.go then return end
        local te = RT.ww()._mapTextEntry
        local focused, jd = false, nil
        pcall(function() focused = te:isFocused() and true or false end)
        pcall(function() jd = JoypadState.players[S.pn + 1] end)
        Q.check(S.nkN == T.k0 + 1 and (focused or jd ~= nil), "MP35 the pad's note (B3): A on the note box opens the pad's keyboard on it (ZeD.MapsTab.noteKeyboard)",
            "keyboard calls " .. (S.nkN - T.k0) .. ", the box has the keys " .. tostring(focused) .. (jd and "" or " (no pad bound: the box takes the keys in place of the on-screen keyboard)"))
        pcall(function() te:setText("ZEDQA typed by pad") end)
        pcall(function() te:unfocus() end)
        T.x, T.y = H.freeSpot(3)
        T.n0 = H.marks()
        T.go = H.cursorAt(T.x, T.y)
    end)
    H.tapA(function() return T.go and not T.off end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        local s = H.lastNew()
        local words = nil
        pcall(function() words = s:getTranslatedText() end)
        Q.check(s ~= nil and H.marks() == T.n0 + 1 and words == "ZEDQA typed by pad", "MP35 the pad's note: the words typed on the pad's keyboard go on the map with A on the cursor", "placed \"" .. tostring(words) .. "\"")
        T.sym = s
        RT.ww()._mapActiveTool = nil
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(not H.hasStop("map:note"), "MP35 the pad's note: with the note put down the box's stop is gone", "stops " .. H.list(H.stopIds(), 30))
        T.k1 = S.nkN
        T.go = T.sym ~= nil and H.cursorAt(T.x, T.y)
    end)
    -- the pad's Edit note: X on it, Edit note opens the keyboard on its words; new words typed, A puts them on it
    H.tapX(function() return T.go and not T.off end)
    H.pause(300)
    H.step(1, function()
        if T.off or not T.go then return end
        local op = H.ctxOpt(H.txt("IGUI_Map_EditNote"))
        if not op then Q.check(false, "MP35 the pad's note: X on the note opens its menu with Edit note", H.ctxNames()); T.go = false; return end
        H.ctxPick(op)
        local te = RT.ww()._mapTextEntry
        local box = nil
        pcall(function() box = te:getText() end)
        Q.check(S.nkN == T.k1 + 1 and box == "ZEDQA typed by pad", "MP35 the pad's note (B3): Edit note by the pad opens the keyboard on the note's words", "keyboard calls " .. (S.nkN - T.k1) .. ", the box \"" .. tostring(box) .. "\"")
        pcall(function() te:setText("ZEDQA edited by pad") end)
        pcall(function() te:unfocus() end)
        T.n1 = H.marks()
        T.go = H.cursorAt(T.x, T.y)
    end)
    H.tapA(function() return T.go and not T.off end)
    H.pause(300)
    H.step(1, function()
        H.padOff()
        H.noteKbOff()
        if T.off or not T.go then return end
        local words = nil
        pcall(function() words = T.sym:getTranslatedText() end)
        Q.check(words == "ZEDQA edited by pad" and H.marks() == T.n1, "MP35 the pad's note: A after Edit note puts the newly typed words on the same note", "the note reads \"" .. tostring(words) .. "\", marks " .. tostring(T.n1) .. " -> " .. H.marks())
    end)
    H.caseEnd(T.L)
end
-- the note box's keyboard counted (the stop's A and Edit note by the pad call it), the call itself the tab's own
function H.noteKbOn()
    S.nkN = S.nkN or 0
    if S.nkW or not (S.MT and S.MT.noteKeyboard) then return end
    S.nkW = S.MT.noteKeyboard
    S.nkFn = function(w, ...) S.nkN = S.nkN + 1; return S.nkW(w, ...) end
    S.MT.noteKeyboard = S.nkFn
end
function H.noteKbOff()
    if not S.nkW then return end
    if S.MT.noteKeyboard == S.nkFn then S.MT.noteKeyboard = S.nkW end
    S.nkW, S.nkFn = nil, nil
end

-- ===================================================================== MP36 the pinned marks
function H.pins() local p = H.md().ZeD_MapPinnedIcons; return type(p) == "table" and p or {} end
function H.pinned(id) for _, v in ipairs(H.pins()) do if v == id then return true end end; return false end
function H.headerTools() local o = {}; for _, z in ipairs(RT.ww()._mapToolZones or {}) do if not z.isGrid and z.id ~= "text" then o[#o + 1] = z.id end end; return o end
function C.mp36()
    local T = { L = "MP36 the pinned marks" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function() if not T.off then H.click("map:disclosure", T.L) end end)
    H.step(3, function()
        if T.off then return end
        Q.check(RT.ww()._mapToolsExpanded == true and H.zone("map:gridtool:heart") ~= nil, T.L .. ": the fold arrow opens the full set", "open " .. tostring(RT.ww()._mapToolsExpanded))
        T.was = H.pinned("heart")
        H.click("map:gridtool:heart", T.L, true)
    end)
    H.step(3, function()
        if T.off then return end
        T.after1 = H.pinned("heart")
        T.onHeader = H.zone("map:tool:heart") ~= nil
        H.click("map:gridtool:heart", T.L, true)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.after1 ~= T.was and H.pinned("heart") == T.was, T.L .. ": a right-click on a mark in the full set pins it, again unpins it (modData.ZeD_MapPinnedIcons)",
            "pinned " .. tostring(T.was) .. " -> " .. tostring(T.after1) .. " -> " .. tostring(H.pinned("heart")) .. "; on the header while pinned " .. tostring(T.onHeader))
    end)
    H.padPress(T, "map:gridtool:heart", nil, "X")
    H.pause(300)
    H.step(1, function() if not T.off then T.after2 = H.pinned("heart") end end)
    H.padPress(T, "map:gridtool:heart", nil, "X")
    H.pause(300)
    H.step(1, function()
        H.padOff()
        if T.off then return end
        Q.check(T.after2 ~= T.was and H.pinned("heart") == T.was, T.L .. " (pad): X on the mark's stop pins and unpins it", tostring(T.was) .. " -> " .. tostring(T.after2) .. " -> " .. tostring(H.pinned("heart")))
        T.full = H.headerTools()
    end)
    H.halfOn(T)
    H.step(3, function()
        if T.off then return end
        local now = H.headerTools()
        local pins = H.pins()
        local inOrder = true
        for i, id in ipairs(now) do if pins[i] ~= id then inOrder = false end end
        H.sizeCheck(T.half and #now <= #T.full and inOrder, T.L .. ": at the half card the header keeps the pins it has room for, folding from the end",
            "the drawer " .. H.drawerW() .. " px; header " .. H.list(now) .. " (full card " .. H.list(T.full) .. "); pins " .. H.list(pins))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== a mark of the run's own, and its menu
-- queue: a mark (id, or "text" for a note with words) placed at a free spot, the tool put down (T.sym, T.sx, T.sy)
function H.makeQ(T, id, spot, words)
    H.armQ(T, id)
    H.step(2, function()
        T.sym = nil
        if T.off then return end
        if id == "text" then pcall(function() RT.ww()._mapTextEntry:setText(words or "ZEDQA note") end) end
        T.sx, T.sy = H.freeSpot(spot or 1)
        T.sym = H.placeAt(T.sx, T.sy)
        RT.ww()._mapActiveTool = nil
        RT.ww()._mapEdit = nil
        if not T.sym then Q.check(false, T.L .. ": a mark is placed to stage the menu", H.tabState()) end
    end)
end
-- the mark under (x, y) is the run's own: the menu then acts on it, never on one of his
function H.hitOurs(T)
    local s = nil
    pcall(function() s = S.N.hitAt(H.mp(), T.sx, T.sy, H.px(16)) end)
    return H.sameMark(s, T.sym), s
end
-- the same mark seen through two of the game's symbol lists (the map's own and the store's give each their own
-- wrapper of one symbol): what it is, where, its color; and none of his found at the start looks like it
function H.sameMark(s, ours)
    if not (s and ours) then return false end
    local a = H.sig(s)
    if a ~= H.sig(ours) or a == "?" then return false end
    for _, g in ipairs(S.found.sigs or {}) do if g == a then return false end end
    return true
end
-- queue: a right-click on the run's mark (its menu up: T.menu)
function H.menuQ(T)
    H.step(2, function()
        T.menu = nil
        if T.off or not T.sym then return end
        local ours, s = H.hitOurs(T)
        if not ours then Q.skip(T.L, "the mark under the pointer is not the run's own (" .. tostring(s and H.sig(s)) .. "): the menu is not used"); return end
        T.c0 = H.ctxSince(0)
        H.mapRight(T.sx, T.sy)
        T.menu = H.ctxSince(0) > T.c0
    end)
end
function C.mp37()
    local T = { L = "MP37 Delete" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    for _, what in ipairs({ "text", "star" }) do
        H.makeQ(T, what, 1, "ZEDQA delete me")
        H.menuQ(T)
        H.step(2, function()
            if T.off or not T.menu then return end
            local op = H.ctxOpt(H.txt("ContextMenu_Delete"))
            T.n0 = H.marks()
            local lit = op ~= nil and not op.notAvailable
            H.ctxPick(op)
            Q.check(lit and not H.inStore(T.sym) and H.marks() == T.n0 - 1, T.L .. " (" .. (what == "text" and "a note" or "a symbol") .. "): with an eraser, Delete takes the mark off the game's store",
                "the option " .. H.ctxNames() .. "; marks " .. tostring(T.n0) .. " -> " .. H.marks() .. ", still there " .. tostring(H.inStore(T.sym)))
        end)
    end
    -- no eraser: greyed with the game's reason, and a press says it
    H.step(2, function() if not T.off then H.kit({ Pencil = true }) end end)
    H.makeQ(T, "star", 2)
    H.menuQ(T)
    H.step(2, function()
        if T.off or not T.menu then return end
        local op = H.ctxOpt(H.txt("ContextMenu_Delete"))
        local tip = op and H.optTip(op)
        T.t1 = getTimestampMs()
        H.ctxPick(op)
        Q.check(op ~= nil and op.notAvailable == true and tip == H.txt("Tooltip_Map_CantErase") and H.inStore(T.sym) and H.said(T.t1, "Tooltip_Map_CantErase"),
            T.L .. ": without an eraser Delete is greyed with the game's \"" .. H.txt("Tooltip_Map_CantErase") .. "\", a press says it and the mark stays",
            "greyed " .. tostring(op and op.notAvailable) .. ", tip \"" .. tostring(tip) .. "\", still there " .. tostring(H.inStore(T.sym)) .. ", said " .. H.list(H.saidSince(T.t1)) .. ", the game's canErase " .. tostring(H.gameCanErase()))
        H.fullKit()
    end)
    -- the pad: X on the cursor over the mark, Delete
    H.makeQ(T, "skull", 3)
    H.step(2, function()
        if T.off or not T.sym then return end
        T.n0 = H.marks()
        T.go = H.cursorAt(T.sx, T.sy)
        T.c0 = H.ctxSince(0)
    end)
    H.tapX(function() return T.go and not T.off end)
    H.pause(300)
    H.step(1, function()
        H.padOff()
        if T.off or not T.go then return end
        local op = H.ctxOpt(H.txt("ContextMenu_Delete"))
        Q.check(H.ctxSince(0) > T.c0 and op ~= nil, T.L .. " (pad): X with the map's cursor on a mark opens its menu", H.ctxNames())
        if op and H.hitOurs(T) then H.ctxPick(op) end
        Q.check(not H.inStore(T.sym), T.L .. " (pad): its Delete takes the mark off", "still there " .. tostring(H.inStore(T.sym)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP38 Change color (B10)
function C.mp38()
    local T = { L = "MP38 Change color" }
    H.step(2, function() H.caseStart(T); H.kit({ Pencil = true, RedPen = true, Eraser = true }) end)
    H.tabQ(T)
    H.step(2, function() if not T.off then RT.ww()._mapActiveColor = 1 end end)
    H.makeQ(T, "star", 1)
    H.menuQ(T)
    H.step(2, function()
        if T.off or not T.menu then return end
        local op = H.ctxOpt(H.tr("UI_ZeD_Map_ChangeColor"))
        local was = H.inkName(T.sym)
        H.ctxPick(op)
        Q.check(op ~= nil and not op.notAvailable and H.inkIs(T.sym, 4), T.L .. ": with a pencil, a red pen and an eraser, a pencil mark steps to the red pen's color",
            "the option " .. H.ctxNames() .. "; " .. was .. " -> " .. H.inkName(T.sym))
        H.kit({ Pencil = true, Eraser = true })
    end)
    H.makeQ(T, "cross", 2)
    H.menuQ(T)
    H.step(2, function()
        if T.off or not T.menu then return end
        local op = H.ctxOpt(H.tr("UI_ZeD_Map_ChangeColor"))
        local r0, g0, b0 = H.rgbOf(T.sym)
        H.ctxPick(op)
        local r1, g1, b1 = H.rgbOf(T.sym)
        local changed = math.abs(r1 - r0) + math.abs(g1 - g0) + math.abs(b1 - b0) > 0.01
        Q.check(changed or (op ~= nil and op.notAvailable == true), T.L .. " (B10): with one pen, Change color either changes the color or is greyed",
            "the option " .. H.ctxNames() .. "; the color " .. H.n3(r0) .. "," .. H.n3(g0) .. "," .. H.n3(b0) .. " -> " .. H.n3(r1) .. "," .. H.n3(g1) .. "," .. H.n3(b1) .. " (the menu still plays MapAddSymbol: MapsTab)")
        H.fullKit()
        H.traitSet("ILLITERATE", true)
    end)
    H.makeQ(T, "x", 3)
    H.menuQ(T)
    H.step(2, function()
        if T.off or not T.menu then return end
        local op = H.ctxOpt(H.tr("UI_ZeD_Map_ChangeColor"))
        local tip = op and H.optTip(op)
        Q.check(op ~= nil and op.notAvailable == true and tip == H.txt("ContextMenu_Illiterate"), T.L .. ": illiterate, Change color is greyed with the game's \"" .. H.txt("ContextMenu_Illiterate") .. "\"",
            "greyed " .. tostring(op and op.notAvailable) .. ", tip \"" .. tostring(tip) .. "\"")
        H.ctxShut()
        H.traitSet("ILLITERATE", false)
    end)
    H.step(1, function() Q.skip(T.L .. ": the change sent to the server (sendModifySymbol)", "multiplayer") end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP39 Edit note
function C.mp39()
    local T = { L = "MP39 Edit note" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.makeQ(T, "text", 1, "ZEDQA edit one")
    H.menuQ(T)
    H.step(2, function()
        if T.off or not T.menu then return end
        local op = H.ctxOpt(H.txt("IGUI_Map_EditNote"))
        H.ctxPick(op)
        local te = RT.ww()._mapTextEntry
        local box = nil
        pcall(function() box = te:getText() end)
        Q.check(op ~= nil and H.armed() == "text" and RT.ww()._mapEdit ~= nil and box == "ZEDQA edit one", T.L .. ": Edit note fills the note box with its words and picks up the note",
            "the option " .. H.ctxNames() .. "; box \"" .. tostring(box) .. "\", tool " .. tostring(H.armed()))
        pcall(function() te:setText("ZEDQA edit two") end)
        T.n0 = H.marks()
        local x, y = H.freeSpot(4)
        H.mapClick(x, y)
        local words = nil
        pcall(function() words = T.sym:getTranslatedText() end)
        Q.check(words == "ZEDQA edit two" and H.marks() == T.n0 and H.armed() == nil, T.L .. ": the next click puts the new words on the same note and puts the tool down",
            "the note \"" .. tostring(words) .. "\", marks " .. tostring(T.n0) .. " -> " .. H.marks() .. ", tool " .. tostring(H.armed()))
        H.kit({ Pencil = true })
    end)
    H.menuQ(T)
    H.step(2, function()
        if T.off or not T.menu then return end
        local op = H.ctxOpt(H.txt("IGUI_Map_EditNote"))
        local tip = op and H.optTip(op)
        Q.check(op ~= nil and op.notAvailable == true and tip == H.txt("Tooltip_Map_CantEdit"), T.L .. ": without an eraser Edit note is greyed with the game's \"" .. H.txt("Tooltip_Map_CantEdit") .. "\"",
            "greyed " .. tostring(op and op.notAvailable) .. ", tip \"" .. tostring(tip) .. "\"")
        H.ctxShut()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP40 the hit test
function C.mp40()
    local T = { L = "MP40 the hit test" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.armQ(T, "star")
    H.step(2, function()
        if T.off then return end
        local x, y = H.freeSpot(1)
        T.a = H.placeAt(x, y)
        T.b = H.placeAt(x + H.px(10), y)
        T.x, T.y = x, y
        RT.ww()._mapActiveTool = nil
        local hit = nil
        pcall(function() hit = S.N.hitAt(H.mp(), x + H.px(5), y, H.px(16)) end)
        T.c0 = H.ctxSince(0)
        local isA, isB = H.sameMark(hit, T.a), H.sameMark(hit, T.b)
        if isA or isB then H.mapRight(x + H.px(5), y) end
        Q.check((isA or isB) and H.ctxSince(0) > T.c0, T.L .. ": a right-click between two marks 10 px apart opens the menu for one of them",
            "the engine's hit or the nearest within 16 px: " .. (isA and "the left one" or (isB and "the right one" or tostring(hit and H.sig(hit)))))
        H.ctxShut()
    end)
    -- a town's name (one of the map's own labels) never opens the menu
    H.step(2, function()
        if T.off then return end
        local best, bd = nil, -1
        local hx, hy = S.p:getX(), S.p:getY()
        for _, t in ipairs((ZeD.MapsSurveyData or {}).towns or {}) do
            local d = (t.x - hx) * (t.x - hx) + (t.y - hy) * (t.y - hy)
            if bd < 0 or d < bd then best, bd = t, d end
        end
        T.town = best
        if not best then return end
        pcall(function() H.api():centerOn(best.x, best.y) end)
        pcall(function() H.api():setZoom(12) end)
    end)
    H.pause(300)
    H.step(1, function()
        if T.off or not T.town then return end
        local sx, sy = H.toUI(T.town.x, T.town.y)
        local mine = nil
        pcall(function() mine = S.N.hitAt(H.mp(), sx, sy, H.px(16)) end)
        T.c1 = H.ctxSince(0)
        if not mine then H.mapRight(sx, sy) end
        Q.check(mine == nil and H.ctxSince(0) == T.c1, T.L .. ": a right-click on a town's name (" .. tostring(T.town.key) .. ") opens no menu", "a mark of his there " .. tostring(mine and H.sig(mine)) .. ", menus " .. (H.ctxSince(0) - T.c1))
        H.ctxShut()
        pcall(function() H.api():centerOn(S.p:getX(), S.p:getY()) end)
        pcall(function() H.api():setZoom(18) end)
    end)
    -- the pad: X with the cursor 15 px off a mark
    H.step(3, function()
        if T.off then return end
        local sx, sy = H.symUI(T.a)
        T.go = sx ~= nil and H.cursorAt(sx - H.px(15), sy)
        T.c2 = H.ctxSince(0)
    end)
    H.tapX(function() return T.go and not T.off end)
    H.pause(300)
    H.step(1, function()
        H.padOff()
        if T.off or not T.go then return end
        Q.check(H.ctxSince(0) > T.c2, T.L .. " (pad): X with the cursor 15 px off a mark opens its menu (16 px reach)", "menus " .. (H.ctxSince(0) - T.c2) .. ": " .. H.ctxNames())
        H.ctxShut()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP42 the old marks carried over
function C.mp42()
    local T = { L = "MP42 the old marks carried over" }
    H.step(2, function()
        H.caseStart(T)
        local md = H.md()
        local hx, hy = math.floor(S.p:getX()) + 40.5, math.floor(S.p:getY()) + 40.5
        T.hx, T.hy = hx, hy
        md.ZeD_MapAnnotations = { { iconId = "star", worldX = hx, worldY = hy, text = "ZEDQA old star", colorIdx = 4 },
                                  { iconId = "text", worldX = hx + 6, worldY = hy, text = "ZEDQA old note", colorIdx = 1 } }
        md.ZeD_MapNotesMoved = nil
        S.back.ann = true
        local n0 = H.marks()
        local added = 0
        pcall(function() added = S.N.migrate(S.p) end)
        local star, words, note = nil, nil, nil
        for _, s in ipairs(H.newSyms()) do
            pcall(function()
                if s:isTexture() and s:getSymbolID() == "Star" and math.abs(s:getWorldX() - hx) < 0.5 then star = s end
                if s:isText() and s:getTranslatedText() == "ZEDQA old star" and math.abs(s:getWorldY() - (hy - 3)) < 0.5 then words = s end
                if s:isText() and s:getTranslatedText() == "ZEDQA old note" then note = s end
            end)
        end
        Q.check(added == 3 and H.marks() == n0 + 3 and star ~= nil and H.inkIs(star, 4) and words ~= nil and note ~= nil and md.ZeD_MapNotesMoved == true,
            T.L .. ": an old ZeD_MapAnnotations list goes into the game's store once: the star (red), its words as a note 3 squares above, the text note; ZeD_MapNotesMoved set",
            "added " .. tostring(added) .. ", marks " .. n0 .. " -> " .. H.marks() .. ", star " .. tostring(star and H.sig(star)) .. ", its words " .. tostring(words ~= nil) .. ", the note " .. tostring(note ~= nil)
            .. ", moved " .. tostring(md.ZeD_MapNotesMoved))
        local again = -1
        pcall(function() again = S.N.migrate(S.p) end)
        md.ZeD_MapNotesMoved = nil
        local third = -1
        pcall(function() third = S.N.migrate(S.p) end)
        Q.check(again == 0 and third == 0 and H.marks() == n0 + 3, T.L .. ": a second carry adds nothing, nor one with the done mark lost (the duplicate guard)", "second " .. again .. ", third " .. third .. ", marks " .. H.marks())
        H.note(T.L .. ": a real load runs the same carry (MapNotes: OnGameStart, OnCreatePlayer); the run calls it, it does not load a game")
        local f = S.found.md
        md.ZeD_MapAnnotations = f.ann
        md.ZeD_MapNotesMoved = f.moved
        S.back.ann = nil
    end)
    H.caseEnd(T.L)
    H.skipCase("MP43 sharing", "multiplayer: a server, his own mark's Sharing card and another player's shared mark")
    H.skipCase("MP44 deleting a shared mark", "multiplayer: the server's sendRemoveSymbol")
    H.skipCase("MP45 a mark shared with him", "multiplayer: another player shares a mark")
end

-- ===================================================================== MP46 unfolding and folding
-- queue: folded by `how`; then the focus (for the pad's ways) and the drawer's own map back with its view
function C.foldLeg(T, how)
    local L = T.L .. " (fold: " .. how .. ")"
    local st = {}
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        st.go = true
        if how == "the placeholder, clicked" then H.click("map:fold", L)
        elseif how == "the button" then H.click("map:popout", L)
        elseif how == "Escape" then st.took = ZeD.EscapeTakers.mapPopout()
        elseif how == "the close box" then local pop = H.pop(); H.zcall(function() pop:close() end)
        elseif how == "A on the placeholder" then
            H.padOn()
            pcall(S.F.claimFocus, RT.ww())
            st.f = false
            pcall(function() st.f = S.F.focusWhere(RT.ww(), "worldTabContent", function(el) return el.id == "map:fold" end) ~= nil end)
        elseif how == "B" then H.padOn(); st.f = H.focusEl("map:canvas:cursor")
        elseif how == "A on the button" then H.padOn(); st.f = H.focusEl("map:popout") end
    end)
    if how == "A on the placeholder" then
        H.step(1, function() if st.f then RT.pad("A", true); RT.padDown(Joypad.AButton, RT.ww()) end end)
        H.step(4, function() if st.f then RT.pad("A", false) end end)
        H.step(4, function() if st.f then RT.pad("A", nil) end end)
    elseif how == "B" then H.tapB(function() return st.f end)
    elseif how == "A on the button" then H.tapA(function() return st.f end) end
    H.wait(2000, function() return T.off or H.pop() == nil end, function(ok)
        if T.off then return end
        local x, y = H.cxy()
        local same = H.mp() == T.drawer
        Q.check(ok and same and x ~= nil and math.abs(x - T.dx) < 0.5 and math.abs(y - T.dy) < 0.5, L .. ": it folds and the drawer's own map is back with its view",
            "unfolded " .. tostring(H.pop() ~= nil) .. ", the same map " .. tostring(same) .. ", center " .. H.n1(x) .. "," .. H.n1(y) .. " (was " .. H.n1(T.dx) .. "," .. H.n1(T.dy) .. ")"
            .. (st.f ~= nil and (", the pad on its stop " .. tostring(st.f)) or "") .. (st.took ~= nil and (", Escape taken " .. tostring(st.took)) or ""))
    end)
    if how == "A on the button" or how == "A on the placeholder" or how == "B" then
        H.pause(400)
        H.step(1, function()
            if T.off then return end
            if how == "B" then
                H.note(L .. ": B folds the map from the unfolded window; with the World window open before, it stays, and the focus goes to " .. tostring(H.focusedId()))
            else
                Q.check(H.focusedId() == "map:popout", L .. ": the pad's focus lands back on the unfold button", "focus " .. tostring(H.focusedId()))
            end
            H.padOff()
        end)
    end
end
function C.mp46()
    local T = { L = "MP46 unfolding and folding" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        T.drawer = H.mp()
        T.dx, T.dy = H.cxy()
        T.big = math.floor(H.screen() * 0.72)
    end)
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        local pop = H.pop()
        local pw = 0
        pcall(function() pw = pop:getWidth() end)
        local title = nil
        pcall(function() title = pop.title end)
        Q.check(H.mp() ~= T.drawer and pw >= math.min(T.big, H.px(600)) - 1, T.L .. ": the unfolded window is its own map, 72% of the screen wide (at least 600 units)",
            "width " .. pw .. " (72% " .. T.big .. "), title " .. tostring(title))
        local w = RT.ww()
        Q.check(w._worldMapPanelInline == T.drawer and not H.vis(T.drawer), T.L .. ": the drawer's map waits off the screen", "parked " .. tostring(w._worldMapPanelInline == T.drawer) .. ", seen " .. tostring(H.vis(T.drawer)))
        H.click("map:popout", T.L)
    end)
    H.wait(2000, function() return T.off or H.pop() == nil end, function() end)
    for _, how in ipairs({ "the placeholder, clicked", "A on the placeholder", "B", "Escape", "the close box", "the button", "A on the button" }) do C.foldLeg(T, how) end
    -- unfolded by the pad
    H.padPress(T, "map:popout")
    H.wait(3000, function() return T.off or H.popUp() end, function(ok)
        H.padOff()
        if T.off then return end
        Q.check(ok, T.L .. " (pad): A on the unfold button unfolds the map", H.tabState())
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP47 Escape with the note box focused
function C.mp47()
    local T = { L = "MP47 Escape in the note box" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.unfoldQ(T)
    H.armQ(T, "text")
    H.step(2, function()
        if T.off then return end
        local te = RT.ww()._mapTextEntry
        pcall(function() te:setText("ZEDQA kept words") end)
        pcall(function() te:focus() end)
        T.focused = false
        pcall(function() T.focused = te:isFocused() and true or false end)
    end)
    H.step(2, function()
        if T.off then return end
        T.took = ZeD.EscapeTakers.mapPopout()
    end)
    H.step(3, function()
        if T.off then return end
        local te = RT.ww()._mapTextEntry
        local words = nil
        pcall(function() words = te:getText() end)
        if not T.focused then Q.skip(T.L, "the note box would not take the keyboard here (no focus)")
        else Q.check(not T.took and H.pop() ~= nil and words == "ZEDQA kept words", T.L .. ": Escape with the note box focused leaves the window and the words", "Escape taken " .. tostring(T.took) .. ", unfolded " .. tostring(H.pop() ~= nil) .. ", the words \"" .. tostring(words) .. "\"") end
        pcall(function() te:unfocus() end)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP48 unfolded, the World window on another tab (B9)
function C.mp48()
    local T = { L = "MP48 unfolded, another tab" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        T.big = H.mp()
        RT.worldTab("loot")
        T.hid, T.n = 0, 0
    end)
    H.wait(1500, function()
        if T.off then return true end
        T.n = T.n + 1
        if not H.vis(T.big) then T.hid = T.hid + 1 end
        return false
    end, function()
        if T.off then return end
        Q.check(T.hid == 0, T.L .. " (B9): with the World window on Loot the unfolded map keeps drawing (the pad's cursor needs it seen)", T.hid .. " of " .. T.n .. " frames the map was not seen; on " .. tostring(RT.ww()._activeTab))
        RT.worldTab("maps")
    end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        T.z0 = H.zoom()
        local dr = RT.ww()._drawerPanel
        H.zcall(function() dr:onMouseWheel(-1) end)
    end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        local z = H.zoom()
        local ret = nil
        local dr = RT.ww()._drawerPanel
        pcall(function() ret = dr:onMouseWheel(-1) end)
        local z2 = H.zoom()
        Q.check(z ~= nil and T.z0 ~= nil and math.abs(z - T.z0) < 0.01 and math.abs((z2 or 0) - z) < 0.01 and ret == true, T.L .. " (B9): unfolded, the drawer takes the wheel over its placeholder and zooms nothing",
            "the unfolded map's zoom " .. H.n2(T.z0) .. " -> " .. H.n2(z) .. " -> " .. H.n2(z2) .. ", the wheel taken " .. tostring(ret))
        H.click("map:popout", T.L)
    end)
    -- folded, the drawer's wheel zooms the drawer's map as before
    H.wait(2000, function() return T.off or (H.pop() == nil and H.mapUp()) end, function(ok)
        if T.off then return end
        T.z1 = H.zoom()
        local dr = RT.ww()._drawerPanel
        H.zcall(function() dr:onMouseWheel(-1) end)
    end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        local z = H.zoom()
        Q.check(H.pop() == nil and z ~= nil and T.z1 ~= nil and z > T.z1, T.L .. ": folded, the drawer's wheel zooms the drawer's map", H.n2(T.z1) .. " -> " .. H.n2(z))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP49 the World window shut with the map unfolded
function C.mp49()
    local T = { L = "MP49 the World window shut while unfolded" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        T.pop = H.pop()
        pcall(ZeD_WorldWindow.close, S.pn)
    end)
    H.step(4, function()
        if T.off then return end
        local inUI = false
        pcall(function() local ui = UIManager.getUI(); for i = 0, ui:size() - 1 do if ui:get(i) == T.pop.javaObject then inUI = true end end end)
        Q.check(not H.wwOpen() and not H.vis(T.pop) and not inUI, T.L .. ": the unfolded map folds with the World window, nothing left on the screen", "World open " .. tostring(H.wwOpen()) .. ", the map's window seen " .. tostring(H.vis(T.pop)) .. ", in the UI " .. tostring(inUI))
        RT.pairOpen()
        pcall(ZeD_WorldWindow.open, S.pn)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP50 the unfolded window's sizes
function C.sizeLeg(T, label, fn)
    H.step(2, function() if not T.off then H.zcall(fn) end end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        local pop = H.pop()
        local mp = H.mp()
        local cw, ch, mx, my, mw, mh, pw, ph = 0, 0, 0, 0, 0, 0, 0, 0
        pcall(function()
            local c = pop._contentPanel
            cw, ch = c:getWidth(), c:getHeight()
            mx, my, mw, mh = mp:getX(), mp:getY(), mp:getWidth(), mp:getHeight()
            pw, ph = pop:getWidth(), pop:getBodyHeight()
        end)
        local band = H.zone("map:style:survey") or H.zone("map:style:menu")
        local bandIn = band == nil or (band.y + band.h <= ch + 1 and band.x + band.w <= cw + 1)
        Q.check(mw > 0 and mh > 0 and mx + mw <= cw + 1 and my + mh <= ch + 1 and math.abs(cw - pw) <= 1 and bandIn, T.L .. " (" .. label .. "): the map and the band follow the window",
            "window " .. math.floor(pw) .. "x" .. math.floor(ph) .. ", body " .. math.floor(cw) .. "x" .. math.floor(ch) .. ", map " .. math.floor(mx) .. "," .. math.floor(my) .. " " .. math.floor(mw) .. "x" .. math.floor(mh)
            .. ", band inside " .. tostring(bandIn))
    end)
end
function C.mp50()
    local T = { L = "MP50 the unfolded window's sizes" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.unfoldQ(T)
    C.sizeLeg(T, "its 600 by 400 minimum", function() local p = H.pop(); p:setWidth(p.minimumWidth or H.px(600)); p:setHeight(p.minimumHeight or H.px(400)) end)
    C.sizeLeg(T, "the full screen", function() local p = H.pop(); local sw, sh = H.screen(); p:setX(0); p:setY(0); p:setWidth(sw); p:setHeight(sh) end)
    H.step(1, function() if not T.off then H.note(T.L .. ": the side list docks only while an extension fills it (MP62 measures it docked)") end end)
    H.caseEnd(T.L)
    H.skipCase("MP51 death with the map unfolded", "the run's character must live: a death ends the run (PaperMap and the World window's close fold it in code: P.stillHeld, isDead)")
end

-- ===================================================================== paper maps
function H.paperItem() local w = RT.ww(); return w and w._mapPopout and w._mapPaperItem or nil end
function H.paperUp(item) return H.popUp() and H.paperItem() ~= nil and (item == nil or H.paperItem() == item or H.ft(H.paperItem()) == H.ft(item)) end
function H.readMap(item) H.zcall(function() ISInventoryPaneContextMenu.onCheckMap(item, S.pn) end) end
-- the game's own paper map windows counted (ISMapWrapper, ISMap made), kept to be shut
function H.gameWinWatch(on)
    if on and not S.gwW then
        S.gwW = { map = ISMap and ISMap.new, wrap = ISMapWrapper and ISMapWrapper.new }
        S.gameWinN = 0
        if S.gwW.wrap then
            ISMapWrapper.new = function(...)
                local o = S.gwW.wrap(...)
                S.gameWinN = S.gameWinN + 1
                S.gameWins = S.gameWins or {}
                S.gameWins[#S.gameWins + 1] = o
                return o
            end
        end
    elseif not on and S.gwW then
        if S.gwW.wrap then ISMapWrapper.new = S.gwW.wrap end
        S.gwW = nil
    end
end
-- a town map to read: one he has read before when there is one (the game keeps no way to unread one)
function H.townMap()
    local first, firstFt = nil, nil
    for _, ft in ipairs(S.TOWN_MAPS) do
        if H.known(ft) then
            local it = H.give(ft)
            local read = false
            pcall(function() read = S.p:hasReadMap(it) and true or false end)
            if read then
                if first then H.removeItem(first) end
                return it, true
            end
            if first then H.removeItem(it) else first, firstFt = it, ft end
        end
    end
    return first, false
end
function H.paperBounds()
    local b = nil
    pcall(function() local a = H.api(); b = { x1 = a:getMinXInSquares(), y1 = a:getMinYInSquares(), x2 = a:getMaxXInSquares(), y2 = a:getMaxYInSquares() } end)
    return b
end
function H.paperSyms() local api = nil; pcall(function() api = S.N.panelAPI(H.mp()) end); return #H.userSyms(api), api end

-- ===================================================================== MP52 Read Map (B1)
function C.mp52()
    local T = { L = "MP52 Read Map" }
    H.step(2, function()
        H.caseStart(T)
        H.gameWinWatch(true)
        RT.pairOpen()
        T.item, T.wasRead = H.townMap()
        if not T.item then T.off = true; Q.skip(T.L, "no town map is known to this game"); return end
        if not T.wasRead then H.note(T.L .. ": he has read no town map before: " .. H.ft(T.item) .. " is now read (the game keeps no way to unread a map; its area is held back by the run)") end
        -- B1, the game's side: what its own Read Map queues (its onCheckMap with the queue's add held, nothing run)
        local held = {}
        local add = ISTimedActionQueue.add
        ISTimedActionQueue.add = function(a) held[#held + 1] = tostring(a and a.Type) end
        pcall(function() ISInventoryPaneContextMenu._zedOrigCheckMap(T.item, S.pn) end)
        ISTimedActionQueue.add = add
        T.gameQ = H.list(held)
        T.gameReads = false
        for _, k in ipairs(held) do if k == "ISReadMapItem" then T.gameReads = true end end
        H.qstop()
        S.reveals = {}
        T.t0 = getTimestampMs()
        T.wins0 = S.gameWinN
        -- (the read action at its own length for this leg: the instant-actions cheat off, put back after)
        H.instant(false)
        H.readMap(T.item)
        T.zq = H.qkinds()
        local a = H.qfirst("ISReadMapItem")
        T.dur = nil
        if a then pcall(function() T.dur = a:getDuration() end); if T.dur == nil then T.dur = a.maxTime end end
        T.upAtOnce = H.paperUp(T.item)
        T.early, T.actSeen, T.actGoneAt = false, a ~= nil, nil
    end)
    -- each frame until the paper is up: the window never before the action has ended
    H.wait(8000, function()
        if T.off then return true end
        local inQ = H.qcount("ISReadMapItem") > 0
        if inQ then T.actSeen = true elseif T.actSeen and not T.actGoneAt then T.actGoneAt = getTimestampMs() end
        local up = H.paperUp(T.item)
        if up and inQ then T.early = true end
        return up
    end, function(ok)
        H.instant(true)
        if T.off then return end
        T.tUp = getTimestampMs()
        local pop = H.pop()
        local title = nil
        pcall(function() title = pop.title end)
        local name = nil
        pcall(function() name = T.item:getName() end)
        Q.check(ok and title == name and S.gameWinN == T.wins0, T.L .. ": Read Map on a town map opens ZeD's window on the paper, titled with its name, no game window",
            "title \"" .. tostring(title) .. "\" (the map \"" .. tostring(name) .. "\"), the game's windows made " .. (S.gameWinN - T.wins0) .. "; " .. H.tabState())
        local read = nil
        pcall(function() read = S.p:hasReadMap(T.item) and true or false end)
        Q.check(not T.gameReads or (string.find(T.zq, "ISReadMapItem", 1, true) ~= nil and not T.upAtOnce and not T.early and ok and (T.dur == nil or T.dur >= 20)),
            T.L .. " (B1): Read Map runs the game's own read action whole (ISReadMapItem, about 30 ticks), and ZeD's window opens only at its end",
            "the game's Read Map queues: " .. T.gameQ .. "; queued: " .. tostring(T.zq) .. ", its length " .. tostring(T.dur) .. " ticks; the window up at once " .. tostring(T.upAtOnce)
            .. ", up while the action ran " .. tostring(T.early) .. ", up " .. (T.tUp - T.t0) .. " ms after Read Map; the game marks the map read " .. tostring(read))
    end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        local mp = H.mp()
        local b = H.paperBounds()
        local r = S.reveals[#S.reveals]
        Q.check(r ~= nil and b ~= nil and r.x1 == b.x1 and r.y1 == b.y1 and r.x2 == b.x2 and r.y2 == b.y2, T.L .. ": the paper's area is asked to be known on the world map (the game's MapUtils.revealKnownArea, held back by the run)",
            "asked " .. (r and (r.x1 .. "," .. r.y1 .. " to " .. r.x2 .. "," .. r.y2) or "nothing") .. "; the paper " .. (b and (b.x1 .. "," .. b.y1 .. " to " .. b.x2 .. "," .. b.y2) or "?"))
        local n = H.paperSyms()
        Q.check(mp ~= nil and mp._paperItem == T.item and mp._paperViewSet == true, T.L .. ": the map is bound to the paper and shows the whole paper once",
            "bound " .. tostring(mp and mp._paperItem == T.item) .. ", the whole paper set " .. tostring(mp and mp._paperViewSet) .. ", the paper's own marks " .. n)
        local styles = H.zone("map:style:survey") or H.zone("map:style:menu") or H.zone("map:style:light")
        local ext = {}
        for _, z in ipairs(RT.ww()._mapExtZones or {}) do if z.band then ext[#ext + 1] = z.id end end
        for _, z in ipairs(RT.ww()._mapExtZones or {}) do if string.sub(tostring(z.id), 1, 8) == "map:ext:" and not z.band then ext[#ext + 1] = z.id end end
        local onlyPaper = true
        for _, id in ipairs(H.zoneIds()) do if string.sub(id, 1, 8) == "map:ext:" and id ~= "map:ext:key" and id ~= "map:ext:paperfind" then onlyPaper = false end end
        Q.check(styles == nil and onlyPaper and #(mp._flyerPins or {}) == 0, T.L .. ": no styles, no Light map, no flyer pins; only the paper's extensions (Key, Find)",
            "zones " .. H.list(H.zoneIds(), 20) .. "; pins " .. #(mp._flyerPins or {}))
        H.click("map:ext:key", T.L)
    end)
    H.pause(400)
    H.shot("mz_paper_" .. H.sizeTag(), "a town map read from the inventory in ZeD's window, its key open on the game's eight building uses (MP52, MP26)", function() return not T.off end)
    H.step(1, function()
        if T.off then return end
        Q.check(RT.ww()._mapKeyOpen == true and H.zone("map:key:page:colors") == nil, T.L .. ": the paper's key is the game's eight building uses (no Survey pages)", "open " .. tostring(RT.ww()._mapKeyOpen) .. "; " .. H.list(H.zoneIds(), 20))
        RT.ww()._mapKeyOpen = false
    end)
    H.step(2, function() H.gameWinWatch(false) end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP53 Read Map on a map in a bag, and on the floor
function C.mp53leg(T, where)
    local L = T.L .. " (" .. where .. ")"
    H.step(2, function()
        T.leg, T.staged = nil, nil
        if T.off then return end
        H.legClean()
        H.qstop()
        local ft = nil
        for _, f in ipairs(S.TOWN_MAPS) do if not ft and H.known(f) then ft = f end end
        if not ft then Q.skip(L, "no town map is known to this game"); return end
        if where == "a backpack" then
            local bag = H.give(H.known("Base.Bag_Schoolbag") and "Base.Bag_Schoolbag" or "Base.Bag_DuffelBag")
            local inv = nil
            pcall(function() inv = bag:getInventory() end)
            if not inv then Q.skip(L, "no bag to put it in"); return end
            T.it = H.giveTo(inv, ft)
        else
            T.it = H.give(ft)
            local sq = S.p:getCurrentSquare()
            pcall(function() H.inv():Remove(T.it) end)
            pcall(function() sq:AddWorldInventoryItem(T.it, 0.5, 0.5, 0) end)
            -- (a map lying on the floor has a container only once the loot lists list the floor: as a player sees it)
            pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
            pcall(function() triggerEvent("OnContainerUpdate") end)
            pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
        end
        T.staged = true
    end)
    H.wait(2500, function() return T.off or not T.staged or H.where(T.it) ~= nil end, function(ok)
        if T.off or not T.staged then return end
        T.staged = nil
        if not ok then Q.skip(L, "the map on the floor has no container the game's transfer can take it from (item:getContainer() nil after the loot lists refreshed)"); return end
        local must = false
        pcall(function() must = luautils.haveToBeTransfered(S.p, T.it, true) and true or false end)
        T.must = must
        T.leg = true
        H.readMap(T.it)
        T.q = H.qkinds()
    end)
    H.wait(6000, function() return T.off or not T.leg or H.paperUp(nil) end, function(ok)
        if T.off or not T.leg then return end
        Q.check(ok and T.must and (string.find(T.q, "Transfer", 1, true) ~= nil), L .. ": the game's transfer first (luautils.haveToBeTransfered), then ZeD's paper window",
            "the game says transfer " .. tostring(T.must) .. ", queued right after " .. tostring(T.q) .. "; the paper up " .. tostring(ok) .. " (" .. H.ft(H.paperItem()) .. ")")
    end)
end
function C.mp53()
    local T = { L = "MP53 Read Map from a bag and the floor" }
    H.step(2, function() H.caseStart(T); RT.pairOpen() end)
    C.mp53leg(T, "a backpack")
    C.mp53leg(T, "the floor")
    H.caseEnd(T.L)
end

-- ===================================================================== MP54 marks on a paper (B2)
function C.mp54()
    local T = { L = "MP54 marks on a paper" }
    H.step(2, function()
        H.caseStart(T)
        RT.pairOpen()
        T.item = H.townMap()
        if not T.item then T.off = true; Q.skip(T.L, "no town map is known"); return end
        H.readMap(T.item)
    end)
    H.wait(3000, function() return T.off or H.paperUp(T.item) end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, T.L .. ": the paper opens", H.tabState()) end
        T.world0 = H.marks()
        T.n0 = H.paperSyms()
    end)
    H.armQ(T, "star")
    H.step(2, function()
        if T.off then return end
        local x, y = H.freeSpot(1)
        H.mapClick(x, y)
        local n1 = H.paperSyms()
        Q.check(n1 == T.n0 + 1 and H.marks() == T.world0, T.L .. ": a mark goes on the paper's own symbols, the world map's store unchanged", "paper " .. T.n0 .. " -> " .. n1 .. ", world " .. T.world0 .. " -> " .. H.marks())
        RT.ww()._mapActiveTool = nil
        H.click("map:popout", T.L)
    end)
    H.wait(2000, function() return T.off or H.pop() == nil end, function() if not T.off then H.readMap(T.item) end end)
    H.wait(3000, function() return T.off or H.paperUp(T.item) end, function(ok)
        if T.off then return end
        local n = H.paperSyms()
        Q.check(ok and n == T.n0 + 1, T.L .. ": put away and read again, the mark is still on the paper", "the paper's marks " .. n .. " (was " .. T.n0 .. " before the mark)")
        Q.skip(T.L .. " (B2): the paper's marks reach the server and the next reader (syncItemFields)", "multiplayer: a server and a second player read the dropped paper")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP55 the paper put away
function C.mp55leg(T, how, shutBefore)
    local L = T.L .. " (" .. how .. ", the World window " .. (shutBefore and "shut" or "open") .. " before)"
    H.step(2, function()
        T.leg = nil
        if T.off then return end
        H.legClean()
        if shutBefore then RT.pairShut(); pcall(ZeD_WorldWindow.close, S.pn) else RT.pairOpen() end
    end)
    H.step(4, function()
        if T.off then return end
        T.item = H.townMap()
        T.before = H.wwOpen()
        T.bag = (how == "into a bag") and H.give("Base.Bag_Schoolbag") or nil
        H.readMap(T.item)
    end)
    H.wait(3000, function() return T.off or H.paperUp(T.item) end, function(ok)
        if T.off then return end
        if not ok then Q.check(false, L .. ": the paper opens", H.tabState()); return end
        T.leg = true
        if how == "dropped" then
            pcall(function() H.inv():Remove(T.item) end)
            pcall(function() S.p:getCurrentSquare():AddWorldInventoryItem(T.item, 0.5, 0.5, 0) end)
        else
            pcall(function() H.inv():Remove(T.item); T.bag:getInventory():AddItem(T.item) end)
        end
    end)
    H.wait(1500, function() return T.off or not T.leg or H.pop() == nil end, function(ok)
        if T.off or not T.leg then return end
        -- the game's own rule for its paper window (ISMap:update): open while his inventory contains(map, true)
        local keeps = false
        pcall(function() keeps = H.inv():contains(T.item, true) and true or false end)
        local where = "?"
        pcall(function() where = tostring(H.where(T.item) and H.where(T.item):getType()) end)
        Q.check((ok ~= keeps) and (keeps or H.wwOpen() == T.before), L .. ": the paper's window shuts exactly when the game's would (ISMap:update: his inventory no longer contains the map), the World window as it was",
            "the game keeps it " .. tostring(keeps) .. " (the map in " .. where .. "); ZeD's unfolded " .. tostring(H.pop() ~= nil) .. ", World open " .. tostring(H.wwOpen()) .. " (before " .. tostring(T.before) .. ")")
    end)
    H.step(2, function() RT.pairOpen() end)
end
function C.mp55()
    local T = { L = "MP55 the paper put away" }
    H.step(2, function() H.caseStart(T) end)
    C.mp55leg(T, "dropped", false)
    C.mp55leg(T, "into a bag", false)
    C.mp55leg(T, "dropped", true)
    H.step(1, function() H.note(T.L .. ": the pad's hand-back to the inventory (PaperMap.returnFocus) is the window that had the pad at Read Map; the run reads by the mouse") end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP56 paper over paper, and the Map key
function C.mp56()
    local T = { L = "MP56 paper over paper and the Map key" }
    H.step(2, function()
        H.caseStart(T)
        RT.pairOpen()
        T.a = H.townMap()
        local ft2 = nil
        for _, ft in ipairs(S.TOWN_MAPS) do if H.known(ft) and ft ~= H.ft(T.a) and not ft2 then ft2 = ft end end
        T.b = ft2 and H.give(ft2) or nil
        if not (T.a and T.b) then T.off = true; Q.skip(T.L, "two town maps are needed"); return end
        H.readMap(T.a)
    end)
    H.wait(3000, function() return T.off or H.paperUp(T.a) end, function(ok)
        if T.off then return end
        H.readMap(T.b)
    end)
    H.wait(3000, function() return T.off or H.paperUp(T.b) end, function(ok)
        if T.off then return end
        Q.check(ok and H.paperItem() == T.b, T.L .. ": Read Map on a second paper shows it in place of the first", "showing " .. H.ft(H.paperItem()))
        H.qstop()
        H.zcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
    end)
    H.wait(4000, function() return T.off or (H.popUp() and H.paperItem() == nil) end, function(ok)
        if T.off then return end
        Q.check(ok and H.wwOpen(), T.L .. ": the Map key with a paper up folds the paper and opens the world map, the World window stays", H.tabState())
        H.readMap(T.a)
    end)
    H.wait(3000, function() return T.off or H.paperUp(T.a) end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": Read Map with the world map unfolded folds it and shows the paper", H.tabState())
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP57 every kind of paper map
function C.mp57()
    local T = { L = "MP57 every kind of paper map" }
    H.step(2, function()
        H.caseStart(T)
        RT.pairOpen()
        H.gameWinWatch(true)
        T.res, T.bad = {}, {}
        H.note(T.L .. ": each town map is opened straight in ZeD's window (MapsTab.openPopout with the item, what Read Map ends in), so no map is marked read here; Read Map itself is MP52")
    end)
    H.tabQ(T)
    for _, ft in ipairs(S.TOWN_MAPS) do
        H.step(2, function()
            T.it = nil
            if T.off or not H.known(ft) then return end
            local w = RT.ww()
            if w._mapPopout then pcall(S.MT.closePopout, w, true) end
            T.it = H.give(ft)
            T.w0 = S.gameWinN
            H.zcall(function() S.MT.openPopout(w, T.it) end)
        end)
        H.wait(2500, function() return T.off or not T.it or (H.paperUp(T.it) and H.mp()._paperViewSet) or S.gameWinN > T.w0 end, function(ok)
            if T.off or not T.it then return end
            local drawn = H.paperUp(T.it)
            local game = S.gameWinN > T.w0
            local b = drawn and H.paperBounds() or nil
            T.res[#T.res + 1] = ft:gsub("Base%.", "") .. (drawn and " drawn" or (game and " the game's window" or " NOTHING"))
            if not (drawn or game) then T.bad[#T.bad + 1] = ft end
            if drawn and b and (b.x2 <= b.x1 or b.y2 <= b.y1) then T.bad[#T.bad + 1] = ft .. " (no area)" end
            local w = RT.ww()
            if w._mapPopout then pcall(S.MT.closePopout, w, true) end
            H.gameMapShut()
            H.removeItem(T.it)
        end)
    end
    H.step(2, function()
        if T.off then return end
        Q.check(#T.bad == 0 and #T.res > 0, T.L .. ": every town and Louisville map is drawn by ZeD, or the game's own window opens in its place", H.list(T.res, 16) .. "; failed " .. H.list(T.bad))
        H.gameWinWatch(false)
    end)
    H.caseEnd(T.L)
    H.skipCase("MP58 a stash map and Find", "reading a stash map places its stash for good: not repeatable on one save, so the run reads none")
end

-- ===================================================================== MP60 the drawer's stops
function H.idx(list, pred) for i, v in ipairs(list) do if pred(v) then return i end end; return nil end
function H.orderText(ids) return H.list(ids, 40) end
function C.mp60()
    local T = { L = "MP60 the drawer's stops" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function() if not T.off then H.padOn(); H.focusEl("map:disclosure") end end)
    H.step(3, function()
        if T.off then return end
        local ids = {}
        for _, e in ipairs(H.stops()) do ids[#ids + 1] = tostring(e.id) end
        local iD = H.idx(ids, function(v) return v == "map:disclosure" end)
        local iT = H.idx(ids, function(v) return string.sub(v, 1, 9) == "map:tool:" end)
        local iP = H.idx(ids, function(v) return v == "map:popout" end)
        local iC = H.idx(ids, function(v) return v == "map:canvas:cursor" end)
        local iS = H.idx(ids, function(v) return string.sub(v, 1, 10) == "map:style:" end)
        local inks = H.idx(ids, function(v) return string.sub(v, 1, 10) == "map:color:" end)
        Q.check(iD == 1 and iT and iP and iC and iT < iP and iP < iC and (iS == nil or iC < iS) and inks == nil,
            T.L .. ": the order is the fold arrow, the header's marks and Aa, the unfold button, the map's cursor, then the band; no ink stops with no tool up", H.orderText(ids))
        RT.ww()._mapToolsExpanded = true
        H.click(H.toolFid("house"), T.L)
    end)
    H.step(4, function()
        if T.off then return end
        local ids = {}
        for _, e in ipairs(H.stops()) do ids[#ids + 1] = tostring(e.id) end
        local iP = H.idx(ids, function(v) return v == "map:popout" end)
        local iInk = H.idx(ids, function(v) return string.sub(v, 1, 10) == "map:color:" end)
        local iG = H.idx(ids, function(v) return string.sub(v, 1, 13) == "map:gridtool:" end)
        local iC = H.idx(ids, function(v) return v == "map:canvas:cursor" end)
        Q.check(iInk and iP and iG and iC and iInk < iP and iP < iG and iG < iC, T.L .. ": with a tool up the inks come before the unfold button; with the fold open the full set after it, before the map",
            H.orderText(ids))
        -- the D-pad down the stops from the fold arrow (logged)
        T.walk = {}
        H.focusEl("map:disclosure")
        for _ = 1, 14 do
            RT.padDir("down", RT.ww())
            T.walk[#T.walk + 1] = tostring(H.focusedId())
        end
        H.note(T.L .. ": D-pad down from the fold arrow visits " .. H.list(T.walk, 14))
        T.go = H.focusEl("map:canvas:cursor")
    end)
    -- the map cursor's B: the tool down first, then off the canvas
    H.tapB(function() return T.go and not T.off end)
    H.pause(200)
    H.step(1, function()
        if T.off then return end
        T.after1 = { tool = H.armed(), on = H.focusedId() }
    end)
    H.tapB(function() return T.go and not T.off end)
    H.pause(200)
    H.step(1, function()
        if T.off then return end
        Q.check(T.go and T.after1.tool == nil and T.after1.on == "map:canvas:cursor" and H.focusedId() ~= "map:canvas:cursor" and H.focusedId() ~= nil,
            T.L .. ": B on the map's cursor puts the tool down first, then leaves the map for the first other stop",
            "after one B: tool " .. tostring(T.after1.tool) .. ", on " .. tostring(T.after1.on) .. "; after two: on " .. tostring(H.focusedId()))
        local jd = nil
        pcall(function() jd = getJoypadData(S.pn) end)
        if not jd then Q.skip(T.L .. ": he cannot move or aim while the pad's cursor is on the map, and can again on leaving", "no pad is bound on this rig (the hold is set by the stick's own tick, _mapPadPlayer)") end
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP61 the unfolded window's stops
function C.mp61()
    local T = { L = "MP61 the unfolded window's stops" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.padPress(T, "map:popout")
    H.wait(3000, function() return T.off or H.popUp() end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, T.L .. ": the pad unfolds the map", H.tabState()); return end
        local pop = H.pop()
        if pop._focusFresh then pcall(pop._focusFresh, pop) end
    end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        Q.check(H.focusedId() == "map:canvas:cursor", T.L .. ": the first landing in the unfolded window is the map's cursor", "on " .. tostring(H.focusedId()) .. "; stops " .. H.list(H.stopIds(), 20))
        T.go = H.focusEl("map:style:color") or H.focusEl("map:popout")
        T.on = H.focusedId()
    end)
    H.tapB(function() return T.go and not T.off end)
    H.wait(1500, function() return T.off or H.pop() == nil end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": B on a stop (" .. tostring(T.on) .. ") folds the map", H.tabState())
        H.padOff()
        H.note(T.L .. ": the style list's own B (it shuts the list, not the window: ownCancel) is MP18's; the unfolded window is wide enough for the radios here")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP62 the side list (B6)
function H.extOn(rows)
    S.sideHits, S.sideDel = 0, 0
    local list = {}
    for i = 1, rows do
        list[i] = { key = "r" .. i, title = "ZEDQA row " .. i, sub = "a test row",
                    activate = function(w) S.sideHits = S.sideHits + 1 end,
                    del = { ask = "Delete the test row? Nothing is lost.", onYes = function(w) S.sideDel = S.sideDel + 1 end } }
    end
    S.qaExt = { order = 90, side = function(win) return { key = "zedqa", title = "ZEDQA list", count = #list, rows = list } end }
    S.MT.addExtension("zedqa_mz", S.qaExt)
end
function H.extOff()
    if not S.qaExt then return end
    for i, d in ipairs(S.E.list or {}) do if d.id == "zedqa_mz" then table.remove(S.E.list, i); break end end
    S.qaExt = nil
    local w = RT.ww()
    if w then w._mapSideSec, w._mapSideSecT, w._mapSideAsk = nil, nil, nil end
end
function C.mp62()
    local T = { L = "MP62 the side list" }
    H.step(2, function() H.caseStart(T); H.extOn(30) end)
    H.tabQ(T)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        RT.ww()._mapSideOpen = true
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.zone("map:side:zedqa:r1") ~= nil and H.zone("map:ext:list") ~= nil, T.L .. ": an extension's rows show in the side list, its button on the band", H.list(H.zoneIds(), 30))
        H.click("map:side:zedqa:r1", T.L)
        T.hits1 = S.sideHits
        H.click("map:side:zedqa:r1:x", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.hits1 == 1 and RT.ww()._mapSideAsk ~= nil and H.zone("map:side:no") ~= nil and H.zone("map:side:yes") ~= nil,
            T.L .. ": a click on a row runs it; its delete button asks, Cancel and Delete in the band's place", "runs " .. tostring(T.hits1) .. ", asking " .. tostring(RT.ww()._mapSideAsk ~= nil))
        H.click("map:side:no", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        T.ask1 = RT.ww()._mapSideAsk
        H.click("map:side:zedqa:r1:x", T.L)
    end)
    H.step(3, function() if not T.off then H.click("map:side:yes", T.L) end end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.ask1 == nil and S.sideDel == 1 and RT.ww()._mapSideAsk == nil, T.L .. ": Cancel asks no more; Delete runs the row's delete", "after Cancel asking " .. tostring(T.ask1 ~= nil) .. ", deletes " .. S.sideDel)
        H.padOn()
        local ids = H.stopIds("map:side:")
        local xs = {}
        for _, id in ipairs(ids) do if string.sub(id, string.len(id) - 1) == ":x" then xs[#xs + 1] = id end end
        Q.check(#xs == 0, T.L .. " (B6): the rows' delete buttons are no pad stops (X on a row asks instead)", #xs .. " delete buttons in the ring: " .. H.list(xs, 4))
    end)
    H.padPress(T, "map:side:zedqa:r2")
    H.pause(200)
    H.padPress(T, "map:side:zedqa:r2", nil, "X")
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        Q.check(S.sideHits == 2 and RT.ww()._mapSideAsk ~= nil, T.L .. " (pad): A on a row runs it, X asks to delete it", "runs " .. S.sideHits .. ", asking " .. tostring(RT.ww()._mapSideAsk ~= nil))
    end)
    H.padPress(T, "map:side:no")
    H.pause(200)
    H.padPress(T, "map:side:zedqa:r2", nil, "X")
    H.pause(200)
    H.padPress(T, "map:side:yes")
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        Q.check(S.sideDel == 2 and RT.ww()._mapSideAsk == nil, T.L .. " (pad): A on Cancel, then X and A on Delete", "deletes " .. S.sideDel)
        H.padOff()
        -- the wheel over the list scrolls the list, not the map
        local z = RT.ww()._mapSideZone
        local mp = H.mp()
        if not (z and mp) then Q.check(false, T.L .. ": the side list has its place over the map", tostring(z)); return end
        T.s0 = RT.ww()._mapSideScroll or 0
        T.z0 = H.zoom()
        H.fake(z.x - mp:getX() + math.floor(z.w / 2), z.y - mp:getY() + math.floor(z.h / 2))
        H.zcall(function() mp:onMouseWheel(1) end)
        H.fakeOff()
    end)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        local s1 = RT.ww()._mapSideScroll or 0
        local z = H.zoom()
        Q.check(s1 > T.s0 and z ~= nil and math.abs(z - (T.z0 or 0)) < 0.01, T.L .. ": the wheel over the list scrolls the list and leaves the map's zoom", "scroll " .. T.s0 .. " -> " .. s1 .. ", zoom " .. H.n2(T.z0) .. " -> " .. H.n2(z))
        H.click("map:ext:list", T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(RT.ww()._mapSideOpen == false and H.zone("map:side:zedqa:r1") == nil, T.L .. ": the band's list button hides the list in the drawer", "open " .. tostring(RT.ww()._mapSideOpen))
        RT.ww()._mapSideOpen = true
    end)
    H.unfoldQ(T)
    H.pause(300)
    H.step(1, function()
        if T.off then return end
        local mp, pop = H.mp(), H.pop()
        local cw, mw = 0, 0
        pcall(function() cw, mw = pop._contentPanel:getWidth(), mp:getWidth() end)
        local side = H.px(236)
        Q.check(math.abs(cw - mw - side) <= 2 and H.zone("map:ext:list") == nil, T.L .. ": unfolded, the list docks 236 units wide at the map's right (no list button)",
            "body " .. math.floor(cw) .. ", map " .. math.floor(mw) .. ", the list " .. math.floor(cw - mw) .. " (want " .. side .. ")")
    end)
    H.step(2, function() H.extOff() end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP63 other mods' extensions
function C.mp63()
    local T = { L = "MP63 other mods' extensions" }
    H.step(2, function()
        H.caseStart(T)
        local ids = {}
        for _, d in ipairs(S.E.list or {}) do ids[d.id] = true end
        H.note(T.L .. ": the extensions loaded: " .. H.extIds() .. " (the key, Survey's print and the paper's Find are ZeD's own)")
        local mods = { { "Draw On The Map", "drawonmap" }, { "Map Symbol Size Slider", "symbolsize" }, { "Where Am I", "whereami" },
                       { "BLT Annotations", "blt" }, { "Players On Map", "pom" }, { "admin zones and teleport", "admin" } }
        local anyOther = false
        for id in pairs(ids) do if id ~= "key" and id ~= "zed-survey-print" and id ~= "paperfind" then anyOther = true end end
        if not anyOther then
            for _, m in ipairs(mods) do Q.skip(T.L .. ": " .. m[1], "not loaded in this run (the run's mod list)") end
        else
            H.note(T.L .. ": other extensions are loaded; their own tools are not driven by this sweep (each mod's support file is its own check)")
        end
        Q.skip(T.L .. ": Custom Map Labels at game start", "the game's map opened and shut by that mod happens at load")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP65 Lite
function C.mp65()
    local T = { L = "MP65 Lite" }
    H.step(2, function() H.caseStart(T) end)
    H.tabQ(T)
    H.step(2, function()
        if T.off then return end
        T.full = H.zoneIds()
        table.sort(T.full)
        if not H.lite(true) then T.off = true; Q.skip(T.L, "no Lite setting here") end
    end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        local lite = H.zoneIds()
        table.sort(lite)
        Q.check(table.concat(lite, ";") == table.concat(T.full, ";") and H.mapUp(), T.L .. ": Lite draws the same tab: the same marks, inks, styles and band buttons",
            "Full " .. H.list(T.full, 20) .. " / Lite " .. H.list(lite, 20))
        H.lite(S.found.liteIdx == 2)
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== MP66 the game's mini-map
function C.mp66()
    local T = { L = "MP66 the game's mini-map" }
    H.step(2, function()
        H.caseStart(T)
        T.mm = nil
        pcall(function() T.mm = getPlayerMiniMap(S.pn) end)
        if not T.mm then T.off = true; Q.skip(T.L, "no mini-map for him (the sandbox's AllowMiniMap " .. tostring(S.found.sbx and S.found.sbx.mini) .. "): nothing to hide"); return end
        pcall(function() T.mm:setVisible(true) end)
        T.t0 = getTimestampMs()
    end)
    H.wait(1500, function() return T.off or not H.vis(T.mm) end, function(ok)
        if T.off then return end
        Q.check(ok and getTimestampMs() - T.t0 <= 900, T.L .. ": the game's mini-map, shown, is hidden within half a second (ZeD.MiniMapOff)", "hidden " .. tostring(ok) .. " in " .. (getTimestampMs() - T.t0) .. " ms")
        if S.found.mini then pcall(function() T.mm:setVisible(true) end) end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the night: MP4 (the key in the dark), MP13 (the tab in the dark), B12, MP59
function H.nightQ(T)
    H.step(2, function()
        if T.off then return end
        S.night = true
        pcall(function() getGameTime():setTimeOfDay(1.0) end)
    end)
    H.wait(12000, function() return T.off or H.dark() end, function(ok) T.dark = ok end)
end
function H.dayQ(T)
    H.step(2, function() H.day() end)
    H.wait(12000, function() return T.off or not H.dark() end, function(ok) T.lit = ok end)
end
-- the run's stand-in for ZeD's light rule (a debug game reads every map in the dark: the view's own answer is then
-- staged, said so in each check)
function H.stageDark(on)
    if on and not S.tooDark0 then
        S.tooDark0 = S.MT.tooDark
        S.MT.tooDark = function() return true end
    elseif not on and S.tooDark0 then
        S.MT.tooDark = S.tooDark0
        S.tooDark0 = nil
    end
end
function C.night()
    local T = { L = "MP4 the Map key in the dark" }
    H.step(2, function() H.caseStart(T); T.dbg = H.debug() end)
    H.tabQ(T)
    H.nightQ(T)
    H.step(2, function()
        if T.off then return end
        if not T.dark then
            Q.skip(T.L .. ": the game's refusal and ZeD's tab in the dark", "not too dark to read here at 1:00 within 12 s (tooDarkToRead false" .. (T.dbg and "; a debug game reads in the dark" or "") .. "): the view's own legs below stage ZeD's rule")
            return
        end
        RT.worldTab("loot")
        H.qstop()
        T.t1 = getTimestampMs()
        H.keyM()
        T.q = H.qkinds()
    end)
    H.pause(600)
    H.step(1, function()
        if T.off or not T.dark then return end
        Q.check(H.said(T.t1, "ContextMenu_TooDark") and H.pop() == nil and H.qcount("ISReadWorldMap") == 0, T.L .. ": the Map key in the dark says the game's \"" .. H.txt("ContextMenu_TooDark") .. "\" and opens nothing",
            "said " .. H.list(H.saidSince(T.t1)) .. "; queued " .. tostring(T.q) .. "; " .. H.tabState())
        local zd = nil
        pcall(function() zd = S.MT.tooDark(S.p) end)
        Q.check(zd == true, T.L .. ": ZeD's light rule agrees with the game's refusal (MapsTab.tooDark)", tostring(zd))
        RT.worldTab("maps")
    end)
    H.pause(800)
    H.step(1, function()
        if T.off or not T.dark then return end
        local word = ZeD.trBare and ZeD.trBare("ContextMenu_TooDark") or H.txt("ContextMenu_TooDark")
        Q.check(H.blocked() and H.drew(word) ~= nil and not H.vis(H.mp()), "MP13 the tab in the dark: the tab reads the game's \"" .. tostring(word) .. "\" in place of the map", "blocked " .. tostring(H.blocked()) .. ", drawn " .. H.textsLike(string.sub(tostring(word), 1, 6)))
        H.padOn()
        Q.check(#H.stops() == 0, "MP13 the tab in the dark (pad): the drawer offers no stops", H.list(H.stopIds(), 8))
        H.padOff()
        H.sbx(nil, false)
    end)
    H.pause(800)
    H.step(1, function()
        if T.off or not T.dark then return end
        Q.check(not H.blocked() and H.vis(H.mp()), "MP13 the tab in the dark: with the sandbox's MapNeedsLight off it is never blocked", "blocked " .. tostring(H.blocked()))
        H.sbx(nil, true)
    end)
    H.dayQ(T)
    H.step(1, function() T.tLit = getTimestampMs() end)
    H.wait(3000, function() return T.off or not T.dark or not H.blocked() end, function(ok)
        if T.off or not T.dark then return end
        Q.check(ok and getTimestampMs() - T.tLit <= 700, "MP13 the tab in the dark: in the light again the map is back within half a second", "back " .. tostring(ok) .. " in " .. (getTimestampMs() - T.tLit) .. " ms after the light")
    end)
    -- B12: the world map unfolded in the light, then the dark comes (staged in a game where it never does)
    H.unfoldQ(T)
    H.step(2, function()
        if T.off then return end
        if T.dark then S.night = true; pcall(function() getGameTime():setTimeOfDay(1.0) end) else H.stageDark(true) end
    end)
    H.wait(12000, function() return T.off or (not T.dark) or H.dark() end, function() end)
    H.pause(800)
    H.step(1, function()
        if T.off then return end
        local how = T.dark and "a night" or "ZeD's light rule answering dark, staged (no night is dark here)"
        Q.check(not H.blocked() and H.vis(H.mp()), "B12 the open map in the dark (" .. how .. "): the unfolded world map stays readable, as the game keeps an open map (ISWorldMap.ToggleWorldMap)",
            "blocked " .. tostring(H.blocked()) .. ", the map seen " .. tostring(H.vis(H.mp())))
        if not H.pop() then H.zcall(function() S.MT.openPopout(RT.ww()) end) end
    end)
    H.step(4, function()
        if T.off then return end
        T.upAgain = H.pop() ~= nil
        H.zcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
    end)
    H.wait(1500, function() return T.off or H.pop() == nil end, function(ok)
        if T.off then return end
        Q.check(ok and T.upAgain, T.L .. ": in the dark the Map key still folds the map (closing never waits on the light)", "unfolded before the key " .. tostring(T.upAgain) .. "; " .. H.tabState())
        RT.worldTab("loot")
    end)
    -- still dark: a map opened now is refused (the tab shown after a gap, the map unfolded), and a refused one looks
    -- again twice a second, so it comes back with the light
    H.pause(800)
    H.step(1, function() if not T.off then RT.worldTab("maps") end end)
    H.pause(500)
    H.step(1, function()
        if T.off then return end
        local how = T.dark and "a night" or "staged dark"
        local word = ZeD.trBare and ZeD.trBare("ContextMenu_TooDark") or H.txt("ContextMenu_TooDark")
        Q.check(H.blocked() and H.drew(word) ~= nil, "MP13 the tab in the dark (" .. how .. "): the tab shown again in the dark reads the game's words in place of the map (the light looked at on opening)",
            "blocked " .. tostring(H.blocked()) .. ", drawn " .. H.textsLike(string.sub(tostring(word), 1, 6)))
        H.zcall(function() S.MT.openPopout(RT.ww()) end)
    end)
    H.pause(400)
    H.step(1, function()
        if T.off then return end
        T.blk = H.blocked() and H.pop() ~= nil
        H.padOn()
        T.go = T.blk and H.focusEl("map:blocked")
        Q.check(T.blk and T.go and #H.stops() == 1, "MP13 the tab in the dark (pad): unfolded in the dark, the refusal is the window's one stop", "blocked " .. tostring(H.blocked()) .. ", unfolded " .. tostring(H.pop() ~= nil) .. "; stops " .. H.list(H.stopIds(), 6))
    end)
    H.tapA(function() return T.go and not T.off end)
    H.wait(1500, function() return T.off or not T.go or H.pop() == nil end, function(ok)
        H.padOff()
        if T.off or not T.go then return end
        Q.check(ok, "MP13 the tab in the dark (pad): A on the refusal folds the unfolded map", H.tabState())
    end)
    H.step(2, function()
        if T.off then return end
        if T.dark then H.day() else H.stageDark(false) end
    end)
    H.wait(12000, function() return T.off or not H.dark() end, function() T.tLit2 = getTimestampMs() end)
    H.wait(3000, function() return T.off or not H.blocked() end, function(ok)
        if T.off then return end
        Q.check(ok and getTimestampMs() - (T.tLit2 or 0) <= 700, "MP13 the tab in the dark (" .. (T.dark and "a night" or "staged dark") .. "): a refused map looks again twice a second and comes back with the light",
            "back " .. tostring(ok) .. " in " .. (getTimestampMs() - (T.tLit2 or 0)) .. " ms after the light")
        H.stageDark(false)
    end)
    -- MP59: a paper opened in the light keeps showing in the dark; Read Map in the dark is the game's greyed option
    H.dayQ(T)
    H.step(2, function()
        if T.off then return end
        T.item = H.townMap()
        if T.item then H.readMap(T.item) end
    end)
    H.wait(3000, function() return T.off or not T.item or H.paperUp(T.item) end, function(ok)
        if T.off or not T.item then return end
        if T.dark then S.night = true; pcall(function() getGameTime():setTimeOfDay(1.0) end) else H.stageDark(true) end
    end)
    H.wait(12000, function() return T.off or not T.item or (not T.dark) or H.dark() end, function() end)
    H.pause(800)
    H.step(1, function()
        if T.off or not T.item then return end
        Q.check(H.paperUp(T.item) and not H.blocked(), "MP59 a paper in the dark: a paper opened in the light keeps showing when it gets dark" .. (T.dark and "" or " (staged dark)"), H.tabState())
        H.stageDark(false)
        if T.dark then
            local ctx = nil
            pcall(function() ctx = ISInventoryPaneContextMenu.createMenu(S.pn, true, { T.item }, 0, 0) end)
            local op = H.ctxOpt(H.txt("ContextMenu_CheckMap"))
            local tip = op and H.optTip(op)
            Q.check(op ~= nil and op.notAvailable == true and tip == H.txt("ContextMenu_TooDark"), "MP59 a paper in the dark: Read Map in the dark is the game's greyed option with its reason",
                "the option " .. H.ctxNames() .. ", tip \"" .. tostring(tip) .. "\"")
            H.ctxShut()
        else
            Q.skip("MP59 a paper in the dark: the game's Read Map greyed in the dark", "no night is dark here")
        end
    end)
    H.dayQ(T)
    H.caseEnd(T.L)
end

-- ===================================================================== MP4's car legs: the light in a car
function C.car()
    local T = { L = "MP4 the Map key in a car at night" }
    H.step(2, function()
        H.caseStart(T)
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then T.off = true; Q.skip(T.L, "the prelude's car helpers are not loaded"); return end
        if H.debug() then T.off = true; Q.skip(T.L, "a debug game reads every map in the dark (the game's own debug pass): a car changes nothing here"); return end
        ZEDQA_CAR_WAIT("Base.CarNormal", "mz_tab", function(v) T.v = v; T.key = ZEDQA_CAR_PREP(v); S.car, S.carKey = v, T.key end, function(why) T.why = why or "no car" end, 6000)
    end)
    H.wait(45000, function() return T.off or T.v ~= nil or T.why ~= nil end, function()
        if T.off then return end
        if not T.v then T.off = true; Q.skip(T.L, "no car: " .. tostring(T.why)); return end
        local ok, why = ZEDQA_CAR_ENTER(T.v, 0)
        if not ok then T.off = true; Q.skip(T.L, "could not seat him: " .. tostring(why)) end
    end)
    H.nightQ(T)
    for _, leg in ipairs({ "a live battery", "a flat battery", "a flat battery and a torch on" }) do
        H.step(2, function()
            if T.off then return end
            pcall(function()
                local it = T.v:getPartById("Battery"):getInventoryItem()
                it:setCurrentUsesFloat(leg == "a live battery" and 1.0 or 0.0)
            end)
            if leg == "a flat battery and a torch on" then
                local ft = nil
                for _, f in ipairs({ "Base.HandTorch", "Base.Torch", "Base.Flashlight" }) do if not ft and H.known(f) then ft = f end end
                local t = ft and H.give(ft)
                if t then pcall(function() S.p:setPrimaryHandItem(t); t:setActivated(true) end) end
            end
        end)
        H.step(10, function()
            if T.off then return end
            local zd = nil
            pcall(function() zd = S.MT.tooDark(S.p) end)
            H.qstop()
            T.t1 = getTimestampMs()
            H.zcall(function() ISWorldMap._zedOrigToggle(S.pn) end)
            local refused = H.said(T.t1, "ContextMenu_TooDark")
            local read = H.qfirst("ISReadWorldMap") ~= nil
            H.qstop()
            local ts, lb, ch = 0, nil, nil
            pcall(function() ts = S.p:getTorchStrength() end)
            pcall(function() lb = T.v:hasLiveBattery() end)
            pcall(function() ch = T.v:getBatteryCharge() end)
            if not T.dark and not refused then
                H.note(T.L .. " (" .. leg .. "): not dark enough at 1:00 to tell; ZeD's rule says dark " .. tostring(zd))
            else
                Q.check(zd == refused, T.L .. " (" .. leg .. "): ZeD's light rule answers as the game's own Toggle", "ZeD dark " .. tostring(zd) .. "; the game refused " .. tostring(refused)
                    .. ", queued its read " .. tostring(read) .. "; live battery " .. tostring(lb) .. ", charge " .. H.n2(ch) .. ", torch " .. H.n2(ts))
            end
        end)
    end
    H.step(2, function()
        H.qstop()
        pcall(function() if S.p:getVehicle() then local v = S.p:getVehicle(); v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
        H.home()
    end)
    H.step(6, function()
        if S.car then pcall(ZEDQA_CAR_AWAY, S.car, S.carKey); S.carGone = S.car; S.car, S.carKey = nil, nil end
        Q.skip(T.L .. ": as an admin", "an admin is a server's player (isAdmin)")
    end)
    H.pause(1500)
    H.dayQ(T)
    H.caseEnd(T.L)
end

-- ===================================================================== B13 a map that failed to build
function C.b13()
    local T = { L = "B13 a map that failed to build" }
    H.step(2, function()
        H.caseStart(T)
        RT.pairOpen()
        H.freshWindow()
    end)
    H.wait(4000, function() return #RT.tabs(RT.worldStrip()) > 0 end, function() end)
    H.step(2, function()
        S.eB13 = H.errN()
        S.uwm = UIWorldMap
        UIWorldMap = { new = function() error("zedqa: the map build fails here (staged)") end }
        RT.worldTab("maps")
    end)
    H.wait(3000, function() local w = RT.ww(); return w ~= nil and (w._worldMapFailed == true or w._worldMapPanel ~= nil) end, function(ok)
        if S.uwm then UIWorldMap = S.uwm; S.uwm = nil end
        if not ok then H.note(T.L .. ": the tab did not try to build its map in 3 s (the drawer not drawn)") end
        -- (the staged throw is caught by the tab's own pcall, and the game logs each caught throw: those are the run's,
        -- not the tab's, so the case's error count starts after them)
        local e = H.errN()
        if e and S.e0 then H.note(T.L .. ": " .. (e - S.e0) .. " Lua errors logged by the staged build failure (excused)"); S.e0 = e end
        if e and S.eB13 then S.excused = (S.excused or 0) + (e - S.eB13) end
        T.tWorks = getTimestampMs()
        T.failed0 = RT.ww() and RT.ww()._worldMapFailed
    end)
    H.step(2, function()
        local word = H.tr("UI_ZeD_Map_Unavailable")
        H.note(T.L .. ": the first build failed (staged): failed mark " .. tostring(T.failed0) .. ", the tab reads \"" .. tostring(H.drew(word) and word) .. "\"")
    end)
    -- the tab tries again a second after the failure (MapsTab MAP_RETRY_MS), and a build that works clears the mark
    H.wait(2500, function() return H.mp() ~= nil end, function(ok)
        local w = RT.ww()
        local failed = w and w._worldMapFailed
        Q.check(ok and T.failed0 == true and not failed, T.L .. ": once the map can be made again, the tab makes it within about 2 s (no World window made again) and clears the failed mark",
            "the map " .. tostring(H.mp() ~= nil) .. " after " .. (getTimestampMs() - (T.tWorks or 0)) .. " ms; failed at first " .. tostring(T.failed0) .. ", now " .. tostring(failed))
    end)
    H.wait(3000, function() return H.mapUp() end, function(ok)
        Q.check(ok, T.L .. ": the made map shows on the tab", H.tabState())
        H.freshWindow()
    end)
    H.wait(4000, function() return #RT.tabs(RT.worldStrip()) > 0 end, function() end)
    H.step(2, function() RT.worldTab("maps") end)
    H.wait(4000, function() return H.mapUp() end, function(ok) Q.check(ok, T.L .. ": a World window made again has its map", H.tabState()) end)
    H.caseEnd(T.L)
end

-- ===================================================================== safe mode: MP10, MP41
function C.safe()
    local T = { L = "MP10 safe mode" }
    H.step(2, function()
        H.caseStart(T)
        if not (ZeD.Settings and ZeD.Settings.safeModeOption) then T.off = true; Q.skip(T.L, "no safe mode setting"); return end
    end)
    H.tabQ(T)
    -- MP41's marks first, in ZeD's map
    H.step(2, function()
        if T.off then return end
        T.made = {}
        for i, m in ipairs({ { "star", 4 }, { "cross", 3 }, { "x", 5 } }) do
            local w = RT.ww()
            w._mapActiveTool = m[1]
            w._mapActiveColor = m[2]
            local x, y = H.freeSpot(i)
            local s = H.placeAt(x, y)
            if s then T.made[#T.made + 1] = s end
        end
        local w = RT.ww()
        w._mapActiveTool = "text"
        w._mapActiveColor = 1
        pcall(function() w._mapTextEntry:setText("ZEDQA safe note") end)
        local x, y = H.freeSpot(5)
        local s = H.placeAt(x, y)
        if s then T.made[#T.made + 1] = s end
        w._mapActiveTool = nil
        T.sigs = {}
        for _, sm in ipairs(T.made) do
            local o = {}
            pcall(function() o = { text = sm:isText() and sm:getTranslatedText() or nil, id = (not sm:isText()) and sm:getSymbolID() or nil, x = sm:getWorldX(), y = sm:getWorldY(), r = sm:getRed(), g = sm:getGreen(), b = sm:getBlue() } end)
            T.sigs[#T.sigs + 1] = o
        end
        H.safeSet(true)
    end)
    H.wait(3000, function() return T.off or H.safeOn() end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.check(false, T.L .. ": safe mode comes on", "on " .. tostring(H.safeOn())); return end
        H.qstop()
        H.zcall(function() ISWorldMap.ToggleWorldMap(S.pn) end)
    end)
    H.wait(6000, function() return T.off or H.gameMapUp() end, function(ok)
        if T.off then return end
        Q.check(ok and H.pop() == nil, T.L .. ": the Map key opens the game's own map in safe mode", "the game's map up " .. tostring(ok) .. ", ZeD's unfolded " .. tostring(H.pop() ~= nil))
        if not ok then return end
        local api = nil
        pcall(function() api = ISWorldMap_instance.mapAPI:getSymbolsAPIv2() end)
        local found = 0
        for _, sg in ipairs(T.sigs) do
            for _, s in ipairs(H.userSyms(api)) do
                local m = false
                pcall(function()
                    m = math.abs(s:getWorldX() - sg.x) < 0.01 and math.abs(s:getWorldY() - sg.y) < 0.01 and math.abs(s:getRed() - sg.r) < 0.01
                        and math.abs(s:getGreen() - sg.g) < 0.01 and math.abs(s:getBlue() - sg.b) < 0.01
                        and ((sg.text and s:isText() and s:getTranslatedText() == sg.text) or (sg.id and not s:isText() and s:getSymbolID() == sg.id))
                end)
                if m then found = found + 1; break end
            end
        end
        Q.check(#T.sigs == 4 and found == 4, "MP41 the game's map sees ZeD's marks: the three marks and the note ZeD made show on the game's own map, same colors (one store: MapItem.getSingleton)",
            found .. " of " .. #T.sigs .. " found on the game's map")
        H.gameMapShut()
        H.speed(1)
    end)
    -- Read Map in safe mode: the game's window
    H.step(4, function()
        if T.off then return end
        H.gameWinWatch(true)
        T.w0 = S.gameWinN
        T.item = H.townMap()
        if T.item then H.readMap(T.item) end
    end)
    H.wait(5000, function() return T.off or not T.item or S.gameWinN > T.w0 end, function(ok)
        if T.off or not T.item then return end
        Q.check(ok and H.paperItem() == nil, T.L .. ": Read Map opens the game's own paper map window (ISMapWrapper) in safe mode", "the game's windows made " .. (S.gameWinN - T.w0) .. ", ZeD's paper " .. tostring(H.paperItem() ~= nil))
        H.gameMapShut()
        H.gameWinWatch(false)
        local mm = nil
        pcall(function() mm = getPlayerMiniMap(S.pn) end)
        if mm then H.note(T.L .. ": the game's mini-map in safe mode is seen " .. tostring(H.vis(mm)) .. " (ZeD shows again only the ones it hid)")
        else Q.skip(T.L .. ": the mini-map comes back", "no mini-map for him (the sandbox's AllowMiniMap " .. tostring(S.found.sbx and S.found.sbx.mini) .. ")") end
        Q.skip(T.L .. ": the D-pad wheel's Map slice", "the game's own wheel in safe mode needs a bound pad")
    end)
    H.step(2, function()
        H.safeSet(S.found.safeIdx == 2)
        S.back.safe = nil
    end)
    H.wait(3000, function() return H.safeOn() == (S.found.safe == true) end, function() end)
    H.step(10, function() RT.pairOpen() end)
    H.tabQ(T)
    H.caseEnd(T.L)
end

-- ===================================================================== MP64 small screens and the UI scale (with MP25's scale legs)
function C.scaleLeg(T, v)
    H.step(2, function()
        T.skipLeg = nil
        if T.off then return end
        local i = H.scaleIdx(v)
        if not i then T.skipLeg = true; Q.skip(T.L .. " (UI scale " .. v .. ")", "ZeD offers no such step"); return end
        H.scaleSet(i)
    end)
    H.wait(10000, function() return T.off or T.skipLeg or H.scaleSettled() end, function(ok)
        if T.off or T.skipLeg then return end
        if math.abs(H.root() - v) > 0.05 then T.skipLeg = true; H.note(T.L .. " (UI scale " .. v .. "): ZeD kept the scale at " .. H.n2(H.root()) .. " on " .. H.sizeTag() .. " (a step too big for the screen)") end
        RT.pairOpen()
    end)
    H.wait(6000, function()
        if T.off or T.skipLeg then return true end
        if not H.onMaps() then RT.worldTab("maps") end
        return H.mapUp()
    end, function(ok)
        if T.off or T.skipLeg then return end
        if not ok then Q.check(false, T.L .. " (UI scale " .. v .. "): the Maps tab opens", H.tabState()); T.skipLeg = true end
    end)
    H.step(2, function()
        if T.off or T.skipLeg then return end
        local root = H.root()
        local got = H.lineH("text-town")
        if got then Q.check(got == math.floor(48 * root + 0.5), "MP25 the map's labels (UI scale " .. H.n2(root) .. "): the town names' line height follows it", tostring(got) .. " (want " .. math.floor(48 * root + 0.5) .. ")") end
        H.sizeSet("large")
    end)
    H.halfOn(T)
    H.pause(300)
    H.step(1, function()
        if T.off or T.skipLeg then return end
        local w = RT.ww()
        local pz = w._mapPopoutZone
        local over = {}
        for _, z in ipairs(w._mapToolZones or {}) do if not z.isGrid and pz and z.x + z.w > pz.x then over[#over + 1] = z.id end end
        for _, z in ipairs(w._mapColorZones or {}) do if pz and z.x + z.w > pz.x then over[#over + 1] = "ink " .. z.idx end end
        local band = H.zone("map:style:survey") and "radios" or (H.zone("map:style:menu") and "the box" or "nothing")
        H.sizeCheck(#over == 0, T.L .. " (UI scale " .. H.n2(H.root()) .. ", Large text, the half card " .. tostring(T.half) .. "): nothing on the header runs under the unfold button",
            "under it: " .. H.list(over) .. "; header " .. H.list(H.headerTools()) .. "; the band shows " .. band .. ", light " .. tostring(H.zone("map:style:light") ~= nil))
        RT.bounds(Q, T.L .. " (UI scale " .. H.n2(H.root()) .. ", Large text)")
        H.halfBack()
        H.sizeBack()
    end)
end
function C.mp64()
    local T = { L = "MP64 small screens" }
    H.step(2, function() H.caseStart(T); H.note(T.L .. ": the run's screen " .. H.sizeTag() .. " (the map asks 1280x720 too: not this run's size)") end)
    H.tabQ(T)
    C.scaleLeg(T, 1.5)
    C.scaleLeg(T, 2.0)
    H.step(2, function()
        if S.back.scale and S.found.scaleIdx then H.scaleSet(S.found.scaleIdx) end
        S.back.scale = nil
    end)
    H.wait(10000, function() return H.scaleSettled() end, function() RT.pairOpen() end)
    H.tabQ({ L = T.L .. " (the scale as found)" })
    H.caseEnd(T.L)
end

-- ===================================================================== what single player cannot show, and code facts
function C.notes()
    H.step(2, function()
        local pns = {}
        for _, c in ipairs(S.ctxCalls) do pns[tostring(c.pn)] = true end
        local o = {}
        for k in pairs(pns) do o[#o + 1] = k end
        Q.skip("B7 the mark menu's player", "split screen: a second local player (in single player the menu's player 0 is his; the menus asked this run were for player " .. H.list(o) .. ")")
        local mp = H.mp()
        Q.skip("B8 flyer visits and the pad's card for another player", "split screen (the drawer map's playerNum is " .. tostring(mp and mp.playerNum) .. ": nil reads player 0's input mode)")
        H.note("B14 dead code: ZeD.MapsTab.gpCursorStep is " .. type(S.MT.gpCursorStep) .. " and nothing calls it since the D-pad stopped moving the cursor (MapsTab, the D-pad step constants with it): no in-game case")
        local center = false
        for _, id in ipairs(H.zoneIds()) do if H.has(id, "center") then center = true end end
        H.note("B15 no center on the player: the tab draws no center control (" .. tostring(center) .. "); the game's C key and button have no counterpart and a far pan in the drawer stays until the World window is made again")
        H.note("FEATURE_MAP rows 649, 650, 652, 653, 654, 655, 657, 658, 659, 660, 686, 687 and 715 cite old lines (the map's section 4 lists each): test drift, no in-game case")
    end)
end

-- ===================================================================== put back
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    if S.uwm then UIWorldMap = S.uwm; S.uwm = nil end
    if S.defs0 then PrintMediaDefinitions.MiscDetails = S.defs0; S.defs0 = nil end
    H.stageDark(false)
    H.noteKbOff()
    H.gameWinWatch(false)
    H.extOff()
    if S.back.cbp ~= nil then pcall(function() getCore():setOptionColorblindPatterns(S.back.cbp) end); S.back.cbp = nil end
    H.legClean()
    H.readBack()
    S.removedAtEnd = H.removeNew()
    for _, it in ipairs(S.made) do H.removeItem(it) end
    H.sbxBack()
    local md = H.md()
    md.ZeD_MapStyle, md.ZeD_MapPaper = f.md.style, f.md.paper
    md.ZeD_MapAnnotations, md.ZeD_MapNotesMoved = f.md.ann, f.md.moved
    if f.pins then local p = {}; for i, v in ipairs(f.pins) do p[i] = v end; md.ZeD_MapPinnedIcons = p else md.ZeD_MapPinnedIcons = nil end
    if f.seen then local s = {}; for k, v in pairs(f.seen) do s[k] = v end; md.ZeD_FlyerSeen = s else md.ZeD_FlyerSeen = nil end
    H.traitSet("ILLITERATE", f.illit == true)
    H.themeBack()
    H.statusBack()
    H.sizeBack()
    if S.back.light then pcall(function() ZeD.Settings.mapLightOption:setValue(f.lightIdx) end); S.back.light = nil end
    if S.back.lite then pcall(function() ZeD.Settings.lookStyleOption:setValue(f.liteIdx) end); S.back.lite = nil end
    if S.back.safe then pcall(function() ZeD.Settings.safeModeOption:setValue(f.safeIdx) end); pcall(function() ZeD.Safe.reread() end); S.back.safe = nil end
    pcall(function() if ZeD.Settings.save then ZeD.Settings.save() end end)
    H.hooksOff()
    pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
    pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
end
-- the World window's map as found: its view, style, fold, key, list, tool, ink and note words
function H.mapBack()
    local f = S.found
    local w = RT.ww()
    if not (w and f.win) then return end
    if w._mapPopout then pcall(S.MT.closePopout, w, true) end
    w._mapToolsExpanded, w._mapKeyOpen, w._mapKeyPage, w._mapSideOpen = f.win.expanded, f.win.key, f.win.page, f.win.side
    w._mapActiveTool, w._mapActiveColor, w._mapEdit = f.win.tool, f.win.color, nil
    if w._mapTextEntry and f.win.note then pcall(function() w._mapTextEntry:setText(f.win.note) end) end
    local mp = w._worldMapPanel
    if mp and f.view then
        pcall(function() mp.mapAPI:centerOn(f.view.x, f.view.y) end)
        pcall(function() mp.mapAPI:setZoom(f.view.z) end)
    end
    if mp and mp.style ~= (f.md.style or ((f.md.paper == true) and "paper" or "survey")) then pcall(function() mp:requestStyle(f.md.style or ((f.md.paper == true) and "paper" or "survey")) end) end
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        H.home()
    end)
    Q.step(6, function() if S.car then pcall(ZEDQA_CAR_AWAY, S.car, S.carKey); S.carGone = S.car; S.car = nil end end)
    Q.waitMs(1500)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then return end
        S.swept = H.sweepNew()
        S.lost = H.unstash()
        local now, n = {}, 0
        for _, it in ipairs(H.all()) do local ft = H.ft(it); now[ft] = (now[ft] or 0) + 1 end
        for ft, was in pairs(f.types or {}) do
            for _ = 1, was - (now[ft] or 0) do
                local it = nil
                pcall(function() it = H.inv():AddItem(ft) end)
                if it then f.inv0[it] = true; n = n + 1 end
            end
        end
        S.refilled = n
        H.hands()
        H.home()
        H.padOff()
        local w = RT.ww()
        if w then w._maxWinW = f.maxW end
        if f.pair then RT.pairOpen() end
        if f.wwOpen and not H.wwOpen() then pcall(ZeD_WorldWindow.open, S.pn) end
    end)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then return end
        H.mapBack()
        if f.wtab then RT.worldTab(f.wtab) end
        if f.ctab then pcall(ZeD_CharacterWindow.openTab, S.pn, f.ctab) end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        -- the world map's store: every mark of his as found, none of the run's left
        local sigs = {}
        for _, s in ipairs(H.userSyms()) do sigs[#sigs + 1] = H.sig(s) end
        local same = #sigs == #f.sigs
        local missing = {}
        for _, a in ipairs(f.sigs) do
            local hit = false
            for _, b in ipairs(sigs) do if a == b then hit = true end end
            if not hit then same = false; missing[#missing + 1] = a end
        end
        Q.check(same and #H.newSyms() == 0, "put back: the world map's marks are exactly his own as found (each one's place and color)",
            #f.sigs .. " found, " .. #sigs .. " now, " .. tostring(S.removedAtEnd) .. " of the run's taken off at the end; changed or gone: " .. H.list(missing, 4))
        Q.check(S.w0 == nil and WorldMapVisited == S.realWMV and MapUtils.revealKnownArea == S.realRKA,
            "put back: no area of the map was made known or forgotten by the run (every reveal held back), the game's own calls handed back",
            #S.reveals .. " paper reveals and " .. #S.known .. " Show-on-map squares held back")
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (the pens, the eraser, the maps, the bags, the torch)", #S.made .. " given; left " .. H.list(left, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (his pens and erasers back)", "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, "
            .. tostring(S.refilled) .. " given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local md = H.md()
        local pinsOk = (f.pins == nil and md.ZeD_MapPinnedIcons == nil) or (f.pins ~= nil and type(md.ZeD_MapPinnedIcons) == "table" and table.concat(md.ZeD_MapPinnedIcons, ",") == table.concat(f.pins, ","))
        local readLeft = 0
        for _, id in ipairs(S.readAdded) do readLeft = readLeft + 1 end
        Q.check(md.ZeD_MapStyle == f.md.style and md.ZeD_MapPaper == f.md.paper and md.ZeD_MapAnnotations == f.md.ann and md.ZeD_MapNotesMoved == f.md.moved and pinsOk and readLeft == 0
            and H.hasTrait("ILLITERATE") == (f.illit == true),
            "put back: his map style, pins, old marks, visits, read pieces and literacy as found", "style " .. tostring(md.ZeD_MapStyle) .. ", pins ok " .. tostring(pinsOk) .. ", read pieces left " .. readLeft)
        local sb = SandboxVars.Map or {}
        Q.check(f.sbx == nil or (sb.AllowWorldMap == f.sbx.allow and sb.MapNeedsLight == f.sbx.light), "put back: the sandbox's AllowWorldMap and MapNeedsLight as found",
            tostring(sb.AllowWorldMap) .. ", " .. tostring(sb.MapNeedsLight))
        local opt = function(o) return H.optVal(o) end
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and ZeD.currentStatus == f.status and opt(ZeD.Settings.mapLightOption) == f.lightIdx
            and opt(ZeD.Settings.lookStyleOption) == f.liteIdx and opt(ZeD.Settings.safeModeOption) == f.safeIdx and opt(ZeD.Settings.uiScaleOption) == f.scaleIdx
            and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil,
            "put back: the theme, text size, status colors, light map, Lite, safe mode, UI scale, input lock and pointer as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", " .. tostring(ZeD.currentStatus) .. ", scale " .. tostring(opt(ZeD.Settings.uiScaleOption)) .. ", lock " .. H.lockFound())
        local mp = H.mp()
        local cx, cy = H.cxy()
        local viewOk = f.view == nil or mp == nil or (cx ~= nil and math.abs(cx - f.view.x) < 1 and math.abs(cy - f.view.y) < 1)
        local w = RT.ww()
        Q.check(viewOk and (w == nil or (w._activeTab == f.wtab or f.wtab == nil)) and H.pop() == nil and H.wwOpen() == (f.wwOpen == true) and UIWorldMap ~= nil and type(UIWorldMap.new) ~= "nil",
            "put back: the World window, its tab and the drawer map's view as found, nothing unfolded",
            "tab " .. tostring(w and w._activeTab) .. " (found " .. tostring(f.wtab) .. "), the view " .. tostring(viewOk) .. (f.view and f.view.mp ~= mp and " (the drawer map was made again during the run: the found center and zoom set on it)" or ""))
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.p:getVehicle() == nil and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, on foot, nothing queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 - (S.excused or 0) == S.err0, "the Maps tab run ran with no Lua error (B13's staged build failure excused)", (e1 - S.err0) .. " new, " .. tostring(S.excused or 0) .. " of them B13's staged throw")
        else Q.skip("the Maps tab run's Lua error count", "the game's Lua error count cannot be read here") end
    end)
    Q.step(10, function()
        local f = S.found
        S.guard = false
        S.holdOn = false
        if f.recorded then
            pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
            pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end)
            if f.pair == false and RT.isOpen() then RT.pairShut() end
        end
        for _, w in ipairs({ RT.ww() or false, RT.cw() or false }) do if w then w._outSince = nil end end
    end)
end

-- ===================================================================== the run
S.setup()
C.mp1()
C.mp15()
C.mp2()
C.mp3()
C.mp5()
C.mp6()
C.mp7()
C.mp8()
C.mp12()
C.mp17()
C.mp18()
C.mp19()
C.mp20()
C.mp21()
C.mp22()
C.mp23()
C.mp24()
C.mp25()
C.mp9()
C.mp26()
C.mp27()
C.mp28()
C.mp29()
C.mp30()
C.mp31()
C.mp32()
C.mp33()
C.mp34()
C.mp36()
C.mp37()
C.mp38()
C.mp39()
C.mp40()
C.mp42()
C.mp46()
C.mp47()
C.mp48()
C.mp49()
C.mp50()
C.mp52()
C.mp53()
C.mp54()
C.mp55()
C.mp56()
C.mp57()
C.mp60()
C.mp61()
C.mp62()
C.mp63()
C.mp65()
C.mp66()
C.night()
C.car()
C.b13()
C.safe()
C.mp64()
C.notes()
S.buildPutBack()
Q.start()
