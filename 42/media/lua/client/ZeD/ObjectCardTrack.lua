-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardTrack.lua
-- ============================================================================
-- OBJECT CARD: ANIMAL TRACKS (card definition, client)
-- Inspect Track (search mode, a track on the ground, or a track item such as
-- droppings or a tuft of fur) opens this card instead of vanilla's small
-- window: what it is, the species (only its size below Tracking 5, as
-- vanilla), how fresh it is, and the way it went on a compass. Vanilla's
-- window never closes by distance and has no controller support; the card
-- keeps the usual leash for a track on the ground and none for one you carry.
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local function txt(k, fb) local s = getTextOrNull and getTextOrNull(k) return s or fb or k end
local function col(c) return c.r, c.g, c.b end

-- (vanilla's names of the eight points, as translation keys; the compass letters are ZeD's own)
local DIR_NAME = { N = "AEBS_zone_name_n", NE = "AEBS_zone_name_ne", E = "AEBS_zone_name_e", SE = "AEBS_zone_name_se",
                   S = "AEBS_zone_name_s", SW = "AEBS_zone_name_sw", W = "AEBS_zone_name_w", NW = "AEBS_zone_name_nw" }
local DIR_DEG = { N = 0, NE = 45, E = 90, SE = 135, S = 180, SW = 225, W = 270, NW = 315 }
local ORDER = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

-- half = true: the half card (220), like the padlock's and the recipe preview's (ZeD_WorldWindow reads def.half);
-- the track's picture and compass sit above its facts there, and the facts' values are cut to the card
-- (the director, Nov 26 2026: "could probably just be a half card"; QA TK2: the values ran past the edge)
local def = { id = "track", half = true }

-- Where a track item is now: the square it lies on, the square of the crate or car it sits in, or none once he
-- carries it (QA TK3, Nov 26 2026: the card kept the square it lay on at open, so one he picked up closed its card
-- 6 tiles from that spot while it was in his bag).
local function itemSquare(item)
    local wi = call(item, "getWorldItem")
    if wi then return call(wi, "getSquare") end
    if call(item, "isInPlayerInventory") then return nil end
    local c = call(item, "getContainer")
    local parent = c and call(c, "getParent")
    return parent and call(parent, "getSquare") or nil
end

-- track = an IsoAnimalTrack on the ground or an InventoryItem with tracks
function def.resolve(player, track)
    if not track then return nil end
    local at = call(track, "getAnimalTracks")
    if not at then return nil end
    local t = { obj = track, at = at, key = "track:" .. tostring(track) }
    if instanceof(track, "IsoAnimalTrack") then
        t.sq = track:getSquare()
        t.tex = getTexture(track:getSprite():getName())
    else
        t.sq = itemSquare(track)
        t.tex = call(track, "getTex") or call(track, "getTexture")
    end
    return t
end

function def.valid(t)
    local o = t.obj
    if instanceof(o, "IsoAnimalTrack") then return o:getSquare() ~= nil and (call(o, "getObjectIndex") or 0) >= 0 end
    -- (read each tick before the leash, so the leash follows the item)
    t.sq = itemSquare(o)
    return true
end

function def.refresh(t, player)
    local at = t.at
    local d = {}
    d.level = player:getPerkLevel(Perks.Tracking)
    local tt = call(at, "getTrackType") or "footstep"
    d.type = txt("IGUI_AnimalTracks_" .. tostring(tt), tostring(tt))
    local dir = call(at, "getDir")
    d.dir = dir and tostring(dir) or nil
    -- vanilla's species rule (ISAnimalTracksUI:getAnimalType)
    local atype = call(at, "getAnimalType")
    local mg = MigrationGroupDefinitions and atype and MigrationGroupDefinitions[atype]
    d.speciesKnown = mg ~= nil and d.level > 4
    if not mg then d.species = "???"
    elseif d.level > 4 then d.species = txt("IGUI_MigrationGroup_" .. tostring(atype), tostring(atype))
    else d.species = txt("IGUI_MigrationGroup_" .. tostring(mg.trackSize), tostring(mg.trackSize)) end
    d.fresh = call(at, "getFreshnessString", d.level) or ""
    t.d = d
    t.verbs = {}
end

function def.title(t) return t.d and t.d.type or txt("IGUI_AnimalTracks_footstep", "Animal Tracks") end
function def.icon(t) return t.tex end
-- the state tag: its words, and the colour of its square mark
function def.pill(t)
    local T = ZeD.T
    if not (t.d and t.d.fresh ~= "") then return nil end
    -- plain, as the game writes it: a green mark read a days-old track as a good state (QA TK1, Nov 26 2026)
    return OC.cap(t.d.fresh), T.textDim
end

-- a map compass: the eight points round a ring, the way it went lit
local function compass(card, cx, cy, r, dir)
    local T, tm = ZeD.T, ZeD.TM
    UI.disc(card, cx, cy, r, T.surf2)
    for d = 0, 355, 5 do UI.run(card, cx, cy, d, r - T.px(1), r, T.borderS, T.px(1)) end
    for d = 0, 350, 10 do UI.run(card, cx, cy, d, r - T.px(16), r - T.px(15), T.border, T.px(1)) end
    local ac = T.accent
    for _, k in ipairs(ORDER) do
        local deg = DIR_DEG[k]
        local a = (deg - 90) * math.pi / 180
        local f = (#k > 1) and T.fontF5 or T.fontF1
        local on = k == dir
        local c = on and ac or T.textDim
        local lx = cx + math.cos(a) * (r - T.px(8))
        local ly = cy + math.sin(a) * (r - T.px(8))
        local kt = ZeD.tr("UI_ZeD_Track_Compass" .. k)
        local lw = tm:MeasureStringX(f, kt)
        card:drawText(kt, math.floor(lx - lw / 2), math.floor(ly - tm:getFontHeight(f) / 2), c.r, c.g, c.b, c.a or 1, f)
    end
    if dir and DIR_DEG[dir] then
        UI.run(card, cx, cy, DIR_DEG[dir], 0, r - T.px(19), ac, T.px(3))
        local a = (DIR_DEG[dir] - 90) * math.pi / 180
        UI.disc(card, cx + math.cos(a) * (r - T.px(19)), cy + math.sin(a) * (r - T.px(19)), T.px(4), ac)
    end
    UI.disc(card, cx, cy, T.px(4), T.text)
end

function def.body(card, x, y, w, t, player)
    local T, tm = ZeD.T, ZeD.TM
    local d = t.d
    if not d then return 0 end
    local A = ZeD.Atoms
    local lw = math.min(T.px(140), w)
    -- side by side when the facts have room beside the picture (the full card), else the picture and the compass
    -- above the facts (the half card)
    local beside = w >= lw + T.px(14) + T.px(180)
    local px = beside and x or (x + math.floor((w - lw) / 2))
    -- the track itself
    local ih = T.px(96)
    UI.fill(card, px, y, lw, ih, "surf2")
    if t.tex then card:drawTextureScaledAspect(t.tex, px + T.px(4), y + T.px(4), lw - 2 * T.px(4), ih - 2 * T.px(4), 1, 1, 1, 1) end
    A.frame(card, px, y, lw, ih, T.borderS)
    -- compass under it
    local r = T.px(60)
    compass(card, px + math.floor(lw / 2), y + ih + T.px(10) + r, r, d.dir)
    local leftH = ih + T.px(10) + r * 2

    -- facts
    local fx = beside and (x + lw + T.px(14)) or x
    local fy = beside and y or (y + leftH + T.px(12))
    local right = x + w   -- (no value runs past the card: TK2)
    local function fact(label, value, dot, dim)
        local f1, f2 = T.fontF1, T.fontF2
        local h = T.px(24)
        local ac = T.accent
        local vx = fx + T.px(96)
        local lab1 = A.truncateText(label, f1, math.max(0, vx - T.px(6) - fx))
        card:drawText(lab1, fx, fy + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
        if dot then
            A.drawStatusDot(card, vx, fy + math.floor((h - T.px(6)) / 2), dot, T.px(6))
            vx = vx + T.px(12)
        end
        local v1 = A.truncateText(tostring(value or ""), f2, math.max(0, right - vx))
        card:drawText(v1, vx, fy + math.floor((h - tm:getFontHeight(f2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
        if dim then
            local dx = vx + tm:MeasureStringX(f2, v1) + T.px(8)
            local d1 = A.truncateText(dim, T.fontF5, math.max(0, right - dx))
            if d1 ~= "" then
                card:drawText(d1, dx, fy + math.floor((h - tm:getFontHeight(T.fontF5)) / 2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF5)
            end
        end
        fy = fy + h
    end
    -- (vanilla's labels end in a colon: the bare word, as the other card labels)
    local function lab(k) return (string.gsub(getText(k), ":%s*$", "")) end
    fact(lab("IGUI_AnimalTracks_Type"), d.type)
    fact(lab("IGUI_AnimalTracks_Animal"), d.species, nil, ZeD.tr("UI_ZeD_Track_TrackingLevel", d.level))
    fact(lab("IGUI_AnimalTracks_Freshness"), d.fresh)
    if d.dir then fact(lab("IGUI_AnimalTracks_Direction"), DIR_NAME[d.dir] and getText(DIR_NAME[d.dir]) or d.dir) end
    return (beside and math.max(leftH, fy - y) or (fy - y)) + T.px(4)
end

OC.register(def)
print("[ZeD] ObjectCardTrack: track card loaded")
return def
