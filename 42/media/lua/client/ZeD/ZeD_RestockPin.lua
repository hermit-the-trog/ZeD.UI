-- ZeD-UI/42/media/lua/client/ZeD/ZeD_RestockPin.lua
-- ============================================================================
-- THE PINNED TO-DO (handoff equip_doll_v4_loadouts, part B5; mockup r2_06)
--
-- While a Casual or Accessible restock (or unpack) runs, the to-do pins as a
-- small list at the left edge of the screen: its name, the lines still to do
-- (their state icon, the thing, where), and one line under them: the last
-- notice ("Bandage x2 from the Bathroom Cabinet") or, walking, "Walking to 2 of
-- 3 | 0:40 left". It goes when the list is empty (a few seconds after, with
-- "Restocked") or when the run stops (with the reason). The close key at its
-- top right stops the run. Drawn with the library's tokens; not a stop for the
-- pad (any button stops the run, ZeD_Restock).
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_Restock"

ZeD = ZeD or {}
ZeD.RestockPin = ZeD.RestockPin or {}
local P = ZeD.RestockPin
local R = ZeD.Restock

local PIN_W = 250      -- design units
local ROW_H = 20
local MAX_ROWS = 8
local LINGER_MS = 5000 -- after the run: how long the last line stays

ZeD_RestockPin = ISPanel:derive("ZeD_RestockPin")

local function fh(f) return ZeD.TM:getFontHeight(f) end
local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end

local STATE_ICON = { take = "box_down", fill = "tap", ask = "help", none = "no", far = "walk", put = "box_down", pick = "help" }
local function tint(T, s)
    if s == "take" or s == "put" then return T.accent end
    if s == "fill" then return T.info end
    if s == "ask" or s == "pick" or s == "far" then return T.warning end
    return T.danger
end

function ZeD_RestockPin:new(pn)
    local T = ZeD.T
    local o = ISPanel:new(T.px(12), math.floor(getCore():getScreenHeight() * 0.55), T.px(PIN_W), T.px(60))   -- (below where the window pair opens)
    setmetatable(o, self)
    self.__index = self
    o.pn = pn
    o.background = false
    o.moveWithMouse = false
    o._rows = {}
    o._ms = 0
    return o
end

-- the lines still to do (kept a second)
function ZeD_RestockPin:refresh(p, run)
    local now = getTimestampMs()
    if now - self._ms < 1000 then return end
    self._ms = now
    local rows = {}
    if run.kind == "unpack" then
        local up = R.unpackPlan(p)
        for _, e in ipairs(up.loot) do
            rows[#rows + 1] = { state = e.state, name = R.call(e.item, "getDisplayName") or "?", where = e.dest and e.dest.name or ZeD.tr("UI_ZeD_Unpack_PickPlace") }
        end
        for _, e in ipairs(up.leftovers) do
            if e.state ~= "stay" then rows[#rows + 1] = { state = e.state, name = R.call(e.item, "getDisplayName") or "?", where = e.dest and e.dest.name or "" } end
        end
    else
        local ok, plan = pcall(R.plan, p, {})
        for _, row in ipairs(ok and plan and plan.rows or {}) do
            if row.state ~= "on" then rows[#rows + 1] = { state = row.state, name = row.line.name or "?", where = row.where or "" } end
        end
    end
    self._rows = rows
end

function ZeD_RestockPin:prerender()
    local T, A = ZeD.T, ZeD.Atoms
    local p = getSpecificPlayer(self.pn)
    local run = R.runs[self.pn]
    if not (p and run) then return end
    if not run.done then self:refresh(p, run) end
    local w = T.px(PIN_W)
    local f1, f2 = T.fontF1, T.fontF2
    local pad = T.px(8)
    local titleH = T.px(24)
    local nRows = run.done and 0 or math.min(MAX_ROWS, #self._rows)
    local status = nil
    if ZeD.EquipLoadout and ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow then
        local win = ZeD_CharacterWindow.getWindow()
        if win then status = ZeD.EquipLoadout.statusText(win) end
    end
    status = status or run.notice or ""
    local lines = A.wrapText(status, f1, w - pad * 2 - T.px(12))
    local h = titleH + nRows * T.px(ROW_H) + (nRows > 0 and T.px(4) or 0) + #lines * (fh(f1) + T.px(2)) + pad
    if self:getWidth() ~= w or self:getHeight() ~= h then self:setWidth(w); self:setHeight(h) end
    -- the panel: surface 1, its frame, the title band on surface 2
    A.surfaceFill(self, 0, 0, w, h, "surf1")
    A.surfaceFill(self, 0, 0, w, titleH, "surf2")
    A.drawDividerH(self, 0, titleH - T.hair, w, true)
    A.frame(self, 0, 0, w, h, T.borderS)
    A.drawHardShadow(self, 0, 0, w, h)
    local title = ZeD.tr(run.kind == "unpack" and "UI_ZeD_Pin_TitleUnpack" or "UI_ZeD_Pin_Title", run.list or "")
    local tc = T.text
    local cb = T.px(16)
    self:drawText(A.truncateText(title, f1, w - pad * 2 - cb - T.px(6)), pad, math.floor((titleH - fh(f1)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f1)
    -- the close key: stops the run
    local cx, cy = w - pad - cb, math.floor((titleH - cb) / 2)
    self._close = { x = cx, y = cy, w = cb, h = cb }
    local hov = A.mouseIn(self, cx, cy, cb, cb)
    ZeD.Molecules.drawIconButton(self, cx, cy, cb, "window_close", { hover = hov, hint = ZeD.tr("UI_ZeD_Pin_Stop"), id = "pinclose", iconSize = T.px(12) })
    local y = titleH + T.px(2)
    for i = 1, nRows do
        local r = self._rows[i]
        local isz = T.px(12)
        A.drawPxIcon(self, STATE_ICON[r.state] or "no", pad, y + math.floor((T.px(ROW_H) - isz) / 2), isz, 1, tint(T, r.state))
        local wt = A.truncateText(r.where or "", f1, math.floor(w * 0.45))
        local dc = T.textDim
        self:drawText(wt, w - pad - tw(f1, wt), y + math.floor((T.px(ROW_H) - fh(f1)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f1)
        local nx = pad + isz + T.px(6)
        self:drawText(A.truncateText(r.name, f2, w - pad - tw(f1, wt) - T.px(8) - nx), nx, y + math.floor((T.px(ROW_H) - fh(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        y = y + T.px(ROW_H)
    end
    if nRows > 0 then y = y + T.px(4) end
    for _, ln in ipairs(lines) do
        A.drawStatusHollow(self, pad, y + math.floor((fh(f1) - T.px(6)) / 2), T.textDim, T.px(6))
        self:drawText(ln, pad + T.px(12), y, tc.r, tc.g, tc.b, tc.a or 1, f1)
        y = y + fh(f1) + T.px(2)
    end
end

function ZeD_RestockPin:render() end

function ZeD_RestockPin:onMouseDown(x, y)
    local c = self._close
    if c and x >= c.x and x < c.x + c.w and y >= c.y and y < c.y + c.h then
        local p = getSpecificPlayer(self.pn)
        local run = R.runs[self.pn]
        if p and run and not run.done then R.stop(p, "user") end
        P.hide(self.pn)
        return true
    end
    return true
end

-- ---------------------------------------------------------------------------
-- shown while a Casual / Accessible run goes (and a few seconds after it)
-- ---------------------------------------------------------------------------
P.panels = P.panels or {}

function P.hide(pn)
    local pin = P.panels[pn]
    if pin then pin:removeFromUIManager(); P.panels[pn] = nil end
end

function P.update()
    for pn, run in pairs(R.runs) do
        local want = (run.mode == "casual" or run.mode == "accessible")
            and ((not run.done) or (getTimestampMs() - (run.doneMs or 0) < LINGER_MS))
        local pin = P.panels[pn]
        if want and not pin then
            pin = ZeD_RestockPin:new(pn)
            pin:initialise()
            pin:addToUIManager()
            pin:setAlwaysOnTop(true)
            P.panels[pn] = pin
        elseif not want and pin then
            P.hide(pn)
        end
    end
end

if not _G._zedRestockPinHooked then
    _G._zedRestockPinHooked = true
    local n = 0
    Events.OnTick.Add(function()
        n = n + 1
        if n % 15 == 0 then pcall(ZeD.RestockPin.update) end
    end)
end
