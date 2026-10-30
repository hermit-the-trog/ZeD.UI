-- ZeD-UI/42/media/lua/client/ZeD/EquipDoll.lua
-- ============================================================================
-- THE EQUIP TAB'S DOLL VIEW (Oct 19 2026, mockup zed_equip_doll_v3.html)
-- Director, Oct 17 2026: "avatar view with lines drawn at right angle to reach
-- the target not as the crow flies and list view are the two we want" ...
-- "yup, make head straight line and I think we have our equipped".
--
-- The character's own 3D model (the Identity tab's ISUI3DModel, full body)
-- standing on the panel (no frame), the worn slots in a column either side, the
-- hands and the belt's slots in a row below. Beyond the columns a band of small
-- slots each side (Oct 29 2026, mockup zed_equip_doll_v4_loadouts): 38 of them for
-- the rings, the necklaces, the pads and the rest; a drawer too narrow for the
-- bands folds every small slot's item back into its big slot as a layer. Each slot points at a stretch of the body
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
-- Every number below is a design unit in the mockup's doll (520 wide, 744 with
-- the bands); the doll scales to fit the drawer (never wider than it, at least
-- 0.7 of full size tall, then the tab scrolls).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.EquipDoll = ZeD.EquipDoll or {}
local D = ZeD.EquipDoll

-- Every x below is a design unit of the doll at scale 1. The Equip drawer is the full card (480 units, 466 beside
-- its scrollbar), so the doll with both bands of small slots is 466 wide (director, Oct 29 2026: "the updates
-- should fit in the full card, not the half card"); the figure's frame is 140 wide, the lanes 7 apart.
local BASE_W   = 324          -- the doll without its bands
local BAND_W   = 71           -- a band of small slots, each side (Oct 29 2026, mockup zed_equip_doll_v4_loadouts)
local WIDE_W   = BASE_W + 2 * BAND_W   -- 466: the doll with both bands
local BOX      = 52
local BOX_IN   = 0
local ROW0     = 16
local ROW_STEP = 82
local COL_L, COL_R = 5, 266
local PHOTO    = { x = 97, y = 6, w = 140, h = 528 }
local AV_DX    = -93          -- the body stretches below were drawn for a photo centred on x 260; it is now on x 167
local BELOW_Y  = 540
local BELOW_STEP = 62
local BELT_X0  = 133
local HANDS_X  = { 5, 65 }    -- the main and off hand
local LANES_L  = { 63, 70, 77, 84, 91 }
local LANES_R  = { 258, 251, 244, 237 }
local MIN_FIT  = 0.7
local BANDS_FIT = 0.9         -- the bands show while the wide doll fits this wide at this much of full size or more
-- the small slots: 20 units, a step of 23, three columns a band; a group's name sits at its row's y, its
-- slots 13 below (a row with no name continues the group above, its slots at the y given)
local SM_SIZE, SM_STEP, SM_NAME_DY = 20, 23, 13
local SM_XL, SM_XR = 2, 396   -- in the wide doll's units
local RULE_L, RULE_R = 70, 392   -- the faint rules between the bands and the doll

local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end

-- The worn slots: side, row, the stretch of the body each points at (x, from
-- y to y, in units drawn for a photo centred on x 260: AV_DX moves them) and the body
-- locations each one gathers. Vanilla's locations, lower case, no underscores.
-- (Ordered by row: the leader lines take their lanes in this order.) A location
-- that has a small slot is not listed here; with the bands folded away it comes
-- back to the big slot named in the small slot's row below.
D.SLOTS = {
    { id = "head",  key = "IGUI_health_Head",  side = "L", row = 0, av = { 262, 40, 92 },
      locs = set{ "hat", "fullhat", "fullsuithead", "fullsuitheadscba", "mask", "maskeyes", "maskfull" } },
    { id = "eyes",  key = "UI_ZeD_Doll_Eyes",  side = "L", row = 1, av = { 258, 80, 80 },
      locs = set{ "eyes", "lefteye", "righteye" } },
    { id = "neck",  key = "UI_ClothingType_Neck",  side = "L", row = 2, av = { 262, 116, 116 },
      locs = set{ "scarf", "necktexture", "neck" } },
    { id = "torso", key = "UI_ZeD_Doll_Torso", side = "L", row = 3, av = { 256, 186, 186 },
      locs = set{ "tshirt", "tanktop", "shirt", "shortsleeveshirt", "torso1", "torso1legs1", "torsoextra",
                  "underwear", "underweartop", "underwearextra1", "underwearextra2" } },
    { id = "outer", key = "UI_ZeD_Doll_Outer", side = "L", row = 4, av = { 212, 230, 230 },
      locs = set{ "jacket", "jacketdown", "jacketbulky", "jacketsuit", "boilersuit", "fullsuit", "fulltop", "bathrobe",
                  "fullrobe", "bodycostume", "sweater", "jersey", "torsoextravest", "torsoextravestbullet", "cuirass",
                  "sweaterhat", "jackethat", "jackethatbulky",   -- hooded tops: a jacket, with its hood
                  "vesttexture" } },
    { id = "hands", key = "UI_ZeD_Doll_Hands", side = "L", row = 5, av = { 200, 320, 320 },
      locs = set{ "hands", "handsleft", "handsright" } },
    { id = "back",  key = "UI_ClothingType_Back",  side = "R", row = 0, av = { 312, 150, 150 },
      locs = set{ "back" } },
    { id = "arms",  key = "UI_ZeD_Doll_Arms",  side = "R", row = 2, av = { 316, 200, 230 },   -- (the handoff says 322; in game the dot sat on the sleeve's edge, so 6 units in)
      locs = set{ "leftarm", "rightarm" } },
    { id = "belt",  key = "UI_ClothingType_Belt",  side = "R", row = 3, av = { 292, 236, 236 },
      locs = set{ "belt" } },
    { id = "legs",  key = "UI_ClothingType_Legs1",  side = "R", row = 4, av = { 300, 260, 460 },
      locs = set{ "pants", "pantsskinny", "pantsextra", "shortpants", "shortsshort", "legs1", "skirt", "longskirt",
                  "dress", "longdress", "underwearbottom", "codpiece" } },
    { id = "feet",  key = "UI_ZeD_Doll_Feet",  side = "R", row = 5, av = { 300, 492, 492 },
      locs = set{ "socks", "shoes" } },
}

-- The small slots, band by band: each row is a group's name (the keys of its words, joined with " | ") at y,
-- and its slots left to right: { id, the big slot it folds into, the key of its place's name (the hint
-- and the empty help), its locations, the letter of a pair }. The names are the game's own words for a
-- body location (UI_ClothingType_*) where it has one. 38 slots.
local SMALL_ROWS = {
    { side = "L", y = 16,  name = { "UI_ClothingType_Ears", "UI_ClothingType_Nose" }, slots = {
        { "ears",   "head", "UI_ClothingType_Ears",   { "ears" } },
        { "eartop", "head", "UI_ClothingType_EarTop", { "eartop" } },
        { "nose",   "head", "UI_ClothingType_Nose",   { "nose" } } } },
    { side = "L", y = 180, name = { "UI_ClothingType_Neck" }, slots = {
        { "necklace",     "neck", "UI_ClothingType_Necklace",      { "necklace" } },
        { "necklacelong", "neck", "UI_ClothingType_Necklace_Long", { "necklacelong" } },
        { "gorget",       "neck", "UI_ClothingType_Gorget",        { "gorget" } } } },
    { side = "L", y = 262, name = { "UI_ClothingType_BellyButton" }, slots = {
        { "belly", "torso", "UI_ClothingType_BellyButton", { "bellybutton" } } } },
    { side = "L", y = 344, name = { "UI_ZeD_Doll_Holster" }, slots = {
        { "holster", "outer", "UI_ClothingType_ShoulderHolster", { "shoulderholster" } } } },
    { side = "L", y = 426, name = { "UI_ZeD_Doll_RingsLeft" }, slots = {
        { "lmiddle", "hands", "UI_ClothingType_Left_MiddleFinger", { "leftmiddlefinger" } },
        { "lring",   "hands", "UI_ClothingType_Left_RingFinger",   { "leftringfinger" } } } },
    { side = "L", y = 467, name = { "UI_ZeD_Doll_RingsRight" }, slots = {
        { "rmiddle", "hands", "UI_ClothingType_Right_MiddleFinger", { "rightmiddlefinger" } },
        { "rring",   "hands", "UI_ClothingType_Right_RingFinger",   { "rightringfinger" } } } },
    { side = "R", y = 16,  name = { "UI_ClothingType_Satchel" }, slots = {
        { "satchel", "back", "UI_ClothingType_Satchel", { "satchel" } } } },
    { side = "R", y = 57,  name = { "UI_ZeD_Doll_AirTank", "UI_ClothingType_Tail" }, slots = {
        { "airtank", "back", "UI_ZeD_Doll_AirTank",  { "scba", "scbanotank" } },
        { "tail",    "back", "UI_ClothingType_Tail", { "tail" } } } },
    { side = "R", y = 98,  name = { "UI_ZeD_Doll_Shoulders" }, slots = {
        { "padl",   "arms", "UI_ClothingType_ShoulderpadLeft",  { "shoulderpadleft" },  "L" },
        { "padr",   "arms", "UI_ClothingType_ShoulderpadRight", { "shoulderpadright" }, "R" },
        { "padsport", "arms", "UI_ClothingType_SportShoulderpad", { "sportshoulderpad", "sportshoulderpadontop" } } } },
    { side = "R", y = 139, name = { "UI_ZeD_Doll_Elbows" }, slots = {
        { "elbowl", "arms", "UI_ClothingType_Elbow_Left",  { "elbowleft" },  "L" },
        { "elbowr", "arms", "UI_ClothingType_Elbow_Right", { "elbowright" }, "R" } } },
    { side = "R", y = 180, name = { "UI_ZeD_Doll_Wrists" }, slots = {
        { "wristl", "arms", "UI_ClothingType_LeftWrist",  { "leftwrist" },  "L" },
        { "wristr", "arms", "UI_ClothingType_RightWrist", { "rightwrist" }, "R" } } },
    { side = "R", y = 221, name = { "UI_ZeD_Doll_Forearms" }, slots = {
        { "forearml", "arms", "UI_ClothingType_ForeArm_Left",  { "forearmleft" },  "L" },
        { "forearmr", "arms", "UI_ClothingType_ForeArm_Right", { "forearmright" }, "R" } } },
    { side = "R", y = 262, name = { "UI_ClothingType_Belt" }, slots = {
        { "fpfront", "belt", "UI_ClothingType_FannyPackFront", { "fannypackfront" } },
        { "fpback",  "belt", "UI_ClothingType_FannyPackBack",  { "fannypackback" } },
        { "webbing", "belt", "UI_ClothingType_Webbing",        { "webbing" } } } },
    { side = "R", y = 299, slots = {
        { "ammo",       "belt", "UI_ClothingType_AmmoStrap", { "ammostrap" } },
        { "beltholster", "belt", "UI_ZeD_Doll_BeltHolster",  { "beltextra" } } } },
    { side = "R", y = 344, name = { "UI_ZeD_Doll_Knees" }, slots = {
        { "kneel", "legs", "UI_ClothingType_Knee_Left",  { "kneeleft" },  "L" },
        { "kneer", "legs", "UI_ClothingType_Knee_Right", { "kneeright" }, "R" } } },
    { side = "R", y = 385, name = { "UI_ZeD_Doll_Thighs" }, slots = {
        { "thighl", "legs", "UI_ClothingType_Thigh_Left",  { "thighleft" },  "L" },
        { "thighr", "legs", "UI_ClothingType_Thigh_Right", { "thighright" }, "R" } } },
    { side = "R", y = 426, name = { "UI_ZeD_Doll_Shins" }, slots = {
        { "shinl", "legs", "IGUI_health_Left_Shin",  { "calfleft", "calflefttexture" },   "L" },
        { "shinr", "legs", "IGUI_health_Right_Shin", { "calfright", "calfrighttexture" }, "R" } } },
    { side = "R", y = 467, name = { "UI_ZeD_Doll_Ankles" }, slots = {
        { "gaiterl", "legs", "UI_ClothingType_Gaiter_Left",  { "gaiterleft" },  "L" },
        { "gaiterr", "legs", "UI_ClothingType_Gaiter_Right", { "gaiterright" }, "R" },
        { "ankleholster", "belt", "UI_ClothingType_AnkleHolster", { "ankleholster" } } } },
}

-- the flat list of small slots (x, y in the wide doll's units), the group names to draw, and the maps
-- from a location to its small slot (the bands showing) or to its big slot (everything folded)
D.SMALL = {}
D.GROUPS = {}
local LOC_TO_SMALL, LOC_TO_BIG, LOC_FOLD = {}, {}, {}
for _, s in ipairs(D.SLOTS) do for loc in pairs(s.locs) do LOC_TO_BIG[loc] = s.id; LOC_FOLD[loc] = s.id end end
for _, row in ipairs(SMALL_ROWS) do
    local x0 = (row.side == "L") and SM_XL or SM_XR
    local y0 = row.y + (row.name and SM_NAME_DY or 0)
    if row.name then D.GROUPS[#D.GROUPS + 1] = { side = row.side, x = x0, y = row.y, name = row.name } end
    for c, t in ipairs(row.slots) do
        local sm = { id = t[1], big = t[2], place = t[3], locs = set(t[4]), letter = t[5], side = row.side,
                     x = x0 + (c - 1) * SM_STEP, y = y0 }
        D.SMALL[#D.SMALL + 1] = sm
        for loc in pairs(sm.locs) do LOC_TO_SMALL[loc] = sm.id; LOC_FOLD[loc] = sm.big end
    end
end

--- The doll slot a worn location shows in: a small slot's id while the bands show, else its big slot's
-- (the loadouts' missing things are drawn there: ZeD_EquipLoadout.ghosts).
function D.slotForLoc(loc, bands)
    if not loc then return nil end
    if bands then return LOC_TO_SMALL[loc] or LOC_TO_BIG[loc] end
    return LOC_FOLD[loc]
end

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
-- A worn location, the way the slots list it: lower case, no namespace, no underscores
local function normLoc(loc)
    local ls = string.lower(tostring(loc))
    local c = ls:find(":")
    if c then ls = ls:sub(c + 1) end
    return (ls:gsub("_", ""))
end

-- slots[id] = { def, items } (outermost first); small[id] likewise (the bands showing only);
-- main, off; belt = ZeD.Belt.slots. bands: the small slots show; without them every location folds
-- back into its big slot as a layer, so nothing is lost at any width.
function D.gather(p, pn, bands)
    bands = bands and true or false
    local out = { slots = {}, small = {}, bands = bands, main = nil, off = nil, belt = {} }
    for _, s in ipairs(D.SLOTS) do out.slots[s.id] = { def = s, items = {} } end
    if bands then for _, sm in ipairs(D.SMALL) do out.small[sm.id] = { def = sm, items = {} } end end
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
            local ls = normLoc(loc)
            local sid = bands and LOC_TO_SMALL[ls]
            if sid then
                table.insert(out.small[sid].items, item)
            else
                local id = bands and LOC_TO_BIG[ls] or LOC_FOLD[ls]
                if id then table.insert(out.slots[id].items, item) end
            end
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

-- The items behind a doll slot key ("doll:torso", "doll:ears", "doll:main", "doll:belt3")
local function itemsFor(data, key)
    local id = key and key:sub(6)
    if not (data and id) then return {} end
    if data.slots[id] then return data.slots[id].items end
    if data.small and data.small[id] then return data.small[id].items end
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
    win._equipDollData = D.gather(win._playerObj, win.playerNum or 0, win._equipDollBands)
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

-- The doll's scale for a drawer w wide with viewH to show it in (never wider than it, at least
-- MIN_FIT of full size tall, then the tab scrolls), and whether the bands show: they do while the
-- 466-unit doll fits across at BANDS_FIT or more (the full card does; the half card and narrower don't).
-- On a short screen the doll shrinks to the height, bands or not, down to MIN_FIT (a small slot of 14
-- units) before the tab scrolls (director, Oct 30 2026: shrink the slots rather than scroll).
local function fit(w, viewH, nBelt)
    local U = ZeD.T.px(1000) / 1000
    local bands = w >= WIDE_W * BANDS_FIT * U
    local byW = w / ((bands and WIDE_W or BASE_W) * U)
    local byH = viewH / (baseH(nBelt) * U)
    return math.min(1, byW, math.max(MIN_FIT, byH)), bands
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

-- the layer count in a slot box's top right corner: a small framed plate with the number
local function layerCount(panel, bx, by, b, n, font, fh, pad, line)
    local T, tm = ZeD.T, ZeD.TM
    local t = tostring(n)
    local tw = math.max(tm:MeasureStringX(font, t) + pad, fh)
    local s4, bs = T.surf4, T.borderS
    panel:drawRect(bx + b - tw, by, tw, fh, s4.a or 1, s4.r, s4.g, s4.b)
    panel:drawRect(bx + b - tw, by + fh, tw, line, bs.a or 1, bs.r, bs.g, bs.b)
    panel:drawRect(bx + b - tw - line, by, line, fh, bs.a or 1, bs.r, bs.g, bs.b)
    local tc = T.text
    panel:drawText(t, bx + b - tw + math.floor((tw - tm:MeasureStringX(font, t)) / 2), by, tc.r, tc.g, tc.b, tc.a or 1, font)
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
    if nLayers and nLayers > 1 then layerCount(panel, bx, by, b, nLayers, f1, f1h, T.px(6), T.px(1)) end
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

-- one small slot: a big slot's box at 24 units (the stripe fill and the strong frame; the item's
-- picture at 18 units, centred one unit high; a 2-unit condition strip inset 2 units at the bottom),
-- empty ones dashed, a pair's empty slot with its faint L or R, the layer count as a big slot shows
-- it; no label (the group's name stands above). u = screen px per doll unit. place = the place's
-- name, for the help line.
local function drawSmall(panel, win, bx, by, b, item, nLayers, key, letter, place, mx, my, u)
    local T, tm = ZeD.T, ZeD.TM
    local function pu(v) return math.max(1, math.floor(v * u + 0.5)) end
    local over = mx >= bx and mx < bx + b and my >= by and my < by + b
    local hover = over and not cuesOn()
    if item then
        local st = T.stripe
        panel:drawRect(bx, by, b, b, st.a, st.r, st.g, st.b)
        if ZeD.EquipmentTab and ZeD.EquipmentTab.draggedItem(win) == item then
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
    local f5 = T.fontF5
    local f5h = T.fontF5H or tm:getFontHeight(f5)
    if item then
        local bs = T.borderS
        panel:drawRectBorder(bx, by, b, b, bs.a or 1, bs.r, bs.g, bs.b)
        local tex = itemTex(item)
        local isz = pu(16)
        if tex then
            panel:drawTextureScaledAspect(tex, bx + math.floor((b - isz) / 2), by + math.floor((b - isz) / 2) - pu(1), isz, isz, 1, 1, 1, 1)
        end
        local f = condOf(item)
        if f then
            local ch, inset = pu(2), pu(2)
            local cx, cw = bx + inset, b - inset * 2
            local cy = by + b - inset - ch
            local bg, fc = T.base, condColor(T, f)
            panel:drawRect(cx, cy, cw, ch, 1, bg.r, bg.g, bg.b)
            panel:drawRect(cx, cy, math.max(1, math.floor(cw * f)), ch, 1, fc.r, fc.g, fc.b)
        end
    else
        local dc = T.textDim
        dashed(panel, bx, by, b, b, dc, 0.35)
        if letter then
            local lt = ZeD.tr(letter == "L" and "UI_ZeD_Doll_SideL" or "UI_ZeD_Doll_SideR")
            local lw = tm:MeasureStringX(f5, lt)
            panel:drawText(lt, bx + math.floor((b - lw) / 2), by + math.floor((b - f5h) / 2), dc.r, dc.g, dc.b, (dc.a or 1) * T.disabledAlpha, f5)
        end
    end
    if nLayers and nLayers > 1 then layerCount(panel, bx, by, b, nLayers, f5, f5h, pu(4), pu(1)) end
    if hover then
        ZeD.Help.set(panel, item and ZeD.tr("UI_ZeD_Doll_SlotHelp", call(item, "getDisplayName") or place)
            or ZeD.tr("UI_ZeD_Doll_EmptyHelp", place))
    end
    return over
end

-- A group's name: the game's words for its places, joined with " | "
local function groupName(g)
    local t = ""
    for i, k in ipairs(g.name) do t = t .. (i > 1 and " | " or "") .. ZeD.tr(k) end
    return ZeD.textCase(t)
end

-- Draws the doll at (x, y) in a drawer w wide with viewH of viewport. Stamps
-- win._equipSlotZones (filled slots: the card), win._equipBeltZones (empty
-- belt slots: the attach list), win._equipDollPhoto (the model's rectangle),
-- win._equipDollLines (for the line layer), win._equipDollHint,
-- win._equipDollAll (every slot's box, for a drop). Returns height.
function D.draw(panel, win, x, y, w, viewH, mx, my)
    local T, tm = ZeD.T, ZeD.TM
    win._equipDollTimer = (win._equipDollTimer or 0) + 1
    local data = win._equipDollData
    local _, bands = fit(w, viewH, data and #data.belt or 0)
    if win._equipDollTimer >= 15 or not data or data.bands ~= bands then
        win._equipDollTimer = 0
        data = D.gather(win._playerObj, win.playerNum or 0, bands)
        win._equipDollData = data
    end
    win._equipDollBands = bands
    local nBelt = #data.belt
    local s = fit(w, viewH, nBelt)
    local k = s * ZeD.T.px(1000) / 1000
    local off = bands and BAND_W or 0          -- every x of the 520-unit doll moves right by this
    local ox = x
    local function P(v) return math.floor(v * k + 0.5) end
    local b = P(BOX)
    -- The width the doll leaves spare (shrunk to a short window's height, it is narrower than the card)
    -- goes between its parts, each the size it is: the bands to the card's edges, the figure in the
    -- middle, the big slots' columns half way between (director, Oct 30 2026: "fill the width of the
    -- space for the equipment doll"). S(v): how far right a doll x (units) moves, its part's share.
    local spare = math.max(0, w - (bands and WIDE_W or BASE_W) * k)
    local function S(v)
        local q
        if bands then q = (v < 73 and 0) or (v < 131 and 0.25) or (v < 333 and 0.5) or (v < 394 and 0.75) or 1
        else q = (v < 60 and 0) or (v < 262 and 0.5) or 1 end
        return math.floor(spare * q + 0.5)
    end
    local belowS = bands and math.floor(spare * 0.25 + 0.5) or 0   -- the hands and the belt keep under the left column

    -- no frame behind the figure: the model stands on the panel (CharacterWindow draws it into this rectangle)
    local fx, fy, fw, fh = ox + P(PHOTO.x + off) + S(PHOTO.x + off), y + P(PHOTO.y), P(PHOTO.w), P(PHOTO.h)
    win._equipDollPhoto = { x = fx + T.px(1), y = fy + T.px(1), w = fw - T.px(2), h = fh - T.px(2) }
    if bands then
        -- faint rules between the bands and the doll (half way across the gap the spare width opens)
        local rw = T.px(1)
        panel:drawRect(ox + P(RULE_L) + math.floor(spare * 0.125 + 0.5), fy, rw, fh, 0.05, 1, 1, 1)
        panel:drawRect(ox + P(RULE_R) + math.floor(spare * 0.875 + 0.5), fy, rw, fh, 0.05, 1, 1, 1)
    end

    local zones, beltZones, lines, empties, rects = {}, {}, {}, {}, {}
    local hint = nil
    local li, ri = 0, 0
    -- what the loadout and outfit applied are missing, where it goes (ZeD_EquipLoadout)
    local EL = ZeD.EquipLoadout
    local ghosts = EL and EL.ghosts and EL.ghosts(win, bands) or nil
    win._equipDollGhosts = ghosts
    for _, def in ipairs(D.SLOTS) do
        local sx0 = ((def.side == "L") and COL_L or COL_R) + off
        local sy0 = ROW0 + def.row * ROW_STEP
        local bx, by = ox + P(sx0 + BOX_IN) + S(sx0 + BOX_IN), y + P(sy0)
        local items = data.slots[def.id].items
        local item = items[1]
        local key = "doll:" .. def.id
        local over = drawBox(panel, win, bx, by, b, item, #items, key, nil, ZeD.textCase(ZeD.tr(def.key)), mx, my)
        if not item and ghosts and ghosts[def.id] then EL.drawGhost(panel, bx, by, b, ghosts[def.id]) end
        rects[#rects + 1] = { x = bx, y = by, w = b, h = b, id = def.id }
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
        local ax = def.av[1] + AV_DX + off
        local ay = math.max(def.av[2], math.min(def.av[3], lsy))
        local pts
        if math.abs(ay - lsy) < 1 then
            pts = { lsx, lsy, ax, ay }
        else
            local lane
            if left then li = li + 1; lane = LANES_L[li] or LANES_L[#LANES_L]
            else ri = ri + 1; lane = LANES_R[ri] or LANES_R[#LANES_R] end
            lane = lane + off
            pts = { lsx, lsy, lane, lsy, lane, ay, ax, ay }
        end
        for i = 1, #pts, 2 do pts[i] = ox + P(pts[i]) + S(pts[i]); pts[i + 1] = y + P(pts[i + 1]) end
        lines[#lines + 1] = pts
    end

    -- the bands: the small slots, each group under its name
    if bands then
        local ss = P(SM_SIZE)
        local f5 = T.fontF5
        local dc = T.textDim
        local f5h = T.fontF5H or getTextManager():getFontHeight(f5)
        for _, g in ipairs(D.GROUPS) do
            -- the name sits on its row's y; on a shrunk doll it rises just enough to clear its slots
            local ny = math.min(y + P(g.y), y + P(g.y + SM_NAME_DY) - f5h - 1)
            panel:drawText(ZeD.Atoms.truncateText(groupName(g), f5, P(BAND_W - 4)), ox + P(g.x) + S(g.x), ny, dc.r, dc.g, dc.b, dc.a or 1, f5)
        end
        for _, sm in ipairs(D.SMALL) do
            local items = data.small[sm.id].items
            local item = items[1]
            local key = "doll:" .. sm.id
            local sbx, sby = ox + P(sm.x) + S(sm.x), y + P(sm.y)
            local place = ZeD.tr(sm.place)
            local over = drawSmall(panel, win, sbx, sby, ss, item, #items, key, sm.letter, place, mx, my, k)
            if not item and ghosts and ghosts[sm.id] then EL.drawGhost(panel, sbx, sby, ss, ghosts[sm.id]) end
            rects[#rects + 1] = { x = sbx, y = sby, w = ss, h = ss, id = sm.id }
            local ptext = ZeD.textCase(place)
            if item then
                zones[#zones + 1] = { x = sbx, y = sby, w = ss, h = ss, type = key, item = item }
                if over then
                    local t = call(item, "getDisplayName") or "?"
                    if #items > 1 then t = ZeD.tr("UI_ZeD_Doll_Under", t, #items - 1) end
                    hint = { key = key, text = t .. " | " .. ptext, x = sbx, y = sby, w = ss }
                end
            else
                empties[#empties + 1] = { x = sbx, y = sby, w = ss, h = ss, type = key }
                if over then hint = { key = key, text = ptext, x = sbx, y = sby, w = ss } end
            end
            win._equipSlotYMap[key] = sby
        end
    end

    -- the row below: the hands, then the belt's slots (three to a row)
    local function below(key, label, item, bx0, by0, beltKey, beltSlot)
        local bx, by = ox + P(bx0 + off + BOX_IN) + belowS, y + P(by0)
        local over = drawBox(panel, win, bx, by, b, item, 1, key, beltKey, label, mx, my)
        local gid = beltSlot and ("belt" .. tostring(beltSlot.i)) or (key and key:sub(6))
        if not item and ghosts and gid and ghosts[gid] then EL.drawGhost(panel, bx, by, b, ghosts[gid]) end
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
    below("doll:main", ZeD.tr("UI_ZeD_Doll_Main"), data.main, HANDS_X[1], BELOW_Y)
    below("doll:off", ZeD.tr("UI_ZeD_Doll_Off"), data.off, HANDS_X[2], BELOW_Y)
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
    win._equipDollAll = rects
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
-- The pad across the figure and into the bands. Left / Right between the two
-- columns go to the nearest row on the other side (the columns don't line up
-- row for row, and the photo between them would otherwise send the press out of
-- the doll). Toward its band a big slot steps into the nearest small slot there,
-- by height; inside a band the four directions move by position; the direction
-- back toward the figure returns to the nearest big slot. Right from the right
-- band / Left from the left band leave as usual.
-- ----------------------------------------------------------------------------
local SLOT_BY_ID, SMALL_BY_ID = {}, {}
for _, s in ipairs(D.SLOTS) do SLOT_BY_ID[s.id] = s end
for _, s in ipairs(D.SMALL) do SMALL_BY_ID[s.id] = s end

local function slotOf(key)
    if type(key) ~= "string" or key:sub(1, 5) ~= "doll:" then return nil end
    return SLOT_BY_ID[key:sub(6)]
end

local function smallOf(key)
    if type(key) ~= "string" or key:sub(1, 5) ~= "doll:" then return nil end
    return SMALL_BY_ID[key:sub(6)]
end

local function charZone(w)
    for i, z in ipairs(w._focusRing or {}) do if z.zone == "charTabContent" then return i, z end end
    return nil
end

local function focusAt(w, zi, zone, j)
    w._focusIdx = zi
    zone.focusedElementIdx = j
    local e = zone.elements[j]
    if e.onFocus then e.onFocus(w, e) end
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)
    return true
end

local function ctr(e) return (e.x or 0) + (e.w or 0) / 2, (e.y or 0) + (e.h or 0) / 2 end

-- the element nearest el by height (then by distance along the row) among those pick(e) accepts
local function nearestByHeight(zone, el, pick)
    local ex, ey = ctr(el)
    local best, bd, bdx
    for j, e in ipairs(zone.elements or {}) do
        if e ~= el and pick(e) then
            local cx, cy = ctr(e)
            local dy, dx = math.abs(cy - ey), math.abs(cx - ex)
            if not best or dy < bd - 1 or (math.abs(dy - bd) <= 1 and dx < bdx) then best, bd, bdx = j, dy, dx end
        end
    end
    return best
end

-- Up / Down / Left / Right from a small slot
local function dpadSmall(w, zi, zone, el, sm, dir)
    local ex, ey = ctr(el)
    local tol = (el.h or 1) * 0.5
    local best, bdy, bdx
    if dir == "up" or dir == "down" then
        for j, e in ipairs(zone.elements or {}) do
            local s2 = smallOf(e.slotType)
            if s2 and s2.side == sm.side then
                local cx, cy = ctr(e)
                local dy = (dir == "down") and (cy - ey) or (ey - cy)
                if dy > tol then
                    local dx = math.abs(cx - ex)
                    if not best or dy < bdy - tol or (math.abs(dy - bdy) <= tol and dx < bdx) then best, bdy, bdx = j, dy, dx end
                end
            end
        end
        if best then return focusAt(w, zi, zone, best) end
        return false
    end
    local sign = (dir == "right") and 1 or -1
    for j, e in ipairs(zone.elements or {}) do
        local s2 = smallOf(e.slotType)
        if s2 and s2.side == sm.side then
            local cx, cy = ctr(e)
            local dx = (cx - ex) * sign
            if dx > tol and math.abs(cy - ey) <= tol and (not best or dx < bdx) then best, bdx = j, dx end
        end
    end
    if best then return focusAt(w, zi, zone, best) end
    if dir == ((sm.side == "L") and "right" or "left") then
        -- toward the figure from the band's edge: the nearest big slot beside it
        local j = nearestByHeight(zone, el, function(e) local d = slotOf(e.slotType); return d and d.side == sm.side end)
        if j then return focusAt(w, zi, zone, j) end
    end
    return false    -- the outer edge: leaves the doll
end

function D.dpad(w, el, dir)
    local key = el and el.slotType
    local zi, zone = charZone(w)
    if not zone then return false end
    local sm = smallOf(key)
    if sm then return dpadSmall(w, zi, zone, el, sm, dir) end
    local def = slotOf(key)
    if not def then return false end
    if (def.side == "L" and dir == "left") or (def.side == "R" and dir == "right") then
        -- toward its band (when it shows): the nearest small slot there, by height
        local j = nearestByHeight(zone, el, function(e) local s2 = smallOf(e.slotType); return s2 and s2.side == def.side end)
        if j then return focusAt(w, zi, zone, j) end
        return false
    end
    if dir ~= "left" and dir ~= "right" then return false end
    -- across the figure to the nearest row on the other side
    local best, bestD, bestRow
    for j, e in ipairs(zone.elements or {}) do
        local d2 = slotOf(e.slotType)
        if d2 and d2.side ~= def.side then
            local dd = math.abs(d2.row - def.row)
            if not best or dd < bestD or (dd == bestD and d2.row < bestRow) then best, bestD, bestRow = j, dd, d2.row end
        end
    end
    if not best then return false end
    return focusAt(w, zi, zone, best)
end

-- ----------------------------------------------------------------------------
-- A drop on the doll: an item released over a slot it fits is worn there, by
-- vanilla's own wear action (which takes it out of a bag first). Asked by the
-- inventory's drop handler before it looks for a container. True when it took
-- the drop.
-- ----------------------------------------------------------------------------
local function wearLoc(item)
    local l = nil
    if call(item, "IsClothing") or call(item, "IsInventoryContainer") then l = call(item, "getBodyLocation") end
    if l == nil or tostring(l) == "" then l = call(item, "canBeEquipped") end
    if l == nil or tostring(l) == "" then return nil end
    return normLoc(l)
end

function D.takeDrop(pn, items)
    local win = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    if not (win and win._equipDollShown and win._equipDollAll and win._equipDollPanel) then return false end
    if win._drawerMode ~= "tab" or win._activeTab ~= "equip" or win._equipSelected or (win._drawerEffW or 0) <= 0 then return false end
    if not (items and items[1]) then return false end
    local panel, clip = win._equipDollPanel, win._equipDollClip
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if clip and not (mx >= clip.x and mx < clip.x + clip.w and my >= clip.y and my < clip.y + clip.h) then return false end
    local hit
    for _, r in ipairs(win._equipDollAll) do
        if mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h then hit = r; break end
    end
    if not hit then return false end
    local p = getSpecificPlayer(pn)
    local bands = win._equipDollBands
    for _, item in ipairs(items) do
        local loc = wearLoc(item)
        local id = loc and (bands and (LOC_TO_SMALL[loc] or LOC_TO_BIG[loc]) or LOC_FOLD[loc])
        if id == hit.id and not call(p, "isEquippedClothing", item) then
            ISInventoryPaneContextMenu.wearItem(item, pn)
            win._equipDollTimer = 99    -- the slots read the new clothes at once
            return true
        end
    end
    return false
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
    layer.onRightMouseDown = function() return false end   -- (42.22: a handler that returns nothing takes the click)
    layer.onRightMouseUp = function() return false end
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
