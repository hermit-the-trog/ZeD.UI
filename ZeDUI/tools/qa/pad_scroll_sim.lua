-- ZeDUI/tools/qa/pad_scroll_sim.lua  (Nov 16 2026, Build): punch list 257, 258 and 262, with no game running.
--   RULE     258's shared pad scroll (FocusManager.lua, PAD SCROLL): the real FocusManager.lua and SpatialNav.lua on
--            Lua 5.1 stubs. A stop in a scrolled view with more of it that way scrolls the view a step and keeps the
--            focus, unless the next stop of the same view is in sight or a step away; the move leaves the view only
--            once its end shows. The dry run (previewMove) never scrolls.
--   CARD     the item card's Down (ItemCard.lua's gpDpad, run on stubs): the footer's verbs wait until the card is
--            read to its foot
--   TOP      257: the station select scrolls the view to the very top (Stations.lua's followFocus, run on stubs)
--   WIRED    the places 257 and 258 name use it: the radio faces, object cards, Server tab, ticket and mail cards,
--            Mechanics, Furniture, the main menu's panes and Traits; 262: the Controller map no longer offers layout
-- Run from the repo root:  lua51 ZeDUI/tools/qa/pad_scroll_sim.lua
-- It prints FAIL lines and a last line "pad_scroll_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_scroll_sim%.lua$", "")
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
local function noop() end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end

Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
LuaEventManager = { AddEvent = noop }
triggerEvent = noop
require = noop
getTimestampMs = function() return 100000 end
getSoundManager = function() return { playUISound = noop } end
isDebugEnabled = function() return false end
getCore = function() return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end } end
getSpecificPlayer = function() return nil end
getJoypadData = function() return nil end
getMaxActivePlayers = function() return 4 end
JoypadState = { players = {}, joypads = {}, controllers = {} }
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD." then return end realPrint(s) end
ZeD = { Input = {}, T = { px = function(n) return n end }, uiSound = noop }

local okN, errN = pcall(dofile, Z .. "Input/SpatialNav.lua")
check("SpatialNav.lua loads", okN, errN)
local okF, errF = pcall(dofile, Z .. "Input/FocusManager.lua")
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus

local function panel(x, y, w, h)
    return { getX = function() return x end, getY = function() return y end,
             getWidth = function() return w end, getHeight = function() return h end,
             isVisible = function() return true end }
end

-- A tab body: a view 100..300 (200 tall) scrolled `off` of 400 (span 400); its stops at content y (minus off), a
-- header stop over it and a band stop under it, both outside the view. stops: content ys of the body's stops.
local function makeWin(off, stops)
    local v = { off = off }
    local view = Focus.scrollView("body", 100, 200, off, 400, function(n) v.off = n end)
    local els = { { id = "head", x = 0, y = 60, w = 100, h = 20 } }
    for i, cy in ipairs(stops) do
        els[#els + 1] = { id = "s" .. i, x = 0, y = 100 + cy - off, w = 100, h = 20, scrollView = view }
    end
    els[#els + 1] = { id = "band", x = 0, y = 320, w = 100, h = 20 }
    local w = { _zedLabel = "sim", _focusIdx = 1,
                _tabPanel = panel(0, 0, 400, 400),
                _focusRing = { { zone = "charTabContent", focusable = true, elements = els, focusedElementIdx = 1 } } }
    return w, v
end
local function focusOn(w, id)
    for zi, z in ipairs(w._focusRing) do
        for ei, e in ipairs(z.elements) do
            if e.id == id then w._focusIdx = zi; z.focusedElementIdx = ei; return true end
        end
    end
    return false
end
local function at(w)
    local z = w._focusRing[w._focusIdx]
    local e = z and z.elements[z.focusedElementIdx]
    return e and e.id or "?"
end
local function press(w, from, dir)
    w._navLast = nil
    focusOn(w, from)
    local ok, err = pcall(Focus.dispatchJoypadDir, w, dir, nil)
    if not ok then return "threw " .. tostring(err) end
    return at(w)
end

-- ---------------------------------------------------------------------------
section("RULE")
-- ---------------------------------------------------------------------------
if Focus and Focus.scrollView and Focus.padScroll and Focus.dispatchJoypadDir then
    -- two stops near the top of a long body (content 0 and 40), the rest of it words
    local w, v = makeWin(0, { 0, 40 })
    check("Down from the last stop, more below: the view scrolls a step and the focus stays",
        press(w, "s2", "down") == "s2" and v.off == 60, at(w) .. " off " .. tostring(v.off))
    w, v = makeWin(400, { 0, 40 })
    -- (scrolled to its end: the stops sit above the view; Down from the last leaves for the band)
    check("Down at the end of the view: the move leaves (the band)", press(w, "s2", "down") == "band" and v.off == 400,
        at(w) .. " off " .. tostring(v.off))
    w, v = makeWin(120, { 0, 40 })
    check("Up from the first stop with more above: the view scrolls up a step", press(w, "s1", "up") == "s1" and v.off == 60,
        at(w) .. " off " .. tostring(v.off))
    w, v = makeWin(0, { 0, 40 })
    check("Up from the first stop at the top: the move leaves (the header)", press(w, "s1", "up") == "head" and v.off == 0,
        at(w) .. " off " .. tostring(v.off))
    -- the next stop in sight: an ordinary move
    w, v = makeWin(0, { 0, 40, 120 })
    check("Down to a stop in sight: the focus moves, no scroll", press(w, "s2", "down") == "s3" and v.off == 0,
        at(w) .. " off " .. tostring(v.off))
    -- the next stop a step past the view's foot: the focus moves (its follow brings it in)
    w, v = makeWin(0, { 0, 40, 220 })
    check("Down to a stop a step out of sight: the focus moves", press(w, "s2", "down") == "s3" and v.off == 0,
        at(w) .. " off " .. tostring(v.off))
    -- the next stop far below (a long letter between two stops): the view scrolls first
    w, v = makeWin(0, { 0, 40, 380 })
    check("Down to a stop far below: the view scrolls a step first", press(w, "s2", "down") == "s2" and v.off == 60,
        at(w) .. " off " .. tostring(v.off))
    -- held Down reads on to the end, then leaves
    w, v = makeWin(0, { 0, 40 })
    focusOn(w, "s2")
    local n = 0
    while at(w) == "s2" and n < 20 do
        local ww, vv = makeWin(v.off, { 0, 40 })   -- (the window builds its stops again as the view scrolls)
        ww._focusRing[1].focusedElementIdx = w._focusRing[1].focusedElementIdx
        w, v.off = ww, v.off
        local view = w._focusRing[1].elements[3].scrollView
        view.set = function(x) v.off = x end
        pcall(Focus.dispatchJoypadDir, w, "down", nil)
        n = n + 1
    end
    check("held Down: 7 steps to the end (400 / 60), then the band", n == 8 and at(w) == "band" and v.off == 400,
        n .. " presses, " .. at(w) .. " off " .. tostring(v.off))
    -- a stop fixed outside the view that reads it (scrollFixed: a band's verb) moves from where it is
    w, v = makeWin(400, { 0, 40 })
    local bandEl = w._focusRing[1].elements[4]
    bandEl.scrollView, bandEl.scrollFixed = w._focusRing[1].elements[3].scrollView, true
    check("scrollFixed: Up from the band reads the view back up (it sits where it is, under the view)", press(w, "band", "up") == "band" and v.off == 340,
        at(w) .. " off " .. tostring(v.off))
    w, v = makeWin(200, { 0, 40 })
    bandEl = w._focusRing[1].elements[4]
    bandEl.scrollView, bandEl.scrollFixed = w._focusRing[1].elements[3].scrollView, true
    check("scrollFixed: Down from the band with more below reads on", press(w, "band", "down") == "band" and v.off == 260,
        at(w) .. " off " .. tostring(v.off))
    -- the dry run never scrolls
    w, v = makeWin(0, { 0, 40 })
    focusOn(w, "s2")
    local r = Focus.previewMove(w, "down")
    check("previewMove: no scroll, and it names where the move would land", v.off == 0 and r.id == "band", tostring(r.id) .. " off " .. tostring(v.off))
    -- a stop with no view: nothing changes
    w, v = makeWin(0, { 0, 40 })
    w._focusRing[1].elements[3].scrollView = nil
    check("a stop with no view: the move goes as before", press(w, "s2", "down") == "band" and v.off == 0, at(w))
    -- a view that fits makes no view
    check("scrollView of a view that fits is nil", Focus.scrollView("x", 0, 100, 0, 0, noop) == nil)
    -- Left / Right never scroll
    w, v = makeWin(0, { 0, 40 })
    focusOn(w, "s2")
    pcall(Focus.dispatchJoypadDir, w, "right", nil)
    check("Right never scrolls", v.off == 0, v.off)
    -- tagScroll keeps a stop's own view
    local own = { key = "own" }
    local t = Focus.tagScroll({ { id = "a" }, { id = "b", scrollView = own } }, { key = "v" })
    check("tagScroll: tags the untagged, keeps an own view", t[1].scrollView.key == "v" and t[2].scrollView == own)
    -- padScroll alone (the main menu's use)
    local off = 0
    local pv = Focus.scrollView("p", 0, 100, 0, 150, function(x) off = x end)
    check("padScroll: no next stop, more below: scrolls", Focus.padScroll(pv, "down", nil, nil) == true and off == 50, off)
    off = 0
    check("padScroll: the next stop in the same view in sight: lets the move go",
        Focus.padScroll(pv, "down", pv, { y = 80, h = 20 }) == false and off == 0)
    check("padScroll: the next stop in another view: scrolls", Focus.padScroll(pv, "down", { key = "q" }, { y = 80, h = 20 }) == true)
else
    check("Focus.scrollView / padScroll / dispatchJoypadDir exist", false)
end

-- ---------------------------------------------------------------------------
section("CARD")
-- ---------------------------------------------------------------------------
do
    local src = readFile(Z .. "ItemCard.lua") or ""
    local body = src:match("\n(function ZeD_ItemCard:gpDpad%(.-\nend)\n")
    check("ItemCard: gpDpad found", body ~= nil)
    if body then
        ZeD_ItemCard = {}
        local okC, errC = pcall(function() assert(loadstring(body))() end)
        check("ItemCard: gpDpad loads", okC, errC)
        ZeD.SpatialNav = ZeD.SpatialNav   -- (the real one, loaded above)
        local function card(scroll, maxScroll)
            local c = { _scrollPixels = scroll, _contentH = maxScroll + 200, _headH = 0,
                        _sb = { visible = maxScroll > 0, setScrollPos = noop } }
            function c:viewH() return 200 end
            function c:scrollToNextDisclosure() end   -- (no section left below: the step does it)
            function c:scrollToPrevDisclosure() end
            return c
        end
        local body1 = { id = "fact", x = 0, y = 50, w = 100, h = 20 }
        local foot = { id = "verb_eat", x = 0, y = 260, w = 100, h = 20, isFooter = true }
        local zone = { zone = "charItemCard", elements = { body1, foot } }
        local realGFZ = Focus.getFocusedZone
        Focus.getFocusedZone = function() return zone end
        local c = card(0, 300)
        local okR, r = pcall(ZeD_ItemCard.gpDpad, c, {}, body1, "down", "charItemCard")
        check("a long card: Down from its last control scrolls it on, not to the verbs", okR and r == true and c._scrollPixels == 60,
            tostring(r) .. " scroll " .. tostring(c._scrollPixels))
        c = card(300, 300)
        okR, r = pcall(ZeD_ItemCard.gpDpad, c, {}, body1, "down", "charItemCard")
        check("read to its foot: Down goes on to the verbs (the spatial move)", okR and r == false, tostring(r))
        -- the control scrolled out above the card's head (the action strip now lies under it): the verbs, not the strip
        local strip = { id = "strip_main", x = 0, y = 10, w = 100, h = 20, isStrip = true }
        local gone = { id = "fact", x = 0, y = -200, w = 100, h = 20 }
        zone.elements = { strip, gone, foot }
        local realFW, went = Focus.focusWhere, nil
        Focus.focusWhere = function(w, zn, pred)
            for _, x in ipairs(zone.elements) do if pred(x) then went = x.id; return x end end
            return nil
        end
        c = card(300, 300)
        okR, r = pcall(ZeD_ItemCard.gpDpad, c, {}, gone, "down", "charItemCard")
        check("scrolled out above the head, read to the foot: Down lands on the verbs, not the strip",
            okR and r == true and went == "verb_eat", tostring(r) .. " " .. tostring(went))
        went = nil
        c = card(100, 300)
        okR, r = pcall(ZeD_ItemCard.gpDpad, c, {}, gone, "down", "charItemCard")
        check("scrolled out above the head, more to read: Down reads on", okR and r == true and went == nil and c._scrollPixels == 160,
            tostring(r) .. " " .. tostring(went) .. " scroll " .. tostring(c._scrollPixels))
        Focus.focusWhere = realFW
        zone.elements = { body1, foot }
        c = card(0, 0)
        okR, r = pcall(ZeD_ItemCard.gpDpad, c, {}, body1, "down", "charItemCard")
        check("a short card: Down goes to the verbs at once", okR and r == false, tostring(r))
        Focus.getFocusedZone = realGFZ
    end
end

-- ---------------------------------------------------------------------------
section("TOP")
-- ---------------------------------------------------------------------------
do
    local src = readFile(Z .. "Stations.lua") or ""
    local body = src:match("\n(function ST%.followFocus%(.-\nend)\n")
    check("Stations: followFocus found", body ~= nil)
    if body then
        ST = {}
        local okS, errS = pcall(function() assert(loadstring(body))() end)
        check("Stations: followFocus loads", okS, errS)
        local sc = { scrollPos = 0.5 }
        function sc:setScrollPos(p) self.scrollPos = p end
        local state = { _lastZones = { { fid = "craft:a:knob", y = 400, h = 20 } } }
        ST.followFocus(state, sc, "craft:stDrop", 100, 200, 600)
        check("the station select scrolls the view to the very top", sc.scrollPos == 0, sc.scrollPos)
        sc.scrollPos = 0
        state._followId = nil
        ST.followFocus(state, sc, "craft:a:knob", 100, 200, 600)
        check("a control below still scrolls into view", sc.scrollPos > 0, sc.scrollPos)
    end
end

-- ---------------------------------------------------------------------------
section("WIRED")
-- ---------------------------------------------------------------------------
do
    local function has(file, s) return (readFile(Z .. file) or ""):find(s, 1, true) ~= nil end
    -- 257
    check("RadioTab: a header stop scrolls the face to the top", has("RadioTab.lua", 'fid == "radio:full" or fid:sub(1, 10) == "radio:tab:"'))
    check("RadioTab: the topmost face stop scrolls to the very top", has("RadioTab.lua", "hh.y <= topY + 1 and cy + hh.h <= h then newOff = 0"))
    check("ObjectCards: a header stop scrolls the body to the top", has("ObjectCards.lua", "z.fid == target and not z.body and z.y + (z.h or 0) <= viewY + 1"))
    check("ObjectCards: the body's topmost stop scrolls to the very top", has("ObjectCards.lua", "z.y <= topY + 1 and cy + z.h <= viewH - T.px(8) then newOff = 0"))
    -- 258, in game
    check("ServerTab: the list is a scrolled view", has("ServerTab.lua", 'Fo.scrollView("srv"'))
    check("ServerTab: the follow runs once per stop", has("ServerTab.lua", "st._followId ~= fe.id"))
    check("TicketCards: a card's body is a scrolled view", has("ZeD_TicketCards.lua", 'Fo.scrollView("tk"'))
    check("TicketCards: the follow runs once per stop", has("ZeD_TicketCards.lua", "if t._followId == fe.id then fe = nil"))
    check("Mechanics: the right column is a scrolled view", has("MechanicsTab.lua", 'Fo.scrollView("mech:right"'))
    check("Mechanics: its follow runs once per stop", has("MechanicsTab.lua", "s._followRight ~= gpId"))
    check("Furniture: the body is a scrolled view", has("FurnitureTab.lua", 'Fo.scrollView("fur"'))
    -- 258, main menu
    check("main menu: joyDir runs the pad scroll", has("ZeD_MainMenu.lua", "Fo.padScroll(cur.scrollView, dir"))
    check("main menu: MM.panePad and MM.paneView", has("ZeD_MainMenu.lua", "function MM.panePad(") and has("ZeD_MainMenu.lua", "function MM.paneView("))
    check("main menu: a read stop draws its mark only", has("ZeD_MainMenuSaves.lua", "if b.readStop then"))
    local n = 0
    for _, f in ipairs({ "ZeD_MainMenuMods.lua", "ZeD_MainMenuWorld.lua", "ZeD_MainMenuSpawn.lua", "ZeD_MainMenuMail.lua",
                         "ZeD_MainMenuDescEdit.lua", "ZeD_MainMenuWorkshop.lua" }) do
        if has(f, "MM.panePad(self") then n = n + 1 else check(f .. " uses MM.panePad", false) end
    end
    check("the six main menu panes use MM.panePad", n == 6, n)
    check("Mods: the pane follow skips a press the pad scroll kept", has("ZeD_MainMenuMods.lua", "if self.focusId == before then return end"))
    check("Traits: the columns use the pad scroll", has("ZeD_MainMenuTraits.lua", "Fo.padScroll(v, dir"))
    -- 262
    check("Controller map: Select row says the wheel only", has("ZeD_ControllerMap.lua", '"UI_ZeD_CMap_SelWheel"')
        and not has("ZeD_ControllerMap.lua", '"UI_ZeD_CMap_View"'))
    check("Options: the pad figure's Select help says the wheel only", has("ZeD_MainMenuOptionsSub.lua", 'help = "UI_ZeD_CMap_SelWheel"'))
    local en = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
    local w = en:match('"UI_ZeD_CMap_SelWheel"%s*:%s*"([^"]*)"')
    check("EN: the new words have no layout", w ~= nil and not w:lower():find("layout"), w)
end

print = realPrint
print("pad_scroll_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
