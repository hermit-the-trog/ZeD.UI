-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MpLeftovers.lua
-- ============================================================================
-- MULTIPLAYER WINDOWS THE GAME STILL OPENED (ZeDUI/VANILLA_WINDOWS_20261107.md, group C). Each through the game's own
-- data and calls; each falls back to the game's own window in safe mode or when ZeD's cannot be built.
--
--   C4  SERVER SAVING   the game's "Server saving game. Please wait." box (ISServerSavingMessage, OnServerStartSaving /
--                       OnServerFinishSaving): a notice in Messages, as every ZeD notice is.
--   C5  MARK SHARING    the map mark's Sharing (ISWorldMapSharing, from MapsTab.lua's mark menu): a form card in the
--                       map's drawer, at the map's right edge: Private, Everyone or Other; under Other, Faction, Safehouse and the players by name. Done
--                       hands the choice to the mark as the game's panel does (symbol:setSharing).
--   C15 EDIT ITEM       the admin's Edit item (ISItemEditorUI.OpenPanel, from the inventory menu): the item's card in edit
--                       mode, the game's own list of fields (ISItemEditPanel:initElements) as field rows, Save in the band;
--                       Save runs the game's own saveAll and, on a server, its InvMngUpdateItem.
--   C16 ADMIN MESSAGE   the game's admin pop-up (ISAdminMessage, OnAdminMessage; ZeD_Tickets.lua passes on what is not a
--                       ticket note): a note in Messages, with Teleport on it where the game's had "Teleport?".
-- C1 and C3 are the pause window's pages (ZeD_MainMenuPlayers.lua), C2 the Server tab's card (ServerTab.lua), C17 the
-- desk screen after a disconnect (ZeD_LeftScreen.lua).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/ZeD_FormCard"
require "ISUI/ISServerSavingMessage"
require "ISUI/AdminPanel/ISItemEditorUI"
require "ISUI/AdminPanel/ISItemEditPanel"

ZeD = ZeD or {}
ZeD.MpLeftovers = ZeD.MpLeftovers or {}
local L = ZeD.MpLeftovers

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function safeOn() return ZeD.Safe ~= nil and ZeD.Safe.on ~= nil and ZeD.Safe.on() end
local function words(s)
    local S = ZeD.ServerTab
    s = ZeD.btnCase(tostring(s or ""))
    return (S and S.btnWords) and S.btnWords(s) or s
end

-- ---------------------------------------------------------------------------
-- C4: SERVER SAVING, A NOTICE IN MESSAGES (the director's standing rule: every ZeD notice is a bubble out of the belt's
-- Messages icon and is kept in Messages, never a box at the top of the screen or in a corner; the bubble itself is
-- Messages' own drawing). The finish needs nothing: the note stays in Messages as a record
-- ---------------------------------------------------------------------------
function L.savingStart()
    local MS = ZeD.Messages
    if safeOn() or not (MS and MS.adminMsg and getPlayer()) then
        L.savingVanilla = true
        return ISServerSavingMessage.showPauseMessage()
    end
    pcall(MS.adminMsg, tr("UI_ZeD_Srv_Saving"), nil)
end

function L.savingDone()
    if L.savingVanilla then
        L.savingVanilla = nil
        return ISServerSavingMessage.showSavingFinishMessage()
    end
end

if not L.savingHooked and ISServerSavingMessage and Events.OnServerStartSaving then
    L.savingHooked = true
    Events.OnServerStartSaving.Remove(ISServerSavingMessage.showPauseMessage)
    Events.OnServerFinishSaving.Remove(ISServerSavingMessage.showSavingFinishMessage)
    Events.OnServerStartSaving.Add(function() L.savingStart() end)
    Events.OnServerFinishSaving.Add(function() L.savingDone() end)
end

-- ---------------------------------------------------------------------------
-- C16: AN ADMIN MESSAGE, AS A NOTE IN MESSAGES (false: the game's pop-up instead)
-- ---------------------------------------------------------------------------
-- the game's message is rich text: its tags (<LINE>, <RGB:1,0,0>, <SIZE:medium>) are left out of the plain note
function L.plain(s)
    s = tostring(s or "")
    s = string.gsub(s, "%s*<LINE>%s*", " ")
    s = string.gsub(s, "<%u+[%w:,%.%-]*>", "")
    s = string.gsub(s, "%s+", " ")
    return (string.gsub(s, "^%s+", ""))
end

function L.adminMessage(message, x, y, z)
    if safeOn() then return false end
    local MS = ZeD.Messages
    if not (MS and MS.adminMsg and getPlayer()) then return false end
    local tp = nil
    if type(x) == "number" and x > -1 then tp = { x = x, y = y, z = z } end
    local ok = pcall(MS.adminMsg, L.plain(message), tp)
    return ok
end

-- the note's Teleport: the game's own answer to its "Teleport?" (ISAdminMessage:onClick, YES)
function L.teleport(tp)
    if not tp then return end
    if isClient() then
        pcall(SendCommandToServer, "/teleportto " .. tostring(tp.x) .. "," .. tostring(tp.y) .. "," .. tostring(tp.z))
    else
        local p = getPlayer()
        if p then pcall(function() p:teleportTo(tp.x, tp.y, tp.z) end) end
    end
end

-- ---------------------------------------------------------------------------
-- C5: SHARING A MAP MARK
-- ---------------------------------------------------------------------------
-- the players to pick from: everyone online (the scoreboard), then anyone the mark is shared with who is not on now
function L.sharePlayers(sym)
    local out, seen = {}, {}
    local me = safe(function() return getPlayer():getUsername() end, "")
    local list = (ZeD.PausePlayers and ZeD.PausePlayers.list) or {}
    if #list == 0 and ZeD.ServerTab then list = ZeD.ServerTab.players or {} end
    for _, e in ipairs(list) do
        if e.user and e.user ~= me and not seen[e.user] then
            seen[e.user] = true
            out[#out + 1] = { user = e.user, name = e.name or e.user }
        end
    end
    local n = safe(function() return sym:getVisibleToPlayerCount() end, 0)
    for i = 0, n - 1 do
        local u = safe(function() return sym:getVisibleToPlayerByIndex(i) end, nil)
        if u and not seen[u] then
            seen[u] = true
            out[#out + 1] = { user = u, name = u, away = true }
        end
    end
    return out
end

-- the mark's sharing now, as the game's panel reads it (PanelMain:setCurrentSymbol)
function L.shareState(sym)
    local s = { mode = "other", faction = false, safehouse = false, players = {} }
    if safe(function() return sym:isPrivate() end, true) then s.mode = "private"
    elseif safe(function() return sym:isVisibleToEveryone() end, false) then s.mode = "all"
    else
        s.faction = safe(function() return sym:isVisibleToFaction() end, false)
        s.safehouse = safe(function() return sym:isVisibleToSafehouse() end, false)
    end
    local n = safe(function() return sym:getVisibleToPlayerCount() end, 0)
    for i = 0, n - 1 do
        local u = safe(function() return sym:getVisibleToPlayerByIndex(i) end, nil)
        if u then s.players[u] = true end
    end
    return s
end

-- the choice, handed to the mark as the game's ISWorldMapSharing:applyChanges does
function L.shareApply(sym, s)
    if not safe(function() return sym:canClientModify() end, false) then return end
    if s.mode == "private" then sym:setSharing(nil); return end
    if s.mode == "all" then sym:setSharing({ everyone = true }); return end
    local players = {}
    for u, on in pairs(s.players) do if on then players[#players + 1] = u end end
    table.sort(players)
    sym:setSharing({ everyone = false, faction = s.faction, safehouse = s.safehouse, players = players })
end

function L.shareRows(sym, s)
    local rows = {}
    local function pick(mode) return function() s.mode = mode end end
    rows[#rows + 1] = { k = "radio", id = "private", text = getText("IGUI_Map_Sharing_Private"), on = s.mode == "private", run = pick("private") }
    rows[#rows + 1] = { k = "radio", id = "all", text = getText("IGUI_Map_Sharing_Everyone"), on = s.mode == "all", run = pick("all") }
    rows[#rows + 1] = { k = "radio", id = "other", text = getText("IGUI_Map_Sharing_Other"), on = s.mode == "other", run = pick("other") }
    local off = s.mode ~= "other"
    rows[#rows + 1] = { k = "check", id = "faction", ind = 18, text = getText("IGUI_Map_Sharing_Faction"), on = s.faction, disabled = off,
        run = function() s.faction = not s.faction end }
    rows[#rows + 1] = { k = "check", id = "safehouse", ind = 18, text = getText("IGUI_Map_Sharing_Safehouse"), on = s.safehouse, disabled = off,
        run = function() s.safehouse = not s.safehouse end }
    rows[#rows + 1] = { k = "label", text = getText("IGUI_Map_Sharing_Players") }
    local list = L.sharePlayers(sym)
    if #list == 0 then rows[#rows + 1] = { k = "line", text = tr("UI_ZeD_MM_NoPlayers") } end
    for _, e in ipairs(list) do
        rows[#rows + 1] = { k = "check", id = "p:" .. e.user, ind = 18, text = e.away and (e.user .. " | " .. tr("UI_ZeD_Map_ShareAway")) or e.name,
            on = s.players[e.user] == true, disabled = off, run = function() s.players[e.user] = not s.players[e.user] end }
    end
    return rows
end

-- opens the card for the mark; false when it can't (the game's panel opens instead)
function L.openSharing(mp, sym, fromPad)
    if safeOn() or not (ZeD.FormCard and sym and isClient()) then return false end
    if not safe(function() return sym:canClientModify() end, false) then return false end
    if L.shareCard and not L.shareCard._done then L.shareCard:finish() end
    if scoreboardUpdate then pcall(scoreboardUpdate) end
    local s = L.shareState(sym)
    local pn = (mp and mp.playerObj and safe(function() return mp.playerObj:getPlayerNum() end, 0)) or 0
    -- a card in the map's drawer (VANILLA_WINDOWS C5): in the panel that holds the map, at the map's right edge
    local function dock()
        local holder = mp and mp.parent
        if not holder then return nil end
        return holder, mp:getX(), mp:getY(), mp:getWidth(), mp:getHeight()
    end
    L.shareCard = ZeD.FormCard.open({
        title = getText("IGUI_Map_Sharing"), width = 320, playerNum = pn, dock = dock,
        help = tr("UI_ZeD_Map_ShareHelp"),
        rows = function() return L.shareRows(sym, s) end,
        band = function(card)
            return { buttons = {
                { id = "cancel", text = ZeD.btnCase(getText("UI_btn_cancel")), run = function(c) c:finish() end },
                { id = "done", text = ZeD.btnCase(getText("UI_btn_accept")), variant = "primary", run = function(c)
                    local ok, err = pcall(L.shareApply, sym, s)
                    if not ok then ZeD.logOnce("map sharing", err) end
                    c:finish()
                end } } }
        end,
        onFinish = function()
            if fromPad and ZeD.Input and ZeD.Input.Focus and ZeD.Input.Focus.reclaimEngineFocus then ZeD.Input.Focus.reclaimEngineFocus() end
        end,
    })
    return L.shareCard ~= nil
end

-- ---------------------------------------------------------------------------
-- C15: THE ADMIN'S EDIT ITEM (the game's own fields and save)
-- ---------------------------------------------------------------------------
local TYPE_NUMBER, TYPE_STRING, TYPE_COLOR = 1, 2, 3     -- (ISItemEditPanel's own)

-- the game's list of fields for this item, each with what it holds now; ed is the game's panel, never shown
function L.editFields(admin, item)
    local ed = ISItemEditPanel:new(0, 0, 400, 200, admin, item)
    ed:initElements()
    local used = {}
    for _, elem in ipairs(ed.elems) do
        local valid = true
        if elem.funcValidate then valid = safe(function() return elem.funcValidate(ed) end, false) end
        if valid and not elem.isAttribute then
            elem.zedLabel = getText(elem.text)
            if elem.type == TYPE_STRING then
                elem.originalValue = safe(function() return item[elem.funcGet](item) end, "")
                elem.zedText = tostring(elem.originalValue or "")
            elseif elem.type == TYPE_NUMBER then
                elem.originalValue = safe(function() return item[elem.funcGet](item) end, 0)
                local v = elem.originalValue
                if elem.round and luautils and luautils.round then v = luautils.round(v, elem.round) end
                elem.zedText = tostring(v)
                if elem.funcEditable then elem.editable = safe(function() return item[elem.funcEditable](item) end, false) end
                if elem.funcMin then elem.min = safe(function() return item[elem.funcMin](item) end, elem.min) end
                if elem.funcMax then elem.max = safe(function() return item[elem.funcMax](item) end, elem.max) end
            elseif elem.type == TYPE_COLOR then
                local c = safe(function() return item[elem.funcGet](item) end, nil)
                if c then
                    elem.originalValue = { r = c:getRedFloat(), g = c:getGreenFloat(), b = c:getBlueFloat(), a = c:getAlphaFloat() }
                    elem.zedColor = { r = elem.originalValue.r, g = elem.originalValue.g, b = elem.originalValue.b }
                else
                    valid = false
                end
            else
                valid = false
            end
            if valid then used[#used + 1] = elem end
        end
    end
    ed.usedElems = used
    return ed, used
end

-- a number field's words as the game's save reads them: kept inside its bounds; words that are no number leave it as it was
function L.numberText(elem, text)
    local n = tonumber(text)
    if not n then return tostring(elem.originalValue) end
    if type(elem.min) == "number" and n < elem.min then n = elem.min end
    if type(elem.max) == "number" and n > elem.max then n = elem.max end
    return tostring(n)
end

-- Save: each field as the game's control it stands for, then the game's own saveAll. A field left as it was is not saved
-- (the game would write back its own rounded figure)
function L.editSave(card, ed, used)
    for i, elem in ipairs(used) do
        local id = "f" .. i
        if elem.type == TYPE_COLOR then
            local c = elem.zedColor
            local o = elem.originalValue
            if c.r == o.r and c.g == o.g and c.b == o.b then elem.editable = false end
            elem.control = { backgroundColor = { r = c.r, g = c.g, b = c.b, a = 1 } }
        else
            local text = card:text(id)
            if elem.editable and text == elem.zedText then elem.editable = false end
            if elem.type == TYPE_NUMBER then text = L.numberText(elem, text) end
            local t = text
            elem.control = { getInternalText = function() return t end }
        end
    end
    local ok, err = pcall(ed.saveAll, ed)
    if not ok then ZeD.logOnce("edit item save", err) end
    -- on a server, as the game's window sends it (ISItemEditorUI:onOptionMouseDown, SAVE)
    if isClient() then
        pcall(function()
            local player = ed.item:getPlayer()
            if player and player:getRole():hasCapability(Capability.InspectPlayerInventory) then
                InvMngUpdateItem(ed.item, player:getOnlineID())
            end
        end)
    end
end

-- the game's own color picker for the color row (ISItemEditPanel:onColor)
function L.pickColor(card, elem)
    if not (ISColorPickerHSB and ColorInfo) then return end
    local c = elem.zedColor
    local ci = ColorInfo.new()
    ci:set(c.r, c.g, c.b, 1.0)
    local cp = ISColorPickerHSB:new(0, 0, ci)
    cp:initialise()
    cp.keepOnScreen = true
    cp.pickedTarget = card
    cp.resetFocusTo = card
    cp:setX(card:getAbsoluteX() + math.floor(card:getWidth() / 3))
    cp:setY(card:getAbsoluteY() + card:titleBarHeight() + px(40))
    cp.pickedFunc = function(_t, color) elem.zedColor = { r = color.r, g = color.g, b = color.b } end
    cp:setInitialColor(ci)
    cp:addToUIManager()
    if cp.setAlwaysOnTop then cp:setAlwaysOnTop(true) end
end

function L.editRows(card, used)
    local rows = {}
    for i, elem in ipairs(used) do
        local id = "f" .. i
        if elem.type == TYPE_COLOR then
            rows[#rows + 1] = { k = "swatch", id = id, label = elem.zedLabel, color = elem.zedColor, run = function(c) L.pickColor(c, elem) end }
        elseif elem.editable then
            rows[#rows + 1] = { k = "field", id = id, label = elem.zedLabel, value = elem.zedText, numbers = elem.type == TYPE_NUMBER }
        else
            rows[#rows + 1] = { k = "fact", label = elem.zedLabel, value = elem.zedText }
        end
    end
    return rows
end

-- opens the card; false when it can't (the game's window opens instead)
function L.openItemEditor(admin, item)
    if safeOn() or not (ZeD.FormCard and item and ISItemEditPanel) then return false end
    if type(admin) == "number" then admin = getSpecificPlayer(admin) end
    admin = admin or getPlayer()
    local ok, ed, used = pcall(L.editFields, admin, item)
    if not ok then ZeD.logOnce("edit item fields", ed); return false end
    local pn = safe(function() return admin:getPlayerNum() end, 0)
    local card = ZeD.FormCard.open({
        title = getText("IGUI_ItemEditor_Title"), width = 420, playerNum = pn,
        head = { tex = safe(function() return item:getTex() end, nil), name = safe(function() return item:getDisplayName() end, ""),
                 sub = safe(function() return item:getFullType() end, "") },
        help = tr("UI_ZeD_Card_EditHelp"),
        rows = function(c) return L.editRows(c, used) end,
        band = function()
            return { buttons = {
                { id = "cancel", text = ZeD.btnCase(getText("UI_btn_cancel")), run = function(c) c:finish() end },
                { id = "save", text = words(getText("IGUI_RadioSave")), variant = "primary", run = function(c)
                    L.editSave(c, ed, used)
                    c:finish()
                end } } }
        end,
    })
    return card ~= nil
end

if not L.editHooked and ISItemEditorUI and ISItemEditorUI.OpenPanel then
    L.editHooked = true
    local base = ISItemEditorUI.OpenPanel
    ISItemEditorUI.OpenPanel = function(player, item)
        local ok, done = pcall(L.openItemEditor, player, item)
        if ok and done then return end
        if not ok then ZeD.logOnce("edit item", done) end
        return base(player, item)
    end
end

return L
