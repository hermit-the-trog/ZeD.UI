-- ZeDUI/tools/qa/zedqa_pagelist_lib.lua  (Nov 2 2026, QA; punch list 52, the page list beside Find)
-- Shared checks for a window that draws ZeD_MMOptions.drawPages (the main menu's Sandbox step, Options, the
-- Sandbox window in game). Loaded by zedqa_menu_pagelist.lua and zedqa_sandbox_ig_pages.lua with
--   local PL = dofile-like require: ZEDQA_PL (this file sets the global table ZEDQA_PL).
-- Every check works on the window's own state and the hit boxes its last prerender registered:
--   box      w._pagesBox (window px) -> screen px; rows: the "<kind>:page:<i>" hits; the bar: "<kind>:pagestrack"
--   clicks   resolved as the menu's pointer does (the window's _hits, last first, first box under the point)
-- A step function returns true when done, or false and why; each step gets a few frames before the next, so the
-- window draws (and registers its hits) in between.
ZEDQA_PL = {}
local PL = ZEDQA_PL

function PL.new(tag, say, verdict, shot)
    local S = { tag = tag, say = say, verdict = verdict, shot = shot, D = {} }
    local function fl(v) return math.floor((tonumber(v) or 0) + 0.5) end
    S.fl = fl

    -- the page hits, in page order, and the bar's hit (screen px)
    function S.hits(w)
        local pre = tostring(w.kind) .. ":page:"
        local t, track, find = {}, nil, nil
        for _, h in ipairs(w._hits or {}) do
            if h.id and string.sub(h.id, 1, #pre) == pre then
                t[#t + 1] = { i = tonumber(string.sub(h.id, #pre + 1)), x = h.x, y = h.y, w = h.w, h = h.h, hit = h }
            elseif h.id == tostring(w.kind) .. ":pagestrack" then track = h
            elseif h.id == tostring(w.kind) .. ":find" then find = h end
        end
        table.sort(t, function(a, b) return (a.i or 0) < (b.i or 0) end)
        return t, track, find
    end
    function S.box(w)
        local b = w._pagesBox
        if not b then return nil end
        local ax, ay = w:getAbsoluteX(), w:getAbsoluteY()
        return { x = ax + b.x, y = ay + b.y, w = b.w, h = b.h, bot = ay + b.y + b.h }
    end
    function S.rowH() return ZeD.T.px(30) end
    function S.hitOf(w, i)
        for _, h in ipairs((S.hits(w))) do if h.i == i then return h end end
        return nil
    end
    -- the first hit under a point, last registered first (as ZeD_MainMenu.lua's hitAt)
    function S.hitAt(w, mx, my)
        local hs = w._hits or {}
        for k = #hs, 1, -1 do
            local h = hs[k]
            if mx >= h.x and mx < h.x + h.w and my >= h.y and my < h.y + h.h then return h end
        end
        return nil
    end
    -- the row of page i shown whole inside the box
    function S.whole(w, i)
        local B, h = S.box(w), S.hitOf(w, i)
        if not (B and h) then return false, "no row drawn for page " .. tostring(i) end
        local ok = h.y >= B.y - 0.5 and h.y + h.h <= B.bot + 0.5 and math.abs(h.h - S.rowH()) < 1
        return ok, "page " .. i .. " row " .. fl(h.y) .. "+" .. fl(h.h) .. " | box " .. fl(B.y) .. " to " .. fl(B.bot)
    end

    -- MEASURE: the box, the rows drawn, all inside it; the bar when the pages overflow
    function S.measure(w, label)
        local pages = w:pages()
        local hs, track = S.hits(w)
        local B = S.box(w)
        if not B then S.verdict(false, label .. ": the window has a page box (_pagesBox)"); return end
        local total = #pages * S.rowH()
        S.D.n, S.D.over = #pages, total > B.h + 0.5
        S.say(label .. ": " .. #pages .. " pages | box " .. fl(B.x) .. "," .. fl(B.y) .. " " .. fl(B.w) .. "x" .. fl(B.h)
            .. " | rows of " .. S.rowH() .. " px: " .. fl(total) .. " px of rows | rows drawn " .. #hs
            .. " | overflows " .. tostring(S.D.over) .. " | screen bottom " .. getCore():getScreenHeight())
        local out = {}
        for _, h in ipairs(hs) do
            if h.y < B.y - 0.5 or h.y + h.h > B.bot + 0.5 then out[#out + 1] = tostring(h.i) end
        end
        S.verdict(#out == 0, label .. ": every row drawn lies inside the page box (" .. #hs .. " drawn"
            .. (#out > 0 and ("; outside: " .. table.concat(out, ",")) or "") .. ")")
        S.verdict(B.bot <= getCore():getScreenHeight() + 0.5, label .. ": the page box ends on screen (" .. fl(B.bot) .. ")")
        if S.D.over then
            S.verdict(track ~= nil, label .. ": the pages overflow and a scroll bar is there")
            S.verdict(#hs < #pages, label .. ": not every page is drawn at once (" .. #hs .. " of " .. #pages .. ")")
        else
            S.say("NOTE " .. label .. ": the pages fit their box at this size; the scroll checks have nothing to scroll")
            S.verdict(track == nil, label .. ": no scroll bar when the pages fit")
        end
    end

    -- WHEEL: the mouse over the box, one notch a frame down to the end, then back up
    function S.wheelPrep(w)
        local B = S.box(w)
        if not B then return false, "no page box" end
        pcall(function() Mouse.setXY(math.floor(B.x + B.w / 2), math.floor(B.y + B.h / 2)) end)
        w.pageIdx = 1; w._pagesShown = nil; w.pagesScroll = 0
        S.D.notches, S.D.scroll0, S.D.up = 0, nil, 0
        return true
    end
    -- one notch over the box's middle. The game reads the real cursor every frame (Mouse.setXY does not hold while the
    -- desktop's pointer sits elsewhere), so for the call only, getMouseX / getMouseY answer the box's middle; the window's
    -- own onMouseWheel then runs as for a real notch. (A real wheel is checked by hand on the Deck run.)
    function S.wheelAt(w, del)
        local B = S.box(w)
        local gx, gy = getMouseX, getMouseY
        local mx, my = math.floor(B.x + B.w / 2), math.floor(B.y + B.h / 2)
        getMouseX = function() return mx end
        getMouseY = function() return my end
        local ok, r = pcall(function() return w:onMouseWheel(del) end)
        getMouseX, getMouseY = gx, gy
        return ok, r
    end
    -- one notch; returns true while there is more to do
    -- (each pass first looks at what the last draw shows, then turns a notch: the pass that stops turns nothing, so the
    -- check after it reads a drawn list, not one a notch ahead of the screen)
    function S.wheelDown(w)
        if S.D.notches >= 80 or S.whole(w, S.D.n) then return false end
        local before = w.pagesScroll or 0
        local ok, r = S.wheelAt(w, 1)
        if not ok then S.say("FAIL wheel: onMouseWheel threw " .. tostring(r)); return false end
        S.D.notches = S.D.notches + 1
        if S.D.notches == 1 then
            S.say("wheel: first notch over the box's middle (the real cursor " .. tostring(getMouseX()) .. "," .. tostring(getMouseY()) .. "): pagesScroll "
                .. fl(before) .. " -> " .. fl(w.pagesScroll) .. " | the settings list's scroll " .. tostring(w.scroll))
        end
        return true
    end
    function S.wheelEnd(w, label)
        local ok, why = S.whole(w, S.D.n)
        if S.D.over then
            S.verdict(ok, label .. ": the wheel over the page list reaches the last page (" .. S.D.notches .. " notches; " .. why .. ")")
        end
        S.D.scrollMax = w.pagesScroll
        S.say(label .. ": wheel end pagesScroll " .. fl(w.pagesScroll) .. " | the page shown " .. tostring(w.pageIdx) .. " (unchanged by the wheel: " .. tostring(w.pageIdx == 1) .. ")")
        S.verdict(w.pageIdx == 1, label .. ": the wheel scrolls without changing the picked page")
        return true
    end
    function S.wheelUp(w)
        if (S.D.up or 0) >= 80 or ((w.pagesScroll or 0) < 0.5 and S.whole(w, 1)) then return false end
        S.wheelAt(w, -1)
        S.D.up = (S.D.up or 0) + 1
        return true
    end
    function S.wheelTop(w, label)
        local ok, why = S.whole(w, 1)
        local hs = S.hits(w)
        S.say(label .. ": wheel up: " .. tostring(S.D.up) .. " notches | pagesScroll " .. fl(w.pagesScroll) .. " | rows drawn "
            .. #hs .. (hs[1] and (" from page " .. tostring(hs[1].i) .. " at " .. fl(hs[1].y)) or "") .. " | picked " .. tostring(w.pageIdx))
        S.verdict(ok and (w.pagesScroll or 0) < 0.5, label .. ": the wheel back up returns to the first page (" .. why .. ")")
        return true
    end

    -- BAR: a press on the bar's bottom end, then its top, then its middle (the drag function a press calls)
    function S.barTo(w, where)
        local _, track = S.hits(w)
        if not track then return false, "no scroll bar" end
        local y = (where == "bottom") and (track.y + track.h - 1) or ((where == "top") and track.y or (track.y + track.h / 2))
        track.drag(track.x + 1, y)
        S.D.barAt = where
        return true
    end
    function S.barCheck(w, label)
        local where = S.D.barAt
        if where == "bottom" then
            local ok, why = S.whole(w, S.D.n)
            S.verdict(ok, label .. ": the bar dragged to its end shows the last page (" .. why .. ")")
        elseif where == "top" then
            local ok, why = S.whole(w, 1)
            S.verdict(ok and (w.pagesScroll or 0) < 0.5, label .. ": the bar dragged to its top shows the first page (" .. why .. ")")
        else
            local B = S.box(w)
            local mx = #w:pages() * S.rowH() - B.h
            local f = (w.pagesScroll or 0) / math.max(1, mx)
            S.verdict(f > 0.25 and f < 0.75, label .. ": the bar dragged to its middle scrolls about halfway (" .. string.format("%.2f", f) .. " of the way)")
        end
        return true
    end

    -- BUMPERS: RB from the first page to the last, one a step, the picked row whole in the box each time
    function S.bumpPrep(w)
        w.pageIdx = 1; w._pagesShown = nil; w.pagesScroll = 0; w.focusId = nil
        S.D.rb, S.D.rbBad = 0, {}
        return true
    end
    function S.bumpStep(w)
        if S.D.rb > 0 then
            local ok, why = S.whole(w, w.pageIdx)
            if not ok then S.D.rbBad[#S.D.rbBad + 1] = why end
        end
        if S.D.rb >= S.D.n - 1 then return false end
        pcall(function() w:joyBumper(1) end)
        S.D.rb = S.D.rb + 1
        return true
    end
    function S.bumpEnd(w, label)
        S.verdict(w.pageIdx == S.D.n, label .. ": RB from the first page reaches the last (page " .. tostring(w.pageIdx) .. " of " .. S.D.n .. ")")
        S.verdict(#S.D.rbBad == 0, label .. ": the picked page stays whole in view at every RB (" .. S.D.rb .. " steps"
            .. (#S.D.rbBad > 0 and ("; out at " .. #S.D.rbBad .. ": " .. S.D.rbBad[1]) or "") .. ")")
        S.shot("_rblast")
        pcall(function() w:joyBumper(1) end)   -- RB on the last page wraps to the first
        return true
    end
    function S.wrapTop(w, label)
        local ok, why = S.whole(w, 1)
        S.verdict(w.pageIdx == 1 and ok, label .. ": RB on the last page wraps to the first, in view (" .. why .. ")")
        pcall(function() w:joyBumper(-1) end)  -- LB on the first wraps to the last
        return true
    end
    function S.wrapBottom(w, label)
        local ok, why = S.whole(w, S.D.n)
        S.verdict(w.pageIdx == S.D.n and ok, label .. ": LB on the first page wraps to the last, in view (" .. why .. ")")
        return true
    end

    -- EDGE CLICKS: a row cut by the box's top edge and one cut by its bottom edge take a click where they show;
    -- the Find box above the list picks no page
    function S.edgePrep(w)
        local rh = S.rowH()
        w.pageIdx = 1; w._pagesShown = 1
        w.pagesScroll = rh * 3 + math.floor(rh / 2)
        return true
    end
    function S.edgeCheck(w, label)
        local B = S.box(w)
        local hs, _, find = S.hits(w)
        local topRow, botRow
        for _, h in ipairs(hs) do
            if math.abs(h.y - B.y) < 1 and h.h < S.rowH() - 1 then topRow = h end
            if math.abs(h.y + h.h - B.bot) < 1 and h.h < S.rowH() - 1 then botRow = h end
        end
        S.say(label .. ": scrolled half a row: top row " .. tostring(topRow and (topRow.i .. " " .. fl(topRow.h) .. " px showing") or "none cut")
            .. " | bottom row " .. tostring(botRow and (botRow.i .. " " .. fl(botRow.h) .. " px showing") or "none cut"))
        S.shot("_edge")
        for _, c in ipairs({ { "top", topRow }, { "bottom", botRow } }) do
            local r = c[2]
            if r then
                local px, py = r.x + 20, r.y + r.h / 2
                local h = S.hitAt(w, px, py)
                local was = w.pageIdx
                if h and h.fn then h.fn() end
                S.verdict(h and h.id == r.hit.id and w.pageIdx == r.i, label .. ": a click on the half-hidden " .. c[1] .. " row picks it (hit "
                    .. tostring(h and h.id) .. ", page " .. tostring(was) .. " -> " .. tostring(w.pageIdx) .. ")")
                -- just outside the box on that side: no page
                local oy = (c[1] == "top") and (B.y - 2) or (B.bot + 2)
                local o = S.hitAt(w, px, oy)
                local isPage = o and string.find(tostring(o.id), ":page:", 1, true)
                S.verdict(not isPage, label .. ": 2 px past the box's " .. c[1] .. " edge is not a page (" .. tostring(o and o.id) .. ")")
            elseif S.D.over then
                S.verdict(false, label .. ": a row cut by the box's " .. c[1] .. " edge after half a row's scroll")
            end
        end
        if find then
            local was = w.pageIdx
            local h = S.hitAt(w, find.x + find.w / 2, find.y + find.h / 2)
            if h and h.fn and h.id == find.id then h.fn() end
            S.verdict(h and h.id == find.id and w.pageIdx == was, label .. ": a click on Find picks no page (" .. tostring(h and h.id) .. ")")
            pcall(function() w.find:unfocus() end)
        else
            S.say("NOTE " .. label .. ": no Find hit registered")
        end
        w.pageIdx = 1; w._pagesShown = nil; w.pagesScroll = 0; w.scroll = 0
        return true
    end

    -- the steps for one window, as { name, fn(w) -> true | false,why ; repeat = fn returns true while it wants another frame }
    function S.steps(label)
        return {
            { "measure " .. label, function(w) S.measure(w, label); S.shot(""); return true end },
            { "wheel prep", S.wheelPrep },
            { "wheel down", S.wheelDown, rep = true },
            { "wheel end", function(w) return S.wheelEnd(w, label) end, only = "over" },
            { "wheel shot", function() S.shot("_wheelend"); return true end, only = "over" },
            { "wheel up", S.wheelUp, rep = true, only = "over" },
            { "wheel top", function(w) return S.wheelTop(w, label) end, only = "over" },
            { "bar bottom", function(w) return S.barTo(w, "bottom") end, only = "over" },
            { "bar bottom check", function(w) return S.barCheck(w, label) end, only = "over" },
            { "bar middle", function(w) return S.barTo(w, "middle") end, only = "over" },
            { "bar middle check", function(w) return S.barCheck(w, label) end, only = "over" },
            { "bar top", function(w) return S.barTo(w, "top") end, only = "over" },
            { "bar top check", function(w) return S.barCheck(w, label) end, only = "over" },
            { "rb prep", S.bumpPrep },
            { "rb walk", S.bumpStep, rep = true },
            { "rb end", function(w) return S.bumpEnd(w, label) end },
            { "wrap top", function(w) return S.wrapTop(w, label) end },
            { "wrap bottom", function(w) return S.wrapBottom(w, label) end },
            { "edge prep", S.edgePrep, only = "over" },
            { "edge check", function(w) return S.edgeCheck(w, label) end, only = "over" },
        }
    end
    return S
end
