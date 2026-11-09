-- ZeD-UI/42/media/lua/client/ZeD/EquipDoll.lua
-- ============================================================================
-- THE EQUIP TAB'S DOLL VIEW - client; data and draw helpers for the Equip
-- drawer, no class of its own (ZeD_CharacterWindow and EquipmentTab call in;
-- InventoryRenderer asks takeDrop about drops; ZeD_EquipLoadout, slotForLoc).
--
-- The character's own 3D model (the Identity tab's ISUI3DModel, full body)
-- standing on the panel (no frame), the worn slots in a column either side,
-- the hands and the belt's slots in a row below. Beyond the columns a band of
-- small slots each side: 38 of them for the rings, the necklaces, the pads
-- and the rest; a drawer too narrow for the bands folds every small slot's
-- item back into its big slot as a layer. With the bands showing the big
-- slots split instead: the upper body's on the left, the back's and the belt
-- and below on the right (SPLIT_BIG and SMALL_ROWS); the spare width of a
-- shrunk doll goes between its parts. No leader lines point at the body; each
-- slot is named under its box.
--
-- Selecting a slot opens the same item card a list row opens (the outermost
-- layer; the card's layer strip steps inward). The list stays the other view;
-- the choice is a ZeD option (Settings.lua equipView), set by the toggle in the
-- Equipped heading too.
--
-- The 3D model and the line layer are window children (CharacterWindow): a
-- model can't live in a stencilled panel, and the layer must sit ABOVE the
-- model. The layer once drew leader lines to the body; now it only asks the
-- window's overlay for the hover hint. Everything else draws here, in the
-- drawer.
--
-- Every number below is a design unit of the doll (324 wide, 466 with the
-- bands); the doll scales to fit the drawer (never wider than it, at least
-- 0.7 of full size tall, then the tab scrolls).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.EquipDoll = ZeD.EquipDoll or {}
local D = ZeD.EquipDoll

-- Every x below is a design unit of the doll at scale 1. The Equip drawer is the full card (480 units, 466 beside
-- its scrollbar), so the doll with both bands of small slots is 466 wide - sized for the full card, not the half
-- card; the figure's frame is 140 wide.
local BASE_W   = 324          -- the doll without its bands
local BAND_W   = 71           -- a band of small slots, each side
local WIDE_W   = BASE_W + 2 * BAND_W   -- 466: the doll with both bands
local BOX      = 52
local BOX_IN   = 0
local ROW0     = 16
local ROW_STEP = 82
local COL_L, COL_R = 5, 266
local PHOTO    = { x = 97, y = 6, w = 140, h = 528 }
local BELOW_Y  = 540
local BELOW_STEP = 62
local BELT_X0  = 133
local HANDS_X  = { 5, 65 }    -- the main and off hand
local MIN_FIT  = 0.7
local BANDS_FIT = 0.9         -- the bands show while the wide doll fits this wide at this much of full size or more
-- the small slots: 20 units, a step of 23, three columns a band; a group's name sits at its row's y, its
-- slots 13 below (a row with no name continues the group above, its slots at the y given)
local SM_SIZE, SM_STEP, SM_NAME_DY = 20, 23, 13
local SM_XL, SM_XR = 2, 396   -- in the wide doll's units
local RULE_L, RULE_R = 70, 392   -- the faint rules between the bands and the doll

local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end

-- The worn slots: side, row, av = the stretch of the body each slot pointed at
-- (x, from y to y, in units for a photo centred on x 260; the leader lines read
-- these, and nothing does now the lines are gone) and the body locations each
-- one gathers. Vanilla's locations, lower case, no underscores. A location
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
    { id = "arms",  key = "UI_ZeD_Doll_Arms",  side = "R", row = 2, av = { 316, 200, 230 },   -- (322 put the line's dot on the sleeve's edge in game, so 6 units in)
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
    -- the left band: the upper body, top to bottom; the lower body (belt and below) and the back's
    -- bags go in the right band
    { side = "L", y = 16,  name = { "UI_ClothingType_Ears", "UI_ClothingType_Nose" }, slots = {
        { "ears",   "head", "UI_ClothingType_Ears",   { "ears" } },
        { "eartop", "head", "UI_ClothingType_EarTop", { "eartop" } },
        { "nose",   "head", "UI_ClothingType_Nose",   { "nose" } } } },
    { side = "L", y = 66,  name = { "UI_ClothingType_Neck" }, slots = {
        { "necklace",     "neck", "UI_ClothingType_Necklace",      { "necklace" } },
        { "necklacelong", "neck", "UI_ClothingType_Necklace_Long", { "necklacelong" } },
        { "gorget",       "neck", "UI_ClothingType_Gorget",        { "gorget" } } } },
    { side = "L", y = 116, name = { "UI_ZeD_Doll_Shoulders" }, slots = {
        { "padl",   "arms", "UI_ClothingType_ShoulderpadLeft",  { "shoulderpadleft" },  "L" },
        { "padr",   "arms", "UI_ClothingType_ShoulderpadRight", { "shoulderpadright" }, "R" },
        { "padsport", "arms", "UI_ClothingType_SportShoulderpad", { "sportshoulderpad", "sportshoulderpadontop" } } } },
    { side = "L", y = 166, name = { "UI_ZeD_Doll_Elbows" }, slots = {
        { "elbowl", "arms", "UI_ClothingType_Elbow_Left",  { "elbowleft" },  "L" },
        { "elbowr", "arms", "UI_ClothingType_Elbow_Right", { "elbowright" }, "R" } } },
    { side = "L", y = 216, name = { "UI_ZeD_Doll_Wrists" }, slots = {
        { "wristl", "arms", "UI_ClothingType_LeftWrist",  { "leftwrist" },  "L" },
        { "wristr", "arms", "UI_ClothingType_RightWrist", { "rightwrist" }, "R" } } },
    { side = "L", y = 266, name = { "UI_ZeD_Doll_Forearms" }, slots = {
        { "forearml", "arms", "UI_ClothingType_ForeArm_Left",  { "forearmleft" },  "L" },
        { "forearmr", "arms", "UI_ClothingType_ForeArm_Right", { "forearmright" }, "R" } } },
    { side = "L", y = 316, name = { "UI_ClothingType_BellyButton" }, slots = {
        { "belly", "torso", "UI_ClothingType_BellyButton", { "bellybutton" } } } },
    { side = "L", y = 366, name = { "UI_ZeD_Doll_Holster" }, slots = {
        { "holster", "outer", "UI_ClothingType_ShoulderHolster", { "shoulderholster" } } } },
    { side = "L", y = 416, name = { "UI_ZeD_Doll_RingsLeft" }, slots = {
        { "lmiddle", "hands", "UI_ClothingType_Left_MiddleFinger", { "leftmiddlefinger" } },
        { "lring",   "hands", "UI_ClothingType_Left_RingFinger",   { "leftringfinger" } } } },
    { side = "L", y = 466, name = { "UI_ZeD_Doll_RingsRight" }, slots = {
        { "rmiddle", "hands", "UI_ClothingType_Right_MiddleFinger", { "rightmiddlefinger" } },
        { "rring",   "hands", "UI_ClothingType_Right_RingFinger",   { "rightringfinger" } } } },
    -- the right band: the back's bags at the top, by Back; the belt and below by Belt, Legs and Feet
    { side = "R", y = 16,  name = { "UI_ClothingType_Satchel" }, slots = {
        { "satchel", "back", "UI_ClothingType_Satchel", { "satchel" } } } },
    { side = "R", y = 57,  name = { "UI_ZeD_Doll_AirTank", "UI_ClothingType_Tail" }, slots = {
        { "airtank", "back", "UI_ZeD_Doll_AirTank",  { "scba", "scbanotank" } },
        { "tail",    "back", "UI_ClothingType_Tail", { "tail" } } } },
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
                     x = x0 + (c - 1) * SM_STEP, y = y0, col = c }
        D.SMALL[#D.SMALL + 1] = sm
        for loc in pairs(sm.locs) do LOC_TO_SMALL[loc] = sm.id; LOC_FOLD[loc] = sm.big end
    end
end

-- THE SPLIT (the bands showing, the full card): the upper body's big slots in two columns on the left,
-- Back at the top on the right with its bags, then Belt, Legs and Feet; no leader lines. The narrow
-- doll (the bands folded) keeps a column each side (COL_L / COL_R, D.SLOTS' rows).
-- Units are the wide doll's.
local SPLIT_BIG = { head = { 75, 16 }, eyes = { 133, 16 }, neck = { 75, 136 }, arms = { 133, 136 },
                    torso = { 75, 256 }, outer = { 133, 256 }, hands = { 75, 376 },
                    back = { 337, 16 }, belt = { 337, 262 }, legs = { 337, 344 }, feet = { 337, 426 } }
local SPLIT_PHOTO_X = 191
-- a big slot's side and column in the split: "L" 1 (by the band), "L" 2 (by the figure), "R" 1
local function splitCol(id)
    local q = SPLIT_BIG[id]
    if not q then return nil end
    if q[1] < 100 then return "L", 1 elseif q[1] < 200 then return "L", 2 end
    return "R", 1
end

--- The doll slot a worn location shows in: a small slot's id while the bands show, else its big slot's
--- (the loadouts' missing things are drawn there: ZeD_EquipLoadout.ghosts).
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
--- The Equip tab's view, "list" or "doll" (the equipView option's value).
function D.view()
    local o = ZeD.Settings and ZeD.Settings.equipViewOption
    local v = o and call(o, "getValue")
    return (v == 2) and "doll" or "list"
end

--- Sets the view ("list" or "doll") and saves the option.
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

--- slots[id] = { def, items } (outermost first); small[id] likewise (the bands showing only);
--- main, off; belt = ZeD.Belt.slots. bands: the small slots show; without them every location folds
--- back into its big slot as a layer, so nothing is lost at any width.
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

--- The card's item for the selection: item, layer index, layer count.
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

--- True for a doll selection key ("doll:torso", "doll:main", "doll:belt3").
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
-- units) before the tab scrolls: the slots shrink rather than scroll.
local function fit(w, viewH, nBelt)
    local U = ZeD.T.px(1000) / 1000
    local bands = w >= WIDE_W * BANDS_FIT * U
    local byW = w / ((bands and WIDE_W or BASE_W) * U)
    local byH = viewH / (baseH(nBelt) * U)
    return math.min(1, byW, math.max(MIN_FIT, byH)), bands
end

--- The doll's height in screen px for a drawer w wide with viewH to show it in.
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
    local T = ZeD.T
    local d, one = T.px(3), T.px(1)
    local r, g, b = c.r, c.g, c.b
    local yb, xr = y + h - one, x + w - one
    -- each edge as one draw from the dash textures (ZeD.Atoms.lineTex: d lit, d clear, from the
    -- edge's start), where the panel's rects are the plain ones: four draws, not one a dash
    local A = ZeD.Atoms
    local jo = A.lineJo and d >= 1 and d <= 32 and w <= 1024 and h <= 1024 and A.lineJo(p)
    local th, tv = jo and A.lineTex("dash_h"), jo and A.lineTex("dash_v")
    if th and tv then
        jo:DrawSubTextureRGBA(th, 0, d - 1, w, 1, x, y, w, one, r, g, b, a)
        jo:DrawSubTextureRGBA(th, 0, d - 1, w, 1, x, yb, w, one, r, g, b, a)
        jo:DrawSubTextureRGBA(tv, d - 1, 0, 1, h, x, y, one, h, r, g, b, a)
        jo:DrawSubTextureRGBA(tv, d - 1, 0, 1, h, xr, y, one, h, r, g, b, a)
        return
    end
    for i = 0, w - 1, d * 2 do
        local l = w - i
        if d < l then l = d end
        p:drawRect(x + i, y, l, one, a, r, g, b)
        p:drawRect(x + i, yb, l, one, a, r, g, b)
    end
    for i = 0, h - 1, d * 2 do
        local l = h - i
        if d < l then l = d end
        p:drawRect(x, y + i, one, l, a, r, g, b)
        p:drawRect(xr, y + i, one, l, a, r, g, b)
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
    local condHov = nil   -- (the condition while the pointer is on its strip)
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
            -- (ten segments even at the floor: the smallest doll on a 0.75 UI scale leaves ~21 px, a pixel a segment)
            local ch = T.px(5)
            condHov = ZeD.Atoms.drawFillBar(panel, bx + T.px(4), by + b - T.px(3) - ch, b - T.px(8), f, false, condColor(T, f), ch)
                and f or nil
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
    if condHov then
        -- on the condition strip: its reading ("Condition 64%")
        ZeD.Help.set(panel, ZeD.Atoms.fillBarHelp(condHov, ZeD.tr("IGUI_invpanel_Condition")))
    elseif hover then
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

-- one small slot: a big slot's box at 20 units (the stripe fill and the strong frame; the item's
-- picture at 16 units, centred one unit high; a 2-unit condition strip inset 2 units at the bottom),
-- empty ones dashed, a pair's empty slot with its faint L or R, the layer count as a big slot shows
-- it; no label (the group's name stands above). u = screen px per doll unit. place = the place's
-- name, for the help line.
-- a small slot's units in screen px, at u px a unit (at least 1)
local function pu(v, u) return math.max(1, math.floor(v * u + 0.5)) end

local function drawSmall(panel, win, bx, by, b, item, nLayers, key, letter, place, mx, my, u)
    local T, tm = ZeD.T, ZeD.TM
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
        local isz = pu(16, u)
        if tex then
            panel:drawTextureScaledAspect(tex, bx + math.floor((b - isz) / 2), by + math.floor((b - isz) / 2) - pu(1, u), isz, isz, 1, 1, 1, 1)
        end
        local f = condOf(item)
        if f then
            local ch, inset = pu(2, u), pu(2, u)
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
    if nLayers and nLayers > 1 then layerCount(panel, bx, by, b, nLayers, f5, f5h, pu(4, u), pu(1, u)) end
    if hover then
        ZeD.Help.set(panel, item and ZeD.tr("UI_ZeD_Doll_SlotHelp", call(item, "getDisplayName") or place)
            or ZeD.tr("UI_ZeD_Doll_EmptyHelp", place))
    end
    return over
end

-- The doll's words (the slots' labels, the groups' names, the places), kept by what they are
-- made from while the language, the test language and the measures hold (ZeD.Text.wordsEpoch):
-- seventy phrases a frame otherwise
local _words = {}
local function dollWords(ep)
    if not ep or _words.ep ~= ep then _words = { ep = ep, label = {}, group = {}, place = {}, ptext = {} } end
    return _words
end

-- A group's name: the game's words for its places, joined with " | " (wd: dollWords)
local function groupName(g, wd)
    local s = wd.group[g]
    if s then return s end
    local t = ""
    for i, k in ipairs(g.name) do t = t .. (i > 1 and " | " or "") .. ZeD.tr(k) end
    s = ZeD.textCase(t)
    wd.group[g] = s
    return s
end

-- The doll's lists of boxes (filled slots, empty ones, every box) are kept on the window and filled
-- again each frame in the tables they had: forty-odd new tables a frame otherwise, all garbage.
local function boxList(win, field)
    local l = win[field]
    if not l then l = {}; win[field] = l end
    l.n = 0
    return l
end
local function slotBox(list, x, y, w, h)
    local n = list.n + 1
    list.n = n
    local t = list[n]
    if not t then t = {}; list[n] = t end
    t.x, t.y, t.w, t.h = x, y, w, h
    return t
end
local function trimList(l) for i = l.n + 1, #l do l[i] = nil end end

--- Draws the doll at (x, y) in a drawer w wide with viewH of viewport. Stamps
--- win._equipSlotZones (filled slots: the card), win._equipBeltZones (empty
--- belt slots: the attach list), win._equipDollPhoto (the model's rectangle),
--- win._equipDollLines (for the line layer), win._equipDollHint,
--- win._equipDollAll (every slot's box, for a drop). Returns height.
function D.draw(panel, win, x, y, w, viewH, mx, my)
    local T, tm = ZeD.T, ZeD.TM
    local wd = dollWords(ZeD.Text.wordsEpoch())   -- (the slots' words, kept)
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
    local off = bands and BAND_W or 0          -- the row below keeps base-doll x values; they move right past the left band
    local ox = x
    local function P(v) return math.floor(v * k + 0.5) end
    local b = P(BOX)
    -- The width the doll leaves spare (shrunk to a short window's height, it is narrower than the card)
    -- goes between its parts, each the size it is: the bands to the card's edges, the figure in the
    -- middle, the big slots' columns half way between, so the doll fills the drawer's width. S(v):
    -- how far right a doll x (units) moves, its part's share. Each band takes a share first, so its
    -- boxes never sit crammed: bandX wider, its small slots half that further apart, its group
    -- names that much more room. The rest goes into the gaps: five in the split (two left columns),
    -- two in the narrow doll.
    local spare = math.max(0, w - (bands and WIDE_W or BASE_W) * k)
    local bandX = bands and math.min(math.floor(spare * 0.2), P(28)) or 0
    local rest = spare - 2 * bandX
    local stepX = math.floor(bandX / 2)          -- (three small slots to a row: two gaps)
    local function S(v)
        if not bands then return math.floor(spare * ((v < 60 and 0) or (v < 262 and 0.5) or 1) + 0.5) end
        if v < 73 then return 0 end
        if v >= 394 then return spare - bandX end   -- (the right band's left edge: it ends at the card's)
        return bandX + math.floor(rest * ((v < 131 and 0.2) or (v < 189 and 0.4) or (v < 335 and 0.6) or 0.8) + 0.5)
    end
    local belowS = bands and (bandX + math.floor(rest * 0.2 + 0.5)) or 0   -- the hands and the belt keep under the left column

    -- no frame behind the figure: the model stands on the panel (CharacterWindow draws it into this rectangle)
    local phx = bands and SPLIT_PHOTO_X or PHOTO.x
    local fx, fy, fw, fh = ox + P(phx) + S(phx), y + P(PHOTO.y), P(PHOTO.w), P(PHOTO.h)
    local photo = win._equipDollPhoto or {}   -- (one table, refilled)
    photo.x, photo.y, photo.w, photo.h = fx + T.px(1), fy + T.px(1), fw - T.px(2), fh - T.px(2)
    win._equipDollPhoto = photo
    if bands then
        -- faint rules between the bands and the doll (half way across the gap the spare width opens)
        local rw = T.px(1)
        panel:drawRect(ox + P(RULE_L) + bandX + math.floor(rest * 0.1 + 0.5), fy, rw, fh, 0.05, 1, 1, 1)
        panel:drawRect(ox + P(RULE_R) + bandX + math.floor(rest * 0.9 + 0.5), fy, rw, fh, 0.05, 1, 1, 1)
    end

    local zones, beltZones, empties, rects = boxList(win, "_dollZones"), {}, boxList(win, "_dollEmpty"), boxList(win, "_dollRects")
    local hint = nil
    -- what the loadout and outfit applied are missing, where it goes (ZeD_EquipLoadout)
    local EL = ZeD.EquipLoadout
    local ghosts = EL and EL.ghosts and EL.ghosts(win, bands) or nil
    win._equipDollGhosts = ghosts
    for _, def in ipairs(D.SLOTS) do
        local sx0, sy0
        if bands then sx0, sy0 = SPLIT_BIG[def.id][1], SPLIT_BIG[def.id][2]
        else sx0, sy0 = (def.side == "L") and COL_L or COL_R, ROW0 + def.row * ROW_STEP end
        local bx, by = ox + P(sx0 + BOX_IN) + S(sx0 + BOX_IN), y + P(sy0)
        local items = data.slots[def.id].items
        local item = items[1]
        local key = "doll:" .. def.id
        local label = wd.label[def]
        if not label then label = ZeD.textCase(ZeD.tr(def.key)); wd.label[def] = label end
        local over = drawBox(panel, win, bx, by, b, item, #items, key, nil, label, mx, my)
        if not item and ghosts and ghosts[def.id] then EL.drawGhost(panel, bx, by, b, ghosts[def.id]) end
        slotBox(rects, bx, by, b, b).id = def.id
        if item then
            local zb = slotBox(zones, bx, by, b, b); zb.type, zb.item = key, item
            if over then
                local t = call(item, "getDisplayName") or "?"
                if #items > 1 then t = ZeD.tr("UI_ZeD_Doll_Under", t, #items - 1) end
                hint = { key = key, text = t, x = bx, y = by, w = b }
            end
        else
            -- an empty slot is still a stop for the pad, so D-pad moves keep to
            -- the doll's columns and rows (nothing happens on A)
            slotBox(empties, bx, by, b, b).type = key
        end
        win._equipSlotYMap[key] = by
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
            panel:drawText(ZeD.Atoms.truncateText(groupName(g, wd), f5, P(BAND_W - 4) + bandX), ox + P(g.x) + S(g.x), ny, dc.r, dc.g, dc.b, dc.a or 1, f5)
        end
        for _, sm in ipairs(D.SMALL) do
            local items = data.small[sm.id].items
            local item = items[1]
            local key = "doll:" .. sm.id
            local sbx, sby = ox + P(sm.x) + S(sm.x) + (sm.col - 1) * stepX, y + P(sm.y)
            local place = wd.place[sm]
            if not place then place = ZeD.tr(sm.place); wd.place[sm] = place end
            local over = drawSmall(panel, win, sbx, sby, ss, item, #items, key, sm.letter, place, mx, my, k)
            if not item and ghosts and ghosts[sm.id] then EL.drawGhost(panel, sbx, sby, ss, ghosts[sm.id]) end
            slotBox(rects, sbx, sby, ss, ss).id = sm.id
            local ptext = wd.ptext[sm]
            if not ptext then ptext = ZeD.textCase(place); wd.ptext[sm] = ptext end
            if item then
                local zb = slotBox(zones, sbx, sby, ss, ss); zb.type, zb.item = key, item
                if over then
                    local t = call(item, "getDisplayName") or "?"
                    if #items > 1 then t = ZeD.tr("UI_ZeD_Doll_Under", t, #items - 1) end
                    hint = { key = key, text = t .. " | " .. ptext, x = sbx, y = sby, w = ss }
                end
            else
                slotBox(empties, sbx, sby, ss, ss).type = key
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
            local zb = slotBox(zones, bx, by, b, b); zb.type, zb.item = key, item
            if over then hint = { key = key, text = call(item, "getDisplayName") or "?", x = bx, y = by, w = b } end
        elseif not beltSlot then
            slotBox(empties, bx, by, b, b).type = key
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

    trimList(zones); trimList(empties); trimList(rects)
    win._equipSlotZones = zones
    win._equipBeltZones = beltZones
    win._equipDollEmpty = empties
    win._equipDollLines = {}   -- (no leader lines any more: the line layer draws only the hint)
    win._equipDollAll = rects
    win._equipDollDot = math.max(2, P(2.5))
    -- the controller's focus on a box with an item: its name at once, the same balloon the pointer gets
    local fk = win._gpFocusedEquipSlot
    if not hint and fk and gpFocused(win, fk) then
        for _, z in ipairs(zones) do
            if z.type == fk and z.item then
                hint = { key = fk, text = call(z.item, "getDisplayName") or "?", x = z.x, y = z.y, w = z.w, now = true }
                break
            end
        end
    end
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
        -- toward the figure from the band's edge: the nearest big slot of the column beside it (the split)
        local j = nearestByHeight(zone, el, function(e)
            local d = slotOf(e.slotType)
            if not d then return false end
            local sd, c = splitCol(d.id)
            return sd == sm.side and c == 1
        end)
        if j then return focusAt(w, zi, zone, j) end
    end
    return false    -- the outer edge: leaves the doll
end

-- Left / Right from a big slot in the split: the left columns step to each other (the outer one
-- into the left band), the inner one and the right column cross the figure to each other by
-- height, the right column steps into the right band. Up / Down are the cone's, down a column.
local function dpadSplit(w, zi, zone, el, def, dir)
    if dir ~= "left" and dir ~= "right" then return false end
    local side, col = splitCol(def.id)
    local function big(want, wantCol)
        return nearestByHeight(zone, el, function(e)
            local d = slotOf(e.slotType)
            if not d then return false end
            local sd, c = splitCol(d.id)
            return sd == want and (wantCol == nil or c == wantCol)
        end)
    end
    local function band(want)
        return nearestByHeight(zone, el, function(e) local s2 = smallOf(e.slotType); return s2 and s2.side == want end)
    end
    local j
    if side == "L" and col == 1 then j = (dir == "left") and band("L") or big("L", 2)
    elseif side == "L" then j = (dir == "left") and big("L", 1) or big("R")
    else j = (dir == "right") and band("R") or big("L", 2) end
    if j then return focusAt(w, zi, zone, j) end
    return false
end

--- A D-pad press from a doll slot (el = the focused element); true when it moved the focus.
function D.dpad(w, el, dir)
    local key = el and el.slotType
    local zi, zone = charZone(w)
    if not zone then return false end
    local sm = smallOf(key)
    if sm then return dpadSmall(w, zi, zone, el, sm, dir) end
    local def = slotOf(key)
    if not def then return false end
    if w._equipDollBands then return dpadSplit(w, zi, zone, el, def, dir) end
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

local function inZone(z, mx, my) return mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h end

-- The belt slot (its index in the game's hotbar) under the pointer: a belt row of
-- the list, a box under the doll (empty: _equipBeltZones; filled: a "doll:beltN"
-- slot zone), or the doll's Back, which is the hotbar's Back slot for a weapon
-- or tool (the game's always-there first slot).
local function beltSlotAt(win, pn, mx, my, hit)
    for _, z in ipairs(win._equipBeltZones or {}) do
        if z.i and inZone(z, mx, my) then return z.i end
    end
    for _, z in ipairs(win._equipSlotZones or {}) do
        local n = type(z.type) == "string" and z.type:match("^doll:belt(%d+)$")
        if n and inZone(z, mx, my) then return tonumber(n) end
    end
    if hit and hit.id == "back" and ZeD.Belt then
        for _, s in ipairs(ZeD.Belt.slots(pn)) do
            if s.slot and s.slot.slotType == "Back" then return s.i end
        end
    end
    return nil
end

--- A drop on the Equip tab: clothing over a doll slot it fits is worn there; a
--- weapon or tool over a belt slot (or the doll's Back) is attached there by the
--- game's own action (ISHotbar:attachItem: the timed attach, out of a bag first,
--- as the belt on the HUD takes it). True when it took the drop.
function D.takeDrop(pn, items)
    local win = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    if not win then return false end
    if win._drawerMode ~= "tab" or win._activeTab ~= "equip" or win._equipSelected or (win._drawerEffW or 0) <= 0 then return false end
    if not (items and items[1]) then return false end
    local doll = win._equipDollShown and win._equipDollAll and win._equipDollPanel
    local panel = doll and win._equipDollPanel or win._equipPanel
    if not (panel and panel:isVisible()) then return false end
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if mx < 0 or my < 0 or mx >= panel:getWidth() or my >= panel:getHeight() then return false end
    local clip = doll and win._equipDollClip
    if clip and not inZone(clip, mx, my) then return false end
    local hit
    for _, r in ipairs(doll and win._equipDollAll or {}) do
        if inZone(r, mx, my) then hit = r; break end
    end
    if hit then
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
    end
    local slotI = beltSlotAt(win, pn, mx, my, hit)
    if slotI and ZeD.Belt then
        for _, item in ipairs(items) do
            if ZeD.Belt.attach(pn, item, slotI) then
                win._equipCache, win._equipDollTimer = nil, 99   -- (the rows read the belt again at once)
                return true
            end
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
    layer.onRightMouseDown = function() return false end   -- (B42.22: a handler that returns nothing takes the click)
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
-- the window's overlay (one delay, over everything), its balloon pointing at the box.
-- c = { key, text, x, y, w } (the box in the doll panel's space); st and clip are no
-- longer needed (kept for callers).
local _hintR, _hintNow = {}, { now = true }
function D.drawHint(layer, win, c, st, clip)
    if not c then return end
    local panel = win._equipDollPanel
    if panel and c.x then
        _hintR.x, _hintR.y, _hintR.w, _hintR.h = c.x, c.y, c.w or 1, c.h or c.w or 1
        ZeD.Atoms.requestHint(win, c.key, c.text, panel, _hintR, c.now and _hintNow or nil)
    else
        ZeD.Atoms.requestHint(win, c.key, c.text, layer)
    end
end

-- ----------------------------------------------------------------------------
-- The List | Doll toggle in the Equipped heading, and the card's layer strip
-- ----------------------------------------------------------------------------

--- List | Doll: two separate icon buttons 4u apart at the heading's right edge,
--- the active one solid accent; each names itself in the library's hint after the
--- pause. Stamps win._equipViewZones.
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

--- The card's layer strip: "LAYER 1 OF 2 | OUTERMOST" with Outer / Inner.
--- Stamps win._equipLayerZones. Returns its height.
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

--- Steps the selected slot's layer: dir 1 goes inward, -1 back out.
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
