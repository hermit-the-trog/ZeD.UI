-- ============================================================================
-- ZeD_BoxSelect.lua: drag a box from empty space to select the rows it crosses (punch list 146)
-- ============================================================================
-- The director, Nov 10 2026 (fast looting, after a vanilla player on a stream): "Box from empty space". In ZeD's
-- inventory and loot lists a drag that starts on a row moves the selection, as before; a drag that starts on empty
-- space (below the rows, between columns' rows) draws a box, and every row it crosses is selected while it is drawn.
-- Ctrl or Shift held at the press adds the box to what was selected. The box works on the rows on screen (the list's
-- hit zones, rebuilt each frame); in a multi-container view only the column it started in.
-- The windows' content panels call start / move / finish / draw (ZeD_CharacterWindow.lua, ZeD_WorldWindow.lua, the
-- list's render in InventoryRenderer.lua).
-- ============================================================================

ZeD = ZeD or {}
ZeD.BoxSelect = ZeD.BoxSelect or {}
local BS = ZeD.BoxSelect

-- an item row's zone: its id is the item (strings are the list's other zones: categories, stacks, buttons)
local function isItemZone(z)
    local t = type(z.id)
    return z.id ~= nil and t ~= "string" and t ~= "number" and t ~= "boolean"
end

--- Begin a box at (x, y), panel-local, over the selection sel (a set: item -> true). colAt: optional function(x)
--- giving the column at x (the box keeps to the one it starts in).
function BS.start(content, x, y, sel, colAt)
    local base = {}
    local add = (isCtrlKeyDown and isCtrlKeyDown()) or (isShiftKeyDown and isShiftKeyDown())
    if add then for k in pairs(sel) do base[k] = true end end
    content._box = { x0 = x, y0 = y, x1 = x, y1 = y, sel = sel, base = base, colAt = colAt,
                     col = colAt and colAt(x) or nil, live = false }
    if content.setCapture then content:setCapture(true) end
end

--- True while a box is being drawn (the drag has moved past the threshold).
function BS.active(content) return content._box ~= nil and content._box.live end

-- every item zone the box crosses, selected; what was there before kept when Ctrl or Shift was held
local function apply(content)
    local b = content._box
    local x0, x1 = math.min(b.x0, b.x1), math.max(b.x0, b.x1)
    local y0, y1 = math.min(b.y0, b.y1), math.max(b.y0, b.y1)
    local sel = b.sel
    for k in pairs(sel) do sel[k] = nil end
    for k in pairs(b.base) do sel[k] = true end
    local last = nil
    for _, z in ipairs(content._hitZones or {}) do
        if isItemZone(z) and z.x < x1 and z.x + z.w > x0 and z.y < y1 and z.y + z.h > y0
           and (b.col == nil or not b.colAt or b.colAt(z.x + math.floor(z.w / 2)) == b.col) then
            sel[z.id] = true
            last = z.id
        end
    end
    b.last = last
end
BS._apply = apply

--- The pointer moved (panel-local x, y): the box follows once past the drag threshold. True while a box is open.
function BS.move(content, x, y)
    local b = content._box
    if not b then return false end
    b.x1, b.y1 = x, y
    if not b.live then
        local T = ZeD.T
        local th = (T and T.px and T.px(4)) or 4
        if math.abs(b.x1 - b.x0) > th or math.abs(b.y1 - b.y0) > th then b.live = true end
    end
    if b.live then apply(content) end
    return true
end

--- The press ended. Returns nil when no box was open, else the last row the box took (or false when it took none
--- or never moved) and the column it was drawn in; the caller sets its last-clicked row from it and updates the
--- item card.
function BS.finish(content)
    local b = content._box
    if not b then return nil end
    if b.live then apply(content) end   -- (the rows under the box where it was let go)
    content._box = nil
    if content.setCapture then content:setCapture(false) end
    if not b.live then return false, b.col end   -- (a press on empty space and no drag changes nothing, as before)
    return b.last or false, b.col
end

--- Draw the open box (the content's render, after the rows): the accent's wash and its outline.
function BS.draw(content)
    local b = content._box
    if not (b and b.live) then return end
    local T = ZeD.T
    local ac = T.accent
    local x0, y0 = math.min(b.x0, b.x1), math.min(b.y0, b.y1)
    local w, h = math.abs(b.x1 - b.x0), math.abs(b.y1 - b.y0)
    content:drawRect(x0, y0, w, h, 0.12, ac.r, ac.g, ac.b)
    content:drawRectBorder(x0, y0, w, h, 0.9, ac.r, ac.g, ac.b)
end

-- ---------------------------------------------------------------------------
-- SELECT ALL: a double-click on empty space (punch list 146, the director, Nov 10 2026, after QA's Mac run: Ctrl+A
-- walked the character, the A being a movement key the game always hears, and was heard only on its release, when Ctrl
-- already read up). The second press of a double-click on the list's empty space, where a box would start, selects
-- every row of that list (the window's zedSelectAll); a single press there still starts a box.
-- ---------------------------------------------------------------------------
BS.DOUBLE_MS = 400
--- A press on empty space at (x, y), panel-local: true when it is the second of a double-click there.
function BS.doubleEmpty(content, x, y)
    local now = getTimestampMs and getTimestampMs() or 0
    local e = content._emptyPress
    local T = ZeD.T
    local near = (T and T.px and T.px(4)) or 4
    if e and now - e.t <= BS.DOUBLE_MS and math.abs(x - e.x) <= near and math.abs(y - e.y) <= near then
        content._emptyPress = nil
        return true
    end
    content._emptyPress = { t = now, x = x, y = y }
    return false
end
