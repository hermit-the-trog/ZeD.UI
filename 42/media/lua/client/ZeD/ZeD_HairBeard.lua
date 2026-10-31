-- ZeD-UI/42/media/lua/client/ZeD/ZeD_HairBeard.lua
-- ============================================================================
-- HAIR AND BEARD — the Identity tab's section under the license (mockup
-- zed_hair_beard_v1, approved "as recommended" Oct 26 2026).
--
-- The game keeps haircuts and beard trims behind the Hair and Beard buttons of
-- its Character screen (ISCharacterScreen:hairMenu / beardMenu), which ZeD never
-- shows. This section asks those same two functions for their choices: they run
-- against a stand-in screen whose context menu only writes the options down, so
-- whatever the game (or a hair mod that replaces those menus) would offer lands
-- here, with its own wording, its own greyed reasons and its own handler
-- (ISCharacterScreen.onCutHair / onTrimBeard: the hat comes off, the tool goes
-- into the hand, the timed action is queued). Nothing about the rules is copied.
--   * Spongie's Hairstyle Unlocker (SpnHairAPI) replaces hairMenu: its extra rows
--     (styles at the current length) carry a small tag with the mod's name.
--   * Improved Hair Menu (improvedhairmenubuild42) and NeatUI Hairstyler
--     (NeatUI_Hairstyler) turn the menu into "Tie Hair" / "Cut Hair" / "Trim Beard"
--     entries that open their picture windows; their lists of choices are read
--     into rows here. Every row already shows the style on the character, so
--     their picture window is not offered from here (director, Oct 26 2026:
--     "use game avatars for each style").
-- What the character cannot do now (a row that needs a tool they lack, a style the
-- hair is too short for) folds under one quiet row, by ZeD setup's Hidden actions
-- (ZeD.Disclose); opened, those rows show greyed with the reason. One press does
-- it (no confirm).
-- Each row, and the Now and After heads, show the game's own 3D figure of the
-- character wearing that style (AVATARS below).
-- ============================================================================

require "ISUI/ISUI3DModel"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.HairBeard = ZeD.HairBeard or {}
local HB = ZeD.HairBeard

-- design units
local GH_H, CUR_H, HEAD_W, HEAD_H, CUR_K = 15, 28, 68, 76, 56
local THUMB, THUMB_PAD = 42, 6     -- a row's figure frame and its inset (the row is as tall as both)
local REFRESH_FRAMES = 30

local function tr(k, ...) return ZeD.tr(k, ...) end
local function F(n) return ZeD.TM:getFontHeight(ZeD.T["fontF" .. n]) end

-- ---------------------------------------------------------------------------
-- the hair mods (fixed for a session)
-- ---------------------------------------------------------------------------
local _mods
local function mods()
    if _mods then return _mods end
    _mods = {}
    local list = getActivatedMods and getActivatedMods()
    if list then
        for i = 0, list:size() - 1 do
            local id = tostring(list:get(i)):gsub("^\\", "")
            _mods[id] = true
        end
    end
    return _mods
end
local function modName(id)
    local mi = getModInfoByID and getModInfoByID(id)
    return (mi and mi:getName()) or id
end
function HB.spongieOn() return mods().SpnHairAPI == true end
function HB.picturesMod()
    local m = mods()
    if m.NeatUI_Hairstyler then return "NeatUI_Hairstyler" end
    if m.improvedhairmenubuild42 then return "improvedhairmenubuild42" end
    return nil
end

-- ---------------------------------------------------------------------------
-- the tools (the game's predicates, ISCharacterScreen.lua)
-- ---------------------------------------------------------------------------
local function isRazor(it) return not it:isBroken() and (it:hasTag(ItemTag.RAZOR) or it:getType() == "Razor") end
local function isScissors(it) return not it:isBroken() and (it:hasTag(ItemTag.SCISSORS) or it:getType() == "Scissors") end
local function isGel(it) return it:getType() == "Hairgel" end
local function isSpray(it) return it:getType() == "Hairspray2" end
local function isHairdo(it) return it:hasTag(ItemTag.DO_HAIRDO) or isGel(it) or isSpray(it) end

local function tools(p)
    local inv = p:getInventory()
    local function first(fn)
        local ok, it = pcall(function() return inv:getFirstEvalRecurse(fn) end)
        return ok and it or nil
    end
    return { razor = first(isRazor), scissors = first(isScissors), gel = first(isGel),
             spray = first(isSpray), hairdo = first(isHairdo) }
end

local function has(req, tl)
    if req == "none" then return true end
    if req == "rs" then return tl.razor ~= nil or tl.scissors ~= nil end
    if req == "s" then return tl.scissors ~= nil end
    if req == "gs" then return tl.hairdo ~= nil end
    if req == "g" then return tl.gel ~= nil end
    if req == "sp" then return tl.spray ~= nil end
    return false
end

local ITEM = { razor = "Base.Razor", scissors = "Base.Scissors", gel = "Base.Hairgel", spray = "Base.Hairspray2" }
local _itemNames = {}
local function itemWord(k)
    local n = _itemNames[k]
    if not n then
        local ok, s = pcall(getItemNameFromFullType, ITEM[k])
        n = (ok and s and s ~= "") and s or ITEM[k]
        _itemNames[k] = n
    end
    return n
end
local function toolWords(req)
    if req == "rs" then return tr("UI_ZeD_Hair_ToolOr", itemWord("razor"), itemWord("scissors")) end
    if req == "s" then return itemWord("scissors") end
    if req == "gs" then return tr("UI_ZeD_Hair_ToolOr", itemWord("gel"), itemWord("spray")) end
    if req == "g" then return itemWord("gel") end
    if req == "sp" then return itemWord("spray") end
    return tr("UI_ZeD_Hair_NoTool")
end

-- ---------------------------------------------------------------------------
-- styles (the game's hairStyles.xml / beardStyles.xml as loaded)
-- ---------------------------------------------------------------------------
local function hairStyle(female, name)
    if not name then return nil end
    local hs = getHairStylesInstance()
    if female then return hs:FindFemaleStyle(name) end
    return hs:FindMaleStyle(name)
end
local function allHair(female)
    local list = female and getHairStylesInstance():getAllFemaleStyles() or getHairStylesInstance():getAllMaleStyles()
    local out = {}
    for i = 0, list:size() - 1 do out[#out + 1] = list:get(i) end
    return out
end
local function hairWord(name)
    if not name or name == "" then return getText("IGUI_Hair_Bald") end
    local k = "IGUI_Hair_" .. name
    local s = getText(k)
    if s == k then return name end
    return s
end
local function beardWord(name)
    if not name or name == "" then return getText("IGUI_Beard_None") end
    local k = "IGUI_Beard_" .. name
    local s = getText(k)
    if s == k then return name end
    return s
end
local function has_(s, sub) return s and string.find(s, sub, 1, true) ~= nil end

-- the tool a hair style needs: Spongie's Hairstyle Unlocker's rule when it is on, else the game's
local _spongieAPI
local function hairReq(name, attached)
    if attached then return "none" end
    if name == "Bald" then return "rs" end
    if HB.spongieOn() then
        if _spongieAPI == nil then
            local ok, api = pcall(require, "SpongieHairUnlocker/SpongieHairAPI")
            _spongieAPI = (ok and type(api) == "table") and api or false
        end
        if _spongieAPI then
            local ok1, gel = pcall(_spongieAPI.NeedHairGel, _spongieAPI, name)
            local ok2, spray = pcall(_spongieAPI.NeedHairSpray, _spongieAPI, name)
            gel, spray = ok1 and gel, ok2 and spray
            if gel and spray then return "gs" end
            if gel then return "g" end
            if spray then return "sp" end
            return "s"
        end
    end
    if (has_(name, "Mohawk") and name ~= "MohawkFlat") or has_(name, "Spike") then return "gs" end
    if has_(name, "GreasedBack") then return "g" end
    if has_(name, "Buffont") then return "sp" end
    return "s"
end

-- ---------------------------------------------------------------------------
-- reading the game's menus: hairMenu / beardMenu against a stand-in screen
-- ---------------------------------------------------------------------------
local function newRecorder()
    local rec = { options = {}, numOptions = 0 }
    function rec:addOption(name, target, onSelect, p1, p2, p3, p4, p5, p6)
        local o = { name = name, target = target, onSelect = onSelect,
                    param1 = p1, param2 = p2, param3 = p3, param4 = p4, param5 = p5, param6 = p6 }
        self.options[#self.options + 1] = o
        self.numOptions = self.numOptions + 1
        return o
    end
    function rec:addOptionOnTop(...) return self:addOption(...) end
    function rec:addDebugOption(...) local o = self:addOption(...); o.debug = true; return o end
    function rec:getNew() return self end
    function rec:addSubMenu() end
    function rec:setOptionChecked() end
    return setmetatable(rec, { __index = function() return function() end end })
end

local function standIn(p, playerNum)
    local s = { char = p, playerNum = playerNum }
    -- the game's addTooltip greys the option and gives its reason; this one writes both down
    s.addTooltip = function(self, option, text)
        option.notAvailable = true
        option.reason = text
    end
    return setmetatable(s, { __index = ISCharacterScreen })
end

local BUTTON = { getAbsoluteX = function() return 0 end, getAbsoluteY = function() return 0 end,
                 getHeight = function() return 0 end, getWidth = function() return 0 end }

local function harvest(p, which)
    if not (ISCharacterScreen and ISContextMenu) then return {} end
    local fn = which == "hair" and ISCharacterScreen.hairMenu or ISCharacterScreen.beardMenu
    if not fn then return {} end
    local rec = newRecorder()
    local orig = ISContextMenu.get
    ISContextMenu.get = function() return rec end
    -- playerNum -100: the menu's "give the pad to the menu" step finds no pad there
    local ok, err = pcall(fn, standIn(p, -100), BUTTON)
    ISContextMenu.get = orig
    if not ok then ZeD.logOnce("hairbeard harvest " .. which, err) end
    return rec.options
end

-- ---------------------------------------------------------------------------
-- rows
-- ---------------------------------------------------------------------------
local GROUPS = { "Tie", "Shave", "Cut", "Style", "Trim" }
local GROUP_KEY = { Tie = "UI_ZeD_Hair_GrpTie", Shave = "UI_ZeD_Hair_GrpShave", Cut = "UI_ZeD_Hair_GrpCut",
                    Style = "UI_ZeD_Hair_GrpStyle", Trim = "UI_ZeD_Hair_GrpTrim" }
local VERB_KEY = { Tie = "UI_ZeD_Hair_VerbTie", Untie = "UI_ZeD_Hair_VerbUntie", Shave = "UI_ZeD_Hair_VerbShave",
                   Cut = "UI_ZeD_Hair_VerbCut", Style = "UI_ZeD_Hair_VerbStyle", Trim = "UI_ZeD_Hair_VerbTrim" }

local function reasonFor(req)
    if req == "rs" then return getText("Tooltip_requireRazorOrScissors") end
    if req == "s" then return getText("Tooltip_RequireScissors") end
    if req == "gs" then return getText("Tooltip_requireHairGelOrHairSpray") end
    if req == "g" then return getText("Tooltip_requireHairGel") end
    if req == "sp" then return getText("Tooltip_requireHairSpray") end
    return nil
end

-- a hair row from a style name, its label, whether it can be done and its handler
local function hairRow(p, cur, name, label, ok, reason, run, kind)
    local female = p:isFemale()
    local hs = hairStyle(female, name)
    local attached = hs and hs:isAttachedHair() or false
    local req = (kind == "untie") and "none" or hairReq(name, attached)
    local grp
    if kind == "untie" or attached then grp = "Tie"
    elseif name == "Bald" then grp = "Shave"
    elseif req == "s" then grp = "Cut"
    else grp = "Style" end
    local verb = (kind == "untie") and "Untie" or grp
    return { key = "h:" .. tostring(kind) .. ":" .. tostring(name), part = "hair", style = name, label = label,
             ok = ok, reason = reason, run = run, req = req, grp = grp, verb = verb, kind = kind,
             level = hs and hs:getLevel() or 0, attached = attached }
end

local function beardRow(name, label, ok, reason, run)
    local shave = (name == nil or name == "")
    local grp = shave and "Shave" or "Trim"
    return { key = "b:" .. tostring(name or ""), part = "beard", style = name or "", label = label, ok = ok,
             reason = reason, run = run, req = "rs", grp = grp, verb = shave and "Shave" or "Trim", kind = "beard" }
end

-- the styles the game's own menu offers from here (for the hair mods' tag)
local function vanillaSet(p, cur)
    local set = {}
    if not cur then return set end
    for _, hs in ipairs(allHair(p:isFemale())) do
        if not hs:isAttachedHair() and not hs:isNoChoose() and hs:getLevel() < cur:getLevel() then set[hs:getName()] = true end
    end
    local tc = cur:getTrimChoices()
    for i = 0, tc:size() - 1 do set[tc:get(i)] = true end
    return set
end

-- the game's "... into %1" wording; a mod that rewords the key without the %1 (Improved Hair Menu
-- makes ContextMenu_TieHair its "Tie Hair" heading) still gets the style named
local function intoLabel(key, word)
    local s = getText(key, word)
    if not string.find(s, word, 1, true) then s = s .. ": " .. word end
    return s
end

-- the picture-window entries of Improved Hair Menu / NeatUI Hairstyler: one list per option
local function isPicList(o)
    return type(o.param1) == "table" and o.param1[1] ~= nil and type(o.param1[1]) == "table" and o.param1[1].id ~= nil
end
local function reqsOk(r)
    if r == nil then return true end
    local any, okAny = false, false
    for _, v in pairs(r) do any = true; if v then okAny = true end end
    return (not any) or okAny
end

local function buildRows(win, p, part)
    local st = win._hb
    local female = p:isFemale()
    local hv = p:getHumanVisual()
    local rows, pics = {}, {}
    if part == "hair" then
        local cur = hairStyle(female, hv:getHairModel())
        local opts = harvest(p, "hair")
        local vset = HB.spongieOn() and vanillaSet(p, cur) or nil
        local untieWord = getText("ContextMenu_UntieHair")
        for _, o in ipairs(opts) do
            local nm = tostring(o.name or "")
            if o.debug or nm:sub(1, 7) == "[DEBUG]" then
                -- the game's debug grow options stay out
            elseif isPicList(o) then
                pics[#pics + 1] = o
                -- (the picture mods' Tie entry lists attached styles only)
                local first = o.param1[1] and hairStyle(female, o.param1[1].id)
                local tie = first ~= nil and first:isAttachedHair()
                for _, e in ipairs(o.param1) do
                    local id, t = e.id, e.actionTime or (tie and 100 or 300)
                    local label
                    if tie then label = intoLabel("ContextMenu_TieHair", hairWord(id))
                    elseif id == "Bald" then label = getText("ContextMenu_ShaveHair")
                    else label = intoLabel("ContextMenu_CutHairFor", hairWord(id)) end
                    local hs = hairStyle(female, id)
                    local req = hairReq(id, hs and hs:isAttachedHair())
                    local ok = reqsOk(e.requirements)
                    local r = hairRow(p, cur, id, label, ok, (not ok) and reasonFor(req) or nil,
                        function(pl) ISCharacterScreen.onCutHair(pl, id, t) end, tie and "tie" or "cut")
                    rows[#rows + 1] = r
                end
            elseif type(o.onSelect) == "function" then
                local style = o.param1
                local kind = (nm == untieWord) and "untie" or "cut"
                local hs = hairStyle(female, style)
                if kind == "cut" and hs and hs:isAttachedHair() then kind = "tie" end
                local reason = o.reason or (o.notAvailable and o.toolTip and o.toolTip.description) or nil
                local r = hairRow(p, cur, style, nm, not o.notAvailable, reason,
                    function() o.onSelect(o.target, o.param1, o.param2, o.param3, o.param4, o.param5, o.param6) end, kind)
                if vset and kind == "cut" and style and not vset[style] then r.mod = "SpnHairAPI" end
                rows[#rows + 1] = r
            end
        end
    else
        local opts = harvest(p, "beard")
        for _, o in ipairs(opts) do
            local nm = tostring(o.name or "")
            if o.debug or nm:sub(1, 7) == "[DEBUG]" then
            elseif isPicList(o) then
                pics[#pics + 1] = o
                for _, e in ipairs(o.param1) do
                    local id = e.id or ""
                    local label = (id == "") and getText("ContextMenu_TrimBeard") or intoLabel("ContextMenu_TrimBeard_For", beardWord(id))
                    local ok = reqsOk(e.requirements)
                    local r = beardRow(id, label, ok, (not ok) and reasonFor("rs") or nil,
                        function(pl) ISCharacterScreen.onTrimBeard(pl, id) end)
                    rows[#rows + 1] = r
                end
            elseif type(o.onSelect) == "function" then
                local reason = o.reason or (o.notAvailable and o.toolTip and o.toolTip.description) or nil
                rows[#rows + 1] = beardRow(o.param1, nm, not o.notAvailable, reason,
                    function() o.onSelect(o.target, o.param1, o.param2, o.param3, o.param4, o.param5, o.param6) end)
            end
        end
    end
    -- grouped in the mockup's order, the game's order inside each group; one row per style
    local seen, out = {}, {}
    for _, g in ipairs(GROUPS) do
        for _, r in ipairs(rows) do
            if r.grp == g and not seen[r.key] then seen[r.key] = true; out[#out + 1] = r end
        end
    end
    return out, pics
end

-- what the game would not offer from here, and why
local function outRows(p, part, rows)
    local out = {}
    local inList = {}
    for _, r in ipairs(rows) do if r.style then inList[r.style] = true end end
    if part == "hair" then
        local female = p:isFemale()
        local hv = p:getHumanVisual()
        if hv:getNonAttachedHair() then return out end
        local cur = hairStyle(female, hv:getHairModel())
        local curLevel = cur and cur:getLevel() or 0
        local curName = cur and cur:getName() or ""
        local list = {}
        for _, hs in ipairs(allHair(female)) do
            local n = hs:getName()
            if n ~= "" and not hs:isAttachedHair() and not hs:isNoChoose() and hs:getLevel() > 0 and n ~= curName and not inList[n] then
                list[#list + 1] = hs
            end
        end
        table.sort(list, function(a, b) return hairWord(a:getName()) < hairWord(b:getName()) end)
        for _, hs in ipairs(list) do
            local n, lv = hs:getName(), hs:getLevel()
            local short = lv > curLevel or curLevel == 0
            out[#out + 1] = { key = "o:" .. n, part = "hair", style = n, label = hairWord(n), out = true,
                why = short and tr("UI_ZeD_Hair_TooShortHair" .. math.max(1, math.min(3, lv))) or tr("UI_ZeD_Hair_NotFromHair", hairWord(curName)),
                tag = short and tr("UI_ZeD_Hair_TagTooShort") or tr("UI_ZeD_Hair_TagNotFromHair") }
        end
    else
        local bs = getBeardStylesInstance()
        local cur = bs:FindStyle(p:getHumanVisual():getBeardModel())
        local curLevel = cur and cur:getLevel() or 0
        local curName = cur and cur:getName() or ""
        local all = bs:getAllStyles()
        for i = 0, all:size() - 1 do
            local s = all:get(i)
            local n, lv = s:getName(), s:getLevel()
            if n ~= "" and n ~= curName and not inList[n] then
                local short = lv > curLevel or curLevel == 0
                out[#out + 1] = { key = "ob:" .. n, part = "beard", style = n, label = beardWord(n), out = true,
                    why = short and tr("UI_ZeD_Hair_TooShortBeard" .. math.max(1, math.min(3, lv))) or tr("UI_ZeD_Hair_NotFromBeard", beardWord(curName)),
                    tag = short and tr("UI_ZeD_Hair_TagTooShort") or tr("UI_ZeD_Hair_TagNotFromBeard") }
            end
        end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- state
-- ---------------------------------------------------------------------------
local function state(win)
    local st = win._hb
    if not st then
        st = { part = "hair", sel = nil, tick = 999, rows = {}, out = {}, pics = {},
               counts = { hair = 0, beard = 0 }, zones = {}, els = {} }
        win._hb = st
    end
    return st
end

local function refresh(win, st, p, force)
    st.tick = (st.tick or 0) + 1
    if not force and st.tick < REFRESH_FRAMES and st.player == p then return end
    st.tick = 0
    st.player = p
    st.female = p:isFemale()
    if st.female then st.part = "hair" end
    st.tools = tools(p)
    local hr, hp = buildRows(win, p, "hair")
    local br, bp = {}, {}
    if not st.female then br, bp = buildRows(win, p, "beard") end
    st.counts = { hair = #hr, beard = #br }
    st.byPart = { hair = { rows = hr, pics = hp }, beard = { rows = br, pics = bp } }
    local cur = st.byPart[st.part]
    st.rows, st.pics = cur.rows, cur.pics
    st.out = outRows(p, st.part, st.rows)
    -- a picked row that is gone (the hair changed) is let go
    if st.sel then
        local keep = false
        for _, r in ipairs(st.rows) do if r.key == st.sel then keep = true end end
        for _, r in ipairs(st.out) do if r.key == st.sel then keep = true end end
        if not keep then st.sel = nil end
    end
end

local function findRow(st, key)
    if not key then return nil end
    for _, r in ipairs(st.rows or {}) do if r.key == key then return r end end
    for _, r in ipairs(st.out or {}) do if r.key == key then return r end end
    return nil
end

function HB.setPart(win, part)
    local st = state(win)
    if st.female then part = "hair" end
    if st.part == part then return end
    st.part, st.sel = part, nil
    if st.byPart then
        st.rows, st.pics = st.byPart[part].rows, st.byPart[part].pics
        if st.player then st.out = outRows(st.player, part, st.rows) end
    end
end

-- ---------------------------------------------------------------------------
-- doing it
-- ---------------------------------------------------------------------------
local function queueHas(p)
    return ISTimedActionQueue.hasActionType(p, "ISCutHair") or ISTimedActionQueue.hasActionType(p, "ISTrimBeard")
end

function HB.run(win, key)
    local st = state(win)
    local p = win._playerObj
    local r = findRow(st, key or st.sel)
    if not (p and r) or r.out or not r.ok or st.busy then return false end
    local ok, err = pcall(r.run, p)
    if not ok then ZeD.logOnce("hairbeard run", err); return false end
    st.busy = { verb = r.verb, part = r.part, t0 = getTimestampMs() }
    st.done, st.sel = nil, nil
    getSoundManager():playUISound("UIActivateButton")
    return true
end

function HB.stop(win)
    local p = win._playerObj
    if p then pcall(ISTimedActionQueue.clear, p) end
end

local function watchBusy(win, st, p)
    local b = st.busy
    if not b then return end
    if queueHas(p) then b.seen = true; return end
    -- the hat's unequip runs first: wait up to a few seconds for the cut to be queued
    if not b.seen and getTimestampMs() - b.t0 < 3000 then return end
    st.busy = nil
    local hv = p:getHumanVisual()
    if b.part == "beard" then
        local bs = getBeardStylesInstance():FindStyle(hv:getBeardModel())
        st.done = tr("UI_ZeD_Hair_DoneBeard", beardWord(bs and bs:getName() or ""))
    else
        st.done = tr("UI_ZeD_Hair_DoneHair", hairWord(hv:getHairModel()))
    end
    win._identityCache = nil   -- the license's Hair style / Facial hair lines follow at once
    refresh(win, st, p, true)
end

-- ---------------------------------------------------------------------------
-- AVATARS: the game's own 3D figure (ISUI3DModel, as its character creation and
-- hair menus use) for each style, the Now head and the After head. Each is the
-- player's own look (skin, body, hair colour, the clothes they wear minus what
-- covers the head) copied into a stand-in SurvivorDesc with the row's hair or
-- beard on it; the real character is never touched (the model copies the desc
-- when it is set). A 3D figure cannot sit in a stencilled panel, so the figures
-- are window children laid over the frames this section draws (a frame cut by
-- the view's edge shows the part of its figure inside the view: the figure's
-- own camera does the cut), from a small pool that grows to what shows. A layer
-- above them dims the greyed rows' figures. The
-- figures go (removed from the window) the first frame the section is not drawn.
-- ---------------------------------------------------------------------------
local AV_ZOOM, AV_YOFF = 17, -0.86            -- head and shoulders: hair rows, Now and After
local AV_ZOOM_BEARD, AV_YOFF_BEARD = 18.5, -0.83   -- beard rows: closer on the lower face, so the beard reads
local AV_DIR = IsoDirections.SE                -- hair: a slight turn, so ties and tails read and the face shows
local AV_DIR_BEARD = IsoDirections.S           -- beard: face on, so long hair does not hide it
-- The game's figure camera (UI3DModel, not isometric): an orthographic view 2 * (25 - zoom) / sqrt(2048)
-- world units tall, centred in the element, the figure moved by the y offset. A frame cut by the
-- view's edge gets a figure element only as tall as the part that shows, with the zoom and the
-- offset scaled so the figure stays where the whole frame would draw it: the cut is the camera's.
local AV_CAM, AV_S = 25, math.sqrt(2048)
local AV_MIN_H = 6                             -- a sliver shorter than this shows no figure
local AV_MAX, AV_DRESS_PER_FRAME = 40, 6       -- pool cap; new looks set per frame (each builds a model)

local AV = { frame = 0, states = {} }          -- the UI frame count; every window state with figures
HB.AV = AV

local function colKey(c)
    if not c then return "-" end
    local ok, r, g, b = pcall(function() return c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat() end)
    if not ok then return "-" end
    return string.format("%.3f,%.3f,%.3f", r, g, b)
end

-- what covers the hair or the beard (hats, hoods, masks, helmets, suit heads): left off the figure
local function coversHead(loc)
    local s = string.lower(tostring(loc or ""))
    return s:find("hat", 1, true) ~= nil or s:find("mask", 1, true) ~= nil or s:find("head", 1, true) ~= nil
        or s:find("helmet", 1, true) ~= nil
end

-- the look every figure shares (refreshed with the rows): a change re-dresses them all
local function baseKeyOf(p)
    local hv = p:getHumanVisual()
    local parts = { tostring(p:isFemale()), tostring(hv:getSkinTextureIndex()), tostring(hv:getSkinTexture()),
                    colKey(hv:getHairColor()), colKey(hv:getBeardColor()), tostring(hv:getBodyHairIndex()) }
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:getItemByIndex(i)
        if it then parts[#parts + 1] = tostring(it:getID()) end
    end
    return table.concat(parts, "|")
end

local function avState(st)
    local av = st.av
    if not av then
        av = { pool = {}, want = 0, drawFrame = -10, veils = {} }
        st.av = av
    end
    return av
end

-- the stand-in: a copy of the player's visual and worn clothes (not what covers the head)
local function syncDesc(av, p, key)
    if av.descKey == key and av.desc then return end
    local d = av.desc
    if not d then d = SurvivorFactory.CreateSurvivor(); av.desc = d end
    d:setFemale(p:isFemale())
    d:getHumanVisual():copyFrom(p:getHumanVisual())
    local worn = d:getWornItems()
    worn:clear()
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:getItemByIndex(i)
        local loc = it and wi:getLocation(it)
        if loc and not coversHead(loc) then worn:setItem(loc, it) end
    end
    av.descKey = key
end

local function setShown(m, on)
    if m:isVisible() ~= on then m:setVisible(on) end
    if m.javaObject:isVisible() ~= on then m.javaObject:setVisible(on) end
end

local function noMouse() return false end
local function makeModel()
    local m = ISUI3DModel:new(0, 0, 10, 10)
    m:initialise()
    m:instantiate()
    m:setState("idle")
    m:setDirection(AV_DIR)
    m:setIsometric(false)
    m:setDoRandomExtAnimations(false)
    m:setAnimateWhilePaused(true)
    m:setZoom(AV_ZOOM)
    m:setYOffset(AV_YOFF)
    m:setXOffset(0)
    -- the press, the wheel and the hover go through to the drawer below (its rows and scroll)
    m.javaObject:setConsumeMouseEvents(false)
    m.onMouseDown, m.onMouseUp, m.onMouseMove, m.onMouseWheel = noMouse, noMouse, noMouse, noMouse
    m.onMouseUpOutside, m.onMouseMoveOutside = noMouse, noMouse
    m.onRightMouseDown, m.onRightMouseUp = noMouse, noMouse   -- (42.22: a handler that returns nothing takes the click)
    m._hbModel = true
    m:setVisible(false)
    m.javaObject:setVisible(false)
    return m
end

-- the layer over the figures (click-through): the veils over the greyed rows
local function makeLayer(win)
    local layer = ISPanel:new(0, 0, 10, 10)
    layer:initialise()
    layer:instantiate()
    layer.background = false
    layer.javaObject:setConsumeMouseEvents(false)
    layer.prerender = function() end
    layer.onMouseDown, layer.onMouseUp, layer.onMouseWheel, layer.onMouseMove = noMouse, noMouse, noMouse, noMouse
    layer.onRightMouseDown, layer.onRightMouseUp = noMouse, noMouse
    layer.render = function(self) HB.renderLayer(self, win) end
    layer._hbLayer = true
    layer:setVisible(false)
    return layer
end

-- every figure off (the window's frame, before the tab draws; the tab shows what it uses)
local function hideAll(av)
    for _, m in ipairs(av.pool) do setShown(m, false) end
    if av.layer and av.layer:isVisible() then av.layer:setVisible(false) end
end

-- the figures leave the window
local function release(win, st)
    local av = st.av
    if not av then return end
    for _, m in ipairs(av.pool) do
        setShown(m, false)
        pcall(function() win:removeChild(m) end)
    end
    if av.layer then pcall(function() win:removeChild(av.layer) end) end
    st.av = nil
    AV.states[st] = nil
end
HB.release = release

-- from ZeD_CharacterWindow.extFrame, each frame before the tab draws
function HB.onWindowFrame(win)
    local st = win._hb
    if st and st.av then hideAll(st.av) end
end

-- before the UI draws: grow the pool to what the section asked for (a child added while the
-- window draws would upset its drawing), and release the figures of a section not drawn
local function preUI()
    AV.frame = AV.frame + 1
    for st, win in pairs(AV.states) do
        local av = st.av
        if not av or av.drawFrame < AV.frame - 1 then
            release(win, st)
        else
            local grew = false
            while #av.pool < math.min(av.want, AV_MAX) do
                local m = makeModel()
                win:addChild(m)
                av.pool[#av.pool + 1] = m
                grew = true
            end
            if not av.layer then
                av.layer = makeLayer(win)
                win:addChild(av.layer)
            elseif grew then
                win:removeChild(av.layer)
                win:addChild(av.layer)
            end
        end
    end
end
Events.OnPreUIDraw.Add(preUI)


-- a figure over its frame: the whole frame, or the part of it inside the view (ct / cb: the
-- pixels cut at the top / bottom), framed by the camera as the whole frame would be
local function fitFigure(m, w, ox, oy)
    local z0 = w.close and AV_ZOOM_BEARD or AV_ZOOM
    local yo = w.close and AV_YOFF_BEARD or AV_YOFF
    local ct, cb = w.ct or 0, w.cb or 0
    local h = w.h - ct - cb
    local z = z0
    if ct > 0 or cb > 0 then
        local size = AV_CAM - z0
        z = AV_CAM - size * h / w.h
        yo = yo + (ct - cb) * size / (w.h * AV_S)
        if yo == 0 then yo = 0.0001 end   -- (0 means the game's own default offset)
    end
    if m._z ~= z then m:setZoom(z); m._z = z end
    if m._yo ~= yo then m:setYOffset(yo); m._yo = yo end
    m:setX(ox + w.x); m:setY(oy + w.y + ct)
    if m:getWidth() ~= w.w then m:setWidth(w.w) end
    if m:getHeight() ~= h then m:setHeight(h) end
    m._cut = ct + cb
end

-- this frame's figures: wants = { { id, x, y, w, h, hair, beard, dim, face, close, ct, cb } } in the panel's coordinates
local function placeFigures(panel, win, st, wants)
    local av = avState(st)
    local p = win._playerObj
    AV.states[st] = win
    av.drawFrame = AV.frame
    av.veils = {}
    if not p then return end
    -- (with the rows: refresh() has just run when its tick is 0)
    if not st.baseKey or st.tick == 0 then st.baseKey = baseKeyOf(p) end
    syncDesc(av, p, st.baseKey)
    local ox, oy = panel:getX(), panel:getY()
    for _, m in ipairs(av.pool) do m._use = nil end
    -- a figure already wearing a wanted look keeps it
    local need = {}
    for _, w in ipairs(wants) do
        w.look = (st.baseKey or "") .. "#" .. w.hair .. "/" .. w.beard .. (w.face and "@S" or "")
        for _, m in ipairs(av.pool) do
            if not m._use and m._look == w.look then m._use = w; w.m = m; break end
        end
        if not w.m then need[#need + 1] = w end
    end
    -- the rest take a free figure (a few new looks a frame: each builds a model)
    local dressed = 0
    local hv = av.desc:getHumanVisual()
    for _, w in ipairs(need) do
        if dressed >= AV_DRESS_PER_FRAME then break end
        local free
        for _, m in ipairs(av.pool) do if not m._use then free = m; break end end
        if not free then break end
        hv:setHairModel(w.hair)
        if not st.female then hv:setBeardModel(w.beard) end
        free:setSurvivorDesc(av.desc)
        free:setDirection(w.face and AV_DIR_BEARD or AV_DIR)
        free._look, free._use, w.m = w.look, w, free
        dressed = dressed + 1
    end
    av.want = #wants
    for _, w in ipairs(wants) do
        local m = w.m
        if m then
            m._id = w.id
            fitFigure(m, w, ox, oy)
            setShown(m, true)
            if w.dim then av.veils[#av.veils + 1] = w end
        end
    end
    for _, m in ipairs(av.pool) do if not m._use then m._id = nil; setShown(m, false) end end
    local layer = av.layer
    if layer then
        layer:setX(ox); layer:setY(oy)
        if layer:getWidth() ~= panel:getWidth() then layer:setWidth(panel:getWidth()) end
        if layer:getHeight() ~= panel:getHeight() then layer:setHeight(panel:getHeight()) end
        if not layer:isVisible() then layer:setVisible(true) end
    end
end

-- the figures showing now (for the QA script): { id, model, x, y, w, h } in window coordinates
function HB.figures(win)
    local st = win and win._hb
    local out = {}
    local av = st and st.av
    if not av then return out end
    for _, m in ipairs(av.pool) do
        if m._id and m:isVisible() and m.javaObject:isVisible() then
            out[#out + 1] = { id = m._id, model = m, x = m:getX(), y = m:getY(), w = m:getWidth(), h = m:getHeight(), look = m._look, cut = m._cut or 0, zoom = m._z, yoff = m._yo }
        end
    end
    return out
end
function HB.poolSize(win)
    local st = win and win._hb
    return (st and st.av) and #st.av.pool or 0
end

-- the frame behind a figure (drawn on the drawer, under the figure): hard corners, live tokens
local function drawFrame(panel, x, y, w, h)
    local T = ZeD.T
    local s3, bs = T.surf3, T.borderS
    panel:drawRect(x, y, w, h, s3.a or 1, s3.r, s3.g, s3.b)
    panel:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
end

-- the layer: veils over the greyed rows' figures (the disabled look: the figure at T.disabledAlpha)
function HB.renderLayer(layer, win)
    local st = win._hb
    local av = st and st.av
    if not av then return end
    local T = ZeD.T
    local clip = av.clip
    if clip then layer:setStencilRect(clip.x, clip.y, clip.w, clip.h) end
    local db = T.drawerBg
    local veilA = 1 - T.disabledAlpha
    for _, w in ipairs(av.veils) do
        layer:drawRect(w.x + 1, w.y + 1, w.w - 2, w.h - 2, veilA, db.r, db.g, db.b)
    end
    if clip then layer:clearStencilRect() end
end

-- what a head looks like now, or after a row
local function headLook(st, p, sel)
    local hv = p:getHumanVisual()
    local h, b = hv:getHairModel() or "", st.female and "" or (hv:getBeardModel() or "")
    if sel then
        if sel.part == "beard" then b = sel.style or "" else h = sel.style or "" end
    end
    return h, b
end

-- the hair colour's swatch on the Now lines
local function colOf(c, fb)
    if not c then return fb end
    local ok, r, g, b = pcall(function() return c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat() end)
    if ok and r then return { r = r, g = g, b = b } end
    return fb
end

-- ---------------------------------------------------------------------------
-- LAYOUT (content coordinates from the section's top; x from its left)
-- ---------------------------------------------------------------------------
local function add(L, it) L.items[#L.items + 1] = it; return it end

local DS = ZeD.Disclose

-- the controller's mark options for the element with this id (the focused window, the
-- controller in use, that element), or nil
local _focusOpts = {}
local function focusOf(win, id)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end

-- a row is as tall as its figure frame and the frame's inset (the list row height is
-- the floor: a Large text size grows the token, not the figure)
local function rowHeight()
    local T = ZeD.T
    return math.max(T.rowH, T.px(THUMB) + 2 * T.px(THUMB_PAD))
end

-- the Hair | Beard radio row's height
local function partsHeight()
    return math.max(ZeD.Atoms.radioSize(), F(2)) + ZeD.T.px(8)
end

-- the key the folded row remembers its open / closed state under (one per part)
local function moreKey(st) return "hb:more:" .. tostring(st.part) end

-- Which rows the list shows now and which the folded row keeps back, by ZeD setup's
-- "Hidden actions": a row the character can do shows; one that needs a tool, and a
-- style the hair is too short for, fold under one quiet row (or all show, greyed, or
-- are left out).
local function sortRows(st)
    local verbs = {}
    for _, r in ipairs(st.rows) do r.canDo = r.ok and true or false; verbs[#verbs + 1] = r end
    for _, r in ipairs(st.out) do r.canDo = false; verbs[#verbs + 1] = r end
    return DS.split(verbs)
end

-- The hidden actions the folded row speaks for: the verbs the character lacks a tool
-- for (Cut, Style, Shave, Trim), each with what it needs and what it would do; styles
-- the hair is too short for count as one more ("choose from more styles"). The folded
-- row (ZeD.Molecules.drawMoreRow) says "With scissors you could cut your hair." for
-- one and "3 more with the right things" for several.
local HINT_KEY = { Cut = "UI_ZeD_Hair_HintCut", Shave = "UI_ZeD_Hair_HintShave", Style = "UI_ZeD_Hair_HintStyle", Trim = "UI_ZeD_Hair_HintTrim" }
local function moreGroups(st, hidden)
    local groups, seen = {}, {}
    local outCount = 0
    for _, r in ipairs(hidden) do
        if r.out then
            outCount = outCount + 1
        else
            local k = r.grp .. "|" .. tostring(r.req)
            if not seen[k] then
                seen[k] = true
                local hint = (r.grp == "Shave" and r.part == "beard") and tr("UI_ZeD_Hair_HintShaveBeard") or tr(HINT_KEY[r.grp] or "UI_ZeD_Hair_HintCut")
                groups[#groups + 1] = { needs = string.lower(toolWords(r.req)), hint = hint }
            end
        end
    end
    if outCount > 0 then
        groups[#groups + 1] = { needs = tr(st.part == "beard" and "UI_ZeD_Hair_NeedsLongerBeard" or "UI_ZeD_Hair_NeedsLongerHair"),
                                hint = tr("UI_ZeD_Hair_HintMoreStyles") }
    end
    return groups
end

function HB.layout(win, w)
    local T = ZeD.T
    local st = state(win)
    local p = win._playerObj
    local L = { items = {}, h = 0 }
    if not p then return L end
    refresh(win, st, p)
    watchBusy(win, st, p)
    local pad = T.sp.sm
    local cw = w - pad * 2
    local x, y = pad, T.px(12)
    -- the section head, as Identity's Traits has: 20u, sentence case, its content line under it
    add(L, { kind = "subh", text = tr("UI_ZeD_Hair_Section"), x = x, y = y, w = cw, h = T.px(20) })
    y = y + T.px(20) + T.sp.afterGroove
    local topH = math.max(T.px(HEAD_H) + T.px(3) + F(5), T.px(CUR_H) * (st.female and 2 or 3))
    add(L, { kind = "heads", x = x, y = y, w = cw, h = topH })
    y = y + topH + T.px(10)
    local ph = partsHeight()
    add(L, { kind = "parts", x = x, y = y, w = cw, h = ph })
    y = y + ph + T.px(8)

    local shown, hidden = sortRows(st)
    local rh = rowHeight()
    local gh = T.px(GH_H)
    if #shown == 0 and #hidden == 0 then
        local text = st.part == "beard" and tr("UI_ZeD_Hair_EmptyBeard") or tr("UI_ZeD_Hair_EmptyHair")
        local lines = ZeD.Atoms.wrapText(text, T.fontF2, cw - T.px(16))
        local eh = #lines * (F(2) + T.px(2)) - T.px(2)
        add(L, { kind = "empty", text = text, x = x + T.px(8), y = y, w = cw - T.px(16), h = eh })
        y = y + eh
    end
    local lastGrp, odd = false, false
    for _, r in ipairs(shown) do
        if r.grp ~= lastGrp then
            lastGrp = r.grp
            if r.grp then
                local n = 0
                for _, q in ipairs(shown) do if q.grp == r.grp then n = n + 1 end end
                add(L, { kind = "gh", grp = r.grp, n = n, x = x, y = y, w = cw, h = gh })
                y = y + gh
            end
            odd = false
        end
        odd = not odd
        add(L, { kind = "row", row = r, odd = not odd, x = x, y = y, w = cw, h = rh })
        y = y + rh
    end
    if #hidden > 0 then
        local key = moreKey(st)
        local groups = moreGroups(st, hidden)
        -- the row alone (the styles it keeps back open as rows below it, not as its own block)
        local mh = ZeD.Molecules.measureMoreRow(cw, groups, key, { closedOnly = true, inset = T.px(8) })
        add(L, { kind = "more", key = key, groups = groups, x = x, y = y, w = cw, h = mh })
        y = y + mh
        if DS.isOpen(key) then
            odd = false
            for _, r in ipairs(hidden) do
                odd = not odd
                add(L, { kind = "row", row = r, odd = not odd, x = x, y = y, w = cw, h = rh })
                y = y + rh
            end
        end
    end
    -- the hair mods
    local note
    local pm = HB.picturesMod()
    if pm and #(st.pics or {}) > 0 then
        note = tr("UI_ZeD_Hair_NotePictures", modName(pm))
    elseif st.part == "hair" and HB.spongieOn() then
        note = tr("UI_ZeD_Hair_NoteSpongie", modName("SpnHairAPI"))
    end
    if note then
        y = y + T.px(8)
        local lines = ZeD.Atoms.wrapText(note, T.fontF2, cw)
        local nh = #lines * (F(2) + T.px(2)) - T.px(2)
        add(L, { kind = "note", lines = lines, x = x, y = y, w = cw, h = nh })
        y = y + nh
    end
    L.h = y + T.sp.sm
    st.L = L
    return L
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------

-- opts for a mod's tag (its name keeps its own capitals) and for the length meter (the framed strip)
local TAG_KEEP, SEG_FRAMED = { keepCase = true }, { framed = true }

-- the length meter: three cells (A.drawSegBar, framed) 10u tall
local function lenBar(panel, x, y, level)
    local T, A = ZeD.T, ZeD.Atoms
    local w, h = T.px(27), T.px(10)
    A.drawSegBar(panel, x, y, w, h, 3, level, T.text, nil, T.px(2), SEG_FRAMED)
    return w
end

-- a figure for this frame when any of its frame shows in the view (a frame cut by the view's
-- edge gets the part of the figure inside it: fitFigure)
local function want(wants, view, id, x, y, w, h, hair, beard, dim, face, close)
    local fy0, fy1 = y + 1, y + h - 1
    local ct, cb = math.max(0, view.y0 - fy0), math.max(0, fy1 - view.y1)
    if (fy1 - fy0) - ct - cb < AV_MIN_H then return end
    wants[#wants + 1] = { id = id, x = x + 1, y = fy0, w = w - 2, h = h - 2, hair = hair or "", beard = beard or "",
                          dim = dim, face = face, close = close, ct = ct, cb = cb }
end

local function drawHeads(panel, win, st, it, y, wants, view)
    local T = ZeD.T
    local p = win._playerObj
    local hv = p:getHumanVisual()
    local bw, bh = T.px(HEAD_W), T.px(HEAD_H)
    local curHair, curBeard = hv:getHairModel(), (not st.female) and hv:getBeardModel() or ""
    drawFrame(panel, it.x, y, bw, bh)
    local nh, nb = headLook(st, p, nil)
    local face = st.part == "beard"
    want(wants, view, "now", it.x, y, bw, bh, nh, nb, false, face)
    local dim, tc = T.toneLo or T.textDim, T.text
    local f5 = T.fontF5
    local function cap(text, cx)
        local tw = ZeD.TM:MeasureStringX(f5, text)
        panel:drawText(text, cx + math.floor((bw - tw) / 2), y + bh + T.px(3), dim.r, dim.g, dim.b, dim.a or 1, f5)
    end
    cap(tr("UI_ZeD_Hair_Now"), it.x)
    local ax = it.x + bw + T.px(6)
    panel:drawText(">", ax, y + math.floor((bh - F(2)) / 2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF2)
    local bx = ax + ZeD.TM:MeasureStringX(T.fontF2, ">") + T.px(6)
    local sel = findRow(st, st.sel)
    drawFrame(panel, bx, y, bw, bh)
    if sel and not sel.out then
        local h2, b2 = headLook(st, p, sel)
        want(wants, view, "after", bx, y, bw, bh, h2, b2, false, face)
    end
    cap(tr("UI_ZeD_Hair_After"), bx)
    -- what the character has now
    local cx = bx + bw + T.px(12)
    local cw = it.x + it.w - cx
    local female = st.female
    local cur = hairStyle(female, curHair)
    local rowsDef = {}
    local tiedTo = hv:getNonAttachedHair()
    local hv1 = hairWord(curHair)
    if tiedTo and cur and cur:isAttachedHair() then hv1 = hv1 .. " " .. tr("UI_ZeD_Hair_Tied", hairWord(tiedTo)) end
    rowsDef[#rowsDef + 1] = { getText("IGUI_char_HairStyle"), hv1, "len", cur and cur:getLevel() or 0 }
    rowsDef[#rowsDef + 1] = { tr("UI_ZeD_Hair_Color"), win._identityCache and win._identityCache.hairColor or "", "color" }
    if not female then
        local bs = getBeardStylesInstance():FindStyle(curBeard)
        rowsDef[#rowsDef + 1] = { getText("IGUI_char_BeardStyle"), beardWord(bs and bs:getName() or ""), "len", bs and bs:getLevel() or 0 }
    end
    local rh = T.px(CUR_H)
    local ry = y + math.floor((it.h - rh * #rowsDef) / 2)
    local f1, f2 = T.fontF1, T.fontF2
    for i, d in ipairs(rowsDef) do
        local ty2 = ry + math.floor((rh - F(2)) / 2)
        local ty1 = ry + math.floor((rh - F(1)) / 2)
        panel:drawText(d[1], cx, ty1, dim.r, dim.g, dim.b, dim.a or 1, f1)
        local meta, mw = nil, 0
        if d[3] == "len" then
            meta = tr("UI_ZeD_Hair_Len" .. math.max(0, math.min(3, d[4])))
            mw = ZeD.TM:MeasureStringX(f1, meta) + T.px(6) + T.px(27)
        else
            meta = tr("UI_ZeD_Hair_GrowsBack")
            mw = ZeD.TM:MeasureStringX(f1, meta)
        end
        local vx = cx + T.px(CUR_K)
        local vx2 = vx
        if d[3] == "color" then
            local hc = colOf(hv:getHairColor(), { r = 0.23, g = 0.14, b = 0.09 })
            local sz = T.px(10)
            panel:drawRect(vx, ry + math.floor((rh - sz) / 2), sz, sz, 1, hc.r, hc.g, hc.b)
            panel:drawRectBorder(vx, ry + math.floor((rh - sz) / 2), sz, sz, T.borderS.a or 1, T.borderS.r, T.borderS.g, T.borderS.b)
            vx2 = vx + sz + T.px(5)
        end
        local vw = cx + cw - mw - T.px(8) - vx2
        panel:drawText(ZeD.Atoms.truncateText(d[2], f2, vw), vx2, ty2, tc.r, tc.g, tc.b, tc.a or 1, f2)
        local mx = cx + cw - mw
        if d[3] == "len" then
            local used = lenBar(panel, mx, ry + math.floor((rh - T.px(10)) / 2), d[4])
            panel:drawText(meta, mx + used + T.px(6), ty1, dim.r, dim.g, dim.b, dim.a or 1, f1)
        else
            panel:drawText(meta, mx, ty1, dim.r, dim.g, dim.b, dim.a or 1, f1)
        end
        if i < #rowsDef then
            local bd = T.border
            panel:drawRect(cx, ry + rh - T.px(1), cw, T.px(1), bd.a or 1, bd.r, bd.g, bd.b)
        end
        ry = ry + rh
    end
end

-- Hair | Beard: two System 7 radio buttons (one of two), each half pressable
local function drawParts(panel, win, st, it, y, mx, my)
    local T, A = ZeD.T, ZeD.Atoms
    local halves = st.female and { "hair" } or { "hair", "beard" }
    local hw = math.floor(it.w / #halves)
    local rs = A.radioSize()
    local hv = T.hover
    local fo = focusOf(win, "hb:part")
    for i, part in ipairs(halves) do
        local hx = it.x + (i - 1) * hw
        local ww = (i == #halves) and (it.x + it.w - hx) or hw
        local on = st.part == part
        local hover = mx ~= nil and mx >= hx and mx < hx + ww and my >= y and my < y + it.h
        if hover then
            panel:drawRect(hx, y, ww, it.h, hv.a, hv.r, hv.g, hv.b)
            if ZeD.Help then ZeD.Help.set(win, tr("UI_ZeD_Hair_HelpPart", part == "hair" and getText("IGUI_char_HairStyle") or getText("IGUI_char_BeardStyle"))) end
        end
        local tc = T.text
        if fo and on and ZeD.Focus.mark(panel, hx, y, ww, it.h, fo) then tc = T.textOnFocus end
        A.drawRadio(panel, hx + T.px(8), y + math.floor((it.h - rs) / 2), on, { hover = hover })
        local word = (part == "hair") and getText("IGUI_char_HairStyle") or getText("IGUI_char_BeardStyle")
        local label = tr("UI_ZeD_Hair_PartCount", word, st.counts[part] or 0)
        panel:drawText(A.truncateText(label, T.fontF2, ww - T.px(8) - rs - T.px(8) - T.px(6)),
            hx + T.px(8) + rs + T.px(8), y + math.floor((it.h - F(2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end
end

-- a group's category row: "Cut (4)", not folding
local function drawGh(panel, win, st, it, y)
    ZeD.Molecules.drawCategoryRow(panel, it.x, y, it.w, tr(GROUP_KEY[it.grp]), it.n, true, { noArrow = true, inset = ZeD.T.px(8) })
end

-- the folded row: the library's, row only (opening it shows the styles themselves as
-- rows below, not the library's block of greyed buttons, so the layout sizes the row and
-- the rows under it before the frame draws)
local _moreOpts = { closedOnly = true }
local function drawMore(panel, win, st, it, y, mx, my)
    local T = ZeD.T
    local hover = mx ~= nil and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    if hover and ZeD.Help then
        ZeD.Help.set(win, tr(DS.isOpen(it.key) and "UI_ZeD_Hair_HelpMoreOpen" or "UI_ZeD_Hair_HelpMore"))
    end
    local o = _moreOpts
    o.hover, o.focus, o.inset, o.win = hover, focusOf(win, "hb:more"), T.px(8), win
    ZeD.Molecules.drawMoreRow(panel, it.x, y, it.w, it.groups, it.key, o)
end

local function drawRow(panel, win, st, it, y, mx, my, wants, view)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local r = it.row
    local bd = T.border
    local sel = st.sel == r.key
    local hov = mx ~= nil and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    if it.odd then local s = T.stripe; panel:drawRect(it.x, y, it.w, it.h, s.a or 1, s.r, s.g, s.b) end
    -- selected: the one accent wash; hover: the hover wash over it
    if sel then local ac = T.accent; panel:drawRect(it.x, y, it.w, it.h, T.selectionA or 0.30, ac.r, ac.g, ac.b) end
    if hov then
        local hv = T.hover
        panel:drawRect(it.x, y, it.w, it.h, hv.a, hv.r, hv.g, hv.b)
        if ZeD.Help then ZeD.Help.set(win, tr("UI_ZeD_Hair_HelpRow", r.label)) end
    end
    -- the controller's mark goes under the words; the words switch only when it is the wash
    local ink, dimInk = T.text, T.toneLo or T.textDim
    local swapped = false
    local fo = focusOf(win, "hb:row:" .. r.key)
    if fo and ZeD.Focus.mark(panel, it.x, y, it.w, it.h, fo) then ink, dimInk, swapped = T.textOnFocus, T.textOnFocus, true end
    panel:drawRect(it.x, y + it.h - T.px(1), it.w, T.px(1), bd.a or 1, bd.r, bd.g, bd.b)
    local greyed = r.out or not r.ok
    local nameA = (greyed and not swapped) and T.disabledAlpha or 1
    -- right side: the tool and its square, or the reason's tag
    local rx = it.x + it.w - T.px(8)
    local f1 = T.fontF1
    local ty1 = y + math.floor((it.h - F(1)) / 2)
    if r.out then
        local tw = A.tagW(r.tag)
        rx = rx - tw
        M.drawTag(panel, rx, y + math.floor((it.h - T.px(16)) / 2), r.tag, nil, { alpha = nameA })
    elseif r.req ~= "none" then
        local words = toolWords(r.req)
        local tw = ZeD.TM:MeasureStringX(f1, words)
        rx = rx - tw
        panel:drawText(words, rx, ty1, ink.r, ink.g, ink.b, (ink.a or 1) * nameA, f1)
        local dsz = T.px(6)
        rx = rx - T.px(6) - dsz
        local dy = y + math.floor((it.h - dsz) / 2)
        if has(r.req, st.tools) then A.drawStatusDot(panel, rx, dy, T.positive, dsz)
        else A.drawStatusHollow(panel, rx, dy, dimInk, dsz) end
    end
    -- the hair mod's tag (its name's first word)
    if r.mod then
        local tag = modName(r.mod):match("^(%a+)") or r.mod
        local tw = A.tagW(tag, false, TAG_KEEP)
        rx = rx - T.px(8) - tw
        M.drawTag(panel, rx, y + math.floor((it.h - T.px(16)) / 2), tag, nil, TAG_KEEP)
    end
    -- the figure wearing this row's style, in its frame
    local ts, tp = T.px(THUMB), T.px(THUMB_PAD)
    local fx, fy = it.x + tp, y + math.floor((it.h - ts) / 2)
    drawFrame(panel, fx, fy, ts, ts)
    local h2, b2 = headLook(st, win._playerObj, r)
    want(wants, view, r.key, fx, fy, ts, ts, h2, b2, greyed and true or false, r.part == "beard", r.part == "beard")
    local nx = fx + ts + T.px(10)
    local nw = rx - T.px(8) - nx
    panel:drawText(ZeD.Atoms.truncateText(r.label, T.fontF2, nw), nx, y + math.floor((it.h - F(2)) / 2),
        ink.r, ink.g, ink.b, (ink.a or 1) * nameA, T.fontF2)
end

function HB.draw(panel, win, L, x, top, w, viewY, viewH)
    local T = ZeD.T
    local st = state(win)
    if not L or not win._playerObj then return end
    st.zones, st.top, st.x = {}, top, x
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local inView = mx >= x and mx < x + w and my >= viewY and my < viewY + viewH
    local Fo = ZeD.Input and ZeD.Input.Focus
    -- (the mouse's hover and cards go quiet while the controller's mark shows)
    if not inView or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    st.hover = nil
    local wants, view = {}, { y0 = viewY, y1 = viewY + viewH }
    for _, it in ipairs(L.items) do
        local y = top + it.y
        local ix = it.x + x
        local vis = y + (it.h or T.px(30)) >= viewY and y <= viewY + viewH
        local item = it
        if ix ~= it.x then
            item = {}
            for k, v in pairs(it) do item[k] = v end
            item.x = ix
        end
        local k = it.kind
        if vis then
            if k == "subh" then
                ZeD.Molecules.drawSectionHeader(panel, ix, y, it.w, it.text, nil, true, false, nil, nil, nil, nil, true)
            elseif k == "heads" then drawHeads(panel, win, st, item, y, wants, view)
            elseif k == "parts" then drawParts(panel, win, st, item, y, mx, my)
            elseif k == "gh" then drawGh(panel, win, st, item, y)
            elseif k == "more" then drawMore(panel, win, st, item, y, mx, my)
            elseif k == "row" then drawRow(panel, win, st, item, y, mx, my, wants, view)
            elseif k == "empty" then
                ZeD.Molecules.drawEmptyLine(panel, ix, y, it.w, it.text)
            elseif k == "note" then
                local c = T.textDim
                for i, line in ipairs(it.lines) do
                    panel:drawText(line, ix, y + (i - 1) * (F(2) + T.px(2)), c.r, c.g, c.b, c.a or 1, T.fontF2)
                end
            end
        end
        -- click zones (only what shows) and the row under the mouse
        if (k == "row" or k == "more" or k == "parts") and vis then
            local zy0, zy1 = math.max(viewY, y), math.min(viewY + viewH, y + it.h)
            if zy1 > zy0 then
                st.zones[#st.zones + 1] = { x = ix, y = zy0, w = it.w, h = zy1 - zy0, item = it }
                if k == "row" and mx and mx >= ix and mx < ix + it.w and my >= zy0 and my < zy1 then
                    st.hover = { key = it.row.key, x = ix, y = y, w = it.w, h = it.h }
                end
            end
        end
    end
    -- the figures over the frames drawn this frame; the layer's veils stay inside the view
    placeFigures(panel, win, st, wants)
    if st.av then st.av.clip = { x = x, y = viewY, w = w, h = viewH } end
end

-- ---------------------------------------------------------------------------
-- the foot of the drawer: what the picked row needs, and the button. A line above the
-- band carries the busy bar, the row's NEEDS line or its notes; the band is the
-- library's (the status words at the left, the verb at the right).
-- ---------------------------------------------------------------------------
local function itemName(it) return it and it:getDisplayName() or "" end

local function notesFor(st, p, r)
    local notes = {}
    if not r.ok then
        notes[#notes + 1] = r.reason or reasonFor(r.req) or ""
        return notes
    end
    local tl = st.tools
    if r.part == "hair" then
        local hat = p:getClothingItem_Head()
        if hat then notes[#notes + 1] = tr("UI_ZeD_Hair_HatOff", itemName(hat)) end
    end
    if r.req == "rs" then
        local t = (r.part == "beard") and (tl.razor or tl.scissors) or (tl.scissors or tl.razor)
        if t then notes[#notes + 1] = tr("UI_ZeD_Hair_ToHand", itemName(t)) end
    elseif r.req == "s" then
        if tl.scissors and not getDebug() then notes[#notes + 1] = tr("UI_ZeD_Hair_ToHand", itemName(tl.scissors)) end
    elseif r.req ~= "none" then
        local t = (r.req == "sp" and tl.spray) or (r.req == "g" and tl.gel) or tl.hairdo
        if t then notes[#notes + 1] = tr("UI_ZeD_Hair_Uses", itemName(t)) end
    else
        notes[#notes + 1] = tr("UI_ZeD_Hair_NoToolNeeded")
    end
    return notes
end

-- what the foot says this frame: { text, color } for the band's status, info (the line
-- above it) with needs = a NEEDS line (hollow square) or plain notes, pct = the busy
-- bar, and the verb button's label and state
local function stripState(win)
    local T = ZeD.T
    local st = state(win)
    local p = win._playerObj
    local s = { label = "", canDo = false }
    if not p then return s end
    if st.busy then
        local b = st.busy
        local key = (b.part == "beard") and "UI_ZeD_Hair_BusyTrim"
            or (b.verb == "Tie" and "UI_ZeD_Hair_BusyTie") or (b.verb == "Untie" and "UI_ZeD_Hair_BusyUntie") or "UI_ZeD_Hair_BusyCut"
        s.text, s.color = tr(key), T.accent
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        local a = q and q.queue and q.queue[1]
        s.pct = 0
        if a and (a.Type == "ISCutHair" or a.Type == "ISTrimBeard") and a.getJobDelta then
            local ok, v = pcall(a.getJobDelta, a)
            if ok and v then s.pct = v end
        end
        s.stop, s.canDo = true, true
        s.label = tr("UI_ZeD_Hair_Stop")
        s.help = tr("UI_ZeD_Hair_HelpStop")
        return s
    end
    local r = findRow(st, st.sel)
    local verb = (st.part == "beard") and "Trim" or "Cut"
    if not r then
        if st.done then s.text, s.color = st.done, T.positive else s.text = tr("UI_ZeD_Hair_Pick") end
    elseif r.out then
        s.text, s.info, s.needs = tr("UI_ZeD_Hair_OutTitleNA", r.label), r.why, true
    else
        s.text = r.label
        if r.mod then s.text = s.text .. " " .. tr("UI_ZeD_Hair_FromMod", modName(r.mod)) end
        verb, s.canDo = r.verb, r.ok
        if r.ok then
            s.color = T.positive
            s.info = table.concat(notesFor(st, p, r), " | ")
        else
            s.needs = true
            if r.req ~= "none" then
                s.info = DS.needsLine({ label = tr(VERB_KEY[r.verb] or "UI_ZeD_Hair_VerbCut"), needs = toolWords(r.req) })
            else
                s.info = r.reason or ""
            end
        end
    end
    s.label = tr(VERB_KEY[verb] or "UI_ZeD_Hair_VerbCut")
    s.help = s.canDo and s.info or nil
    if s.info == "" then s.info = nil end
    return s
end

-- the height of the foot: the band, and the line above it when there is one
function HB.stripH(win)
    local T, M = ZeD.T, ZeD.Molecules
    local s = win and stripState(win) or {}
    local extra = 0
    if s.pct then extra = T.fillBarH + T.px(12)
    elseif s.info then extra = F(2) + T.px(10) end
    return M.bandH() + extra
end

function HB.drawStrip(panel, win, x, y, w, h)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local st = state(win)
    local p = win._playerObj
    st.btn = nil
    if not p then return end
    local s = stripState(win)
    local pad = T.sp.sm
    local infoH = h - M.bandH()
    if infoH > 0 then
        A.surfaceFill(panel, x, y, w, infoH, "surf2")
        A.drawDividerH(panel, x, y, w, true)
        if s.pct then
            -- the busy bar: the standard framed strip
            A.drawSmoothBar(panel, x + pad, y + math.floor((infoH - T.fillBarH) / 2), w - pad * 2, s.pct, false, T.accent)   -- (a timed action: smooth)
        elseif s.info then
            local tx = x + pad
            local ty = y + math.floor((infoH - F(2)) / 2)
            local tc = s.needs and T.text or T.textDim
            if s.needs then
                local sq = T.px(6)
                A.drawStatusHollow(panel, tx, ty + math.floor((F(2) - sq) / 2), T.textDim, sq)
                tx = tx + sq + T.px(6)
            end
            panel:drawText(A.truncateText(s.info, T.fontF2, x + w - pad - tx), tx, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        end
    end
    local hdr, out = M.drawBand(panel, x, y + infoH, w, {
        status = { text = s.text or "", color = s.color },
        buttons = { { label = s.label, variant = s.stop and "default" or "primary", disabled = not s.canDo,
                      focus = s.stop and focusOf(win, "hb:do") or nil, help = s.help, id = "do" } },
        win = win, noLine = infoH > 0,
    })
    local b = out.buttons[1]
    if b then st.btn = { x = b.x, y = b.y, w = b.w, h = b.h, on = s.canDo, stop = s.stop and true or false } end
end

-- ---------------------------------------------------------------------------
-- the hover card (also the Identity traits' and the Traits tab's): the shared detail
-- card. The mouse asks the window's overlay for it (it appears after the shared pause);
-- the controller's focus draws it at once, under the element (rect = its place on panel).
-- body is a line of words, or a list of lines.
-- ---------------------------------------------------------------------------
function HB.hoverCard(panel, win, key, title, body, rect, focused)
    local lines = nil
    if type(body) == "table" then lines = body
    elseif body and body ~= "" then lines = { body } end
    local card = { title = title, lines = lines, maxW = 280 }
    if focused then
        local T = ZeD.T
        ZeD.Molecules.drawDetailCard(panel, rect.x + T.px(8), rect.y + rect.h - T.px(14), card)
    else
        ZeD.Atoms.requestDetailCard(win, key, card, panel)
    end
end

-- the hover card for a row: the game's own hint
function HB.drawHints(panel, win)
    local st = state(win)
    local hv = st.hover
    if not hv then return end
    local r = findRow(st, hv.key)
    if not r then return end
    local body
    if r.out then body = r.why
    elseif not r.ok then body = r.reason or reasonFor(r.req)
    elseif r.req == "none" then body = tr("UI_ZeD_Hair_NoToolNeeded")
    else
        local tl = st.tools
        local t = (r.req == "rs" and (tl.scissors or tl.razor)) or (r.req == "s" and tl.scissors)
            or (r.req == "sp" and tl.spray) or (r.req == "g" and tl.gel) or tl.hairdo
        body = t and tr("UI_ZeD_Hair_YouHave", itemName(t)) or nil
    end
    HB.hoverCard(panel, win, "hb:" .. hv.key, r.label, body, hv, false)
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

function HB.onClick(win, x, y)
    local st = win._hb
    if not st then return false end
    if st.btn and inRect(st.btn, x, y) then
        if st.btn.stop then HB.stop(win) elseif st.btn.on then HB.run(win) end
        return true
    end
    for _, z in ipairs(st.zones or {}) do
        if inRect(z, x, y) then
            local it = z.item
            if it.kind == "row" then
                st.sel = (st.sel == it.row.key) and nil or it.row.key
                st.done = nil
            elseif it.kind == "more" then
                DS.toggle(it.key)
            elseif it.kind == "parts" then
                local half = (not st.female) and (x >= it.x + st.x + it.w / 2) or false
                HB.setPart(win, half and "beard" or "hair")
            end
            getSoundManager():playUISound("UIActivateButton")
            return true
        end
    end
    return false
end

-- the controller's stops: the Hair | Beard switch, each row, the folded row
-- (as laid out this frame; rows scrolled out of view keep their place for the cone)
function HB.focusables(win)
    local st = win._hb
    local L = st and st.L
    if not (L and st.top) then return {} end
    local out = {}
    for _, it in ipairs(L.items) do
        local y = st.top + it.y
        local x = it.x + (st.x or 0)
        local e
        if it.kind == "parts" then
            e = { id = "hb:part",
                onDpadDir = function(w, el, dir)
                    if st.female then return false end
                    if dir == "left" and st.part ~= "hair" then HB.setPart(w, "hair"); return true end
                    if dir == "right" and st.part ~= "beard" then HB.setPart(w, "beard"); return true end
                    return false
                end,
                onActivate = function(w) if not st.female then HB.setPart(w, st.part == "hair" and "beard" or "hair") end end }
        elseif it.kind == "row" then
            local key = it.row.key
            e = { id = "hb:row:" .. key,
                onFocus = function() st.sel = key; st.done = nil end,
                onActivate = function(w) st.sel = key; HB.run(w, key) end }
        elseif it.kind == "more" then
            local key = it.key
            e = { id = "hb:more", onActivate = function() DS.toggle(key) end }
        end
        if e then
            e.x, e.y, e.w, e.h, e.cy, e.hbStop = x, y, it.w, it.h, it.y, true
            e.onFocus = e.onFocus or function() end
            out[#out + 1] = e
        end
    end
    -- the foot's Stop while a cut runs
    if st.busy and st.btn then
        out[#out + 1] = { id = "hb:do", x = st.btn.x, y = st.btn.y, w = st.btn.w, h = st.btn.h, onFocus = function() end,
                          onActivate = function(w) HB.stop(w) end }
    end
    return out
end

-- what moves the stops (for the window's rebuild check)
function HB.key(win)
    local st = win._hb
    if not st then return "" end
    return tostring(st.part) .. ":" .. tostring(DS.isOpen(moreKey(st))) .. ":" .. tostring(#(st.rows or {})) .. ":"
        .. tostring(#(st.out or {})) .. ":" .. tostring(st.busy ~= nil) .. ":" .. tostring(st.rows and st.rows[1] and st.rows[1].key)
        .. ":" .. DS.setting()
end

function HB.state(win) return state(win) end
