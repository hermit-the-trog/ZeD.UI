-- ZeD-UI/42/media/lua/client/ZeD/EquipDoll.lua
-- ============================================================================
-- THE EQUIP TAB'S DOLL VIEW (Oct 19 2026, mockup zed_equip_doll_v3.html)
-- Director, Oct 17 2026: "avatar view with lines drawn at right angle to reach
-- the target not as the crow flies and list view are the two we want" ...
-- "yup, make head straight line and I think we have our equipped".
--
-- The character's own 3D model (the Identity tab's ISUI3DModel, full body) in
-- a narrow photo frame, the worn slots in a column either side, the hands and
-- the belt's slots in a row below. Each slot points at a stretch of the body
-- with a right-angle leader line: straight in when the slot is level with its
-- stretch ("if it doesnt need a bend dont make one"), otherwise one turn in its
-- own lane, lanes 16 apart, lower slots nearer the body, so no two lines run
-- side by side or cross.
--
-- Selecting a slot opens the same item card a list row opens (the outermost
-- layer; the card's layer strip steps inward). The list stays the other view;
-- the choice is a ZeD option (Settings.lua equipView), set by the toggle in the
-- Equipped heading too.
--
-- The 3D model and the lines are window children (CharacterWindow): a model
-- can't live in a stencilled panel, and the lines must sit ABOVE the model so
-- their dots land on the body. Everything else draws here, in the drawer.
--
-- Every number below is a design unit in the mockup's 520-wide doll; the doll
-- scales to fit the drawer (never wider than it, at least 0.7 of full size
-- tall, then the tab scrolls).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.EquipDoll = ZeD.EquipDoll or {}
local D = ZeD.EquipDoll

local BASE_W   = 520
local SLOT_W   = 76          -- a slot: its box, its label under it
local BOX      = 58
local BOX_IN   = 9           -- box inset in the slot ((76 - 58) / 2)
local ROW0     = 16
local ROW_STEP = 82
local COL_L, COL_R = 18, 426
local PHOTO    = { x = 140, y = 6, w = 240, h = 528 }
local BELOW_Y  = 540
local BELOW_STEP = 80
local BELT_X0  = 260
local LANES_L  = { 100, 116, 132, 148, 164, 180 }
local LANES_R  = { 420, 404, 388, 372 }
local MIN_FIT  = 0.7

local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end

-- The worn slots: side, row, the stretch of the body each points at (x, from
-- y to y, in the doll's units: the photo's centre is x 260) and the body
-- locations each one gathers. Vanilla's locations, lower case, no underscores.
D.SLOTS = {
    { id = "head",  key = "IGUI_health_Head",  side = "L", row = 0, av = { 262, 40, 92 },
      locs = set{ "hat", "fullhat", "fullsuithead", "fullsuitheadscba",
                  "mask", "maskeyes", "maskfull", "ears", "eartop", "nose" } },
    { id = "eyes",  key = "UI_ZeD_Doll_Eyes",  side = "L", row = 1, av = { 258, 80, 80 },
      locs = set{ "eyes", "lefteye", "righteye" } },
    { id = "neck",  key = "UI_ClothingType_Neck",  side = "L", row = 2, av = { 262, 116, 116 },
      locs = set{ "scarf", "necktexture", "necklace", "necklacelong", "neck" } },
    { id = "torso", key = "UI_ZeD_Doll_Torso", side = "L", row = 3, av = { 256, 186, 186 },
      locs = set{ "tshirt", "tanktop", "shirt", "shortsleeveshirt", "torso1", "torso1legs1", "torsoextra",
                  "underwear", "underweartop", "underwearextra1", "underwearextra2" } },
    { id = "outer", key = "UI_ZeD_Doll_Outer", side = "L", row = 4, av = { 212, 230, 230 },
      locs = set{ "jacket", "jacketdown", "jacketbulky", "jacketsuit", "boilersuit", "fullsuit", "fulltop", "bathrobe",
                  "fullrobe", "bodycostume", "sweater", "jersey", "torsoextravest", "torsoextravestbullet", "cuirass",
                  "sweaterhat", "jackethat", "jackethatbulky",   -- hooded tops: a jacket, with its hood
                  "gorget", "vesttexture", "shoulderholster" } },
    { id = "hands", key = "UI_ZeD_Doll_Hands", side = "L", row = 5, av = { 200, 320, 320 },
      locs = set{ "hands", "handsleft", "handsright", "leftmiddlefinger", "rightmiddlefinger", "leftringfinger",
                  "rightringfinger" } },
    { id = "back",  key = "UI_ClothingType_Back",  side = "R", row = 0, av = { 312, 150, 150 },
      locs = set{ "back", "satchel" } },
    { id = "belt",  key = "UI_ClothingType_Belt",  side = "R", row = 2, av = { 292, 236, 236 },
      locs = set{ "belt", "beltextra", "fannypackfront", "fannypackback", "webbing", "ankleholster", "ammostrap" } },
    { id = "arms",  key = "UI_ZeD_Doll_Arms",  side = "R", row = 3, av = { 322, 280, 300 },
      locs = set{ "leftwrist", "rightwrist", "leftarm", "rightarm", "forearmleft", "forearmright", "elbowleft",
                  "elbowright", "shoulderpadleft", "shoulderpadright", "sportshoulderpad", "sportshoulderpaddontop" } },
    { id = "legs",  key = "UI_ClothingType_Legs1",  side = "R", row = 4, av = { 300, 260, 460 },
      locs = set{ "pants", "pantsskinny", "pantsextra", "shortpants", "shortsshort", "legs1", "skirt", "longskirt",
                  "dress", "longdress", "underwearbottom", "codpiece", "kneeleft", "kneeright", "thighleft", "thighright",
                  "calfleft", "calfright", "calflefttexture", "calfrighttexture", "gaiterleft", "gaiterright" } },
    { id = "feet",  key = "UI_ZeD_Doll_Feet",  side = "R", row = 5, av = { 300, 492, 492 },
      locs = set{ "socks", "shoes" } },
}
local LOC_TO_SLOT = {}
for _, s in ipairs(D.SLOTS) do for loc in pairs(s.locs) do LOC_TO_SLOT[loc] = s.id end end

local function call(o, m, ...)
    if not o then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end

-- ----------------------------------------------------------------------------
-- The view (List or Doll), a ZeD option
-- ----------------------------------------------------------------------------
function D.view()
    local o = ZeD.Settings and ZeD.Settings.equipViewOption
    local v = o and call(o, "getValue")
    return (v == 2) and "doll" or "list"
end

function D.setView(v)
    local o = ZeD.Settings and ZeD.Settings.equipViewOption
    if not o then return end
    call(o, "setValue", v == "doll" and 2 or 1)
    if PZAPI and PZAPI.ModOptions then pcall(PZAPI.ModOptions.save, PZAPI.ModOptions) end
end

-- ----------------------------------------------------------------------------
-- What is worn where
-- ----------------------------------------------------------------------------
-- slots[id] = { def, items } (outermost first); main, off; belt = ZeD.Belt.slots
function D.gather(p, pn)
    local out = { slots = {}, main = nil, off = nil, belt = {} }
    for _, s in ipairs(D.SLOTS) do out.slots[s.id] = { def = s, items = {} } end
    if not p then return out end
    local worn = call(p, "getWornItems")
    local n = worn and call(worn, "size") or 0
    -- vanilla keeps worn items innermost first (BodyLocations.lua order); the
    -- doll leads with the outermost
    for i = n - 1, 0, -1 do
        local wi = worn:get(i)
        local item = wi and call(wi, "getItem")
        local loc = wi and call(wi, "getLocation")
        if item and loc then
            local ls = string.lower(tostring(loc))
            local c = ls:find(":")
            if c then ls = ls:sub(c + 1) end
            ls = ls:gsub("_", "")
            local id = LOC_TO_SLOT[ls]
            if id then table.insert(out.slots[id].items, item) end
        end
    end
    out.main = call(p, "getPrimaryHandItem")
    local off = call(p, "getSecondaryHandItem")
    if off ~= out.main then out.off = off end
    local B = ZeD.Belt
    if B and B.slots then
        local ok, s = pcall(B.slots, pn or 0)
        if ok and s then out.belt = s end
    end
    return out
end

-- The items behind a doll slot key ("doll:torso", "doll:main", "doll:belt3")
local function itemsFor(data, key)
    local id = key and key:sub(6)
    if not (data and id) then return {} end
    if data.slots[id] then return data.slots[id].items end
    if id == "main" then return { data.main } end
    if id == "off" then return { data.off } end
    local bi = tonumber(id:match("^belt(%d+)$") or "")
    if bi then
        for _, s in ipairs(data.belt) do if s.i == bi then return { s.item } end end
    end
    return {}
end

-- The card's item for the selection: item, layer index, layer count
function D.selection(win)
    local key = win and win._equipSelected
    if not (type(key) == "string" and key:sub(1, 5) == "doll:") then return nil end
    win._equipDollData = D.gather(win._playerObj, win.playerNum or 0)
    local items = itemsFor(win._equipDollData, key)
    local n = #items
    if n == 0 or not items[1] then return nil, 0, 0 end
    local i = math.max(1, math.min(n, win._equipLayer or 1))
    win._equipLayer = i
    return items[i], i, n
end

function D.isDollKey(key) return type(key) == "string" and key:sub(1, 5) == "doll:" end

-- ----------------------------------------------------------------------------
-- Layout
-- ----------------------------------------------------------------------------
local function beltRows(n) return math.max(1, math.ceil(n / 3)) end

local function baseH(nBelt)
    return BELOW_Y + (beltRows(nBelt) - 1) * ROW_STEP + BOX + 24
end

-- The doll's scale for a drawer w wide with viewH to show it in
local function fit(w, viewH, nBelt)
    local U = ZeD.T.px(1000) / 1000
    local byW = w / (BASE_W * U)
    local byH = viewH / (baseH(nBelt) * U)
    return math.min(1, byW, math.max(MIN_FIT, byH))
end

function D.measure(win, w, viewH)
    local data = win._equipDollData
    local nBelt = data and #data.belt or 0
    local s = fit(w, viewH, nBelt)
    local U = ZeD.T.px(1000) / 1000
    return math.floor(baseH(nBelt) * s * U + 0.5)
end

-- ----------------------------------------------------------------------------
-- Drawing
-- ----------------------------------------------------------------------------
local function condColor(T, f)
    if f > 0.6 then return T.positive elseif f > 0.3 then return T.warningText end
    return T.danger
end

local function dashed(p, x, y, w, h, c, a)
    local d = ZeD.T.px(3)
    for i = 0, w - 1, d * 2 do
        local l = math.min(d, w - i)
        p:drawRect(x + i, y, l, ZeD.T.px(1), a, c.r, c.g, c.b)
        p:drawRect(x + i, y + h - ZeD.T.px(1), l, ZeD.T.px(1), a, c.r, c.g, c.b)
    end
    for i = 0, h - 1, d * 2 do
        local l = math.min(d, h - i)
        p:drawRect(x, y + i, ZeD.T.px(1), l, a, c.r, c.g, c.b)
        p:drawRect(x + w - ZeD.T.px(1), y + i, ZeD.T.px(1), l, a, c.r, c.g, c.b)
    end
end

local function itemTex(item)
    return call(item, "getTex") or call(item, "getTexture")
end

local function condOf(item)
    local m = call(item, "getConditionMax") or 0
    if m <= 0 then return nil end
    return math.max(0, math.min(1, (call(item, "getCondition") or 0) / m))
end

-- The controller is on this element of the Equip tab: the window has the focus,
-- the controller is in use (Focus.liveZone) and the focus is in the tab's zone.
-- Returns the focus mark's opts when it is, else false.
local _focusOpts = {}
local function gpFocused(win, key)
    if win._gpFocusedEquipSlot ~= key then return false end
    local Focus = ZeD.Input and ZeD.Input.Focus
    local z = Focus and Focus.liveZone and Focus.liveZone(win)
    if not (z and z.zone == "charTabContent") then return false end
    _focusOpts.win, _focusOpts.zone = win, "charTabContent"
    return _focusOpts
end

-- the pointer's hover is off while the controller's mark shows
local function cuesOn()
    local Focus = ZeD.Input and ZeD.Input.Focus
    return Focus and Focus.cuesVisible and Focus.cuesVisible() or false
end

-- one slot box: the item's picture, its condition (the framed strip), the
-- layer count or the belt key; empty boxes dashed. The pointer's hover wash and
-- the controller's focus mark go under the picture. bx, by, b = the box in
-- panel coords.
local function drawBox(panel, win, bx, by, b, item, nLayers, key, beltKey, label, mx, my)
    local T, tm = ZeD.T, ZeD.TM
    local ac = T.accent
    local over = mx >= bx and mx < bx + b and my >= by and my < by + b
    local hover = over and not cuesOn()
    if item then
        local st = T.stripe
        panel:drawRect(bx, by, b, b, st.a, st.r, st.g, st.b)
        if ZeD.EquipmentTab and ZeD.EquipmentTab.draggedItem(win) == item then
            -- being dragged: dimmed, as the inventory lists dim the rows they carry
            local s1 = T.surf1
            panel:drawRect(bx, by, b, b, 0.4, s1.r, s1.g, s1.b)
        end
    end
    if hover then
        local hv = T.hover
        panel:drawRect(bx, by, b, b, hv.a, hv.r, hv.g, hv.b)
    end
    local fo = gpFocused(win, key)
    if fo then ZeD.Focus.mark(panel, bx, by, b, b, fo) end
    if item then
        local bs = T.borderS
        panel:drawRectBorder(bx, by, b, b, bs.a or 1, bs.r, bs.g, bs.b)
        local tex = itemTex(item)
        local isz = math.floor(b * 36 / 58)
        if tex then
            panel:drawTextureScaledAspect(tex, bx + math.floor((b - isz) / 2), by + math.floor((b - isz) / 2) - T.px(2), isz, isz, 1, 1, 1, 1)
        end
        local f = condOf(item)
        if f then
            local ch = T.px(5)
            ZeD.Atoms.drawFillBar(panel, bx + T.px(4), by + b - T.px(3) - ch, b - T.px(8), f, false, condColor(T, f), ch)
        end
    else
        local dc = T.textDim
        dashed(panel, bx, by, b, b, dc, 0.35)
    end
    local f1 = T.fontF1
    local f1h = T.fontF1H or tm:getFontHeight(f1)
    if nLayers and nLayers > 1 then
        local t = tostring(nLayers)
        local tw = math.max(tm:MeasureStringX(f1, t) + T.px(6), f1h)
        local s4, bs = T.surf4, T.borderS
        panel:drawRect(bx + b - tw, by, tw, f1h, s4.a or 1, s4.r, s4.g, s4.b)
        panel:drawRect(bx + b - tw, by + f1h, tw, T.px(1), bs.a or 1, bs.r, bs.g, bs.b)
        panel:drawRect(bx + b - tw - T.px(1), by, T.px(1), f1h, bs.a or 1, bs.r, bs.g, bs.b)
        local tc = T.text
        panel:drawText(t, bx + b - tw + math.floor((tw - tm:MeasureStringX(f1, t)) / 2), by, tc.r, tc.g, tc.b, tc.a or 1, f1)
    end
    if beltKey then
        local tw = math.max(tm:MeasureStringX(f1, beltKey) + T.px(6), f1h)
        local bgc = item and ac or T.surf3
        local tc = item and T.textOnAccent or T.textDim
        panel:drawRect(bx, by, tw, f1h, bgc.a or 1, bgc.r, bgc.g, bgc.b)
        panel:drawText(beltKey, bx + math.floor((tw - tm:MeasureStringX(f1, beltKey)) / 2), by, tc.r, tc.g, tc.b, tc.a or 1, f1)
    end
    if hover then
        ZeD.Help.set(panel, item and ZeD.tr("UI_ZeD_Doll_SlotHelp", call(item, "getDisplayName") or label)
            or ZeD.tr("UI_ZeD_Doll_EmptyHelp", label))
    end
    -- the label, centred under the box (an empty slot's at the disabled alpha)
    local lc = T.textDim
    local la = (lc.a or 1) * (item and 1 or T.disabledAlpha)
    local lw = tm:MeasureStringX(f1, label)
    panel:drawText(label, bx + math.floor((b - lw) / 2), by + b + T.px(3), lc.r, lc.g, lc.b, la, f1)
    return over
end

-- Draws the doll at (x, y) in a drawer w wide with viewH of viewport. Stamps
-- win._equipSlotZones (filled slots: the card), win._equipBeltZones (empty
-- belt slots: the attach list), win._equipDollPhoto (the model's frame),
-- win._equipDollLines (for the line layer), win._equipDollHint. Returns height.
function D.draw(panel, win, x, y, w, viewH, mx, my)
    local T, tm = ZeD.T, ZeD.TM
    win._equipDollTimer = (win._equipDollTimer or 0) + 1
    if win._equipDollTimer >= 15 or not win._equipDollData then
        win._equipDollTimer = 0
        win._equipDollData = D.gather(win._playerObj, win.playerNum or 0)
    end
    local data = win._equipDollData
    local nBelt = #data.belt
    local s = fit(w, viewH, nBelt)
    local k = s * ZeD.T.px(1000) / 1000
    local ox = x + math.max(0, math.floor((w - BASE_W * k) / 2))
    local function P(v) return math.floor(v * k + 0.5) end
    local b = P(BOX)

    -- the photo frame (the model draws over it, from CharacterWindow)
    local fx, fy, fw, fh = ox + P(PHOTO.x), y + P(PHOTO.y), P(PHOTO.w), P(PHOTO.h)
    local frame = T.surf2
    panel:drawRect(fx, fy, fw, fh, frame.a, frame.r, frame.g, frame.b)
    local bc = T.border
    panel:drawRectBorder(fx, fy, fw, fh, bc.a or 1, bc.r, bc.g, bc.b)
    local p = win._playerObj
    local desc = p and call(p, "getDescriptor")
    local nm = desc and ((call(desc, "getForename") or "") .. " " .. (call(desc, "getSurname") or "")) or ""
    if nm ~= " " then
        local f1 = T.fontF1
        local dc = T.textDim
        panel:drawText(ZeD.Atoms.truncateText(nm, f1, fw - T.px(16)), fx + T.px(8), fy + fh - T.px(6) - (T.fontF1H or tm:getFontHeight(f1)),
            dc.r, dc.g, dc.b, dc.a or 1, f1)
    end
    win._equipDollPhoto = { x = fx + T.px(1), y = fy + T.px(1), w = fw - T.px(2), h = fh - T.px(2) }

    local zones, beltZones, lines, empties = {}, {}, {}, {}
    local hint = nil
    local li, ri = 0, 0
    for _, def in ipairs(D.SLOTS) do
        local sx0 = (def.side == "L") and COL_L or COL_R
        local sy0 = ROW0 + def.row * ROW_STEP
        local bx, by = ox + P(sx0 + BOX_IN), y + P(sy0)
        local items = data.slots[def.id].items
        local item = items[1]
        local key = "doll:" .. def.id
        local over = drawBox(panel, win, bx, by, b, item, #items, key, nil, ZeD.textCase(ZeD.tr(def.key)), mx, my)
        if item then
            zones[#zones + 1] = { x = bx, y = by, w = b, h = b, type = key, item = item }
            if over then
                local t = call(item, "getDisplayName") or "?"
                if #items > 1 then t = ZeD.tr("UI_ZeD_Doll_Under", t, #items - 1) end
                hint = { key = key, text = t, x = bx, y = by, w = b }
            end
        else
            -- an empty slot is still a stop for the pad, so D-pad moves keep to
            -- the doll's columns and rows (nothing happens on A)
            empties[#empties + 1] = { x = bx, y = by, w = b, h = b, type = key }
        end
        win._equipSlotYMap[key] = by
        -- the leader line, in the doll's units first: level out of the box,
        -- one turn in a lane when the slot isn't level with its stretch
        local left = def.side == "L"
        local lsx = left and (sx0 + BOX_IN + BOX) or (sx0 + BOX_IN)
        local lsy = sy0 + 30
        local ax = def.av[1]
        local ay = math.max(def.av[2], math.min(def.av[3], lsy))
        local pts
        if math.abs(ay - lsy) < 1 then
            pts = { lsx, lsy, ax, ay }
        else
            local lane
            if left then li = li + 1; lane = LANES_L[li] or LANES_L[#LANES_L]
            else ri = ri + 1; lane = LANES_R[ri] or LANES_R[#LANES_R] end
            pts = { lsx, lsy, lane, lsy, lane, ay, ax, ay }
        end
        for i = 1, #pts, 2 do pts[i] = ox + P(pts[i]); pts[i + 1] = y + P(pts[i + 1]) end
        lines[#lines + 1] = pts
    end

    -- the row below: the hands, then the belt's slots (three to a row)
    local function below(key, label, item, bx0, by0, beltKey, beltSlot)
        local bx, by = ox + P(bx0 + BOX_IN), y + P(by0)
        local over = drawBox(panel, win, bx, by, b, item, 1, key, beltKey, label, mx, my)
        win._equipSlotYMap[key] = by
        if item then
            zones[#zones + 1] = { x = bx, y = by, w = b, h = b, type = key, item = item }
            if over then hint = { key = key, text = call(item, "getDisplayName") or "?", x = bx, y = by, w = b } end
        elseif not beltSlot then
            empties[#empties + 1] = { x = bx, y = by, w = b, h = b, type = key }
        elseif beltSlot then
            -- an empty belt slot: A / a click opens its attach list (the list's ATTACH)
            local fid = "belt:" .. tostring(beltSlot.i)
            beltZones[#beltZones + 1] = { x = bx, y = by, w = b, h = b, i = beltSlot.i, item = nil, action = "attach",
                                          btn = { x = bx, y = by, w = b, h = b }, fid = fid }
            win._equipSlotYMap[fid] = by
            if over then hint = { key = fid, text = ZeD.tr("UI_ZeD_Doll_EmptyHint", (ZeD.Belt and ZeD.Belt.slotName(beltSlot.slot)) or label), x = bx, y = by, w = b } end
        end
    end
    below("doll:main", ZeD.tr("UI_ZeD_Doll_Main"), data.main, 30, BELOW_Y)
    below("doll:off", ZeD.tr("UI_ZeD_Doll_Off"), data.off, 110, BELOW_Y)
    for n, bs in ipairs(data.belt) do
        local r, c = math.floor((n - 1) / 3), (n - 1) % 3
        local key = bs.item and ("doll:belt" .. tostring(bs.i)) or nil
        local label = ZeD.tr("UI_ZeD_Doll_BeltSlot", tostring(bs.key or bs.i))
        below(key or ("belt:" .. tostring(bs.i)), label, bs.item, BELT_X0 + c * BELOW_STEP, BELOW_Y + r * ROW_STEP,
              bs.key and tostring(bs.key) or nil, bs)
    end

    win._equipSlotZones = zones
    win._equipBeltZones = beltZones
    win._equipDollEmpty = empties
    win._equipDollLines = lines
    win._equipDollDot = math.max(2, P(2.5))
    win._equipDollHintCand = hint
    return math.floor(baseH(nBelt) * k + 0.5)
end

-- The 3D model copies the character's look when it is bound; rebind it when
-- the clothes change (vanilla's character screen does the same), so the doll
-- and the Identity photo wear what the slots show.
if Events and Events.OnClothingUpdated then
    Events.OnClothingUpdated.Add(function(chr)
        local w = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
        if w and w._identityModel and chr == w._playerObj then w._identityModel._characterBound = false end
    end)
end

-- ----------------------------------------------------------------------------
-- The pad across the figure: Left / Right between the two columns go to the
-- nearest row on the other side (the columns don't line up row for row, and
-- the photo between them would otherwise send the press out of the doll).
-- Right from the right column / Left from the left one leave as usual.
-- ----------------------------------------------------------------------------
local SLOT_BY_ID = {}
for _, s in ipairs(D.SLOTS) do SLOT_BY_ID[s.id] = s end

local function slotOf(key)
    if type(key) ~= "string" or key:sub(1, 5) ~= "doll:" then return nil end
    return SLOT_BY_ID[key:sub(6)]
end

function D.dpad(w, el, dir)
    if dir ~= "left" and dir ~= "right" then return false end
    local def = slotOf(el and el.slotType)
    if not def then return false end
    if (def.side == "L") ~= (dir == "right") then return false end
    local zi, zone
    for i, z in ipairs(w._focusRing or {}) do if z.zone == "charTabContent" then zi, zone = i, z; break end end
    if not zone then return false end
    local best, bestD, bestRow
    for j, e in ipairs(zone.elements or {}) do
        local d2 = slotOf(e.slotType)
        if d2 and d2.side ~= def.side then
            local dd = math.abs(d2.row - def.row)
            if not best or dd < bestD or (dd == bestD and d2.row < bestRow) then best, bestD, bestRow = j, dd, d2.row end
        end
    end
    if not best then return false end
    w._focusIdx = zi
    zone.focusedElementIdx = best
    local e = zone.elements[best]
    if e.onFocus then e.onFocus(w, e) end
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)
    return true
end

-- ----------------------------------------------------------------------------
-- The line layer: a window child above the 3D model (CharacterWindow places it
-- over the drawer each frame and hides it when the doll isn't showing). Mouse
-- events pass through it to the drawer.
-- ----------------------------------------------------------------------------
function D.newLineLayer(win)
    local layer = ISPanel:new(0, 0, 10, 10)
    layer:initialise()
    layer:instantiate()
    layer.background = false
    layer.javaObject:setConsumeMouseEvents(false)
    layer.prerender = function(self) end
    layer.render = function(self) D.renderLines(self, win) end
    layer.onMouseDown = function() return false end
    layer.onMouseUp = function() return false end
    layer.onMouseWheel = function() return false end
    layer:setVisible(false)
    return layer
end

-- lines + dots, clipped to the drawer's scroll viewport; then the hover hint
function D.renderLines(layer, win)
    local T = ZeD.T
    local clip = win._equipDollClip
    local lines = win._equipDollLines
    if not (clip and lines) then return end
    layer:setStencilRect(clip.x, clip.y, clip.w, clip.h)
    local t = T.px(1)
    local la = 0.42
    for _, pts in ipairs(lines) do
        for i = 1, #pts - 2, 2 do
            local x1, y1, x2, y2 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
            if y1 == y2 then
                layer:drawRect(math.min(x1, x2), y1, math.abs(x2 - x1) + t, t, la, 1, 1, 1)
            else
                layer:drawRect(x1, math.min(y1, y2), t, math.abs(y2 - y1) + t, la, 1, 1, 1)
            end
        end
        local d = win._equipDollDot or 2
        local ex, ey = pts[#pts - 1], pts[#pts]
        layer:drawRect(ex - d, ey - d + t, d * 2 + t, d * 2 - t, 0.75, 1, 1, 1)
        layer:drawRect(ex - d + t, ey - d, d * 2 - t, d * 2 + t, 0.75, 1, 1, 1)
    end
    layer:clearStencilRect()
    D.drawHint(layer, win, win._equipDollHintCand, "_equipDollHint", win._equipDollClip)
end

-- An icon-only box names its item after the pause: the library's hint, asked of
-- the window's overlay (one delay, placed by the pointer, over everything).
-- c = { key, text, ... }; st and clip are no longer needed (kept for callers).
function D.drawHint(layer, win, c, st, clip)
    if not c then return end
    ZeD.Atoms.requestHint(win, c.key, c.text, layer)
end

-- ----------------------------------------------------------------------------
-- The List | Doll toggle in the Equipped heading, and the card's layer strip
-- ----------------------------------------------------------------------------

-- List | Doll: two separate icon buttons 4u apart at the heading's right edge,
-- the active one solid accent; each names itself in the library's hint after the
-- pause. Stamps win._equipViewZones.
local _toggleOpts = {}
function D.drawToggle(panel, win, x, y, w, headerH, mx, my)
    local T = ZeD.T
    local bw = math.min(T.buttonH, headerH - T.px(6))
    local sep = T.px(4)
    local by = y + math.floor((headerH - bw) / 2)
    local bx = x + w - T.px(10) - bw * 2 - sep
    local cur = D.view()
    local zones = {}
    for i, v in ipairs({ "list", "doll" }) do
        local zx = bx + (i - 1) * (bw + sep)
        local key = "__view_" .. v
        local text = (v == "list") and ZeD.tr("UI_ZeD_Doll_ViewList") or ZeD.tr("UI_ZeD_Doll_ViewDoll")
        local o = _toggleOpts
        o.active = (v == cur)
        o.hover = (not cuesOn()) and mx >= zx and mx < zx + bw and my >= by and my < by + bw
        o.focus, o.hint, o.id, o.win = gpFocused(win, key) or nil, text, key, win
        o.help = ZeD.tr(v == "list" and "UI_ZeD_Doll_ListHelp" or "UI_ZeD_Doll_DollHelp")
        o.iconSize = math.min(T.px(16), bw - T.px(6))
        ZeD.Molecules.drawIconButton(panel, zx, by, bw, v == "list" and "view_list" or "stand", o)   -- (ZeD pixel icons)
        zones[#zones + 1] = { x = zx, y = by, w = bw, h = bw, view = v, key = key, hint = text }
    end
    win._equipViewZones = zones
end

-- The card's layer strip: "LAYER 1 OF 2 | OUTERMOST" with Outer / Inner.
-- Stamps win._equipLayerZones. Returns its height.
function D.layerStripH() return ZeD.T.px(34) end

-- A band of the card's (the library's band: surface 2, its structure line on
-- top): the layer's words on the left in sentence case, Inner / Outer as push
-- buttons on the right.
local _layerBtn = {}
function D.drawLayerStrip(panel, win, x, y, w, idx, n, mx, my)
    local T, tm = ZeD.T, ZeD.TM
    local M = ZeD.Molecules
    local h = D.layerStripH()
    ZeD.Atoms.surfaceFill(panel, x, y, w, h, "surf2")
    ZeD.Atoms.drawDividerH(panel, x, y, w, true)
    local f1 = T.fontF1
    local where = (idx == 1) and ZeD.tr("UI_ZeD_Doll_Outermost") or ((idx == n) and ZeD.tr("UI_ZeD_Doll_Innermost") or ZeD.tr("UI_ZeD_Doll_UnderN", idx - 1))
    local lbl = ZeD.textCase(ZeD.tr("UI_ZeD_Doll_LayerStrip", idx, n, where))
    local lc = T.toneLo or T.textDim
    panel:drawText(lbl, x + T.px(10), y + math.floor((h - (T.fontF1H or tm:getFontHeight(f1))) / 2), lc.r, lc.g, lc.b, lc.a or 1, f1)
    local zones = {}
    local bh = math.min(T.buttonH, h - T.px(6))
    local by = y + math.floor((h - bh) / 2)
    local rx = x + w - T.px(8)
    for _, b in ipairs({ { dir = 1, label = ZeD.tr("UI_ZeD_Doll_StepInner") }, { dir = -1, label = ZeD.tr("UI_ZeD_Doll_StepOuter") } }) do
        local bw = M.buttonW(b.label)
        rx = rx - bw
        local enabled = (b.dir > 0 and idx < n) or (b.dir < 0 and idx > 1)
        local key = "__layer_" .. b.dir
        local o = _layerBtn
        o.disabled, o.win = not enabled, win
        o.focus = gpFocused(win, key) or nil
        o.hover = enabled and (not cuesOn()) and mx >= rx and mx < rx + bw and my >= by and my < by + bh
        M.drawButton(panel, rx, by, bw, bh, b.label, "default", false, nil, o)
        zones[#zones + 1] = { x = rx, y = by, w = bw, h = bh, dir = b.dir, enabled = enabled, key = key }
        rx = rx - T.px(8)
    end
    win._equipLayerZones = zones
    return h
end

function D.stepLayer(win, dir)
    local _, i, n = D.selection(win)
    if not (i and n and n > 1) then return end
    win._equipLayer = math.max(1, math.min(n, i + dir))
end

-- ----------------------------------------------------------------------------
-- Clicks (drawer-local x, y): the toggle and the layer strip. Slots go through
-- the Equip tab's own routes (_equipSlotZones selects, _equipBeltZones attach).
-- ----------------------------------------------------------------------------
local function inZ(z, x, y) return x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end

function D.onClick(win, x, y)
    if win._equipSelected then
        for _, z in ipairs(win._equipLayerZones or {}) do
            if inZ(z, x, y) then
                if z.enabled then D.stepLayer(win, z.dir) end
                return true
            end
        end
        return false
    end
    for _, z in ipairs(win._equipViewZones or {}) do
        if inZ(z, x, y) then
            if D.view() ~= z.view then
                D.setView(z.view)
                win._equipListExpanded = true
                win._gpFocusedEquipSlot = z.key
            end
            return true
        end
    end
    return false
end
