-- ZeDUI/tools/qa/object_card_fill_sim.lua  (Nov 23 2026, Build; object card fill, the director's 4K report)
-- The medical card and the washer's card stood short of the World window's drawer: the figure, the text, the scroll
-- bar, then an empty strip before the tab strip. (QA's runs narrowed the card alone to 336 or 220 inside the 480 drawer.)
-- The drawer's width for an object card is now one function (ZeD_WorldWindow.objectDrawerW), and the card fills the
-- drawer it is given (ZeD_WorldWindow.objectCardW); a half kind over a wider tab keeps the half card.
-- This sim cuts the two functions and the item drawer's prerender (itemDrawer._onPrerender) out of the real
-- ZeD_WorldWindow.lua and runs them on stub panels at 4K (1.75), 1080p (1) and the Deck (0.75). It checks:
--   TARGET  a full kind's drawer is the full card (480); a half kind is the half card alone, the tab's card under it
--   FILL    for drawers 480, 336, 220 and one wider than the full card (600), the card is the drawer's width, and its
--           scroll bar's right edge (the card's own: ObjectCards draws it at w - scrollbarW) is the drawer's right edge
--   HALF    a half kind over a 480 tab is 220 (the tab shows beside it), and fills a 220 drawer
--   COVER   the tab's hidden part under the card (the drawer's coverL) is the card's width
-- Run from the repo root:  lua51 ZeDUI/tools/qa/object_card_fill_sim.lua
-- It prints FAIL lines and a last line "object_card_fill_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]object_card_fill_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("object_card_fill_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed > 0 and 1 or 0)
end

local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_WorldWindow.lua", "rb")
local src = f:read("*a"):gsub("\r\n", "\n"); f:close()   -- (the file may have CRLF line ends)

-- the two width functions, with the file's two card widths in front of them
local fnA = src:match("(function ZeD_WorldWindow%.objectDrawerW%(def, base, heldIn%).-\nend)\n")
local fnB = src:match("(function ZeD_WorldWindow%.objectCardW%(def, effectiveW%).-\nend)\n")
local itemW = tonumber(src:match("\nlocal ITEM_CARD_W%s*=%s*(%d+)"))
local objW = tonumber(src:match("\nlocal OBJECT_CARD_W%s*=%s*(%d+)"))
check("objectDrawerW is found in ZeD_WorldWindow.lua", fnA ~= nil)
check("objectCardW is found in ZeD_WorldWindow.lua", fnB ~= nil)
check("the card widths are 220 and 480", itemW == 220 and objW == 480, tostring(itemW) .. " / " .. tostring(objW))
-- the item drawer's prerender (the card's place and width each frame)
local a = src:find("    itemDrawer._onPrerender = function(self)\n", 1, true)
local b = a and src:find("\n    end\n\n    itemDrawer.onMouseWheel", a, true)
check("the item drawer's prerender is found", a and b)
-- the tab's cover under a card (the drawer's coverL lines)
local cov = src:match("(local coverL = %(win%._drawerItem ~= nil%).-or nil)\n")
check("the drawer's cover under a card is found", cov ~= nil)
if not (fnA and fnB and itemW and objW and a and b and cov) then done() end

local SC = 1
ZeD = { T = { px = function(v) return math.floor(v * SC + 0.5) end, sp = {} }, Surface = { fill = function() end } }
ZeD_WorldWindow = {}
assert(loadstring("local ITEM_CARD_W, OBJECT_CARD_W = ...\n" .. fnA .. "\n" .. fnB, "width functions"))(itemW, objW)
local pre = assert(loadstring("local win, drawer, card, objCard = ...\nreturn " .. src:sub(a + #"    itemDrawer._onPrerender = ", b + #"\n    end" - 1), "item drawer prerender"))
local coverFn = assert(loadstring("local win, effectiveW, T, ITEM_CARD_W = ...\nlocal od = win._drawerObject and win._drawerObject.def\n"
    .. cov .. "\nreturn coverL", "cover"))

-- a stub panel: the calls the prerender makes
local function panel(x, w, h)
    local p = { x = x or 0, y = 0, w = w or 0, h = h or 0, vis = true }
    function p:setX(v) self.x = v end
    function p:setY(v) self.y = v end
    function p:getX() return self.x end
    function p:setWidth(v) self.w = v end
    function p:getWidth() return self.w end
    function p:setHeight(v) self.h = v end
    function p:getHeight() return self.h end
    function p:setVisible(v) self.vis = v end
    return p
end

local FULL, HALF = { id = "medic" }, { id = "lock", half = true }
-- one frame of the World window's item drawer with an object card of kind def in a drawer effU design units wide
local function frame(def, effU, mode)
    local T = ZeD.T
    local win = { _drawerEffW = T.px(effU), _drawerObject = { def = def }, _drawerItem = nil, _drawerMode = mode or "object",
                  getBodyHeight = function() return T.px(600) end }
    local drawer = panel(T.px(36 + 372), T.px(effU), T.px(600))
    local itemDrawer, card, objCard = panel(0, 0, 0), panel(), panel()
    pre(win, drawer, card, objCard)(itemDrawer)
    local coverL = coverFn(win, math.floor(win._drawerEffW), T, itemW)
    return objCard, itemDrawer, drawer, coverL
end

for _, s in ipairs({ { "4K", 1.75 }, { "1080p", 1 }, { "Deck", 0.75 } }) do
    SC = s[2]
    local T = ZeD.T
    T.sp.scrollbarW = T.px(10)
    -- TARGET
    check(s[1] .. " TARGET: a full kind's drawer is the full card", ZeD_WorldWindow.objectDrawerW(FULL, 0) == T.px(480))
    check(s[1] .. " TARGET: a full kind over a half tab is still the full card", ZeD_WorldWindow.objectDrawerW(FULL, T.px(220)) == T.px(480))
    check(s[1] .. " TARGET: a half kind alone is the half card", ZeD_WorldWindow.objectDrawerW(HALF, 0) == T.px(220))
    check(s[1] .. " TARGET: a half kind over a full tab keeps the tab's drawer", ZeD_WorldWindow.objectDrawerW(HALF, T.px(480)) == T.px(480))
    -- FILL: drawers at the full card, QA's 336 and 220, and one wider than the full card's snap
    for _, effU in ipairs({ 480, 336, 220, 600 }) do
        local oc, idr, dr, coverL = frame(FULL, effU)
        local innerW = dr:getWidth()
        local sbRight = oc:getX() + (oc:getWidth() - T.sp.scrollbarW) + T.sp.scrollbarW   -- the scroll bar's right edge
        check(s[1] .. " FILL " .. effU .. ": the card is the drawer's width", oc:getWidth() == innerW and idr:getWidth() == innerW,
            ("card %d, item drawer %d, drawer %d"):format(oc:getWidth(), idr:getWidth(), innerW))
        check(s[1] .. " FILL " .. effU .. ": the card sits at the drawer's left", idr:getX() == dr:getX() and oc:getX() == 0)
        check(s[1] .. " FILL " .. effU .. ": the scroll bar's right edge is the drawer's", idr:getX() + sbRight == dr:getX() + innerW,
            ("%d vs %d"):format(idr:getX() + sbRight, dr:getX() + innerW))
        check(s[1] .. " COVER " .. effU .. ": the tab's hidden part is the card", coverL == oc:getWidth())
        check(s[1] .. " FILL " .. effU .. ": the card shows", oc.vis == true)
    end
    -- HALF: a half kind over a full tab is the half card; alone in a half drawer it fills it
    local oc, _, _, coverL = frame(HALF, 480, "tab")
    check(s[1] .. " HALF: a half kind over a 480 tab is the half card", oc:getWidth() == T.px(220), oc:getWidth())
    check(s[1] .. " HALF: the tab's hidden part is the half card", coverL == T.px(220))
    oc = frame(HALF, 220)
    check(s[1] .. " HALF: a half kind fills a 220 drawer", oc:getWidth() == T.px(220))
end

done()
