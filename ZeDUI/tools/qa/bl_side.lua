-- ZeDUI/tools/qa/bl_side.lua  (Nov 23 2026, QA; tag bl_side): the in-game proof of the director's belt side marks,
-- Build's commit 3fd6221dd on branch fix/beltside. The director, Nov 23 2026: "On belt and attachments, can we add an
-- indicator, much like the number, saying which slot it is in the hotbar or hotkeys? I would like to see a left or
-- right indicator on the belt icon for each slot, rather than saying belt L, belt R. There'd be a left and right
-- indicator up in the corner."
-- Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA bl_side". Manifest: bl_side.txt.
--
-- Staging: the QA character at the drag strip wears the run's double holster (Base.HolsterDouble: HolsterLeft and
-- HolsterRight) and ALICE belt and suspenders (Base.Bag_ALICE_BeltSus: SmallBeltLeft, SmallBeltRight, WebbingLeft and
-- WebbingRight); a plain belt (Base.Belt2) only when the belt slots are still missing after those two. His own items on
-- the six side slots come off the hotbar for the run (the game's ISHotbar:removeItem, no animation) and go back on at
-- the end. The belt's drawing is read for one frame: ZeD_BeltHUD._prerender wrapped for that one frame only (the
-- wrapper takes itself off on its first call), the belt's drawRect, drawText and drawTextureScaledAspect and
-- ZeD.Atoms.drawLamp recorded inside it and put back right after. The boxes are read as the belt laid them out
-- (hud._boxes, kind "slot", b.s.slot.slotType), in the belt's own coordinates, as the draws are.
-- The tag sizes the checks expect are _drawBox's own: the tag's height the F1 font's height, its width
-- max(width of the text + px(6), height).
--
-- Checks:
--   SIDE 0     EN (the director's language): getText of UI_ZeD_Belt_SideL / SideR is "L" / "R", and of SlotBelt,
--              SlotWeb and SlotHolster "Belt", "Web" and "Holster" (another language: skipped, said so)
--   staging    the worn gear gives all six side slots and the belt draws a box for each
--   SIDE 1     (one line per side slot, empty) ZeD.Belt.sideMark(slotType) is the slot's side (L for a Left slot, R for
--              a Right one, in the game's words); a tag in the box's top right corner: as tall as the key-number tag
--              at top left, as wide as _drawBox's rule gives for the letter (and as the key tag when the key is one
--              character), filled with surf3 (not the accent), the letter drawn inside it; the key tag still on the
--              accent
--   SIDE 2     (one line per side slot, empty) the box's name is the plain word ("Belt", "Web" or "Holster", as
--              ZeD.Belt.shortName gives it and the game's translation says); no old "Belt L" style name anywhere on
--              the belt. Picture bl_side_empty_<w>x<h>
--   SIDE 3     every slot with no side (Back always; Shoulder, Ankle and Pack when worn) has no mark: sideMark nil, no
--              tag in the top right corner, no L or R drawn in it
--   staging    a screwdriver on SmallBeltLeft, a hammer on SmallBeltRight, a pistol (Base.Pistol) on HolsterLeft, a
--              second pistol (Base.Pistol2) on HolsterRight, a hunting knife on WebbingLeft and an angle-head
--              flashlight (Base.FlashLight_AngleHead, off) on WebbingRight, each through ZeD.Belt.attach (the
--              game's ISHotbar:attachItem with its timed action, as a drop on the belt does)
--   SIDE 4     (one line per side slot, with its item) the item is on the slot, its icon is drawn in the box, the
--              side mark still drawn with its letter on surf3, the key tag on the accent. Picture
--              bl_side_items_<w>x<h>
--   SIDE 5     the flashlight turned on (setActivated(true)): the lamp draws inside its box, its top at or below the
--              side mark's bottom, inside the box's right edge. Picture bl_side_lamp_<w>x<h>
-- (Nov 23 2026, QA, Build's fix/beltrow2 on main 99d56a202, the director's "Belt, space, time, space, messages, chat"
-- and "Bag lights, speed keys grey"; the bag button's pick set to the Pocket for these:)
--   BAG 1      the row's box kinds end "...speed, notice" (single player) and each group is one B.ICON_GAP apart: the
--              bag button, the hands, the belt (the strap in Full, the slots in Lite), the five speed keys, the notice
--   BAG 2      a pen in a bag he carries (not worn) dragged (ISMouseDrag.dragging, one recorded frame): the bag
--              button's _dropState is "fit", hud._bagDrop.fit, ZeD.Belt.bagTakes gives the Pocket and the pen, the
--              button draws the accent's wash
--   BAG 3      under that drag the five speed keys draw the ink wash (gray)
--   BAG 4      a pencil already in the Pocket dragged: "no", nothing that fits, the button gray, the keys gray
--   BAG 5      the pen dropped on the bag button (ZeD.Belt.takeDrop, as InventoryRenderer.handleDrop calls it, the
--              belt's pointer read on the button): its item id in the Pocket, not in his bag
--   BAG 6      a closed stack of three dropped on it (a stand-in list content with the stack model InventoryRenderer
--              builds, the stack not open): all three ids in the Pocket
--   put back   (below)
--
-- Puts back (also when a step throws or the time runs out): the one-frame recorder gone (_prerender, the belt's draw
-- methods, ZeD.Atoms.drawLamp as found), the pointer and the cursor as found; the drag (ISMouseDrag.dragging), the
-- belt's pointer read and the bag button's pick (his modData ZeD_BeltBag) as found; the flashlight off; the run's items off
-- the hotbar and taken away; the run's gear taken off and away, every worn item of his as found; the hotbar's slots in
-- the found order with his items on their found slots (his modData "hotbar" as found); both windows shut, then open
-- or shut as found, placed and on their tabs, his modData ZeD_WinState as found; the game speed. Checked: the worn
-- items, the hotbar, the flashlight, the recorder, the windows and no new Lua error over the run.
-- No file is written but the three pictures (Zomboid/Screenshots/bl_side_*.png).
-- Not run offline; parse-checked with the game's Kahlua compiler (KCheck).

if not (RT and RT.make) then
    print("ZEDQA bl_side ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bl_side VERDICT FAIL 1")
    print("ZEDQA bl_side DONE")
    return
end

local Q = RT.make("bl_side")
Q.maxMs = 600000   -- (ten minutes, then the put-back; a run takes about two)
local S = { p = RT.p, pn = RT.pn, was = {}, k = {}, given = {}, his = {}, items = {} }
S.SIDES = {
    { t = "SmallBeltLeft", sd = "L", key = "UI_ZeD_Belt_SlotBelt", en = "Belt", item = "Base.Screwdriver" },
    { t = "SmallBeltRight", sd = "R", key = "UI_ZeD_Belt_SlotBelt", en = "Belt", item = "Base.Hammer" },
    { t = "HolsterLeft", sd = "L", key = "UI_ZeD_Belt_SlotHolster", en = "Holster", item = "Base.Pistol" },
    { t = "HolsterRight", sd = "R", key = "UI_ZeD_Belt_SlotHolster", en = "Holster", item = "Base.Pistol2" },
    { t = "WebbingLeft", sd = "L", key = "UI_ZeD_Belt_SlotWeb", en = "Web", item = "Base.HuntingKnife" },
    { t = "WebbingRight", sd = "R", key = "UI_ZeD_Belt_SlotWeb", en = "Web", item = "Base.FlashLight_AngleHead" },
}
S.SIDE_BY = {}
for _, e in ipairs(S.SIDES) do S.SIDE_BY[e.t] = e end
S.LAMP_T = "WebbingRight"
S.GEAR = { "Base.HolsterDouble", "Base.Bag_ALICE_BeltSus" }
S.BELT = "Base.Belt2"
-- the old names a side slot said before (their keys stay in the language files)
S.OLD_KEYS = { "UI_ZeD_Belt_SlotBeltL", "UI_ZeD_Belt_SlotBeltR", "UI_ZeD_Belt_SlotHolsterL", "UI_ZeD_Belt_SlotWebL", "UI_ZeD_Belt_SlotWebR" }
S.RAW = { "drawRect", "drawText", "drawTextureScaledAspect", "getMouseX", "getMouseY" }

-- ===================================================================== words and numbers
function S.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function S.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    if depth > 4 then return nil end
    local o = {}
    for k, v in pairs(t) do o[k] = S.copy(v, depth + 1) end
    return o
end
function S.now() return getTimestampMs() end
function S.md() return S.p:getModData() end
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.tx(key) local s = nil; pcall(function() s = getText(key) end); return s end
function S.ztr(key) local s = nil; pcall(function() s = ZeD.tr(key) end); return s end
function S.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function S.itemShow(it) local n = nil; pcall(function() n = it:getDisplayName() end); return tostring(n) end
function S.rectText(r)
    if not r then return "none" end
    return S.num(r.x) .. "," .. S.num(r.y) .. " " .. S.num(r.w) .. "x" .. S.num(r.h)
end
function S.near(a, b, tol)
    return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 1)
end
function S.sameCol(r, c)
    return r ~= nil and c ~= nil and S.near(r.r, c.r, 0.01) and S.near(r.g, c.g, 0.01) and S.near(r.b, c.b, 0.01)
end
function S.colName(r)
    if not r then return "none" end
    local T = ZeD.T
    if S.sameCol(r, T.surf3) then return "surf3" end
    if ZeD.Belt and S.sameCol(r, ZeD.Belt.SIDE_BLACK) then return "the black box" end
    if ZeD.Belt and S.sameCol(r, ZeD.Belt.SIDE_WHITE) then return "the white box" end
    if S.sameCol(r, T.accent) then return "the accent" end
    return "rgb " .. S.num(r.r) .. "/" .. S.num(r.g) .. "/" .. S.num(r.b)
end

-- ===================================================================== waits (by the clock)
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
function S.settle(minMs, maxMs, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(maxMs / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if now - st.t >= minMs then
            local okC, r = pcall(cond)
            if okC and r then st.ok = true; return true end
        end
        return now - st.t >= maxMs
    end, function() fn(st.ok == true) end)
end

-- ===================================================================== the belt and the hotbar
function S.hud() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
function S.hb() local h = nil; pcall(function() h = ZeD.Belt.hotbar(S.pn) end); return h end
function S.drawnOk() local hud = S.hud(); return hud ~= nil and hud._drawn == true end
function S.slots() local hb = S.hb(); return (hb and hb.availableSlot) or {} end
function S.attached(i) local hb = S.hb(); return hb and hb.attachedItems and hb.attachedItems[i] or nil end
function S.idxOf(t)
    for i, sl in ipairs(S.slots()) do if sl.slotType == t then return i end end
    return nil
end
function S.box(t)
    local hud = S.hud()
    for _, b in ipairs((hud and hud._boxes) or {}) do
        if b.kind == "slot" and b.s and b.s.slot and b.s.slot.slotType == t then return b end
    end
    return nil
end
function S.slotBoxes()
    local out = {}
    local hud = S.hud()
    for _, b in ipairs((hud and hud._boxes) or {}) do
        if b.kind == "slot" and b.s and b.s.slot then out[#out + 1] = b end
    end
    return out
end
function S.typesText()
    local out = {}
    for i, sl in ipairs(S.slots()) do
        local it = S.attached(i)
        out[#out + 1] = i .. " " .. tostring(sl.slotType) .. (it and (" (" .. S.itemShow(it) .. ")") or "")
    end
    return table.concat(out, ", ")
end
function S.allSideBoxes()
    for _, e in ipairs(S.SIDES) do if not S.box(e.t) then return false end end
    return true
end
function S.missing()
    local out = {}
    for _, e in ipairs(S.SIDES) do
        if not S.idxOf(e.t) then out[#out + 1] = e.t .. " (no hotbar slot)"
        elseif not S.box(e.t) then out[#out + 1] = e.t .. " (no box on the belt)" end
    end
    return table.concat(out, ", ")
end
function S.sideMark(t) local m = nil; pcall(function() m = ZeD.Belt.sideMark(t) end); return m end
function S.shortName(t) local m = nil; pcall(function() m = ZeD.Belt.shortName(t) end); return m end
function S.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) elseif setGameSpeed then pcall(setGameSpeed, n) end end

-- ===================================================================== the tag sizes, as _drawBox measures them
function S.fh() local h = nil; pcall(function() h = ZeD.TM:getFontHeight(ZeD.T.fontF1) end); return h end
function S.tagW(txt)
    local w = nil
    pcall(function()
        local f1 = ZeD.T.fontF1
        w = math.max(ZeD.TM:MeasureStringX(f1, txt) + ZeD.T.px(6), ZeD.TM:getFontHeight(f1))
    end)
    return w
end

-- ===================================================================== one frame of the belt's drawing, recorded
-- (the class's _prerender is wrapped until its next call for this belt, which takes the wrapper off first; the draws
-- are recorded only inside that one call)
function S.arm()
    local hud = S.hud()
    if not (hud and ZeD_BeltHUD and type(ZeD_BeltHUD._prerender) == "function") then return false end
    S.rec, S.recDone, S.recErr = nil, false, nil
    S.recHud = hud
    if not S.origPre then S.origPre = ZeD_BeltHUD._prerender end
    ZeD_BeltHUD._prerender = S.recPre
    return true
end
function S.recPre(self)
    if self ~= S.recHud then return S.origPre(self) end
    ZeD_BeltHUD._prerender = S.origPre
    local rec = { rects = {}, texts = {}, texs = {}, lamps = {} }
    S.rec = rec
    local raw = { r = rawget(self, "drawRect"), t = rawget(self, "drawText"), x = rawget(self, "drawTextureScaledAspect") }
    local bR, bT, bX = self.drawRect, self.drawText, self.drawTextureScaledAspect
    self.drawRect = function(me, x, y, w, h, a, r, g, b)
        rec.rects[#rec.rects + 1] = { x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b }
        return bR(me, x, y, w, h, a, r, g, b)
    end
    self.drawText = function(me, s, x, y, r, g, b, a, font)
        rec.texts[#rec.texts + 1] = { s = s, x = x, y = y, r = r, g = g, b = b }
        return bT(me, s, x, y, r, g, b, a, font)
    end
    self.drawTextureScaledAspect = function(me, tex, x, y, w, h, a, r, g, b)
        rec.texs[#rec.texs + 1] = { tex = tex, x = x, y = y, w = w, h = h }
        return bX(me, tex, x, y, w, h, a, r, g, b)
    end
    local A = ZeD.Atoms
    local bL = A and A.drawLamp
    if bL then
        A.drawLamp = function(panel, x, y, d, c, a)
            if panel == self then rec.lamps[#rec.lamps + 1] = { x = x, y = y, w = d, h = d } end
            return bL(panel, x, y, d, c, a)
        end
    end
    local ok, err = pcall(S.origPre, self)
    self.drawRect, self.drawText, self.drawTextureScaledAspect = raw.r, raw.t, raw.x
    if bL then A.drawLamp = bL end
    if not ok then S.recErr = tostring(err) end
    S.recDone = true
end
function S.disarm()
    if S.origPre and ZeD_BeltHUD and ZeD_BeltHUD._prerender == S.recPre then ZeD_BeltHUD._prerender = S.origPre end
end
-- a tag of the F1 font's height at the box's top edge: in the top right corner (right) or the top left (not right)
function S.tagAt(rec, b, right)
    local fh = S.fh()
    local found = nil
    for _, r in ipairs(rec.rects) do
        if S.near(r.y, b.y) and S.near(r.h, fh) and type(r.w) == "number" and r.w < b.w - 2 then
            if right and S.near(r.x + r.w, b.x + b.w) then found = r end
            if (not right) and S.near(r.x, b.x) then found = r end
        end
    end
    return found
end
function S.textsIn(rec, b)
    local out = {}
    for _, t in ipairs(rec.texts) do
        if type(t.x) == "number" and type(t.y) == "number" and t.x >= b.x - 1 and t.x < b.x + b.w and t.y >= b.y - 1 and t.y < b.y + b.h then
            out[#out + 1] = t
        end
    end
    return out
end
function S.textsWords(list)
    local out = {}
    for _, t in ipairs(list) do out[#out + 1] = "\"" .. tostring(t.s) .. "\"@" .. S.num(t.x) .. "," .. S.num(t.y) end
    return table.concat(out, " ")
end
function S.inside(r, b)
    return type(r.x) == "number" and type(r.y) == "number" and r.x >= b.x - 1 and r.y >= b.y - 1 and r.x < b.x + b.w and r.y < b.y + b.h
end
function S.recOk(label)
    if S.recDone and S.rec and not S.recErr then return true end
    Q.check(false, label .. ": one frame of the belt recorded", "done " .. tostring(S.recDone) .. ", error " .. tostring(S.recErr))
    return false
end

-- ===================================================================== the reads
-- the side mark of one side slot: { ok, why, text }
function S.markRead(rec, e)
    local why = {}
    local b = S.box(e.t)
    if not b then return { ok = false, text = "no box on the belt for " .. e.t } end
    local T = ZeD.T
    local want = S.ztr(e.sd == "L" and "UI_ZeD_Belt_SideL" or "UI_ZeD_Belt_SideR")
    local sm = S.sideMark(e.t)
    if sm ~= want then why[#why + 1] = "sideMark gives " .. tostring(sm) .. ", not " .. tostring(want) end
    local mk, kt = S.tagAt(rec, b, true), S.tagAt(rec, b, false)
    local key = b.s and b.s.key
    local ww = S.tagW(tostring(want))
    if not mk then why[#why + 1] = "no tag in the top right corner"
    else
        if not S.near(mk.w, ww) then why[#why + 1] = "the mark is " .. S.num(mk.w) .. " wide, not " .. S.num(ww) end
        if kt and not S.near(kt.h, mk.h) then why[#why + 1] = "the mark is " .. S.num(mk.h) .. " tall, the key tag " .. S.num(kt.h) end
        if kt and key ~= nil and #tostring(key) == 1 and not S.near(kt.w, mk.w) then
            why[#why + 1] = "the mark is " .. S.num(mk.w) .. " wide, the key tag " .. S.num(kt.w)
        end
        -- (the director, Nov 23 2026, fix/sideink: "Black box, white text" on one side and the negative on the other:
        -- L a near-black box with light text, R the reverse, in every theme; surf3 before that)
        local B = ZeD.Belt or {}
        local inkFill = (e.sd == "L") and B.SIDE_BLACK or B.SIDE_WHITE
        if inkFill == nil then inkFill = T.surf3 end
        if not S.sameCol(mk, inkFill) then why[#why + 1] = "the mark's fill is " .. S.colName(mk) .. ", not the " .. ((e.sd == "L") and "black" or "white") .. " box" end
        local lt = nil
        for _, t in ipairs(rec.texts) do
            if t.s == want and type(t.x) == "number" and t.x >= mk.x - 1 and t.x < mk.x + mk.w and S.near(t.y, mk.y) then lt = t end
        end
        if not lt then why[#why + 1] = "the letter " .. tostring(want) .. " is not drawn in the mark" end
    end
    if key ~= nil then
        if not kt then why[#why + 1] = "no key tag at top left (key " .. tostring(key) .. ")"
        elseif not S.sameCol(kt, T.accent) then why[#why + 1] = "the key tag's fill is " .. S.colName(kt) .. ", not the accent" end
    end
    local text = "box " .. S.rectText(b) .. "; mark " .. S.rectText(mk) .. " on " .. S.colName(mk) .. " (want " .. S.num(ww) .. "x"
        .. S.num(S.fh()) .. "); key " .. tostring(key) .. " tag " .. S.rectText(kt) .. " on " .. S.colName(kt) .. "; drawn in the box: "
        .. S.textsWords(S.textsIn(rec, b))
    return { ok = #why == 0, why = why, text = text .. ((#why > 0) and ("; WRONG: " .. table.concat(why, "; ")) or ""), mark = mk, box = b }
end
-- the old "Belt L" style names drawn anywhere on the belt this frame
function S.oldDrawn(rec)
    local old = {}
    for _, k in ipairs(S.OLD_KEYS) do
        local s = S.ztr(k)
        if s and s ~= k then old[s] = true end
    end
    local out = {}
    for _, t in ipairs(rec.texts) do if old[t.s] then out[#out + 1] = tostring(t.s) end end
    return out
end

-- ===================================================================== worn things (as vk4_belt does)
function S.wornList()
    local out = {}
    local wl = nil
    pcall(function() wl = S.p:getWornItems() end)
    if not wl then return out end
    pcall(function()
        for i = 0, wl:size() - 1 do
            local wi = wl:get(i)
            local it, loc = nil, nil
            if wi then
                it = wi:getItem()
                loc = wi:getLocation()
            end
            if it and loc ~= nil then out[#out + 1] = { loc = loc, item = it } end
        end
    end)
    return out
end
function S.isWorn(it)
    for _, e in ipairs(S.wornList()) do if e.item == it then return true end end
    return false
end
function S.locOf(it)
    local loc = nil
    pcall(function()
        if it:IsInventoryContainer() then loc = it:canBeEquipped() end
        if loc == nil or loc == "" then loc = it:getBodyLocation() end
    end)
    if loc == "" then loc = nil end
    return loc
end
function S.clothes() pcall(function() triggerEvent("OnClothingUpdated", S.p) end) end
-- the hotbar's slots read again now (the game's own refresh, which its update runs after a clothing change)
function S.refresh()
    S.clothes()
    local hb = S.hb()
    if hb then pcall(function() hb:refresh() end) end
end
function S.wear(it)
    local loc = it and S.locOf(it) or nil
    if not loc then return false end
    pcall(function() S.p:setWornItem(loc, it) end)
    return S.isWorn(it)
end
function S.unwear(it)
    if not (it and S.isWorn(it)) then return end
    pcall(function() S.p:removeWornItem(it) end)
end
function S.give(ft)
    local it = RT.give(ft)
    if it then S.given[#S.given + 1] = it end
    return it
end
function S.isGiven(it)
    for _, g in ipairs(S.given) do if g == it then return true end end
    return false
end
function S.inInv(it) local y = false; pcall(function() y = S.p:getInventory():contains(it) end); return y end

-- ===================================================================== the windows (as vk4_belt does)
function S.charOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(S.pn) end); return o and true or false end
function S.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function S.none() return not S.charOpen() and not S.worldOpen() end
function S.shutAll()
    if S.charOpen() and S.worldOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn); return end
    if S.charOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
    if S.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
end
function S.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function S.placeBack(w, g)
    if not (w and g) then return end
    pcall(function()
        if math.abs(w:getWidth() - g.w) > 1 then
            w.minimumWidth = math.min(w.minimumWidth or g.w, g.w)
            w:setWidth(g.w)
        end
        if math.abs(w:getHeight() - g.h) > 1 then
            w.minimumHeight = math.min(w.minimumHeight or g.h, g.h)
            w:setHeight(g.h)
        end
        if w:getX() ~= g.x then w:setX(g.x) end
        if w:getY() ~= g.y then w:setY(g.y) end
    end)
end

-- ===================================================================== the pointer parked, the cursor hidden (pictures and reads)
function S.park(on)
    if on then
        if not S.parked then
            local hud = S.hud()
            S.parked = { hud = hud, hx = hud and rawget(hud, "getMouseX"), hy = hud and rawget(hud, "getMouseY"), mx = getMouseX, my = getMouseY }
            if hud then
                hud.getMouseX = function() return -100000 end
                hud.getMouseY = function() return -100000 end
            end
            getMouseX = function() return -100000 end
            getMouseY = function() return -100000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        S.cursorHidden = true
        return
    end
    local pk = S.parked
    if pk then
        S.parked = nil
        if pk.hud then pk.hud.getMouseX, pk.hud.getMouseY = pk.hx, pk.hy end
        getMouseX, getMouseY = pk.mx, pk.my
    end
    if S.cursorHidden then
        S.cursorHidden = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function S.shot(name, what)
    local file = "bl_side_" .. name .. "_" .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ".png"
    local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
    if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
    else Q.say("NOTE the picture " .. file .. " was not taken: " .. tostring(e)) end
end
-- one recorded frame with the pointer parked: arm, wait for the frame, read it (fn), then the picture
function S.readAndShot(label, fn, name, what)
    Q.step(2, function()
        if not S.ok then return end
        S.park(true)
        if not S.arm() then S.recErr = "the belt or its _prerender is missing"; S.recDone = true end
    end)
    Q.waitFor(1, 300, function() return not S.ok or S.recDone == true end, function()
        if not S.ok then return end
        S.disarm()
        if S.recOk(label) then fn(S.rec) end
    end)
    Q.step(3, function() if S.ok then S.shot(name, what) end end)
    Q.step(2, function() S.park(false) end)
end

-- ===================================================================== the hotbar put back
-- the slots in the found order (the game's own slot tables, or new ones from its getSlotDef), saved as the game saves
-- them, then his items on their found slots through the game's ISHotbar:attachItem without the animation
function S.orderSame()
    local sl = S.slots()
    if #sl ~= #S.was.slots then return false end
    for i, f in ipairs(S.was.slots) do if not (sl[i] and sl[i].slotType == f.t) then return false end end
    return true
end
function S.hotbarBack()
    local hb = S.hb()
    if not (hb and S.was.slots) then return end
    if not S.orderSame() then
        S.reordered = true
        local on = {}
        for _, it in pairs(hb.attachedItems or {}) do on[#on + 1] = it end
        for _, it in ipairs(on) do pcall(function() hb:removeItem(it, false) end) end
        local cur, list, used = {}, {}, {}
        for _, sl in ipairs(hb.availableSlot or {}) do cur[sl.slotType] = sl end
        for _, f in ipairs(S.was.slots) do
            local sl = cur[f.t]
            if not sl then pcall(function() local d = hb:getSlotDef(f.t); if d then sl = { slotType = d.type, name = d.name, def = d } end end) end
            if sl then list[#list + 1] = sl; used[f.t] = true end
        end
        for _, sl in ipairs(hb.availableSlot or {}) do if not used[sl.slotType] then list[#list + 1] = sl end end
        hb.availableSlot = list
        pcall(function() hb:savePosition() end)
    end
    for i, f in ipairs(S.was.slots) do
        local sl = hb.availableSlot[i]
        if f.item and sl and sl.slotType == f.t and hb.attachedItems[i] ~= f.item then
            pcall(function()
                if f.item:getAttachedSlot() > -1 then hb:removeItem(f.item, false) end
                local there = hb.attachedItems[i]
                if there then hb:removeItem(there, false) end
                if S.inInv(f.item) then hb:attachItem(f.item, sl.def.attachments[f.item:getAttachmentType()], i, sl.def, false) end
            end)
        end
    end
    pcall(function() hb:reloadIcons() end)
end

-- ===================================================================== start: what was found
Q.step(3, function()
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then Q.check(false, "the character is alive (staging)"); return end
    local ready = ZeD ~= nil and ZeD.Belt ~= nil and ZeD.Belt.getHUD ~= nil and ZeD.Belt.hotbar ~= nil and ZeD.Belt.attach ~= nil
        and ZeD.Belt.shortName ~= nil and ZeD_BeltHUD ~= nil and type(ZeD_BeltHUD._prerender) == "function" and ZeD.Atoms ~= nil
        and ZeD.Atoms.drawLamp ~= nil and ZeD.T ~= nil and ZeD.TM ~= nil and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil
        and S.hb() ~= nil and S.hud() ~= nil
    if not Q.check(ready, "ZeD's belt, its hotbar, the atoms, theme sizes and the windows are loaded (staging)") then return end
    Q.check(ZeD.Belt.sideMark ~= nil, "SIDE: ZeD.Belt.sideMark exists (Build's 3fd6221dd)")
    S.err0 = S.errN()
    S.origLamp = ZeD.Atoms.drawLamp
    S.origPreFound = ZeD_BeltHUD._prerender
    S.gmx, S.gmy = getMouseX, getMouseY
    local hud = S.hud()
    S.was.raw = {}
    for _, k in ipairs(S.RAW) do S.was.raw[k] = rawget(hud, k) end
    S.was.hud = hud
    -- the hotbar as found: its slots in order, the item on each, his modData "hotbar"
    S.was.slots = {}
    for i, sl in ipairs(S.slots()) do S.was.slots[#S.was.slots + 1] = { t = sl.slotType, item = S.attached(i) } end
    local md = S.md()
    S.was.mdh = { had = md.hotbar ~= nil, v = S.copy(md.hotbar) }
    S.was.ws = { had = md.ZeD_WinState ~= nil, v = S.copy(md.ZeD_WinState) }
    S.was.worn = S.wornList()
    S.was.char, S.was.world = S.charOpen(), S.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = S.was.char and S.geo(cw) or nil, w = S.was.world and S.geo(ww) or nil }
    S.was.tab = { c = (S.was.char and cw) and (cw._activeTab or "loot") or nil, w = (S.was.world and ww) and (ww._activeTab or "loot") or nil }
    S.was.speed = getGameSpeed()
    S.ok = true
    local wordsW = {}
    for _, e in ipairs(S.was.worn) do wordsW[#wordsW + 1] = S.itemShow(e.item) end
    Q.say("start: screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ", ZeD's scale " .. tostring(ZeD.T.scale)
        .. ", language " .. S.lang() .. "; Lite " .. tostring(ZeD.Belt.simple and ZeD.Belt.simple()) .. "; hotbar: " .. S.typesText()
        .. "; Character window open " .. tostring(S.was.char) .. ", World window open " .. tostring(S.was.world) .. "; game speed "
        .. tostring(S.was.speed) .. "; Lua errors so far " .. tostring(S.err0) .. "; worn: " .. table.concat(wordsW, ", "))

    -- SIDE 0: the words in the director's language
    local lang = S.lang()
    if lang == "EN" then
        local got = { L = S.tx("UI_ZeD_Belt_SideL"), R = S.tx("UI_ZeD_Belt_SideR"), b = S.tx("UI_ZeD_Belt_SlotBelt"),
                      w = S.tx("UI_ZeD_Belt_SlotWeb"), h = S.tx("UI_ZeD_Belt_SlotHolster") }
        Q.check(got.L == "L" and got.R == "R" and got.b == "Belt" and got.w == "Web" and got.h == "Holster",
            "SIDE 0: EN: getText of UI_ZeD_Belt_SideL / SideR is L / R, of SlotBelt, SlotWeb and SlotHolster Belt, Web and Holster",
            "SideL " .. tostring(got.L) .. ", SideR " .. tostring(got.R) .. ", SlotBelt " .. tostring(got.b) .. ", SlotWeb "
            .. tostring(got.w) .. ", SlotHolster " .. tostring(got.h))
    else
        Q.skip("SIDE 0: the EN words", "the game's language is " .. lang .. ", not EN")
    end

    -- the run's settings: both windows shut (nothing in front of him), the game running for the timed attaches
    S.shutAll()
    if S.was.speed == 0 then S.speed(1) end
    -- the gear that gives every side slot
    S.gear = {}
    for _, ft in ipairs(S.GEAR) do
        local it = S.give(ft)
        local on = it ~= nil and S.wear(it)
        S.gear[#S.gear + 1] = ft .. " worn " .. tostring(on)
    end
    S.refresh()
    if not (S.idxOf("SmallBeltLeft") and S.idxOf("SmallBeltRight")) then
        local it = S.give(S.BELT)
        S.gear[#S.gear + 1] = S.BELT .. " worn " .. tostring(it ~= nil and S.wear(it))
        S.refresh()
    end
end)
S.settle(300, 8000, function() return not S.ok or (S.none() and S.drawnOk() and S.allSideBoxes()) end, function(ok)
    if not S.ok then return end
    if not Q.check(ok, "staging: the worn gear gives all six side slots, each with a box on the belt, both windows shut",
        table.concat(S.gear or {}, ", ") .. "; hotbar: " .. S.typesText() .. "; missing: " .. S.missing() .. "; windows shut "
        .. tostring(S.none()) .. ", the belt drawn " .. tostring(S.drawnOk())) then
        S.ok = false
        return
    end
    -- his own items off the six side slots for the empty read (back on at the end)
    local hb = S.hb()
    for _, e in ipairs(S.SIDES) do
        local i = S.idxOf(e.t)
        local it = i and S.attached(i) or nil
        if it and not S.isGiven(it) then
            S.his[#S.his + 1] = S.itemShow(it) .. " on " .. e.t
            pcall(function() hb:removeItem(it, false) end)
        end
    end
    Q.say("NOTE staged: " .. table.concat(S.gear or {}, ", ") .. "; hotbar now: " .. S.typesText() .. "; his items taken off the side slots for the run: "
        .. ((#S.his > 0) and table.concat(S.his, ", ") or "none"))
end)
Q.waitMs(500)

-- ===================================================================== SIDE 1 to 3: the side slots empty
S.readAndShot("SIDE 1 to 3 (empty)", function(rec)
    local old = S.oldDrawn(rec)
    for _, e in ipairs(S.SIDES) do
        local r = S.markRead(rec, e)
        Q.check(r.ok, "SIDE 1 " .. e.t .. " (empty): the " .. e.sd .. " mark in the top right corner, the key tag's size, in its ink (L a black box, R a white box) "
            .. "(not the accent), the key tag on the accent", r.text)
        -- the plain name
        local b = r.box
        local want = S.ztr(e.key)
        local sn = S.shortName(e.t)
        local drawn = false
        local inBox = b and S.textsIn(rec, b) or {}
        for _, t in ipairs(inBox) do if t.s == want then drawn = true end end
        local empty = b ~= nil and b.s ~= nil and b.s.item == nil
        local en = (S.lang() ~= "EN") or want == e.en
        Q.check(b ~= nil and empty and drawn and sn == want and en and #old == 0,
            "SIDE 2 " .. e.t .. " (empty): the box says the plain " .. tostring(want) .. ", no old Belt L style name on the belt",
            "empty " .. tostring(empty) .. "; shortName " .. tostring(sn) .. ", the translation " .. tostring(want) .. " (EN wants " .. e.en
            .. "); drawn in the box: " .. S.textsWords(inBox) .. "; old names drawn: " .. ((#old > 0) and table.concat(old, ", ") or "none"))
    end
    -- SIDE 3: the slots with no side
    local seen, bad = {}, {}
    local letters = { [tostring(S.ztr("UI_ZeD_Belt_SideL"))] = true, [tostring(S.ztr("UI_ZeD_Belt_SideR"))] = true }
    for _, b in ipairs(S.slotBoxes()) do
        local t = b.s.slot.slotType
        if not S.SIDE_BY[t] then
            seen[#seen + 1] = tostring(t)
            local mk = S.tagAt(rec, b, true)
            if S.sideMark(t) ~= nil then bad[#bad + 1] = t .. ": sideMark gives " .. tostring(S.sideMark(t)) end
            if mk then bad[#bad + 1] = t .. ": a tag in the top right corner " .. S.rectText(mk) .. " on " .. S.colName(mk) end
            for _, tx in ipairs(S.textsIn(rec, b)) do
                if letters[tostring(tx.s)] then bad[#bad + 1] = t .. ": " .. tostring(tx.s) .. " drawn in the box" end
            end
        end
    end
    Q.check(#seen > 0 and #bad == 0, "SIDE 3: no mark on the slots with no side (Back, Shoulder, Ankle, Pack as worn)",
        "slots with no side on the belt: " .. table.concat(seen, ", ") .. ((#bad > 0) and ("; WRONG: " .. table.concat(bad, "; ")) or ""))
end, "empty", "the six side slots empty: Belt, Holster and Web, each with its L or R mark in the top right corner")

-- ===================================================================== SIDE 4: an item on each side slot
-- (QA, Nov 23 2026: one at a time, each waited out: queued together only the first landed, the game's attach
-- action of each replacing the last)
S.attachWords = {}
for _, e in ipairs(S.SIDES) do
    Q.step(2, function()
        if not S.ok then return end
        local it = S.give(e.item)
        S.items[e.t] = it
        local i = S.idxOf(e.t)
        local ok = false
        if it and i then
            local okA, r = pcall(ZeD.Belt.attach, S.pn, it, i)
            ok = okA and r == true
        end
        if ok then S.queued = true end
        S.attachWords[#S.attachWords + 1] = e.item .. " to " .. e.t .. " (slot " .. tostring(i) .. ") " .. (ok and "queued" or "REFUSED")
        S.k.attachWords = table.concat(S.attachWords, ", ")
    end)
    S.wait(15000, function()
        if not S.ok then return true end
        local i = S.idxOf(e.t)
        return i ~= nil and S.items[e.t] ~= nil and S.attached(i) == S.items[e.t]
    end, function() end)
end
S.wait(45000, function()
    if not S.ok then return true end
    for _, e in ipairs(S.SIDES) do
        local i = S.idxOf(e.t)
        if not (i and S.items[e.t] and S.attached(i) == S.items[e.t]) then return false end
    end
    return true
end, function(ok)
    if not S.ok then return end
    Q.check(ok, "staging: an item on each side slot through ZeD.Belt.attach (the game's attach and its timed action)",
        tostring(S.k.attachWords) .. "; hotbar now: " .. S.typesText())
end)
Q.waitMs(400)
S.readAndShot("SIDE 4 (items)", function(rec)
    for _, e in ipairs(S.SIDES) do
        local it = S.items[e.t]
        local i = S.idxOf(e.t)
        local on = it ~= nil and i ~= nil and S.attached(i) == it
        local r = S.markRead(rec, e)
        local tex = nil
        if it then pcall(function() tex = it:getTex() end) end
        local icon = false
        if r.box and tex then
            for _, d in ipairs(rec.texs) do if d.tex == tex and S.inside(d, r.box) then icon = true end end
        end
        Q.check(on and icon and r.ok, "SIDE 4 " .. e.t .. " (with " .. e.item .. "): the item on the slot, its icon drawn in the box, "
            .. "the " .. e.sd .. " mark still in the top right corner in its ink, the key tag on the accent",
            "on the slot " .. tostring(on) .. ", its icon drawn " .. tostring(icon) .. "; " .. r.text)
    end
end, "items", "an item on each side slot (screwdriver, hammer, two pistols, a hunting knife, the flashlight off), the marks kept")

-- ===================================================================== SIDE 5: the flashlight lit, its lamp under the mark
Q.step(2, function()
    if not S.ok then return end
    local fl = S.items[S.LAMP_T]
    S.k.lampOn = false
    if fl then
        pcall(function() fl:setActivated(true) end)
        pcall(function() S.k.lampOn = fl:isActivated() end)
    end
end)
Q.waitMs(300)
S.readAndShot("SIDE 5 (the lamp)", function(rec)
    local e = S.SIDE_BY[S.LAMP_T]
    local fl = S.items[S.LAMP_T]
    local i = S.idxOf(S.LAMP_T)
    local on = fl ~= nil and i ~= nil and S.attached(i) == fl
    local r = S.markRead(rec, e)
    local lamp = nil
    if r.box then
        for _, d in ipairs(rec.lamps) do if S.inside(d, r.box) then lamp = d end end
    end
    local why = {}
    if not (on and S.k.lampOn) then why[#why + 1] = "the flashlight on the slot " .. tostring(on) .. ", lit " .. tostring(S.k.lampOn) end
    if not lamp then why[#why + 1] = "no lamp drawn in the box (" .. #rec.lamps .. " lamps on the belt)" end
    if lamp and r.mark and lamp.y < r.mark.y + r.mark.h - 0.5 then
        why[#why + 1] = "the lamp's top " .. S.num(lamp.y) .. " is above the mark's bottom " .. S.num(r.mark.y + r.mark.h)
    end
    if lamp and r.box and lamp.x + lamp.w > r.box.x + r.box.w + 0.5 then why[#why + 1] = "the lamp reaches past the box's right edge" end
    if not r.ok then why[#why + 1] = "the mark: " .. table.concat(r.why or { "not read" }, "; ") end
    Q.check(#why == 0, "SIDE 5 " .. S.LAMP_T .. ": a lit flashlight's lamp draws under the R mark, inside the box",
        "lamp " .. S.rectText(lamp) .. "; " .. r.text .. ((#why > 0) and ("; WRONG: " .. table.concat(why, "; ")) or ""))
end, "lamp", "the flashlight on the right webbing lit: its lamp under the R mark")
-- (Build, Nov 23 2026, c5f185743: the lit lamp drew in T.warningText, a dark brown in Light; now a fixed amber,
-- ZeD.Belt.LAMP_ON, on a near-black rim, in every theme. Taken again in Dark, then the theme put back.)
S.LAMP_AMBER = function() return ZeD.Belt and ZeD.Belt.LAMP_ON or { r = 1.0, g = 0.78, b = 0.24 } end
Q.step(2, function()
    S.themeWas = ZeD.currentBase
    if ZeD.currentBase ~= "dark" then pcall(ZeD.applyTheme, "dark", ZeD.currentAccent, ZeD.currentSize) end
end)
Q.waitMs(800)
S.readAndShot("SIDE 5 (the lamp, Dark)", function(rec)
    local e = S.SIDE_BY[S.LAMP_T]
    local r = S.markRead(rec, e)
    local lamp = nil
    if r.box then
        for _, d in ipairs(rec.lamps) do if S.inside(d, r.box) then lamp = d end end
    end
    local amber = S.LAMP_AMBER()
    local colOk = lamp ~= nil and (lamp.r == nil or S.sameCol(lamp, amber))
    Q.check(lamp ~= nil and colOk and ZeD.currentBase == "dark",
        "SIDE 5 " .. S.LAMP_T .. " (Dark): the lit lamp draws in the fixed amber under the mark",
        "theme " .. tostring(ZeD.currentBase) .. "; lamp " .. S.rectText(lamp) .. " in " .. S.colName(lamp))
end, "lamp_dark", "the flashlight on the right webbing lit, in the Dark theme")
Q.step(2, function()
    if S.themeWas and ZeD.currentBase ~= S.themeWas then pcall(ZeD.applyTheme, S.themeWas, ZeD.currentAccent, ZeD.currentSize) end
end)
Q.step(2, function()
    local fl = S.items[S.LAMP_T]
    if fl then pcall(function() fl:setActivated(false) end) end
end)

-- ===================================================================== BAG: the row's groups, the bag button under a drag
-- (Nov 23 2026, QA, Build's fix/beltrow2 on main 99d56a202. The director: "Belt, space, time, space, messages, chat"
-- and "Bag lights, speed keys grey".) The bag button's pick is set to the Pocket for these (his modData ZeD_BeltBag
-- put back after). The drags are ISMouseDrag.dragging set to the run's items for one recorded frame (as a ZeD list's
-- drag sets it), the pointer parked off the belt. The drops are ZeD.Belt.takeDrop, as InventoryRenderer.handleDrop
-- calls it, with the belt's own pointer read on the bag button's middle for that one call. The closed stack's list is a
-- stand-in content with the stack model InventoryRenderer builds (its _stacks entry for the row, the stack not open),
-- so IR.dragItems brings the whole stack as a real list's drag does.
S.BAG_KINDS = { "Base.Bag_Schoolbag", "Base.Plasticbag" }
S.PEN_KINDS = { "Base.Pen", "Base.Pencil" }
function S.px(n) local v = nil; pcall(function() v = ZeD.T.px(n) end); return v end
function S.kindBoxes(kind)
    local out = {}
    local hud = S.hud()
    for _, b in ipairs((hud and hud._boxes) or {}) do if b.kind == kind then out[#out + 1] = b end end
    return out
end
function S.addTo(c, ft)
    local it = nil
    pcall(function() it = c:AddItem(ft) end)
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        RT.given[#RT.given + 1] = it
        S.given[#S.given + 1] = it
    end
    return it
end
function S.idOf(it) local id = nil; pcall(function() id = it:getID() end); return id end
function S.idIn(inv, id)
    local found = false
    if not (inv and id) then return false end
    pcall(function()
        local items = inv:getItems()
        for i = 0, items:size() - 1 do if items:get(i):getID() == id then found = true; break end end
    end)
    return found
end
function S.pocket() local c = nil; pcall(function() c = S.p:getInventory() end); return c end
-- the bag button's pick set to the Pocket (his modData ZeD_BeltBag as found kept once), and put back
function S.pickPocket()
    local B = ZeD.Belt
    local key = B and B.BAG_KEY
    if not key then return false end
    local md = S.md()
    if not S.was.bagPick then S.was.bagPick = { had = md[key] ~= nil, v = S.copy(md[key]) } end
    md[key] = nil
    if B._bagCache then B._bagCache[S.pn] = nil end
    return true
end
function S.pickBack()
    local B = ZeD.Belt
    local key = B and B.BAG_KEY
    if not (key and S.was.bagPick) then return end
    local md = S.md()
    if S.was.bagPick.had then md[key] = S.copy(S.was.bagPick.v) else md[key] = nil end
    if B._bagCache then B._bagCache[S.pn] = nil end
    S.k.pickBack = true
end
-- a drag: ISMouseDrag.dragging as a ZeD list's drag sets it (the found value kept once), and let go
function S.dragOn(items)
    if not ISMouseDrag then return false end
    if not S.k.dragSet then S.was.drag = { d = ISMouseDrag.dragging }; S.k.dragSet = true end
    ISMouseDrag.dragging = items
    return true
end
function S.dragOff()
    if S.k.dragSet and ISMouseDrag and S.was.drag then ISMouseDrag.dragging = S.was.drag.d end
    S.k.dragSet = nil
end
-- the belt's own pointer read on box b's middle (its instance fields as found kept), and back
function S.pointAt(b)
    local hud = S.hud()
    if not (hud and b) then return false end
    if not S.pointed then S.pointed = { hud = hud, hx = rawget(hud, "getMouseX"), hy = rawget(hud, "getMouseY") } end
    local lx, ly = b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)
    hud.getMouseX = function() return lx end
    hud.getMouseY = function() return ly end
    return true
end
function S.pointBack()
    local pk = S.pointed
    if not pk then return end
    S.pointed = nil
    pk.hud.getMouseX, pk.hud.getMouseY = pk.hx, pk.hy
end
-- a box's wash in the recorded frame: a rect over the whole box in color c, its alpha within tol of a
function S.wash(rec, b, c, a, tol)
    if not (rec and b and c) then return false end
    for _, r in ipairs(rec.rects) do
        if S.near(r.x, b.x) and S.near(r.y, b.y) and S.near(r.w, b.w) and S.near(r.h, b.h) and type(r.a) == "number"
            and S.near(r.a, a, tol) and S.sameCol(r, c) then return true end
    end
    return false
end
-- the five speed keys grayed: each with the slots' ink wash (ZeD_Belt.lua NO_A 0.45, B.INK) in the frame
function S.keysGray(rec)
    local keys = S.kindBoxes("speed")
    local n = 0
    local ink = ZeD.Belt and ZeD.Belt.INK
    for _, b in ipairs(keys) do if S.wash(rec, b, ink, 0.45, 0.02) then n = n + 1 end end
    return n, #keys
end
-- one recorded frame under a drag of getItems(), the pointer parked; fn(rec, items) reads it while the drag is on
function S.dragFrame(label, getItems, fn)
    Q.step(2, function()
        if not S.ok or S.bagSkip then return end
        local items = getItems()
        S.park(true)
        if not (items and S.dragOn(items)) then S.recErr = "nothing to drag (or no ISMouseDrag)"; S.recDone = true; return end
        if not S.arm() then S.recErr = "the belt or its _prerender is missing"; S.recDone = true end
    end)
    Q.waitFor(1, 300, function() return not S.ok or S.bagSkip or S.recDone == true end, function()
        if not S.ok or S.bagSkip then return end
        S.disarm()
        if S.recOk(label) then fn(S.rec, getItems()) end
        S.dragOff()
        S.park(false)
    end)
end

Q.step(3, function()
    if not S.ok then return end
    local B = ZeD.Belt
    local ready = B.bagTakes ~= nil and B.takeDrop ~= nil and B.noticeScreen ~= nil and type(ZeD_BeltHUD._dropState) == "function"
        and B.BAG_KEY ~= nil and B.ICON_GAP ~= nil and ISMouseDrag ~= nil and ZeD.InventoryRenderer ~= nil
        and ZeD.InventoryRenderer.dragItems ~= nil
    if not Q.check(ready, "BAG: the bag button's drop (ZeD.Belt.bagTakes, takeDrop, _dropState) and the notice's row place are there (Build's fix/beltrow2) (staging)") then
        S.bagSkip = true
        return
    end
    S.pickPocket()
    -- a bag he carries (not worn: not on the bag button's list), a pen and a stack of three in it; a pencil in the Pocket
    for _, ft in ipairs(S.BAG_KINDS) do
        if not S.bagInv then
            local it = S.give(ft)
            local c = nil
            if it then pcall(function() c = it:getInventory() end) end
            if c then S.bagIt, S.bagInv = it, c end
        end
    end
    S.three = {}
    if S.bagInv then
        for _, ft in ipairs(S.PEN_KINDS) do
            if not S.one then
                S.one = S.addTo(S.bagInv, ft)
                if S.one then S.oneFt = ft end
            end
        end
        local sft = (S.oneFt == "Base.Pen") and "Base.Pencil" or "Base.Pen"
        for _ = 1, 3 do
            local it = S.addTo(S.bagInv, sft)
            if it then S.three[#S.three + 1] = it end
        end
    end
    S.inPocket = S.give("Base.Pencil")
    if not Q.check(S.bagInv ~= nil and S.one ~= nil and #S.three == 3 and S.inPocket ~= nil,
        "BAG: staging: a bag he carries with a pen and a stack of three in it, a pencil in the Pocket, the bag button on the Pocket",
        "bag " .. tostring(S.bagIt and S.itemShow(S.bagIt)) .. ", the one " .. tostring(S.oneFt) .. ", the stack " .. #S.three
        .. ", the Pocket's pencil " .. tostring(S.inPocket ~= nil)) then
        S.bagSkip = true
    end
end)
Q.waitMs(400)
-- BAG 1: the row's order and its even group space
Q.step(2, function()
    if not S.ok or S.bagSkip then return end
    local hud = S.hud()
    local boxes = (hud and hud._boxes) or {}
    local kinds = {}
    for _, b in ipairs(boxes) do kinds[#kinds + 1] = tostring(b.kind) end
    local gap = S.px(ZeD.Belt.ICON_GAP)
    local bag = S.kindBoxes("bag")[1]
    local keys = S.kindBoxes("speed")
    local note = S.kindBoxes("notice")[1]
    local handsL, handsR, beltL, beltR = nil, nil, nil, nil
    for _, b in ipairs(boxes) do
        local r = b.x + b.w
        if b.kind == "hand" or b.kind == "watch" or b.kind == "ammo" then
            if not handsL or b.x < handsL then handsL = b.x end
            if not handsR or r > handsR then handsR = r end
        elseif b.kind == "slot" or b.kind == "extra" then
            if b.kind == "slot" and (not beltL or b.x < beltL) then beltL = b.x end
            if not beltR or r > beltR then beltR = r end
        end
    end
    -- (the Full belt's strap is the belt group: from the strap's left end to its right, past the slots' own edges)
    local st = hud and hud._strap
    if st then
        beltL = st.x
        if not beltR or st.x + st.w > beltR then beltR = st.x + st.w end
    end
    local first, last = keys[1], keys[#keys]
    local g1 = (bag and handsL) and (handsL - (bag.x + bag.w)) or nil
    local g2 = (handsR and beltL) and (beltL - handsR) or nil
    local g3 = (first and beltR) and (first.x - beltR) or nil
    local g4 = (note and last) and (note.x - (last.x + last.w)) or nil
    local even = gap ~= nil and S.near(g1, gap) and S.near(g2, gap) and S.near(g3, gap) and S.near(g4, gap)
    local ends = #kinds > 1 and kinds[#kinds] == "notice" and kinds[#kinds - 1] == "speed" and #keys == 5
    Q.check(ends and even, "BAG 1: the belt row ends with the Messages notice after the five speed keys, each group one B.ICON_GAP apart (bag button, hands, belt, speed keys, notice)",
        "kinds " .. table.concat(kinds, ",") .. "; the gaps " .. S.num(g1) .. ", " .. S.num(g2) .. ", " .. S.num(g3) .. ", " .. S.num(g4)
        .. " (B.ICON_GAP " .. S.num(gap) .. " px); Lite " .. tostring(st == nil))
end)
-- BAG 2, BAG 3: a pen from the bag he carries: the Pocket takes it, the button lit; the speed keys gray
S.dragFrame("BAG 2 (a pen from his bag)", function() return S.one and { S.one } or nil end, function(rec, items)
    local hud = S.hud()
    local bb = S.kindBoxes("bag")[1]
    local st = nil
    if hud and bb then pcall(function() st = hud:_dropState(bb, items) end) end
    local dest, list = nil, nil
    pcall(function() dest, list = ZeD.Belt.bagTakes(S.pn, items) end)
    list = list or {}
    local fitC = hud ~= nil and hud._bagDrop ~= nil and hud._bagDrop.fit == true
    local lit = S.wash(rec, bb, ZeD.T.accent, 0.14, 0.02)
    local pk = S.pocket()
    Q.check(st == "fit" and fitC and dest ~= nil and dest == pk and #list == 1 and list[1] == S.one and lit,
        "BAG 2: under a drag of a pen from a bag he carries, the bag button's _dropState is fit (the Pocket takes it) and it draws the accent's wash",
        "_dropState " .. tostring(st) .. ", _bagDrop.fit " .. tostring(fitC) .. "; bagTakes: the Pocket " .. tostring(dest ~= nil and dest == pk)
        .. ", " .. #list .. " that fit; the accent's wash drawn " .. tostring(lit))
    local n, of = S.keysGray(rec)
    Q.check(of == 5 and n == 5, "BAG 3: under a drag the five speed keys draw gray (the ink wash over each)", n .. " of " .. of .. " keys gray")
end)
-- BAG 4: a pencil already in the Pocket: the button grays
S.dragFrame("BAG 4 (a pencil in the Pocket)", function() return S.inPocket and { S.inPocket } or nil end, function(rec, items)
    local hud = S.hud()
    local bb = S.kindBoxes("bag")[1]
    local st = nil
    if hud and bb then pcall(function() st = hud:_dropState(bb, items) end) end
    local list = nil
    pcall(function() local _, l = ZeD.Belt.bagTakes(S.pn, items); list = l end)
    list = list or {}
    local gray = S.wash(rec, bb, ZeD.Belt.INK, 0.45, 0.02)
    local lit = S.wash(rec, bb, ZeD.T.accent, 0.14, 0.02)
    local n, of = S.keysGray(rec)
    Q.check(st == "no" and #list == 0 and gray and not lit and n == 5,
        "BAG 4: under a drag of a pencil already in the Pocket, the bag button's _dropState is no and it draws gray (the speed keys too)",
        "_dropState " .. tostring(st) .. ", " .. #list .. " that fit; gray " .. tostring(gray) .. ", the accent's wash " .. tostring(lit) .. "; " .. n .. " of " .. of .. " keys gray")
end)
-- BAG 5: a drop of the pen on the bag button
Q.step(2, function()
    if not S.ok or S.bagSkip then return end
    local bb = S.kindBoxes("bag")[1]
    S.oneId = S.idOf(S.one)
    S.k.drop1 = false
    if bb and S.pointAt(bb) then
        local ok, took = pcall(ZeD.Belt.takeDrop, S.pn, { S.one })
        S.k.drop1 = ok and took == true
        S.queued = true
    end
    S.pointBack()
end)
S.wait(8000, function() return not S.ok or S.bagSkip or S.idIn(S.pocket(), S.oneId) end, function(ok)
    if not S.ok or S.bagSkip then return end
    local inP, inB = S.idIn(S.pocket(), S.oneId), S.idIn(S.bagInv, S.oneId)
    Q.check(ok and S.k.drop1 and inP and not inB,
        "BAG 5: a drop on the bag button moves the pen into the Pocket (counted by its item id)",
        "takeDrop took it " .. tostring(S.k.drop1) .. "; id " .. tostring(S.oneId) .. " in the Pocket " .. tostring(inP) .. ", still in his bag " .. tostring(inB))
end)
-- BAG 6: a closed stack of three dropped on it (its row's item, the list's stack model with the stack not open)
Q.step(2, function()
    if not S.ok or S.bagSkip then return end
    local bb = S.kindBoxes("bag")[1]
    local t = S.three
    S.threeIds = { S.idOf(t[1]), S.idOf(t[2]), S.idOf(t[3]) }
    local stk = { rep = t[1], items = { t[1], t[2], t[3] }, count = 3, key = "ZeDQA bl_side stack" }
    local content = { _dragSourceInv = S.bagInv, _inventory = S.bagInv, _playerObj = S.p, _stacks = {}, _expandedStacks = {} }
    content._stacks[t[1]] = stk
    S.k.drop3 = false
    if bb and S.pointAt(bb) then
        local ok, took = pcall(ZeD.Belt.takeDrop, S.pn, { t[1] }, content, S.bagInv)
        S.k.drop3 = ok and took == true
        S.queued = true
    end
    S.pointBack()
end)
function S.threeIn(inv)
    local n = 0
    for _, id in ipairs(S.threeIds or {}) do if S.idIn(inv, id) then n = n + 1 end end
    return n
end
S.wait(10000, function() return not S.ok or S.bagSkip or S.threeIn(S.pocket()) == 3 end, function(ok)
    if not S.ok or S.bagSkip then return end
    local inP, inB = S.threeIn(S.pocket()), S.threeIn(S.bagInv)
    Q.check(ok and S.k.drop3 and inP == 3 and inB == 0,
        "BAG 6: a closed stack of 3 dropped on the bag button moves all 3 into the Pocket",
        "takeDrop took it " .. tostring(S.k.drop3) .. "; in the Pocket " .. inP .. " of 3 (by id), still in his bag " .. inB)
end)
Q.step(2, function()
    S.dragOff()
    S.pointBack()
    S.pickBack()
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    S.disarm()
    S.park(false)
    S.dragOff(); S.pointBack(); S.pickBack()   -- (the BAG checks: Nov 23 2026)
    for _, it in ipairs(S.given) do pcall(function() if it:isActivated() then it:setActivated(false) end end) end
    if S.queued then pcall(function() ISTimedActionQueue.clear(S.p) end) end
    local hb = S.hb()
    if hb then
        for _, it in ipairs(S.given) do pcall(function() if it:getAttachedSlot() > -1 then hb:removeItem(it, false) end end) end
    end
    S.shutAll()
end)
S.wait(5000, function() return S.none() end, function(ok)
    if not ok then S.shutAll() end
    if not S.was.worn then return end
    -- the worn items as found: the run's taken off, his own back where they were
    for _, it in ipairs(S.given) do S.unwear(it) end
    for _, e in ipairs(S.was.worn) do
        local now = nil
        pcall(function() now = S.p:getWornItem(e.loc) end)
        if now ~= e.item then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
    S.refresh()
    pcall(RT.takeBack)
    S.hotbarBack()
    local md = S.md()
    if S.was.mdh then
        if S.was.mdh.had then md.hotbar = S.copy(S.was.mdh.v) else md.hotbar = nil end
    end
    if S.was.ws then
        if S.was.ws.had then md.ZeD_WinState = S.copy(S.was.ws.v) else md.ZeD_WinState = nil end
    end
    if S.was.speed == 0 then S.speed(0) end   -- (the run only set x1 when it found the game paused)
    -- the windows open as found (the found window state loads on open)
    if S.was.char and S.was.world then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn)
    elseif S.was.char then pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif S.was.world then pcall(ZeD_WorldWindow.open, S.pn) end
end)
S.settle(300, 5000, function() return S.charOpen() == (S.was.char == true) and S.worldOpen() == (S.was.world == true) end, function()
    if S.was.char then
        S.placeBack(RT.cw(), S.was.geo and S.was.geo.c)
        if S.was.tab and S.was.tab.c then pcall(RT.charTab, S.was.tab.c) end
    end
    if S.was.world then
        S.placeBack(RT.ww(), S.was.geo and S.was.geo.w)
        if S.was.tab and S.was.tab.w then pcall(RT.worldTab, S.was.tab.w) end
    end
end)
Q.step(4, function()
    if not S.was.worn then Q.say("NOTE nothing was recorded or changed: no put-back to read"); return end
    -- the worn items
    local wornNow = S.wornList()
    local bad = {}
    for _, e in ipairs(S.was.worn) do
        local now = nil
        pcall(function() now = S.p:getWornItem(e.loc) end)
        if now ~= e.item then bad[#bad + 1] = S.itemShow(e.item) .. " not back on" end
    end
    for _, it in ipairs(S.given) do
        if S.isWorn(it) then bad[#bad + 1] = S.itemShow(it) .. " (the run's) still worn" end
        if S.inInv(it) then bad[#bad + 1] = S.itemShow(it) .. " (the run's) still in his inventory" end
    end
    Q.check(#bad == 0 and #wornNow == #S.was.worn, "put back: every worn item as found, the run's gear and items taken away",
        "worn now " .. #wornNow .. " (found " .. #S.was.worn .. ")" .. ((#bad > 0) and ("; " .. table.concat(bad, "; ")) or ""))
    -- the hotbar
    local hbad = {}
    local sl = S.slots()
    if #sl ~= #S.was.slots then hbad[#hbad + 1] = #sl .. " slots, found " .. #S.was.slots end
    for i, f in ipairs(S.was.slots) do
        if not (sl[i] and sl[i].slotType == f.t) then hbad[#hbad + 1] = "slot " .. i .. " is " .. tostring(sl[i] and sl[i].slotType) .. ", found " .. f.t end
        if S.attached(i) ~= f.item then
            hbad[#hbad + 1] = "slot " .. i .. " holds " .. tostring(S.attached(i) and S.itemShow(S.attached(i))) .. ", found "
                .. tostring(f.item and S.itemShow(f.item))
        end
    end
    local mdh = S.md().hotbar
    if S.was.mdh and S.was.mdh.had then
        for i, t in ipairs(S.was.mdh.v or {}) do
            if not (type(mdh) == "table" and mdh[i] == t) then hbad[#hbad + 1] = "modData hotbar " .. i .. " is " .. tostring(type(mdh) == "table" and mdh[i]) .. ", found " .. tostring(t) end
        end
    end
    Q.check(#hbad == 0, "put back: the hotbar's slots in the found order, his items on their found slots, his modData hotbar as found",
        "hotbar now: " .. S.typesText() .. "; reordered " .. tostring(S.reordered == true) .. ((#hbad > 0) and ("; WRONG: " .. table.concat(hbad, "; ")) or ""))
    -- the flashlight
    local fl = S.items[S.LAMP_T]
    local flLit = false
    if fl then pcall(function() flLit = fl:isActivated() end) end
    Q.check(fl == nil or (not flLit and not S.inInv(fl)), "put back: the flashlight off and gone",
        "lit " .. tostring(flLit) .. ", in his inventory " .. tostring(fl ~= nil and S.inInv(fl)))
    -- the recorder, the pointer
    local hud = S.was.hud
    local rawOk = true
    for _, k in ipairs(S.RAW) do if hud and rawget(hud, k) ~= S.was.raw[k] then rawOk = false end end
    local clean = rawOk and ZeD_BeltHUD._prerender == S.origPreFound and ZeD.Atoms.drawLamp == S.origLamp
        and getMouseX == S.gmx and getMouseY == S.gmy and S.parked == nil and S.cursorHidden == nil
    Q.check(clean, "put back: no wrapper left (the belt's _prerender, its draw methods and pointer reads, ZeD.Atoms.drawLamp, the global pointer)",
        "belt fields " .. tostring(rawOk) .. ", _prerender " .. tostring(ZeD_BeltHUD._prerender == S.origPreFound) .. ", drawLamp "
        .. tostring(ZeD.Atoms.drawLamp == S.origLamp) .. ", pointer " .. tostring(getMouseX == S.gmx and getMouseY == S.gmy))
    -- the BAG checks' drag, the belt's pointer read and the bag button's pick (Nov 23 2026)
    if S.was.bagPick then
        local key = ZeD.Belt and ZeD.Belt.BAG_KEY
        local now = key and S.md()[key] or nil
        local was = S.was.bagPick.v
        local same = (now == nil and was == nil) or (type(now) == "table" and type(was) == "table" and now.id == was.id and now.type == was.type)
        local dragWas = S.was.drag and S.was.drag.d or nil
        local dragNow = ISMouseDrag and ISMouseDrag.dragging or nil
        Q.check(same and S.k.dragSet == nil and S.pointed == nil and dragNow == dragWas,
            "put back: the bag button's pick (his modData ZeD_BeltBag), the drag and the belt's pointer read as found",
            "pick " .. tostring(type(now) == "table" and now.type or now) .. " (found " .. tostring(type(was) == "table" and was.type or was)
            .. "); dragging " .. tostring(dragNow ~= nil) .. " (found " .. tostring(dragWas ~= nil) .. ")")
    end
    -- the windows, the speed
    local cw, ww = S.charOpen(), S.worldOpen()
    Q.check(cw == (S.was.char == true) and ww == (S.was.world == true) and getGameSpeed() == S.was.speed,
        "put back: the windows open or shut as found, the game speed as found",
        "Character " .. tostring(cw) .. " (found " .. tostring(S.was.char) .. "), World " .. tostring(ww) .. " (found " .. tostring(S.was.world)
        .. "); game speed " .. tostring(getGameSpeed()) .. " (found " .. tostring(S.was.speed) .. ")")
    -- the Lua errors
    local e1 = S.errN()
    if S.err0 and e1 then
        Q.check(e1 == S.err0, "the run made no new Lua error", (e1 - S.err0) .. " new (" .. e1 .. " now)")
    else
        Q.skip("the run made no new Lua error", "the game gives no error count here")
    end
end)
Q.start()
