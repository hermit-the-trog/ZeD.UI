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
--     into rows here, and a Pictures button opens their window.
-- Rows the game would not offer (too short, not from this style) sit folded
-- under Out of reach with the reason. One press does it (no confirm).
-- The Now and After heads are drawn pixel shapes, not the 3D head.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.HairBeard = ZeD.HairBeard or {}
local HB = ZeD.HairBeard

-- design units
local ROW_H, GH_H, PART_H, CUR_H, HEAD_W, HEAD_H, STRIP_H, CUR_K = 26, 22, 26, 28, 58, 66, 50, 56
local HINT_MS = 450
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
                    r.pics = o
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
                    r.pics = o
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
        st = { part = "hair", sel = nil, outOpen = false, tick = 999, rows = {}, out = {}, pics = {},
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
    st.part, st.sel, st.outOpen = part, nil, false
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

-- the picture window of Improved Hair Menu / NeatUI Hairstyler; the pad comes back to ZeD when it closes
function HB.openPictures(win)
    local st = state(win)
    local p = win._playerObj
    if not p then return end
    local sel = findRow(st, st.sel)
    local o = (sel and sel.pics) or nil
    if not o then
        for _, x in ipairs(st.pics or {}) do
            if not o or x.param2 == getText("ContextMenu_CutHair") then o = x end
        end
    end
    if not o or type(o.onSelect) ~= "function" then return end
    local pn = p:getPlayerNum()
    local made
    local W = HairMenuPanelWindow
    local origNew = W and W.new
    if W and origNew then
        W.new = function(...)
            local m = origNew(...)
            made = m
            return m
        end
    end
    local ok, err = pcall(o.onSelect, standIn(p, pn), o.param1, o.param2, o.param3)
    if W and origNew then W.new = origNew end
    if not ok then ZeD.logOnce("hairbeard pictures", err); return end
    if made then
        made.returnFocus = nil
        local close = made.close
        made.close = function(self)
            close(self)
            if ZeD.Input and ZeD.Input.Focus and ZeD.Input.Focus.reclaimEngineFocus and JoypadState.players[pn + 1] then
                ZeD.Input.Focus.reclaimEngineFocus()
            end
            st.tick = 999
        end
    end
    getSoundManager():playUISound("UIActivateButton")
end

-- ---------------------------------------------------------------------------
-- the drawn heads (pixel shapes on a 29 x 33 grid: enough to tell long from
-- short, tied from loose, which beard)
-- ---------------------------------------------------------------------------
local SKIN = { r = 0.89, g = 0.72, b = 0.59 }
local SHIRT = { r = 0.29, g = 0.33, b = 0.38 }
local INK = { r = 0.16, g = 0.16, b = 0.16 }
local LIP = { r = 0.60, g = 0.35, b = 0.29 }
local function colOf(c, fb)
    if not c then return fb end
    local ok, r, g, b = pcall(function() return c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat() end)
    if ok and r then return { r = r, g = g, b = b } end
    return fb
end
local function span(cx, cy, rx, ry, y)
    local d = (y + 0.5 - cy) / ry
    if d < -1 or d > 1 then return nil end
    local dx = rx * math.sqrt(1 - d * d)
    return math.floor(cx - dx + 0.5), math.floor(cx + dx - 0.5)
end

function HB.drawHead(panel, x, y, w, h, look, alpha)
    local T = ZeD.T
    alpha = alpha or 1
    panel:drawRect(x, y, w, math.floor(h / 2), alpha, 0.165, 0.184, 0.2)
    panel:drawRect(x, y + math.floor(h / 2), w, h - math.floor(h / 2), alpha, 0.11, 0.125, 0.141)
    local bs = T.borderS
    panel:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
    if not look then return end
    local c = math.max(1, math.floor(w / 29))
    local ox, oy = x + math.floor((w - c * 29) / 2), y + math.floor((h - c * 33) / 2)
    local function run(row, x0, x1, col, a)
        if not x0 or x1 < x0 or row < 0 or row > 32 then return end
        x0, x1 = math.max(0, x0), math.min(28, x1)
        panel:drawRect(ox + x0 * c, oy + row * c, (x1 - x0 + 1) * c, c, (a or 1) * alpha, col.r, col.g, col.b)
    end
    local hc, bc = look.hair, look.beard
    local n, L = look.hairName or "", look.level or 0
    local tied = look.attached
    local mohawk = has_(n, "Mohawk")
    local spike = has_(n, "Spike") and not mohawk
    local braids = has_(n, "Braid") or has_(n, "Cornrow")
    -- long hair falls behind the shoulders
    if L >= 3 and not tied and not mohawk then
        if braids then
            for r = 12, 30 do run(r, 5, 6, hc); run(r, 22, 23, hc) end
        else
            for r = 8, 28 do
                local a0, a1 = span(14.5, 17, 9.5, 12, r)
                if r >= 17 then a0, a1 = 5, 23 end
                run(r, a0, a1, hc)
            end
        end
    end
    if tied and not has_(n, "Bun") then for r = 12, 25 do run(r, 21, 23 - (r > 21 and 1 or 0), hc) end end
    if tied and has_(n, "Bun") then for r = 1, 5 do local a0, a1 = span(14.5, 3.5, 3, 2.8, r); run(r, a0, a1, hc) end end
    -- shoulders, neck, face, ears
    local sk = look.skin or SKIN
    run(27, 9, 19, SHIRT); run(28, 7, 21, SHIRT)
    for r = 29, 32 do run(r, 5, 23, SHIRT) end
    for r = 22, 26 do run(r, 12, 16, sk) end
    for r = 7, 23 do local a0, a1 = span(14.5, 15.5, 6.5, 8, r); run(r, a0, a1, sk) end
    for r = 14, 17 do run(r, 7, 7, sk); run(r, 21, 21, sk) end
    run(15, 11, 11, INK); run(15, 17, 17, INK)
    -- the beard
    local bn = look.beardName or ""
    local bl = look.beardLevel or 0
    if bn ~= "" then
        if bn == "Moustache" then run(20, 11, 17, bc)
        elseif bn == "Goatee" then run(20, 12, 16, bc); for r = 22, 25 do run(r, 12, 16, bc) end
        elseif bn == "Chops" then for r = 13, 21 do run(r, 8, 9, bc); run(r, 19, 20, bc) end
        elseif bn == "Chin" then run(24, 12, 16, bc); run(25, 12, 16, bc)
        elseif bn == "PointyChin" then
            run(23, 12, 16, bc); run(24, 13, 15, bc); run(25, 13, 15, bc); run(26, 14, 14, bc); run(27, 14, 14, bc)
        elseif bn == "BeardOnly" then
            for r = 19, 25 do
                local a0, a1 = span(14.5, 17, 7, 9, r)
                if r <= 22 then run(r, a0, 10, bc); run(r, 18, a1, bc) else run(r, a0, a1, bc) end
            end
        else
            -- Full, Long, Scruffy and any style a mod adds: by its length
            local bottom = (bl >= 3) and 31 or 25
            for r = 19, bottom do
                local a0, a1 = span(14.5, 17, 7, 9, r)
                if r > 25 then a0, a1 = 10 + math.floor((r - 26) / 2), 18 - math.floor((r - 26) / 2) end
                run(r, a0, a1, bc, 0.9)
            end
        end
    end
    run(21, 13, 15, LIP)
    -- the hair on top
    if mohawk then
        local top = (n == "MohawkFlat") and 5 or 1
        for r = top, 11 do run(r, 13, 16, hc) end
    elseif L >= 1 or tied then
        for r = 6, 11 do local a0, a1 = span(14.5, 15.5, 7.5, 9.5, r); run(r, a0, a1, hc) end
        if L >= 2 and not tied then
            for r = 12, 21 do
                local a0, a1 = span(14.5, 15.5, 7.8, 10, r)
                local f0, f1 = span(14.5, 15.5, 6.5, 8, r)
                if a0 and f0 then run(r, a0, f0 - 1, hc); run(r, f1 + 1, a1, hc) end
            end
        end
        if spike then for _, cx in ipairs({ 8, 11, 14, 17, 20 }) do for r = 2, 5 do run(r, cx, cx + 1, hc) end end end
        if braids and L <= 1 then for _, cx in ipairs({ 11, 14, 17 }) do run(7, cx, cx, INK, 0.5); run(9, cx, cx, INK, 0.5) end end
    end
end

-- what a head looks like now, or after a row
local function lookOf(p, hairName, beardName)
    local hv = p:getHumanVisual()
    local female = p:isFemale()
    local hs = hairStyle(female, hairName)
    local bs = (not female) and beardName and beardName ~= "" and getBeardStylesInstance():FindStyle(beardName) or nil
    return { hairName = hairName or "", level = hs and hs:getLevel() or 0, attached = hs and hs:isAttachedHair() or false,
             beardName = (not female) and (beardName or "") or "", beardLevel = bs and bs:getLevel() or 0,
             hair = colOf(hv:getHairColor(), { r = 0.23, g = 0.14, b = 0.09 }),
             beard = colOf(hv:getBeardColor(), { r = 0.23, g = 0.14, b = 0.09 }) }
end

-- ---------------------------------------------------------------------------
-- LAYOUT (content coordinates from the section's top; x from its left)
-- ---------------------------------------------------------------------------
local function add(L, it) L.items[#L.items + 1] = it; return it end

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
    add(L, { kind = "groove", x = x, y = y, w = cw })
    y = y + T.grooveH + T.px(12)
    add(L, { kind = "subh", text = ZeD.upper(tr("UI_ZeD_Hair_Section")), x = x, y = y })
    y = y + F(1) + T.px(8)
    local topH = math.max(T.px(HEAD_H) + T.px(3) + F(5), T.px(CUR_H) * (st.female and 2 or 3))
    add(L, { kind = "heads", x = x, y = y, w = cw, h = topH })
    y = y + topH + T.px(10)
    add(L, { kind = "parts", x = x, y = y, w = cw, h = T.px(PART_H) })
    y = y + T.px(PART_H) + T.px(8)
    local listTop = y
    if #st.rows == 0 then
        local text = st.part == "beard" and tr("UI_ZeD_Hair_EmptyBeard") or tr("UI_ZeD_Hair_EmptyHair")
        local lines = ZeD.Atoms.wrapText(text, T.fontF2, cw - T.px(16))
        local eh = T.px(20) + #lines * F(2)
        add(L, { kind = "empty", lines = lines, x = x, y = y, w = cw, h = eh })
        y = y + eh
    end
    local lastGrp, odd = nil, false
    for _, r in ipairs(st.rows) do
        if r.grp ~= lastGrp then
            lastGrp = r.grp
            local n = 0
            for _, q in ipairs(st.rows) do if q.grp == r.grp then n = n + 1 end end
            add(L, { kind = "gh", grp = r.grp, n = n, req = r.req, x = x, y = y, w = cw, h = T.px(GH_H) })
            y = y + T.px(GH_H)
            odd = false
        end
        odd = not odd
        add(L, { kind = "row", row = r, odd = not odd, x = x, y = y, w = cw, h = T.px(ROW_H) })
        y = y + T.px(ROW_H)
    end
    if #st.out > 0 then
        add(L, { kind = "outh", n = #st.out, x = x, y = y, w = cw, h = T.px(GH_H) })
        y = y + T.px(GH_H)
        if st.outOpen then
            odd = false
            for _, r in ipairs(st.out) do
                odd = not odd
                add(L, { kind = "row", row = r, odd = not odd, x = x, y = y, w = cw, h = T.px(ROW_H) })
                y = y + T.px(ROW_H)
            end
        end
    end
    add(L, { kind = "listbox", x = x, y = listTop, w = cw, h = y - listTop })
    -- the hair mods
    local note, pics = nil, false
    local pm = HB.picturesMod()
    if pm and #(st.pics or {}) > 0 then
        note = tr("UI_ZeD_Hair_NotePictures", modName(pm)); pics = true
    elseif st.part == "hair" and HB.spongieOn() then
        note = tr("UI_ZeD_Hair_NoteSpongie", modName("SpnHairAPI"))
    end
    if note then
        y = y + T.px(8)
        local bw = pics and (ZeD.TM:MeasureStringX(T.fontF3, ZeD.btnCase(tr("UI_ZeD_Hair_Pictures"))) + T.px(24)) or 0
        local lines = ZeD.Atoms.wrapText(note, T.fontF1, cw - (pics and (bw + T.px(10)) or 0))
        local nh = math.max(#lines * F(1), pics and T.px(24) or 0)
        add(L, { kind = "note", lines = lines, x = x, y = y, w = cw, h = nh })
        if pics then add(L, { kind = "pics", x = x + cw - bw, y = y, w = bw, h = T.px(24) }) end
        y = y + nh
    end
    L.h = y + T.sp.sm
    st.L = L
    return L
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local function focusedEl(win)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if not (Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.getFocusedElement) then return nil end
    return Fo.getFocusedElement(win)
end
HB.focusedEl = focusedEl
local function isFoc(win, id)
    local el = focusedEl(win)
    return el ~= nil and el.id == id
end

local function lenBar(panel, x, y, level, col, dim)
    local T = ZeD.T
    local bw, bh, gap = T.px(7), T.px(9), T.px(2)
    for i = 1, 3 do
        local bx = x + (i - 1) * (bw + gap)
        if i <= level then panel:drawRect(bx, y, bw, bh, col.a or 1, col.r, col.g, col.b)
        else panel:drawRectBorder(bx, y, bw, bh, dim.a or 1, dim.r, dim.g, dim.b) end
    end
    return 3 * bw + 2 * gap
end

local function drawHeads(panel, win, st, it, y)
    local T = ZeD.T
    local p = win._playerObj
    local hv = p:getHumanVisual()
    local bw, bh = T.px(HEAD_W), T.px(HEAD_H)
    local curHair, curBeard = hv:getHairModel(), (not st.female) and hv:getBeardModel() or ""
    HB.drawHead(panel, it.x, y, bw, bh, lookOf(p, curHair, curBeard), 1)
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
    if sel and not sel.out then
        local h2, b2 = curHair, curBeard
        if sel.part == "beard" then b2 = sel.style else h2 = sel.style end
        HB.drawHead(panel, bx, y, bw, bh, lookOf(p, h2, b2), 1)
    else
        HB.drawHead(panel, bx, y, bw, bh, nil, 0.35)
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
            mw = ZeD.TM:MeasureStringX(f1, meta) + T.px(6) + T.px(25)
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
            local used = lenBar(panel, mx, ry + math.floor((rh - T.px(9)) / 2), d[4], T.text, dim)
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

local function drawParts(panel, win, st, it, y)
    local T = ZeD.T
    local bs, ac = T.borderS, T.accent
    local halves = st.female and { "hair" } or { "hair", "beard" }
    local hw = math.floor(it.w / #halves)
    local foc = isFoc(win, "hb:part")
    for i, part in ipairs(halves) do
        local hx = it.x + (i - 1) * hw
        local ww = (i == #halves) and (it.x + it.w - hx) or hw
        local on = st.part == part
        if on then panel:drawRect(hx, y, ww, it.h, 1, ac.r, ac.g, ac.b) end
        local word = (part == "hair") and getText("IGUI_char_HairStyle") or getText("IGUI_char_BeardStyle")
        local label = tr("UI_ZeD_Hair_PartCount", word, st.counts[part] or 0)
        local tc = on and T.textOnAccent or T.text
        local tw = ZeD.TM:MeasureStringX(T.fontF1, label)
        panel:drawText(label, hx + math.floor((ww - tw) / 2), y + math.floor((it.h - F(1)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)
        if i > 1 then panel:drawRect(hx, y, T.px(1), it.h, bs.a or 1, bs.r, bs.g, bs.b) end
        if foc and on then ZeD.Atoms.drawAccentRing(panel, hx, y, ww, it.h, T.px(2), T.accentBright) end
    end
    panel:drawRectBorder(it.x, y, it.w, it.h, bs.a or 1, bs.r, bs.g, bs.b)
end

local function drawGh(panel, win, st, it, y, mx, my)
    local T = ZeD.T
    local s1, bd = T.surf1, T.border
    local foc = it.kind == "outh" and isFoc(win, "hb:out")
    local hov = it.kind == "outh" and mx and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    panel:drawRect(it.x, y, it.w, it.h, 1, s1.r, s1.g, s1.b)
    local ac = T.accent
    if foc then panel:drawRect(it.x, y, it.w, it.h, 0.55, ac.r, ac.g, ac.b)
    elseif hov then panel:drawRect(it.x, y, it.w, it.h, 0.22, ac.r, ac.g, ac.b) end
    panel:drawRect(it.x, y + it.h - T.px(1), it.w, T.px(1), bd.a or 1, bd.r, bd.g, bd.b)
    local c = foc and T.textOnFocus or (T.toneLo or T.textDim)
    local ty = y + math.floor((it.h - F(5)) / 2)
    local tx = it.x + T.px(8)
    local left, right
    if it.kind == "outh" then
        local tri = T.px(5)
        if st.outOpen then ZeD.Atoms.drawTriangleDown(panel, tx, y + math.floor((it.h - tri) / 2), tri, c)
        else ZeD.Atoms.drawTriangleRight(panel, tx, y + math.floor((it.h - tri) / 2), tri, c) end
        tx = tx + tri + T.px(6)
        left, right = ZeD.upper(tr("UI_ZeD_Hair_OutOfReach")), tostring(it.n)
    else
        left = ZeD.upper(tr(GROUP_KEY[it.grp]))
        local words = (it.grp == "Tie") and tr("UI_ZeD_Hair_NoTool") or toolWords(it.req)
        right = (it.n > 1) and (words .. " | " .. it.n) or words
    end
    panel:drawText(left, tx, ty, c.r, c.g, c.b, c.a or 1, T.fontF5)
    local rw = ZeD.TM:MeasureStringX(T.fontF5, right)
    panel:drawText(right, it.x + it.w - T.px(8) - rw, ty, c.r, c.g, c.b, c.a or 1, T.fontF5)
end

local function drawRow(panel, win, st, it, y, mx, my)
    local T = ZeD.T
    local r = it.row
    local ac, bd = T.accent, T.border
    local sel = st.sel == r.key
    local foc = isFoc(win, "hb:row:" .. r.key)
    local hov = mx and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    if it.odd then local s = T.stripe; panel:drawRect(it.x, y, it.w, it.h, s.a or 1, s.r, s.g, s.b) end
    if sel then panel:drawRect(it.x, y, it.w, it.h, 1, ac.r, ac.g, ac.b)
    elseif foc then panel:drawRect(it.x, y, it.w, it.h, 0.55, ac.r, ac.g, ac.b)
    elseif hov then panel:drawRect(it.x, y, it.w, it.h, 0.22, ac.r, ac.g, ac.b) end
    if foc then ZeD.Atoms.drawAccentRing(panel, it.x, y, it.w, it.h, T.px(2), T.accentBright) end
    panel:drawRect(it.x, y + it.h - T.px(1), it.w, T.px(1), bd.a or 1, bd.r, bd.g, bd.b)
    local ink = sel and T.textOnAccent or (foc and T.textOnFocus or T.text)
    local dimInk = sel and T.textOnAccent or (foc and T.textOnFocus or (T.toneLo or T.textDim))
    local nameA = (r.out or not r.ok) and not sel and not foc and 0.45 or 1
    -- right side: the tool and its dot, or the reason's tag
    local rx = it.x + it.w - T.px(8)
    local f1 = T.fontF1
    local ty1 = y + math.floor((it.h - F(1)) / 2)
    if r.out then
        local tw = ZeD.TM:MeasureStringX(f1, r.tag)
        rx = rx - tw
        panel:drawText(r.tag, rx, ty1, dimInk.r, dimInk.g, dimInk.b, dimInk.a or 1, f1)
    elseif r.req ~= "none" then
        local words = toolWords(r.req)
        local tw = ZeD.TM:MeasureStringX(f1, words)
        rx = rx - tw
        panel:drawText(words, rx, ty1, ink.r, ink.g, ink.b, ink.a or 1, f1)
        local dsz = T.px(8)
        rx = rx - T.px(5) - dsz
        local dy = y + math.floor((it.h - dsz) / 2)
        if has(r.req, st.tools) then ZeD.Atoms.drawStatusDot(panel, rx, dy, sel and T.textOnAccent or T.positive, dsz)
        else ZeD.Atoms.drawStatusRing(panel, rx, dy, dimInk, dsz) end
    end
    -- the hair mod's tag
    if r.mod then
        local tag = ZeD.upper(modName(r.mod):match("^(%a+)") or r.mod)
        local tw = ZeD.TM:MeasureStringX(T.fontF5, tag) + T.px(8)
        local th = T.px(14)
        rx = rx - T.px(8) - tw
        local tagY = y + math.floor((it.h - th) / 2)
        local bc = sel and T.textOnAccent or T.borderS
        panel:drawRectBorder(rx, tagY, tw, th, bc.a or 1, bc.r, bc.g, bc.b)
        panel:drawText(tag, rx + T.px(4), tagY + math.floor((th - F(5)) / 2), dimInk.r, dimInk.g, dimInk.b, dimInk.a or 1, T.fontF5)
    end
    local nx = it.x + T.px(8)
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
    if not inView then mx, my = nil, nil end
    st.hover = nil
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
            if k == "groove" then ZeD.Atoms.drawGroove(panel, ix, y, it.w)
            elseif k == "subh" then
                local c = T.toneLo or T.textDim
                panel:drawText(it.text, ix, y, c.r, c.g, c.b, c.a or 1, T.fontF1)
            elseif k == "heads" then drawHeads(panel, win, st, item, y)
            elseif k == "parts" then drawParts(panel, win, st, item, y)
            elseif k == "gh" or k == "outh" then drawGh(panel, win, st, item, y, mx, my)
            elseif k == "row" then drawRow(panel, win, st, item, y, mx, my)
            elseif k == "empty" then
                local c = T.toneLo or T.textDim
                for i, line in ipairs(it.lines) do
                    panel:drawText(line, ix + T.px(8), y + T.px(10) + (i - 1) * F(2), c.r, c.g, c.b, c.a or 1, T.fontF2)
                end
            elseif k == "listbox" then
                local bd = T.border
                panel:drawRectBorder(ix, y, it.w, it.h, bd.a or 1, bd.r, bd.g, bd.b)
            elseif k == "note" then
                local c = T.toneLo or T.textDim
                for i, line in ipairs(it.lines) do
                    panel:drawText(line, ix, y + (i - 1) * F(1), c.r, c.g, c.b, c.a or 1, T.fontF1)
                end
            elseif k == "pics" then
                local ac = T.accent
                ZeD.Molecules.drawButton(panel, ix, y, it.w, it.h, tr("UI_ZeD_Hair_Pictures"), "default", false,
                    { fill = isFoc(win, "hb:pics") and { r = ac.r, g = ac.g, b = ac.b, a = 0.55 } or nil })
            end
        end
        -- click zones (only what shows) and the row under the mouse
        if (k == "row" or k == "outh" or k == "parts" or k == "pics") and vis then
            local zy0, zy1 = math.max(viewY, y), math.min(viewY + viewH, y + it.h)
            if zy1 > zy0 then
                st.zones[#st.zones + 1] = { x = ix, y = zy0, w = it.w, h = zy1 - zy0, item = it }
                if k == "row" and mx and mx >= ix and mx < ix + it.w and my >= zy0 and my < zy1 then
                    st.hover = { key = it.row.key, x = ix, y = y, w = it.w, h = it.h }
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- the action strip at the drawer's foot (what the picked row needs; the button)
-- ---------------------------------------------------------------------------
function HB.stripH() return ZeD.T.px(STRIP_H) end

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

function HB.drawStrip(panel, win, x, y, w, h)
    local T = ZeD.T
    local st = state(win)
    local p = win._playerObj
    st.btn = nil
    if not p then return end
    local s2, bs = T.surf2, T.borderS
    panel:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
    panel:drawRect(x, y, w, T.px(1), bs.a or 1, bs.r, bs.g, bs.b)
    local pad = T.sp.sm
    local dsz = T.px(8)
    local tc, dim = T.text, T.toneLo or T.textDim
    local l1, l2, dot, verb, canDo, extra = nil, nil, "ring", nil, false, nil
    local pct = nil
    if st.busy then
        local b = st.busy
        local key = (b.part == "beard") and "UI_ZeD_Hair_BusyTrim"
            or (b.verb == "Tie" and "UI_ZeD_Hair_BusyTie") or (b.verb == "Untie" and "UI_ZeD_Hair_BusyUntie") or "UI_ZeD_Hair_BusyCut"
        l1, dot = tr(key), "busy"
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        local a = q and q.queue and q.queue[1]
        pct = 0
        if a and (a.Type == "ISCutHair" or a.Type == "ISTrimBeard") and a.getJobDelta then
            local ok, v = pcall(a.getJobDelta, a)
            if ok and v then pct = v end
        end
        verb, canDo = "stop", true
    else
        local r = findRow(st, st.sel)
        if not r then
            if st.done then l1, dot = st.done, "pos" else l1 = tr("UI_ZeD_Hair_Pick") end
            local pad_ = ZeD.Input and ZeD.Input.Detector and ZeD.Input.Detector.getMode and ZeD.Input.Detector.getMode() == "gamepad"
            l2 = pad_ and tr("UI_ZeD_Hair_HintPad") or tr("UI_ZeD_Hair_HintMouse")
            verb = (st.part == "beard") and "Trim" or "Cut"
        elseif r.out then
            l1, l2 = tr("UI_ZeD_Hair_OutTitle", r.label), r.why
            verb = (st.part == "beard") and "Trim" or "Cut"
        else
            l1 = r.label
            if r.mod then extra = tr("UI_ZeD_Hair_FromMod", modName(r.mod)) end
            l2 = table.concat(notesFor(st, p, r), " | ")
            dot = r.ok and "pos" or "ring"
            verb, canDo = r.verb, r.ok
        end
    end
    -- the button
    local label = (verb == "stop") and tr("UI_ZeD_Hair_Stop") or tr(VERB_KEY[verb] or "UI_ZeD_Hair_VerbCut")
    local bw = math.max(T.px(64), ZeD.TM:MeasureStringX(T.fontF3, ZeD.btnCase(label)) + T.px(28))
    local bh = T.px(26)
    local bx, by = x + w - pad - bw, y + math.floor((h - bh) / 2)
    local ac = T.accent
    ZeD.Molecules.drawButton(panel, bx, by, bw, bh, label, (verb ~= "stop") and "primary" or "default", false,
        { fill = isFoc(win, "hb:do") and { r = ac.r, g = ac.g, b = ac.b, a = 0.55 } or nil })
    if not canDo then panel:drawRect(bx, by, bw, bh, 0.6, s2.r, s2.g, s2.b) end
    st.btn = { x = bx, y = by, w = bw, h = bh, on = canDo, stop = verb == "stop" }
    -- the lines
    local tx = x + pad
    local tw = bx - T.px(10) - tx
    local twoLines = (l2 ~= nil and l2 ~= "") or pct ~= nil
    local l1y = y + math.floor((h - F(2)) / 2)
    if twoLines then l1y = y + math.floor((h - F(2) - T.px(3) - F(5)) / 2) end
    local dy = l1y + math.floor((F(2) - dsz) / 2)
    if dot == "pos" then ZeD.Atoms.drawStatusDot(panel, tx, dy, T.positive, dsz)
    elseif dot == "busy" then ZeD.Atoms.drawStatusDot(panel, tx, dy, T.accent, dsz)
    else ZeD.Atoms.drawStatusRing(panel, tx, dy, dim, dsz) end
    local lx = tx + dsz + T.px(6)
    local t1 = ZeD.Atoms.truncateText(l1 or "", T.fontF2, tw - (lx - tx))
    panel:drawText(t1, lx, l1y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    if extra then
        local ex = lx + ZeD.TM:MeasureStringX(T.fontF2, t1) + T.px(6)
        if ex < tx + tw then panel:drawText(ZeD.Atoms.truncateText(extra, T.fontF5, tx + tw - ex), ex, l1y + F(2) - F(5), dim.r, dim.g, dim.b, dim.a or 1, T.fontF5) end
    end
    if pct then
        local barW = math.min(T.px(200), tw)
        local barY = l1y + F(2) + T.px(4)
        local s4 = T.surf4 or T.surf3
        panel:drawRect(tx, barY, barW, T.px(4), 1, s4.r, s4.g, s4.b)
        panel:drawRect(tx, barY, math.floor(barW * math.max(0, math.min(1, pct))), T.px(4), 1, ac.r, ac.g, ac.b)
    elseif l2 then
        panel:drawText(ZeD.Atoms.truncateText(l2, T.fontF5, tw), tx, l1y + F(2) + T.px(3), dim.r, dim.g, dim.b, dim.a or 1, T.fontF5)
    end
end

-- ---------------------------------------------------------------------------
-- the hover balloon (also the Identity traits' and the Traits tab's): a title and
-- wrapped lines in the ZeD hint style, below the anchor, kept inside the clip
-- ---------------------------------------------------------------------------
function HB.balloon(panel, title, body, ax, ay, aw, ah, clip)
    local T = ZeD.T
    local maxW = T.px(280)
    local pad, padY = T.px(8), T.px(5)
    local lines = {}
    if body and body ~= "" then lines = ZeD.Atoms.wrapText(body, T.fontF2, maxW - pad * 2) end
    local w = title and ZeD.TM:MeasureStringX(T.fontF2, title) or 0
    for _, l in ipairs(lines) do w = math.max(w, ZeD.TM:MeasureStringX(T.fontF2, l)) end
    w = math.min(maxW, w + pad * 2)
    local nl = #lines + (title and 1 or 0)
    local h = nl * F(2) + padY * 2
    local cx, cy, cw, ch = 0, 0, panel:getWidth(), panel:getHeight()
    if clip then cx, cy, cw, ch = clip.x, clip.y, clip.w, clip.h end
    local x = math.max(cx + T.px(2), math.min(ax + T.px(14), cx + cw - w - T.px(2)))
    local y = ay + ah + T.px(4)
    if y + h > cy + ch then y = ay - h - T.px(4) end
    if y < cy then y = cy + T.px(2) end
    local s2, bs, tc = T.surf2, T.borderS, T.text
    panel:drawRect(x + T.px(2), y + T.px(2), w, h, 0.5, 0, 0, 0)
    panel:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
    panel:drawRectBorder(x, y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
    local ly = y + padY
    if title then
        local hc = T.textHead or tc
        panel:drawText(ZeD.Atoms.truncateText(title, T.fontF2, w - pad * 2), x + pad, ly, hc.r, hc.g, hc.b, hc.a or 1, T.fontF2)
        ly = ly + F(2)
    end
    for _, l in ipairs(lines) do
        panel:drawText(l, x + pad, ly, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        ly = ly + F(2)
    end
end

-- a hint after a short pause on the same thing (focus shows it at once)
function HB.hintDue(st, key, now)
    if not key then st.hintKey = nil; return false end
    if st.hintKey ~= key then st.hintKey, st.hintSince = key, now; return false end
    return now - (st.hintSince or now) >= HINT_MS
end

-- the hover balloon for a row: the game's own hint
function HB.drawHints(panel, win, clip)
    local st = state(win)
    local hv = st.hover
    local now = getTimestampMs()
    if not HB.hintDue(st, hv and hv.key, now) then return end
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
    HB.balloon(panel, r.label, body, hv.x, hv.y, hv.w, hv.h, clip)
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
            elseif it.kind == "outh" then
                st.outOpen = not st.outOpen
            elseif it.kind == "parts" then
                local half = (not st.female) and (x >= it.x + st.x + it.w / 2) or false
                HB.setPart(win, half and "beard" or "hair")
            elseif it.kind == "pics" then
                HB.openPictures(win)
            end
            getSoundManager():playUISound("UIActivateButton")
            return true
        end
    end
    return false
end

-- the controller's stops: the Hair | Beard switch, each row, Out of reach, Pictures
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
        elseif it.kind == "outh" then
            e = { id = "hb:out", onActivate = function() st.outOpen = not st.outOpen end }
        elseif it.kind == "pics" then
            e = { id = "hb:pics", onActivate = function(w) HB.openPictures(w) end }
        end
        if e then
            e.x, e.y, e.w, e.h, e.cy, e.hbStop = x, y, it.w, it.h, it.y, true
            e.onFocus = e.onFocus or function() end
            out[#out + 1] = e
        end
    end
    -- the strip's Stop while a cut runs
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
    return tostring(st.part) .. ":" .. tostring(st.outOpen) .. ":" .. tostring(#(st.rows or {})) .. ":"
        .. tostring(#(st.out or {})) .. ":" .. tostring(st.busy ~= nil) .. ":" .. tostring(st.rows and st.rows[1] and st.rows[1].key)
end

function HB.state(win) return state(win) end
