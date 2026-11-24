-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SpecialTip.lua
-- ============================================================================
-- THE TROUGH AND FARM PLOT HOVER FACTS IN ZeD'S LOOK (Nov 23 2026, the
-- director: "Redraw."). Client.
--
-- Pointing at a feeding trough or a planted farm plot, the game draws a plain
-- box by the pointer (the Java ObjectTooltip, painted by two Lua handlers on
-- Events.DoSpecialTooltip), and it can sit over the character. Those two
-- handlers are kept aside before they are added (shared/ZeD/ZeD_SpecialTipHook.lua);
-- this file draws the same facts, with the same gates and in the game's own
-- words, in ZeD's balloon, never over the character.
--
-- How the game's box works (read from the game's Java, 42.22): when the
-- pointer's picked object has a special tooltip, the ObjectTooltip shows after
-- a short delay; each frame it draws, IsoObject.DoSpecialTooltip sets its
-- height to 0, fires the event, and hides the tooltip for good (until the
-- pointer picks another object) if no handler gave it a height. The tooltip
-- draws nothing of its own (the game's handlers draw its background). So
-- while ZeD has facts to show, its handler gives the tooltip a height of 1:
-- the tooltip stays up, invisible, and the event keeps firing every frame
-- while the pointer stays on the object. It is the pointer's (the mouse
-- picker's) only: a controller never shows it, in the game or here.
--
-- The facts are recorded each time the event fires and drawn by a top-level
-- layer; they go 2 frames after the event stops. When ZeD steps aside (safe
-- mode) the kept game handler is called instead, and the game's box is back.
--
-- For QA:
--   ZeD.SpecialTip.shown     true while the balloon drew in the last frame
--   ZeD.SpecialTip.kind      "trough" or "farm" (what is shown)
--   ZeD.SpecialTip.title     the balloon's title
--   ZeD.SpecialTip.lines     its lines as plain words ("Water levels: Fine")
--   ZeD.SpecialTip.rect      the balloon on the screen { x, y, w, h }
--   ZeD.SpecialTip.anchor    the hovered square on the screen { x, y, w, h }
--   ZeD.SpecialTip.charRect  the character on the screen { x, y, w, h }
--   ZeD.SpecialTip.muted     how many times ZeD's facts stood in for the game's box (one a frame)
--   ZeD.SpecialTip.captured  how many game handlers were kept aside (2 in a normal game)
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/SafeMode"
require "ZeD/Balloon"

ZeD = ZeD or {}
ZeD.SpecialTip = ZeD.SpecialTip or {}
local ST = ZeD.SpecialTip

ST.TROUGH_REACH = 13   -- the game's trough box: only within this many tiles
ST.FARM_REACH = 6      -- the game's farm box: player 0 within this many tiles
ST.FARM_LEVEL = 3      -- ... with at least this Farming level
ST.PHASE_LEVEL = 6     -- the next growing phase from this level
ST.HEAD_Z = 0.75       -- the top of the character's head above its feet, in floors (with a little room)
ST.OBJ_Z = 0.35        -- the hovered object's height above its square, in floors

ST.muted = ST.muted or 0
ST.captured = ST.captured or 0
ST._frame = ST._frame or 0
ST.shown = false

-- true while ZeD draws these facts (not in safe mode)
function ST.active()
    local S = ZeD.Safe
    if S and S.on and S.on() then return false end
    return true
end

-- ---------------------------------------------------------------------------
-- THE FACTS: what the game's handler would show, or nil where it shows nothing.
-- { kind, title, titleSt ("good" / "bad" / nil), lines = { plain words, ... },
--   info = { dim words under them, ... }, rows = { { label, value, st }, ... } }
-- ---------------------------------------------------------------------------

-- CFeedingTroughSystem.lua's DoSpecialTooltip1, step for step
function ST.troughFacts(square)
    if Mouse and Mouse.isRightDown and Mouse.isRightDown() then return nil end
    local sys = CFeedingTroughSystem and CFeedingTroughSystem.instance
    if not (sys and square) then return nil end
    local lo = sys:getLuaObjectOnSquare(square)
    if not lo then return nil end
    -- a two-tile trough: the half that holds the numbers is its partner
    if lo.linkedX and lo.linkedY and lo.linkedX > 0 and lo.linkedY > 0 then
        local sq2 = getSquare(lo.linkedX, lo.linkedY, square:getZ())
        if sq2 then lo = sys:getLuaObjectOnSquare(sq2) end
    end
    if not lo then return nil end
    local trough = lo:getIsoObject()
    if not trough then return nil end
    local pl = getPlayer()
    if pl and pl:DistToProper(trough) > ST.TROUGH_REACH then return nil end
    local feed, water = trough:getCurrentFeedAmount(), trough:getWater()
    local f = { kind = "trough", title = getText("ContextMenu_FeedingTrough"), lines = {}, info = {} }
    local text = getText("Fluid_Empty")
    if water > 0 then
        text = round(trough:getWater(), 2) * 1000 .. " / " .. trough:getMaxWater() * 1000 .. getText("IGUI_Milliliter")
    end
    -- only the water when there's no feed, only the feed when there's no water (the game's rule)
    if feed <= 0 then f.lines[#f.lines + 1] = getText("IGUI_FeedingTroughUI_Water") .. ": " .. text end
    text = getText("Fluid_Empty")
    if feed > 0 then text = round(feed, 2) end
    if water <= 0 then f.lines[#f.lines + 1] = getText("IGUI_FeedingTroughUI_Feeding") .. ": " .. tostring(text) end
    f.info[1] = getText("Tooltip_trough_info1")
    f.info[2] = getText("Tooltip_trough_info2")
    f.info[3] = getText("Tooltip_trough_info3")
    return f
end

-- r, g, b alike (to read which of its colors the game picked)
local function sameRGB(a, b)
    if not (a and b) then return false end
    return math.abs((a.r or 0) - (b.r or 0)) < 0.01 and math.abs((a.g or 0) - (b.g or 0)) < 0.01
       and math.abs((a.b or 0) - (b.b or 0)) < 0.01
end

-- the water level's color from the game's own rule (ISFarmingInfo.getWaterLvlColor), as a status
function ST.waterSt(plant, level)
    local okC, rgb = pcall(ISFarmingInfo.getWaterLvlColor, plant, level)
    if not (okC and rgb) then return nil end
    local ref = {}
    ISFarmingInfo:getGreen(ref)
    if sameRGB(rgb, ref) then return "ok" end
    ISFarmingInfo:getOrange(ref)
    if sameRGB(rgb, ref) then return "warn" end
    ISFarmingInfo:getRed(ref)
    if sameRGB(rgb, ref) then return "bad" end
    return nil   -- (white: below the level that reads it)
end

-- the plant name's color from the game's own rule (ISFarmingInfo.getTitleColor): bad for a dead plant
function ST.titleSt(plant)
    local okC, rgb = pcall(ISFarmingInfo.getTitleColor, plant)
    if not (okC and rgb) then return nil end
    local bad = getCore():getBadHighlitedColor()
    if sameRGB(rgb, { r = bad:getR(), g = bad:getG(), b = bad:getB() }) then return "bad" end
    return "good"
end

-- CFarmingSystem.lua's DoSpecialTooltip1, step for step
function ST.farmFacts(square)
    if ISFarmingCursorMouse and ISFarmingCursorMouse.IsVisible and ISFarmingCursorMouse.IsVisible() then return nil end
    local sys = CFarmingSystem and CFarmingSystem.instance
    if not (sys and square) then return nil end
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return nil end
    if playerObj:DistTo(square:getX(), square:getY()) > ST.FARM_REACH then return nil end
    local cheat = ISFarmingMenu and ISFarmingMenu.cheat
    if sys:getXp(playerObj) < ST.FARM_LEVEL and not cheat then return nil end
    local plant = sys:getLuaObjectOnSquare(square)
    if not plant or plant.typeOfSeed == "none" then return nil end
    local level = sys:getXp(playerObj)
    local f = { kind = "farm", title = farming_vegetableconf.getObjectName(plant), titleSt = ST.titleSt(plant), rows = {} }
    local rows = f.rows
    local function row(label, value, st) rows[#rows + 1] = { label = label, value = value, st = st } end
    if cheat then
        row("state", tostring(plant.state))
        row("nbOfGrow", tostring(plant.nbOfGrow))
        if plant.hasVegetable then row("hasVegetable", tostring(plant.hasVegetable)) end
        if plant.hasSeed then row("hasSeed", tostring(plant.hasSeed)) end
        if plant.cursed then row("cursed", tostring(plant.cursed)) end
        if plant.bonusYield then row("bonusYield", tostring(plant.bonusYield)) end
        if plant.hasWeeds then row("hasWeeds", tostring(plant.hasWeeds)) end
        if (plant.fertilizer or 0) > 0 then row("fertilizer", tostring(plant.fertilizer)) end
        if plant.compost then row("compost", tostring(plant.compost)) end
    end
    if plant:isAlive() then
        row(getText("Farming_Water_levels"), ISFarmingInfo.getWaterLvl(plant, level), ST.waterSt(plant, level))
        if level >= ST.PHASE_LEVEL or cheat then
            -- (the game draws it in its highlight color: a time to watch, not a fault)
            row(getText("Farming_Next_growing_phase"), ISFarmingInfo.getNextGrowingPhase({ plant = plant, character = playerObj }), "warn")
        end
        if cheat then row("hoursElapsed", tostring(sys.hoursElapsed)) end
        if level >= ST.FARM_LEVEL or cheat then
            local pests = { { "aphidLvl", "Farming_Aphid" }, { "mildewLvl", "Farming_Mildew" },
                            { "fliesLvl", "Farming_Pest_Flies" }, { "slugsLvl", "Farming_Slugs" } }
            for _, p in ipairs(pests) do
                local lv = plant[p[1]] or 0
                if lv > 0 then row(getText(p[2]), ISFarmingInfo.getDiseaseString(lv, level), "bad") end
            end
        end
    end
    -- the pest info (cheat only), as the game lists it
    if cheat and farming_vegetableconf.props then
        local props = farming_vegetableconf.props[plant.typeOfSeed] or {}
        local names = {}
        for k, _ in pairs(props) do
            local s = tostring(k)
            if string.find(s, "Food", 1, true) or string.find(s, "Bane", 1, true) or string.find(s, "Proof", 1, true) then
                names[#names + 1] = s
            end
        end
        if #names > 0 then
            row(getText("Farming_Tooltip_PestInfo") .. ":", "")
            for _, s in ipairs(names) do
                row(getText("Farming_" .. string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2, -1)), "")
            end
        end
    end
    return f
end

--- The facts as plain words, one string a line (QA reads these).
function ST.plainLines(f)
    local out = {}
    for _, s in ipairs(f.lines or {}) do out[#out + 1] = s end
    for _, r in ipairs(f.rows or {}) do
        out[#out + 1] = (r.value ~= nil and r.value ~= "") and (tostring(r.label) .. ": " .. tostring(r.value)) or tostring(r.label)
    end
    for _, s in ipairs(f.info or {}) do out[#out + 1] = s end
    return out
end

--- The balloon's content for the facts (ZeD.Balloon's content table), read in the live theme.
function ST.content(f)
    local T = ZeD.T
    local c = { kind = "rich", title = f.title }
    if f.titleSt == "bad" then c.titleColor = T.dangerText
    elseif f.titleSt == "good" then c.titleColor = T.positiveText end
    local lines = {}
    for _, s in ipairs(f.lines or {}) do lines[#lines + 1] = s end
    -- the trough's three how-to lines under the numbers, dimmer (the game leaves a blank line before them)
    for _, s in ipairs(f.info or {}) do lines[#lines + 1] = { text = s, color = T.textSec or T.textDim } end
    if #lines > 0 then c.lines = lines end
    if f.rows and #f.rows > 0 then
        local rows, sig = {}, {}
        for _, r in ipairs(f.rows) do
            local vals = {}
            if r.value ~= nil and r.value ~= "" then vals[1] = { t = tostring(r.value), st = r.st } end
            rows[#rows + 1] = { label = tostring(r.label), values = vals }
            sig[#sig + 1] = tostring(r.label) .. "=" .. tostring(r.value) .. "/" .. tostring(r.st)
        end
        -- (sig: the layout is kept per content; a new table each frame would miss the cache)
        c.req = { rows = rows, conds = {}, sig = table.concat(sig, "\1") }
    end
    return c
end

-- ---------------------------------------------------------------------------
-- WHERE IT GOES
-- ---------------------------------------------------------------------------

local function overlap(ax, ay, aw, ah, r)
    if not r then return 0 end
    local w = math.min(ax + aw, r.x + r.w) - math.max(ax, r.x)
    local h = math.min(ay + ah, r.y + r.h) - math.max(ay, r.y)
    if w <= 0 or h <= 0 then return 0 end
    return w * h
end

--- Where a boxW x boxH balloon goes for the hovered square's screen rect anchor, never over charRect (the character's
--- screen rect), inside a screenW x screenH screen. gap: the room between the square and the box (the tail's), m: the
--- screen margin. Beside the square on the side away from the character first, then above or below it (away first),
--- then beside it on the character's side; a box that would still cover the character slides past it. The first
--- place that covers neither the character nor the square wins; then the first that keeps off the character; then
--- the one that covers the least of it. Returns x, y, side ("right", "left", "above", "below").
function ST.place(boxW, boxH, anchor, charRect, screenW, screenH, gap, m)
    gap, m = gap or 0, m or 0
    local a, cr = anchor, charRect
    local acx, acy = a.x + a.w / 2, a.y + a.h / 2
    local ccx, ccy = acx, acy
    if cr then ccx, ccy = cr.x + cr.w / 2, cr.y + cr.h / 2 end
    local away = (acx >= ccx) and "right" or "left"
    local toward = (away == "right") and "left" or "right"
    local vAway = (acy < ccy) and "above" or "below"
    local vToward = (vAway == "above") and "below" or "above"
    local function clampX(x) return math.max(m, math.min(x, screenW - m - boxW)) end
    local function clampY(y) return math.max(m, math.min(y, screenH - m - boxH)) end
    local cands = {}
    local function add(x, y, side) cands[#cands + 1] = { x = math.floor(clampX(x) + 0.5), y = math.floor(clampY(y) + 0.5), side = side } end
    local function beside(side)
        local x = (side == "right") and (a.x + a.w + gap) or (a.x - gap - boxW)
        add(x, acy - boxH / 2, side)
        if cr then
            add(x, cr.y - gap - boxH, side)        -- (slid up past the character)
            add(x, cr.y + cr.h + gap, side)        -- (slid down past it)
        end
    end
    local function vertical(side)
        local y = (side == "above") and (a.y - gap - boxH) or (a.y + a.h + gap)
        add(acx - boxW / 2, y, side)
        if cr then
            add(cr.x + cr.w + gap, y, side)        -- (slid right past the character)
            add(cr.x - gap - boxW, y, side)        -- (slid left past it)
        end
    end
    beside(away)
    vertical(vAway)
    vertical(vToward)
    beside(toward)
    for _, c in ipairs(cands) do
        if overlap(c.x, c.y, boxW, boxH, cr) == 0 and overlap(c.x, c.y, boxW, boxH, a) == 0 then return c.x, c.y, c.side end
    end
    for _, c in ipairs(cands) do
        if overlap(c.x, c.y, boxW, boxH, cr) == 0 then return c.x, c.y, c.side end
    end
    local best, bestA = cands[1], nil
    for _, c in ipairs(cands) do
        local o = overlap(c.x, c.y, boxW, boxH, cr)
        if bestA == nil or o < bestA then best, bestA = c, o end
    end
    return best.x, best.y, best.side
end

--- The balloon's placement in Balloon's own fields (B.place's), for the box at x, y beside or over anchor.
function ST.placement(x, y, side, w, anchor, cell, depth)
    local pl = { x = x, y = y, side = side, cell = cell, depth = depth }
    if side == "right" or side == "left" then
        pl.corner = "top"
        pl.tipY = math.floor(anchor.y + anchor.h / 2 + 0.5)
    else
        -- the tail toward the square's middle, kept on the box
        local tipX = math.floor(anchor.x + anchor.w / 2 + 0.5)
        tipX = math.max(x, math.min(tipX, x + w - 1))
        pl.corner = (tipX - x < w / 2) and "left" or "right"
        pl.tipX = tipX
    end
    return pl
end

-- the hovered square on the screen: the tile's diamond, raised by the object on it
function ST.squareScreenRect(pn, sq)
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local xs = { isoToScreenX(pn, x, y, z), isoToScreenX(pn, x + 1, y, z), isoToScreenX(pn, x + 1, y + 1, z), isoToScreenX(pn, x, y + 1, z) }
    local ys = { isoToScreenY(pn, x, y, z), isoToScreenY(pn, x + 1, y, z), isoToScreenY(pn, x + 1, y + 1, z), isoToScreenY(pn, x, y + 1, z),
                 isoToScreenY(pn, x, y, z + ST.OBJ_Z) }
    local x0, x1, y0, y1 = xs[1], xs[1], ys[1], ys[1]
    for _, v in ipairs(xs) do x0 = math.min(x0, v); x1 = math.max(x1, v) end
    for _, v in ipairs(ys) do y0 = math.min(y0, v); y1 = math.max(y1, v) end
    return { x = x0, y = y0, w = x1 - x0, h = y1 - y0 }
end

-- the character on the screen: from its feet to the top of its head, a tile's width wide
function ST.charScreenRect(pn, chr)
    local x, y, z = chr:getX(), chr:getY(), chr:getZ()
    local fx, fy = isoToScreenX(pn, x, y, z), isoToScreenY(pn, x, y, z)
    local hy = isoToScreenY(pn, x, y, z + ST.HEAD_Z)
    -- a tile's width on the screen, measured, not assumed (QA, Nov 23 2026: B42's tiles are not 64 px): one step
    -- +x and -y is one tile straight across the screen, whatever the zoom and the tile scale
    local tw = math.abs(isoToScreenX(pn, x + 1, y - 1, z) - fx)
    if not tw or tw <= 0 then
        local zoom = 1
        pcall(function() zoom = getCore():getZoom(pn) end)
        if not zoom or zoom <= 0 then zoom = 1 end
        tw = 64 / zoom
    end
    local halfW = tw * 0.4
    local pad = tw * 0.1
    return { x = fx - halfW, y = hy - pad, w = halfW * 2, h = (fy - hy) + pad * 2 }
end

-- ---------------------------------------------------------------------------
-- THE EVENT: ZeD's facts, or the game's own box when ZeD steps aside
-- ---------------------------------------------------------------------------

function ST.onTip(tooltip, square)
    if not square then return end
    local on = ST.active()
    local facts = nil
    local kinds = { { ST.gameTrough, ST.troughFacts, "trough" }, { ST.gameFarm, ST.farmFacts, "farm" } }
    for _, k in ipairs(kinds) do
        local game = k[1]
        -- (only a handler that was kept aside is stood in for: one that wasn't still draws the game's box itself)
        if game then
            if not on then
                game(tooltip, square)
            elseif not facts then
                local okF, f = pcall(k[2], square)
                if okF then
                    facts = f
                else
                    -- a fact ZeD can't read: the game's box, so nothing is lost
                    if ZeD.logOnce then ZeD.logOnce("specialtip:" .. k[3], "[ZeD] SpecialTip: " .. tostring(f)) end
                    game(tooltip, square)
                end
            end
        end
    end
    if not facts then return end
    -- another balloon holds the slot: ZeD's would not draw, so the game's box stands this frame (QA, Nov 23 2026:
    -- never neither)
    local B = ZeD.Balloon
    if B and B.claim and not B.claim("specialtip:" .. tostring(facts.kind)) then
        for _, k in ipairs(kinds) do
            if k[1] and k[3] == facts.kind then k[1](tooltip, square) end
        end
        return
    end
    facts.square = square
    facts.frame = ST._frame
    ST._hover = facts
    ST.muted = ST.muted + 1
    -- keep the game's tooltip up (it draws nothing of its own): with no height the game hides it and stops asking
    if tooltip and tooltip:getHeight() <= 0 then tooltip:setHeight(1) end
    ST.showLayer()
end

--- The facts to draw now, or nil: the event fired this frame or the one before (the layer may draw first).
function ST.live()
    local h = ST._hover
    if not h then return nil end
    if h.frame < ST._frame - 1 then return nil end
    return h
end

-- ---------------------------------------------------------------------------
-- THE LAYER: a top-level panel above every window that draws the balloon
-- ---------------------------------------------------------------------------
local Layer = nil

function ST.drawOn(p)
    local h = ST.live()
    local B = ZeD.Balloon
    if not (h and B and ZeD.T) then ST.shown = false; return end
    local pn = 0
    local chr = getSpecificPlayer(pn)
    local T = ZeD.T
    local c = ST.content(h)
    local lay = B.layout(c)
    local anchor = ST.squareScreenRect(pn, h.square)
    local cr = chr and ST.charScreenRect(pn, chr) or nil
    local core = getCore()
    local cell = T.hair or 1
    local depth = B.TAIL * cell
    local x, y, side = ST.place(lay.w, lay.h, anchor, cr, core:getScreenWidth(), core:getScreenHeight(), cell + depth, T.px(B.MARGIN))
    local pl = ST.placement(x, y, side, lay.w, anchor, cell, depth)
    local bx = B.draw(p, c, anchor, side, { key = "specialtip:" .. h.kind, owner = p, place = pl })
    ST.shown = bx ~= nil
    ST.kind, ST.title, ST.lines = h.kind, h.title, ST.plainLines(h)
    ST.rect = { x = x, y = y, w = lay.w, h = lay.h }
    ST.anchor, ST.charRect = anchor, cr
end

function ST.showLayer()
    if Layer then
        if not Layer:isVisible() then Layer:setVisible(true) end
        return
    end
    if not ISPanel then return end
    Layer = ISPanel:new(0, 0, 1, 1)
    Layer.background = false
    Layer.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    Layer.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    Layer:initialise()
    Layer:instantiate()
    pcall(function() Layer.javaObject:setConsumeMouseEvents(false) end)
    Layer.prerender = function() end
    Layer.render = function(self)
        local ok, err = pcall(ST.drawOn, self)
        if not ok then
            ST.shown = false
            if ZeD.logOnce then ZeD.logOnce("specialtip:draw", "[ZeD] SpecialTip draw: " .. tostring(err)) end
        end
    end
    Layer:addToUIManager()
    Layer:setAlwaysOnTop(true)
    ST._layer = Layer
end

if Events and not ST._hooked then
    ST._hooked = true
    if Events.OnPreUIDraw then Events.OnPreUIDraw.Add(function() ST._frame = ST._frame + 1 end) end
    -- (the game's Add, not the hook's: ZeD's handler is never one the hook keeps aside)
    if Events.DoSpecialTooltip then
        local add = ST._origAdd or Events.DoSpecialTooltip.Add
        add(function(tooltip, square) ST.onTip(tooltip, square) end)
    end
end

return ST
