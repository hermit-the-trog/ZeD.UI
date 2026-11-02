-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardPreview.lua
-- ============================================================================
-- OBJECT CARD: THE RECIPE PREVIEW (punch list 49; the director, Nov 1 2026: "I want to
-- see what that upgrade will do before I commit")
-- A click on the picked recipe's icon in the Build or Craft header, or A on it with a
-- controller, opens this half card over the drawer, the way an item card opens over a
-- tab. A build recipe's card: the thing's picture (its tiles laid as the game lays them),
-- the facing with Left / Right to turn it, the game's words, its strength for the
-- character as they stand, and the skill it needs. A craft recipe's card: the item you
-- would get as its card shows it (ZeD.itemFacts, the item card's own facts), and, when
-- the recipe upgrades one of your own items, what changes, old to new. The band's one
-- verb builds or crafts as the drawer's button does. Reading is free: the card opens for
-- a recipe you cannot make yet; only the verb says no. It closes with B or Back, the
-- icon again, or when another recipe is picked (valid() follows the drawer's pick).
-- Strength (ISBuildIsoEntity:getHealth): a fixed health from the recipe's script, or its
-- skill base plus 50 a level of carpentry and 100 more for Handy (buildUtil.getWoodHealth);
-- barricades carry neither, their strength is each plank's.
-- ============================================================================
require "ZeD/ObjectCards"
local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call

local def = { id = "preview", half = true }

-- the faces' names as the compass letters ZeD already has
local FACE_KEYS = { N = "UI_ZeD_Track_CompassN", E = "UI_ZeD_Track_CompassE", S = "UI_ZeD_Track_CompassS", W = "UI_ZeD_Track_CompassW" }
local PICTURE_H = 220        -- design units: the picture box on a build card
local ITEM_ICON = 40         -- the item's picture on a craft card

-- o: { entry, rd, state, win, config } from CraftingCore.openPreview
function def.resolve(player, o)
    if not (o and o.entry and o.state and o.config) then return nil end
    return { obj = o, entry = o.entry, face = 1,
             key = "preview:" .. tostring(o.config.prefix) .. ":" .. tostring(o.entry.name) }
end

-- open while the drawer's pick is still this recipe
function def.valid(t) return t.obj.state.selected == t.entry.name end

local function firstNumber(s)
    local n = tostring(s):match("%-?%d+%.?%d*")
    return n and tonumber(n) or nil
end

local function pctChange(a, b)
    local x, y = firstNumber(a), firstNumber(b)
    if x and y and x ~= 0 then return math.floor((y - x) / math.abs(x) * 100 + 0.5) end
    return nil
end

-- A BUILD RECIPE: the faces' tiles, the strength, the skill
local function buildData(d, t, player)
    local e = t.entry
    local okL, logic = pcall(function()
        local l = BuildLogic.new(player, nil, nil)
        l:setRecipe(e.recipe)
        return l
    end)
    local info = (okL and logic) and call(logic, "getSelectedBuildObject") or nil
    local script = info and call(info, "getScript") or nil
    d.faces = {}
    if info then
        local single = call(info, "isSingleFace")
        for i = 0, 3 do
            local f = call(info, "getFace", i)
            if f then
                local face = { name = tostring(call(f, "getFaceName") or ""), tiles = {} }
                local fw, fh, fz = call(f, "getWidth") or 1, call(f, "getHeight") or 1, call(f, "getzLayers") or 1
                for z = 0, fz - 1 do
                    for y = 0, fh - 1 do
                        for x = 0, fw - 1 do
                            local ti = call(f, "getTileInfo", x, y, z)
                            local sn = ti and call(ti, "getSpriteName") or nil
                            local tex = (sn and sn ~= "") and getTexture(sn) or nil
                            if tex then face.tiles[#face.tiles + 1] = { tex = tex, x = x, y = y, z = z } end
                        end
                    end
                end
                if #face.tiles == 0 then
                    local mt = call(f, "getMasterTileInfo")
                    local sn = mt and call(mt, "getSpriteName") or nil
                    local tex = (sn and sn ~= "") and getTexture(sn) or nil
                    if tex then face.tiles[1] = { tex = tex, x = 0, y = 0, z = 0 } end
                end
                if #face.tiles > 0 then d.faces[#d.faces + 1] = face end
                if single then break end
            end
        end
    end
    if #d.faces == 0 then
        local sn = info and call(info, "getMainSpriteNameUI") or nil
        local tex = ((sn and sn ~= "") and getTexture(sn)) or e.iconTex
        if tex then d.faces[1] = { name = "", tiles = { { tex = tex, x = 0, y = 0, z = 0 } } } end
    end
    local health = script and call(script, "getHealth") or -1
    local base = script and call(script, "getSkillBaseHealth") or 0
    if health and health ~= -1 then
        d.strength = tostring(health)
    elseif base and base > 0 then
        local lvl = call(player, "getPerkLevel", Perks.Woodwork) or 0
        local skill = lvl * 50
        if CharacterTrait and CharacterTrait.HANDY and call(player, "hasTrait", CharacterTrait.HANDY) then skill = skill + 100 end
        d.strength = ZeD.tr("UI_ZeD_Preview_StrengthSkill", tostring(base), tostring(skill))
    end
    local sk = {}
    for _, s in ipairs(e.skillDefs or {}) do sk[#sk + 1] = tostring(s.name) .. " " .. tostring(s.required) end
    d.skill = (#sk > 0) and table.concat(sk, ", ") or nil
end

-- A CRAFT RECIPE: the item you would get, and what changes from the one of yours it upgrades
local function craftData(d, t, player)
    local e = t.entry
    local out = e.outputDefs and e.outputDefs[1] or nil
    local types = {}
    if out then for ft in pairs(out.validTypes or {}) do types[#types + 1] = ft end end
    table.sort(types)
    d.outName = (out and out.name) or e.displayName
    d.others = math.max(0, #types - 1)
    local item = nil
    if types[1] and instanceItem then
        local okI, it = pcall(instanceItem, types[1])
        if okI then item = it end
    end
    if item and ZeD.itemFacts then d.facts, d.bars, d.cat = ZeD.itemFacts(item) end
    d.tex = (item and (call(item, "getTex") or call(item, "getTexture"))) or e.iconTex
    d.weight = item and call(item, "getActualWeight") or nil
    if item and d.cat and (d.cat == "Weapon" or d.cat == "Firearm" or d.cat == "Clothing") then
        local inv = call(player, "getInventory")
        for _, inp in ipairs(e.inputDefs or {}) do
            for ift in pairs(inp.validTypes or {}) do
                local it = inv and call(inv, "getFirstTypeRecurse", ift) or nil
                if it then
                    local f2, _, c2 = ZeD.itemFacts(it)
                    if c2 == d.cat then
                        d.base, d.baseFacts, d.baseName = it, f2, call(it, "getDisplayName")
                        break
                    end
                end
            end
            if d.base then break end
        end
    end
    if d.baseFacts and d.facts then
        local byLabel = {}
        for _, f in ipairs(d.baseFacts) do byLabel[f.label] = f.value end
        d.changes = {}
        for _, f in ipairs(d.facts) do
            local old = byLabel[f.label]
            if old ~= nil and tostring(old) ~= tostring(f.value) then
                d.changes[#d.changes + 1] = { label = tostring(f.label), old = tostring(old), new = tostring(f.value), pct = pctChange(old, f.value) }
            end
        end
        local w1 = call(d.base, "getActualWeight")
        if w1 and d.weight and math.abs(w1 - d.weight) > 0.005 then
            d.changes[#d.changes + 1] = { label = ZeD.tr("UI_ZeD_Preview_Weight"), old = string.format("%.1f", w1), new = string.format("%.1f", d.weight) }
        end
    end
    local sk = {}
    for _, s in ipairs(e.skillDefs or {}) do sk[#sk + 1] = tostring(s.name) .. " " .. tostring(s.required) end
    d.skill = (#sk > 0) and table.concat(sk, ", ") or nil
end

function def.refresh(t, player)
    local e, o = t.entry, t.obj
    local d = { words = e.description }
    if o.config.prefix == "build" then buildData(d, t, player) else craftData(d, t, player) end
    t.d = d
    -- the drawer's own reading of the recipe, fresh when it is still this one
    local rd = (o.state._rdLast and o.state._rdLast.entry == e) and o.state._rdLast or o.rd
    local can = rd ~= nil and rd.status == "craftable" and rd.learned ~= false and rd.hasSkill ~= false
    local needs = nil
    if rd and rd.learned == false then needs = ZeD.tr("UI_ZeD_Preview_NeedLearn")
    elseif rd and rd.hasSkill == false then needs = ZeD.tr("UI_ZeD_Preview_NeedSkill")
    elseif not can then needs = ZeD.tr("UI_ZeD_Preview_NeedParts") end
    local labelKey = o.config.buildLabel or "IGUI_CraftingWindow_Craft"
    t.verbs = { {
        id = "go", label = ZeD.btnCase and ZeD.btnCase(getText(labelKey)) or getText(labelKey), primary = true,
        enabled = can and true or false, needs = needs, hint = ZeD.tr("UI_ZeD_Preview_HintGo"),
        run = function(pl, tt, card)
            card:close()
            if o.config.startAction then o.config.startAction(o.win, o.state) end
        end,
    } }
end

function def.title(t) return t.entry.displayName end
function def.icon(t) return (t.d and t.d.tex) or t.entry.iconTex end

-- the tiles of a face laid as the game lays them (a square's step half a tile's width across and a
-- quarter down, a storey three quarters of a tile's height up), fitted into the box
local function drawTiles(card, tiles, x, y, w, h)
    if #tiles == 0 then return end
    local pos = {}
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for i, tl in ipairs(tiles) do
        local tw = call(tl.tex, "getWidthOrig") or call(tl.tex, "getWidth") or 0
        local th = call(tl.tex, "getHeightOrig") or call(tl.tex, "getHeight") or 0
        if tw > 0 and th > 0 then
            local dx = (tl.x - tl.y) * tw / 2
            local dy = (tl.x + tl.y) * tw / 4 - tl.z * th * 0.75
            pos[i] = { dx = dx, dy = dy, tw = tw, th = th, order = (tl.x + tl.y) * 10 + tl.z, i = i }
            if dx < minX then minX = dx end
            if dy < minY then minY = dy end
            if dx + tw > maxX then maxX = dx + tw end
            if dy + th > maxY then maxY = dy + th end
        end
    end
    local list = {}
    for _, p in pairs(pos) do list[#list + 1] = p end
    if #list == 0 then return end
    table.sort(list, function(a, b) return a.order < b.order end)
    local cw, ch = maxX - minX, maxY - minY
    local k = math.min(w / cw, h / ch)
    local ox = x + (w - cw * k) / 2 - minX * k
    local oy = y + (h - ch * k) / 2 - minY * k
    for _, p in ipairs(list) do
        card:drawTextureScaled(tiles[p.i].tex, ox + p.dx * k, oy + p.dy * k, p.tw * k, p.th * k, 1, 1, 1, 1)
    end
end

function def.body(card, x, y, w, t, player)
    local T, tm = ZeD.T, ZeD.TM
    local d = t.d
    if not d then return 0 end
    local cy = y
    if t.obj.config.prefix == "build" then
        local n = #(d.faces or {})
        local face = (n > 0) and d.faces[((t.face - 1) % n) + 1] or nil
        local boxH = T.px(PICTURE_H)
        UI.fill(card, x, cy, w, boxH, "surf2")
        if face then
            drawTiles(card, face.tiles, x + T.px(8), cy + T.px(8), w - T.px(16), boxH - T.px(16))
        else
            local f2, c = T.fontF2, T.textDim
            local s = ZeD.tr("UI_ZeD_Preview_NoPicture")
            card:drawText(s, x + math.floor((w - tm:MeasureStringX(f2, s)) / 2), cy + math.floor((boxH - tm:getFontHeight(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
        end
        ZeD.Atoms.frame(card, x, cy, w, boxH, T.borderS)
        cy = cy + boxH + T.px(6)
        if n > 1 then
            local bh = T.buttonH
            local bw = UI.buttonW("<")
            UI.button(card, x, cy, "<", { w = bw, h = bh, hover = UI.hovered(card, "oc:faceL"), focus = card:focusOf("oc:faceL") })
            card:zone({ fid = "oc:faceL", x = x, y = cy, w = bw, h = bh, body = true, help = ZeD.tr("UI_ZeD_Preview_TurnLeft"),
                run = function() t.face = t.face - 1 end })
            UI.button(card, x + w - bw, cy, ">", { w = bw, h = bh, hover = UI.hovered(card, "oc:faceR"), focus = card:focusOf("oc:faceR") })
            card:zone({ fid = "oc:faceR", x = x + w - bw, y = cy, w = bw, h = bh, body = true, help = ZeD.tr("UI_ZeD_Preview_TurnRight"),
                run = function() t.face = t.face + 1 end })
            local nm = face and face.name or ""
            if FACE_KEYS[nm] then nm = ZeD.tr(FACE_KEYS[nm]) end
            local label = (nm ~= "") and ZeD.tr("UI_ZeD_Preview_Facing", nm) or ""
            local f2, c = T.fontF2, T.text
            card:drawText(label, x + math.floor((w - tm:MeasureStringX(f2, label)) / 2), cy + math.floor((bh - tm:getFontHeight(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + bh + T.px(8)
        end
        if d.words then cy = cy + UI.para(card, x, cy, w, d.words) + T.px(6) end
        if d.strength then cy = cy + UI.pairWide(card, x, cy, w, ZeD.tr("UI_ZeD_Preview_Strength"), d.strength) end
        if d.skill then cy = cy + UI.pairWide(card, x, cy, w, ZeD.tr("UI_ZeD_Preview_Skill"), d.skill) end
    else
        cy = cy + UI.section(card, x, cy, w, ZeD.tr("UI_ZeD_Preview_YouGet")) + T.px(4)
        local isz = T.px(ITEM_ICON)
        UI.fill(card, x, cy, isz, isz, "surf2")
        if d.tex then card:drawTextureScaledAspect(d.tex, x + T.px(4), cy + T.px(4), isz - T.px(8), isz - T.px(8), 1, 1, 1, 1) end
        ZeD.Atoms.frame(card, x, cy, isz, isz, T.borderS)
        local f2, f5 = T.fontF2, T.fontF5
        local nx = x + isz + T.px(8)
        local c = T.text
        card:drawText(ZeD.Atoms.truncateText(tostring(d.outName or ""), f2, x + w - nx), nx, cy + T.px(2), c.r, c.g, c.b, c.a or 1, f2)
        if d.others > 0 then
            local dc = T.textDim
            card:drawText(ZeD.tr("UI_ZeD_Preview_OneOf", tostring(d.others)), nx, cy + T.px(4) + tm:getFontHeight(f2), dc.r, dc.g, dc.b, dc.a or 1, f5)
        end
        cy = cy + isz + T.px(6)
        if d.words then cy = cy + UI.para(card, x, cy, w, d.words) + T.px(6) end
        for _, f in ipairs(d.facts or {}) do cy = cy + UI.pairWide(card, x, cy, w, tostring(f.label), tostring(f.value)) end
        if d.weight then cy = cy + UI.pairWide(card, x, cy, w, ZeD.tr("UI_ZeD_Preview_Weight"), string.format("%.1f", d.weight)) end
        if d.skill then cy = cy + UI.pairWide(card, x, cy, w, ZeD.tr("UI_ZeD_Preview_Skill"), d.skill) end
        if d.changes and #d.changes > 0 then
            cy = cy + T.px(6) + UI.section(card, x, cy, w, ZeD.tr("UI_ZeD_Preview_Changes"), d.baseName) + T.px(4)
            for _, ch in ipairs(d.changes) do
                local v = ZeD.tr("UI_ZeD_Preview_ChangeLine", ch.old, ch.new)
                if ch.pct then v = v .. string.format(" (%+d%%)", ch.pct) end
                cy = cy + UI.pairWide(card, x, cy, w, ch.label, v)
            end
        end
    end
    return cy - y
end

OC.register(def)
print("[ZeD] ObjectCards: recipe preview card loaded")
return def
