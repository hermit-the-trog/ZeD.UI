-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/SPNCC.lua
-- ============================================================================
-- SUPPORT FOR SPONGIE'S CHARACTER CUSTOMISATION (mod id SPNCC, Workshop 3414634809)
-- Director, Oct 25 2026: "Can we add support for Spoungies character editor? so it
-- matches ZeD when that mod is active." Mockup zed_spongie_appearance_v1 approved.
--
-- ModSupport/<mod id>.lua is ZeD's pattern for working well with another mod: the
-- file does nothing unless that mod is on, builds the mod's surfaces from ZeD's parts
-- and drives the mod's own functions and data (never its panels).
--
--   Character window, Appearance tab (after Identity): the mod's faces and details
--     as picture tiles (each its own 3D figure, the mod's camera for that option)
--     or a list, a 3D preview, stubble and body hair with the mod's Shave actions,
--     Muscle and Body Hair Growth when the server leaves them to the player,
--     Cancel | Save. The server's rules are the mod's (CharacterScreen.lua).
--   The mod's window at game start (an old save, FaceManager_Shared.
--     OpenCharacterCustomisationWindow) opens this tab instead, paused, Save only.
--   The Looks screen for a new character: ZeD_MainMenuLooks.lua asks
--     ZeD.ModSupport.SPNCC.looksRows for the mod's rows.
--
-- Saving goes through the mod: FaceManager_Server.SetCustomisation in single
-- player, the "SetCustomisation" client command in multiplayer, with the same
-- data as the mod's own Save (CharacterCustomisationPanel_Ingame).
-- ============================================================================

local MOD_ID = "SPNCC"

local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_CharacterWindow"
require "ISUI/ISUI3DModel"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.SPNCC = S

local TAB_ID = "appearance"

-- design units
local PAD, FIG_W, FIG_H, COL_GAP = 10, 150, 300, 12
local TILE_W, TILE_PIC, TILE_GAP = 68, 72, 8
local LROW_H, BROW_H = 28, 30

-- the mod's zoom steps (CharacterCustomisationPanel ZoomSettings)
local ZOOM_STEPS, ZOOM_MAX, Y_MIN, Y_MAX = 4, 18, -0.5, -0.875

S.view = "grid"      -- "grid" (pictures) or "list"
S.first = false      -- the mod asked for a look at game start (Save only, paused)

local function mod(name)
    local ok, m = pcall(require, name)
    return ok and type(m) == "table" and m or nil
end
local function Data() return mod("CharacterCustomisation/SPNCC_Data") end
local function Shared() return mod("CharacterCustomisation/FaceManager_Shared") end

local function txt(key) return getText(key) end
local function sandbox() return SandboxVars and SandboxVars.SPNCharCustom or {} end

-- ---------------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------------
local function state(win)
    local st = win._spncc
    if not st then
        st = { scroll = ZeD_ScrollbarState:new(), tick = 999, zoom = 0, tiles = {}, zones = {},
               els = {}, pool = {}, poolKeys = {} }
        win._spncc = st
    end
    return st
end

local function hasTag(player, tag)
    if not tag then return false end
    local ok, r = pcall(function()
        return player:getInventory():containsEvalRecurse(function(it) return it:hasTag(tag) end)
    end)
    return ok and r or false
end
local function hasRazor(player)
    local ok, r = pcall(function()
        return player:getInventory():containsEvalRecurse(function(it)
            return not it:isBroken() and it:hasTag(ItemTag.RAZOR)
        end)
    end)
    return ok and r or false
end
local function adminish() return isDebugEnabled() or (isClient() and isAdmin()) end

local function sortedOptions(dict, unlocker)
    local list = {}
    for _, v in pairs(dict or {}) do
        if not v.locked or unlocker then list[#list + 1] = v end
    end
    table.sort(list, function(a, b)
        local sa, sb = tostring(a.sort or "b"), tostring(b.sort or "b")
        if sa ~= sb then return sa < sb end
        return tostring(a.display or a.name) < tostring(b.display or b.name)
    end)
    return list
end

-- the picks start as what the character wears (the mod's SetPlayerCustomisationFromData)
local function readPicks(st, data)
    st.face = data.face and data.face.name or "DefaultFace"
    st.det = {}
    for _, d in ipairs(data.bodyDetails or {}) do st.det[d.name] = true end
    st.muscle = data.muscleVisuals and true or false
    st.growth = data.bodyHairGrowthEnabled and true or false
    st.savedKey = nil
end

local function picksKey(st)
    local names = {}
    for n in pairs(st.det or {}) do names[#names + 1] = n end
    table.sort(names)
    return tostring(st.face) .. "|" .. table.concat(names, ",") .. "|" .. tostring(st.muscle) .. tostring(st.growth)
end

local function refresh(win, st)
    local player = win._playerObj
    local data = player and player:getModData().SPNCharCustom
    st.data = data
    if not data then return end
    st.tick = st.tick + 1
    if st.tick >= 30 or not st.faces then
        st.tick = 0
        local D = Data()
        local changer = adminish() or hasTag(player, SPNCC and SPNCC.ItemTag and SPNCC.ItemTag.AppearanceChanger)
        st.unlocker = adminish() or hasTag(player, SPNCC and SPNCC.ItemTag and SPNCC.ItemTag.AppearanceUnlocker)
        st.changer = changer
        local allow = sandbox().AllowCustomisationChange or 4
        st.canFace = S.first or changer or allow == 1 or allow == 2
        st.canDet  = S.first or changer or allow == 1 or allow == 3
        st.muscleChoice = sandbox().MuscleVisuals == 3
        st.growthChoice = sandbox().BodyHairGrowthEnabled == 3
        st.razor = hasRazor(player)
        st.female = player:isFemale()
        st.faces = D and sortedOptions(D.GetFacesForCharacter(player), st.unlocker) or {}
        st.dets  = D and sortedOptions(D.GetBodyDetailsForCharacter(player), st.unlocker) or {}
        local FS = Shared()
        st.muscleLevel = FS and FS.GetMuscleLevel(player:getPerkLevel(Perks.Strength)) or 0
    end
    if not st.face then readPicks(st, data) end
    if not st.savedKey then
        local saved = {}
        readPicks(saved, data)
        st.savedKey = picksKey(saved)
    end
end

local function dirty(st) return st.savedKey ~= nil and picksKey(st) ~= st.savedKey end
local function canChange(st)
    return st.canFace or st.canDet or st.muscleChoice or st.growthChoice
end

local function findOpt(list, name)
    for _, v in ipairs(list or {}) do if v.name == name then return v end end
    return nil
end

-- ---------------------------------------------------------------------------
-- PICKS, SAVE, SHAVE
-- ---------------------------------------------------------------------------
local function pickFace(st, opt) st.face = opt.name end

-- a detail on an exclusive body location takes the place of the one there
-- (BodyDetailMenuPanel:setSelectedOption)
local function toggleDetail(st, opt)
    if st.det[opt.name] then st.det[opt.name] = nil; return end
    if not opt.isMultiItem then
        for n in pairs(st.det) do
            local o = findOpt(st.dets, n)
            if o and o.bodylocation == opt.bodylocation then st.det[n] = nil end
        end
    end
    st.det[opt.name] = true
end

local function unpause()
    if isClient() or isServer() then return end
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc and sc:getCurrentGameSpeed() == 0 then
        sc:SetCurrentGameSpeed(1)
        UIManager.setShowPausedMessage(false)
    end
end
local function pause()
    if isClient() or isServer() then return end
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc then
        sc:SetCurrentGameSpeed(0)
        UIManager.setShowPausedMessage(false)
    end
end

local function save(win, st)
    local player = win._playerObj
    if not player or not st.data then return end
    local face = findOpt(st.faces, st.face)
    local data = { bodyDetails = {}, muscleVisuals = st.muscle, bodyHairGrowth = st.growth }
    if face and face.name ~= "DefaultFace" then
        data.face = { name = face.name, id = face.id, texture = face.texture }
    else
        data.face = { name = "DefaultFace", id = "", texture = 0 }
    end
    for _, o in ipairs(st.dets) do
        if st.det[o.name] then data.bodyDetails[#data.bodyDetails + 1] = { name = o.name, id = o.id, texture = o.texture } end
    end
    if not isClient() and not isServer() then
        local FM = mod("CharacterCustomisation/FaceManager/Main")
        if FM and FM.SetCustomisation then FM.SetCustomisation(player, data) end
    else
        sendClientCommand(player, "SPNCC", "SetCustomisation", { data = data })
    end
    st.face, st.savedKey, st.previewKey = nil, nil, nil
    if S.first then S.first = false; unpause() end
    getSoundManager():playUISound("UIActivateButton")
end

local function cancel(st)
    st.face, st.savedKey = nil, nil
end

-- the mod's shave actions (added to ISCharacterScreen by its CharacterScreen.lua)
local function shave(win, st, key)
    local player = win._playerObj
    if not player or not st.razor or not ISCharacterScreen then return end
    local fake = { char = player }
    if key == "body" then
        if ISCharacterScreen.onShaveBodyHair then ISCharacterScreen.onShaveBodyHair(fake) end
    elseif ISCharacterScreen.onShaveStubble then
        ISCharacterScreen.onShaveStubble(fake, key == "beard")
    end
    st.shaving = key
end

-- ---------------------------------------------------------------------------
-- 3D FIGURES (window-parented: a 3D figure cannot sit in a stencilled panel)
-- ---------------------------------------------------------------------------
local function newDesc(player)
    local desc = SurvivorFactory:CreateSurvivor()
    desc:setForename("Preview")
    return desc
end

local function syncDesc(desc, player)
    local pv, v = desc:getHumanVisual(), player:getHumanVisual()
    desc:setFemale(player:isFemale())
    pv:setSkinTextureIndex(v:getSkinTextureIndex())
    pv:setBeardModel(v:getBeardModel())
    pv:setBeardColor(v:getBeardColor())
    pv:setHairModel(v:getHairModel())
    pv:setHairColor(v:getHairColor())
end

local function makeModel(win, st, isPreview)
    local m = ISUI3DModel:new(0, 0, 10, 10)
    m:initialise()
    m:instantiate()
    m:setState("idle")
    m:setDirection(IsoDirections.S)
    m:setIsometric(false)
    m:setDoRandomExtAnimations(false)
    m:setAnimateWhilePaused(true)
    m:setVisible(false)
    m.javaObject:setVisible(false)
    if not isPreview then
        -- a tile: a press picks it, the wheel scrolls the tab
        m.onMouseDown = function(self) self._down = true; return true end
        m.onMouseUp = function(self)
            if self._down and self._tile then S.activate(win, st, self._tile) end
            self._down = false
            return true
        end
        m.onMouseUpOutside = function(self) self._down = false; return true end
        m.onMouseMove = function(self) st.hover = self._tile; return true end
        m.onMouseMoveOutside = function(self) if st.hover == self._tile then st.hover = nil end end
    else
        local origMove = m.onMouseMove
        m.onMouseMove = function(self, dx, dy) st.hover = nil; return origMove(self, dx, dy) end
    end
    m.onMouseWheel = function(self, del)
        local dp = win._drawerPanel
        if dp and dp.onMouseWheel then return dp:onMouseWheel(del) end
        return true
    end
    win:addChild(m)
    return m
end

local function wearList(desc, items)
    local worn = desc:getWornItems()
    worn:clear()
    for _, it in ipairs(items) do
        if it then desc:setWornItem(it:getBodyLocation(), it) end
    end
end

-- the big figure: face, details, stubble and body hair as worn, muscle (UpdatePreviewCustomisation)
local function previewItems(win, st)
    local FS, D = Shared(), Data()
    local player = win._playerObj
    local items = {}
    local face = findOpt(st.faces, st.face)
    if face and face.name ~= "DefaultFace" and face.id ~= "" then items[#items + 1] = FS.CreateItem(face.id, face.texture) end
    for _, o in ipairs(st.dets) do
        if st.det[o.name] then items[#items + 1] = FS.CreateItem(o.id, o.texture) end
    end
    local L = SPNCC and SPNCC.ItemBodyLocation or {}
    for _, loc in ipairs({ L.StubbleHead, L.StubbleBeard, L.BodyHair }) do
        local w = loc and player:getWornItem(loc)
        if w then items[#items + 1] = FS.CreateItem(w:getType(), w:getVisual():getBaseTexture()) end
    end
    if st.muscle and (st.muscleLevel or 0) > 0 and D then
        local id = player:isFemale() and D.Muscle[2] or D.Muscle[1]
        local off = st.muscleLevel == 2 and 5 or 0
        items[#items + 1] = FS.CreateItem(id, player:getHumanVisual():getSkinTextureIndex() + off)
    end
    return items
end

local function updatePreview(win, st)
    local player = win._playerObj
    local key = picksKey(st) .. "|" .. tostring(st.muscleLevel) .. tostring(st.data and st.data.stubbleBeard)
        .. tostring(st.data and st.data.stubbleHead) .. tostring(st.data and st.data.bodyHair)
    if st.previewKey == key then return end
    st.previewKey = key
    st.previewDesc = st.previewDesc or newDesc(player)
    syncDesc(st.previewDesc, player)
    wearList(st.previewDesc, previewItems(win, st))
    st.preview:setSurvivorDesc(st.previewDesc)
    st.tileBase = nil
end

-- a tile: the figure with the picked face only, plus its own option (BodyDetailAvatar:applyVisual)
local function updateTile(win, st, m, tile)
    local opt = tile.opt
    local key = tile.kind .. ":" .. opt.name .. "|" .. tostring(st.face) .. "|" .. tostring(st.previewKey)
    if m._key == key then return end
    m._key = key
    local FS = Shared()
    local player = win._playerObj
    st.tileDesc = st.tileDesc or newDesc(player)
    syncDesc(st.tileDesc, player)
    local items = {}
    local face = findOpt(st.faces, st.face)
    if tile.kind == "face" then
        if opt.id and opt.id ~= "" then items[1] = FS.CreateItem(opt.id, opt.texture) end
    else
        if face and face.id and face.id ~= "" then items[1] = FS.CreateItem(face.id, face.texture) end
        if opt.id and opt.id ~= "" then items[#items + 1] = FS.CreateItem(opt.id, opt.texture) end
    end
    wearList(st.tileDesc, items)
    m:setSurvivorDesc(st.tileDesc)
    m:setDirection(opt.direction or IsoDirections.S)
    m:setZoom(opt.zoom or 20)
    m:setYOffset(opt.yoffset or -0.89)
    m:setXOffset(opt.xoffset or 0)
end

local function setShown(m, on)
    if m:isVisible() ~= on then m:setVisible(on) end
    if m.javaObject:isVisible() ~= on then m.javaObject:setVisible(on) end
end

-- the big figure's camera: the hovered or focused option's, or the whole figure at the zoom step
local function previewCamera(st, opt)
    local m = st.preview
    local key = opt and ("o:" .. opt.name) or ("z:" .. st.zoom)
    if st.camKey == key then return end
    local wasOpt = st.camKey and st.camKey:sub(1, 2) == "o:"
    st.camKey = key
    if opt then
        m:setDirection(opt.direction or IsoDirections.S)
        m:setZoom(opt.zoom or 20)
        m:setYOffset(opt.yoffset or -0.89)
        m:setXOffset(opt.xoffset or 0)
    else
        if wasOpt then m:setDirection(st.dir or IsoDirections.S) end
        m:setZoom(ZOOM_MAX / ZOOM_STEPS * st.zoom)
        m:setYOffset(Y_MIN + (Y_MAX - Y_MIN) / ZOOM_STEPS * st.zoom)
        m:setXOffset(0)
    end
end

-- every frame from the window (ZeD_CharacterWindow.extFrame): place the figures over
-- the rects the tab drew last frame, or hide them
function S.onWindowFrame(win, drawerW)
    local st = win._spncc
    if not st then return end
    local show = win._activeTab == TAB_ID and win._drawerMode == "tab" and not win._drawerItem
        and (drawerW or 0) > 0 and st.rendered and st.data ~= nil
    local dp = win._drawerPanel
    local ox, oy = dp and dp:getX() or 0, dp and dp:getY() or 0
    st.rendered = false
    st.wantPreview = show
    if st.preview and show then updatePreview(win, st) end
    if st.preview then
        local r = st.previewRect
        local on = show and r ~= nil and r.x + r.w <= drawerW
        if on then
            st.preview:setX(ox + r.x); st.preview:setY(oy + r.y)
            st.preview:setWidth(r.w); st.preview:setHeight(r.h)
            local foc = st.focusOpt
            previewCamera(st, st.hover and st.hover.opt or foc)
        end
        setShown(st.preview, on)
    end
    local used = 0
    if show then
        for _, t in ipairs(st.tiles) do
            if t.inView and t.pic.x + t.pic.w <= drawerW then
                used = used + 1
                local m = st.pool[used]
                if not m then st.wantPool = used; break end
                m._tile = t
                updateTile(win, st, m, t)
                m:setX(ox + t.pic.x); m:setY(oy + t.pic.y)
                m:setWidth(t.pic.w); m:setHeight(t.pic.h)
                setShown(m, true)
            end
        end
    end
    for i = used + 1, #st.pool do
        st.pool[i]._tile = nil
        setShown(st.pool[i], false)
    end
end

-- ---------------------------------------------------------------------------
-- LAYOUT (content coordinates; drawn at y - scroll offset)
-- ---------------------------------------------------------------------------
local function F1H() return ZeD.TM:getFontHeight(ZeD.T.fontF1) end
local function F2H() return ZeD.TM:getFontHeight(ZeD.T.fontF2) end
local function F5H() return ZeD.TM:getFontHeight(ZeD.T.fontF5) end

local function addItem(L, it) L.items[#L.items + 1] = it; return it end

local function layoutOptions(st, L, kind, list, x, y, w)
    local T = ZeD.T
    if S.view == "grid" then
        local tw, gap = T.px(TILE_W), T.px(TILE_GAP)
        local picH, labH = T.px(TILE_PIC), F5H() + T.px(5)
        local cols = math.max(1, math.floor((w + gap) / (tw + gap)))
        for i, opt in ipairs(list) do
            local c, r = (i - 1) % cols, math.floor((i - 1) / cols)
            local tx, ty = x + c * (tw + gap), y + r * (picH + labH + gap)
            addItem(L, { kind = "tile", tk = kind, opt = opt, x = tx, y = ty, w = tw, h = picH + labH, picH = picH })
        end
        local rows = math.ceil(#list / cols)
        return y + rows * (picH + labH + gap) - (rows > 0 and gap or 0)
    end
    local rh = T.px(LROW_H)
    for i, opt in ipairs(list) do
        addItem(L, { kind = "lrow", tk = kind, opt = opt, x = x, y = y + (i - 1) * rh, w = w, h = rh, odd = i % 2 == 0 })
    end
    return y + #list * rh
end

local function layoutReadOnly(st, L, kind, list, x, y, w, note)
    local T = ZeD.T
    local chosen = {}
    for _, opt in ipairs(list) do
        if (kind == "face" and opt.name == st.face) or (kind == "det" and st.det[opt.name]) then chosen[#chosen + 1] = opt end
    end
    if #chosen == 0 then
        addItem(L, { kind = "text", text = ZeD.tr("UI_ZeD_SPNCC_NoneWorn"), x = x, y = y, dim = true })
        y = y + F2H() + T.px(4)
    else
        local saveView = S.view
        S.view = "grid"
        local n0 = #L.items
        y = layoutOptions(st, L, kind, chosen, x, y, w)
        for i = n0 + 1, #L.items do L.items[i].ro = true end
        S.view = saveView
    end
    addItem(L, { kind = "text", text = note, x = x, y = y + T.px(6), dim = true, small = true })
    return y + T.px(6) + F5H()
end

-- a section head (20u, sentence case, its content line under it); count = "(n)" after it
local function layoutSubhead(L, text, x, y, w, count)
    addItem(L, { kind = "subh", text = text, count = count, x = x, y = y, w = w, h = ZeD.T.px(20) })
    return y + ZeD.T.px(20) + ZeD.T.sp.afterGroove
end

local function layoutBody(win, st, L, x, y, w)
    local T = ZeD.T
    y = layoutSubhead(L, ZeD.tr("UI_ZeD_SPNCC_Body"), x, y, w)
    local rh = T.px(BROW_H)
    local rows = {}
    if not st.female then rows[#rows + 1] = { "beard", ZeD.tr("UI_ZeD_SPNCC_BeardStubble"), st.data.stubbleBeard } end
    rows[#rows + 1] = { "head", ZeD.tr("UI_ZeD_SPNCC_HeadStubble"), st.data.stubbleHead }
    rows[#rows + 1] = { "body", ZeD.tr("UI_ZeD_SPNCC_BodyHair"), st.data.bodyHair }
    for _, r in ipairs(rows) do
        local it = addItem(L, { kind = "groom", key = r[1], text = r[2], grown = r[3] and true or false, x = x, y = y, w = w, h = rh })
        -- its Shave button, placed here so it is a controller stop while scrolled out of view too
        local bw = math.max(T.px(64), ZeD.TM:MeasureStringX(T.fontF3, getText("UI_characreation_shave")) + T.px(20))
        local bh = T.buttonH - T.px(4)   -- a push button inside a row
        it.btn = { x = x + w - bw, y = math.floor((rh - bh) / 2), w = bw, h = bh }
        y = y + rh
    end
    if st.muscleChoice or st.growthChoice then
        y = y + T.px(8)
        local cx = x
        if st.muscleChoice then
            local it = addItem(L, { kind = "check", key = "muscle", text = getText("UI_Muscle"), x = cx, y = y, h = T.px(20) })
            cx = cx + T.checkboxSz + T.px(6) + ZeD.TM:MeasureStringX(T.fontF2, it.text) + T.px(18)
        end
        if st.growthChoice then
            addItem(L, { kind = "check", key = "growth", text = getText("UI_BodyHairGrowth"), x = cx, y = y, h = T.px(20) })
        end
        y = y + T.px(20)
    end
    if not st.muscleChoice then
        local on = (sandbox().MuscleVisuals or 1) ~= 2
        addItem(L, { kind = "status", text = getText("UI_Muscle"),
            value = on and ZeD.tr("UI_ZeD_SPNCC_MuscleFrom") or ZeD.tr("UI_ZeD_SPNCC_MuscleOff"), on = on,
            x = x, y = y, w = w, h = rh })
        y = y + rh
    end
    return y
end

local function layout(win, st, w, viewH)
    local T = ZeD.T
    local L = { items = {} }
    local x, y = T.px(PAD), T.px(PAD) - T.px(2)
    local cw = w - T.px(PAD) * 2
    local mi = getModInfoByID and getModInfoByID(MOD_ID)
    addItem(L, { kind = "credit", text = mi and mi:getName() or "Spongie's Character Customisation", x = x, y = y })
    y = y + F5H() + T.px(8)
    if S.first or (st.changer and not adminish() and (sandbox().AllowCustomisationChange or 4) ~= 1) then
        local title = S.first and ZeD.tr("UI_ZeD_SPNCC_NewTitle") or ZeD.tr("UI_ZeD_SPNCC_SpiffoTitle")
        local body = S.first and ZeD.tr("UI_ZeD_SPNCC_NewText") or ZeD.tr("UI_ZeD_SPNCC_SpiffoText")
        local lines = ZeD.Atoms.wrapText(body, T.fontF2, cw - T.px(20))
        local bh = T.px(16) + F1H() + T.px(3) + #lines * F2H()
        addItem(L, { kind = "banner", title = title, lines = lines, warn = S.first, x = x, y = y, w = cw, h = bh })
        y = y + bh + T.px(12)
    end
    -- zone A: the figure left, the face and the details right
    local figTop = y
    -- the figure is as tall as the tab's view allows (down to 160), so it shows whole
    local figH = (viewH or T.px(FIG_H)) - y - T.px(4) - F5H() - T.px(6) - T.buttonH - T.px(PAD)
    figH = math.max(T.px(160), math.min(T.px(FIG_H), figH))
    st.figItem = addItem(L, { kind = "figure", x = x, y = y, w = T.px(FIG_W), h = figH })
    local by = y + figH + T.px(4) + F5H() + T.px(6)
    local bw, bgap = T.buttonH, T.px(4)
    local bx = x + math.floor((T.px(FIG_W) - (bw * 4 + bgap * 3)) / 2)
    for i, b in ipairs({ "turnL", "turnR", "zoomOut", "zoomIn" }) do
        addItem(L, { kind = "fbtn", act = b, x = bx + (i - 1) * (bw + bgap), y = by, w = bw, h = bw })
    end
    local leftBottom = by + T.buttonH
    local rx = x + T.px(FIG_W) + T.px(COL_GAP)
    local rw = cw - T.px(FIG_W) - T.px(COL_GAP)
    local ry = layoutSubhead(L, getText("UI_characreation_face"), rx, figTop, rw)
    if st.canFace then ry = layoutOptions(st, L, "face", st.faces, rx, ry, rw)
    else ry = layoutReadOnly(st, L, "face", st.faces, rx, ry, rw, getText("UI_characreation_facedisabled")) end
    ry = ry + T.px(10)
    addItem(L, { kind = "groove", x = rx, y = ry, w = rw })
    ry = ry + T.grooveH + T.px(10)
    local n = 0
    for _ in pairs(st.det) do n = n + 1 end
    ry = layoutSubhead(L, getText("UI_characreation_bodydetail"), rx, ry, rw, n)
    if #st.dets == 0 then
        addItem(L, { kind = "text", text = ZeD.tr("UI_ZeD_SPNCC_NoDetails"), x = rx, y = ry, dim = true })
        ry = ry + F2H()
    elseif st.canDet then ry = layoutOptions(st, L, "det", st.dets, rx, ry, rw)
    else ry = layoutReadOnly(st, L, "det", st.dets, rx, ry, rw, getText("UI_characreation_detailsdisabled")) end
    y = math.max(leftBottom, ry) + T.px(12)
    addItem(L, { kind = "groove", x = x, y = y, w = cw })
    y = y + T.grooveH + T.px(10)
    y = layoutBody(win, st, L, x, y, cw)
    L.h = y + T.px(PAD)
    return L
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local function focusedEl(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == win and Focus.getFocusedElement) then return nil end
    local el = Focus.getFocusedElement(win)
    if el and el.spn then return el end
    return nil
end

-- The controller's mark options for the element with this id: set only when the window is
-- the focused one, the controller is in use and that element has the focus.
local _focusOpts = {}
local function focusOf(win, id)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if id and Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end

-- the footer help line's words for what the pointer is over
local function help(win, text)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end
end

-- the pointer over (x, y, w, h) with the mouse in use, and inside the tab's scroll view
local function hoverIn(panel, st, x, y, w, h)
    local v = st.view
    if v then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        if mx < v.x or mx >= v.x + v.w or my < v.y or my >= v.y + v.h then return false end
    end
    return ZeD.Atoms.mouseIn(panel, x, y, w, h)
end

local function itemId(it)
    if it.kind == "tile" or it.kind == "lrow" then return "spn:" .. it.tk .. ":" .. it.opt.name end
    if it.kind == "fbtn" then return "spn:fig:" .. it.act end
    if it.kind == "groom" then return "spn:shave:" .. it.key end
    if it.kind == "check" then return "spn:chk:" .. it.key end
    return nil
end

local function isSel(st, it)
    if it.tk == "face" then return it.opt.name == st.face end
    return st.det[it.opt.name] == true
end

-- a picture tile: the picture (the mod's 3D figure over it) and a label strip under it. Picked:
-- the one accent wash on the strip; hover: the hover wash; the controller's mark under the words
local function drawTile(panel, win, st, it, y)
    local T = ZeD.T
    local sel = isSel(st, it)
    local s1, bs, ac = T.surf1, T.borderS, T.accent
    panel:drawRect(it.x, y, it.w, it.h, 1, s1.r, s1.g, s1.b)
    local pg = T.surf3
    panel:drawRect(it.x + 1, y + 1, it.w - 2, it.picH - 1, 1, pg.r, pg.g, pg.b)
    local labY = y + it.picH
    local labH = it.h - it.picH
    if sel and not it.ro then panel:drawRect(it.x, labY, it.w, labH, T.selectionA or 0.30, ac.r, ac.g, ac.b) end
    local tc = T.text
    if not it.ro then
        if hoverIn(panel, st, it.x, y, it.w, it.h) then
            local hv = T.hover
            panel:drawRect(it.x, labY, it.w, labH, hv.a, hv.r, hv.g, hv.b)
            help(win, ZeD.tr(sel and "UI_ZeD_SPNCC_HelpTileOn" or "UI_ZeD_SPNCC_HelpTile", tostring(it.opt.display or it.opt.name)))
        end
        local fo = focusOf(win, itemId(it))
        if fo and ZeD.Focus.mark(panel, it.x, labY, it.w, labH, fo) then tc = T.textOnFocus end
    end
    local label = ZeD.Atoms.truncateText(tostring(it.opt.display or it.opt.name), T.fontF5, it.w - T.px(4))
    local lw = ZeD.TM:MeasureStringX(T.fontF5, label)
    panel:drawText(label, it.x + math.floor((it.w - lw) / 2), labY + T.px(2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF5)
    ZeD.Atoms.frame(panel, it.x, y, it.w, it.h, bs)
    panel:drawRect(it.x, labY, it.w, T.px(1), bs.a or 1, bs.r, bs.g, bs.b)
end

-- marks over a tile's picture are drawn on the figures' layer by the mod (icons); ZeD
-- puts the eye and the padlock in the label strip's corners instead (the figure covers the picture)
local function drawMarks(panel, it, y)
    local T = ZeD.T
    local sz = T.px(9)
    local x = it.x + T.px(3)
    local my = y + it.picH + math.floor((it.h - it.picH - sz) / 2)
    if it.opt.visionModifier then
        ZeD.Atoms.drawStatusHollow(panel, x, my, T.textDim, sz)
        x = x + sz + T.px(2)
    end
    if it.opt.locked then ZeD.Atoms.drawStatusDot(panel, x, my, T.warning, sz) end
end

-- a list row: a radio button (the face: one of many) or a check box (a detail), the name
local function drawListRow(panel, win, st, it, y)
    local T, A = ZeD.T, ZeD.Atoms
    local sel = isSel(st, it)
    local ac = T.accent
    if it.odd then local s = T.stripe; panel:drawRect(it.x, y, it.w, it.h, s.a or 1, s.r, s.g, s.b) end
    if sel then panel:drawRect(it.x, y, it.w, it.h, T.selectionA or 0.30, ac.r, ac.g, ac.b) end
    local hover = hoverIn(panel, st, it.x, y, it.w, it.h)
    if hover then
        local hv = T.hover
        panel:drawRect(it.x, y, it.w, it.h, hv.a, hv.r, hv.g, hv.b)
        help(win, ZeD.tr(sel and "UI_ZeD_SPNCC_HelpTileOn" or "UI_ZeD_SPNCC_HelpTile", tostring(it.opt.display or it.opt.name)))
    end
    local tc = T.text
    local fo = focusOf(win, itemId(it))
    if fo and ZeD.Focus.mark(panel, it.x, y, it.w, it.h, fo) then tc = T.textOnFocus end
    local cs = T.checkboxSz
    local cy = y + math.floor((it.h - cs) / 2)
    if it.tk == "face" then
        local rs = A.radioSize()
        A.drawRadio(panel, it.x + T.px(6), y + math.floor((it.h - rs) / 2), sel, { hover = hover })
    else
        A.drawCheckbox(panel, it.x + T.px(6), cy, sel, hover, false)
    end
    panel:drawText(tostring(it.opt.display or it.opt.name), it.x + T.px(12) + cs, y + math.floor((it.h - F2H()) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    local bd = T.border
    panel:drawRect(it.x, y + it.h - 1, it.w, 1, bd.a or 1, bd.r, bd.g, bd.b)
    local dsz = T.px(6)
    local dy = y + math.floor((it.h - dsz) / 2)
    if it.opt.visionModifier then A.drawStatusHollow(panel, it.x + it.w - T.px(16), dy, T.textDim, dsz) end
    if it.opt.locked then A.drawStatusDot(panel, it.x + it.w - T.px(30), dy, T.warning, dsz) end
end

-- the figure's turn and zoom keys: icon buttons (each names itself after a pause)
local FIG_ICON = {
    turnL = function(p, x, y, s, c) local t = math.max(ZeD.T.px(6), math.floor(s * 0.6)); ZeD.Atoms.drawTriangleLeft(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c) end,
    turnR = function(p, x, y, s, c) local t = math.max(ZeD.T.px(6), math.floor(s * 0.6)); ZeD.Atoms.drawTriangleRight(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c) end,
    zoomOut = function(p, x, y, s, c)
        local u, a = ZeD.T.hair, math.floor(s * 0.6)
        p:drawRect(x + math.floor((s - a) / 2), y + math.floor((s - u * 2) / 2), a, u * 2, c.a or 1, c.r, c.g, c.b)
    end,
    zoomIn = function(p, x, y, s, c)
        local u, a = ZeD.T.hair, math.floor(s * 0.6)
        p:drawRect(x + math.floor((s - a) / 2), y + math.floor((s - u * 2) / 2), a, u * 2, c.a or 1, c.r, c.g, c.b)
        p:drawRect(x + math.floor((s - u * 2) / 2), y + math.floor((s - a) / 2), u * 2, a, c.a or 1, c.r, c.g, c.b)
    end,
}
local FIG_HINT = { turnL = "UI_ZeD_SPNCC_TurnLeft", turnR = "UI_ZeD_SPNCC_TurnRight", zoomOut = "UI_ZeD_SPNCC_ZoomOut", zoomIn = "UI_ZeD_SPNCC_ZoomIn" }
local _figOpts = {}
local function drawFigBtn(panel, win, it, y, st)
    local dis = (it.act == "zoomOut" and st.zoom <= 0) or (it.act == "zoomIn" and st.zoom >= ZOOM_STEPS)
    local o = _figOpts
    o.hover = (not dis) and hoverIn(panel, st, it.x, y, it.w, it.h) or false
    o.disabled = dis
    o.focus = focusOf(win, itemId(it))
    o.win = win
    o.hint = ZeD.tr(FIG_HINT[it.act])
    o.id = "spnfig:" .. it.act
    o.help = nil
    ZeD.Molecules.drawIconButton(panel, it.x, y, it.w, FIG_ICON[it.act], o)
end

local function drawGroom(panel, win, st, it, y)
    local T, A = ZeD.T, ZeD.Atoms
    local tl, tc = T.toneLo or T.textDim, T.text
    local ty = y + math.floor((it.h - F2H()) / 2)
    panel:drawText(it.text, it.x, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    local vx = it.x + T.px(130)
    local dsz = T.px(6)
    local dy = y + math.floor((it.h - dsz) / 2)
    local busy = st.shaving == it.key and it.grown
    local word
    if busy then
        A.drawStatusDot(panel, vx, dy, T.accent, dsz); word = ZeD.tr("UI_ZeD_SPNCC_Shaving")
    elseif it.grown then
        A.drawStatusDot(panel, vx, dy, T.positive, dsz); word = ZeD.tr("UI_ZeD_SPNCC_Grown")
    else
        A.drawStatusHollow(panel, vx, dy, T.textDim, dsz); word = ZeD.tr("UI_ZeD_SPNCC_None")
    end
    panel:drawText(word, vx + dsz + T.px(6), ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    if it.grown and not busy then
        local label = getText("UI_characreation_shave")
        local bw, bh = it.btn.w, it.btn.h
        local bx = it.btn.x
        local by = y + math.floor((it.h - bh) / 2)
        -- the push button (a row's size); without a razor it is greyed, and the line says why
        local o = _figOpts
        o.hover = hoverIn(panel, st, bx, by, bw, bh)
        o.disabled = not st.razor
        o.focus = focusOf(win, itemId(it))
        o.win = win
        o.help = st.razor and ZeD.tr("UI_ZeD_SPNCC_HelpShave", it.text) or getText("Tooltip_RequireRazor")
        o.hint, o.id = nil, nil
        ZeD.Molecules.drawButton(panel, bx, by, bw, bh, label, "default", false, nil, o)
        if not st.razor then
            local why = getText("Tooltip_RequireRazor")
            local sq = T.px(6)
            local ww = ZeD.TM:MeasureStringX(T.fontF2, why)
            local wx = bx - ww - T.px(10)
            panel:drawText(why, wx, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            A.drawStatusHollow(panel, wx - sq - T.px(6), y + math.floor((it.h - sq) / 2), T.textDim, sq)
        end
    end
    local bd = T.border
    panel:drawRect(it.x, y + it.h - 1, it.w, 1, bd.a or 1, bd.r, bd.g, bd.b)
end

local function drawItem(panel, win, st, it, y, contentW)
    local T = ZeD.T
    local k = it.kind
    if k == "credit" then
        local c = T.textDim
        panel:drawText(it.text, it.x, y, c.r, c.g, c.b, c.a or 1, T.fontF5)
    elseif k == "subh" then
        -- the section head: 20u, sentence case, its content line under it, not folding
        ZeD.Molecules.drawSectionHeader(panel, it.x, y, it.w, it.text, it.count, true, false, nil, nil, nil, nil, true)
    elseif k == "text" then
        local c = it.dim and (T.toneLo or T.textDim) or T.text
        local f = it.small and T.fontF5 or T.fontF2
        panel:drawText(it.text, it.x, y, c.r, c.g, c.b, c.a or 1, f)
    elseif k == "groove" then
        ZeD.Atoms.drawDividerH(panel, it.x, y, it.w)
    elseif k == "banner" then
        -- a notice: a 1u frame, a status square before the title (no side bar, no tinted fill)
        local c = it.warn and T.warning or T.accent
        ZeD.Atoms.frame(panel, it.x, y, it.w, it.h, T.borderS)
        local sq = T.px(6)
        local th = T.textHead or T.text
        ZeD.Atoms.drawStatusDot(panel, it.x + T.px(12), y + T.px(7) + math.floor((F1H() - sq) / 2), c, sq)
        panel:drawText(it.title, it.x + T.px(12) + sq + T.px(6), y + T.px(7), th.r, th.g, th.b, th.a or 1, T.fontF1)
        local tc = T.text
        for i, line in ipairs(it.lines) do
            panel:drawText(line, it.x + T.px(12), y + T.px(10) + F1H() + (i - 1) * F2H(), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        end
    elseif k == "figure" then
        local bs, s3 = T.borderS, T.surf3
        panel:drawRect(it.x, y, it.w, it.h, 1, s3.r, s3.g, s3.b)
        panel:drawRectBorder(it.x, y, it.w, it.h, bs.a or 1, bs.r, bs.g, bs.b)
        local cap
        local o = (st.hover and st.hover.opt) or st.focusOpt
        if o then cap = tostring(o.display or o.name) else cap = "" end
        local c = T.toneLo or T.textDim
        local cwid = ZeD.TM:MeasureStringX(T.fontF5, cap)
        panel:drawText(cap, it.x + math.floor((it.w - cwid) / 2), y + it.h + T.px(4), c.r, c.g, c.b, c.a or 1, T.fontF5)
    elseif k == "fbtn" then
        drawFigBtn(panel, win, it, y, st)
    elseif k == "tile" then
        drawTile(panel, win, st, it, y)
        drawMarks(panel, it, y)
    elseif k == "lrow" then
        drawListRow(panel, win, st, it, y)
    elseif k == "groom" then
        drawGroom(panel, win, st, it, y)
    elseif k == "check" then
        local on = st[it.key]
        local cs = T.checkboxSz
        local tw = ZeD.TM:MeasureStringX(T.fontF2, it.text)
        local cw = cs + T.px(6) + tw
        local hover = hoverIn(panel, st, it.x - T.px(3), y, cw + T.px(6), it.h)
        local tc = T.text
        if hover then
            local hv = T.hover
            panel:drawRect(it.x - T.px(3), y, cw + T.px(6), it.h, hv.a, hv.r, hv.g, hv.b)
            help(win, ZeD.tr("UI_ZeD_SPNCC_HelpCheck", it.text))
        end
        local fo = focusOf(win, itemId(it))
        if fo and ZeD.Focus.mark(panel, it.x - T.px(3), y, cw + T.px(6), it.h, fo) then tc = T.textOnFocus end
        ZeD.Atoms.drawCheckbox(panel, it.x, y + math.floor((it.h - cs) / 2), on, hover, false)
        panel:drawText(it.text, it.x + cs + T.px(6), y + math.floor((it.h - F2H()) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        it.w = cs + T.px(6) + tw
    elseif k == "status" then
        local tc = T.text
        local ty = y + math.floor((it.h - F2H()) / 2)
        panel:drawText(it.text, it.x, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        local vx, dsz = it.x + T.px(130), T.px(6)
        if it.on then ZeD.Atoms.drawStatusDot(panel, vx, y + math.floor((it.h - dsz) / 2), T.positive, dsz)
        else ZeD.Atoms.drawStatusHollow(panel, vx, y + math.floor((it.h - dsz) / 2), T.textDim, dsz) end
        panel:drawText(it.value, vx + dsz + T.px(6), ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end
end

-- the header's List and Pictures: two separate icon buttons 4u apart, the shown one solid accent
local _tgOpts = {}
local function drawViewToggle(panel, win, st, x, y, w, headH)
    local T = ZeD.T
    local bs = T.buttonH
    local gap = T.px(4)
    local tx = x + w - T.px(PAD) - (bs * 2 + gap)
    local ty = y + math.floor((headH - bs) / 2)
    st.toggles = {}
    for i, v in ipairs({ "list", "grid" }) do
        local zx = tx + (i - 1) * (bs + gap)
        local o = _tgOpts
        o.hover = ZeD.Atoms.mouseIn(panel, zx, ty, bs, bs)
        o.active = S.view == v
        o.focus = focusOf(win, "spn:view:" .. v)
        o.win = win
        o.hint = ZeD.tr(v == "list" and "UI_ZeD_SPNCC_ViewList" or "UI_ZeD_SPNCC_ViewPictures")
        o.id = "spnview:" .. v
        ZeD.Molecules.drawIconButton(panel, zx, ty, bs, v == "list" and "view_list" or "view_grid", o)   -- (ZeD pixel icons)
        st.toggles[#st.toggles + 1] = { x = zx, y = ty, w = bs, h = bs, view = v }
    end
end

-- the foot: the library's band (the status words at the left, Cancel and Save at the right)
local function drawStrip(panel, win, st, x, y, w, h)
    local T, M = ZeD.T, ZeD.Molecules
    local d = dirty(st)
    local word = S.first and ZeD.tr("UI_ZeD_SPNCC_NotSavedYet") or (d and ZeD.tr("UI_ZeD_SPNCC_NotSaved") or ZeD.tr("UI_ZeD_SPNCC_Saved"))
    local canSave = S.first or d
    local buttons = {}
    if not S.first then
        buttons[#buttons + 1] = { label = getText("UI_Cancel"), disabled = not d, focus = focusOf(win, "spn:cancel"), id = "cancel" }
    end
    buttons[#buttons + 1] = { label = getText("UI_characreation_BuildSave"), variant = "primary", disabled = not canSave,
        focus = focusOf(win, "spn:save"), id = "save" }
    local _, out = M.drawBand(panel, x, y, w, {
        status = { text = word, color = canSave and T.warning or nil },
        buttons = buttons, win = win,
    })
    st.btns = {}
    for i, b in ipairs(out.buttons) do
        local act = buttons[i].id
        st.btns[#st.btns + 1] = { x = b.x, y = b.y, w = b.w, h = b.h, act = act, on = (act == "save") and canSave or d }
    end
end

-- keep the controller's focus in view (once per newly focused stop)
local function followFocus(win, st, viewH, maxOff)
    local el = focusedEl(win)
    if not el or not el.cy or el.id == st.lastPinned then return end
    st.lastPinned = el.id
    local off = st.off or 0
    local newOff = off
    if el.cy < off then newOff = el.cy - ZeD.T.px(6)
    elseif el.cy + el.h > off + viewH then newOff = el.cy + el.h - viewH + ZeD.T.px(6) end
    newOff = math.max(0, math.min(maxOff, newOff))
    if newOff ~= off and maxOff > 0 then st.scroll:setScrollPos(newOff / maxOff) end
end

local function buildZones(win, st, L, sy, sh, off)
    local zones, els = {}, {}
    st.tiles = {}
    st.focusOpt = nil
    local foc = focusedEl(win)
    for _, it in ipairs(L.items) do
        local id = itemId(it)
        local dy = sy + it.y - off
        if it.kind == "tile" then
            local T = ZeD.T
            local pic = { x = it.x + 1, y = dy + 1, w = it.w - 2, h = it.picH - 1 }
            st.tiles[#st.tiles + 1] = { kind = it.tk, opt = it.opt, pic = pic, ro = it.ro,
                inView = pic.y >= sy and pic.y + pic.h <= sy + sh }
        end
        if id and not it.ro then
            local inView = dy + it.h > sy and dy < sy + sh
            local hit = it
            if it.kind == "groom" then hit = nil end
            if hit and inView then zones[#zones + 1] = { x = it.x, y = math.max(sy, dy), w = it.w or 0, h = math.min(dy + it.h, sy + sh) - math.max(sy, dy), item = it } end
            if it.kind ~= "groom" or (it.grown and st.razor and st.shaving ~= it.key) then
                els[#els + 1] = { x = it.x, y = dy, w = it.w or ZeD.T.px(100), h = it.h, id = id, spn = true, cy = it.y, item = it,
                    opt = it.opt, onFocus = function() end, onActivate = function(w) S.activate(w, st, it) end }
            end
            if foc and foc.id == id and it.opt then st.focusOpt = it.opt end
        end
    end
    st.zones = zones
    st.els = els
end

function S.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local st = state(win)
    refresh(win, st)
    if not st.data then return end
    local M = ZeD.Molecules
    local headH = M.getTabHeaderH()
    local showStrip = canChange(st)
    local stripH = showStrip and M.bandH() or 0
    local sy, sh = y + headH, h - headH - stripH
    local scroll = st.scroll
    local L = layout(win, st, w - T.sp.scrollbarW, h - headH - stripH)
    local needs = L.h > sh
    scroll.visible = needs
    local maxOff = math.max(0, L.h - sh)
    if needs then
        scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, sy, sh
        scroll:setBarSize(sh / math.max(1, L.h))
    else
        scroll:setScrollPos(0)
    end
    followFocus(win, st, sh, maxOff)
    local off = needs and math.floor(scroll.scrollPos * maxOff) or 0
    st.off = off
    buildZones(win, st, L, sy, sh, off)
    if st.shaving and st.data[({ beard = "stubbleBeard", head = "stubbleHead", body = "bodyHair" })[st.shaving]] ~= true then
        st.shaving = nil
    end
    st.view = { x = x, y = sy, w = w, h = sh }   -- (what the pointer may hover)
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(L.items) do
        local dy = sy + it.y - off
        if dy + (it.h or T.px(30)) >= sy and dy <= sy + sh then drawItem(panel, win, st, it, dy, w) end
    end
    panel:clearStencilRect()
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    -- the big figure sits over its frame only when the whole frame shows
    local fi = st.figItem
    local fy = sy + fi.y - off
    -- scrolled part way out it keeps the part in view, as the Identity photo does (a 3D figure
    -- cannot be clipped); less than half in view, it hides
    local top, bot = math.max(fy + 1, sy), math.min(fy + fi.h - 1, sy + sh)
    st.previewRect = (bot - top >= fi.h / 2) and { x = fi.x + 1, y = top, w = fi.w - 2, h = bot - top } or nil
    M.drawTabHeader(panel, x, y, w, getText("UI_characreation_appearance"), false, false, true)
    st.toggles = nil
    if st.canFace or st.canDet then drawViewToggle(panel, win, st, x, y, w, headH) end
    st.btns = nil
    if showStrip then drawStrip(panel, win, st, x, y + h - stripH, w, stripH) end
    if needs then scroll:draw(panel) end
    st.rendered = true
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------
function S.activate(win, st, it)
    local k = it.kind
    if k == "tile" or k == "lrow" or k == "face" or k == "det" then
        local kind = it.tk or it.kind
        if kind == "face" then
            if not st.canFace then return end
            pickFace(st, it.opt)
        else
            if not st.canDet then return end
            toggleDetail(st, it.opt)
        end
        getSoundManager():playUISound("UIActivateButton")
    elseif k == "fbtn" then
        local m = st.preview
        if it.act == "zoomIn" then st.zoom = math.min(ZOOM_STEPS, st.zoom + 1); st.camKey = nil
        elseif it.act == "zoomOut" then st.zoom = math.max(0, st.zoom - 1); st.camKey = nil
        elseif m then
            local d = m:getDirection()
            d = (it.act == "turnL") and d:RotRight() or d:RotLeft()
            m:setDirection(d)
            st.dir = d
        end
    elseif k == "groom" then
        shave(win, st, it.key)
    elseif k == "check" then
        st[it.key] = not st[it.key]
        getSoundManager():playUISound("UIActivateButton")
    end
end

local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

function S.onClick(win, x, y)
    local st = state(win)
    local sc = st.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return
    end
    for _, t in ipairs(st.toggles or {}) do
        if inRect(t, x, y) then S.view = t.view; getSoundManager():playUISound("UIActivateButton"); return end
    end
    for _, b in ipairs(st.btns or {}) do
        if inRect(b, x, y) then
            if b.on then
                if b.act == "save" then save(win, st) else cancel(st) end
            end
            return
        end
    end
    for _, z in ipairs(st.zones or {}) do
        if inRect(z, x, y) then S.activate(win, st, z.item); return end
    end
    -- a Shave button (its row is not a click target, only its button)
    for _, e in ipairs(st.els or {}) do
        local it = e.item
        if it and it.kind == "groom" and it.btn and it.grown then
            local by = e.y + it.btn.y
            if x >= it.btn.x and x < it.btn.x + it.btn.w and y >= by and y < by + it.btn.h then S.activate(win, st, it); return end
        end
    end
end

-- the controller's stops: the view pair, every option, the figure's buttons, Shave,
-- the check boxes, Cancel and Save (their rects as drawn this frame)
function S.buildFocusables(win)
    local st = win._spncc
    if not st or not st.data then return {} end
    local out = {}
    for _, e in ipairs(st.els or {}) do
        if e.item and e.item.kind == "groom" and e.item.btn then
            out[#out + 1] = { x = e.item.btn.x, y = e.y + e.item.btn.y, w = e.item.btn.w, h = e.item.btn.h, id = e.id, spn = true,
                cy = e.cy, item = e.item, onFocus = e.onFocus, onActivate = e.onActivate }
        elseif e.item and e.item.kind ~= "groom" then
            out[#out + 1] = e
        end
    end
    for _, t in ipairs(st.toggles or {}) do
        local v = t.view
        out[#out + 1] = { x = t.x, y = t.y, w = t.w, h = t.h, id = "spn:view:" .. v, spn = true,
            onFocus = function() end, onActivate = function() S.view = v end }
    end
    for _, b in ipairs(st.btns or {}) do
        if b.on then
            local act = b.act
            out[#out + 1] = { x = b.x, y = b.y, w = b.w, h = b.h, id = "spn:" .. act, spn = true,
                onFocus = function() end,
                onActivate = function(w) if act == "save" then save(w, st) else cancel(st) end end }
        end
    end
    return out
end

function S.scrollKey(win)
    local st = win._spncc
    if not st then return nil end
    return tostring(st.off or 0) .. ":" .. S.view .. ":" .. tostring(#(st.els or {})) .. ":" .. tostring(dirty(st)) .. tostring(S.first)
end

-- ---------------------------------------------------------------------------
-- THE TAB
-- ---------------------------------------------------------------------------
-- its lit pixel-art icon, as every other tab's (ZeDUI/tools/tabpx/icons.py "appearance", drawn by ZeD_TabPx.lua)
require "ZeD/ZeD_TabPx"
if ZeD.TabPx and ZeD.TabPx.ICONS then ZeD.TabPx.ICONS[TAB_ID] = true end

ZeD_CharacterWindow.addTab({
    id = TAB_ID, after = "identity", group = 2, glyph = "A",
    iconName = "appearance-tab-white", icon = getTexture("media/textures/ZeD/TabIcons/appearance-tab-white.png"),
    label = function() return getText("UI_characreation_appearance") end,
    visible = function(win)
        local p = win and win._playerObj
        return p ~= nil and p:getModData().SPNCharCustom ~= nil
    end,
    render = S.render,
    scroll = function(win) return win._spncc and win._spncc.scroll or nil end,
    onClick = S.onClick,
    buildFocusables = S.buildFocusables,
    scrollKey = S.scrollKey,
    onWindowFrame = S.onWindowFrame,
})

-- open the Character window on this tab (the D-pad wheel's way: press the tab once the window is up)
function S.openTab(playerNum)
    playerNum = playerNum or 0
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggle(playerNum) end
    local tries = 0
    local function tick()
        tries = tries + 1
        local win = ZeD_CharacterWindow.getWindow()
        local strip = win and win._tabStripPanel
        local done = false
        if win and win._activeTab == TAB_ID and win._drawerOpen ~= false then done = true
        elseif strip and strip._hitZones then
            for _, z in ipairs(strip._hitZones) do
                if z.id == "tab:" .. TAB_ID then strip:onMouseDown(z.x + 2, z.y + 2); done = true; break end
            end
        end
        if done or tries >= 60 then
            Events.OnPreUIDraw.Remove(tick)
            local F = ZeD.Input and ZeD.Input.Focus
            if win and F and F.claimFocus and JoypadState.players[playerNum + 1] then pcall(F.claimFocus, win) end
        end
    end
    Events.OnPreUIDraw.Add(tick)
end

-- the mod's window at game start (and its "Change" button on the game's info screen,
-- which ZeD replaces): ZeD's tab instead, paused as the mod pauses, Save only when the
-- mod hides Cancel. Safe mode keeps the mod's own window.
local function hookOpen()
    local FS = Shared()
    if not FS or FS._zedHooked or not FS.OpenCharacterCustomisationWindow then return end
    local orig = FS.OpenCharacterCustomisationWindow
    FS._zedHooked = true
    FS.OpenCharacterCustomisationWindow = function(player, hideCancelButton)
        if (ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()) or not player or not player:getModData().SPNCharCustom then
            return orig(player, hideCancelButton)
        end
        S.first = hideCancelButton and true or false
        local win = ZeD_CharacterWindow.getWindow()
        if win and win._spncc then win._spncc.face, win._spncc.savedKey, win._spncc.tick = nil, nil, 999 end
        if S.first then pause() end
        S.openTab(player:getPlayerNum())
        return nil
    end
end
Events.OnGameStart.Add(hookOpen)
hookOpen()

-- the figures join the window before the UI draws (a child added while the window draws its
-- children would upset the drawing)
local function addModels()
    local win = ZeD_CharacterWindow.getWindow()
    local st = win and win._spncc
    if not st then return end
    if st.wantPreview and not st.preview then st.preview = makeModel(win, st, true) end
    while #st.pool < (st.wantPool or 0) do st.pool[#st.pool + 1] = makeModel(win, st, false) end
end
Events.OnPreUIDraw.Add(addModels)

-- the mod's window un-pauses when it closes: so does closing the Character window unsaved
local function watchFirst()
    if S.first and not ZeD_CharacterWindow.isOpen() then
        S.first = false
        unpause()
    end
end
Events.OnPreUIDraw.Add(watchFirst)

-- ---------------------------------------------------------------------------
-- THE LOOKS SCREEN (a new character)
-- The mod's picker hangs off the game's character screen (its Change Appearance
-- button), which ZeD hides and drives from its Looks screen. These rows drive the
-- mod's own picker panel the same way: its face and detail menus keep the choice,
-- its spn_update_character_customisation dresses the figure and stores the data the
-- mod reads when the character spawns.
-- ---------------------------------------------------------------------------
local function fakeCombo(names, sel, onPick)
    local c = { options = names, selected = sel, disabled = false }
    function c:getOptionText(i) return self.options[i] end
    c.onChange = function(_, combo) onPick(combo.selected) end
    return c
end
local function fakeTick(on, onSet)
    return { options = { "" }, selected = { [1] = on and true or false },
             changeOptionMethod = function(_, i, v) onSet(v) end }
end

-- body hair shows for women too with the mod on (its CC_BodyHairReplacement)
S.bodyHairForAll = true

function S.looksRows(v, rows, head)
    local panel = v and v.characterCustomisationPanel
    if not (panel and panel.faceMenu and panel.bodyDetailMenu) then return end
    local function update() pcall(function() v:spn_update_character_customisation() end) end
    local sb = sandbox()
    if sb.MuscleVisuals == 3 and panel.muscleButton then
        rows[#rows + 1] = { kind = "tick", label = getText("UI_Muscle"), tickNoText = true,
            control = fakeTick(panel.muscleButton:isSelected(), function(on) panel.muscleButton:setSelected(on); update() end) }
    end
    if sb.BodyHairGrowthEnabled == 3 and panel.hairButton then
        rows[#rows + 1] = { kind = "tick", label = getText("UI_BodyHairGrowth"), tickNoText = true,
            control = fakeTick(panel.hairButton:isSelected(), function(on) panel.hairButton:setSelected(on); update() end) }
    end
    -- FACE: the mod's faces in its order (the default face first)
    local faces = sortedOptions(panel.faceMenu.options, panel.faceMenu.lockedOptionsVisible)
    if #faces > 0 then
        head(getText("UI_characreation_face"))
        local names, sel = {}, 1
        local cur = panel.faceMenu:getSelectedOption()
        for i, o in ipairs(faces) do
            names[i] = tostring(o.display or o.name)
            if cur and cur.name == o.name then sel = i end
        end
        rows[#rows + 1] = { kind = "combo", label = getText("UI_characreation_face"),
            control = fakeCombo(names, sel, function(i)
                panel.faceMenu:setSelectedOption(faces[i].name); update()
            end) }
    end
    -- DETAILS: a tick each (an exclusive body location trades places, as in the mod)
    local dets = sortedOptions(panel.bodyDetailMenu.options, panel.bodyDetailMenu.lockedOptionsVisible)
    if #dets > 0 then
        head(getText("UI_characreation_bodydetail"))
        for _, o in ipairs(dets) do
            local opt = o
            rows[#rows + 1] = { kind = "tick", label = tostring(opt.display or opt.name), tickNoText = true,
                control = fakeTick(panel.bodyDetailMenu.selectedOptions[opt.name] ~= nil, function()
                    panel.bodyDetailMenu:setSelected(opt); update()
                end) }
        end
    end
end
