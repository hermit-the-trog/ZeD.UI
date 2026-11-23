-- ZeDUI/tools/qa/gd_ads.lua  (Nov 22 2026, QA; tag gd_ads): the F1 survival guide book's ad pages in game after branch
-- inkads (3a8d8cd41, the director: only black ink): all 66 ad pictures re-rendered in the book's one ink, and the Lua
-- house ad's price in the ink in a ruled box (it was paper-colored words on an ink block). Manifest gd_ads.txt, on the
-- 1.0 gallery's staging as gc_cleanup.txt (no story stage). 4K full screen.
-- The book opened as F1 opens it (ZeD.Guide.toggle; when Lite shows the Simple window on F1 instead, the book itself
-- through ZeD.GuideBook.open on its contents, noted). Its own page model after B.paginate (bk.pages, the deal made by
-- B.dealAds): a whole page's full-page ad (p.ad a name; "house" or nil the publisher's house ad, ZeD_GuideBook:drawAdPage;
-- false, the smaller ads over the whole page), the fillers on flow pages (items k "filler", it.ads) and at the foot of
-- rules pages (p.filler.ads; a spoiler table's foot shows once its numbers are shown, so they are shown first, as a
-- reader's click would: ZeD.Guide.spoil). Every spread with an ad is turned to (bk.spread) and checked; the ad ids on
-- each page are printed ("ADS p<printed number>").
-- Pictures to Zomboid/Screenshots/gd_ads_<printed page number>.png (the folio the reader sees; the first ad page of the
-- spread), at most 24: every spread with a full-page ad or the house ad, then the spreads that show the most ads not yet
-- pictured, until 24 or every dealt ad is in a picture.
-- Checks (Q.check, "ZEDQA gd_ads PASS|FAIL ..."):
--   opened      the book opens and its pages carry ads; the house ad is dealt exactly once
--   one ink     on each ad page, in its ads' room (the whole page for a full-page slot, the filler's band elsewhere),
--               the book panel's draws for one frame (drawRect, drawRectBorder, drawText, drawTextZoomed,
--               drawTextureScaled; the text layer held off that one frame so the words come through drawTextZoomed with
--               their color): no text in a paper color (the paper, the page as drawn, or near white: reversed type),
--               and no filled rect in a paper color drawn over an ink rect drawn before it. The thumb index's chapter
--               number (paper on its dark tab, prerender's thumb block) is not an ad and is left out
--   drawn       the ad pictures drawn on each page are the ones the page model deals it (by texture name); the house
--               ad's page draws its words and no picture
-- What it puts back: the book closed (open again on its page if it was open), the page (spread) it was on, the spoiler
-- table as found, the draw wrappers and the text layer, the windows' pair as found, game speed. Settings: none changed.
-- grep "ZEDQA gd_ads".
local S = HFR and HFR.init and HFR.init("gd_ads", true)
if not S then return end
local Q = S.Q
S.DIR = "gd_ads_"
Q.maxMs = 900000
S.MAX_PICS = 24
S.pic, S.spreads = {}, {}
S.REC_FNS = { "drawRect", "drawRectBorder", "drawText", "drawTextZoomed", "drawTextureScaled" }
-- the book's colors (ZeD_SurvivalGuideBook.lua: INK, PAPER; PAGE the paper at the paper tone)
S.INK = { r = 0.137, g = 0.165, b = 0.227 }
S.PAPER = { r = 0.961, g = 0.925, b = 0.824 }
S.AD_SIZE = { full = true, half = true, third = true, quarter = true }

-- ===================================================================== the checks (rt_kit.lua's way)
Q.pass, Q.fail, Q.skips = 0, 0, 0
function Q.check(ok, what, detail)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    Q.say((ok and "PASS " or "FAIL ") .. tostring(what) .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
S.step0, S.wait0 = Q.step, Q.waitFor
function S.guard(fn)
    return function(res)
        local ok, e = pcall(fn, res)
        if not ok then Q.check(false, "a step ran without an error", tostring(e)) end
    end
end
function Q.step(n, fn) S.step0(n, S.guard(fn)) end
function Q.waitFor(n, max, cond, fn) S.wait0(n, max, cond, S.guard(fn)) end
function S.verdict()
    Q.step(2, function()
        Q.say(string.format("checks: %d pass, %d fail, %d skipped", Q.pass, Q.fail, Q.skips))
        Q.say(Q.fail > 0 and ("VERDICT FAIL " .. Q.fail) or ("VERDICT PASS " .. Q.pass))
    end)
end

S.B = ZeD and ZeD.GuideBook
S.W = ZeD and ZeD.Guide
if not (S.B and S.B.open and S.B.close and S.B.isOpen and S.B.books and S.B.layerBegin and S.W and S.W.toggle
        and S.W.spoilKey and ZeD.GuideAds and ZeD_GuideBook) then
    Q.check(false, "ZeD's survival guide book is loaded")
    S.verdict()
    Q.start()
    return
end

-- ===================================================================== the error watch
S.errN, S.errAt = nil, -100000
function S.errWatch()
    local n = nil
    if getLuaDebuggerErrorCount then n = getLuaDebuggerErrorCount() end
    if n ~= nil and n ~= S.errN then
        if S.errN ~= nil then S.errAt = getTimestampMs() end
        S.errN = n
    end
end
function S.quiet() S.errWatch(); return getTimestampMs() - S.errAt > 3600 end
Events.OnPreUIDraw.Add(S.errWatch)
function S.n(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    return tostring(math.floor(x * 10 + 0.5) / 10)
end
function S.bk() return S.B.books[S.pn] end
function S.open() return S.B.isOpen(S.pn) == true end

-- ===================================================================== the draw recorder (one frame of the book's draws)
function S.texName(tex)
    local nm = nil
    if tex == nil then return nil end
    if type(tex) == "string" then return tex end
    pcall(function() nm = tex:getName() end)
    return nm
end
function S.recAdd(R, fn, a1, a2, a3, a4, a5, a6, a7, a8)
    local d = { fn = fn, k = #R.list + 1 }
    if fn == "drawRect" or fn == "drawRectBorder" then
        d.x, d.y, d.w, d.h = a1, a2, a3, a4
        d.a, d.r, d.g, d.b = a5, a6, a7, a8
    elseif fn == "drawText" then
        d.str, d.x, d.y, d.w, d.h, d.text = tostring(a1), a2, a3, 0, 0, true
        d.r, d.g, d.b, d.a = a4, a5, a6, a7
    elseif fn == "drawTextZoomed" then
        d.str, d.x, d.y, d.w, d.h, d.text = tostring(a1), a2, a3, 0, 0, true
        d.r, d.g, d.b, d.a = a5, a6, a7, a8
    else
        d.name = S.texName(a1)
        d.x, d.y, d.w, d.h = a2, a3, a4, a5
    end
    d.x, d.y, d.w, d.h = tonumber(d.x) or 0, tonumber(d.y) or 0, tonumber(d.w) or 0, tonumber(d.h) or 0
    d.r, d.g, d.b, d.a = tonumber(d.r), tonumber(d.g), tonumber(d.b), tonumber(d.a)
    R.list[#R.list + 1] = d
end
function S.recFn(R, fn, orig)
    return function(self, a1, a2, a3, a4, a5, a6, a7, a8, ...)
        pcall(S.recAdd, R, fn, a1, a2, a3, a4, a5, a6, a7, a8)
        return orig(self, a1, a2, a3, a4, a5, a6, a7, a8, ...)
    end
end
function S.recOn(panel)
    S.recOff()
    if not panel then return false end
    local R = { panel = panel, own = {}, list = {} }
    for _, fn in ipairs(S.REC_FNS) do
        R.own[fn] = rawget(panel, fn) or false
        local orig = panel[fn]
        if orig then panel[fn] = S.recFn(R, fn, orig) end
    end
    S.R = R
    return true
end
function S.recOff()
    local R = S.R
    if not R then return nil end
    for _, fn in ipairs(S.REC_FNS) do
        local o = R.own[fn]
        if o then R.panel[fn] = o else R.panel[fn] = nil end
    end
    S.R = nil
    return R
end
-- the text layer held off for the recorded frame: the book's words come through the panel's drawTextZoomed (its
-- fallback), so their color is seen; the next frame the layer draws them again
function S.layerOff(on)
    local B = S.B
    if on then
        if S.lb0 then return end
        S.lb0 = B.layerBegin
        B.layerBegin = function(panel) return S.lb0(nil) end
        return
    end
    if S.lb0 then B.layerBegin = S.lb0; S.lb0 = nil end
end

-- ===================================================================== the page model: which pages carry ads
function S.addNames(ids, blocks)
    for _, b in ipairs(blocks or {}) do
        if b.names then for _, nm in ipairs(b.names) do ids[#ids + 1] = tostring(nm) end end
    end
end
-- a page's ads: { ids, regs (bands from the page's top, or whole), kind } or nil when it carries none
function S.pageAds(p)
    local ids, regs, kind = {}, {}, nil
    if p.kind == "ad" then
        if p.ad == nil or p.ad == "house" then ids[1] = "house"; kind = "house ad"
        elseif p.ad then ids[1] = tostring(p.ad); kind = "full-page ad"
        else
            kind = "whole page of smaller ads"
            if p.filler then S.addNames(ids, p.filler.ads) end
        end
        regs[1] = { whole = true }
        return { ids = ids, regs = regs, kind = kind }
    end
    if p.kind == "flow" then
        for _, it in ipairs(p.items or {}) do
            if it.k == "filler" then
                S.addNames(ids, it.ads)
                regs[#regs + 1] = { y = tonumber(it.y) or 0, y1 = tonumber(it.y1) or 0 }
            end
        end
        kind = "filler"
    elseif p.kind == "rules" and p.filler then
        S.addNames(ids, p.filler.ads)
        regs[1] = { y = tonumber(p.filler.y) or 0, y1 = tonumber(p.filler.y1) or 0 }
        kind = "filler at a rules page's foot" .. ((p.rules and p.rules.spoiler) and " (a spoiler table)" or "")
    end
    if #ids == 0 then return nil end
    return { ids = ids, regs = regs, kind = kind }
end
function S.buildSpreads(bk)
    S.spreads = {}
    local pages = bk.pages or {}
    local bySpread = {}
    local house, dealt = 0, 0
    for i, p in ipairs(pages) do
        local A = S.pageAds(p)
        if A then
            local s = math.floor((i + 1) / 2)
            local sp = bySpread[s]
            if not sp then
                sp = { s = s, pages = {} }
                bySpread[s] = sp
                S.spreads[#S.spreads + 1] = sp
            end
            A.i, A.no, A.p = i, i + 1, p
            A.left = (i % 2 == 1)
            sp.pages[#sp.pages + 1] = A
            for _, id in ipairs(A.ids) do
                if id == "house" then house = house + 1 else dealt = dealt + 1 end
            end
            if A.kind == "house ad" or A.kind == "full-page ad" then sp.full = true end
        end
    end
    return house, dealt, #pages
end
-- the pictures: every spread with a full-page ad or the house ad, then the most ads not yet pictured, at most 24
function S.pickShots()
    local seen, n = {}, 0
    local function newCount(sp)
        local c = 0
        for _, A in ipairs(sp.pages) do for _, id in ipairs(A.ids) do if not seen[id] then c = c + 1 end end end
        return c
    end
    local function take(sp)
        sp.pick = true
        n = n + 1
        for _, A in ipairs(sp.pages) do for _, id in ipairs(A.ids) do seen[id] = true end end
    end
    for _, sp in ipairs(S.spreads) do if sp.full and n < S.MAX_PICS then take(sp) end end
    while n < S.MAX_PICS do
        local best, bestN = nil, 0
        for _, sp in ipairs(S.spreads) do
            if not sp.pick then
                local c = newCount(sp)
                if c > bestN then best, bestN = sp, c end
            end
        end
        if not best then break end
        take(best)
    end
    local ids = 0
    for _ in pairs(seen) do ids = ids + 1 end
    return n, ids
end

-- ===================================================================== one spread: its draws checked
function S.near(c, ref, tol)
    return c.r ~= nil and math.abs(c.r - ref.r) <= tol and math.abs(c.g - ref.g) <= tol and math.abs(c.b - ref.b) <= tol
end
function S.lum(c) return 0.299 * (c.r or 0) + 0.587 * (c.g or 0) + 0.114 * (c.b or 0) end
function S.paperish(d)
    if d.r == nil then return false end
    return S.near(d, S.PAPER, 0.08) or (S.PAGE and S.near(d, S.PAGE, 0.08)) or S.lum(d) >= 0.75
end
function S.inkish(d)
    if d.r == nil then return false end
    return (d.a == nil or d.a >= 0.5) and (S.near(d, S.INK, 0.08) or S.lum(d) <= 0.3)
end
function S.inRect(r, x, y, pad)
    pad = pad or 0
    return r ~= nil and x >= r.x - pad and x < r.x + r.w + pad and y >= r.y - pad and y < r.y + r.h + pad
end
function S.overlap(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
function S.thumbHit(bk, d, u)
    for _, r in ipairs(bk._thumbs or {}) do
        if S.inRect(r, d.x, d.y, 4 * u) then return true end
    end
    return false
end
function S.adNameOf(nm)
    if not nm then return nil end
    -- (by its base name, whatever path form the engine keeps: an ad's file starts with its size)
    local s = string.lower(tostring(nm))
    local base = s:match("([%w_]+)%.png$") or s:match("([%w_]+)$")
    if not base then return nil end
    local size = base:match("^(%a+)_")
    if size and S.AD_SIZE[size] then return base end
    return nil
end
function S.idsSay(A) return table.concat(A.ids, ", ") end
function S.checkPage(bk, R, A)
    local g = bk._g
    local u = (g and g.u) or 1
    local P = A.left and g.left or g.right
    -- the ads' room: the whole page, or the filler's bands
    local rooms = {}
    for _, rg in ipairs(A.regs) do
        if rg.whole then rooms[#rooms + 1] = { x = P.x, y = P.y, w = P.w, h = P.h }
        else rooms[#rooms + 1] = { x = P.x, y = P.y + rg.y, w = P.w, h = math.max(0, rg.y1 - rg.y) } end
    end
    local function inRoom(x, y)
        for _, r in ipairs(rooms) do if S.inRect(r, x, y, 0.5) then return true end end
        return false
    end
    local rev, revSay, texts, inks, drawn, thumbs = 0, nil, 0, {}, {}, 0
    for _, d in ipairs(R.list) do
        local cx, cy = d.x + d.w / 2, d.y + d.h / 2
        if d.text then
            if inRoom(d.x, d.y) then
                if S.thumbHit(bk, d, u) then thumbs = thumbs + 1
                else
                    texts = texts + 1
                    if S.paperish(d) then
                        rev = rev + 1
                        revSay = revSay or ("reversed type \"" .. string.sub(d.str or "", 1, 40) .. "\" at " .. S.n(d.x) .. "," .. S.n(d.y)
                            .. " in " .. S.n(d.r) .. "/" .. S.n(d.g) .. "/" .. S.n(d.b))
                    end
                end
            end
        elseif d.fn == "drawRect" then
            -- (a rect wholly inside one room: the desk's dim and the sheet under both pages are not the ads')
            local inside = false
            for _, r in ipairs(rooms) do
                if d.x >= r.x - 0.5 and d.y >= r.y - 0.5 and d.x + d.w <= r.x + r.w + 0.5 and d.y + d.h <= r.y + r.h + 0.5 then inside = true end
            end
            if inside and d.w > 0 and d.h > 0 then
                if S.inkish(d) then inks[#inks + 1] = d
                elseif S.paperish(d) and (d.a == nil or d.a >= 0.5) then
                    for _, k in ipairs(inks) do
                        if S.overlap(d, k) then
                            rev = rev + 1
                            revSay = revSay or ("a paper-colored rect " .. S.n(d.x) .. "," .. S.n(d.y) .. " " .. S.n(d.w) .. " x " .. S.n(d.h)
                                .. " over an ink rect at " .. S.n(k.x) .. "," .. S.n(k.y))
                            break
                        end
                    end
                end
            end
        elseif d.fn == "drawTextureScaled" then
            local nm = S.adNameOf(d.name)
            if nm and S.inRect(P, cx, cy, 0.5) then drawn[#drawn + 1] = nm end
        end
    end
    local head = "p" .. A.no .. " (" .. A.kind .. ": " .. S.idsSay(A) .. ")"
    Q.check(rev == 0, head .. ": one ink, no reversed type and no paper-colored shape on ink in its ads",
        texts .. " text runs and " .. #inks .. " ink rects in the ads' room (" .. #rooms .. " band(s))" .. (thumbs > 0 and (", "
        .. thumbs .. " thumb-index number(s) left out") or "") .. (revSay and ("; first: " .. revSay) or ""))
    -- the ad pictures drawn there are the ones dealt
    local want, missing, extra = {}, {}, {}
    for _, id in ipairs(A.ids) do if id ~= "house" then want[#want + 1] = string.lower(id) end end
    for _, id in ipairs(want) do
        local found = false
        for _, nm in ipairs(drawn) do if nm == id then found = true end end
        if not found then missing[#missing + 1] = id end
    end
    for _, nm in ipairs(drawn) do
        local found = false
        for _, id in ipairs(want) do if nm == id then found = true end end
        if not found then extra[#extra + 1] = nm end
    end
    if A.kind == "house ad" then
        Q.check(#drawn == 0 and texts > 0, head .. ": the house ad draws its own words, no picture",
            texts .. " text runs; ad pictures drawn: " .. ((#drawn > 0) and table.concat(drawn, ", ") or "none"))
    else
        Q.check(#missing == 0 and #extra == 0, head .. ": the ad pictures the page model deals are the ones drawn",
            "drawn: " .. ((#drawn > 0) and table.concat(drawn, ", ") or "none") .. ((#missing > 0) and ("; not drawn: " .. table.concat(missing, ", ")) or "")
            .. ((#extra > 0) and ("; drawn but not dealt here: " .. table.concat(extra, ", ")) or ""))
    end
end
-- a spoiler table's foot draws its ads only once its numbers are shown: shown for the spreads with one
function S.reveal(sp)
    for _, A in ipairs(sp.pages) do
        local p = A.p
        if p.kind == "rules" and p.rules and p.rules.spoiler and p.topic then
            local key = nil
            pcall(function() key = S.W.spoilKey(p.topic, p.ri or 1) end)
            if key and S.W.spoil and not S.W.spoil[key] then
                S.W.spoil[key] = true
                S.revealed = (S.revealed or 0) + 1
                Q.say("note: p" .. A.no .. "'s spoiler table shown (its foot's ads draw only then)")
            end
        end
    end
end

-- ===================================================================== the walk through the spreads
function S.walkTick()
    local V = S.V
    if not V then return true end
    local sp = S.spreads[V.k]
    if not sp then return true end
    if V.wait > 0 then V.wait = V.wait - 1; return false end
    local bk = S.bk()
    if not (bk and S.open()) then
        Q.check(false, "the book stays open through the walk", "closed at spread " .. tostring(sp.s))
        V.k = #S.spreads + 1
        return true
    end
    if V.phase == 0 then
        S.reveal(sp)
        bk.spread = sp.s
        for _, A in ipairs(sp.pages) do
            Q.say("ADS p" .. A.no .. " (page " .. A.i .. ", spread " .. sp.s .. ", " .. (A.left and "left" or "right") .. "): "
                .. A.kind .. ": " .. S.idsSay(A))
        end
        V.phase, V.wait = 1, 4
        return false
    end
    if V.phase == 1 then
        if bk.spread ~= sp.s then
            Q.check(false, "spread " .. sp.s .. " opens", "the book is on spread " .. tostring(bk.spread))
            V.k, V.phase = V.k + 1, 0
            return false
        end
        S.layerOff(true)
        S.recOn(bk)
        V.phase = 2
        return false
    end
    if V.phase == 2 then
        local R = S.recOff()
        S.layerOff(false)
        if R and #R.list > 0 then
            for _, A in ipairs(sp.pages) do
                local ok, e = pcall(S.checkPage, bk, R, A)
                if not ok then Q.check(false, "p" .. A.no .. ": its draws were read", tostring(e)) end
            end
        else
            Q.check(false, "spread " .. sp.s .. ": the book's draws recorded", "none")
        end
        if sp.pick then V.phase, V.wait, V.q = 3, 20, 0
        else V.k, V.phase, V.wait = V.k + 1, 0, 0 end
        return false
    end
    -- the picture: the text layer back, the ad textures loaded, no fresh Lua error
    if not S.quiet() and V.q < 240 then V.q = V.q + 1; return false end
    local first = sp.pages[1]
    local name = tostring(first.no)
    if not S.quiet() then Q.say("NOTE gd_ads_" .. name .. ": a Lua error came " .. tostring(getTimestampMs() - S.errAt) .. " ms before the picture") end
    S.shot(name)
    S.pic[#S.pic + 1] = "gd_ads_" .. name
    local say = {}
    for _, A in ipairs(sp.pages) do say[#say + 1] = "p" .. A.no .. " " .. A.kind .. ": " .. S.idsSay(A) end
    Q.say("SHOT gd_ads_" .. name .. " | spread " .. sp.s .. ": " .. table.concat(say, "; "))
    V.k, V.phase, V.wait = V.k + 1, 0, 2
    return false
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    S.was.book = S.open()
    local bk = S.bk()
    S.was.hadBook = bk ~= nil
    S.was.spread = bk and bk.spread or nil
    S.was.spoil = S.W.spoil
    pcall(function() S.PAGE = ZeD.paperTone(S.PAPER) end)
    -- (the Simple guide window open: closed, F1 would only close it)
    local win = S.W.get and S.W.get(S.pn) or nil
    if win and win:isReallyVisible() then pcall(function() win:close() end); Q.say("note: the Simple guide window was open: closed") end
    if S.was.pairOpen then S.closePair() end
    Q.say("found: the book " .. (S.was.book and "open" or "closed") .. ", on spread " .. tostring(S.was.spread) .. ", screen "
        .. S.core:getScreenWidth() .. " x " .. S.core:getScreenHeight() .. ", UI scale " .. tostring(ZeD.T and ZeD.T.scale)
        .. ", F1 opens the book " .. tostring(S.W.useBook and S.W.useBook()))
end)
Q.step(10, function()
    if S.open() then return end
    if S.W.useBook and S.W.useBook() then
        pcall(S.W.toggle, S.pn)
        Q.say("F1's path: ZeD.Guide.toggle")
    else
        Q.say("NOTE F1 opens the Simple window here (Lite, or a language the book does not print): the book opened itself, on its contents")
        pcall(S.B.open, S.pn, nil, true)
    end
end)
Q.waitFor(5, 600, function()
    local bk = S.bk()
    return S.open() and bk ~= nil and bk.pages ~= nil and bk._g ~= nil
end, function(ok)
    local bk = S.bk()
    if not ok or not bk then Q.check(false, "the guide book opens (staging)", "open " .. tostring(S.open())); return end
    local house, dealt, np = S.buildSpreads(bk)
    local rep = nil
    pcall(function() rep = S.B.adReport(bk) end)
    Q.say(tostring(rep))
    Q.check(#S.spreads > 0, "the book opens and its pages carry ads", np .. " pages, " .. #S.spreads .. " spreads with ads, "
        .. dealt .. " ad pictures dealt (of " .. (#ZeD.GuideAds.full + #ZeD.GuideAds.half + #ZeD.GuideAds.third + #ZeD.GuideAds.quarter) .. ")")
    Q.check(house == 1, "the house ad is in the book exactly once", house .. " time(s)")
    local n, ids = S.pickShots()
    Q.say("pictures planned: " .. n .. " spreads (at most " .. S.MAX_PICS .. "), showing " .. ids .. " different ads")
    S.V = { k = 1, phase = 0, wait = 2 }
end)
Q.waitFor(1, 30000, S.walkTick, function(ok)
    if not ok then Q.check(false, "the walk through the ad spreads finished", "ran out of frames at spread " .. tostring(S.V and S.V.k)) end
    S.V = nil
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.recOff()
    S.layerOff(false)
    S.V = nil
    S.W.spoil = S.was.spoil or {}
    local bk = S.bk()
    if bk and S.was.hadBook and S.was.spread then bk.spread = S.was.spread end
    if not S.was.book and S.open() then pcall(S.B.close, S.pn) end
end)
Q.step(20, function()
    if S.was.pairOpen then S.openPair() end
    S.back0()
end)
Q.step(20, function()
    pcall(function() Mouse.setCursorVisible(true) end)
    Events.OnPreUIDraw.Remove(S.errWatch)
    local bk = S.bk()
    Q.say("put back: the book " .. (S.open() and "open" or "closed") .. " (found " .. (S.was.book and "open" or "closed") .. "), on spread "
        .. tostring(bk and bk.spread) .. " (found " .. tostring(S.was.spread) .. "), spoiler table as found " .. tostring(S.W.spoil == S.was.spoil
        or S.was.spoil == nil) .. " (" .. tostring(S.revealed or 0) .. " shown in the run), wrappers left "
        .. tostring(S.lb0 ~= nil or S.R ~= nil) .. ", pair open " .. tostring(S.CWm.isOpen() and S.WWm.isOpen()) .. " (found "
        .. tostring(S.was.pairOpen) .. "), game speed " .. tostring(getGameSpeed()) .. "; pictures taken: "
        .. ((#S.pic > 0) and table.concat(S.pic, ", ") or "none"))
end)
S.verdict()
Q.start()
