-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardMedic.lua
-- ============================================================================
-- OBJECT CARD: MEDICAL CHECK OF ANOTHER PLAYER (card definition, client)
-- Right-click a player > Medical Check: they say yes (the game's own question,
-- a ZeD prompt), the game's ISMedicalCheckAction runs, and where vanilla's perform opens its health
-- panel on them (ISHealthPanel in a collapsible window) this card opens instead (Overrides/
-- TradeMedic.lua). It is ZeD's Health tab on the patient:
--   the body figure coloured by each part's health, the summary (overall, wounded parts, their pain
--   for a First Aid 5+ doctor, as vanilla) or the part under the pointer or the controller, then the
--   injury list (beside the figure on the full card, under it on the half card), with exactly what vanilla's panel lets this doctor see (ZeD.HealthTab's classifier,
--   given the doctor's First Aid level). On a server another player's body is read from their remote
--   copy, as vanilla reads it.
--   A part (on the figure or in the list) opens the game's treatment menu for it: vanilla's own
--   ISHealthPanel:doBodyPartContextMenu with the doctor as doctor and the patient as patient, so
--   bandage, disinfect, stitch, splint, remove glass or a bullet and the rest are the game's own
--   timed actions on them. Not while the game is paused, as vanilla's list.
-- It closes as vanilla's window closes: either of you moves (a staff member who may check from afar,
-- and two people in one car, excepted), or they leave and come back. More than 2 tiles apart
-- (possible only in those two cases) blocks it with vanilla's words until you are close again.
-- Works in single player and split screen too (another local player is read directly).
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/HealthTab"
require "ZeD/ZeD_BodyFigure"
require "XpSystem/ISUI/ISHealthPanel"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call

ZeD = ZeD or {}
ZeD.Medic = ZeD.Medic or {}
local MC = ZeD.Medic

local def = { id = "medic", vehicleOk = true }

--- The check can open on this doctor's World window (one window, for one player; not in safe mode).
function MC.canOpen(doctor)
    if not doctor then return false end
    if ZeD.Safe and ZeD.Safe.on("windows") then return false end
    if not (OC.kinds.medic and ZeD_WorldWindow and ZeD_WorldWindow.openObjectCard) then return false end
    local win = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(doctor:getPlayerNum())
    if win and win._playerObj and win._playerObj ~= doctor then return false end
    return true
end

function MC.open(doctor, patient)
    local ok = OC.open(doctor, "medic", patient)
    if ok then
        local card = ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard(doctor:getPlayerNum())
        MC.current = card and card.entry and card.entry.t or nil
    end
    return ok
end

-- the check's card gone by any path (the World window closed or toggled away, another card, safe mode):
-- the doctor stops receiving the patient's body, as vanilla does when its window hides
local function ended(t)
    if MC.current == t then MC.current = nil end
    if t and not t._ended and t.doctor and t.patient then
        t._ended = true
        pcall(function() t.doctor:stopReceivingBodyDamageUpdates(t.patient) end)
    end
end
MC.ended = ended
function MC.tick()
    local t = MC.current
    if not t then return end
    -- the card on the doctor's own window
    local card = ZeD_WorldWindow and ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard(t.doctor and t.doctor:getPlayerNum())
    local e = card and card.entry
    if not (e and e.t == t) then ended(t) end
end
if Events and Events.OnTick and not MC._tickAdded then
    MC._tickAdded = true
    Events.OnTick.Add(function() MC.tick() end)
end

local function remote(p) return isClient() and not p:isLocalPlayer() end

-- the patient's name in the title, as vanilla's perform writes it
local function patientName(p)
    if isClient() then return call(p, "getDisguisedDisplayName") or "?" end
    local d = call(p, "getDescriptor")
    if d then return tostring(call(d, "getForename") or "") .. " " .. tostring(call(d, "getSurname") or "") end
    return call(p, "getDisplayName") or "?"
end

function def.resolve(doctor, patient)
    if not (doctor and patient) or doctor == patient then return nil end
    return {
        doctor = doctor, patient = patient,
        key = "medic:" .. tostring(call(patient, "getOnlineID") or patient),
        -- (vanilla's setOtherPlayer: where both stood when the check opened)
        pX = patient:getX(), pY = patient:getY(), dX = doctor:getX(), dY = doctor:getY(),
        level = doctor:getPerkLevel(Perks.Doctor),
        fakeWin = {},   -- (what the Health tab's detail view writes to)
    }
end

-- vanilla's ISHealthPanel:update for another player, every frame: false closes the card
function def.valid(t)
    local d, p = t.doctor, t.patient
    if not (d and p) then return false end
    if isClient() and p ~= getPlayerByOnlineID(p:getOnlineID()) then return false end
    local cheat = false
    if isMultiplayer() then
        local ok, r = pcall(function() return d:getRole():hasCapability(Capability.CanMedicalCheat) end)
        cheat = ok and r == true
    end
    if not cheat and not ISHealthPanel.IsCharactersInSameCar(d, p) and
            (math.abs(d:getX() - t.dX) > 0.5 or math.abs(d:getY() - t.dY) > 0.5 or
             math.abs(p:getX() - t.pX) > 0.5 or math.abs(p:getY() - t.pY) > 0.5) then
        return false
    end
    if (math.abs(p:getX() - d:getX()) > 2 or math.abs(p:getY() - d:getY()) > 2) and not ISHealthPanel.cheat then
        if not t.blocking then
            pcall(function() d:stopReceivingBodyDamageUpdates(p) end)
            pcall(function() p:getBodyDamageRemote():RestoreToFullHealth() end)
            t.d = nil
        end
        t.blocking = getText("IGUI_TradingUI_TooFarAway", p:getDisplayName())
    else
        if t.blocking then pcall(function() d:startReceivingBodyDamageUpdates(p) end) end
        t.blocking = nil
    end
    return true
end

-- vanilla's tryStopReceivingBodyDamageUpdates when its window goes
function def.onClose(t, card)
    ended(t)
end

function def.refresh(t, doctor)
    t.verbs = t.verbs or {}
    if t.blocking then return end
    local p = t.patient
    local isRemote = remote(p)
    -- (read afresh every time: startReceivingBodyDamageUpdates resets the remote copy, and the
    -- server fills it as its updates arrive, so what this reads grows after the first frames. The
    -- server's copy of the patient is what arrives: a wound that only the patient's own client
    -- holds never reaches it)
    local bd = isRemote and p:getBodyDamageRemote() or p:getBodyDamage()
    if not bd then return end
    local d = ZeD.HealthTab.gatherData(p, { doctorLevel = t.level, bodyDamage = bd })
    -- each listed part's name on the figure (the list's words can differ: "Left Thigh")
    local figOf = {}
    for fname, bp in pairs(d.partByFigure or {}) do figOf[bp] = fname end
    for _, en in ipairs(d.entries) do en.figure = figOf[en.bodyPart] end
    local pain = 0
    if isRemote then pain = bd:getRemotePainLevel()
    else
        local ok, v = pcall(function() return p:getMoodles():getMoodleLevel(MoodleType.PAIN) end)
        pain = ok and v or 0
    end
    -- (vanilla: their pain shows to a First Aid 5+ doctor)
    t.pain = ((ISHealthPanel.cheat or t.level > 4) and pain > 0) and pain or nil
    t.d = d
end

function def.title(t) return getText("IGUI_health_playerHealth", patientName(t.patient)) end
function def.icon(t) return nil end
function def.pxIcon(t) return "stethoscope" end

-- (the status bars' rule: ZeD.Atoms.statusColor, punch list 143)
function def.pill(t)
    if t.blocking or not t.d then return nil end
    -- (cut down, as the Overall row's percent: 99.6 is 99%, never 100% beside "Slight damage")
    local frac = t.d.overall / 100
    return ZeD.Atoms.pctText(frac), ZeD.Atoms.statusColor(frac)
end

function def.status(t)
    if t.blocking then return { text = t.blocking, c = ZeD.T.danger } end
    return nil
end

-- where the controller lands: the worst injury, else the chest on the figure
function def.openFocus(t)
    local en = t.d and t.d.entries and t.d.entries[1]
    if en then return "mc:part:" .. tostring(en.name) end
    return "mc:fig:Upper Torso"
end

-- ---------------------------------------------------------------------------
-- treatment: the game's own menu for one part
-- ---------------------------------------------------------------------------
local function treat(card, t, bp, zx, zy, zh)
    if not bp or t.blocking then return end
    -- (vanilla's list: no treatment menu while the game is paused, unless in debug)
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc and sc:getCurrentGameSpeed() == 0 and not getDebug() then return end
    local rx, ry = zx or 0, (zy or 0) + (zh or 0)
    if card:pointerOver() then
        rx = getMouseX() - card:getAbsoluteX()
        ry = getMouseY() - card:getAbsoluteY()
    end
    ZeD.HealthTab.treat(t.patient, t.doctor, bp, card, rx, ry, t.blocking)
end

-- the part the right column details: the controller's (a figure part or an injury row) leads,
-- else the pointer's; the second value is true when it came from the figure
local function activePart(card, t)
    local function fromFid(fid)
        if not fid then return nil end
        local fig = fid:match("^mc:fig:(.+)$")
        if fig then return fig, true end
        local row = fid:match("^mc:part:(.+)$")
        if row and t.d then
            for _, en in ipairs(t.d.entries) do
                if en.name == row then return en.figure, false end
            end
        end
        return nil
    end
    local part, onFig = fromFid(card._fid)
    if part then return part, onFig end
    return fromFid(card._hoverFid)
end

local FIG = nil
local function figure()
    if not FIG then
        FIG = ZeD_BodyFigure:new(0, 0, 100, 100)
        FIG:initialise()
        FIG:loadTextures()
        FIG.boneLift = true   -- the tint keeps the bones light, as the Health tab's (the director, Nov 23 2026)
    end
    return FIG
end

-- the summary column (the Health tab's, without your own exercise): overall, wounded, their pain
local function summary(card, t, rx, ry, rw)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local d = t.d
    local secH = ZeD.TM:getFontHeight(T.fontF1)
    local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
    local dotSz, dotGap = T.px(6), T.px(4)
    local y = ry
    -- (the Health tab's overall block: the row, the bar and the game's own word under them)
    y = ZeD.HealthTab.drawOverall(card, rx, y, rw, d)
    -- (the Health tab's summary: wounds counted, muscle strain apart) (Strain, the director, Nov 22 2026)
    y = ZeD.HealthTab.drawSummary(card, d, rx, y)
    if t.pain then
        A.drawStatusDot(card, rx, y + math.floor((bodyFH - dotSz) / 2), (t.pain >= 3) and T.danger or T.warning, dotSz)
        A.drawBody(card, getText("Moodles_Pain_lvl" .. tostring(t.pain)), rx + dotSz + dotGap, y)
        y = y + secH + T.sp.sm
    end
    return y
end

-- one row of the injury list (the Health tab's look): the mark, the part, its health, its tags
local function injuryRow(card, t, x, y, w, en, stripe)
    local T, A = ZeD.T, ZeD.Atoms
    local HT = ZeD.HealthTab
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    -- (the tags as the Health list: the words under the name, the squares under its square)
    local ind = T.px(2) + T.px(6) + T.px(6)
    local hang = HT.tagHang and HT.tagHang() or 0
    local tagsH = HT.condTags(nil, en.conditions, 0, 0, w - ind, hang)
    local h = bodyH + T.px(2) + (tagsH > 0 and (tagsH + T.sp.xs) or 0) + T.px(1) + T.sp.afterGroove
    if stripe then
        local st = T.stripe
        card:drawRect(x, y, w, h, st.a, st.r, st.g, st.b)
    end
    local fid = "mc:part:" .. tostring(en.name)
    local fo = card:focusOf(fid)
    local onFocus = fo and ZeD.Focus.mark(card, x, y, w, h, fo) or false
    local ink = onFocus and T.textOnFocus or T.text
    local sq = T.px(6)
    local mark = HT.sevColor(en.worstSev)
    if mark then A.drawStatusDot(card, x + T.px(2), y + math.floor((bodyH - sq) / 2), mark, sq) end
    A.drawBody(card, ZeD.partLabel(en.name), x + T.px(2) + sq + T.px(6), y, ink)
    A.drawTextRight(card, math.floor(en.health + 0.5) .. "%", x + w, y, T.fontF2, ink)
    local ty = y + bodyH + T.px(2)
    if tagsH > 0 then HT.condTags(card, en.conditions, x + ind, ty, w - ind, hang); ty = ty + tagsH + T.sp.xs end
    A.drawDividerH(card, x, ty, w)
    local bp = en.bodyPart
    card:zone({ fid = fid, x = x, y = y, w = w, h = h, body = true, help = getText("IGUI_health_JoypadTreatment"),
        run = function(c) treat(card, t, bp, x, y, h) end })
    return h
end

function def.body(card, x, y, w, t, doctor)
    local T, A = ZeD.T, ZeD.Atoms
    if t.blocking then return UI.warn(card, x, y, w, t.blocking) + T.px(4) end
    local d = t.d
    if not d then return 0 end
    local y0 = y
    -- the figure in its frame, the left half of the card, the text the right half; a card too narrow for halves
    -- (the 220 drawer card) stacks the frame over the text (Figure frame, the director, Nov 22 2026)
    local L = ZeD.Molecules.figureFrame(x, y, w)
    local active, onFig = activePart(card, t)
    -- the figure: each part in its health's colour (a strained part with no wound in the strain tint, as the
    -- Health tab's: HealthTab.figureColor) (Strain, the director, Nov 22 2026); the controller's mark under the focused part
    -- (last frame's rects, as the Health tab draws it), the part a stop that opens the treatment menu
    local fig = figure()
    if d.isFemale ~= nil then fig:setSex(d.isFemale) end
    -- (no clearColors: the check maps every body part each frame, and the figure reuses its colour tables) (beast W19)
    for fname, health in pairs(d.partHealth) do
        ZeD.HealthTab.tintPart(fig, d, fname, health)   -- (a healthy part: no tint, the director, Nov 23 2026)
    end
    -- the patient's wounds and their care, on their own skin, as the Health tab draws them (Design, Nov 22 2026)
    fig:setSkinTone(d.skinTone)
    for fname in pairs(d.partHealth) do
        fig:setPartWounds(fname, d.woundsByFigure and d.woundsByFigure[fname])
    end
    fig.selectedPart = active
    -- the frame and its chart first: the controller's marks and the figure sit on them (Figure frame, Nov 22 2026)
    ZeD.Molecules.drawFigureFrame(card, L)
    fig:drawChart(card, L)
    for _, r in ipairs(t._rects or {}) do
        local fo = card:focusOf("mc:fig:" .. r.name)
        if fo then ZeD.Focus.mark(card, r.x, r.y, r.w, r.h, fo) end
    end
    fig:drawAt(card, L.figX, L.figY, L.figW, L.figH)   -- (at the layout's whole zoom; the stops follow: getPartRects)
    t._rects = fig:getPartRects()
    for _, r in ipairs(t._rects) do
        local bp = d.partByFigure and d.partByFigure[r.name]
        local rr = r
        card:zone({ fid = "mc:fig:" .. r.name, x = r.x, y = r.y, w = r.w, h = r.h, body = true,
            help = getText("IGUI_health_JoypadTreatment"),
            run = function(c) treat(card, t, bp, rr.x, rr.y, rr.h) end })
    end
    local rx, ry, rw = L.rightX, L.rightY, L.rightW
    local bottom
    -- a card wide enough for halves: the summary, then the injury list with its treatments, in the column beside the
    -- figure, as the Health tab's column lists them, so no one scrolls past the figure to reach a treatment. The
    -- column grows down with the card and scrolls with it. A figure part in hand takes the summary's place; an injury
    -- row in hand does not, as the row already shows its part and a column that changed height under the pointer
    -- would slide the rows it points at (the director, Nov 26 2026)
    if L.two then
        if active and onFig and d.partHealth[active] then
            bottom = ZeD.HealthTab._renderDetailView(card, t.fakeWin, d, active, rx, ry, rw)
        else
            bottom = summary(card, t, rx, ry, rw)
        end
        y = bottom or ry
        if #d.entries > 0 then
            A.drawDividerH(card, rx, y, rw)
            y = y + T.px(1) + T.sp.afterGroove
            for i, en in ipairs(d.entries) do
                y = y + injuryRow(card, t, rx, y, rw, en, i % 2 == 0)
            end
        end
        return math.max(L.frameY + L.frameH, y) - y0
    end
    -- the 220 drawer card, stacked: under the figure the part in hand, else the summary, then the list full width
    if active and d.partHealth[active] then
        bottom = ZeD.HealthTab._renderDetailView(card, t.fakeWin, d, active, rx, ry, rw)
    else
        bottom = summary(card, t, rx, ry, rw)
    end
    y = math.max(L.frameY + L.frameH, bottom or ry) + T.px(10)   -- (past the frame's foot and the text's)
    -- the injury list
    if #d.entries > 0 then
        A.drawDividerH(card, x, y, w, true)
        y = y + T.px(1) + T.sp.afterLine
        for i, en in ipairs(d.entries) do
            y = y + injuryRow(card, t, x, y, w, en, i % 2 == 0)
        end
    end
    return y - y0
end

OC.register(def)
print("[ZeD] ObjectCardMedic: medical check card loaded")
return MC
