-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/WoundsOverhaul.lua
-- ============================================================================
-- SUPPORT FOR WOUNDS OVERHAUL [B42] (mod id WoundsOverhaul, Workshop 3775026731,
-- by looo6). Client. What follows about the mod was read from its own code,
-- version 0.6.2.
--
-- What the mod does: "the Health tab becomes an examination". A limb has to be
-- looked at before the game names what is on it or offers to treat it (on its
-- strictest examination setting, the default). Looking is a timed action
-- (WoundsExamineAction) that trains First Aid. Its own examination panel lives in
-- the game's Character Info window, which ZeD hides, so with ZeD on a player could
-- never examine: ZeD's Health tab named every wound outright, and the part's menu
-- (which goes through the mod's wrap of ISHealthPanel.doBodyPartContextMenu) held
-- back to "Something is wrong here." with no way past it.
--
-- What ZeD does now, in its own Health tab, through the tab's general hooks
-- (ZeD.HealthTab.addExtras):
--   holds      a part the mod holds back (its own rule, Wounds.body.needsExamFirst,
--              the one its shims for other health UIs use) names no wound: the tab
--              keeps what the character knows without looking (pain, stiffness, a
--              bandage, stitches, a splint, a poultice), as the mod's Ergonomic UI
--              shim does.
--   partLines  on such a part, the mod's own line "Something is wrong here." in
--              the detail view and as a tag in the injury list.
--   openPart   the part's menu (right-click, or A on the controller): on a part
--              held back, Examine (the mod's examination, below) over the mod's
--              gray line; on any other part, the game's menu through the mod's wrap,
--              marked as coming from a view that has applied the rule
--              (Wounds.menuFromView, as the mod's own panel does), so every one of
--              the mod's treatments is in it. A skull, spine or torso fracture with
--              nothing else on the part offers nothing, the mod's rule.
--
-- The examination is the mod's own code, run exactly as its panel runs it: its body
-- view's beginExamine works out the workload from the findings, the familiarity from
-- the last look and whether the look pays XP, refuses a second look already queued,
-- and queues WoundsExamineAction:new(character, part, onFinish, familiar, workload);
-- onFinish writes the mod's examination record. ZeD hands it a stand-in for the view
-- (a plain table that reads the mod's WoundsBodyView class, the way the mod's own
-- menu extras hand its offers a stand-in): nothing is drawn, nothing is added to the
-- screen. The stand-in's refresh (the mod's own, at most every quarter second while
-- the tab reads the body, as its panel's) gathers the findings and drops the record
-- of a limb that has healed, as the mod's panel does while it is open.
--
-- Nothing of the mod's is wrapped or replaced and ZeD saves nothing. The one thing
-- ZeD sets is the mod's own flag Wounds.menuFromView, for the length of the menu
-- call, as the mod's panel sets it. Every call into the mod goes through pcall; when
-- a piece is missing (another version of the mod) the tab and the menu are what they
-- were before this file, and the mod's own wrap still holds the menu back.
--
-- Not carried over: the mod's own findings (sepsis, an open fracture, a burn's
-- degree, a closure's quality) are not listed by the tab, and a part looked at once
-- names a later wound at once (the mod's rule for other health UIs), where the mod's
-- own panel would ask for a second look.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "WoundsOverhaul"

-- Is the mod switched on in this game? getActivatedMods() is a Java list of mod ids;
-- a leading backslash (a mod loaded by its folder id) is cut off before comparing.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do                           -- Java lists count from 0
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end   -- a file's top level can "return": the rest never runs

require "ZeD/Tokens"
require "ZeD/HealthTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.WoundsOverhaul = S

-- How often the stand-in re-reads the body, in real ms (the mod's own panel: 250)
local REFRESH_MS = 250
-- The color of the mod's "something is wrong" line in its own shims (mid severity)
local HELD_COLOR = { r = 0.9, g = 0.6, b = 0.2, a = 1 }

-- The mod's main table, or nil while it is not there or lacks the rule we read.
-- Asked every time: nothing of the mod's is kept.
local function WO()
    local m = Wounds                              -- (an unset global reads as nil)
    if type(m) == "table" and type(m.body) == "table"
        and type(m.body.needsExamFirst) == "function" then
        return m
    end
    return nil
end

-- The mod's body view class, when it has the two methods ZeD runs
local function viewClass()
    local V = WoundsBodyView
    if type(V) == "table" and type(V.refresh) == "function"
        and type(V.beginExamine) == "function" then
        return V
    end
    return nil
end

-- Does the mod hold this part back until it is examined? (its own rule)
local function held(bodyPart)
    local m = WO()
    if not (m and bodyPart) then return false end
    local ok, yes = pcall(m.body.needsExamFirst, bodyPart)
    return ok and yes == true
end

-- The mod's own words for a part held back ("Something is wrong here.")
local function unexamined()
    return ZeD.tr("IGUI_Wounds_Unexamined")
end

-- ---------------------------------------------------------------------------
-- THE STAND-IN for the mod's body view, one per local player. It carries only what
-- the view's examination methods read (the player, the findings, no limbs to draw);
-- the methods are the mod's, through the metatable. A refresh that fails once is
-- not tried again (each failure would be one more stack trace in console.txt).
-- ---------------------------------------------------------------------------
local stands = {}
local broken = false

local function model(playerObj, now)
    local V = viewClass()
    if broken or not (V and playerObj) then return nil end
    local okN, num = pcall(function() return playerObj:getPlayerNum() end)
    if not okN or type(num) ~= "number" then return nil end
    local st = stands[num]
    if not st or st.view.player ~= playerObj then
        st = { view = setmetatable({ player = playerObj, woundInfo = {}, bps = {} }, { __index = V }), at = nil }
        stands[num] = st
    end
    local t = getTimestampMs and getTimestampMs() or 0
    if now or not st.at or t - st.at >= REFRESH_MS or t < st.at then
        st.at = t
        local ok, err = pcall(V.refresh, st.view)
        if not ok then
            broken = true
            if ZeD.logOnce then ZeD.logOnce("woundsov refresh", tostring(err)) end
            return nil
        end
    end
    return st.view
end

-- ---------------------------------------------------------------------------
-- EXAMINE: the mod's examination of one part, as its panel starts it
-- ---------------------------------------------------------------------------
function S.examine(playerObj, bodyPart)
    local m, V = WO(), viewClass()
    if not (m and V and playerObj and bodyPart) then return false end
    local view = model(playerObj, true)                    -- the findings as they are now
    if not view then return false end
    local ok, err = pcall(function()
        local bd = (m.body.damage and m.body.damage(playerObj)) or playerObj:getBodyDamage()
        local key = m.body.keyOfType(bd, bodyPart:getType())
        if not key then return end
        -- (the view's own limb record: the part and its key)
        V.beginExamine(view, { bodyPart = bodyPart, woundKey = key }, key, view.woundInfo[key] or {})
    end)
    if not ok and ZeD.logOnce then ZeD.logOnce("woundsov examine", tostring(err)) end
    return ok
end

-- (the menu's Examine: ISContextMenu calls it with the option's target, then its argument)
local function onExamine(playerObj, bodyPart)
    S.examine(playerObj, bodyPart)
end

-- The menu of a part held back: Examine, and the mod's gray line under it
local function examineMenu(playerObj, bodyPart, panel, x, y)
    local num = playerObj:getPlayerNum()
    local context = ISContextMenu.get(num, x + panel:getAbsoluteX(), y + panel:getAbsoluteY())
    context:addOption(ZeD.tr("UI_ZeD_Health_Examine"), playerObj, onExamine, bodyPart)
    local note = context:addOption(unexamined(), nil)
    note.notAvailable = true
    -- the game's own last lines, so a controller lands on the menu
    local pad = JoypadState and JoypadState.players and JoypadState.players[num + 1]
    if pad and context:getIsVisible() then
        context.mouseOver = 1
        context.origin = panel
        pad.focus = context
        updateJoypadFocus(pad)
    end
end

-- ---------------------------------------------------------------------------
-- THE TAB'S HOOKS (ZeD.HealthTab.addExtras)
-- ---------------------------------------------------------------------------
--- True while the mod holds this part's diagnosis back (it wants an examination first).
function S.holds(playerObj, bodyPart)
    if not WO() then return false end
    model(playerObj)        -- (keeps the mod's examination record as its open panel would)
    return held(bodyPart)
end

--- On a part held back, the mod's own gray line; nil on any other part.
function S.partLines(playerObj, bodyPart)
    if not held(bodyPart) then return nil end
    return { { text = unexamined(), color = HELD_COLOR, severity = "warning" } }
end

--- The part's menu: Examine on a held part, the game's menu through the mod's wrap on
--- the rest. True when handled here; anything else and the tab opens the game's menu.
function S.openPart(playerObj, bodyPart, panel, x, y)
    local m = WO()
    if not (m and viewClass() and playerObj and bodyPart and panel) then return false end
    local view = model(playerObj)
    if held(bodyPart) then
        if not view then return false end                  -- (the mod's own wrap shows its gray line)
        examineMenu(playerObj, bodyPart, panel, x, y)
        return true
    end
    -- the mod's rule from its own panel: an axial fracture alone offers nothing
    local bare = false
    pcall(function() bare = m.body.bareAxialFracture and m.body.bareAxialFracture(bodyPart) == true end)
    if bare then return true end
    -- the game's menu with every treatment of the mod's: ZeD has applied the rule above
    m.menuFromView = true
    local ok, err = pcall(ISHealthPanel.doBodyPartContextMenu, panel, bodyPart, x, y)
    m.menuFromView = nil
    if not ok and ZeD.logOnce then ZeD.logOnce("woundsov menu", tostring(err)) end
    return ok        -- (on an error the tab opens the game's menu itself, as before this file)
end

ZeD.HealthTab.addExtras(MOD_ID, S)
