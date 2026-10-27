-- ZeD-UI/42/media/lua/client/ZeD/FlyerMap.lua
-- ============================================================================
-- THE FLYER MAP (Oct 19 2026, director: "thats it! its the flyer map! how can
-- we use that in a cool way?" ... "your recs")
--
-- Every newspaper ad, flyer and brochure the character has READ marks its
-- places on the Maps tab (vanilla's rule: ISWorldMap:renderPrintMedia shows
-- only the pieces in getReadPrintMedia). ZeD pins them:
--   * a little paper flyer with a red thumbtack at each place (pixel art,
--     ZeDUI/tools/physpx/d_flyerpin.py); the same pins show on the minimap
--     (the World window's map with its containers rolled up);
--   * hovering one shows a card: what it is and whether you have been there;
--   * a click (A with the map cursor on it) opens the piece in ZeD's reader;
--   * once the character has walked into the place, the character's own
--     ballpoint tick is drawn over the pin ("been there"). Only what the
--     character did: nothing is revealed that reading did not.
--   * a "Show on map" (the reader, the Journal's Papers) lands with a pulse
--     around the place.
-- Visits are kept per character (modData.ZeD_FlyerSeen, a key per place).
-- ============================================================================

require "ZeD/ZeD_PrintPage"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.FlyerMap = ZeD.FlyerMap or {}
local F = ZeD.FlyerMap
local P = ZeD.Print

local NEAREST = 3
local PIN_W, PIN_H = 13, 16          -- texels (d_flyerpin.py)
local TICK_W, TICK_H = 12, 10
local FLASH_MS = 2600
local CHECK_MS = 1000                -- how often the character's place is checked

local _tex = {}
local function tex(name)
    local t = _tex[name]
    if t == nil then t = Texture.getSharedTexture("media/textures/ZeD/map/" .. name .. ".png", NEAREST) or false; _tex[name] = t end
    return t or nil
end

local function key(id, j, k) return tostring(id) .. ":" .. j .. ":" .. k end

-- ---------------------------------------------------------------------------
-- Visits: the character standing inside a place marks it (every piece's places,
-- read or not, so reading one later shows the tick at once)
-- ---------------------------------------------------------------------------
local _lastCheck = 0
local function checkVisits(player)
    if not (player and PrintMediaDefinitions and PrintMediaDefinitions.MiscDetails) then return end
    local now = getTimestampMs()
    if now - _lastCheck < CHECK_MS then return end
    _lastCheck = now
    if player:getZ() < -8 then return end
    local x, y = player:getX(), player:getY()
    local seen = nil
    for id, d in pairs(PrintMediaDefinitions.MiscDetails) do
        for j = 1, 5 do
            local locs = d["location" .. j]
            if not locs then break end
            for k, r in ipairs(locs) do
                if x >= r.x1 and x <= r.x2 + 1 and y >= r.y1 and y <= r.y2 + 1 then
                    seen = seen or player:getModData()
                    seen.ZeD_FlyerSeen = seen.ZeD_FlyerSeen or {}
                    seen.ZeD_FlyerSeen[key(id, j, k)] = true
                end
            end
        end
    end
end
Events.OnPlayerUpdate.Add(function(p)
    if p and p:isLocalPlayer() and p:getPlayerNum() == 0 then checkVisits(p) end
end)

function F.visited(player, id, j, k)
    local s = player and player:getModData().ZeD_FlyerSeen
    return s ~= nil and s[key(id, j, k)] == true
end

-- ---------------------------------------------------------------------------
-- The pins on a map panel (mp: ZeD_WorldMap; its mapAPI and playerObj)
-- ---------------------------------------------------------------------------
local function fit()   -- the pins' whole zoom: the nearest whole number to the scale (T.art; Oct 21 2026)
    local T = ZeD.T
    return T.art or math.max(1, math.floor((T.scale or 1) + 0.5))
end

-- this frame's pins: { id, j, k, x, y, w, h (panel px), cx, cy (world), done }
function F.layout(mp)
    local pins = mp._flyerPins or {}
    for i = #pins, 1, -1 do pins[i] = nil end
    mp._flyerPins = pins
    local chr = mp.playerObj
    local read = chr and chr.getReadPrintMedia and chr:getReadPrintMedia()
    if not (read and not read:isEmpty() and PrintMediaDefinitions and PrintMediaDefinitions.MiscDetails) then return pins end
    local ck = fit()
    local w, h = PIN_W * ck, PIN_H * ck
    local pw, ph = mp:getWidth(), mp:getHeight()
    local api = mp.mapAPI
    local ids = ArrayList.new(read)
    for i = 0, ids:size() - 1 do
        local id = ids:get(i)
        local d = PrintMediaDefinitions.MiscDetails[id]
        for j = 1, 5 do
            local locs = d and d["location" .. j]
            if not locs then break end
            for k, r in ipairs(locs) do
                local cx, cy = (r.x1 + r.x2) / 2, (r.y1 + r.y2) / 2
                -- the tack's point on the place: the pin hangs below it
                local tx, ty = api:worldToUIX(cx, cy), api:worldToUIY(cx, cy)
                local sx = math.floor(tx - w / 2)
                local sy = math.floor(ty - ck)
                -- only a place on the visible map gets its pin (a place past the edge
                -- shows nothing); the map clips what hangs over its edge (MapsTab render)
                if tx >= 0 and ty >= 0 and tx < pw and ty < ph then
                    pins[#pins + 1] = { id = id, j = j, k = k, x = sx, y = sy, w = w, h = h, cx = cx, cy = cy,
                                        done = F.visited(chr, id, j, k) }
                end
            end
        end
    end
    return pins
end

-- the pin under a panel point (the topmost: drawn last)
function F.hit(mp, x, y)
    local pins = mp._flyerPins
    if not pins then return nil end
    -- (the part of a pin past the map's edge is clipped away: it is not there to hover)
    if x < 0 or y < 0 or x >= mp:getWidth() or y >= mp:getHeight() then return nil end
    for i = #pins, 1, -1 do
        local p = pins[i]
        if x >= p.x and x < p.x + p.w and y >= p.y and y < p.y + p.h then return p end
    end
    return nil
end

function F.draw(mp)
    local pins = F.layout(mp)
    local ck = fit()
    local pt, tt = tex("flyer_pin"), tex("flyer_tick")
    for _, p in ipairs(pins) do
        if pt then mp:drawTextureScaledAspect(pt, p.x, p.y, p.w, p.h, 1, 1, 1, 1) end
        if p.done and tt then
            mp:drawTextureScaledAspect(tt, p.x + 2 * ck, p.y + 6 * ck, TICK_W * ck, TICK_H * ck, 1, 1, 1, 1)
        end
    end
    -- the pulse where a Show on map landed
    local f = F._flash
    if f then
        local t = (getTimestampMs() - f.t0) / FLASH_MS
        if t >= 1 then F._flash = nil
        else
            local T = ZeD.T
            local ac = T.accent
            local sx, sy = mp.mapAPI:worldToUIX(f.x, f.y), mp.mapAPI:worldToUIY(f.x, f.y)
            for ring = 0, 1 do
                local tr = (t * 2 + ring * 0.5) % 1
                local r = T.px(8) + tr * T.px(36)
                local a = (1 - tr) * 0.8
                local th = T.px(2)
                mp:drawRectBorder(sx - r, sy - r, r * 2, r * 2, a, ac.r, ac.g, ac.b)
                mp:drawRectBorder(sx - r + th / 2, sy - r + th / 2, r * 2 - th, r * 2 - th, a, ac.r, ac.g, ac.b)
            end
        end
    end
end

-- The hover card (the mouse, or the controller's map cursor): the library's
-- detail card look (ZeD.Atoms.drawHoverShell: surface 1, solid, a 1u frame and
-- System 7's hard shadow; the title in F4, the lines in F2), after the shared
-- hover delay. It sits beside the pin and stays on the map, so it is drawn here
-- rather than at the pointer: a status line carries its square mark (been there:
-- solid, not yet: hollow).
function F.drawCard(mp)
    local T, A = ZeD.T, ZeD.Atoms
    local p = nil
    local pad = false
    local D = ZeD.Input and ZeD.Input.Detector
    local padMode = D and D.getMode and D.getMode() == "gamepad"
    if padMode and mp._gpCursorX and mp._gpCursorLive then
        p = F.hit(mp, mp._gpCursorX, mp._gpCursorY); pad = p ~= nil
    end
    if not p and mp:isMouseOver() then p = F.hit(mp, mp:getMouseX(), mp:getMouseY()) end
    mp._flyerHover = p
    local st = mp._flyerHoverSt
    if not st then st = {}; mp._flyerHoverSt = st end
    if not A.hoverReady(st, p and key(p.id, p.j, p.k)) then return end
    local meta = F.meta(p.id)
    local title, teaser = meta.title, meta.teaser
    local status = ZeD.tr(p.done and "UI_ZeD_Flyer_BeenThere" or "UI_ZeD_Flyer_NotBeenThere")
    local hint = ZeD.tr(pad and "UI_ZeD_Flyer_PadRead" or "UI_ZeD_Flyer_ClickRead")
    local f4, f2 = T.fontF4, T.fontF2
    local tm = ZeD.TM
    local padX, padY, lgap = T.px(10), T.px(8), T.px(2)
    local sq = T.px(6)
    local w = math.max(tm:MeasureStringX(f4, title), sq + T.px(6) + tm:MeasureStringX(f2, status), tm:MeasureStringX(f2, hint),
        teaser and math.min(tm:MeasureStringX(f2, teaser), T.px(260)) or 0) + padX * 2
    w = math.min(w, T.px(280), mp:getWidth() - T.px(8))
    local lh4, lh2 = tm:getFontHeight(f4), tm:getFontHeight(f2)
    local h = padY * 2 + lh4 + T.px(4) + (teaser and (lh2 + lgap) or 0) + lh2 + lgap + lh2
    local x = p.x + p.w + T.px(6)
    if x + w > mp:getWidth() - T.px(4) then x = p.x - w - T.px(6) end
    x = math.max(T.px(4), x)
    local y = math.max(T.px(4), math.min(p.y, mp:getHeight() - h - T.px(4)))
    A.drawHoverShell(mp, x, y, w, h)
    local th, tx, td = T.textHead, T.text, T.textDim
    local inner = w - padX * 2
    local cy = y + padY
    mp:drawText(A.truncateText(title, f4, inner), x + padX, cy, th.r, th.g, th.b, th.a or 1, f4)
    cy = cy + lh4 + T.px(4)
    if teaser then
        mp:drawText(A.truncateText(teaser, f2, inner), x + padX, cy, tx.r, tx.g, tx.b, tx.a or 1, f2)
        cy = cy + lh2 + lgap
    end
    local my = cy + math.floor((lh2 - sq) / 2)
    if p.done then A.drawStatusDot(mp, x + padX, my, T.positive, sq)
    else A.drawStatusHollow(mp, x + padX, my, td, sq) end
    mp:drawText(A.truncateText(status, f2, inner - sq - T.px(6)), x + padX + sq + T.px(6), cy, tx.r, tx.g, tx.b, tx.a or 1, f2)
    cy = cy + lh2 + lgap
    mp:drawText(A.truncateText(hint, f2, inner), x + padX, cy, td.r, td.g, td.b, td.a or 1, f2)
end

-- a piece's name and the first line of its words (looked up once)
local _meta = {}
function F.meta(id)
    local m = _meta[id]
    if m then return m end
    local pm = P.ofId(id)
    local raw = getTextOrNull(pm.text)
    local teaser = nil
    if raw then
        raw = raw:gsub("\\n", "\n")          -- (the text's line breaks are written \n)
        for line in (raw .. "\n"):gmatch("(.-)\n") do
            local t = line:gsub("^%s+", ""):gsub("%s+$", "")
            if t ~= "" then teaser = t; break end
        end
    end
    m = { title = P.title(pm), teaser = teaser }
    _meta[id] = m
    return m
end

-- open the pinned piece in the reader
function F.open(mp, p)
    if not (p and mp.playerObj and ZeD.Reader and ZeD.Reader.openPrintId) then return false end
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
    return ZeD.Reader.openPrintId(mp.playerObj, p.id)
end

-- a Show on map landed here: pulse it
function F.flash(x, y)
    if not (x and y) then return end
    F._flash = { x = x, y = y, t0 = getTimestampMs() }
end
