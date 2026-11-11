-- ============================================================================
-- ZeD_LootCard.lua: the loot card, the item a looting player points at, in ZeD's own parts (punch list 146)
-- ============================================================================
-- The director, Nov 10 2026: "The looting tooltips are vanilla. We need to simplify them and use our parts." Then,
-- from three clips of a fast vanilla player looting (ZeDUI/PUNCH_LIST.md 146) and the mockup
-- (ZeDUI/qa/loot_hover_card_mockup.html): a compact card, by the pointer, at once; Alt shows the game's full
-- tooltip instead (ZeD_InvTip.lua), so every mod's lines are one key away.
--
-- The card is ZeD's balloon (Balloon.lua): the item's name as its title (a stack's count after it), then a body of
--   tags     Broken, Wet, Frozen, Burnt; a food's Fresh, Stale or Rotten
--   Condition  the five-cell status bar and its percent, when the item has a condition
--   Weight   and, when it differs, what it weighs worn or held ("0.9 worn": the game's "(0.9 equipped)")
--   its kind's figures:
--     a weapon: damage, a blade's sharpness, reach; a gun: its rounds
--     food: hunger and thirst, signed as the item card signs them
--     clothing: bite and scratch, and against what is worn in that place ("+15" green, "-10" red: the figures the
--       streamer reads in every tooltip)
--     a bag: what it holds of what it can, its weight reduction
--     a book: the pages read; a drainable: what is left
--   and whatever the kind, how full it is when it holds a liquid or runs down (punch lists 151, 152; the director,
--     Nov 11 2026: "At a quick glance that is hovering over something, you're only going to be able to look at it and
--     tell by the level ... It's not until you inspect it ... where you see how much is in it"): a level bar, the fill
--     bar's ten cells, under the liquid's name ("Water", the game's "Mixture" for several; "Empty") in the liquid
--     blue, or "Remaining" in a light neutral (the text's tone) for what runs down; no numbers (the litres are on the item card); the game's
--     "Tainted" as a red tag where its own tooltip shows it; "Unknown" where the game hides the level. The item's one
--     bar is ItemMeter's: an item that holds something shows how full, not its condition.
-- Content is kept per item for half a second (the figures move: a transfer, wear), and per scale and theme.
-- ============================================================================

ZeD = ZeD or {}
ZeD.LootCard = ZeD.LootCard or {}
local LC = ZeD.LootCard

local function safe(o, m, ...)
    if not o then return nil end
    local f = o[m]
    if type(f) ~= "function" then return nil end
    local ok, v = pcall(f, o, ...)
    if ok then return v end
    return nil
end
local function isA(o, cls) local ok, v = pcall(instanceof, o, cls); return ok and v end
-- a game label as a card label: no trailing colon
local function label(key) local s = getText(key) or key; return (s:gsub("%s*:%s*$", "")) end
local function tr(k, ...) return ZeD.tr(k, ...) end
local function f1(v) return string.format("%.1f", v or 0) end
local function kg(v)
    if (v or 0) < 0.1 and (v or 0) > 0 then return string.format("%.2f kg", v) end
    return string.format("%.1f kg", v or 0)
end
local function pct(v) return tostring(math.floor((v or 0) + 0.5)) .. "%" end
local function signed(n)
    n = (n >= 0) and math.floor(n + 0.5) or -math.floor(-n + 0.5)   -- (to the nearest whole, halves away from 0)
    if n > 0 then return "+" .. n end
    return tostring(n)
end

-- what is worn in the place this clothing goes (nil: nothing, or the item itself)
local function wornThere(item, chr)
    if not chr then return nil end
    local loc = safe(item, "getBodyLocation")
    if not loc or loc == "" then return nil end
    local w = safe(chr, "getWornItem", loc)
    if w == item then return nil end
    return w
end

--- The card's facts for item (no drawing): { tags = { {text, key} }, cond = 0..1 or nil, rows = { {label, value,
--- extra, extraKey} } }; key is "good" | "warn" | "bad" | nil (the status colors). chr: whose worn things to compare.
function LC.facts(item, chr)
    local tags, rows = {}, {}
    local f = { tags = tags, rows = rows }
    if safe(item, "isBroken") then tags[#tags + 1] = { tr("UI_ZeD_Loot_Broken"), "bad" } end
    local wet = safe(item, "getWetness")
    if wet and wet > 15 then tags[#tags + 1] = { tr("UI_ZeD_Loot_Wet"), "warn" } end
    local food = isA(item, "Food")
    if food then
        if safe(item, "isRotten") then tags[#tags + 1] = { label("Tooltip_food_Rotten"), "bad" }
        elseif safe(item, "isFresh") then tags[#tags + 1] = { label("Tooltip_food_Fresh"), "good" }
        elseif (safe(item, "getOffAge") or 0) > 0 and (safe(item, "getOffAgeMax") or 0) < 1000000000 then
            tags[#tags + 1] = { label("Tooltip_food_Stale"), "warn" }
        end
        if safe(item, "isBurnt") then tags[#tags + 1] = { tr("UI_ZeD_Loot_Burnt"), "warn" } end
    end
    if safe(item, "isFrozen") then tags[#tags + 1] = { tr("UI_ZeD_Loot_Frozen"), nil } end

    -- the item's one bar (ItemMeter.lua): its condition when it wears, how full when it holds or runs down
    local IM = ZeD.ItemMeter
    local mk, mf = nil, nil
    if IM then mk, mf = IM.of(item) end
    if mk == "cond" and not food then f.cond = mf end
    if mk == "uses" then f.amount = { label = IM.label("uses"), f = mf, color = IM.style("uses") } end
    local fc = IM and IM.fluidOf(item)
    if fc then LC.liquid(f, fc, mk, mf) end

    -- the weight, and worn or held when that is lighter
    local wt = safe(item, "getActualWeight") or safe(item, "getWeight") or 0
    local eq = safe(item, "getEquippedWeight")
    local extra = nil
    if eq and eq > 0 and math.abs(eq - wt) > 0.005 then
        local clothing = isA(item, "Clothing") or ((safe(item, "getBodyLocation") or "") ~= "")
        extra = tr(clothing and "UI_ZeD_Loot_Worn" or "UI_ZeD_Loot_Held", (eq < 0.1) and string.format("%.2f", eq) or f1(eq))
    end
    rows[#rows + 1] = { tr("UI_ZeD_Weight"), kg(wt), extra, nil }

    if isA(item, "HandWeapon") then
        if safe(item, "isRanged") then
            local mx = safe(item, "getMaxAmmo") or 0
            if mx > 0 then rows[#rows + 1] = { label("Tooltip_weapon_Ammo"), tostring(safe(item, "getCurrentAmmoCount") or 0) .. " / " .. mx, nil, nil } end
        else
            local mn, mx = safe(item, "getMinDamage"), safe(item, "getMaxDamage")
            -- (a plain hyphen: the en dash isn't in ZeD's data face, and "0.8–2.0" read "0.82.0": QA's Mac run)
            if mn and mx then rows[#rows + 1] = { label("Tooltip_weapon_Damage"), f1(mn) .. " - " .. f1(mx), nil, nil } end
            if safe(item, "hasSharpness") then
                local sh = safe(item, "getSharpness")
                if sh then rows[#rows + 1] = { tr("UI_ZeD_Loot_Sharpness"), pct(sh * 100), nil, nil } end
            end
            local r = safe(item, "getMaxRange")
            if r and r > 0 then rows[#rows + 1] = { tr("UI_ZeD_Card_Reach"), f1(r), nil, nil } end
        end
    elseif food then
        local h, t = safe(item, "getHungerChange"), safe(item, "getThirstChange")
        if h and h ~= 0 then rows[#rows + 1] = { label("Tooltip_food_Hunger"), signed(-h * 100), nil, nil } end
        if t and t ~= 0 then rows[#rows + 1] = { label("Tooltip_food_Thirst"), signed(-t * 100), nil, nil } end
    elseif isA(item, "Clothing") then
        local worn = wornThere(item, chr)
        for _, d in ipairs({ { "getBiteDefense", "IGUI_health_Bite" }, { "getScratchDefense", "IGUI_health_Scratch" } }) do
            local v = safe(item, d[1]) or 0
            local wv = worn and (safe(worn, d[1]) or 0) or nil
            if v > 0 or (wv and wv > 0) then
                local ex, key = nil, nil
                if wv then
                    local dd = math.floor(v + 0.5) - math.floor(wv + 0.5)
                    if dd ~= 0 then ex, key = signed(dd), (dd > 0) and "good" or "bad" end
                end
                rows[#rows + 1] = { label(d[2]), pct(v), ex, key }
            end
        end
    elseif isA(item, "InventoryContainer") then
        local inv = safe(item, "getInventory")
        local cap = safe(item, "getCapacity") or (inv and safe(inv, "getCapacity")) or 0
        if cap > 0 then rows[#rows + 1] = { tr("UI_ZeD_Loot_Holds"), f1(inv and safe(inv, "getCapacityWeight") or 0) .. " / " .. tostring(math.floor(cap + 0.5)), nil, nil } end
        local red = safe(item, "getWeightReduction")
        if red and red > 0 then rows[#rows + 1] = { tr("UI_ZeD_Card_WeightReduce"), pct(red), nil, nil } end
    elseif isA(item, "Literature") then
        local n = safe(item, "getNumberOfPages") or 0
        if n > 0 then rows[#rows + 1] = { tr("UI_ZeD_Loot_Pages"), tostring(safe(item, "getAlreadyReadPages") or 0) .. " / " .. n, nil, nil } end
    end
    return f
end

--- A liquid container on the card: its level bar (f.amount) under the liquid's name, "Tainted" as a red tag where the
--- game's tooltip shows it, "Unknown" (a row) where the game hides the level. The water card's rules (ZeD.Fluid).
function LC.liquid(f, fc, mk, mf)
    local FL = ZeD.Fluid
    local liquids = {}
    if FL and FL.liquidsOf then
        local ok, v = pcall(FL.liquidsOf, fc)
        if ok and type(v) == "table" then liquids = v end
    end
    local name
    if safe(fc, "isEmpty") then name = label("Fluid_Empty")
    else
        name = FL and FL.fluidLabel and FL.fluidLabel(liquids)
        if not name then
            local pf = safe(fc, "getPrimaryFluid")
            name = pf and (safe(pf, "getTranslatedName") or safe(pf, "getFluidTypeString"))
        end
        name = tostring(name or label("Fluid_Mixture"))
    end
    if FL and FL.taintedShown then
        local ok, v = pcall(FL.taintedShown, fc, liquids)
        if ok and v == true then f.tags[#f.tags + 1] = { label("Tooltip_tainted"), "bad" } end
    end
    if mk == "hidden" then f.rows[#f.rows + 1] = { name, label("Fluid_Unknown"), nil, nil }
    elseif mk == "fluid" then f.amount = { label = name, f = mf, color = ZeD.T and ZeD.T.info, liquid = true } end
end

-- ---------------------------------------------------------------------------
-- THE BODY: measured once per content, drawn by the balloon under the title
-- ---------------------------------------------------------------------------
local function colorOf(key, text)
    local A = ZeD.Atoms
    if key == "good" then return A.statusColor(1, text) end
    if key == "warn" then return A.statusColor(0.5, text) end
    if key == "bad" then return A.statusColor(0, text) end
    return nil
end

local function makeBody(f)
    local T, A, TM = ZeD.T, ZeD.Atoms, ZeD.TM
    local f2, f3 = T.fontF2, T.fontF3
    local lead = T.px(2)
    local lineH = math.max(TM:getFontHeight(f2), TM:getFontHeight(f3)) + lead
    local gap, colGap = T.px(6), T.px(10)
    local barW, barH = T.px(46), (A.fillBarCompactH and A.fillBarCompactH()) or T.px(8)
    -- the tags' row
    local tagsW, tagH = 0, 0
    for i, t in ipairs(f.tags) do
        local w = A.tagW(t[1], t[2] ~= nil)
        tagsW = tagsW + w + ((i > 1) and T.px(4) or 0)
        tagH = T.px(16)
    end
    -- the rows: the widest label, value and extra
    local condLabel = (getText("IGUI_invpanel_Condition") or ""):gsub("%s*:%s*$", "")
    local labW = f.cond and TM:MeasureStringX(f2, condLabel) or 0
    local valW, exW = 0, 0
    if f.amount then labW = math.max(labW, TM:MeasureStringX(f2, f.amount.label)) end
    for _, r in ipairs(f.rows) do
        labW = math.max(labW, TM:MeasureStringX(f2, r[1]))
        valW = math.max(valW, TM:MeasureStringX(f3, r[2]))
        if r[3] then exW = math.max(exW, TM:MeasureStringX(f3, r[3])) end
    end
    local pctW = TM:MeasureStringX(f3, "100%")
    local rightW = math.max(valW + (exW > 0 and (gap + exW) or 0), (f.cond or f.amount) and (barW + gap + pctW) or 0)
    local w = math.max(tagsW, labW + colGap + rightW)
    local n = #f.rows + (f.cond and 1 or 0) + (f.amount and 1 or 0)
    local h = (tagH > 0 and (tagH + T.px(4)) or 0) + n * lineH - lead
    local body = { w = w, h = h }
    body.draw = function(p, x, y)
        local tc, sc = T.text, T.textSec or T.textDim
        local cy = y
        if tagH > 0 then
            local tx = x
            for _, t in ipairs(f.tags) do
                local tw = ZeD.Molecules.drawTag(p, tx, cy, t[1], colorOf(t[2], false))
                tx = tx + (tw or A.tagW(t[1], t[2] ~= nil)) + T.px(4)
            end
            cy = cy + tagH + T.px(4)
        end
        local right = x + w
        local function textY(font) return cy + math.floor((lineH - lead - TM:getFontHeight(font)) / 2) end
        if f.cond then
            p:drawText(condLabel, x, textY(f2), sc.r, sc.g, sc.b, sc.a or 1, f2)
            local s = pct(f.cond * 100)
            A.drawTextRight(p, s, right, textY(f3), f3, tc)
            local bx = right - pctW - gap - barW
            A.drawSegFill(p, bx, cy + math.floor((lineH - lead - barH) / 2), barW, barH, A.STATUS_SEGS, A.statusSegsLit(f.cond), A.statusColor(f.cond))
            cy = cy + lineH
        end
        if f.amount then
            -- the level: the fill bar's ten cells across the bar's and the percent's room, no number
            local am = f.amount
            p:drawText(am.label, x, textY(f2), sc.r, sc.g, sc.b, sc.a or 1, f2)
            local aw = barW + gap + pctW
            A.drawSegFill(p, right - aw, cy + math.floor((lineH - lead - barH) / 2), aw, barH, A.FILL_SEGS or 10,
                A.fillSegsLit(am.f, A.FILL_SEGS or 10), am.color or T.accent)
            cy = cy + lineH
        end
        for _, r in ipairs(f.rows) do
            p:drawText(r[1], x, textY(f2), sc.r, sc.g, sc.b, sc.a or 1, f2)
            if r[3] then
                local ec = colorOf(r[4], true) or sc
                A.drawTextRight(p, r[3], right, textY(f3), f3, ec)
                A.drawTextRight(p, r[2], right - exW - gap, textY(f3), f3, tc)
            else
                A.drawTextRight(p, r[2], right, textY(f3), f3, tc)
            end
            cy = cy + lineH
        end
    end
    -- what it shows, for the balloon's layout cache
    local sig = { tostring(f.cond and math.floor(f.cond * 100) or "-"),
                  f.amount and (f.amount.label .. "~" .. tostring(ZeD.Atoms.fillSegsLit(f.amount.f, ZeD.Atoms.FILL_SEGS or 10))) or "-" }
    for _, t in ipairs(f.tags) do sig[#sig + 1] = t[1] end
    for _, r in ipairs(f.rows) do sig[#sig + 1] = r[1] .. "=" .. r[2] .. "/" .. tostring(r[3]) end
    body.sig = table.concat(sig, "|") .. "@" .. tostring(T.scale) .. tostring(T)
    return body
end

-- per item: its content and when it was made
local _cache = setmetatable({}, { __mode = "k" })
LC._cache = _cache
LC.KEEP_MS = 500

--- The balloon content for item (count: a stack's, shown after the name); chr: whose worn things to compare.
function LC.content(item, chr, count)
    local now = getTimestampMs()
    local e = _cache[item]
    local T = ZeD.T
    if e and e.T == T and e.count == count and now - e.t < LC.KEEP_MS then return e.c end
    local name = safe(item, "getName") or "?"
    if count and count > 1 then name = name .. " ×" .. count end
    local f = LC.facts(item, chr)
    local c = { kind = "card", title = name, body = makeBody(f) }
    if e and e.c and e.c.title == c.title and e.c.body and e.c.body.sig == c.body.sig then c = e.c end   -- (the same table while it shows the same)
    _cache[item] = { c = c, t = now, T = T, count = count }
    return c
end
