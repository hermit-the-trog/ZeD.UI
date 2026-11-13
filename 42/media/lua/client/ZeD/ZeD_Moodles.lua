-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Moodles.lua
-- ============================================================================
-- MOODLES — where vanilla's moodles sit, and ZeD's hover note over them.
-- Client; an organism (ZeD_MoodleLayer, one per local player) that works
-- alongside vanilla's own MoodlesUI rather than replacing it.
--
-- The moodles themselves stay exactly as vanilla draws them: ZeD only moves
-- them and draws its own hover text. The placement is a ZeD-UI option
-- (Settings.lua, "Moodles"), each good for different players:
--   right   (default) vanilla's own MoodlesUI column on the right edge,
--           centred on the screen's middle, kept under the watch
--   left    vanilla's own column on the left edge, centred the same way
--   bottom  a row above the belt (above the dashboard in a car). Vanilla's
--           column only stacks downward, so ZeD draws a faithful copy of it:
--           vanilla's textures for the Moodle size option, the backing tinted
--           grey -> the Good / Bad highlight colour by level / 4, the outline
--           ring, vanilla's order, the wiggle when a level changes
-- Hover text: ZeD's balloon (Balloon.lua: vanilla's name for the level as its
-- title, vanilla's description as its line) beside the moodle, its tail on it,
-- after the shared hover pause. With ZeD setup's "Moodle notices" on, a note
-- (status square, name, description) also shows by itself for a few seconds
-- when a moodle comes on or changes level, in a thought bubble whose trail runs
-- to its moodle: a notice, not pointed at. A ZeD layer lies exactly over vanilla's
-- column; UIManager hands a mouse move to the topmost element under the pointer
-- only, so the column never sees the pointer and never draws its own text, while
-- it keeps drawing the moodles. Clicks pass through, as they do on vanilla's column.
-- The layer keeps its place under the windows (a moodle a window covers is the
-- window's, and shows no balloon); the note and the balloon draw from a second,
-- see-through layer on top of everything (ZeD_MoodleNote).
--
-- Vanilla facts (42.20.2, MoodlesUI): the column sits at x = right edge -
-- (10 + size), y = 120; the engine resets its x every frame before the UI
-- draws (y only in split screen), so the move is made in OnPreUIDraw; slots
-- stack size + 10 apart in the order of its HashMap (see M.order); Well Fed
-- shows from level 3; the hover text is drawn to the LEFT of the column; no
-- chevrons and no pulse are drawn.
--
-- Another mod that draws the moodles itself in place of the game's column (it
-- takes MoodlesUI off the screen and puts a panel of its own there, as Moodle
-- Quarters does: ModSupport/moodle_quarters.lua) says so with M.setStandIn.
-- ZeD keeps placing; it lists the moodles in that mod's order (so the note is
-- for the moodle under the pointer), draws no copy of its own in the row, and
-- tells the mod where the moodles go through M.rect.
-- A stand-in marked whole (ModSupport/ImmersiveMoodles.lua: its own column, side,
-- top and hover text) is left the moodles entirely while it draws: ZeD places
-- nothing, draws no row and no note, and M.rect is nil.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/ZeD_Panel"
require "ZeD/SafeMode"
require "ZeD/ZeD_Bubbles"

ZeD = ZeD or {}
ZeD.Moodles = ZeD.Moodles or {}
local M = ZeD.Moodles

-- Every MoodleType in registration order (M.order sorts them into vanilla's
-- slot order; this order breaks its ties) and each type's art
-- (MoodleTextureSet: FOOD_EATEN reuses the hunger icon)
local ORDER = {
    { "ENDURANCE", "Status_DifficultyBreathing" }, { "TIRED", "Mood_Sleepy" }, { "HUNGRY", "Status_Hunger" },
    { "PANIC", "Mood_Panicked" }, { "SICK", "Mood_Nauseous" }, { "BORED", "Mood_Bored" }, { "UNHAPPY", "Mood_Sad" },
    { "BLEEDING", "Status_Bleeding" }, { "WET", "Status_Wet" }, { "HAS_A_COLD", "Mood_Ill" }, { "ANGRY", "Mood_Angry" },
    { "STRESS", "Mood_Stressed" }, { "THIRST", "Status_Thirst" }, { "INJURED", "Status_InjuredMinor" },
    { "PAIN", "Mood_Pained" }, { "HEAVY_LOAD", "Status_HeavyLoad" }, { "DRUNK", "Mood_Drunk" }, { "DEAD", "Mood_Dead" },
    { "ZOMBIE", "Mood_Zombified" }, { "HYPERTHERMIA", "Status_TemperatureHot" }, { "HYPOTHERMIA", "Status_TemperatureLow" },
    { "WINDCHILL", "Status_Windchill" }, { "CANT_SPRINT", "Status_MovementRestricted" },
    { "UNCOMFORTABLE", "Mood_Discomfort" }, { "NOXIOUS_SMELL", "Mood_NoxiousSmell" }, { "FOOD_EATEN", "Status_Hunger" },
}
local GAP = 10             -- vanilla: slots are size + 10 apart (raw pixels, not ZeD units)
local EDGE = 10            -- vanilla: the column's distance from the screen edge
local SIZES = { 32, 48, 64, 80, 96, 128 }
local GREY = 0.5           -- Color.gray, the level-0 end of vanilla's backing tint

M.PLACES = { "right", "left", "bottom" }

local function safe(f, ...) local ok, r = pcall(f, ...); if ok then return r end return nil end

-- The current placement (the ZeD-UI option; "right" until Settings loads)
function M.place()
    local o = ZeD.Settings and ZeD.Settings.moodlePlaceOption
    local v = o and safe(o.getValue, o)
    return M.PLACES[v or 1] or "right"
end

-- Vanilla's moodle size for the Moodle size option (MoodlesUI.getTextureSizeForOption)
function M.size()
    local core = getCore()
    local opt = (safe(core.getOptionMoodleSize, core) or 2) - 1
    if opt >= 0 and opt < #SIZES then return SIZES[opt + 1] end
    -- the choice after the six sizes follows the font size option instead
    if opt == 6 then
        local f = (safe(core.getOptionFontSizeReal, core) or 1) - 1
        if f >= 0 and f < #SIZES then return SIZES[f + 1] end
    end
    return 32
end

-- Vanilla's order. MoodlesUI keeps its moodles in a HashMap<MoodleType, ...>
-- and draws them in that map's iteration order: 26 entries end in 64
-- buckets, bucket = (h ^ (h >>> 16)) & 63 of each type's hashCode, ties in
-- registration order. hashCode is an identity hash, so the order changes with
-- every launch; it is worked out once per session (tested in game: it matches
-- vanilla's column slot for slot). Without hashCode it falls back to
-- registration order.
local orderCache
local function xor6(a, b)
    local r, bit = 0, 1
    for _ = 1, 6 do
        if a % 2 ~= b % 2 then r = r + bit end
        a, b, bit = math.floor(a / 2), math.floor(b / 2), bit * 2
    end
    return r
end
function M.order()
    if orderCache then return orderCache end
    local rows = {}
    for i, e in ipairs(ORDER) do
        local t = MoodleType and MoodleType[e[1]]
        local idx = i
        local h = t and t.hashCode and safe(t.hashCode, t)
        if h then
            if h < 0 then h = h + 4294967296 end
            idx = xor6(h % 64, math.floor(h / 65536) % 64)
        end
        rows[#rows + 1] = { e = e, idx = idx, ins = i }
    end
    table.sort(rows, function(a, b) if a.idx ~= b.idx then return a.idx < b.idx end return a.ins < b.ins end)
    orderCache = {}
    for _, r in ipairs(rows) do orderCache[#orderCache + 1] = r.e end
    return orderCache
end
Events.OnGameStart.Add(function() orderCache = nil end)

-- A stand-in: another mod that draws the moodles in place of the game's column.
-- spec = { id = "<mod id>",
--          whole = true                                 -- (optional) it draws the moodles in whole: ZeD steps aside
--          order = { { "ENDURANCE", "<art>" }, ... }   -- (optional) its draw order, ORDER's shape; else M.order()
--          drawing = function(playerNum) ... end }      -- true while it draws for that player
local standIn = nil
--- Make `spec` (above) the moodles' stand-in. One at a time: the last to call
--- wins; nil takes it away.
function M.setStandIn(spec) standIn = spec end
-- The stand-in drawing for this player now, or nil (then ZeD works as above)
function M.standIn(playerNum)
    if not standIn or not standIn.drawing then return nil end
    if safe(standIn.drawing, playerNum or 0) then return standIn end
    return nil
end

-- The moodles that are on, in the given order, filled into out (emptied first) with entry tables from
-- pool (reused when pool is the caller's own): { key, type, art, level, gbn (0 neutral, 1 good, 2 bad) }
local function fillActive(md, order, out, pool)
    local n = 0
    if md then
        for _, e in ipairs(order) do
            local t = MoodleType[e[1]]
            local lvl = t and safe(md.getMoodleLevel, md, t) or 0
            -- vanilla shows Well Fed and up only from Stuffed (level 3)
            if e[1] == "FOOD_EATEN" and lvl < 3 then lvl = 0 end
            if lvl and lvl > 0 then
                n = n + 1
                local m = pool[n]
                if not m then m = {}; pool[n] = m end
                m.key, m.type, m.art, m.level = e[1], t, e[2], lvl
                m.gbn = safe(md.getGoodBadNeutral, md, t) or 0
                out[n] = m
            end
        end
    end
    for i = #out, n + 1, -1 do out[i] = nil end
    return out
end

-- The moodles that are on, in vanilla's slot order (the stand-in's, when one draws):
-- { key, type, art, level, gbn (0 neutral, 1 good, 2 bad) }; a new list every call
function M.active(player)
    local out = {}
    local md = player and player:getMoodles()
    if not md or not MoodleType then return out end
    local si = M.standIn(safe(player.getPlayerNum, player))
    return fillActive(md, si and si.order or M.order(), out, {})
end

-- Vanilla's backing colour: grey lerped toward the Good / Bad highlight colour.
-- The two colours are kept between reads: read again whenever a layer
-- reads the moodle list (every 100 ms; the game's Options apply a new colour in play at once), when ZeD's
-- theme changes (a new ZeD.T) and at every game start.
local function hl(getter)
    local core = getCore()
    local c = safe(core[getter], core)
    if not c then return nil end
    local r, g, b = safe(c.getR, c), safe(c.getG, c), safe(c.getB, c)
    if not r then return nil end
    return r, g, b
end
local hlc = { have = false }
local function hlColours()
    if hlc.have and hlc.T == ZeD.T then return hlc end
    local r, g, b = hl("getGoodHighlitedColor")
    hlc.gr, hlc.gg, hlc.gb = r or 0, g or 1, b or 0
    r, g, b = hl("getBadHighlitedColor")
    hlc.br, hlc.bg, hlc.bb = r or 1, g or 0, b or 0
    hlc.T, hlc.have = ZeD.T, true
    return hlc
end
Events.OnGameStart.Add(function() hlc.have = false end)
function M.backing(m)
    local r, g, b
    if m.gbn == 1 then local c = hlColours(); r, g, b = c.gr, c.gg, c.gb
    elseif m.gbn == 2 then local c = hlColours(); r, g, b = c.br, c.bg, c.bb
    else return GREY, GREY, GREY end
    local f = math.min(1, m.level / 4)
    return GREY + (r - GREY) * f, GREY + (g - GREY) * f, GREY + (b - GREY) * f
end

local texCache = {}
local function tex(size, name)
    local k = size .. "/" .. name
    local t = texCache[k]
    if t == nil then
        t = getTexture("media/ui/Moodles/" .. size .. "/" .. name .. ".png") or false
        texCache[k] = t
    end
    return t or nil
end

-- ----------------------------------------------------------------------------
-- ZeD_MoodleLayer — one per local player, a top-level panel. Over vanilla's
-- column (right / left) it only takes the pointer and draws the chip; as the
-- row (bottom) it draws the copy too.
-- ----------------------------------------------------------------------------
ZeD_MoodleLayer = ZeD_MoodleLayer or ZeD_Panel:derive("ZeD_MoodleLayer")

function ZeD_MoodleLayer:new(playerNum)
    local o = ZeD_Panel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o._zedLabel = "Moodles"
    o.anchorBottom, o.anchorRight = false, false
    -- it mirrors vanilla's column, which runs past the bottom of the screen;
    -- ISUIElement:setX / setY clamp a top-level panel (no parent) back onto the
    -- screen unless keepOnScreen is false
    o.keepOnScreen = false
    o._wig = {}            -- per moodle key: { level, osc } for the row's wiggle
    o._step = 0
    return o
end

function ZeD_MoodleLayer:player() return getSpecificPlayer(self.playerNum) end
function ZeD_MoodleLayer:vanilla() return UIManager.getMoodleUI and UIManager.getMoodleUI(self.playerNum) or nil end

-- Where the row sits: above the belt, else above the dashboard, else the bottom
function ZeD_MoodleLayer:_rowY(size)
    local T = ZeD.T
    local pn = self.playerNum
    local top = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - T.px(16)
    local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD(pn) or nil
    if hud and hud._drawn and hud:getIsVisible() then
        top = hud:getY()
    else
        local dash = ZeD.Dashboard and ZeD.Dashboard.getInstance and ZeD.Dashboard.getInstance(pn) or nil
        if dash and dash:getIsVisible() then top = dash:getY() end
    end
    return top - T.px(12) - size
end

-- Where the right column starts: under the watch, else vanilla's 120
function ZeD_MoodleLayer:_rightY()
    local pn = self.playerNum
    local w = pn == 0 and ZeD.Watch and ZeD.Watch.getInstance and ZeD.Watch.getInstance() or nil
    -- only the corner watch: a belt watch popped open sits wherever it was dragged, and
    -- one popped at the bottom would push the moodles into the bottom-right corner
    if w and w:getIsVisible() and w:getHeight() > 0 and not w._belt then
        return w:getY() + w:getHeight() + ZeD.T.px(10)
    end
    return getPlayerScreenTop(pn) + 120
end

-- The moodles that are on for this layer's player (M.active's list), kept in one reused list and read
-- from the game at most every ACTIVE_MS (26 pcall'd getMoodleLevel and a
-- table per moodle every frame). A different character or a different order (a stand-in starting or
-- stopping, a new game) reads at once.
local ACTIVE_MS = 100
function ZeD_MoodleLayer:_activeList(p)
    local list = self._actList
    if not list then list = {}; self._actList = list; self._actPool = {} end
    if not (p and MoodleType) then
        self._actP = nil
        for i = #list, 1, -1 do list[i] = nil end
        return list
    end
    local si = M.standIn(self.playerNum)
    local order = si and si.order or M.order()
    local now = getTimestampMs()
    local at = self._actAt
    if at and p == self._actP and order == self._actOrder and now >= at and now - at < ACTIVE_MS then return list end
    self._actP, self._actOrder, self._actAt = p, order, now
    hlc.have = false                       -- the highlight colours are read again with the list (Options apply them in play)
    return fillActive(p:getMoodles(), order, list, self._actPool)
end

function ZeD_MoodleLayer:_place()
    local T = ZeD.T
    local mui = self:vanilla()
    local p = self:player()
    local place = M.place()
    self._mode = place
    self._rect = nil
    if not (p and mui) then self._show = false; return end
    local pn = self.playerNum
    -- a stand-in that draws the moodles in whole: nothing for ZeD to place or say (the game's
    -- column stays wherever that mod put it; no row, no note, M.rect nil)
    local si = M.standIn(pn)
    if si and si.whole then self._show = false; return end
    local shown = (ISUIHandler == nil or ISUIHandler.allUIVisible ~= false) and mui:isVisible()
    self._show = shown
    if place == "bottom" then
        -- vanilla's column out of sight (re-applied each frame: UIManager.resize resets it)
        if mui:getY() > -5000 then mui:setY(-10000) end
        local size = M.size()
        self._size = size
        self._list = self:_activeList(p)
        local n = #self._list
        local w = n > 0 and (n * size + (n - 1) * GAP) or 0
        local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
        local y = self:_rowY(size)
        if self:getX() ~= x then self:setX(x) end
        if self:getY() ~= y then self:setY(y) end
        if self:getWidth() ~= w then self:setWidth(w) end
        if self:getHeight() ~= size then self:setHeight(size) end
        self._rect = { place = place, x = x, y = y, w = w, h = size, size = size, n = n }
        return
    end
    -- right / left: move vanilla's own column, then lie exactly over it.
    -- The stack is centred on the screen's middle, so it grows up
    -- and down as moodles come and go; it stays under the watch (right) and
    -- above the belt.
    -- (a stand-in keeps the game's column off UIManager, so its width can be stale: the option's size)
    local size = M.standIn(pn) and M.size() or mui:getWidth()
    self._size = size
    self._list = self:_activeList(p)
    local n = #self._list
    local stackH = n > 0 and (n * size + (n - 1) * GAP) or 0
    local top = getPlayerScreenTop(pn)
    local y = top + math.floor((getPlayerScreenHeight(pn) - stackH) / 2)
    local minY = place == "left" and top + T.px(10) or self:_rightY()
    local maxY = self:_rowY(0) - stackH
    if y > maxY then y = maxY end
    if y < minY then y = minY end
    local x
    if place == "left" then
        x = getPlayerScreenLeft(pn) + EDGE
    else
        x = getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn) - EDGE - size
    end
    if mui:getX() ~= x then mui:setX(x) end
    if mui:getY() ~= y then mui:setY(y) end
    local h = mui:getHeight()
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    if self:getWidth() ~= size then self:setWidth(size) end
    if self:getHeight() ~= h then self:setHeight(h) end
    self._rect = { place = place, x = x, y = y, w = size, h = stackH, size = size, n = n }
end

--- Where ZeD put the moodles for this player this frame, in screen pixels:
--- { place, x, y, w, h, size, n } (n moodles, size + 10 apart; a column for right /
--- left, a row for bottom), or nil while they are not shown or ZeD is in safe mode.
function M.rect(playerNum)
    local L = M._layers and M._layers[playerNum or 0]
    if not (L and L._show and L._rect) then return nil end
    if ZeD.Safe and ZeD.Safe.on("moodles") then return nil end
    return L._rect
end

-- The moodle under the pointer (index into self._list), or nil. Only while nothing above the layer holds the
-- pointer there (the engine's own picking, as ZeD_Window:pointerOn asks): a window pulled over the column takes
-- the pointer, and a moodle under it says nothing. (Asked after the cheap test: the pointer on the strip at all.)
function ZeD_MoodleLayer:_hoverIndex()
    local mx, my = self:getMouseX(), self:getMouseY()
    local size = self._size or 32
    if mx < 0 or my < 0 or mx >= self:getWidth() or my >= self:getHeight() then return nil end
    if not self:isMouseOver() then return nil end
    local i
    if self._mode == "bottom" then
        i = math.floor(mx / (size + GAP))
        if mx - i * (size + GAP) >= size then return nil end
    else
        i = math.floor(my / (size + GAP))
        if my - i * (size + GAP) >= size or mx >= size then return nil end
    end
    if i < 0 or i >= #(self._list or {}) then return nil end
    return i + 1
end

-- One moodle as vanilla draws it: backing tinted by level, outline ring, icon
function ZeD_MoodleLayer:_drawMoodle(m, x, y)
    local size = self._size
    local bg, ring = tex(size, "_Moodles_BGsolid"), tex(size, "_Moodles_BGoutline")
    local r, g, b = M.backing(m)
    if bg then self:drawTexture(bg, x, y, 1, r, g, b) end
    if ring then self:drawTexture(ring, x, y, 1, 1, 1, 1) end
    local icon = tex(size, m.art)
    if icon then
        local off = math.ceil((size - icon:getWidth()) / 2)
        self:drawTexture(icon, x + off, y + off, 1, 1, 1, 1)
    end
end

-- The copy, as vanilla draws it: backing, outline, icon; wiggle on a change
function ZeD_MoodleLayer:_drawRow()
    local size = self._size
    local list = self._list
    local frac = (UIManager.getMillisSinceLastRender and UIManager.getMillisSinceLastRender() or 33.3) / 33.3
    self._step = self._step + 0.8 * frac
    local seen = self._seen                                -- (reused, emptied every frame)
    if not seen then seen = {}; self._seen = seen end
    for k in pairs(seen) do seen[k] = nil end
    for i, m in ipairs(list) do
        seen[m.key] = true
        local w = self._wig[m.key]
        if not w then w = { level = m.level, osc = 0 }; self._wig[m.key] = w end
        if w.level ~= m.level then w.level = m.level; w.osc = 1 end
        if w.osc > 0.01 then w.osc = w.osc - w.osc * 0.04 * frac else w.osc = 0 end
        self:_drawMoodle(m, (i - 1) * (size + GAP) + math.floor(math.sin(self._step) * 15.6 * w.osc), 0)
    end
    -- forget the moodles that went away: one that comes back starts over like a new one,
    -- still until its level next changes
    for k in pairs(self._wig) do if not seen[k] then self._wig[k] = nil end end
end

-- The ZeD note: status square, vanilla's name for the level, vanilla's description, in a thought
-- bubble (ZeD.Bubbles' cloud, the one over the head) whose trail of three small bubbles runs to the
-- moodle it is about, so the note shows which moodle it comes from. Right / left: the cloud beside
-- the column, level with its moodle, the trail across; bottom: above the row, the trail down.
-- Laid out in the layer's own space; drawn on `on` (the note layer) with the layer's corner at (ox, oy) in it.
function ZeD_MoodleLayer:_drawChip(m, idx, on, ox, oy)
    on, ox, oy = on or self, ox or 0, oy or 0
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local p = self:player()
    local md = p and p:getMoodles()
    if not md then return end
    local Bb, P = ZeD.Bubbles, ZeD.Px
    if not (Bb and Bb.cloudBody and P) then return end
    local name = safe(md.getMoodleDisplayString, md, m.type) or ""
    local desc = safe(md.getMoodleDescriptionString, md, m.type) or ""
    -- the over-head bubble's pixel art at the screen's whole zoom k; this cloud is taller than the one over
    -- the head, so its corners round in proportion (a third of its height) and its trail is drawn at 2k
    local k = P.k((ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1)
    local tk = 2 * k
    local padX, padY = 9 * k, math.max(T.px(7), 7 * k)     -- inside the cloud, clear of its round corners
    local cw = T.px(252)
    local f4, f2 = T.fontF4, T.fontF2
    local lines = A.wrapText(desc, f2, cw - padX * 2)
    local nh, lh = tm:getFontHeight(f4), tm:getFontHeight(f2)
    local wu = math.ceil(cw / k)
    local hu = math.ceil((padY * 2 + nh + T.px(3) + #lines * lh) / k)
    local W, H = wu * k, hu * k
    local rad = math.max(10.5, math.floor(hu / 3) + 0.5)
    local size = self._size
    local len = Bb.TRAIL_LEN * tk
    local my = (idx - 1) * (size + GAP)
    local cx, cy, dir, tox, toy        -- the cloud and the trail's origin, in the layer (px); the trail's way
    if self._mode == "bottom" then
        local mcx = (idx - 1) * (size + GAP) + math.floor(size / 2)
        toy = -len - 2 * k                                 -- the trail's end two units above the moodle
        cx, cy = mcx - math.floor(W / 2) + 3 * k, toy - k - H
        -- keep it on the player's screen (the trail stays on its moodle)
        local absL = self:getAbsoluteX() + cx
        local minL = getPlayerScreenLeft(self.playerNum) + T.px(8)
        local maxL = getPlayerScreenLeft(self.playerNum) + getPlayerScreenWidth(self.playerNum) - T.px(8) - W
        if absL < minL then cx = cx + (minL - absL) elseif absL > maxL then cx = cx - (absL - maxL) end
        dir, tox = "down", mcx
    elseif self._mode == "left" then
        toy = my + math.floor(size / 2)
        tox = size + len + 2 * k
        cx, cy = tox + k, toy - math.floor(H / 2)
        dir = "left"
    else
        toy = my + math.floor(size / 2)
        tox = -len - 2 * k
        cx, cy = tox - k - W, toy - math.floor(H / 2)
        dir = "right"
    end
    Bb.syncColours(T)
    local cv = P.canvas(on, ox + cx, oy + cy, k)
    Bb.cloudShadow(cv, 0, 0, wu, hu, 1, rad)
    Bb.drawTrail(P.canvas(on, ox + tox, oy + toy, tk), T, dir, 0, 0, 1)
    Bb.cloudBody(cv, T, 0, 0, wu, hu, 1, rad)
    self._chip = { idx = idx, key = m.key, x = cx, y = cy, w = W, h = H, k = k, tk = tk, dir = dir, tox = tox, toy = toy }   -- (where the note went, in the layer's space; the in-game test scripts read it)
    local dot = (m.gbn == 1 and T.positive) or (m.gbn == 2 and (m.level >= 3 and T.danger or T.warning)) or T.textDim
    local ds = T.px(7)
    A.drawStatusDot(on, ox + cx + padX, oy + cy + padY + math.floor((nh - ds) / 2), dot, ds)
    local tc = T.text
    on:drawText(name, ox + cx + padX + ds + T.px(7), oy + cy + padY, tc.r, tc.g, tc.b, tc.a or 1, f4)
    local dc = T.textDim
    local ly = cy + padY + nh + T.px(3)
    for _, ln in ipairs(lines) do
        on:drawText(ln, ox + cx + padX, oy + ly, dc.r, dc.g, dc.b, dc.a or 1, f2)
        ly = ly + lh
    end
end

-- A moodle that comes on or changes level shows its note by itself for NOTICE_MS, on every change,
-- while ZeD setup's "Moodle notices" is on (prerender checks it). Several at once take turns; the
-- queue keeps the one showing and the newest NOTICE_MAX - 1 waiting (the oldest waiting goes). The
-- moodles already on when the layer first sees the player stay quiet. The pointer's moodle wins
-- while it is on one.
local NOTICE_MS, NOTICE_MAX = 4000, 3
function ZeD_MoodleLayer:_noticeTick()
    local now = getTimestampMs()
    local p = self:player()
    local list = self._list or {}
    if not self._levels or self._levelsFor ~= p then
        self._levels, self._levelsFor, self._notices, self._noticeAt = {}, p, {}, nil
        for _, m in ipairs(list) do self._levels[m.key] = m.level end
        return
    end
    -- (two level maps take turns, so a frame makes no new table)
    local q, seen, cur = self._notices, self._levels, self._levelsSpare
    if not cur or cur == seen then cur = {} end
    for k in pairs(cur) do cur[k] = nil end
    for _, m in ipairs(list) do
        cur[m.key] = m.level
        if seen[m.key] ~= m.level then
            if q[1] == m.key then
                self._noticeAt = now                       -- the one showing changed again: its time starts over
            else
                for i = #q, 2, -1 do if q[i] == m.key then table.remove(q, i) end end
                q[#q + 1] = m.key
                while #q > NOTICE_MAX do table.remove(q, 2) end
            end
        end
    end
    self._levels, self._levelsSpare = cur, seen
    for i = #q, 1, -1 do                                   -- a moodle that went away is not shown
        if not cur[q[i]] then table.remove(q, i); if i == 1 then self._noticeAt = nil end end
    end
    if q[1] then
        if not self._noticeAt then self._noticeAt = now
        elseif now - self._noticeAt >= NOTICE_MS then table.remove(q, 1); self._noticeAt = q[1] and now or nil end
    end
end

-- The layer keeps its own place among the windows: it was added at game start, so a window opened or
-- pressed since sits over it and takes the pointer there. The copy of the row (bottom) is the moodles
-- themselves and draws here, under such a window, as the game's own column does. The note and the
-- balloon draw from the note layer instead (ZeD_MoodleNote, over every window), so a note is never half
-- hidden behind the World window, and the layer itself never has to stand over the windows.
function ZeD_MoodleLayer:prerender()
    if not ZeD.T or not self._mode then return end
    self:_noticeTick()
    self._chip = nil
    self._held = nil
    -- (a stand-in draws the row itself, at M.rect)
    if self._show and self._mode == "bottom" and not M.standIn(self.playerNum) then self:_drawRow() end
end

-- A press on the strip leaves the layer where it is (ISUIElement's onFocus brings a top-level panel to
-- the top: the layer would then stand over the windows and take their pointer in its strip)
function ZeD_MoodleLayer:onFocus() end

--- The note or the balloon this frame, drawn on `on` (the note layer, from its render: over every
--- window); the layer's corner sits at (ox, oy) in it.
function ZeD_MoodleLayer:_drawNotes(on)
    if not self._show then return end
    local ox, oy = self:getAbsoluteX() - on:getAbsoluteX(), self:getAbsoluteY() - on:getAbsoluteY()
    local i = self:_hoverIndex()
    -- the moodle under the pointer: its name and description in the balloon beside it, after the shared pause
    self._hvSt = self._hvSt or {}
    local hm = i and self._list[i]
    local A = ZeD.Atoms
    if A and A.hoverReady and A.hoverReady(self._hvSt, hm and hm.key or nil) and hm then
        self:_drawBalloon(hm, i, on, ox, oy)
        return
    end
    if hm then return end
    -- (the pointer went from the moodle onto its balloon: it stays)
    if ZeD.Balloon and ZeD.Balloon.redrawHeld(self, on) then self._held = true; return end
    -- (ZeD setup's "Moodle notices", off for a new player: while it is off, a note shows only under the pointer)
    local S = ZeD.Settings
    local notices = S and S.moodleNoticesOn and S.moodleNoticesOn() or false
    if notices and self._notices[1] then
        for k, m in ipairs(self._list or {}) do if m.key == self._notices[1] then i = k end end
        if i then self:_drawChip(self._list[i], i, on, ox, oy) end
    end
end

-- The moodle's balloon: the game's name for its level as the title, its description as the line,
-- beside the column (the side away from the screen's edge) or above the row, the tail on the moodle.
-- A notice that shows by itself keeps the thought bubble (_drawChip): it is not pointed at.
-- Drawn on `on` (the note layer), the layer's corner at (ox, oy) in it.
function ZeD_MoodleLayer:_drawBalloon(m, idx, on, ox, oy)
    on, ox, oy = on or self, ox or 0, oy or 0
    local p = self:player()
    local md = p and p:getMoodles()
    if not (md and ZeD.Balloon) then return end
    local name = safe(md.getMoodleDisplayString, md, m.type) or ""
    local desc = safe(md.getMoodleDescriptionString, md, m.type) or ""
    local c = self._bc
    if not c or c.title ~= name or self._bcDesc ~= desc then
        c = { kind = "rich", title = name, lines = (desc ~= "") and { desc } or nil }
        self._bc, self._bcDesc = c, desc
    end
    local size = self._size or 32
    local a = self._ba
    if not a then a = {}; self._ba = a end
    local lx, ly = self:getAbsoluteX(), self:getAbsoluteY()
    local side
    if self._mode == "bottom" then
        a.x, a.y, side = lx + (idx - 1) * (size + GAP), ly, "above"
    else
        a.x, a.y = lx, ly + (idx - 1) * (size + GAP)
        side = (self._mode == "left") and "right" or "left"
    end
    a.w, a.h, a.below, a.noFlip = size, size, nil, nil
    local x, y, w, h = ZeD.Balloon.draw(on, c, a, side, { key = "moodle:" .. tostring(m.key), owner = self })
    if x then
        -- (where it went, in the layer's space; the in-game test scripts read it)
        self._chip = { idx = idx, key = m.key, x = x - ox, y = y - oy, w = w, h = h, balloon = true }
    end
end
function ZeD_MoodleLayer:render() end

-- Take every pointer move over the moodles (vanilla's column then never sees
-- the pointer, so its own hover text never draws); let clicks through.
function ZeD_MoodleLayer:onMouseMove(dx, dy) return self._show == true end
function ZeD_MoodleLayer:onMouseMoveOutside(dx, dy) end
function ZeD_MoodleLayer:onMouseDown(x, y) return false end
function ZeD_MoodleLayer:onMouseUp(x, y) return false end
function ZeD_MoodleLayer:onRightMouseDown(x, y) return false end
function ZeD_MoodleLayer:onRightMouseUp(x, y) return false end
function ZeD_MoodleLayer:onMouseWheel(del) return false end

-- ----------------------------------------------------------------------------
-- ZeD_MoodleNote — the note layer, one per moodle layer: a 1x1 top-level panel
-- at the screen's corner, always on top, that takes no pointer at all (as the
-- inventory's loot card's layer, ZeD_InvTip). Its render draws the moodle
-- layer's note and balloon at that layer's place, so they show over every
-- window while the moodle layer keeps its own place under them.
-- ----------------------------------------------------------------------------
ZeD_MoodleNote = ZeD_MoodleNote or ZeD_Panel:derive("ZeD_MoodleNote")

function ZeD_MoodleNote:new(layer)
    local o = ZeD_Panel:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    o.layer = layer
    o._zedLabel = "Moodle notes"
    o.anchorBottom, o.anchorRight = false, false
    o.wantMouseEvents = false
    return o
end
function ZeD_MoodleNote:instantiate()
    ZeD_Panel.instantiate(self)
    pcall(function() self.javaObject:setConsumeMouseEvents(false) end)
end
function ZeD_MoodleNote:onMouseMove() return false end
function ZeD_MoodleNote:onMouseMoveOutside() end
function ZeD_MoodleNote:onMouseDown() return false end
function ZeD_MoodleNote:onMouseUp() return false end
function ZeD_MoodleNote:onRightMouseDown() return false end
function ZeD_MoodleNote:onRightMouseUp() return false end
function ZeD_MoodleNote:onMouseWheel() return false end
function ZeD_MoodleNote:onFocus() end
function ZeD_MoodleNote:prerender() end
function ZeD_MoodleNote:render()
    local L = self.layer
    -- (only for the layer that is installed: a game started again makes new ones)
    if not (ZeD.T and L and L._mode and M._layers[L.playerNum] == L) then return end
    L:_drawNotes(self)
end

-- ----------------------------------------------------------------------------
-- Lifecycle: one layer per local player, each with its note layer
-- ----------------------------------------------------------------------------
M._layers = M._layers or {}
function M.install(playerNum)
    playerNum = playerNum or 0
    local old = M._layers[playerNum]
    if old then return old end
    local shown = not ZeD.Safe.on("moodles")   -- safe mode: hidden until ZeD takes over again
    local layer = ZeD_MoodleLayer:new(playerNum)
    layer:initialise()
    layer:addToUIManager()
    layer:setVisible(shown)
    local note = ZeD_MoodleNote:new(layer)
    note:initialise()
    note:addToUIManager()
    -- (the game's Java side can throw; pcall turns a crash into a note layer that stays in the list's order)
    pcall(function() note:setAlwaysOnTop(true) end)
    note:setVisible(shown)
    layer._note = note
    M._layers[playerNum] = layer
    print("[ZeD] Moodles: layer installed for player " .. tostring(playerNum) .. " (" .. M.place() .. ")")
    return layer
end
function M.getLayer(playerNum) return M._layers[playerNum or 0] end

-- Placement runs just before the UI draws: the engine puts vanilla's column
-- back at the right edge (x only; y in split screen) every frame before that,
-- so a move made any earlier never reaches the screen.
local function preDraw()
    if not ZeD.T then return end
    if ZeD.Safe.on("moodles") then return end   -- safe mode: vanilla's column stays where the engine puts it
    for _, layer in pairs(M._layers) do layer:_place() end
end
Events.OnPreUIDraw.Add(preDraw)

-- Safe mode (SafeMode.lua): the layers hide and vanilla's column goes back to
-- its own spot (the engine resets its x every frame but not its y, which every
-- placement moves). Taking over again shows the layers; preDraw moves the
-- column again.
ZeD.Safe.register("moodles", {
    leave = function()
        for pn, layer in pairs(M._layers) do
            layer:setVisible(false)
            if layer._note then layer._note:setVisible(false) end
            layer._show = false
            local mui = getSpecificPlayer(pn) and layer:vanilla()
            if mui then
                mui:setX(getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn) - EDGE - mui:getWidth())
                mui:setY(getPlayerScreenTop(pn) + 120)
            end
        end
    end,
    enter = function()
        for _, layer in pairs(M._layers) do
            layer:setVisible(true)
            if layer._note then layer._note:setVisible(true) end
        end
    end,
})

Events.OnGameStart.Add(function() M._layers = {}; M.install(0) end)
Events.OnCreatePlayer.Add(function(playerNum) if playerNum and playerNum > 0 then M.install(playerNum) end end)

print("[ZeD] Moodles: module loaded")
return M
