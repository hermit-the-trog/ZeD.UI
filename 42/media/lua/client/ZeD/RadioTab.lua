-- ZeD-UI/42/media/lua/client/ZeD/RadioTab.lua
-- ============================================================================
-- RADIO TAB — client; the radios' tab in both windows.
--
-- Plugs into BOTH ZeD_CharacterWindow's TAB_RENDERERS and ZeD_WorldWindow's
-- WORLD_TAB_RENDERERS via the shared register() entry point. The drawing is
-- identical in both windows; only the radio discovery source
-- differs (equipped on player vs in-range world objects). Each window's
-- refresh loop writes what it found to win._radios before render() runs,
-- so render() itself only reads.
-- One thing to know: everything the mouse or the controller can press is a
-- rect the drawing stamped on win this frame (the tab strip's win._radioTabZones,
-- the face's win._radioTw.hits); the click router and the focus builder read
-- those, they never measure the layout again.
--
-- FACES: every radio is drawn as a face: the two-way sets (TwoWayFace.lua),
-- the ordinary radios, the CD player and the TVs (RtvFace.lua), or, with ZeD
-- setup's Devices row on Simple, the plain card (PlainFace.lua) over the same
-- driver. A radio or TV with no face of its own (a modded one) gets the plain
-- card as well (faceFor below). The drawn chassis card that came before the
-- faces (ON / SEEK / VOL, presets 1-8, the orange display) is gone: the
-- director, Nov 13 2026, "It shouldn't exist."
--
-- LAYER STRUCTURE INSIDE THIS FILE:
--   - The sub-page strip (ZeD.SubTabs), shared with other tabs
--   - Data discovery: buildEquippedRadios, buildWorldRadios
--   - Faces: faceFor, wantW, the fill blocks under a face, renderTwoWay (any
--     face, its footer and its scrollbar)
--   - Top-level: render (with the radios' tab strip), then the click router, the
--     wheel and the right-click, register, and the controller's focusables
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/TwoWayFace"
require "ZeD/TwoWayFull"
require "ZeD/RtvFace"
require "ZeD/PlainFace"
require "ZeD/WorldRoutes"
require "ZeD/ZeD_TabFill"

ZeD = ZeD or {}
ZeD.RadioTab = ZeD.RadioTab or {}

-- ============================================================================
-- THE SUB-PAGE STRIP (punch list 175, C4: one way to pick a sub-page, the tab strip)
-- ZeD.SubTabs.draw is the library's tab (ZeD.Molecules.drawTab) in a row, as
-- Animals (Ranch | Butcher) and Furniture draw it: the active tab open at the
-- bottom into its content, the strip's line under the others. The Radio tab
-- (one tab per radio), the Vehicle tab (one per vehicle) and the Journal (its
-- pages) pick their sub-page with it. A strip short of room closes the tabs'
-- side room up, then cuts the longer words ("..."), then shows the tabs
-- around the active one (and the controller's) only.
-- Draw-only: it hands back the tabs' rects; the caller stamps its own presses
-- and controller stops.
-- ============================================================================
ZeD.SubTabs = ZeD.SubTabs or {}
local _stTw, _stLab = {}, {}   -- per tab: its width and its words this frame (reused)
local _stOpts, _stTabOpts = {}, {}

--- Which tabs fit in avail px: first, last and each one's width and words in _stTw / _stLab.
--- items[i].label; active, focus: indexes kept on view (focus may be nil).
function ZeD.SubTabs.fit(items, avail, active, focus)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local font = T.fontF2
    local n = #items
    local gap = T.sp.tabGap
    local padX = T.sp.tabPadX
    local function total(pX, first, last, cap)
        local s = 0
        for i = first, last do
            local tw = tm:MeasureStringX(font, A.textCase(items[i].label or "")) + pX * 2
            if cap and tw > cap then tw = cap end
            s = s + tw + ((i < last) and gap or 0)
        end
        return s
    end
    if n == 0 then return 1, 0, padX end
    if total(padX, 1, n) > avail then padX = T.px(4) end
    local minW = T.px(40)
    -- the tabs shown: all, or a run round the active one (and the controller's) that fits at minW each
    local first, last = 1, n
    local most = math.max(1, math.floor((avail + gap) / (minW + gap)))
    if n > most then
        local a = math.max(1, math.min(n, active or 1))
        local f = focus and math.max(1, math.min(n, focus)) or a
        local lo, hi = math.min(a, f), math.max(a, f)
        if hi - lo + 1 > most then lo, hi = f, f end
        while hi - lo + 1 < most do
            if hi < n then hi = hi + 1 end
            if hi - lo + 1 < most and lo > 1 then lo = lo - 1 end
            if lo == 1 and hi == n then break end
        end
        first, last = lo, hi
    end
    -- the widest a tab may be (the longer words cut): the largest cap that fits
    local cap = nil
    if total(padX, first, last) > avail then
        local lo2, hi2 = minW, math.max(minW, avail)
        while hi2 - lo2 > 1 do
            local mid = math.floor((lo2 + hi2) / 2)
            if total(padX, first, last, mid) <= avail then lo2 = mid else hi2 = mid end
        end
        cap = lo2
    end
    for i = first, last do
        local s = A.textCase(items[i].label or "")
        local tw = tm:MeasureStringX(font, s) + padX * 2
        if cap and tw > cap then
            s = A.truncateText(s, font, math.max(0, cap - padX * 2))
            tw = cap
        end
        _stTw[i], _stLab[i] = tw, s
    end
    return first, last, padX
end

--- Draw the strip at (x, y), w wide: items[i] = { label, help (the help line's words on hover) };
--- active: the open one's index. opts { focusOf = function(i) -> the ZeD.Focus.mark opts or nil,
--- focus (the index the controller is on), noHover (the controller's cues on), win (the help
--- line's window), rightReserve (px kept clear at the right) }. Returns the strip's height and
--- its tabs' rects { x, y, w, h, idx } (only the tabs shown).
function ZeD.SubTabs.draw(panel, x, y, w, items, active, opts)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    opts = opts or _stOpts
    local tH = T.tabH
    local gap = T.sp.tabGap
    local left = x + T.sp.sm
    local avail = x + w - (opts.rightReserve or 0) - T.sp.sm - left
    local first, last, padX = ZeD.SubTabs.fit(items, avail, active, opts.focus)
    local zones = {}
    local tabX = left
    local activeX, activeW
    local o = _stTabOpts
    for i = first, last do
        local tw = _stTw[i]
        local isActive = (i == active)
        local hovered = (not opts.noHover) and A.mouseIn(panel, tabX, y, tw, tH)
        if hovered and items[i].help and ZeD.Help and ZeD.Help.set then ZeD.Help.set(opts.win or panel, items[i].help) end
        o.padX = padX
        o.focus = opts.focusOf and opts.focusOf(i) or nil
        M.drawTab(panel, tabX, y, _stLab[i], isActive, hovered, false, o)
        if isActive then activeX, activeW = tabX, tw end
        zones[#zones + 1] = { x = tabX, y = y, w = tw, h = tH, idx = i }
        tabX = tabX + tw + gap
    end
    -- the strip's line, around the active tab
    local ly = y + tH - T.hair
    if activeX then
        A.drawDividerH(panel, x, ly, activeX - x, true)
        A.drawDividerH(panel, activeX + activeW, ly, x + w - (activeX + activeW), true)
    else
        A.drawDividerH(panel, x, ly, w, true)
    end
    return tH, zones
end

-- ============================================================================
-- DATA DISCOVERY
-- ============================================================================

-- Lookup: PZ radio item check. Both inventory items (Radio class) and world
-- IsoWaveSignal objects expose getDeviceData(). We probe the method via
-- direct field access (Kahlua: indexing an exposed class returns the method
-- as a callable, or nil if not exposed) — avoids the "Tried to call nil"
-- log spam that pcall produces on missing methods.
local function _hasDeviceData(obj)
    if obj == nil or obj.getDeviceData == nil then return false end
    local dd = obj:getDeviceData()
    return dd ~= nil, dd
end

-- The slot a radio sits in, in the player's language. The tags themselves ("Primary",
-- "Secondary", "Back", "Floor") are ids: they key the wave cache and stay English.
function ZeD.RadioTab.locationName(tag)
    if tag == "Primary" then return ZeD.tr("UI_ZeD_Radio_LocPrimary") end
    if tag == "Secondary" then return ZeD.tr("UI_ZeD_Radio_LocSecondary") end
    if tag == "Back" then return ZeD.tr("UI_ZeD_Radio_LocBack") end
    if tag == "Floor" then return getText("ContextMenu_Floor") end
    if tag == "Carried" then return getText("IGUI_InventoryTooltip") end   -- in a bag or the inventory (WorldRoutes.lua)
    if tag == "Vehicle" then return getText("UI_optionscreen_binding_Vehicle") end   -- a car's device part (WorldRoutes.lua)
    return tag or ""
end

-- a radio's place in a tab list (by its owner: the item, the set or the part), nil when it is not there
function ZeD.RadioTab.indexOf(list, dev)
    if dev == nil then return nil end
    for i, e in ipairs(list or {}) do
        if e.radioInstance == dev then return i end
    end
    return nil
end

--- Scan the player's equipped slots for radios.
--- Mirrors vanilla ISRadioWindow's scan — hand items + back-clothing slot.
--- Returns array of entries each shaped:
---   { radioInstance, deviceData, locationTag, kind = "equipped", cacheKey }
--- locationTag is the slot's id (Primary / Secondary / Back); the drawer
--- header shows it in the player's language (locationName above).
function ZeD.RadioTab.buildEquippedRadios(playerObj)
    local out = {}
    if playerObj == nil then return out end

    local function tryAdd(item, tag)
        if item == nil then return end
        if not instanceof(item, "Radio") then return end
        local has, dd = _hasDeviceData(item)
        if not has then return end
        -- Stable cache key per equipped slot. The slot tag is unique within an
        -- equipped scan (Primary / Secondary / Back), so it's a reliable key
        -- without needing getID() (which IsoWaveSignal/Radio inheritance can
        -- omit and produce "Tried to call nil" log spam).
        out[#out + 1] = {
            radioInstance = item,
            deviceData    = dd,
            locationTag   = tag,
            kind          = "equipped",
            cacheKey      = "eq:" .. tag,
        }
    end

    tryAdd(playerObj:getPrimaryHandItem(),   "Primary")
    tryAdd(playerObj:getSecondaryHandItem(), "Secondary")
    -- Back-clothing slot — ISRadioWindow checks this so portable radios slung
    -- on the player's back register too.
    if playerObj.getClothingItem_Back then
        tryAdd(playerObj:getClothingItem_Back(), "Back")
    end
    -- a radio opened from a bag or the inventory (WorldRoutes.radio pins it): listed while it stays on the player
    local pin = ZeD.RadioTab._carried and ZeD.RadioTab._carried[playerObj:getPlayerNum()]
    if pin then
        local okC, still = pcall(function()
            local c = pin:getContainer()
            return c ~= nil and c:isInCharacterInventory(playerObj)
        end)
        if okC and still and not ZeD.RadioTab.indexOf(out, pin) then tryAdd(pin, "Carried") end
        if not (okC and still) then ZeD.RadioTab._carried[playerObj:getPlayerNum()] = nil end
    end

    return out
end

--- Scan the 3x3 grid around the player for IsoWaveSignal radios.
--- Mirrors buildWorldContainers (ZeD_WorldWindow.lua) for reach semantics:
--- canReachTo wall check + safehouse loot permission. Returns entries shaped:
---   { radioInstance, deviceData, locationTag, kind = "world", distance, cacheKey }
--- sorted by distance ascending; a device a route pinned is added at the end
--- when the scan missed it.
function ZeD.RadioTab.buildWorldRadios(playerObj)
    local out = {}
    if playerObj == nil then return out end

    local cell = getCell()
    if cell == nil then return out end

    local cx = math.floor(playerObj:getX())
    local cy = math.floor(playerObj:getY())
    local cz = math.floor(playerObj:getZ())
    local currentSq = playerObj:getCurrentSquare()

    for dy = -1, 1 do
        for dx = -1, 1 do
            local gs = cell:getGridSquare(cx + dx, cy + dy, cz)
            -- Wall-pass check: player must be able to reach the neighbor sq.
            if gs and gs ~= currentSq and currentSq then
                if not currentSq:canReachTo(gs) then gs = nil end
            end
            -- Safehouse loot permission (matches container reach).
            if gs and isClient() and SafeHouse and SafeHouse.isSafehouseAllowLoot then
                if not SafeHouse.isSafehouseAllowLoot(gs, playerObj) then
                    gs = nil
                end
            end
            if gs then
                local objs = gs:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if instanceof(o, "IsoWaveSignal") then
                            local has, dd = _hasDeviceData(o)
                            if has then
                                local distSq = dx * dx + dy * dy
                                -- Use world coordinates as the stable cache
                                -- key. IsoWaveSignal occupies a fixed tile
                                -- so x/y/z is stable for the life of the
                                -- object, and uniquely identifies it among
                                -- all radios in range.
                                local ox = math.floor(o:getX() or 0)
                                local oy = math.floor(o:getY() or 0)
                                local oz = math.floor(o:getZ() or 0)
                                out[#out + 1] = {
                                    radioInstance = o,
                                    deviceData    = dd,
                                    locationTag   = "Floor",
                                    kind          = "world",
                                    distance      = math.sqrt(distSq),
                                    cacheKey      = string.format("w:%d,%d,%d", ox, oy, oz),
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.distance < b.distance end)
    -- a device a route opened the tab on (a TV across the room, a car's device part) stays on the
    -- list while it is within the game's reach for its window (WorldRoutes.lua)
    if ZeD.WorldRoutes and ZeD.WorldRoutes.addPinned then out = ZeD.WorldRoutes.addPinned(playerObj, out) end
    return out
end

-- Helper: read a deviceData getter via field probe -- if the method isn't
-- exposed on this radio's Java class, the field is nil and we return the
-- fallback silently. Avoids the "Tried to call nil" log spam that pcall
-- triggers when a defensive call hits an unexposed method.
local function _safeGet(dd, fnName, fallback)
    if dd == nil then return fallback end
    local fn = dd[fnName]
    if fn == nil then return fallback end
    local v = fn(dd)
    if v == nil then return fallback end
    return v
end

-- the face a radio tab entry is drawn as: its driver (ZeD.TwoWay, ZeD.Rtv, or the plain card over either), plate
-- id and plate. ZeD setup's Devices row (Full or Simple): Simple draws the plain card over the same driver
-- (PlainFace.lua: ZeD.PlainFace.wrap, its own size in place of the plate). A radio or TV with no face of its own
-- (a modded one) gets the plain card in either mode, with the controls of the ordinary set it is most like
-- (ZeD.Rtv.fallbackPid: a radio the black radio's, a TV the black TV's). Nil only for an entry with no device
-- data, which the radio lists never hold.
local function _simple()
    return ZeD.PlainFace ~= nil and ZeD.Settings ~= nil and ZeD.Settings.devicesSimple ~= nil and ZeD.Settings.devicesSimple() == true
end
function ZeD.RadioTab.faceFor(entry)
    local pid, des = ZeD.TwoWay.plateFor(entry)
    if des then
        if _simple() then return ZeD.PlainFace.wrap(ZeD.TwoWay), pid, ZeD.PlainFace.des(ZeD.TwoWay, pid) end
        return ZeD.TwoWay, pid, des
    end
    pid, des = ZeD.Rtv.plateFor(entry)
    if des then
        if _simple() then return ZeD.PlainFace.wrap(ZeD.Rtv), pid, ZeD.PlainFace.des(ZeD.Rtv, pid) end
        return ZeD.Rtv, pid, des
    end
    pid = (entry and ZeD.PlainFace and ZeD.Rtv.fallbackPid) and ZeD.Rtv.fallbackPid(entry.radioInstance, entry.deviceData) or nil
    if pid then return ZeD.PlainFace.wrap(ZeD.Rtv), pid, ZeD.PlainFace.des(ZeD.Rtv, pid) end
    return nil, nil, nil
end

-- ============================================================================
-- THE TWO-WAY RADIOS
-- A radio whose device data is two-way is drawn as its own face (TwoWayFace.lua):
-- a walkie (or the ManPack) centred in a 220-wide
-- panel at the content's left edge, a ham set centred across the drawer, at the
-- plates' whole zoom; the footer names the brand and "* 2-WAY PORTABLE" / "BASE
-- SET". The header's full view button (and a click on the face away from its
-- controls) shows the face on its own (TwoWayFull.lua). The body (face and
-- footer) scrolls as one unit when the window is shorter than the face.
-- win._radioTw = { dev, pid, des, k, hits, face rect, ... } while a face of any
-- kind is shown (renderTwoWay draws the ordinary radios, the TVs and the plain
-- card the same way).
-- ============================================================================
local FULL_ICON, FOLD_ICON = "expand", "contract"   -- ZeD pixel icons

local function _twFocusId(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.liveZone and Focus.liveElement) then return nil end
    local fz = Focus.liveZone(win)
    local zn = fz and fz.zone
    if zn ~= "charTabContent" and zn ~= "worldTabContent" then return nil end
    local el = Focus.liveElement(win)
    return el and el.id or nil
end

-- the radios' tab strip (ZeD.SubTabs): its opts, the tab the controller is on and the mark's opts (reused each frame)
local _browseMark = {}
local _stripFocus = { idx = nil }
local _stripOpts = { focusOf = function(i) if _stripFocus.idx == i then return _browseMark end return nil end }

-- the controller's cues on: the pointer's hover washes stay off
local function _cuesOn()
    local F = ZeD.Input and ZeD.Input.Focus
    return (F and F.cuesVisible and F.cuesVisible()) and true or false
end

-- a radio's name: the set's own (its mod prefix cut; the engine's title case kept, it is an item's name)
local function _radioName(e)
    local n = e and e.deviceData and _safeGet(e.deviceData, "getDeviceName", "") or ""
    if type(n) ~= "string" or n == "" then return getText("IGUI_ItemType_Radio") end
    return n:match("^[^%.]+%.(.+)$") or n
end

local _tabItems = {}
--- The radios' tabs: each radio's name; two of the same name carry where each is ("Walkie Talkie (Primary)"),
--- or their place in the list when that is the same too. The help line names the radio and where it is.
function ZeD.RadioTab.tabItems(radios)
    local seen = {}
    for _, e in ipairs(radios or {}) do
        local n = _radioName(e)
        seen[n] = (seen[n] or 0) + 1
    end
    local locSeen = {}
    for i, e in ipairs(radios or {}) do
        local n = _radioName(e)
        local loc = ZeD.RadioTab.locationName(e.locationTag)
        local k = n .. "|" .. loc
        locSeen[k] = (locSeen[k] or 0) + 1
    end
    for i, e in ipairs(radios or {}) do
        local n = _radioName(e)
        local loc = ZeD.RadioTab.locationName(e.locationTag)
        local label = n
        if seen[n] > 1 then
            label = n .. " (" .. ((locSeen[n .. "|" .. loc] > 1 or loc == "") and tostring(i) or loc) .. ")"
        end
        local it = _tabItems[i] or {}
        _tabItems[i] = it
        it.label = label
        it.help = (loc ~= "") and (n .. " | " .. loc) or n
    end
    for i = #_tabItems, #(radios or {}) + 1, -1 do _tabItems[i] = nil end
    return _tabItems
end

--- Show the radio at idx (a tab's press, or A on it).
function ZeD.RadioTab.selectRadio(win, i)
    local r = win and win._radios
    if not (r and r[i]) then return end
    win._radioIdx = i
    win._radioFollow = r[i].radioInstance
end

--- The width (screen px) the radio's face needs, nil when the tab is not on one; the window gives it the half card
--- or the full card, whichever holds that (limit: the widest card the window lets the drawer be). A walkie needs
--- its panel, the face and its margins at the plates' whole zoom — only as wide as the graphic, and a card
--- is always the half card or the full card: the half card wherever one of its widths fits it,
--- else the 220 panel (the full card). A ham set needs its own width. Where
--- that is more than limit, the set's narrow face is drawn (render below), which needs a walkie's panel.
--- The ordinary radios and the CD player: the half card wherever one of their widths fits it, else the
--- full card (the hand-built radio at 0.75 and 1.5); the TVs: the full card (RtvFace.wantW).
function ZeD.RadioTab.wantW(win, base, limit)
    local r = win and win._radios and win._radios[win._radioIdx or 1]
    local drv, pid, des = ZeD.RadioTab.faceFor(r)
    if not des then return nil end
    if drv.plain then return drv.wantW(pid, des) end      -- the plain card: the half card, a TV's the full card
    local T, Sc = ZeD.T, ZeD.Scale
    local k = ZeD.Px.k((Sc and Sc.root and Sc.root()) or 1)
    if drv == ZeD.Rtv then return ZeD.Rtv.wantW(pid, des, k, limit) end
    local panel = ZeD.TwoWay.PANEL_W * k + T.sp.scrollbarW
    if des.w < ZeD.TwoWay.PANEL_W then
        local _, _, pw = ZeD.TwoWay.halfFace(pid, k)
        if pw then return pw * k + T.sp.scrollbarW end
        return panel
    end
    local wide = des.w * k + T.sp.scrollbarW
    if limit and wide > limit and ZeD.TwoWay.narrowOf(pid) then return panel end
    return wide
end

-- the full view button at the header's right end: an icon button (square, the standard
-- button height) that names itself after the shared pause; returns its rect
local _fullOpts = {}
local function _drawFullButton(panel, win, x, y, w, headerH, open, fid)
    local T = ZeD.T
    local bs = T.buttonH
    local bx, by = x + w - T.px(10) - bs, y + math.floor((headerH - bs) / 2)
    local o = _fullOpts
    o.hover = ZeD.Atoms.mouseIn(panel, bx, by, bs, bs)
    o.focus = (fid == "radio:full") and { win = win } or nil
    o.win = win
    o.hint = ZeD.tr(open and "UI_ZeD_Radio_CloseFullView" or "UI_ZeD_Radio_FullView")
    o.id = "radio:fullbtn"
    o.help = o.hint
    ZeD.Molecules.drawIconButton(panel, bx, by, bs, open and FOLD_ICON or FULL_ICON, o)
    return { x = bx, y = by, w = bs, h = bs }
end

-- where a control's list opens (screen px): under the control
local function _menuAt(tw, h)
    local p = tw and tw.panel
    if not (p and h) then return nil end
    return { x = p:getAbsoluteX() + h.x, y = p:getAbsoluteY() + h.y + h.h }
end
local function _hitById(tw, id)
    for _, hh in ipairs((tw and tw.hits) or {}) do if hh.id == id then return hh end end
    return nil
end
ZeD.RadioTab._menuAt, ZeD.RadioTab._hitById = _menuAt, _hitById

-- ============================================================================
-- UNDER THE FACE: Channels, Heard, Power
-- ZeD_TabFill blocks under any face, in both windows: the set's stored channels (a
-- row tunes to it, the one tuned in carries the wash), the last lines it showed
-- (RtvFace keeps them per set, from vanilla's OnDeviceText) and its power: the
-- battery or the mains, spare batteries on you, the headphones, the frequency range
-- (not on a TV) and, on a two-way set, its range and microphone. Read twice a
-- second (tw.fill); drawn each frame.
-- ============================================================================

local function _fillGet(o, m, ...)
    local f = o and o[m]
    if not f then return nil end
    local ok, v = pcall(f, o, ...)
    if ok then return v end
    return nil
end

-- a stored channel's value on its row: a radio's frequency the way the game's own radio
-- window lists its presets, one decimal on every set (a walkie's face reads "098.400", its
-- row "98.4"); a TV's channel number, as its dial and plain card show it ("03"), since a TV
-- has no frequency to show
local function _channelValue(freq, tv)
    if not tv then return ZeD.RadioOps.freqText(freq, false) end
    local s = ZeD.Rtv.stopOf and ZeD.Rtv.stopOf(freq)
    return s and string.format("%02d", s.number) or nil
end

-- the rows of the three blocks for this set, from the game
local function _radioFillRead(win, dev)
    local T, O = ZeD.T, ZeD.RadioOps
    local st = ZeD.Rtv and ZeD.Rtv.read and ZeD.Rtv.read(dev)
    if not (st and O) then return nil end
    local dd = st.dd
    local twoWay = _fillGet(dd, "getIsTwoWay") == true
    local tv = _fillGet(dd, "getIsTelevision") == true
    local d = { presets = {}, heard = {}, power = {} }
    for i, p in ipairs(st.presets or {}) do
        local name = (p.name and p.name ~= "") and p.name or O.chanName(p.freq) or getText("IGUI_RadioUknownChannel")
        local idx = i
        d.presets[i] = { id = "fill:radio:ch:" .. i, label = ZeD.tr("UI_ZeD_Plain_ChannelName", i, name), cut = true,
                         value = _channelValue(p.freq, tv), sel = (i == st.presetIdx),
                         fn = function() O.recall(win._playerObj, dev, idx) end }
    end
    local lines = ZeD.Rtv.heardLines and ZeD.Rtv.heardLines(st) or nil
    for i, l in ipairs(lines or {}) do
        d.heard[i] = { id = "fill:radio:heard:" .. i, label = l, read = true }
    end
    -- nothing shown yet on this channel this session: the block stays, with one dim line saying so (an empty
    -- block drew nothing, and the review read that as Heard missing)
    local nHeard = #d.heard
    d.heardN = nHeard
    if nHeard == 0 then
        d.heard[1] = { id = "fill:radio:heard:none", label = ZeD.tr("UI_ZeD_Radio_NothingHeard"), dim = true, read = true }
    end
    local pw = d.power
    if st.battery then
        if st.hasBattery then
            pw[#pw + 1] = { id = "fill:radio:batt", label = getText("Tooltip_Dashboard_Battery"),
                            value = math.floor((st.charge or 0) * 100 + 0.5) .. "%", bar = st.charge or 0,
                            barColor = ZeD.Atoms.statusColor(st.charge or 0) }
        else
            pw[#pw + 1] = { id = "fill:radio:batt", dot = T.danger, label = ZeD.tr("UI_ZeD_Plain_NoBattery") }
        end
        local inv = win._playerObj and win._playerObj:getInventory()
        local n = inv and _fillGet(inv, "getCountTypeRecurse", "Base.Battery") or 0
        if n > 0 then
            -- (Spare, not the item's name: the row above already says Battery, QA's review, Nov 11 2026)
            pw[#pw + 1] = { id = "fill:radio:spare", label = ZeD.tr("UI_ZeD_Radio_Spare"), value = "x" .. n }
        else
            pw[#pw + 1] = { id = "fill:radio:spare", dot = T.textDim, hollow = true, label = ZeD.tr("UI_ZeD_Radio_NoBatteries") }
        end
    else
        pw[#pw + 1] = { id = "fill:radio:mains", dot = st.grid and T.positive or T.danger,
                        label = getText(st.grid and "IGUI_RadioPowerNearby" or "IGUI_RadioRequiresPowerNearby") }
    end
    if not twoWay then
        pw[#pw + 1] = { id = "fill:radio:phones", label = ZeD.tr("UI_ZeD_Plain_Headphones"),
                        value = ZeD.tr(st.phones and "UI_ZeD_Plain_PhonesIn" or "UI_ZeD_Plain_PhonesOut") }
    end
    -- (a TV has channels, not a frequency band: the game's own window shows it no range either)
    if not tv then
        pw[#pw + 1] = { id = "fill:radio:range", label = getText("IGUI_RadioFreqRange"),
                        value = ZeD.tr("UI_ZeD_Plain_MHz", O.freqText(st.min, false) .. "-" .. O.freqText(st.max, false)) }
    end
    if twoWay then
        local tr = _fillGet(dd, "getTransmitRange") or 0
        pw[#pw + 1] = { id = "fill:radio:tx", label = getText("IGUI_RadioStrength"), value = tostring(tr) .. " " .. getText("IGUI_RadioMeter") }
        local muted = _fillGet(dd, "getMicIsMuted") == true
        pw[#pw + 1] = { id = "fill:radio:mic", label = getText("IGUI_RadioMicrophone"), value = getText(muted and "IGUI_RadioNo" or "IGUI_RadioYes") }
    end
    for _, r in ipairs(pw) do r.read = true end
    return d
end

local _radioFillOpts = {}
--- The three blocks under a face from (x, y), w wide; panel nil only measures. Returns their height (0 with none).
function ZeD.RadioTab.renderFill(panel, win, tw, x, y, w)
    local F = ZeD.TabFill
    if not (F and tw and tw.dev) then return 0 end
    local now = getTimestampMs()
    if not tw.fill or not tw.fillAt or now - tw.fillAt >= 500 or now < tw.fillAt then
        tw.fill, tw.fillAt = _radioFillRead(win, tw.dev), now
    end
    local d = tw.fill
    if not d then return 0 end
    _radioFillOpts.view = tw.view
    -- (Channels in both windows: one word for the set's stored channels)
    local h = F.block(panel, win, "radio", "channels", x, y, w,
        ZeD.tr("UI_ZeD_Radio_Channels"), #d.presets, d.presets, _radioFillOpts)
    h = h + F.block(panel, win, "radio", "heard", x, y + h, w, ZeD.tr("UI_ZeD_Radio_Heard"), d.heardN or #d.heard, d.heard, _radioFillOpts)
    h = h + F.block(panel, win, "radio", "power", x, y + h, w, getText("IGUI_RadioPower"), nil, d.power, _radioFillOpts)
    return h
end

-- the face, its footer and the scrollbar under the header (y, h: the body). drv: the face's driver, ZeD.TwoWay or
-- ZeD.Rtv (the ordinary radios and the TVs, which have no footer: the brand is on the face)
local function renderTwoWay(panel, win, x, y, w, h, current, pid, des, drv)
    local T = ZeD.T
    local TW = drv or ZeD.TwoWay
    local Sc = ZeD.Scale
    local sbW = T.sp.scrollbarW
    -- the plates' whole zoom (a whole step down only when the drawer cannot hold the face; it never flips with the scrollbar)
    -- (the plain card, PlainFace.lua: no zoom and no margin; the drawer's width and as tall as its rows)
    local plain = TW.plain == true
    local k = plain and 1 or ZeD.Px.kFit((Sc and Sc.root and Sc.root()) or 1, TW.slotW(des), w - sbW)
    local pad = TW.PAD * k
    local footH = TW.footer and T.px(22) or 0
    local faceH = plain and TW.height(current.radioInstance, pid, w - sbW) or des.h * k
    -- the fill blocks under the face and its footer (Channels, Heard, Power), measured with no panel
    local tw0 = win._radioTw
    local fillTw = (tw0 and tw0.dev == current.radioInstance) and tw0 or nil
    local fillH = fillTw and ZeD.RadioTab.renderFill(nil, win, fillTw, 0, 0, w - sbW - T.px(16)) or 0
    if fillH > 0 then fillH = fillH + T.px(6) end
    local contentH = pad + faceH + pad + footH + fillH
    local scroll = win._radioScroll
    if not scroll then scroll = ZeD_ScrollbarState:new(); win._radioScroll = scroll end
    local needs = contentH > h
    scroll.visible = needs
    local cw = needs and (w - sbW) or w
    local off = 0
    if needs then
        scroll.x, scroll.y, scroll.height = x + w - sbW, y, h
        scroll:setBarSize(h / contentH)
        -- (the drawer passes the radio tab its presses only: the drag and the release are read here)
        if scroll.dragging and isMouseButtonDown(0) then scroll:handleMouseMove(panel:getMouseY() - scroll.y)
        elseif (scroll.dragging or scroll.upPressed or scroll.downPressed) and not isMouseButtonDown(0) then scroll:handleMouseUp() end
        off = math.floor(scroll.scrollPos * (contentH - h))
    else
        scroll:setScrollPos(0)
    end
    -- centred across the drawer: a walkie's drawer is its own panel, a ham set's the full drawer
    local faceW = plain and cw or des.w * k
    local fx = x + math.floor((cw - faceW) / 2)
    local fy0 = y + pad                                       -- the face's top, scrolled to the top
    local tw = win._radioTw
    local dev = current.radioInstance
    if not (tw and tw.dev == dev) then tw = { dev = dev }; win._radioTw = tw end
    tw.drv, tw.panel = TW, panel
    -- the controller: the focused control kept in view
    local fid = _twFocusId(win)
    local fctl = fid and fid:match("^radio:tw:(.+)$")
    if needs and fctl and tw.follow ~= fid then
        tw.follow = fid
        for _, hh in ipairs(tw.hits or {}) do
            if hh.id == fctl then
                local cy = hh.y - (tw.fy or fy0) + pad                  -- its top within the body
                local newOff = off
                if cy < off then newOff = cy elseif cy + hh.h > off + h then newOff = cy + hh.h - h end
                newOff = math.max(0, math.min(contentH - h, newOff))
                if newOff ~= off then scroll:setScrollPos(newOff / (contentH - h)); off = newOff end
            end
        end
    end
    -- a fill row the controller is on, kept whole in view (last frame's zones)
    if needs and fid and fid:sub(1, 10) == "fill:radio" and tw.fillFollow ~= fid then
        tw.fillFollow = fid
        local n = ZeD.TabFill.follow(win, "radio", fid, y, h, off, contentH - h)
        if n then scroll:setScrollPos(n / (contentH - h)); off = n end
    end
    if not (fid and fid:sub(1, 10) == "fill:radio") then tw.fillFollow = nil end
    local fy = fy0 - off
    panel:setStencilRect(x, y, cw, h)
    -- a held key (the mouse): a short press acts on the release, a long one names / stores (MEM, the army set's 1..6)
    local chr = win._playerObj
    local press = tw.press
    if press and not press.fired then
        if isMouseButtonDown(0) then TW.holdTick(press, chr, dev, nil)
        else
            press.fired = true
            TW.press(chr, dev, press.id, nil, _menuAt(tw, _hitById(tw, press.id)))
        end
    end
    if press and press.fired and not isMouseButtonDown(0) then tw.press = nil end
    local hov = TW.hitAt(tw.hits, panel:getMouseX(), panel:getMouseY())
    local hits = TW.drawFace(panel, fx, fy, k, { dev = dev, pid = pid, des = des, focusId = fctl,
        hoverId = (not fctl) and hov and hov.id or nil, pressId = tw.press and tw.press.id or nil,
        w = faceW, minH = (needs or fillH > 0) and 0 or h, win = win })
    -- the footer: at the drawer's foot, or under the face when the body scrolls or the fill blocks follow it
    local footY = fy + faceH + pad
    if TW.footer then
        if fillH == 0 then footY = math.max(fy + des.h * k + pad, y + h - footH) end
        TW.footer(panel, x, footY, cw, footH, pid, _safeGet(current.deviceData, "getIsHighTier", false))
    end
    -- the fill blocks, under the footer
    tw.view = { x = x, y = y, w = cw, h = h }
    ZeD.TabFill.begin(win, "radio")
    if fillH > 0 then ZeD.RadioTab.renderFill(panel, win, tw, x + T.px(8), footY + footH + T.px(6), cw - T.px(16)) end
    panel:clearStencilRect()
    if needs then scroll:draw(panel) end
    tw.pid, tw.des, tw.k, tw.hits, tw.fy = pid, des, k, hits, fy
    tw.face = { x = fx, y = fy, w = faceW, h = faceH }
    tw.view = { x = x, y = y, w = cw, h = h }
end

-- ============================================================================
-- TOP-LEVEL TAB RENDERER
-- ============================================================================

--- Render the radio tab content into the drawer.
--- @param panel  The drawer ISPanel
--- @param win    The window owning the drawer (Char or World)
--- @param x, y   Top-left of the tab content area in panel-local coords
--- @param w, h   Available drawing region
function ZeD.RadioTab.render(panel, win, x, y, w, h)
    local T = ZeD.T
    if T == nil then return end

    local radios = win._radios or {}

    -- Empty state — one line, no header.
    if #radios == 0 then
        -- drop any stale gamepad focus id so the seed gate fires fresh
        -- next time a radio is equipped (the gate only writes on nil).
        win._gpFocusedRadioCtl = nil
        -- one dim F2 line at the list's text inset, a full sentence (no header here: 10u from the top)
        ZeD.Molecules.drawEmptyLine(panel, x + T.px(10), y + T.px(10), w - T.px(20), ZeD.tr("UI_ZeD_Radio_None"))
        return
    end

    -- the tab stays on the radio it was opened on or browsed to while the list re-sorts by distance
    if win._radioFollow then
        local at = ZeD.RadioTab.indexOf(radios, win._radioFollow)
        if at then win._radioIdx = at else win._radioFollow = nil end
    end

    -- Clamp index defensively (window refresh may have shrunk the list mid-frame).
    local idx = win._radioIdx or 1
    if idx < 1 then idx = 1 end
    if idx > #radios then idx = #radios end
    win._radioIdx = idx

    local current = radios[idx]

    -- Standard ZeD drawer-header strip height — sourced from the spacing token.
    local headerH = T.stripH   -- row 1
    -- a radio with a face: its own face (renderTwoWay above); a two-way set's full view button in the header
    local fDrv, twPid, twDes = ZeD.RadioTab.faceFor(current)
    local isTw = fDrv == ZeD.TwoWay
    if not twDes then win._radioTw, win._radioFullZone = nil, nil end
    if not isTw then win._radioFullZone = nil end
    -- the width that fills the card: a walkie's for the half card
    -- (the drawer is that card wherever one fits; centred in the drawer, its margins its own); a ham set's for
    -- the drawer as a machine plate's. A ham set the tab cannot hold at the plates' whole zoom: its narrow face
    -- (the drawer is then a walkie's width). The ordinary radios and the TVs the same way (RtvFace.pickFace).
    if twDes and not fDrv.plain then
        local Sc = ZeD.Scale
        local k0 = ZeD.Px.k((Sc and Sc.root and Sc.root()) or 1)
        if not isTw then
            twPid, twDes = ZeD.Rtv.pickFace(twPid, w - T.sp.scrollbarW, k0)
        elseif twDes.w < ZeD.TwoWay.PANEL_W then
            local hPid, hDes = ZeD.TwoWay.halfFace(twPid, k0)
            if hDes then twPid, twDes = hPid, hDes end
        else
            local fPid, fw = ZeD.Px.pickWidth(twPid, w - T.sp.scrollbarW, k0)
            local nPid, nDes = ZeD.TwoWay.narrowOf(twPid)
            if fw then twPid, twDes = fPid, ZeD.PhysPx.plates[fPid]
            elseif nDes and twDes.w * k0 > w - T.sp.scrollbarW then twPid, twDes = nPid, nDes end
        end
    end
    -- 1. The radios' tab strip (punch list 175, C4: a tab per radio, as Animals picks Ranch or Butcher), in row 1's
    -- height and at its foot so the face keeps its place; a two-way set's full view button at its right. A tab's
    -- press (or A on it) shows that radio; the pointer on it names the radio and where it is in the help line.
    -- (the button sits 10 from the right edge (_drawFullButton): the strip keeps clear of all of it and 4 more, so a press
    -- on the button's left edge is the button's, not the strip's; QA Nov 13, twoway)
    local fullW = isTw and (T.buttonH + T.px(14)) or 0
    local items = ZeD.RadioTab.tabItems(radios)
    local hfid = _twFocusId(win)
    local fIdx = hfid and tonumber(hfid:match("^radio:tab:(%d+)$") or "") or nil
    _stripOpts.win, _stripOpts.focus = win, fIdx
    _stripOpts.rightReserve = (twDes and isTw) and fullW or 0
    _stripOpts.noHover = _cuesOn()
    _stripFocus.idx = fIdx
    _browseMark.win = win
    local _, tabZones = ZeD.SubTabs.draw(panel, x, y + headerH - T.tabH, w, items, idx, _stripOpts)
    win._radioTabZones = tabZones
    -- (the zone under row 1's strip: a press there that misses a tab does nothing)
    win._radioStripZone = { x = x, y = y, w = w - _stripOpts.rightReserve, h = headerH }

    -- 2. Below the header: the face, or the plain card (faceFor gives one for every radio with device data)
    if twDes then
        if isTw then
            local pn = win._playerObj and win._playerObj:getPlayerNum() or 0
            local open = ZeD.TwoWayFull.showing(pn) == current.radioInstance
            win._radioFullZone = _drawFullButton(panel, win, x, y, w, headerH, open, _twFocusId(win))
        end
        -- (its clip is set and cleared once, as every tab's: a clip set again here outlived the frame's drawer and cut
        -- off what drew after it, the full view among them)
        renderTwoWay(panel, win, x, y + headerH, w, h - headerH, current, twPid, twDes, fDrv)
    end
end

-- ============================================================================
-- CLICK HANDLER
-- ============================================================================

-- Hit-test helper: true when (x, y) lies inside the zone (no zone: false).
local function _hitZone(zone, x, y)
    if not zone then return false end
    return x >= zone.x and x < zone.x + zone.w
       and y >= zone.y and y < zone.y + zone.h
end

-- ----------------- Action functions -----------------

local function _browsePrev(win)
    local n = (win._radios and #win._radios) or 0
    if n <= 1 then return end
    local idx = (win._radioIdx or 1) - 1
    if idx < 1 then idx = n end
    win._radioIdx = idx
    win._radioFollow = win._radios[idx] and win._radios[idx].radioInstance or nil
end

local function _browseNext(win)
    local n = (win._radios and #win._radios) or 0
    if n <= 1 then return end
    local idx = (win._radioIdx or 1) + 1
    if idx > n then idx = 1 end
    win._radioIdx = idx
    win._radioFollow = win._radios[idx] and win._radios[idx].radioInstance or nil
end

--- Click router — called from each window's drawer.onMouseDown when the
--- active tab is "radio". Coordinates are panel-local (relative to the drawer).
--- Returns true when the click was the tab's.
function ZeD.RadioTab.onClick(win, x, y)
    if win == nil then return false end

    -- The radios' tab strip: a tab shows its radio; the rest of the strip takes the press too (nothing under it)
    for _, z in ipairs(win._radioTabZones or {}) do
        if _hitZone(z, x, y) then ZeD.RadioTab.selectRadio(win, z.idx); return true end
    end
    if _hitZone(win._radioStripZone, x, y) then return true end

    -- a face: the full view button (two-way sets), the scrollbar, the face's controls; a click on a two-way face away
    -- from them opens full view
    local tw = win._radioTw
    local cur = win._radios and win._radios[win._radioIdx or 1]
    if tw and cur and cur.radioInstance == tw.dev then
        local TW, chr = tw.drv or ZeD.TwoWay, win._playerObj
        local isTw = TW == ZeD.TwoWay
        if isTw and _hitZone(win._radioFullZone, x, y) then ZeD.TwoWayFull.toggle(chr, tw.dev, win); return true end
        local sc = win._radioScroll
        if sc and sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
            sc:handleMouseDown(y - sc.y); return true
        end
        if not _hitZone(tw.view, x, y) then return true end
        -- a fill block's head or row under the face
        if ZeD.TabFill.onClick(win, "radio", x, y) then return true end
        local h = TW.hitAt(tw.hits, x, y)
        if h then
            -- (a key that opens a list, as a held one, acts on the release: RtvFace.onRelease)
            if (TW.onRelease or TW.holdable)(h.id) then tw.press = { id = h.id, t0 = getTimestampMs(), fired = false }
            elseif h.knob then TW.press(chr, tw.dev, h.id, x - (h.x + h.w / 2), _menuAt(tw, h))
            else
                tw.press = { id = h.id, t0 = getTimestampMs(), fired = true }    -- shaded while held; it acts on the press
                TW.press(chr, tw.dev, h.id, nil, _menuAt(tw, h))
            end
            return true
        end
        if isTw and _hitZone(tw.face, x, y) then ZeD.TwoWayFull.open(chr, tw.dev, win) end
        return true
    end

    return false
end

-- the D-pad or the wheel turning a knob: held or spun, the tuning runs faster (s = { t, streak })
local function _turnStreak(s, gap)
    local t = getTimestampMs()
    if t - s.t < gap then s.streak = s.streak + 1 else s.streak = 0 end
    s.t = t
    return s.streak
end

--- The mouse wheel over a face (both windows' drawers ask while the radio tab is up): the knob under the
--- pointer turns, anywhere else the body scrolls. Returns true when it used the wheel.
function ZeD.RadioTab.onWheel(win, del, x, y)
    -- over the radios' tab strip: the next or the previous radio
    if win and _hitZone(win._radioStripZone, x, y) then
        if del > 0 then _browseNext(win) else _browsePrev(win) end
        return true
    end
    local tw = win and win._radioTw
    if not tw then return false end
    local TW = tw.drv or ZeD.TwoWay
    local h = _hitZone(tw.view, x, y) and TW.hitAt(tw.hits, x, y) or nil
    if h and h.knob then
        win._radioWheel = win._radioWheel or { t = 0, streak = 0 }
        local n = _turnStreak(win._radioWheel, 160)   -- (a brisk hand spins about 10 notches a second: a 110 ms gap sat right on it)
        local mult = (h.id == "tune") and TW.turnMult(tw.pid, n) or 1
        TW.turn(win._playerObj, tw.dev, h.id, del > 0 and -1 or 1, mult)
        return true
    end
    local sc = win._radioScroll
    if sc and sc.visible then sc:handleMouseWheel(del); return true end
    return false
end

--- A right-click on a face's control: its second meaning (MEM names, a preset key stores, a knob
--- turns down). Returns true when it was on the face.
function ZeD.RadioTab.onRightClick(win, x, y)
    local tw = win and win._radioTw
    if not tw then return false end
    local TW = tw.drv or ZeD.TwoWay
    local h = _hitZone(tw.view, x, y) and TW.hitAt(tw.hits, x, y) or nil
    if h then TW.secondary(win._playerObj, tw.dev, h.id, nil) end
    return h ~= nil
end

--- Register the radio tab into a tab-renderer dispatch table.
--- Called by both ZeD_CharacterWindow and ZeD_WorldWindow at module-load time.
function ZeD.RadioTab.register(dispatchTable)
    dispatchTable["radio"] = ZeD.RadioTab.render
end

-- ============================================================================
-- FOCUSABLE BUILDER — ring elements for the host window's tab-content
-- ============================================================================
-- Called each frame from the per-window panel-focusable dispatcher
-- (_buildPanelFocusables in Char, _buildWorldPanelFocusables in World) when
-- the Radio tab is active. Returns the face's controls (or the plain card's) in
-- the order its builder below gives, then the radios' tabs and the fill blocks
-- under the face. Mouse and gamepad share the rects the face stamped this frame
-- (win._radioTw.hits, win._radioTabZones), so builder and render stay in step.

-- The radios' tabs as stops ("radio:tab:<n>"; only with more than one radio): A shows that radio. The focus id
-- left for the old radio goes (its preset count and CD may differ from the new one's).
local function _tabActivate(w, el) ZeD.RadioTab.selectRadio(w, el.radioIdx); w._gpFocusedRadioCtl = nil end
local function _tabFocus(w, el) w._gpFocusedRadioCtl = el.id end
local function _addTabStops(win, elements)
    local zs = win._radioTabZones
    if not (zs and win._radios and #win._radios > 1) then return end
    for _, z in ipairs(zs) do
        elements[#elements + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = "radio:tab:" .. z.idx, radioIdx = z.idx,
            onFocus = _tabFocus, onActivate = _tabActivate }
    end
end

-- the fill blocks' heads and rows under a face (ZeD_TabFill): a channel row tunes to it on A, the rest read
local function _addFillStops(win, elements)
    local tw = win._radioTw
    local F = ZeD.TabFill
    if not (F and tw and tw.view) then return end
    local onFocus = function(w, e) w._gpFocusedRadioCtl = e.id end
    for _, el in ipairs(F.focusables(win, "radio", tw.view)) do
        el.onFocus = onFocus
        elements[#elements + 1] = el
    end
end

-- An ordinary radio's or a TV's face: its controls first, power first (the pad rule: focus lands on
-- the primary control), then the rest in reading order, then the radios'
-- tabs. A presses (a list opens under the key, and the focus comes back to the key when it closes), held (or
-- X) a preset stores; up / down on a knob turns it, left / right walk on. The focus stays on the key it pressed.
local function _rtvFocusables(win, tw)
    local R = ZeD.Rtv
    local dev = tw.dev
    local elements = {}
    local onFocus = function(w, e) w._gpFocusedRadioCtl = e.id end
    for _, h in ipairs(R.focusOrder(tw.hits, tw.k)) do
        local id = h.id
        local el = { x = h.x, y = h.y, w = h.w, h = h.h, id = "radio:tw:" .. id, onFocus = onFocus }
        if h.knob then
            if id == "volpwr" then el.onActivate = function(w) R.press(w._playerObj, dev, "volpwr") end end
            el.onDpadDir = function(w, e, dir)
                if dir ~= "up" and dir ~= "down" then return false end
                w._radioPadTurn = w._radioPadTurn or { t = 0, streak = 0 }
                local n = _turnStreak(w._radioPadTurn, 260)
                R.turn(w._playerObj, dev, id, dir == "up" and 1 or -1, (id == "tune") and R.turnMult(tw.pid, n) or 1)
                return true
            end
        else
            el.onActivate = function(w)
                local t = w._radioTw
                R.press(w._playerObj, dev, id, nil, _menuAt(t, _hitById(t, id)))
            end
            if R.holdable(id) then
                el.onHoldActivate = function(w) R.secondary(w._playerObj, dev, id) end
                el.onContextMenu = function(w) R.secondary(w._playerObj, dev, id) end
            end
        end
        elements[#elements + 1] = el
    end
    _addTabStops(win, elements)
    _addFillStops(win, elements)
    if elements[1] and win._gpFocusedRadioCtl == nil then win._gpFocusedRadioCtl = elements[1].id end
    return elements
end

-- The plain card (PlainFace.lua: Devices on Simple, or a radio with no face of its own): its controls in the order it draws them (the face's order: power
-- first, top to bottom, then the footer band), then the radios' tabs. A presses (a list opens under the key);
-- held (or X) a preset key stores and MEM names. A stepper is one stop: left / right turn it (the tuning faster
-- while held), up / down move on, since the card is a column.
local function _plainFocusables(win, tw)
    local D = tw.drv
    local dev = tw.dev
    local elements = {}
    local onFocus = function(w, e) w._gpFocusedRadioCtl = e.id end
    for _, h in ipairs(D.focusOrder(tw.hits)) do
        local id = h.id
        local el = { x = h.x, y = h.y, w = h.w, h = h.h, id = "radio:tw:" .. id, onFocus = onFocus }
        if h.knob then
            el.onDpadDir = function(w, e, dir)
                if dir ~= "left" and dir ~= "right" then return false end
                w._radioPadTurn = w._radioPadTurn or { t = 0, streak = 0 }
                local n = _turnStreak(w._radioPadTurn, 260)
                D.turn(w._playerObj, dev, id, dir == "right" and 1 or -1, (id == "tune") and D.turnMult(tw.pid, n) or 1)
                return true
            end
        else
            el.onActivate = function(w)
                local t = w._radioTw
                D.press(w._playerObj, dev, id, nil, _menuAt(t, _hitById(t, id)))
            end
            if D.holdable(id) then
                el.onHoldActivate = function(w) D.secondary(w._playerObj, dev, id, nil) end
                el.onContextMenu = function(w) D.secondary(w._playerObj, dev, id, nil) end
            end
        end
        elements[#elements + 1] = el
    end
    _addTabStops(win, elements)
    _addFillStops(win, elements)
    if elements[1] and win._gpFocusedRadioCtl == nil then win._gpFocusedRadioCtl = elements[1].id end
    return elements
end

--- The controller's stops on the radio tab (both windows call it while the tab is up): the plain card's, an
--- ordinary radio's or a TV's face, or a two-way face; before the tab has drawn one, the radios' tabs only.
function ZeD.RadioTab.buildFocusables(win)
    if not win then return {} end
    local rtw = win._radioTw
    local rcur = win._radios and win._radios[win._radioIdx or 1]
    -- the plain card (Devices on Simple, or a radio with no face): its rows top to bottom, then its footer band (above)
    if rtw and rtw.drv and rtw.drv.plain and rcur and rcur.radioInstance == rtw.dev and rtw.hits then
        return _plainFocusables(win, rtw)
    end
    -- an ordinary radio's or a TV's face (above)
    if rtw and rtw.drv == ZeD.Rtv and rcur and rcur.radioInstance == rtw.dev and rtw.hits then
        return _rtvFocusables(win, rtw)
    end
    local elements = {}

    -- Append helper: a rect not stamped this frame (the tab not drawn yet) adds no stop.
    local function addZone(z, id, onAct)
        if z == nil or (z.w or 0) <= 0 then return end
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h, id = id,
            onFocus    = function(w, el) w._gpFocusedRadioCtl = el.id end,
            onActivate = onAct,
        }
    end

    -- ---- The radios' tab strip (a tab per radio; with one radio there is none to pick) ----
    _addTabStops(win, elements)

    -- ---- A two-way face: the full view button, then the face's controls in reading order. A presses, held (or
    -- X) MEM names and the army set's 1..6 store; up / down on a knob turns it, left / right walk on.
    local tw = win._radioTw
    local cur = win._radios and win._radios[win._radioIdx or 1]
    if tw and cur and cur.radioInstance == tw.dev and tw.hits then
        local TW = ZeD.TwoWay
        local dev = tw.dev
        addZone(win._radioFullZone, "radio:full", function(w) ZeD.TwoWayFull.toggle(w._playerObj, dev, w) end)
        for _, h in ipairs(TW.readingOrder(tw.hits, tw.k)) do
            local id = h.id
            local el = { x = h.x, y = h.y, w = h.w, h = h.h, id = "radio:tw:" .. id,
                         onFocus = function(w, e) w._gpFocusedRadioCtl = e.id end }
            if h.knob then
                if id == "vol" then el.onActivate = function(w) TW.press(w._playerObj, dev, "vol") end end
                el.onDpadDir = function(w, e, dir)
                    if dir ~= "up" and dir ~= "down" then return false end
                    w._radioPadTurn = w._radioPadTurn or { t = 0, streak = 0 }
                    local n = _turnStreak(w._radioPadTurn, 260)
                    TW.turn(w._playerObj, dev, id, dir == "up" and 1 or -1, (id == "tune") and TW.turnMult(tw.pid, n) or 1)
                    return true
                end
            else
                el.onActivate = function(w) TW.press(w._playerObj, dev, id) end
                if TW.holdable(id) then
                    el.onHoldActivate = function(w) TW.secondary(w._playerObj, dev, id, nil) end
                    el.onContextMenu = function(w) TW.secondary(w._playerObj, dev, id, nil) end
                end
            end
            elements[#elements + 1] = el
        end
        _addFillStops(win, elements)
        if elements[1] and win._gpFocusedRadioCtl == nil then win._gpFocusedRadioCtl = elements[1].id end
        return elements
    end

    -- Seed gate — only writes on nil so D-pad onFocus updates are never
    -- stomped between frames.
    if elements[1] and win._gpFocusedRadioCtl == nil then
        win._gpFocusedRadioCtl = elements[1].id
    end
    return elements
end
