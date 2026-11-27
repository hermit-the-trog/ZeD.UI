-- ZeDUI/tools/qa/gc_qa_cleanup_sim.lua  (QA cleanup run, Nov 22 2026): two of QA's findings after the graphic
-- cleanup, checked with no game running, on the real ZeD_BodyFigure.lua and ObjectCardLaundry.lua.
--   FIGURE   every part of both figures (male, female) at several zooms (1, 2, 3 and one below 1): its focus box
--            (getPartRects) holds a point the figure's hit map (hitTestAt) gives back to that part, the box's centre
--            first. The boxes (M_HITS / F_HITS) and the hit map (M_HITMAP / F_HITMAP) come from the same art, so
--            every part's box and its hit pixels must agree.
--   LAUNDRY  the room behind each face (the floor round the top-loading washer, the wall behind the dryer and the
--            washer-dryer) on the full, 336 and half cards, with the card's body scrolled so the face runs past the
--            bottom of its view: no backdrop draw lies outside the card, its body's width or its view.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/gc_qa_cleanup_sim.lua
-- It prints FAIL lines and a last line "gc_qa_cleanup_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]gc_qa_cleanup_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end
local function loadFile(path)
    local f = io.open(path, "rb")
    if not f then return false, "missing " .. path end
    local src = f:read("*a")
    f:close()
    local fn, err = loadstring(src, "@" .. path)
    if not fn then return false, err end
    return pcall(fn)
end

-- ---------------------------------------------------------------------------
-- stubs: just enough of the game and of ZeD for the two files to load
-- ---------------------------------------------------------------------------
require = function() return nil end
local function col() return { r = 1, g = 1, b = 1, a = 1 } end
ZeD = {
    T = setmetatable({ px = function(n) return n end }, { __index = function(t, k) local c = col(); rawset(t, k, c); return c end }),
    tr = function(k) return k end,
    trDefaults = noop,
    textCase = function(s) return s end,
    colorBlend = function(a) return a end,
    paperTone = function(c) return c end,
}
ISPanel = {}
function ISPanel:derive(name) local c = {}; setmetatable(c, { __index = self }); c.Type = name; return c end
function ISPanel:new(x, y, w, h) local o = { x = x, y = y, width = w, height = h }; return o end
ISPanel.render, ISPanel.onMouseMove, ISPanel.onMouseMoveOutside, ISPanel.onMouseDown = noop, noop, noop, noop
Texture = { getSharedTexture = function(p) return { path = p } end }
instanceof = function() return false end
getTimestampMs = function() return 0 end
local byteChar = string.char
string.char = function(...)     -- (the game's strings are wide; a wide char is one "?" here, as dash_odo_sim.lua)
    local out = {}
    for i = 1, select("#", ...) do
        local c = select(i, ...)
        out[i] = c > 255 and "?" or byteChar(c)
    end
    return table.concat(out)
end

-- ===========================================================================
-- FIGURE
-- ===========================================================================
local ok, err = loadFile(CLIENT .. "ZeD_BodyFigure.lua")
check("FIGURE ZeD_BodyFigure.lua loads", ok, err)
local panel = { drawTextureScaled = noop, drawTextureScaledUniform = noop }
-- (the canvas 106 x 254 since Nov 23 2026: the measure stops at the head)
local SIZES = { { 106, 254, "1x" }, { 212, 508, "2x" }, { 318, 762, "3x" }, { 80, 192, "below 1x" } }
if ok then
    for _, fem in ipairs({ false, true }) do
        for _, sz in ipairs(SIZES) do
            local fig = ZeD_BodyFigure:new(0, 0, 100, 100)
            fig:setSex(fem)
            fig.texturesLoaded = true   -- (no textures here: drawAt only needs its transform)
            fig:drawAt(panel, 7, 11, sz[1], sz[2])
            local rects = fig:getPartRects()
            local say = (fem and "female" or "male") .. " at " .. sz[3]
            check("FIGURE " .. say .. ": 17 focus boxes", #rects == 17, #rects)
            for _, r in ipairs(rects) do
                local cx, cy = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
                local hit = fig:hitTestAt(cx, cy) == r.name
                if not hit then   -- (the centre may fall between bones: any pixel of the box will do)
                    for y = r.y, r.y + r.h - 1 do
                        for x = r.x, r.x + r.w - 1 do
                            if fig:hitTestAt(x, y) == r.name then hit = true; break end
                        end
                        if hit then break end
                    end
                end
                check("FIGURE " .. say .. ": a point in " .. r.name .. "'s box hit-tests back to it", hit,
                    r.x .. "," .. r.y .. " " .. r.w .. "x" .. r.h)
            end
        end
    end
end

-- ===========================================================================
-- LAUNDRY
-- ===========================================================================
local function plate(w, h) return { w = w, h = h } end
-- (the narrow faces as redrawn to fit the half card's 138 body at 1x: 130 x 190; Narrow washer, the director, Nov 22 2026)
ZeD.PhysPx = { plates = { washer = plate(233, 214), washer_n = plate(130, 190), dryer = plate(233, 250),
                          dryer_n = plate(130, 190), washer_dryer = plate(233, 250), washer_dryer_n = plate(130, 190) },
               narrow = { washer = "washer_n", dryer = "dryer_n", washer_dryer = "washer_dryer_n" } }
ZeD.ObjectCards = { ui = {}, call = noop, register = noop, spriteIcon = noop, faceZone = noop }
ZeD.Plate = { centre = function(aw, w, k) return math.floor((aw - w * k) / 2) end }
ZeD.ObjectCardPlain = { on = function() return false end }
-- (the card defines its door's walk-then-open action at load, as ObjectCards.lua does: QA LA4, Nov 26 2026)
ISBaseTimedAction = ISBaseTimedAction or { derive = function(self, name) return { Type = name } end }
ok, err = loadFile(CLIENT .. "ZeD_PixelParts.lua")
check("LAUNDRY ZeD_PixelParts.lua loads", ok, err)
ok, err = loadFile(CLIENT .. "ObjectCardLaundry.lua")
check("LAUNDRY ObjectCardLaundry.lua loads", ok, err)
local LD = ZeD.ObjectCardLaundry
check("LAUNDRY the room is reachable (LD._drawRoom)", LD and type(LD._drawRoom) == "function")
if ok and LD and LD._drawRoom then
    -- a card that writes down every rect it is asked to draw
    local function card(W, H, viewY, viewH)
        local c = { W = W, H = H, _viewY = viewY, _viewH = viewH, list = {} }
        function c:getWidth() return self.W end
        function c:getHeight() return self.H end
        function c:drawRect(x, y, w, h) self.list[#self.list + 1] = { x = x, y = y, w = w, h = h } end
        return c
    end
    -- the cards QA measured: the full card (840 x 650 at 4K, 360 x 278 on the Deck), a 336 body, the half card
    local CARDS = {
        { "full card at 4K", 840, 650, 18, 804, 2 },
        { "full card on the Deck", 360, 278, 8, 333, 1 },
        { "336 body", 279, 278, 8, 252, 1 },
        { "half card", 165, 278, 8, 138, 1 },
    }
    for _, face in ipairs({ "washer", "dryer", "washer_dryer" }) do
        for _, cd in ipairs(CARDS) do
            local name, W, H, bx, bw, k = cd[1], cd[2], cd[3], cd[4], cd[5], cd[6]
            local fid = face
            local des = ZeD.PhysPx.plates[fid]
            if des.w * k > bw then fid = face .. "_n"; des = ZeD.PhysPx.plates[fid] end
            for _, scroll in ipairs({ 0, 40 }) do
                local viewY, viewH = 26 * k, H - 40 * k
                local c = card(W, H, viewY, viewH)
                local y = viewY + 8 * k - scroll * k    -- (the face's top, as ObjectCards.lua hands it to the body)
                local px0 = bx + math.floor((bw - des.w * k) / 2)
                LD._drawRoom(c, bx, y, bw, px0, des, k, fid)
                local out, first = 0, nil
                for _, d in ipairs(c.list) do
                    local bad = d.x < bx - 0.01 or d.x + d.w > bx + bw + 0.01 or d.x < 0 or d.x + d.w > W
                        or d.y < viewY - 0.01 or d.y + d.h > viewY + viewH + 0.01 or d.y < 0 or d.y + d.h > H
                        or d.w <= 0 or d.h <= 0
                    if bad then
                        out = out + 1
                        first = first or (d.x .. "," .. d.y .. " " .. d.w .. "x" .. d.h)
                    end
                end
                local say = "LAUNDRY " .. fid .. " on the " .. name .. " scrolled " .. scroll
                -- (a face as wide as the body or wider leaves no room either side: nothing to draw there is right)
                if des.w * k < bw then check(say .. ": the room draws", #c.list > 0, #c.list) end
                check(say .. ": no backdrop draw outside the card's face area", out == 0,
                    out .. " of " .. #c.list .. " outside, first " .. tostring(first))
            end
        end
    end
end

-- the real narrow faces (PhysPx.lua, not the stand-in above) fit the half card's 138-unit body at 1x, the card's
-- smallest zoom, so nothing overhangs it (Narrow washer, the director, Nov 22 2026)
do
    local mock = ZeD.PhysPx
    local okP, errP = loadFile(CLIENT .. "PhysPx.lua")
    check("LAUNDRY PhysPx.lua loads", okP, errP)
    local X = ZeD.PhysPx
    ZeD.PhysPx = mock
    if okP and X and X.plates then
        for _, fid in ipairs({ "washer_n", "dryer_n", "washer_dryer_n" }) do
            local des = X.plates[fid]
            check("LAUNDRY " .. fid .. " fits the half card's 138 body at 1x", des ~= nil and des.w <= 138,
                des and (des.w .. " x " .. des.h) or "missing")
            for _, h in ipairs((des and des.hits) or {}) do
                check("LAUNDRY " .. fid .. " control " .. h.id .. " lies on the face", h.x >= 0 and h.y >= 0
                    and h.x + h.w <= des.w and h.y + h.h <= des.h, h.x .. "," .. h.y .. " " .. h.w .. "x" .. h.h)
            end
        end
    end
end

-- the full card at 4K (840 x 650, UI scale 1.75) with the real faces: the face picked and its whole zoom leave the
-- face, its gaps and the readings under it inside the view's height, so nothing it draws (the face's pictures, the
-- room either side) lies outside the card. (QA laundry 4K, Nov 22 2026)
do
    local mock, mockPx = ZeD.PhysPx, ZeD.T.px
    ZeD.PhysPx = nil
    local okP = loadFile(CLIENT .. "PhysPx.lua")
    local X = ZeD.PhysPx
    ZeD.PhysPx = X
    local SCALE = 1.75
    ZeD.T.px = function(n) return n * SCALE end
    local P = ZeD.PixelParts or ZeD.Px
    check("LAUNDRY 4K: the real PhysPx loads", okP and X and X.widths ~= nil)
    if okP and X and X.widths and LD and LD._fitFace and LD._drawRoom then
        local W, H = 840, 650
        local viewY, viewH = 26 * 2, H - 40 * 2
        local bx, bw = 18, 804
        for _, face in ipairs({ "washer", "dryer", "washer_dryer" }) do
            local t = { pid = face, d = { dryerOnly = (face == "dryer") } }
            local c = { W = W, H = H, _viewY = viewY, _viewH = viewH, list = {} }
            function c:getWidth() return self.W end
            function c:getHeight() return self.H end
            function c:drawRect(x, y, w, h) self.list[#self.list + 1] = { x = x, y = y, w = w, h = h } end
            local des, fid, k = LD._fitFace(c, t, bw, SCALE)
            local say = "LAUNDRY 4K full card " .. face
            check(say .. ": a face and a whole zoom", des ~= nil and k == math.floor(k) and k >= 1, tostring(k))
            if des then
                local top = viewY + 8 * SCALE
                local rows = (face == "dryer") and 1 or 2
                local bottom = top + des.h * k + 6 * SCALE + rows * 20 * SCALE + 18 * SCALE
                check(say .. " (" .. tostring(fid) .. " at " .. k .. "x): the face and its readings end inside the view",
                    bottom <= viewY + viewH + 0.01, bottom .. " > " .. (viewY + viewH))
                check(say .. ": the face lies inside the card's width", des.w * k <= bw, des.w * k)
                local px0 = bx + math.floor((bw - des.w * k) / 2)
                LD._drawRoom(c, bx, top, bw, px0, des, k, fid)
                local out = 0
                for _, d in ipairs(c.list) do
                    if d.x < 0 or d.x + d.w > W or d.y < viewY - 0.01 or d.y + d.h > viewY + viewH + 0.01 then out = out + 1 end
                end
                check(say .. ": no room draw outside the card", out == 0, out)
                print("  " .. say .. " picks " .. tostring(fid) .. " at " .. k .. "x")
            end
        end
    end
    ZeD.PhysPx, ZeD.T.px = mock, mockPx
end

-- the same cards at 1x (1080p and 1280x800, zoom 1): a card 278 tall, the full width (480) and 336, the view from
-- y 26 to the card's bottom and to a status band's top (40 short). QA saw washer.png at 59,34 230x262 run 18 px past
-- the card's bottom. Pixel art never draws at a fractional zoom: the zoom is whole and at least 1; the big face where
-- it and its rows fit the view, else the narrow face (_n) where it fits, else the narrow face at 1x, clipped by the
-- card's stencil. Centred either way. (QA laundry 1x, Nov 22 2026)
do
    local mock, mockPx = ZeD.PhysPx, ZeD.T.px
    ZeD.PhysPx = nil
    local okP = loadFile(CLIENT .. "PhysPx.lua")
    local X = ZeD.PhysPx
    ZeD.PhysPx = X
    local SCALE = 1
    ZeD.T.px = function(n) return n * SCALE end
    local savedScale = ZeD.Scale
    ZeD.Scale = { root = function() return SCALE end, artZoom = function() return 1 end }
    check("LAUNDRY 1x: the real PhysPx loads", okP and X and X.widths ~= nil)
    if okP and X and X.widths and LD and LD._fitFace then
        local H, viewY = 278, 26
        for _, W in ipairs({ 480, 336 }) do
            for _, viewH in ipairs({ H - viewY, H - viewY - 40 }) do
                local bw = W - 20
                for _, face in ipairs({ "washer", "dryer", "washer_dryer" }) do
                    local t = { pid = face, d = { dryerOnly = (face == "dryer") } }
                    local c = { _viewY = viewY, _viewH = viewH }
                    local des, fid, k = LD._fitFace(c, t, bw, SCALE)
                    local say = "LAUNDRY 1x " .. W .. " card, view " .. viewH .. ", " .. face
                    check(say .. ": a face and a whole zoom of at least 1", des ~= nil and k and k >= 1 and k == math.floor(k), tostring(k))
                    if des then
                        local rows = (face == "dryer") and 1 or 2
                        local extra = 8 + 6 + rows * 20 + 18
                        local fitsH = des.h * k + extra <= viewH
                        local narrow = (fid == X.narrow[face])
                        local kind = narrow and "narrow" or "big"
                        check(say .. ": the face is the big one or the narrow one", narrow or (fid and fid:find("^" .. face) ~= nil
                            and not fid:find("_n$")), tostring(fid))
                        -- it fits, or it is the narrow face at 1x clipped by the stencil (case 3)
                        check(say .. " (" .. tostring(fid) .. " at " .. k .. "x): the face and its rows fit the view, or it is the clipped narrow case",
                            fitsH or (narrow and k == 1), (des.h * k + extra) .. " > " .. viewH)
                        check(say .. ": the face lies inside the card's width", des.w * k <= bw, des.w * k)
                        -- the narrow face only where no big face fits at 1x
                        if narrow then
                            local bigFits = false
                            for _, id in pairs(X.widths[face]) do
                                local bd = X.plates[id]
                                if bd and bd.w <= bw and bd.h + extra <= viewH then bigFits = true end
                            end
                            check(say .. ": narrow only where no big face fits", not bigFits)
                        end
                        -- centred: the same room either side, within the pixel PL.centre's floor gives the right
                        local px0 = math.floor((bw - des.w * k) / 2)
                        local right = bw - (px0 + des.w * k)
                        check(say .. ": the face is centred", right - px0 >= 0 and right - px0 < 2, px0 .. " / " .. right)
                        print("  " .. say .. " picks " .. tostring(fid) .. " (" .. kind .. ") at " .. k .. "x, "
                            .. (des.w * k) .. " x " .. (des.h * k) .. (fitsH and ", fits" or ", clipped by the stencil"))
                    end
                end
            end
        end
    end
    ZeD.PhysPx, ZeD.T.px, ZeD.Scale = mock, mockPx, savedScale
end

print("gc_qa_cleanup_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
