-- ZeD-UI/42/media/lua/client/ZeD/PopClear.lua
-- ============================================================================
-- POP-OUTS KEEP CLEAR OF ZeD'S WINDOWS (client)
-- (Nov 15 2026, QA's beta 16 pass: the seat pop-out's cabin and the TV's face, placed beside the player, sat over the
-- World window's bottom right corner.) A pop-out placing itself (never one the player dragged, nor a saved spot) asks
-- ZeD.PopClear.spot for a place clear of the player's Character and World windows: its own spot when nothing is in
-- the way, else just below the window it overlaps, else just above it, else its own spot after all (better over a
-- corner than off the screen). Read when the pop-out opens, not every frame.
-- ============================================================================

ZeD = ZeD or {}
local PC = {}
ZeD.PopClear = PC

-- the player's open ZeD windows, as rects { x, y, w, h } (a rolled-up or hidden window is not in the way)
local function windowsOf(pn)
    local out = {}
    local list = { ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }
    for i = 1, 2 do
        local get = list[i]
        if get then
            local ok, win = pcall(get, pn)
            if ok and win and win.isReallyVisible and win:isReallyVisible() then
                out[#out + 1] = { x = win:getX(), y = win:getY(), w = win:getWidth(), h = win:getHeight() }
            end
        end
    end
    return out
end

-- true when the two rects share any pixel
local function overlaps(ax, ay, aw, ah, b)
    return ax < b.x + b.w and b.x < ax + aw and ay < b.y + b.h and b.y < ay + ah
end

-- the first window the rect sits over, or nil
local function hitOf(wins, x, y, w, h)
    for _, b in ipairs(wins) do if overlaps(x, y, w, h, b) then return b end end
    return nil
end

--- A spot for a w x h pop-out wanted at (x, y), clear of pn's ZeD windows. Returns x, y.
function PC.spot(pn, x, y, w, h)
    local wins = windowsOf(pn or 0)
    local b = hitOf(wins, x, y, w, h)
    if not b then return x, y end
    local T = ZeD.T
    local gap = (T and T.px) and T.px(8) or 8
    local sh = getCore():getScreenHeight()
    -- below the window, then above it: the first that is whole on the screen and over no window
    local tries = { b.y + b.h + gap, b.y - h - gap }
    for i = 1, 2 do
        local ny = tries[i]
        if ny >= 0 and ny + h <= sh and not hitOf(wins, x, ny, w, h) then return x, ny end
    end
    return x, y
end

return PC
