-- ZeDUI/tools/qa/sb_edges.lua  (Nov 25 2026, QA; tag sb_edges): the scroll bars' edges, in the running game on the QA
-- save. The director: "Can you pay attention to scroll bar placement? In some cases it looks like it's not all the way
-- up against the edge of the frame. I've even seen it where there's a pixel gap between the scroll bar edge and the
-- frame edge. Should all just be one consistent 1 pixel line on the edges, right?" The rule: a scroll bar's outer edge
-- shares the frame's line, one line on the right, top and bottom, no gap and no doubled line. QA's audit found two
-- faults: a GAP after a text-size change (a bar kept the width it was built with) and a DOUBLED line everywhere (the
-- bar's own outline one hairline inside the divider, heading rule or footer rule). Build's fix (fix/scrollbars,
-- c5e964b54): ZeD_ScrollbarState reads width and arrowH from T.sp.scrollbarW when a caller has not set them, its draw
-- reaches one hairline past right, top and bottom (inRight / inTop / inBottom opt out, reserveBottom keeps the bottom
-- off a grow box, nothing past the panel's own edge), and Animals, ZeD_Prompt and the Workshop bar are 14u.
-- Run after zedqa_prelude.lua and rt_kit.lua (sb_edges.txt). grep "ZEDQA sb_edges".
--
-- How it reads a bar: ZeD_ScrollbarState.draw is wrapped while the script runs (put back at the end), so every bar that
-- DRAWS in a frame is recorded with the panel it drew on: its state (x, y, width, arrowH, height, reserveBottom, the
-- in* flags, the width and arrowH the caller set itself), the panel's place on the screen (getAbsoluteX / Y and its
-- x / y scroll) and its size, and the sides the draw reaches past (outR / outT / outB, the draw's own rule worked out
-- again here). The surface's own bar is the object the tab keeps (win._equipScroll, win._healthScroll, the list's
-- content._scroll, the card's _sb, the craft state's scroll, win._zedBars[key] for Molecules.scrollBar's bars), else
-- the bar drawn on the surface's panel.
-- At each surface:
--   * the bar shows (the content scrolls); where it does not, the surface is given more to list (things carried,
--     things on the floor, notes in Messages), then its window is made shorter (put back right after); a bar that
--     still does not show is a SKIP, said why
--   * STATE line: the bar's x, y, width, arrowH, height, the in* flags, reserveBottom, the caller's own width, the panel
--   * CHECK: its width is T.sp.scrollbarW (the token at that moment), in every pass; in the Large pass this is the
--     direct check of fault 1 (the size switched within the session, the bars built before it)
--   * a picture Zomboid/Screenshots/sb_<surface>_<theme>_<textsize>_<w>x<h>.png (a "-short" surface: the window was
--     made shorter for it), and one RECT line per bar drawn in that frame:
--       ZEDQA sb_edges RECT pic=<picture> bar=<name> target=0|1 x= y= w= h= hl= aH= rb= inR= inT= inB= outR= outT=
--       outB= line=<rrggbb> frame=<rrggbb>
--     x, y: the bar's own rect on the screen in pixels; the scorer (sb_judge.py) finds the bar in the picture from it
-- Surfaces (pass A: Dark at the text size found):
--   Character window: Equipment (List view, every group open), Health, Thermal, Skills, Identity, Journal (its diary),
--   Cooking; the inventory list; the Equipment card on the 480 drawer and on the 220 (half) drawer (the width cap made
--   too narrow for the full card, eq_tab's halfOn); World window: the ground list (the floor shown), Crafting,
--   Foraging, Animals (when the tab is offered and lists something); the Messages window (QA notes filed under
--   "ZeD QA scroll test", cleared after); the Vehicle tab's parts list (Mechanics) on a car spawned on the drag strip
--   (the prelude's ZEDQA_CAR_WAIT, opened the mechanics key's way, MechanicsTab.openFromAction), with MECH lines for
--   Build: s.maxScroll, s.scrollY, the list's body height and total, win._zedBars["mech:list"] on the World window and
--   on the panel, and whether it drew. The Lua console needs nothing (its bars sit at the panel's edge).
-- Pass B: the Character tabs and the inventory again in the other text size (Large when Small was found), switched
-- in this session; pass C: the same in High contrast at the size found.
-- Puts back: the theme and the text size, the width cap, every window's height, the Equip view and its folds, the card,
-- the Journal's page, the bars' scroll, the World window's container, both windows' tabs and layout, Messages (shut
-- if it was shut, its page as found, the QA notes cleared), every thing it gave or laid on the floor, the car (taken
-- away, the look ended), him where he stood, the pointer and the draw wrapper.
if not RT then print("ZEDQA sb_edges ERR rt_kit.lua did not run first"); print("ZEDQA sb_edges DONE"); return end
local Q = RT.make("sb_edges")
Q.maxMs = 1380000                    -- (the runner gives this script 1500 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, madeSet = {}, floorMade = {}, shots = {}, frame = 0,
            errs = 0, shrinks = {}, rectN = 0, t0 = getTimestampMs() }

-- ===================================================================== constants
S.TAG = "sb_edges"
S.MSG = "ZeD QA scroll test"
S.GROUPS = { "head", "torso", "arms", "legs", "held" }
S.CHAR = {
    { id = "equip", key = "equip", obj = "_equipScroll" },
    { id = "health", key = "health", obj = "_healthScroll" },
    { id = "thermal", key = "thermal", obj = "_thermalScroll" },
    { id = "skills", key = "skills", obj = "_skillsScroll" },
    { id = "identity", key = "identity", obj = "_identityScroll" },
    { id = "journal", key = "journal", obj = "_journalScroll" },
}
-- light things to list (only the ones this game knows are used)
S.STOCK = { "Base.Apple", "Base.Banana", "Base.Orange", "Base.Lemon", "Base.Carrots", "Base.Potato", "Base.Tomato",
            "Base.Pen", "Base.Pencil", "Base.Notebook", "Base.Book", "Base.Magazine", "Base.Newspaper", "Base.Battery",
            "Base.Lighter", "Base.Matches", "Base.Candle", "Base.Bandage", "Base.RippedSheets", "Base.Thread",
            "Base.Needle", "Base.Scissors", "Base.Spoon", "Base.Fork", "Base.ButterKnife", "Base.Mug", "Base.Twine",
            "Base.Nails", "Base.Screws", "Base.DuctTape", "Base.Glue", "Base.Screwdriver", "Base.TinOpener",
            "Base.Crisps", "Base.Chocolate", "Base.Cigarettes", "Base.Comb", "Base.Toothbrush", "Base.Soap2",
            "Base.Paperclip", "Base.Eraser", "Base.SheetPaper2", "Base.Rope", "Base.KitchenKnife", "Base.Hammer" }
S.CARS = { "Base.CarNormal", "Base.PickUpTruck" }
S.BESIDE = { { -3, 0 }, { 3, 0 }, { -3, 1 }, { 3, -1 }, { 0, -5 }, { 0, 5 } }
S.HEX = "0123456789abcdef"
-- the three passes (sizes filled in at setup: A and C at the size found, B the other size)
S.PASS_A = { theme = "dark", key = "A" }
S.PASS_B = { theme = "dark", key = "B", changed = true }
S.PASS_C = { theme = "hicon", key = "C" }

-- ===================================================================== small helpers (et_calls')
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.note(s) Q.say("NOTE " .. tostring(s)) end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.waitIdle(n) Q.step(n, function() end) end
function S.i(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x + 0.5)) end
function S.n(v) local x = tonumber(v); if x == nil then return 0 end; return math.floor(x + 0.5) end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
function S.known(ft)
    local ok = false
    if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end
    return ok
end
function S.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function S.hex2(v)
    local n = math.floor((tonumber(v) or 0) * 255 + 0.5)
    if n < 0 then n = 0 elseif n > 255 then n = 255 end
    local hi = math.floor(n / 16)
    local lo = n - hi * 16
    return string.sub(S.HEX, hi + 1, hi + 1) .. string.sub(S.HEX, lo + 1, lo + 1)
end
function S.hexC(c)
    if type(c) ~= "table" then return "none" end
    return S.hex2(c.r) .. S.hex2(c.g) .. S.hex2(c.b)
end
function S.isItem(it) return it ~= nil and instanceof(it, "InventoryItem") end

-- ===================================================================== things (et_calls')
function S.loose(it)
    if not S.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
end
function S.removeItem(it)
    if not S.isItem(it) then return end
    S.loose(it)
    local wo = it:getWorldItem()
    if wo then
        local sq = wo:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
        pcall(function() wo:removeFromWorld() end)
        pcall(function() wo:removeFromSquare() end)
        pcall(function() it:setWorldItem(nil) end)
    end
    local c = it:getContainer()
    if c then pcall(function() c:Remove(it) end) end
end
function S.mark(it, list)
    if not S.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    list[#list + 1] = it
    S.madeSet[it] = true
    return it
end
function S.where(it) if not S.isItem(it) then return nil end; return it:getContainer() end
function S.onFloor(it) if not S.isItem(it) then return false end; return it:getWorldItem() ~= nil end
-- things carried, to make a list long (only when it does not scroll already)
function S.stockInv()
    local n = 0
    for _, ft in ipairs(S.STOCK) do
        if S.known(ft) then
            local it = RT.give(ft)
            if S.mark(it, S.made) then n = n + 1 end
        end
    end
    return n
end
-- things on his square's floor, for the ground list
function S.stockFloor()
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())) end)
    if not (sq and instanceof(sq, "IsoGridSquare")) then return 0, "no square under him" end
    local n = 0
    for i, ft in ipairs(S.STOCK) do
        if S.known(ft) then
            local it = nil
            local fx = 0.2 + (i - math.floor(i / 6) * 6) * 0.1
            pcall(function() it = sq:AddWorldInventoryItem(ft, fx, 0.5, 0) end)
            if S.mark(it, S.floorMade) then n = n + 1 end
        end
    end
    pcall(function() triggerEvent("OnContainerUpdate") end)
    return n
end

-- ===================================================================== the pointer and pictures (et_calls')
function S.park(on)
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
-- a picture, then one RECT line per bar drawn in the frame before it (T.rec: the surface's own bar)
function S.shot(name, what, gate, T)
    local st = {}
    Q.step(1, function()
        if S.dead then return end
        if gate and not gate() then st.off = true; return end
        st.mine = S.parked == nil
        S.park(true)
    end)
    Q.step(4, function()
        if st.off then return end
        if S.dead then if st.mine then S.park(false) end; return end
        local nm = (type(name) == "function") and name() or name
        local file = tostring(nm) .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then
            S.shots[#S.shots + 1] = file
            Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. tostring(what))
            S.printRects(tostring(nm), T)
        else Q.say("NOTE the picture " .. tostring(nm) .. " was not taken: " .. tostring(e)) end
        if st.mine then S.park(false) end
    end)
    Q.waitMs(1500)
end

-- ===================================================================== the theme and the text size (et_calls')
function S.theme(key)
    local o = S.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function S.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = S.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function S.sizeSet(key)
    local o = S.zopt("textSize")
    local i = nil
    for k, v in ipairs(ZeD.Settings.sizeKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function S.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local f = S.found
    local o = S.zopt("textSize")
    if o and f.sizeIdx then pcall(function() o:setValue(f.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, f.size)
end

-- ===================================================================== the bars as drawn
function S.count() S.frame = S.frame + 1 end
function S.spyOn()
    if S.spy then return true end
    local SB = ZeD_ScrollbarState
    if type(SB) ~= "table" or type(rawget(SB, "draw")) ~= "function" then return false end
    local sp = { own = rawget(SB, "draw"), recs = {} }
    SB.draw = function(self, panel)
        if type(self) == "table" and self.visible and type(panel) == "table" then
            local ok, e = pcall(S.spyRec, sp, self, panel)
            if not ok and not sp.said then sp.said = true; Q.say("ERR the bar recorder threw: " .. tostring(e)) end
        end
        return sp.own(self, panel)
    end
    S.spy = sp
    return true
end
function S.spyOff()
    local sp = S.spy
    if not sp then return end
    S.spy = nil
    if type(ZeD_ScrollbarState) == "table" then ZeD_ScrollbarState.draw = sp.own end
end
-- one bar as it draws: its state, its panel's place, the sides its draw reaches past (Molecules.lua's own rule)
function S.spyRec(sp, sb, panel)
    local T = ZeD.T
    local hl = T.px(1)
    local r = { sb = sb, panel = panel, frame = S.frame, x = sb.x or 0, y = sb.y or 0, w = sb.width or 0, h = sb.height or 0,
                aH = sb.arrowH or 0, rb = sb.reserveBottom or 0, inR = sb.inRight and true or false,
                inT = sb.inTop and true or false, inB = sb.inBottom and true or false,
                rawW = rawget(sb, "width"), rawA = rawget(sb, "arrowH"), hl = hl, pos = sb.scrollPos, ratio = sb.barSizeRatio }
    r.ax, r.ay = panel:getAbsoluteX(), panel:getAbsoluteY()
    r.xs, r.ys = 0, 0
    if type(panel.getXScroll) == "function" then r.xs = panel:getXScroll() or 0 end
    if type(panel.getYScroll) == "function" then r.ys = panel:getYScroll() or 0 end
    r.pw = (type(panel.getWidth) == "function") and panel:getWidth() or nil
    r.ph = (type(panel.getHeight) == "function") and panel:getHeight() or nil
    local outR = r.inR and 0 or hl
    local outT = r.inT and 0 or hl
    local outB = (r.inB or r.rb > 0) and 0 or hl
    if r.pw and r.x + r.w + outR > r.pw then outR = 0 end
    if r.y - outT < 0 then outT = 0 end
    if r.ph and r.y + r.h + outB > r.ph then outB = 0 end
    r.outR, r.outT, r.outB = outR, outT, outB
    r.sx = S.n(r.ax + r.xs + r.x)
    r.sy = S.n(r.ay + r.ys + r.y)
    sp.recs[sb] = r
end
-- the bars drawn in the last whole frame (none when nothing drew lately)
function S.drawn()
    local sp = S.spy
    if not sp then return {} end
    local top = -1
    for _, r in pairs(sp.recs) do if r.frame > top then top = r.frame end end
    local out = {}
    if top < S.frame - 3 then return out end
    for _, r in pairs(sp.recs) do if r.frame == top then out[#out + 1] = r end end
    table.sort(out, function(a, b) return a.sx * 100000 + a.sy < b.sx * 100000 + b.sy end)
    return out
end
-- a bar's name for the RECT and STATE lines (the objects ZeD keeps, then the _zedBars keys, then the panel's name)
function S.nameOf(r)
    local sb = r.sb
    local cw, ww = RT.cw(), RT.ww()
    local known = {}
    if cw then
        for _, c in ipairs(S.CHAR) do known[#known + 1] = { cw[c.obj], "char:" .. c.key } end
        known[#known + 1] = { cw._mainContent and cw._mainContent._scroll, "char:inventory" }
        known[#known + 1] = { cw._itemCard and cw._itemCard._sb, "char:itemcard" }
        local ec = S.ecard()
        known[#known + 1] = { ec and ec._sb, "char:equipcard" }
    end
    if ww then
        known[#known + 1] = { ww._mainContent and ww._mainContent._scroll, "world:ground" }
        known[#known + 1] = { ww._itemCard and ww._itemCard._sb, "world:itemcard" }
        known[#known + 1] = { ww._forageScroll, "world:forage" }
        known[#known + 1] = { ww._animalsScroll, "world:animals" }
        local cs = ww._craftState
        if cs then
            known[#known + 1] = { cs.scroll, "world:craft:list" }
            known[#known + 1] = { cs.altScroll, "world:craft:alt" }
            known[#known + 1] = { cs.cardScroll, "world:craft:card" }
        end
    end
    local mw = S.msgWin()
    if mw then known[#known + 1] = { mw._sb, "messages" } end
    for _, k in ipairs(known) do if k[1] ~= nil and k[1] == sb then return k[2] end end
    for _, own in ipairs({ { cw, "char" }, { ww, "world" }, { r.panel, "panel" } }) do
        local bars = own[1] and own[1]._zedBars
        if type(bars) == "table" then
            for key, b in pairs(bars) do if b == sb then return own[2] .. ":bars:" .. tostring(key) end end
        end
    end
    local pl = tostring(r.panel._zedLabel or r.panel.Type or "panel")
    return (string.gsub("bar@" .. pl, "[^%w:%-%.@]", "_"))
end
function S.colors()
    local T = ZeD.T
    return S.hexC(T.borderS), S.hexC(T.border)
end
function S.printRects(pic, T)
    local recs = S.drawn()
    local line, frame = S.colors()
    for i, r in ipairs(recs) do
        S.rectN = S.rectN + 1
        local tgt = (T and T.rec and T.rec.sb == r.sb) and 1 or 0
        Q.say("RECT pic=" .. pic .. " bar=" .. S.nameOf(r) .. " target=" .. tgt .. ((i == 1) and " first=1" or "")
            .. " x=" .. r.sx .. " y=" .. r.sy .. " w=" .. S.i(r.w) .. " h=" .. S.i(r.h) .. " hl=" .. S.i(r.hl) .. " aH=" .. S.i(r.aH)
            .. " rb=" .. S.i(r.rb) .. " inR=" .. (r.inR and 1 or 0) .. " inT=" .. (r.inT and 1 or 0) .. " inB=" .. (r.inB and 1 or 0)
            .. " outR=" .. S.i(r.outR) .. " outT=" .. S.i(r.outT) .. " outB=" .. S.i(r.outB) .. " line=" .. line .. " frame=" .. frame)
    end
    if #recs == 0 then Q.say("NOTE " .. pic .. ": no bar drew in the frame before the picture") end
end
function S.barText(sb)
    if type(sb) ~= "table" then return "none" end
    return "visible=" .. tostring(sb.visible) .. " x=" .. S.i(sb.x) .. " y=" .. S.i(sb.y) .. " width=" .. S.i(sb.width)
        .. " height=" .. S.i(sb.height) .. " arrowH=" .. S.i(sb.arrowH) .. " (caller's width " .. tostring(rawget(sb, "width")) .. ")"
end

-- ===================================================================== windows
function S.ecard()
    local w = RT.cw()
    local p = w and w._drawerPanel
    return p and p._equipCard or nil
end
function S.msgWin()
    local W = ZeD.MessagesWindow
    if not (W and W.get) then return nil end
    return W.get(S.pn)
end
function S.isHalf() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
function S.geo(win)
    if not win then return "none" end
    return S.i(win:getX()) .. "," .. S.i(win:getY()) .. "," .. S.i(win:getWidth()) .. "," .. S.i(win:getHeight()) .. "," .. S.i(win._drawerEffW or 0)
end
-- the window made shorter (a list too short to scroll); put back by S.shrinkBack
function S.shrinkOn(win)
    if not win then return false end
    local h = win:getHeight()
    local minH = win.minimumHeight or ZeD.T.px(220)
    local nh = math.max(minH, math.floor(h * 0.5))
    if nh >= h then return false end
    S.shrinks[#S.shrinks + 1] = { win = win, h = h }
    S.layoutTouched = true
    win:setHeight(nh)
    return true
end
function S.shrinkBack()
    for i = #S.shrinks, 1, -1 do
        local s = S.shrinks[i]
        pcall(function() s.win:setHeight(s.h) end)
    end
    S.shrinks = {}
end
function S.charTab(id) if RT.charTab(id) then return true end; return false end
function S.worldTab(id) if RT.worldTab(id) then return true end; return false end
function S.charOffers(id) return S.inList(RT.tabs(RT.charStrip()), id) end
function S.worldOffers(id) return S.inList(RT.tabs(RT.worldStrip()), id) end
function S.eqDirty()
    local w = RT.cw()
    if not w then return end
    w._equipCache = nil
    w._equipProtCache = nil
    w._equipDollTimer = 99
    w._equipDollStale = true
end
-- the Equipment tab on its List view, every group open, no card
function S.equipList()
    local w = RT.cw()
    if not w then return end
    w._equipSelected = nil
    local D = ZeD.EquipDoll
    if D and D.view and D.view() ~= "list" then pcall(D.setView, "list") end
    w._equipListExpanded = true
    w._equipExpanded = w._equipExpanded or {}
    for _, g in ipairs(S.GROUPS) do w._equipExpanded[g] = true end
    S.eqDirty()
end
-- the slot whose card to open: a garment (its zones make the card long), else anything worn or held
function S.cardSlot()
    local w = RT.cw()
    local best = nil
    for _, z in ipairs((w and w._equipSlotZones) or {}) do
        if z.type and S.isItem(z.item) then
            if instanceof(z.item, "Clothing") then return z end
            best = best or z
        end
    end
    return best
end
-- the floor's entry in the World window's containers
function S.floorInv()
    local ww = RT.ww()
    for _, e in ipairs((ww and ww._containers) or {}) do
        local inv = e.inventory
        if inv and instanceof(inv, "ItemContainer") then
            if e.isFloor or inv:getType() == "floor" then return inv end
        end
    end
    return nil
end

-- ===================================================================== the run's own records (for the put-back)
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        f.pair = RT.isOpen()
        if ZEDQA_HOME then pcall(ZEDQA_HOME, S.TAG) end
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, S.optVal(S.zopt("textSize"))
        f.view = ZeD.EquipDoll and ZeD.EquipDoll.view and ZeD.EquipDoll.view() or "list"
        f.inv0 = {}
        pcall(function()
            local items = S.p:getInventory():getItems()
            for i = 0, items:size() - 1 do f.inv0[items:get(i)] = true end
        end)
        if ZEDQA_LAYOUT_SNAP and f.pair then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local mw = S.msgWin()
        f.msgOpen = mw ~= nil and mw:isVisible() and true or false
        f.msgSel = mw and mw.sel or nil
        f.msgHad = ZeD.Messages and ZeD.Messages.sources and ZeD.Messages.sources[S.MSG] ~= nil
        -- the passes: A and C at the size found, B the other size (Large when Small was found)
        local keys = ZeD.Settings and ZeD.Settings.sizeKeys or { "small", "large" }
        local other = (f.size == "large") and "small" or "large"
        if not S.inList(keys, other) then other = keys[#keys] end
        S.PASS_A.size, S.PASS_B.size, S.PASS_C.size = f.size, other, f.size
        S.back.on = true
        RT.pairOpen()
        Events.OnPreUIDraw.Add(S.count)
        S.counting = true
        local spied = S.spyOn()
        Q.check(spied, "setup: ZeD_ScrollbarState.draw can be watched (every bar's draw recorded)", tostring(type(ZeD_ScrollbarState)))
        if not spied then S.dead = true end
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", theme " .. tostring(f.base) .. ", text "
            .. tostring(f.size) .. " (pass B: " .. tostring(other) .. "), Equip view " .. tostring(f.view) .. ", Messages open "
            .. tostring(f.msgOpen) .. ", token T.sp.scrollbarW " .. S.i(ZeD.T.sp.scrollbarW) .. ", hairline " .. S.i(ZeD.T.px(1))
            .. ", screen " .. S.sizeTag())
    end)
    S.wait(10, 300, function()
        local cw, ww = RT.cw(), RT.ww()
        return cw ~= nil and cw._tabStripPanel ~= nil and ww ~= nil and ww._actionTabStrip ~= nil
    end, function(ok)
        local cw, ww = RT.cw(), RT.ww()
        if not Q.check(ok, "setup: the Character and World windows are open") then S.dead = true; return end
        local f = S.found
        f.charTab, f.worldTab = cw._activeTab, ww._activeTab
        f.listExp, f.exp = cw._equipListExpanded, S.copy(cw._equipExpanded)
        f.jsub = cw._journalSubTab
        f.maxWinW = cw._maxWinW
        f.worldInv = ww._mainContent and ww._mainContent._inventory or nil
        f.scrolls = {}
        local objs = {}
        for _, c in ipairs(S.CHAR) do objs[#objs + 1] = cw[c.obj] end
        objs[#objs + 1] = cw._mainContent and cw._mainContent._scroll
        objs[#objs + 1] = ww._mainContent and ww._mainContent._scroll
        objs[#objs + 1] = ww._forageScroll
        objs[#objs + 1] = ww._animalsScroll
        for _, sb in ipairs(objs) do
            if type(sb) == "table" and sb.setScrollPos then f.scrolls[#f.scrolls + 1] = { sb = sb, pos = sb.scrollPos or 0 } end
        end
        Q.say("found: Character tab " .. tostring(f.charTab) .. ", World tab " .. tostring(f.worldTab) .. ", width cap "
            .. tostring(f.maxWinW) .. ", Character window " .. S.geo(cw) .. ", World window " .. S.geo(ww))
    end)
end

-- ===================================================================== one surface
-- spec: key (picture name), label, win() (the window that holds it), avail() (ok, why), open(T) (false, why: a SKIP),
-- after(T) (more steps queued after open), obj() (its bar object or a list of them), panel() (else a bar drawn on
-- this panel), more(T) (gives the list more to show; returns true when it did), shrink (the window may be made
-- shorter), close(T)
function S.lab(spec, pass) return spec.label .. " (" .. tostring(pass.theme) .. ", " .. tostring(pass.size) .. ")" end
function S.settle(T, spec, gate)
    S.wait(4, 600, function()
        if T.off or (gate and not gate()) then return true end
        local g = S.geo(spec.win and spec.win())
        T.st = T.st or { last = "", n = 0 }
        if g == T.st.last then T.st.n = T.st.n + 1 else T.st.last, T.st.n = g, 0 end
        return T.st.n >= 6
    end, function(ok)
        if T.off or (gate and not gate()) then return end
        if not ok then S.note(spec.label .. ": the window did not settle (" .. tostring(T.st and T.st.last) .. ")") end
        T.st = nil
    end)
    S.waitIdle(4)
end
function S.read(T, spec)
    T.recs = S.drawn()
    T.rec = nil
    local want = spec.obj and spec.obj() or nil
    if type(want) == "table" and want.draw == nil and #want > 0 then
        for _, o in ipairs(want) do
            for _, r in ipairs(T.recs) do if not T.rec and r.sb == o then T.rec = r end end
        end
    elseif want then
        for _, r in ipairs(T.recs) do if r.sb == want then T.rec = r end end
    end
    if not T.rec and spec.panel then
        local p = spec.panel()
        for _, r in ipairs(T.recs) do if not T.rec and p and r.panel == p then T.rec = r end end
    end
    return T.rec
end
function S.stateLine(T, spec, pass)
    local r = T.rec
    local tok = ZeD.T.sp.scrollbarW
    local lab = S.lab(spec, pass)
    local pl = tostring(r.panel._zedLabel or r.panel.Type or "?")
    Q.say("STATE " .. spec.key .. " " .. tostring(pass.theme) .. " " .. tostring(pass.size) .. ": bar " .. S.nameOf(r)
        .. " x=" .. S.i(r.x) .. " y=" .. S.i(r.y) .. " width=" .. S.i(r.w) .. " arrowH=" .. S.i(r.aH) .. " height=" .. S.i(r.h)
        .. " reserveBottom=" .. S.i(r.rb) .. " inRight=" .. tostring(r.inR) .. " inTop=" .. tostring(r.inT) .. " inBottom=" .. tostring(r.inB)
        .. " | caller's width " .. tostring(r.rawW) .. ", arrowH " .. tostring(r.rawA) .. " | draws past R/T/B " .. S.i(r.outR) .. "/"
        .. S.i(r.outT) .. "/" .. S.i(r.outB) .. " | panel " .. pl .. " at " .. S.i(r.ax) .. "," .. S.i(r.ay) .. " " .. S.i(r.pw) .. "x"
        .. S.i(r.ph) .. " scroll " .. S.i(r.xs) .. "," .. S.i(r.ys) .. " | screen " .. r.sx .. "," .. r.sy .. " | thumb "
        .. string.format("%.2f", tonumber(r.ratio) or 0) .. " at " .. string.format("%.2f", tonumber(r.pos) or 0)
        .. " | token " .. S.i(tok) .. ", hairline " .. S.i(r.hl) .. (T.shrunk and " | the window made shorter" or "")
        .. (T.more and (" | " .. T.more) or ""))
    Q.check(math.abs((tonumber(r.w) or -1) - tok) < 0.5,
        lab .. ": the bar's width is T.sp.scrollbarW" .. (pass.changed and " after the text-size change (fault 1)" or ""),
        "width " .. S.i(r.w) .. " (the caller's own " .. tostring(r.rawW) .. "), token " .. S.i(tok))
    if r.aH ~= 0 and math.abs((tonumber(r.aH) or -1) - (tonumber(r.w) or -2)) >= 0.5 then
        S.note(lab .. ": arrowH " .. S.i(r.aH) .. " is neither 0 nor the bar's width " .. S.i(r.w))
    end
end
function S.picName(spec, pass, T)
    return "sb_" .. spec.key .. (T.shrunk and "-short" or "") .. "_" .. tostring(pass.theme) .. "_" .. tostring(pass.size) .. "_" .. S.sizeTag()
end
function S.surface(spec, pass)
    local T = {}
    S.step(2, function()
        T.off, T.rec, T.shrunk, T.more, T.moreDid = nil, nil, nil, nil, nil
        local lab = S.lab(spec, pass)
        if spec.avail then
            local ok, why = spec.avail()
            if not ok then T.off = true; Q.skip(lab, why or "not offered here"); return end
        end
        local okc, r1, r2 = pcall(spec.open, T)
        if not okc then T.off = true; S.errs = S.errs + 1; Q.check(false, lab .. ": staged without an error", tostring(r1)); return end
        if r1 == false then T.off = true; Q.skip(lab, r2 or "could not be staged"); return end
    end)
    if spec.after then spec.after(T) end
    S.settle(T, spec)
    S.step(1, function() if not T.off then S.read(T, spec) end end)
    -- more to list, when it does not scroll
    S.step(1, function()
        if T.off or T.rec or not spec.more then return end
        local ok, did = pcall(spec.more, T)
        T.moreDid = ok and did and true or false
    end)
    S.settle(T, spec, function() return T.moreDid end)
    S.waitIdle(10)
    S.step(1, function() if T.moreDid and not T.off then S.read(T, spec) end end)
    -- the window made shorter, when it still does not scroll
    S.step(1, function()
        if T.off or T.rec or not spec.shrink then return end
        T.shrunk = S.shrinkOn(spec.win and spec.win()) or nil
    end)
    S.settle(T, spec, function() return T.shrunk end)
    S.step(1, function()
        if T.off then return end
        if T.shrunk then S.read(T, spec) end
        if not T.rec then
            local seen = {}
            for _, r in ipairs(T.recs or {}) do seen[#seen + 1] = S.nameOf(r) end
            Q.skip(S.lab(spec, pass), "its bar does not show here (nothing more to list; window made shorter: "
                .. tostring(T.shrunk == true) .. "); bars drawn: " .. ((#seen > 0) and table.concat(seen, ", ") or "none"))
            return
        end
        S.stateLine(T, spec, pass)
    end)
    S.shot(function() return S.picName(spec, pass, T) end, S.lab(spec, pass) .. ": its scroll bar's right, top and bottom edges",
        function() return not T.off and T.rec ~= nil end, T)
    S.step(2, function()
        if T.shrunk then S.shrinkBack(); T.shrunk = nil end
        if spec.close then pcall(spec.close, T) end
    end)
    S.waitIdle(8)
end

-- ===================================================================== the surfaces
function S.charSpec(c)
    return {
        key = c.key, label = "Character " .. c.key,
        win = function() return RT.cw() end,
        avail = function() if S.charOffers(c.id) then return true end; return false, "the Character window offers no " .. c.id .. " tab here" end,
        open = function(T)
            local w = RT.cw()
            if c.id == "equip" then S.equipList() end
            if c.id == "journal" and w then w._journalSubTab = 1 end
            if not S.charTab(c.id) then return false, "its tab could not be pressed" end
            return true
        end,
        obj = function() local w = RT.cw(); return w and w[c.obj] end,
        panel = function() local w = RT.cw(); return w and w._drawerPanel end,
        shrink = true,
    }
end
S.SP_INV = {
    key = "inventory", label = "the inventory list",
    win = function() return RT.cw() end,
    open = function(T)
        local w = RT.cw()
        if w then w._equipSelected = nil end
        S.charTab("loot")
        return true
    end,
    obj = function() local w = RT.cw(); return w and w._mainContent and w._mainContent._scroll end,
    more = function(T)
        if S.stocked then return false end
        S.stocked = true
        local n = S.stockInv()
        T.more = n .. " things given to list"
        return n > 0
    end,
    shrink = true,
}
S.SP_COOK = {
    key = "cooking", label = "Character cooking",
    win = function() return RT.cw() end,
    avail = function() if S.charOffers("cooking") then return true end; return false, "the Character window offers no cooking tab here" end,
    open = function(T) if not S.charTab("cooking") then return false, "its tab could not be pressed" end; return true end,
    panel = function() local w = RT.cw(); return w and w._drawerPanel end,
    shrink = true,
}
-- the Equipment card: card 480 or 220 (the width cap made too narrow for the full card, et_calls' halfOn)
function S.cardSpec(card)
    return {
        key = "equipcard" .. card, label = "the Equipment card, " .. card,
        win = function() return RT.cw() end,
        open = function(T)
            local w = RT.cw()
            if not w then return false, "no Character window" end
            S.equipList()
            if card == 220 and not S.isHalf() then
                if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
                S.layoutTouched = true
                w._maxWinW = ZeD.T.px(620)
            end
            if not S.charTab("equip") then return false, "the Equipment tab could not be pressed" end
            return true
        end,
        after = function(T)
            S.wait(4, 600, function()
                if T.off then return true end
                local w = RT.cw()
                if card == 220 and not S.isHalf() then return false end
                return w ~= nil and w._activeTab == "equip" and #(w._equipSlotZones or {}) > 0
            end, function(ok)
                if T.off then return end
                local w = RT.cw()
                if not ok then
                    T.off = true
                    Q.skip("the Equipment card, " .. card, "the Equipment list or the " .. card .. " drawer did not come (drawer "
                        .. S.i(w and w._drawerEffW) .. " px, the half card is " .. S.i(ZeD.T.px(220)) .. ")")
                    return
                end
                local z = S.cardSlot()
                if not z then T.off = true; Q.skip("the Equipment card, " .. card, "he wears and holds nothing to open a card on"); return end
                T.item = z.item
                w._equipSelected = z.type
                local dw = S.n(w._drawerEffW)
                Q.say("NOTE the Equipment card, " .. card .. ": opened on slot " .. tostring(z.type) .. ", " .. tostring(z.item:getDisplayName())
                    .. "; the drawer is " .. dw .. " px (the " .. card .. " card is " .. S.i(ZeD.T.px(card)) .. ")"
                    .. ((math.abs(dw - ZeD.T.px(card)) > 1) and " - NOT that card on this screen" or ""))
            end)
            S.wait(2, 300, function()
                if T.off then return true end
                local c = S.ecard()
                return c ~= nil and c:isVisible() and c.item == T.item
            end, function(ok)
                if T.off then return end
                if not ok then T.off = true; Q.skip("the Equipment card, " .. card, "the card did not open") end
            end)
        end,
        obj = function() local c = S.ecard(); return c and c._sb end,
        shrink = true,
        close = function(T)
            local w = RT.cw()
            if w then w._equipSelected = nil end
        end,
    }
end
S.SP_GROUND = {
    key = "ground", label = "the World window's ground list",
    win = function() return RT.ww() end,
    open = function(T)
        if not S.floorStocked then
            S.floorStocked = true
            local n, why = S.stockFloor()
            T.floorN = n
            if n == 0 then S.note("the ground list: nothing could be laid on his floor (" .. tostring(why) .. ")") end
        end
        S.worldTab("loot")
        return true
    end,
    after = function(T)
        S.wait(4, 300, function() return T.off or S.floorInv() ~= nil end, function(ok)
            if T.off then return end
            local inv = S.floorInv()
            if not inv then T.off = true; Q.skip("the World window's ground list", "the World window lists no floor here"); return end
            pcall(ZeD_WorldWindow.selectContainer, inv, 60, S.pn)
            S.back.worldInv = true
        end)
        S.wait(2, 300, function()
            if T.off then return true end
            local ww = RT.ww()
            return ww ~= nil and ww._mainContent ~= nil and ww._mainContent._inventory == S.floorInv()
        end, function(ok)
            if T.off then return end
            if not ok then S.note("the ground list: the floor was asked for and the World window shows something else") end
        end)
    end,
    obj = function() local w = RT.ww(); return w and w._mainContent and w._mainContent._scroll end,
    shrink = true,
}
function S.worldSpec(id, key, label, objFn)
    return {
        key = key, label = label,
        win = function() return RT.ww() end,
        avail = function() if S.worldOffers(id) then return true end; return false, "the World window offers no " .. id .. " tab here" end,
        open = function(T) if not S.worldTab(id) then return false, "its tab could not be pressed" end; return true end,
        obj = objFn,
        panel = function() local w = RT.ww(); return w and w._drawerPanel end,
        shrink = true,
    }
end
S.SP_CRAFT = S.worldSpec("craft", "crafting", "the Crafting recipe list", function()
    local w = RT.ww()
    local cs = w and w._craftState
    return cs and cs.scroll
end)
S.SP_FORAGE = S.worldSpec("forage", "foraging", "the Foraging tab", function()
    local w = RT.ww()
    return w and w._forageScroll
end)
-- a list of the bar objects that exist (no holes: # counts them)
function S.some(a, b, c, d)
    local t = {}
    for _, o in ipairs({ { a }, { b }, { c }, { d } }) do if o[1] ~= nil then t[#t + 1] = o[1] end end
    return t
end
S.SP_ANIMALS = S.worldSpec("animals", "animals", "the Animals tab", function()
    local w = RT.ww()
    if not w then return nil end
    local b = w._zedBars or {}
    return S.some(w._animalsScroll, b["an:roster"], b["an:detail"], b["an:butcher"])
end)
-- the Messages window, with QA notes filed under one source of its own (cleared after)
function S.msgText(i)
    local words = {}
    for k = 1, 9 do
        words[#words + 1] = "Note " .. i .. ", line " .. k .. ": a long QA note so the cards overflow and the Messages window shows its scroll bar."
    end
    return table.concat(words, " ")
end
S.SP_MSG = {
    key = "messages", label = "the Messages window",
    win = function() return S.msgWin() end,
    avail = function()
        local W, M = ZeD.MessagesWindow, ZeD.Messages
        if W and W.open and W.get and M and M.add and M.clear then return true end
        return false, "ZeD.MessagesWindow / ZeD.Messages are not loaded"
    end,
    open = function(T)
        local M = ZeD.Messages
        if not S.msgFiled then
            S.msgFiled = true
            for i = 1, 14 do M.add(S.MSG, "mods", { text = S.msgText(i) }) end
        end
        local win = ZeD.MessagesWindow.open(S.pn, S.MSG)
        if not win then return false, "the window did not open" end
        return true
    end,
    obj = function() local w = S.msgWin(); return w and w._sb end,
    shrink = true,
    close = function(T)
        local w = S.msgWin()
        if not w then return end
        if S.found.msgOpen then
            if S.found.msgSel then pcall(function() w:choose(S.found.msgSel) end) end
        else
            pcall(function() w:close() end)
        end
    end,
}

-- ===================================================================== the Vehicle tab's parts list (Mechanics)
function S.carStart()
    if not ZEDQA_CAR_WAIT then S.carWhy = "the prelude's car helpers are not loaded"; return end
    ZEDQA_CAR_WAIT(S.CARS[1], S.TAG, function(v)
        if S.carGaveUp then if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v) end; return end
        S.car = { v = v, script = S.CARS[1] }
    end, function(why) S.carWhy = why end, 4000)
end
function S.dist(v)
    local d = 999
    if not (v and instanceof(v, "BaseVehicle")) then return d end
    local dx, dy = v:getX() - S.p:getX(), v:getY() - S.p:getY()
    return math.sqrt(dx * dx + dy * dy)
end
-- him within the tab's reach of the car (gc_cleanup's carNear)
function S.carNear(v)
    local d = S.dist(v)
    if d <= 4.0 then return d end
    local vx, vy, z = math.floor(v:getX()), math.floor(v:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(S.BESIDE) do
        local sq = getCell():getGridSquare(vx + o[1], vy + o[2], z)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and sq:getVehicleContainer() == nil end) end
        if free then
            S.goTo(vx + o[1] + 0.5, vy + o[2] + 0.5, z)
            S.note("moved him beside the car (it stood " .. string.format("%.1f", d) .. " tiles away)")
            return S.dist(v)
        end
    end
    return d
end
function S.carAway()
    S.carGaveUp = true
    pcall(function() ZeD.MechanicsTab.endLooks(S.p) end)
    local c = S.car
    if not c or c.going then return end
    c.going = true
    if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, c.v, nil) end
end
function S.carLive(v)
    if not v then return false end
    local live = false
    local vs = nil
    pcall(function() vs = getCell():getVehicles() end)
    if not vs then return false end
    local it = nil
    pcall(function() it = vs:iterator() end)
    if not it then return false end
    pcall(function() while it:hasNext() do if it:next() == v then live = true end end end)
    return live
end
function S.mechReady()
    local ww = RT.ww()
    local v = S.car and S.car.v
    if not (ww and v and ww._activeTab == "vehicle") then return false end
    local s = ZeD.MechanicsTab.getState(ww)
    local cur = s and s.vehicles and s.vehicles[s.idx or 1]
    return cur ~= nil and cur.vehicle == v and s.listClip ~= nil
end
-- Build's lines: the list's state (MechanicsTab.lua renderList: s.maxScroll = total - bodyH, s.listClip.h = bodyH;
-- drawScrollbar returns before drawing when total <= bodyH) and both places the bar can be kept
function S.mechLog(tag, T)
    local ww = RT.ww()
    local MT = ZeD.MechanicsTab
    local s = ww and MT.getState(ww)
    if not s then Q.say("MECH " .. tag .. ": no state"); return end
    local c = s.listClip
    local bodyH = c and c.h or nil
    local ms = tonumber(s.maxScroll) or 0
    local total = (bodyH and ms > 0) and S.i(ms + bodyH) or ("<= " .. S.i(bodyH) .. " (maxScroll 0: the list fits, so drawScrollbar returns before drawing)")
    local insp = false
    pcall(function() insp = MT.isInspected(S.car.v) end)
    Q.say("MECH " .. tag .. ": s.maxScroll=" .. S.i(s.maxScroll) .. " s.scrollY=" .. S.i(s.scrollY) .. " bodyH (s.listClip.h)=" .. S.i(bodyH)
        .. " total=" .. total .. " listClip=" .. (c and (S.i(c.x) .. "," .. S.i(c.y) .. " " .. S.i(c.w) .. "x" .. S.i(c.h)) or "none")
        .. " view=" .. tostring(s.view) .. " inspected=" .. tostring(insp) .. " s.win is the World window: " .. tostring(s.win == ww))
    local pb = s.panel and s.panel._zedBars and s.panel._zedBars["mech:list"]
    local wb = ww._zedBars and ww._zedBars["mech:list"]
    Q.say("MECH " .. tag .. ": win._zedBars[\"mech:list\"] on the World window: " .. S.barText(wb))
    Q.say("MECH " .. tag .. ": the panel's (s.panel " .. tostring(s.panel and (s.panel._zedLabel or s.panel.Type)) .. ") _zedBars[\"mech:list\"]: " .. S.barText(pb))
    local drew = "no"
    for _, r in ipairs(S.drawn()) do if (wb and r.sb == wb) or (pb and r.sb == pb) then drew = "yes, " .. S.nameOf(r) end end
    Q.say("MECH " .. tag .. ": the bar drew in the last frame: " .. drew .. " (a Molecules.scrollBar bar's visible stays true once drawn)")
end
function S.mechanics(pass)
    local T = {}
    local spec = { key = "mechanics", label = "the Vehicle tab's parts list (Mechanics)", win = function() return RT.ww() end,
                   obj = function()
                       local ww = RT.ww()
                       local s = ww and ZeD.MechanicsTab.getState(ww)
                       local pb = s and s.panel and s.panel._zedBars
                       return S.some(ww and ww._zedBars and ww._zedBars["mech:list"], pb and pb["mech:list"])
                   end }
    S.step(2, function()
        local MT = ZeD.MechanicsTab
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_AWAY and MT and MT.openFromAction and MT.getState and MT.endLooks) then
            T.off = true
            Q.skip(S.lab(spec, pass), "the prelude's car helpers or the Mechanics tab are not loaded")
            return
        end
        S.worldTab("loot")
        if ZEDQA_HOME then pcall(ZEDQA_HOME, S.TAG) end
        S.carStart()
    end)
    S.wait(10, 3600, function() return T.off or S.car ~= nil or S.carWhy ~= nil end, function(ok)
        if T.off then return end
        if not S.car then T.off = true; S.carGaveUp = true; Q.skip(S.lab(spec, pass), "no car could be spawned ready: " .. tostring(S.carWhy or "none in time")) end
    end)
    S.step(5, function()
        if T.off then return end
        local v = S.car.v
        pcall(function() v:repair() end)
        local d = S.carNear(v)
        local ok, r = pcall(ZeD.MechanicsTab.openFromAction, S.p, v)
        Q.say("NOTE the car " .. tostring(S.car.script) .. " " .. string.format("%.1f", d) .. " tiles away; the Vehicle tab opened " .. tostring(ok and r))
    end)
    S.wait(4, 600, function() return T.off or S.mechReady() end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip(S.lab(spec, pass), "the Vehicle tab did not show the car's parts (tab " .. tostring(RT.ww() and RT.ww()._activeTab) .. ")") end
    end)
    S.settle(T, spec)
    S.step(1, function()
        if T.off then return end
        S.read(T, spec)
        S.mechLog("as it opens", T)
        if T.rec then S.stateLine(T, spec, pass) end
    end)
    -- (the natural picture whatever shows: Build asked for it)
    S.shot(function() return S.picName(spec, pass, T) end, S.lab(spec, pass) .. " as it opens (its bar " .. "shows when the parts overflow)",
        function() return not T.off end, T)
    S.step(1, function()
        if T.off or T.rec then return end
        T.shrunk = S.shrinkOn(RT.ww()) or nil
    end)
    S.settle(T, spec, function() return T.shrunk end)
    S.step(1, function()
        if T.off or not T.shrunk then return end
        S.read(T, spec)
        S.mechLog("the World window made shorter", T)
        if T.rec then S.stateLine(T, spec, pass)
        else Q.skip(S.lab(spec, pass), "the parts list's bar does not show even with the window made shorter") end
    end)
    S.shot(function() return S.picName(spec, pass, T) end, S.lab(spec, pass) .. " with the World window made shorter",
        function() return not T.off and T.shrunk and T.rec ~= nil end, T)
    S.step(2, function()
        if T.shrunk then S.shrinkBack(); T.shrunk = nil end
        S.carAway()
        S.worldTab("loot")
    end)
    S.waitIdle(10)
end

-- ===================================================================== the passes
function S.passStart(pass)
    S.step(2, function()
        if ZeD.currentBase ~= pass.theme then S.theme(pass.theme) end
        if ZeD.currentSize ~= pass.size then S.sizeSet(pass.size) end
        local w = RT.cw()
        if w then w._equipSelected = nil end
    end)
    S.waitIdle(30)
    S.step(2, function()
        pass.tok = ZeD.T.sp.scrollbarW
        Q.say("pass " .. pass.key .. ": theme " .. tostring(ZeD.currentBase) .. ", text " .. tostring(ZeD.currentSize) .. ", token T.sp.scrollbarW "
            .. S.i(pass.tok) .. ", hairline " .. S.i(ZeD.T.px(1)) .. (pass.changed and " (the size switched in this session: the bars were built at "
            .. tostring(S.found.size) .. ")" or ""))
    end)
end
function S.charPass(pass)
    for _, c in ipairs(S.CHAR) do S.surface(S.charSpec(c), pass) end
    S.surface(S.SP_INV, pass)
end
function S.build()
    S.setup()
    -- A: Dark at the size found, every surface
    S.passStart(S.PASS_A)
    S.charPass(S.PASS_A)
    S.surface(S.SP_COOK, S.PASS_A)
    S.surface(S.cardSpec(480), S.PASS_A)
    S.surface(S.cardSpec(220), S.PASS_A)
    S.step(2, function() S.halfBack() end)
    S.waitIdle(20)
    S.surface(S.SP_GROUND, S.PASS_A)
    S.surface(S.SP_CRAFT, S.PASS_A)
    S.surface(S.SP_FORAGE, S.PASS_A)
    S.surface(S.SP_ANIMALS, S.PASS_A)
    S.surface(S.SP_MSG, S.PASS_A)
    S.mechanics(S.PASS_A)
    -- B: the other text size, switched now (the bars were built before it)
    S.step(2, function() S.worldTab("loot"); S.charTab("loot") end)
    S.passStart(S.PASS_B)
    S.charPass(S.PASS_B)
    -- C: High contrast at the size found
    S.step(2, function() S.sizeBack() end)
    S.passStart(S.PASS_C)
    S.charPass(S.PASS_C)
end
function S.halfBack()
    if not S.back.maxW then return end
    local w = RT.cw()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.park(false)
    S.shrinkBack()
    S.halfBack()
    S.themeBack()
    S.sizeBack()
    S.carAway()
    local w = RT.cw()
    if w then
        w._equipSelected = nil
        w._equipClickWait = nil
        if f.charTab then
            w._equipListExpanded = f.listExp
            w._equipExpanded = S.copy(f.exp)
            w._journalSubTab = f.jsub
        end
    end
    S.eqDirty()
    if ZeD.EquipDoll and ZeD.EquipDoll.view and f.view and ZeD.EquipDoll.view() ~= f.view then pcall(ZeD.EquipDoll.setView, f.view) end
    -- Messages: the QA notes cleared, the window as found
    if (S.msgFiled or f.msgHad) and ZeD.Messages and ZeD.Messages.clear then pcall(ZeD.Messages.clear, S.MSG) end
    if f.msgHad then S.note("an earlier run's QA notes were still in Messages (" .. S.MSG .. "): cleared with this run's") end
    local mw = S.msgWin()
    if mw then
        if f.msgOpen then
            if not mw:isVisible() then pcall(ZeD.MessagesWindow.open, S.pn, f.msgSel) end
            if f.msgSel then pcall(function() mw:choose(f.msgSel) end) end
        elseif mw:isVisible() then pcall(function() mw:close() end) end
    end
    -- the things given and laid on the floor
    for _, it in ipairs(S.made) do S.removeItem(it) end
    for _, it in ipairs(S.floorMade) do S.removeItem(it) end
    pcall(function() triggerEvent("OnContainerUpdate") end)
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        S.putBack()
        RT.pairOpen()
    end)
    Q.step(10, function()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, S.TAG) end
    end)
    Q.step(20, function()
        local f = S.found
        if f.charTab then RT.charTab(f.charTab) end
        if f.worldTab then RT.worldTab(f.worldTab) end
        if S.back.worldInv and f.worldInv then pcall(ZeD_WorldWindow.selectContainer, f.worldInv, 60, S.pn) end
        -- (the layout's put-back shuts Messages: open again when it was found open)
        local mw = S.msgWin()
        if f.msgOpen and not (mw and mw:isVisible()) and ZeD.MessagesWindow and ZeD.MessagesWindow.open then
            pcall(ZeD.MessagesWindow.open, S.pn, f.msgSel)
        end
        local w = RT.cw()
        if w and f.charTab then w._maxWinW = f.maxWinW end
        for _, s in ipairs(f.scrolls or {}) do pcall(function() s.sb:setScrollPos(s.pos) end) end
    end)
    Q.waitFor(10, 600, function() return not (S.car and S.carLive(S.car.v)) end, function(ok)
        if S.car and not ok then S.note("the car is still in the world 10 s after it was sent away") end
    end)
    Q.step(10, function()
        S.spyOff()
        if S.counting then Events.OnPreUIDraw.Remove(S.count); S.counting = nil end
        local f = S.found
        if not f.base then Q.skip("put back", "nothing was staged"); return end
        local left = 0
        for _, it in ipairs(S.made) do if S.where(it) ~= nil or S.onFloor(it) then left = left + 1 end end
        for _, it in ipairs(S.floorMade) do if S.where(it) ~= nil or S.onFloor(it) then left = left + 1 end end
        Q.check(left == 0, "put back: every thing the test gave or laid on the floor is gone", left .. " of " .. (#S.made + #S.floorMade) .. " left")
        local extra = 0
        pcall(function()
            local items = S.p:getInventory():getItems()
            for i = 0, items:size() - 1 do if not f.inv0[items:get(i)] then extra = extra + 1 end end
        end)
        Q.check(extra == 0, "put back: the inventory holds only what it held", extra .. " more")
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and S.optVal(S.zopt("baseTheme")) == f.baseIdx
            and S.optVal(S.zopt("textSize")) == f.sizeIdx, "put back: the theme and the text size as found (and their options)",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize))
        local cw, ww = RT.cw(), RT.ww()
        Q.check(cw ~= nil and ww ~= nil and cw._activeTab == f.charTab and ww._activeTab == f.worldTab and cw._maxWinW == f.maxWinW
            and cw._equipSelected == nil and #S.shrinks == 0 and S.back.maxW == nil,
            "put back: both windows' tabs, the width cap, no card open, every window's height",
            "Character " .. tostring(cw and cw._activeTab) .. " (found " .. tostring(f.charTab) .. "), World " .. tostring(ww and ww._activeTab)
            .. " (found " .. tostring(f.worldTab) .. "), cap " .. tostring(cw and cw._maxWinW) .. " (found " .. tostring(f.maxWinW) .. ")")
        local view = ZeD.EquipDoll and ZeD.EquipDoll.view and ZeD.EquipDoll.view() or "list"
        Q.check(view == f.view, "put back: the Equip view as found", tostring(view))
        local mw = S.msgWin()
        local open = mw ~= nil and mw:isVisible() and true or false
        local M = ZeD.Messages
        Q.check(open == f.msgOpen and not (M and M.sources and M.sources[S.MSG]), "put back: Messages as found, the QA notes cleared",
            "open " .. tostring(open) .. " (found " .. tostring(f.msgOpen) .. ")")
        Q.check(not (S.car and S.carLive(S.car.v)), "put back: the car is gone", tostring(S.car and S.car.script))
        Q.check(ZeD_ScrollbarState.draw == (S.spyOwn or ZeD_ScrollbarState.draw) and S.spy == nil and S.parked == nil,
            "put back: the bar's draw and the pointer the game's own again")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6, "put back: he stands where he stood", string.format("%.1f,%.1f off", dx, dy))
        Q.check(S.errs == 0, "put back: nothing staged for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the scroll bar run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the run's Lua error count", "the game's Lua error count cannot be read here") end
        Q.say("pictures: " .. #S.shots .. ", RECT lines: " .. S.rectN .. " (score them: sb_judge.py --pics <Screenshots folder> --console console.txt --tag sb_edges --crops <folder>)")
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
S.spyOwn = type(ZeD_ScrollbarState) == "table" and rawget(ZeD_ScrollbarState, "draw") or nil
if not (ZeD and ZeD.T and ZeD.T.sp and ZeD.T.px and ZeD.applyTheme and ZeD.Settings and S.spyOwn) then
    Q.check(false, "ZeD's tokens, theme and scroll bar are loaded")
else
    S.build()
end
S.buildPutBack()
Q.start()
