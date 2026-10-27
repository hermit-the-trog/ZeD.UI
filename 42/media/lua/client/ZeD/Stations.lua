-- ZeD-UI/42/media/lua/client/ZeD/Stations.lua
-- ============================================================================
-- CRAFTING STATIONS — HOOK_MAP rows 1 and 14
-- The World window's Craft tab works at a station as well as by hand. This
-- module owns the station side of that:
--   * discovery  — every usable station within reach of the player: craft
--                  benches (kilns, forges, pottery wheels...), drying racks
--                  (machines with slots and a start / stop cycle), ovens and
--                  microwaves (appliances with knobs);
--   * binding    — which station the Craft tab is working at. Benches and
--                  racks take vanilla's one-player lock (setUsingPlayer), the
--                  same lock vanilla's station window takes, and release it
--                  when the tab goes back to Hand, the player walks away, gets
--                  in a vehicle, or the World window closes;
--   * drawing    — the STATION selector, its dropdown and the station band.
-- The bound views live in CraftingTab (benches), StationMachine (racks) and
-- StationAppliance (oven, microwave). Vanilla entry points are routed here by
-- Overrides/Stations.lua.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/CraftingCore"

ZeD = ZeD or {}
ZeD.Stations = ZeD.Stations or {}
local ST = ZeD.Stations

ST.REACH      = 4     -- tiles: vanilla's station windows close past 4
ST.OVEN_REACH = 3     -- tiles: vanilla's oven / microwave panel closes past 3
ST.SCAN_EVERY = 30    -- frames between nearby scans while a station view draws
ST.gen        = ST.gen or 0   -- bumped on every bind / unbind; views reset on change

local _bind = {}      -- [playerNum] = bound station (nil = Hand)
local _scan = {}      -- [playerNum] = { t = frames since scan, list = stations }

-- ----------------------------------------------------------------------------
-- Safe Java calls. Indexing a Java object by method name yields the method (or
-- nil); pcall keeps a missing or throwing method from breaking the frame.
-- ----------------------------------------------------------------------------
local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
ST.call = call

local function isEntityKind(kind) return kind == "bench" or kind == "machine" end
ST.isEntityKind = isEntityKind

-- ----------------------------------------------------------------------------
-- CLASSIFY — what kind of station an object is, and its working component.
-- ----------------------------------------------------------------------------
function ST.classify(obj)
    if not obj then return nil end
    if instanceof(obj, "IsoStove") then
        if call(obj, "isMicrowave") then return "micro" end
        return "oven"
    end
    if not ComponentType then return nil end
    local bench = call(obj, "getComponent", ComponentType.CraftBench)
    if bench then return "bench", bench end
    local dry = call(obj, "getComponent", ComponentType.DryingCraftLogic)
    if dry then return "machine", dry end
    return nil
end

-- Display name: the entity style's name (what vanilla's window title shows),
-- or the container title for ovens and microwaves.
function ST.nameOf(obj, kind)
    if kind == "oven" or kind == "micro" then
        local c = call(obj, "getContainer")
        local t = c and call(c, "getType")
        if t and getTextOrNull then
            local s = getTextOrNull("IGUI_ContainerTitle_" .. tostring(t))
            if s and s ~= "" then return s end
        end
        return getText(kind == "micro" and "IGUI_ContainerTitle_microwave" or "IGUI_ContainerTitle_stove")
    end
    local style = nil
    if ISEntityUI and ISEntityUI.GetEntityUiStyle then
        local ok, s = pcall(ISEntityUI.GetEntityUiStyle, obj)
        if ok then style = s end
    end
    local n = style and call(style, "getDisplayName")
    if not n or n == "" then n = call(obj, "getEntityDisplayName") end
    if not n or n == "" then n = ZeD.tr("UI_ZeD_Station_Fallback") end
    return tostring(n)
end

-- Icon: the entity style's icon (what vanilla's window header shows). World
-- tile sprites read as a speck at icon size, so appliances go without.
function ST.iconOf(obj, kind)
    if isEntityKind(kind) and ISEntityUI and ISEntityUI.GetEntityUiStyle then
        local ok, style = pcall(ISEntityUI.GetEntityUiStyle, obj)
        local tex = ok and style and call(style, "getIcon")
        if tex then return tex end
    end
    return nil
end

ST.DOT = "|"   -- the separator: ZeD OS's pipe (director, Oct 16 2026: no middle dots)

-- the keys of the kind words on the station band (translated where they are drawn)
local KIND_LABEL = { bench = "UI_ZeD_Station_KindBench", machine = "UI_ZeD_Station_KindMachine",
    oven = "UI_ZeD_Station_KindAppliance", micro = "UI_ZeD_Station_KindAppliance" }
ST.KIND_LABEL = KIND_LABEL

function ST.reachFor(kind)
    if kind == "oven" or kind == "micro" then return ST.OVEN_REACH end
    return ST.REACH
end

-- Distance in tiles from the player to the nearest square the station covers
-- (a two-tile drying rack counts from whichever half is closer).
local function partDist(player, st)
    local px, py = player:getX(), player:getY()
    local best = nil
    for _, s in ipairs(st.squares) do
        local dx, dy = (s[1] + 0.5) - px, (s[2] + 0.5) - py
        local d = math.sqrt(dx * dx + dy * dy)
        if not best or d < best then best = d end
    end
    return best or 999
end

function ST.tilesText(d)
    local n = math.max(1, math.floor((d or 0) + 0.5))
    return n == 1 and ZeD.tr("UI_ZeD_Station_TileOne") or ZeD.tr("UI_ZeD_Station_TileMany", n)
end

-- "The nearest is 3 tiles away." (a whole sentence per count, never glued)
function ST.nearestText(d)
    local n = math.max(1, math.floor((d or 0) + 0.5))
    return n == 1 and ZeD.tr("UI_ZeD_Station_NearestOne") or ZeD.tr("UI_ZeD_Station_NearestMany", n)
end

local function keyFor(sq, kind, obj)
    local spr = call(obj, "getSprite")
    local sn = spr and call(spr, "getName") or "?"
    return tostring(sq:getX()) .. "," .. tostring(sq:getY()) .. "," .. tostring(sq:getZ()) .. ":" .. kind .. ":" .. tostring(sn)
end

-- ----------------------------------------------------------------------------
-- SCAN — every station whose nearest square is within reach on the player's
-- floor. Multi-tile stations resolve to their master object and appear once.
-- ----------------------------------------------------------------------------
function ST.scan(player)
    local out = {}
    if not player then return out end
    local sq0 = player:getCurrentSquare()
    if not sq0 then return out end
    local px, py, pz = sq0:getX(), sq0:getY(), sq0:getZ()
    local cell = getCell()
    local R = ST.REACH
    local byObj = {}
    for x = px - R, px + R do
        for y = py - R, py + R do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    local m = call(o, "getMasterObject") or o
                    local e = byObj[m]
                    if e == nil then
                        local kind, comp = ST.classify(m)
                        if kind and isEntityKind(kind) and ISEntityUI and ISEntityUI.CanOpenWindowFor then
                            local ok, can = pcall(ISEntityUI.CanOpenWindowFor, player, m)
                            if not (ok and can) then kind = nil end
                        end
                        if kind then
                            local msq = call(m, "getSquare") or sq
                            e = { obj = m, kind = kind, comp = comp, key = keyFor(msq, kind, m), squares = {} }
                        else
                            e = false
                        end
                        byObj[m] = e
                    end
                    if e then e.squares[#e.squares + 1] = { x, y } end
                end
            end
        end
    end
    for _, e in pairs(byObj) do
        if e then
            e.dist = partDist(player, e)
            if e.dist <= ST.reachFor(e.kind) + 0.5 then
                e.name = ST.nameOf(e.obj, e.kind)
                local u = call(e.obj, "getUsingPlayer")
                e.inUse = isEntityKind(e.kind) and u ~= nil and u ~= player
                out[#out + 1] = e
            end
        end
    end
    table.sort(out, function(a, b)
        if math.abs(a.dist - b.dist) > 0.01 then return a.dist < b.dist end
        return a.name < b.name
    end)
    return out
end

-- Throttled scan, cached per player. Lazily built fields (icon, recipe set)
-- carry over to the fresh entries for stations that are still there.
function ST.nearby(player, force)
    if not player then return {} end
    local pn = player:getPlayerNum()
    local c = _scan[pn]
    if c and not force and c.t < ST.SCAN_EVERY then
        c.t = c.t + 1
        return c.list
    end
    local list = ST.scan(player)
    if c then
        local old = {}
        for _, e in ipairs(c.list) do old[e.key] = e end
        for _, e in ipairs(list) do
            local o = old[e.key]
            if o then e.recipeSet = o.recipeSet; e.icon = o.icon end
        end
    end
    _scan[pn] = { t = 0, list = list }
    return list
end

function ST.icon(st)
    if st.icon == nil then st.icon = ST.iconOf(st.obj, st.kind) or false end
    return st.icon or nil
end

-- Recipe names a bench or machine can make (lazy, cached on the station).
function ST.recipeSet(st)
    if st.recipeSet then return st.recipeSet end
    local set = {}
    local list = st.comp and call(st.comp, "getRecipes")
    if list then
        for i = 0, list:size() - 1 do
            local r = list:get(i)
            local n = r and call(r, "getName")
            if n then set[n] = true end
        end
    end
    st.recipeSet = set
    return set
end

-- Nearest station within reach that makes a recipe (nil when none).
function ST.nearestFor(player, recipeName)
    for _, st in ipairs(ST.nearby(player)) do
        if isEntityKind(st.kind) and not st.inUse and ST.recipeSet(st)[recipeName] then
            return st
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- RECIPE STATION LABELS — which station a recipe needs, from its tags, with
-- vanilla's own names ("Primitive Kiln", "Simple or better Forge") and a
-- short row tag ("KILN", "FORGE").
-- ----------------------------------------------------------------------------
local SHORT_TAG = {
    WoodCharcoal = "UI_ZeD_Station_ShortCharcoal", CoffeeMachine = "UI_ZeD_Station_ShortCoffee",
    DryingRackGrain = "UI_ZeD_Station_ShortRack", DryingRackHerb = "UI_ZeD_Station_ShortRack",
    DryLeatherLarge = "UI_ZeD_Station_ShortRack", DryLeatherMedium = "UI_ZeD_Station_ShortRack", DryLeathersmall = "UI_ZeD_Station_ShortRack",
    Stone_Quern = "UI_ZeD_Station_ShortQuern", Stone_Mill = "UI_ZeD_Station_ShortMill",
    RemoveFlesh = "UI_ZeD_Station_ShortBeam", RemoveFur = "UI_ZeD_Station_ShortBeam", TanLeather = "UI_ZeD_Station_ShortBarrel",
}
local HEAT_TAG = { Forge = true, PrimitiveForge = true, AdvancedForge = true,
    Furnace = true, PrimitiveFurnace = true, AdvancedFurnace = true,
    KilnSmall = true, KilnLarge = true, DomeKiln = true, WoodCharcoal = true }

local _recipeStation = {}   -- recipe name -> info table or false

function ST.recipeStation(recipe)
    if not recipe then return nil end
    local name = call(recipe, "getName")
    if not name then return nil end
    local cached = _recipeStation[name]
    -- (the words are cached; the test language flips them, so a flip recomputes)
    if cached ~= nil and (cached == false or cached.tt == ZeD.trTestOn()) then return cached or nil end
    local info = false
    if call(recipe, "requiresSpecificWorkstation") then
        local tags = call(recipe, "getTags")
        local labels, short, heat = {}, nil, false
        if tags then
            for i = 0, tags:size() - 1 do
                local tag = tostring(tags:get(i))
                local lbl = getText("IGUI_CraftingWindow_" .. tag)
                if lbl == ("IGUI_CraftingWindow_" .. tag) then lbl = tag end
                labels[#labels + 1] = lbl
                if HEAT_TAG[tag] then heat = true end
                if not short then
                    short = SHORT_TAG[tag]
                    if short then
                        short = ZeD.tr(short)
                    else
                        local last = nil
                        for word in string.gmatch(lbl, "[%a%-]+") do last = word end
                        short = last or lbl   -- the game's own word, as it writes it
                    end
                end
            end
        end
        if #labels > 0 then
            local label = labels[1]
            for i = 2, #labels do
                label = ZeD.tr(i == #labels and "UI_ZeD_Station_ListOr" or "UI_ZeD_Station_ListComma", label, labels[i])
            end
            info = { label = label, short = short or ZeD.tr("UI_ZeD_Station_ShortFallback"), heat = heat, tt = ZeD.trTestOn() }
        end
    end
    _recipeStation[name] = info
    return info or nil
end

-- "Needs a Primitive Kiln." / "Needs an Advanced Forge." One sentence per article, so a
-- language with no articles writes the same words in both keys.
function ST.needsText(label)
    local first = string.lower(string.sub(label or "", 1, 1))
    if first == "a" or first == "e" or first == "i" or first == "o" or first == "u" then
        return ZeD.tr("UI_ZeD_Station_NeedsAn", label)
    end
    return ZeD.tr("UI_ZeD_Station_NeedsA", label)
end

-- ----------------------------------------------------------------------------
-- BINDING
-- ----------------------------------------------------------------------------
function ST.current(player)
    if not player then return nil end
    return _bind[player:getPlayerNum()]
end

function ST.bind(player, st)
    if not (player and st) then return false end
    if isEntityKind(st.kind) then
        local u = call(st.obj, "getUsingPlayer")
        if u ~= nil and u ~= player then return false end
    end
    local pn = player:getPlayerNum()
    local cur = _bind[pn]
    if cur and cur.key == st.key then return true end
    if cur then ST.unbind(player) end
    if isEntityKind(st.kind) then call(st.obj, "setUsingPlayer", player) end
    st.dist = partDist(player, st)
    -- Opened from far away (a right-click on a station across the room): the
    -- leash starts at that distance and tightens as the player closes in.
    st.leash = math.max(ST.reachFor(st.kind) + 0.5, st.dist + 1)
    _bind[pn] = st
    ST.gen = ST.gen + 1
    return true
end

function ST.unbind(player)
    if not player then return end
    local pn = player:getPlayerNum()
    local st = _bind[pn]
    if not st then return end
    _bind[pn] = nil
    if isEntityKind(st.kind) and call(st.obj, "getUsingPlayer") == player then
        call(st.obj, "setUsingPlayer", nil)
    end
    ST.gen = ST.gen + 1
end

-- Keeps a binding honest: the station still exists, the player is near it and
-- out of a vehicle, and nobody else has taken it. Returns the station or nil.
function ST.validate(player)
    if not player then return nil end
    local st = _bind[player:getPlayerNum()]
    if not st then return nil end
    local obj = st.obj
    local sq = call(obj, "getSquare")
    local idx = call(obj, "getObjectIndex")
    if not sq or (idx ~= nil and idx < 0) or player:getVehicle() or player:isDead()
       or math.floor(player:getZ()) ~= sq:getZ() then
        ST.unbind(player)
        return nil
    end
    st.dist = partDist(player, st)
    st.leash = math.max(ST.reachFor(st.kind) + 0.5, math.min(st.leash or 0, st.dist + 1))
    if st.dist > st.leash then
        ST.unbind(player)
        return nil
    end
    if isEntityKind(st.kind) then
        local u = call(obj, "getUsingPlayer")
        if u == nil then
            call(obj, "setUsingPlayer", player)   -- something cleared it: take it back
        elseif u ~= player then
            _bind[player:getPlayerNum()] = nil    -- someone else has it now
            ST.gen = ST.gen + 1
            return nil
        end
    end
    return st
end

-- Resolve a world object (any tile of a station) to a bindable station entry.
function ST.entryFor(player, obj)
    if not (player and obj) then return nil end
    local m = call(obj, "getMasterObject") or obj
    for _, e in ipairs(ST.nearby(player, true)) do
        if e.obj == m then return e end
    end
    local kind, comp = ST.classify(m)
    if not kind then return nil end
    local sq = call(m, "getSquare")
    if not sq then return nil end
    local e = { obj = m, kind = kind, comp = comp, squares = { { sq:getX(), sq:getY() } }, key = keyFor(sq, kind, m) }
    e.dist = partDist(player, e)
    e.name = ST.nameOf(m, kind)
    local u = call(m, "getUsingPlayer")
    e.inUse = isEntityKind(kind) and u ~= nil and u ~= player
    return e
end

-- Release the lock whenever the World window is gone, and keep bindings valid
-- while the player moves around with the Craft tab hidden.
local _tick = 0
local function watchdog()
    _tick = _tick + 1
    if _tick % 15 ~= 0 then return end
    local open = ZeD_WorldWindow and ZeD_WorldWindow.isOpen and ZeD_WorldWindow.isOpen()
    for pn, _ in pairs(_bind) do
        local p = getSpecificPlayer(pn)
        if not p then
            _bind[pn] = nil
            ST.gen = ST.gen + 1
        elseif not open then
            ST.unbind(p)
        else
            ST.validate(p)
        end
    end
end
if Events and Events.OnTick then Events.OnTick.Add(watchdog) end

-- ----------------------------------------------------------------------------
-- OPEN — bind a station and show it in the World window's Craft tab.
-- ----------------------------------------------------------------------------
function ST.open(player, obj)
    if not (player and obj) then return false end
    if not (ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return false end
    local st = ST.entryFor(player, obj)
    if not st then return false end
    if st.inUse then
        if getText then player:Say(getText("IGUI_ObjectAlreadyUsedSayMessage")) end
        return true
    end
    if not ST.bind(player, st) then return false end
    return ZeD_WorldWindow.openTab(player:getPlayerNum(), "craft") and true or false
end

-- ----------------------------------------------------------------------------
-- DRAWING — selector box, dropdown overlay, station band
-- ----------------------------------------------------------------------------

-- A select box in the pop-up menu's look (ZeD_Dropdown): surface 2 with a 1u outline,
-- the label in F1 textDim, the value in F2, the triangle at the right. Hover is the
-- T.hover wash; the controller's mark goes under the words. (accentOn is no longer
-- drawn: a bound station reads from its name and the band under it.) disabled: the
-- whole control at T.disabledAlpha (a select that cannot be opened now).
function ST.drawSelect(panel, x, y, w, h, label, value, accentOn, focused, hovered, disabled)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local da = disabled and T.disabledAlpha or 1
    A.surfaceFill(panel, x, y, w, h, "surf2")
    if hovered and not focused and not disabled then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = focused and ZeD.Focus.mark(panel, x, y, w, h) or false
    A.frame(panel, x, y, w, h, T.borderS, da)
    local cx = x + T.sp.inputPadX
    local lf = T.fontF1
    if label and label ~= "" then
        local s = A.textCase(label)
        local lc = onFocus and T.textOnFocus or T.textDim
        local ly = y + math.floor((h - tm:getFontHeight(lf)) / 2)
        panel:drawText(s, cx, ly, lc.r, lc.g, lc.b, (lc.a or 1) * da, lf)
        cx = cx + tm:MeasureStringX(lf, s) + T.px(6)
    end
    local arrowSz = T.px(5)
    local arrowX = x + w - arrowSz - T.sp.inputPadX
    local vf = T.fontF2
    local v = ZeD.CraftingCore.truncText(value or "", vf, arrowX - cx - T.px(4))
    local vy = y + math.floor((h - tm:getFontHeight(vf)) / 2)
    local tc = onFocus and T.textOnFocus or T.text
    panel:drawText(v, cx, vy, tc.r, tc.g, tc.b, (tc.a or 1) * da, vf)
    local ac = onFocus and T.textOnFocus or T.textDim
    local arc = (da < 1) and { r = ac.r, g = ac.g, b = ac.b, a = (ac.a or 1) * da } or ac
    A.drawTriangleDown(panel, arrowX, y + math.floor((h - arrowSz) / 2), arrowSz, arc)
end

-- Dropdown rows: Hand, a header, then each station in reach.
local OPT_H, HDR_H, DD_MAX_VIS = 26, 18, 9

function ST.dropdownRows(player)
    local rows = { { kind = "hand" } }
    local list = ST.nearby(player)
    rows[#rows + 1] = { kind = "hdr", label = ZeD.tr((#list > 0) and "UI_ZeD_Station_InReach" or "UI_ZeD_Station_NoneInReach") }
    for _, st in ipairs(list) do rows[#rows + 1] = { kind = "station", st = st } end
    return rows
end

function ST.dropdownMaxScroll(rows)
    return math.max(0, #rows - DD_MAX_VIS)
end

-- Layout of the visible dropdown rows (screen px) for draw, click and focus.
function ST.dropdownLayout(geo, rows, scrollOff)
    local T = ZeD.T
    local out = {}
    local y = geo.y
    local shown = 0
    for i = 1 + (scrollOff or 0), #rows do
        if shown >= DD_MAX_VIS then break end
        local r = rows[i]
        local h = T.px(r.kind == "hdr" and HDR_H or OPT_H)
        out[#out + 1] = { row = r, x = geo.x, y = y, w = geo.w, h = h, idx = i }
        y = y + h
        shown = shown + 1
    end
    return out, y - geo.y
end

-- Focus id of a dropdown row (shared by the cue paint and the focusables).
function ST.rowFocusId(prefix, row)
    if row.kind == "hand" then return prefix .. ":st:hand" end
    if row.kind == "station" then return prefix .. ":st:" .. row.st.key end
    return nil
end

function ST.drawDropdown(panel, geo, rows, scrollOff, current, focusId, prefix)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local lay, listH = ST.dropdownLayout(geo, rows, scrollOff)
    -- a pop-up list: solid, System 7's hard shadow outside it
    A.drawHardShadow(panel, geo.x, geo.y, geo.w, listH)
    panel:setStencilRect(geo.x, geo.y, geo.w, listH)
    local bg = T.surf2
    panel:drawRect(geo.x, geo.y, geo.w, listH, 1, bg.r, bg.g, bg.b)
    for _, L in ipairs(lay) do
        local r = L.row
        if r.kind == "hdr" then
            local s1 = T.surf1
            panel:drawRect(L.x, L.y, L.w, L.h, 1, s1.r, s1.g, s1.b)
            local f = T.fontF1
            panel:drawText(A.textCase(r.label), L.x + T.px(8), L.y + math.floor((L.h - tm:getFontHeight(f)) / 2),
                T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f)
        else
            local isOn = (r.kind == "hand" and not current) or (r.kind == "station" and current ~= nil and current.key == r.st.key)
            local dim = r.kind == "station" and r.st.inUse
            -- selected: the one accent wash; hover: T.hover over it
            if isOn then
                local ac = T.accent
                panel:drawRect(L.x, L.y, L.w, L.h, T.selectionA, ac.r, ac.g, ac.b)
            end
            if not dim and A.mouseIn(panel, L.x, L.y, L.w, L.h) then
                local hv = T.hover
                panel:drawRect(L.x, L.y, L.w, L.h, hv.a, hv.r, hv.g, hv.b)
            end
            local onFocus = false
            if focusId and focusId == ST.rowFocusId(prefix, r) then
                onFocus = ZeD.Focus.mark(panel, L.x, L.y, L.w, L.h)
            end
            local isz = T.px(16)
            local ix = L.x + T.px(8)
            local iy = L.y + math.floor((L.h - isz) / 2)
            local tex = (r.kind == "station") and ST.icon(r.st) or nil
            if tex then
                panel:drawTextureScaledAspect(tex, ix, iy, isz, isz, dim and 0.4 or 1, 1, 1, 1)
            else
                local s3 = T.surf3
                panel:drawRect(ix, iy, isz, isz, s3.a, s3.r, s3.g, s3.b)
                panel:drawRectBorder(ix, iy, isz, isz, T.border.a, T.border.r, T.border.g, T.border.b)
            end
            local name = (r.kind == "hand") and ZeD.tr("UI_ZeD_Station_Hand") or r.st.name
            local meta = A.textCase((r.kind == "hand") and ZeD.tr("UI_ZeD_Station_AnySurface") or (r.st.inUse and ZeD.tr("UI_ZeD_Station_InUse") or ST.tilesText(r.st.dist)))
            local mf = T.fontF1
            local mw = tm:MeasureStringX(mf, meta)
            local nf = T.fontF2
            local nx = ix + isz + T.px(6)
            local tc = onFocus and T.textOnFocus or (dim and T.textDim or T.text)
            local nstr = ZeD.CraftingCore.truncText(name, nf, L.x + L.w - T.px(16) - mw - nx)
            panel:drawText(nstr, nx, L.y + math.floor((L.h - tm:getFontHeight(nf)) / 2), tc.r, tc.g, tc.b, tc.a or 1, nf)
            A.drawTextRight(panel, meta, L.x + L.w - T.px(8), L.y + math.floor((L.h - tm:getFontHeight(mf)) / 2), mf, onFocus and T.textOnFocus or T.textDim)
        end
        A.drawDividerH(panel, L.x, L.y + L.h - T.px(1), L.w, false)
    end
    local maxScroll = ST.dropdownMaxScroll(rows)
    if maxScroll > 0 then
        local arrowC = T.textSec
        if (scrollOff or 0) > 0 then
            A.drawTriangleUp(panel, geo.x + math.floor((geo.w - T.px(6)) / 2), geo.y + T.px(2), T.px(6), arrowC)
        end
        if (scrollOff or 0) < maxScroll then
            A.drawTriangleDown(panel, geo.x + math.floor((geo.w - T.px(6)) / 2), geo.y + listH - T.px(8), T.px(6), arrowC)
        end
    end
    panel:drawRectBorder(geo.x, geo.y, geo.w, listH, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    panel:clearStencilRect()
    return lay
end

-- What the band says about a station's state, and the dot colour for it.
function ST.stateText(st, player)
    local T = ZeD.T
    if st.kind == "bench" then
        return ZeD.tr("UI_ZeD_Station_StateInUseByYou"), T.positive
    elseif st.kind == "machine" then
        if st.comp and call(st.comp, "isRunning") then return ZeD.tr("UI_ZeD_Station_StateRunning"), T.positive end
        return ZeD.tr("UI_ZeD_Station_StateIdle"), T.textDim
    else
        local c = call(st.obj, "getContainer")
        local powered = c and call(c, "isPowered")
        if not powered then return ZeD.tr("UI_ZeD_Station_StateNoPower"), T.danger end
        if call(st.obj, "Activated") then return getText("UI_On"), T.positive end
        return getText("UI_Off"), T.textDim
    end
end

-- The station band under the header: icon, name, distance and kind, state.
ST.BAND_H = 28
function ST.drawBand(panel, x, y, w, st, player)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local h = T.px(ST.BAND_H)
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y + h - T.px(1), w, true)
    local cx = x + T.px(10)
    local isz = T.px(18)
    local tex = ST.icon(st)
    if tex then
        panel:drawTextureScaledAspect(tex, cx, y + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1)
        cx = cx + isz + T.px(6)
    end
    local stTxt, stCol = ST.stateText(st, player)
    local sf = T.fontF2
    local stW = tm:MeasureStringX(sf, stTxt)
    local dotSz = T.px(6)
    local stX = x + w - T.px(10) - stW
    panel:drawText(stTxt, stX, y + math.floor((h - tm:getFontHeight(sf)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, sf)
    A.drawStatusDot(panel, stX - dotSz - T.px(5), y + math.floor((h - dotSz) / 2), stCol, dotSz)
    local meta = A.textCase(ST.tilesText(st.dist)) .. "  " .. ST.DOT .. "  " .. (KIND_LABEL[st.kind] and A.textCase(ZeD.tr(KIND_LABEL[st.kind])) or "")
    local mf = T.fontF1
    local nf = T.fontF4
    local metaW = tm:MeasureStringX(mf, meta)
    local nameMax = (stX - dotSz - T.px(14)) - cx - metaW - T.px(8)
    local nstr = ZeD.CraftingCore.truncText(st.name or "", nf, math.max(T.px(40), nameMax))
    panel:drawText(nstr, cx, y + math.floor((h - tm:getFontHeight(nf)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, nf)
    cx = cx + tm:MeasureStringX(nf, nstr) + T.px(8)
    panel:drawText(meta, cx, y + math.floor((h - tm:getFontHeight(mf)) / 2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, mf)
    return h
end

-- ----------------------------------------------------------------------------
-- DROPDOWN BEHAVIOUR — shared by the recipe view (CraftingCore) and the
-- machine / appliance views. State lives on the Craft tab's state table:
-- stDropdownOpen, stDropdownScroll, _stGeo (anchor), _stRows, _stLayout.
-- ----------------------------------------------------------------------------
function ST.drawDropdownFor(panel, state, player, focusId, prefix)
    if not (state.stDropdownOpen and state._stGeo and player) then
        state._stLayout = nil
        return
    end
    local rows = ST.dropdownRows(player)
    state._stRows = rows
    local ms = ST.dropdownMaxScroll(rows)
    state.stDropdownScroll = math.max(0, math.min(ms, state.stDropdownScroll or 0))
    state._stLayout = ST.drawDropdown(panel, state._stGeo, rows, state.stDropdownScroll,
        ST.current(player), focusId, prefix or "craft")
end

-- Choose a row: Hand unbinds, a station binds. Headers and taken stations
-- leave the dropdown open.
function ST.pickRow(state, player, row)
    if not (player and row) then return end
    if row.kind == "hdr" then return end
    if row.kind == "station" then
        if row.st.inUse then return end
        if not ST.bind(player, row.st) then return end
    else
        ST.unbind(player)
    end
    state.stDropdownOpen = false
    state.stDropdownScroll = 0
end

function ST.dropdownClick(state, player, x, y)
    for _, L in ipairs(state._stLayout or {}) do
        if x >= L.x and x < L.x + L.w and y >= L.y and y < L.y + L.h then
            ST.pickRow(state, player, L.row)
            return true
        end
    end
    state.stDropdownOpen = false
    state.stDropdownScroll = 0
    return true
end

function ST.dropdownWheel(state, del)
    local ms = state._stRows and ST.dropdownMaxScroll(state._stRows) or 0
    -- PZ: positive del = scroll down (Q5)
    state.stDropdownScroll = math.max(0, math.min(ms, (state.stDropdownScroll or 0) + (del > 0 and 1 or -1)))
    return true
end

function ST.dropdownFocusables(state, player, prefix)
    local out = {}
    for _, L in ipairs(state._stLayout or {}) do
        local fid = ST.rowFocusId(prefix, L.row)
        if fid and not (L.row.kind == "station" and L.row.st.inUse) then
            out[#out + 1] = {
                x = L.x, y = L.y, w = L.w, h = L.h, id = fid, craftKind = "stRow", row = L.row,
                onFocus = function(w, el) end,
                onActivate = function(w, el) ST.pickRow(state, w._playerObj, el.row) end,
                onCancel = function(w, el)
                    state.stDropdownOpen = false
                    state.stDropdownScroll = 0
                end,
                promptB = getText("UI_Close"),
            }
        end
    end
    return out
end

-- B leaves the station from anywhere in the Craft tab while one is bound.
function ST.addLeaveCancel(elements, win, prefix)
    if prefix ~= "craft" then return end
    local player = win and win._playerObj
    if not (player and ST.current(player)) then return end
    for _, el in ipairs(elements) do
        if not el.onCancel then
            el.onCancel = function(w, _el) ST.unbind(w._playerObj) end
            el.promptB = ZeD.tr("UI_ZeD_Station_Leave")
        end
    end
end

-- ----------------------------------------------------------------------------
-- STATION VIEW SCAFFOLD — shared by the machine and appliance views
-- ----------------------------------------------------------------------------

-- The focused gamepad element id when focus is in the World window's tab
-- content (same resolution CraftingCore.render does for the recipe view).
-- Only while the mark may show (the window has the controller and the pad is
-- in use): the views paint their focus cue from it.
function ST.focusedId(win)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.liveZone and Focus.liveElement) then return nil end
    local fz = Focus.liveZone(win)
    if fz and (fz.zone == "worldTabContent" or fz.zone == "charTabContent") then
        local fe = Focus.liveElement(win)
        return fe and fe.id or nil
    end
    return nil
end

-- Full-width STATION select and the band. Stamps the select's zone and the
-- dropdown anchor; returns the height used.
function ST.renderViewHeader(panel, win, x, y, w, state, st)
    local T = ZeD.T
    local pad = T.px(6)
    local h = T.inputH
    local sx, sy, sw = x + pad, y + pad, w - pad * 2
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local hov = (not state.stDropdownOpen) and mx >= sx and mx < sx + sw and my >= sy and my < sy + h
    ST.drawSelect(panel, sx, sy, sw, h, ZeD.tr("UI_ZeD_Station_SelectLabel"), st.name, true, state._gpFocusedId == "craft:stDrop", hov)
    state.zones[#state.zones + 1] = { type = "stationDropdown", x = sx, y = sy, w = sw, h = h }
    state._stGeo = { x = sx, y = sy + h, w = math.floor(sw / 2) }
    ZeD.Atoms.drawDividerH(panel, x, y + pad * 2 + h - T.px(1), w, true)
    local used = pad * 2 + h
    used = used + ST.drawBand(panel, x, y + used, w, st, win._playerObj)
    return used
end

-- Shared click handling for a view's header: the dropdown when open, the
-- select itself. Returns true when handled.
function ST.viewHeaderClick(state, player, x, y)
    if state.stDropdownOpen then
        ST.dropdownClick(state, player, x, y)
        return true
    end
    for _, z in ipairs(state.zones or {}) do
        if z.type == "stationDropdown" and x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h then
            state.stDropdownOpen = true
            state.stDropdownScroll = 0
            return true
        end
    end
    return false
end

-- The select as a gamepad element (views add it first).
function ST.selectFocusable(state)
    for _, z in ipairs(state.zones or {}) do
        if z.type == "stationDropdown" then
            return {
                x = z.x, y = z.y, w = z.w, h = z.h, id = "craft:stDrop", craftKind = "stDrop",
                onFocus = function(w, el) end,
                onActivate = function(w, el)
                    state.stDropdownOpen = not state.stDropdownOpen
                    state.stDropdownScroll = 0
                end,
            }
        end
    end
    return nil
end

-- Keep the focused element of a scrolling view inside its viewport. zones are
-- last frame's (screen px, scroll baked in); scroll is a ZeD_ScrollbarState.
function ST.followFocus(state, scroll, focusId, viewY, viewH, totalH)
    if not (focusId and scroll and totalH > viewH) then return end
    if state._followId == focusId then return end
    state._followId = focusId
    for _, z in ipairs(state._lastZones or {}) do
        if z.fid == focusId then
            local span = math.max(1, totalH - viewH)
            local off = math.floor(scroll.scrollPos * span)
            local cy = z.y - viewY + off
            local newOff = off
            if cy < off then newOff = cy
            elseif cy + z.h > off + viewH then newOff = cy + z.h - viewH end
            newOff = math.max(0, math.min(span, newOff))
            if newOff ~= off then scroll:setScrollPos(newOff / span) end
            return
        end
    end
end

-- The machine and appliance views have no recipe search.
function ST.hidesSearch(win)
    local player = win and win._playerObj
    local st = player and ST.current(player)
    return st ~= nil and st.kind ~= "bench"
end

print("[ZeD] Stations: station discovery and binding loaded")
return ST
