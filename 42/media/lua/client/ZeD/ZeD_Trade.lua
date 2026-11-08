-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Trade.lua
-- ============================================================================
-- TRADING WITH ANOTHER PLAYER — HOOK_MAP row 18b (the director, Nov 7 2026: B10, "build it as a
-- World window card"). The trade itself: one session per local player, every rule and every call
-- of vanilla's ISTradingUI (media/lua/client/ISUI/ISTradingUI.lua) kept, drawn by the World
-- window's trade card (ObjectCardTrade.lua); the hooks that open it are Overrides/TradeMedic.lua.
--
-- What vanilla does, and the session does the same:
--   * Right-click a player > Trade with: the window opens blocked ("Waiting for X's answer."),
--     requestTrading(you, them); their answer comes back as Events.AcceptedTrade.
--   * Their request: the game's own Yes / No question (a ZeD prompt through Overrides/Prompts.lua);
--     Yes ends any open trade first (WindowWasClosed), opens the window, acceptTrading(you, them, yes).
--   * Your offer: at most ISTradingUI.MaxItems (20) items, only from your main inventory (not a bag,
--     not the ground), not equipped or worn, not a favorite; tradingUISendAddItem / RemoveItem for
--     each change, and a change unseals their side of your window. An offered item that leaves your
--     main inventory comes off the offer. The list leaves out equipped, worn, favorite and hidden
--     items, groups by name (keyring, hotbar first) and keeps 20 of a kind, as vanilla's.
--   * Seal offer: DealWasSealed / DealWasUnsealed. Their add or remove unticks yours (locally, as
--     vanilla). Accept deal only when both are sealed and something is offered: DealWasFinalized, and
--     the window closes on both sides; the server moves the items.
--   * Cancel (Close once the trade is over): WindowWasClosed. Their close, their refusal, them gone,
--     or more than 2 tiles apart blocks the window with vanilla's own words.
--   * While the window is up, ISTradingUI.GetUIForPlayer(you):isVisible() is true: the game's
--     right-click menus say "Can't use inventory context menu while trading." and its transfers
--     wait (ISInventoryTransferAction), so nothing offered can be eaten or dropped mid-trade. The
--     session's stand-in element (ZeD_TradeSession, never drawn) is what the game finds there.
-- ============================================================================

require "ISUI/ISUIElement"
require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.Trade = ZeD.Trade or {}
local TR = ZeD.Trade

TR.sessions = TR.sessions or {}   -- [player index + 1] = the open session

local function maxItems() return (ISTradingUI and ISTradingUI.MaxItems) or 20 end
local function coolDown() return (ISTradingUI and ISTradingUI.CoolDownMessage) or 300 end

-- the stand-in the game asks for (ISTradingUI.windows, GetUIForPlayer, its Java menu's isVisible): a
-- plain UI element, never added to the UI manager, visible while the trade is open
ZeD_TradeSession = ZeD_TradeSession or ISUIElement:derive("ZeD_TradeSession")

local Session = {}
Session.__index = Session
TR.Session = Session

-- ---------------------------------------------------------------------------
-- open / find / close
-- ---------------------------------------------------------------------------
local function idx(player)
    local ok, i = pcall(function() return player:getIndex() end)
    return ok and i or 0
end

--- The open trade of a local player, or nil.
function TR.get(player)
    if not player then return nil end
    local s = TR.sessions[idx(player) + 1]
    if s and s.open and s.player == player then return s end
    return nil
end

--- The trade on a player's World window can be ZeD's: not in safe mode, the card is there, and the
--- World window (one, for one player) is that player's or not open yet.
function TR.canOpen(player)
    if not player then return false end
    if ZeD.Safe and ZeD.Safe.on("windows") then return false end
    local OC = ZeD.ObjectCards
    if not (OC and OC.kinds and OC.kinds.trade and ZeD_WorldWindow and ZeD_WorldWindow.openObjectCard) then return false end
    local win = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if win and win._playerObj and win._playerObj ~= player then return false end
    return true
end

--- Open a trade with other on the World window's card. asked = you asked them (vanilla's onTrade:
--- blocked until they answer, requestTrading sent); else you said yes to theirs. False when the
--- card could not open (the caller then runs vanilla's own window).
function TR.open(player, other, asked)
    if not (player and other) then return false end
    local old = TR.get(player)
    if old then old:cancel() end
    -- (vanilla's ISTradingUI:new stops what the player was doing)
    pcall(function() player:StopAllActionQueue() end)
    local s = setmetatable({
        player = player, other = other, index = idx(player),
        your = {}, his = {}, sealed = false, otherSealed = false,
        blocking = nil, blocking2 = nil, pending = false,
        flash = nil, flashCD = 0, log = {}, groups = {}, open = true,
    }, Session)
    local el = ZeD_TradeSession:new(0, 0, 0, 0)
    el:initialise()
    el:instantiate()
    el:setVisible(true)
    el.zedTrade = s
    -- (the fields the game's own trade handlers read, as no-ops: a mod that wrapped one of them before ZeD
    -- loaded keeps it on the event, and it must find nothing to break here; ZeD's router does the work)
    local noop = function() end
    el.hisOfferDatas = { items = {}, addItem = noop, removeItemByIndex = noop }
    el.yourOfferDatas = { items = {}, addItem = noop, removeItemByIndex = noop }
    el.sealOffer = { selected = {} }
    el.setHistoryMessage = noop
    el.finalizeDeal = noop
    el.getIndexFromItemId = function() return -1 end
    el.player, el.otherPlayer = player, other
    s.element = el
    TR.sessions[s.index + 1] = s
    if ISTradingUI and ISTradingUI.windows then ISTradingUI.windows[s.index + 1] = el end
    s:rebuild()
    local ok, opened = pcall(ZeD.ObjectCards.open, player, "trade", s)
    if not (ok and opened) then
        if not ok then print("[ZeD] Trade: the card did not open: " .. tostring(opened)) end
        s:finish()
        return false
    end
    if asked then
        s.pending = true
        s.blocking = getText("IGUI_TradingUI_WaitingAnswer", other:getDisplayName())
        requestTrading(player, other)
    end
    return true
end

-- the trade is over on this side: the stand-in goes, the card closes (no word to the other player)
function Session:finish()
    if not self.open then return end
    self.open = false
    pcall(function() self.element:setVisible(false) end)
    if ISTradingUI and ISTradingUI.windows and ISTradingUI.windows[self.index + 1] == self.element then
        ISTradingUI.windows[self.index + 1] = nil
    end
    if TR.sessions[self.index + 1] == self then TR.sessions[self.index + 1] = nil end
    local card = ZeD_WorldWindow and ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard()
    local e = card and card.entry
    if e and e.t and e.t.s == self and ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
end

-- the trade can no longer go on (they closed, refused or left): the stand-in goes, so the game's
-- right-click menus and transfers are free again; the card stays with their words until it closes
function Session:release()
    if self.released then return end
    self.released = true
    pcall(function() self.element:setVisible(false) end)
    if ISTradingUI and ISTradingUI.windows and ISTradingUI.windows[self.index + 1] == self.element then
        ISTradingUI.windows[self.index + 1] = nil
    end
end

--- End every open ZeD trade as Cancel does (safe mode taking over, the World window given back).
function TR.endAll()
    local open = {}
    for _, s in pairs(TR.sessions) do if s and s.open then open[#open + 1] = s end end
    for _, s in ipairs(open) do s:cancel() end
end
if ZeD.Safe and ZeD.Safe.register then
    ZeD.Safe.register("trade", { leave = function() TR.endAll() end })
end

--- Cancel (vanilla's CANCEL button): close, then tell the other player.
function Session:cancel()
    if not self.open then return end
    self:finish()
    tradingUISendUpdateState(self.player, self.other, TradingState.WindowWasClosed)
end

-- ---------------------------------------------------------------------------
-- state
-- ---------------------------------------------------------------------------
function Session:isBlocked() return self.blocking ~= nil or self.blocking2 ~= nil end
function Session:blockText() return self.blocking or self.blocking2 end
function Session:max() return maxItems() end

function Session:isOffered(item)
    for _, it in ipairs(self.your) do if it == item then return true end end
    return false
end

-- vanilla's setHistoryMessage: the line under the lists for a while, and in the trade log when it
-- is the other player's doing (added = added an item, removed = took one off)
function Session:history(message, publish, added, removed)
    if not self.open then return end
    self.flash = message
    self.flashCD = coolDown()
    if publish then
        self.log[#self.log + 1] = { message = message, add = added, remove = removed }
    end
end

-- the state line the card shows for a few seconds (vanilla's history message), or nil
function Session:flashText()
    if self.flashCD and self.flashCD > 0 then return self.flash end
    return nil
end

--- Vanilla's addItemToYourOffer, rule for rule.
function Session:addItem(item)
    if not (self.open and item) then return false end
    if self.sealed then return false end
    local player = self.player
    if #self.your + 1 > maxItems() then
        self:history(getText("IGUI_TradingUI_MaxItemReached", maxItems()), false, false, false)
        return false
    end
    if luautils.haveToBeTransfered(player, item) then
        self:history(getText("IGUI_TradingUI_ItemNeedTransfer", item:getName()), false, false, false)
        return false
    end
    if player:isEquipped(item) or player:isEquippedClothing(item) then
        self:history(getText("IGUI_TradingUI_ItemNeedUnequip", item:getName()), false, false, false)
        return false
    end
    if item:isFavorite() then
        self:history(getText("IGUI_TradingUI_CantAddFavorite"), false, false, false)
        return false
    end
    if self:isOffered(item) then return false end
    self.your[#self.your + 1] = item
    tradingUISendAddItem(player, self.other, item)
    self.otherSealed = false
    return true
end

--- A whole group (vanilla's group header): each item in turn, as vanilla adds them.
function Session:addGroup(g)
    if not (g and g.items) or self.sealed then return end
    for _, item in ipairs(g.items) do self:addItem(item) end
    self:rebuild()
end

--- Take one off your offer (vanilla's removeItem).
function Session:removeItem(item)
    if not self.open then return end
    for i, it in ipairs(self.your) do
        if it == item then
            tradingUISendRemoveItem(self.player, self.other, item)
            table.remove(self.your, i)
            self.otherSealed = false
            self:rebuild()
            return true
        end
    end
    return false
end

--- Seal offer ticked or unticked (vanilla's onSealOffer).
function Session:setSealed(on)
    if not self.open or self:isBlocked() then return end
    self.sealed = on and true or false
    if self.sealed then
        tradingUISendUpdateState(self.player, self.other, TradingState.DealWasSealed)
    else
        tradingUISendUpdateState(self.player, self.other, TradingState.DealWasUnsealed)
    end
end

--- Accept deal can be pressed (vanilla's updateButtons), and the words why not.
function Session:canAccept()
    if self:isBlocked() then return false, self:blockText() end
    if self.sealed and self.otherSealed then
        if #self.your > 0 or #self.his > 0 then return true, nil end
        return false, getText("IGUI_TradingUI_TradeAtLeastOne")
    end
    return false, getText("IGUI_TradingUI_AcceptDealTooltip")
end

function Session:accept()
    if not (self.open and self:canAccept()) then return end
    tradingUISendUpdateState(self.player, self.other, TradingState.DealWasFinalized)
    self:finish()
end

-- the index of their offered item with this id, or -1 (vanilla's getIndexFromItemId)
function Session:hisIndex(itemId)
    for i, it in ipairs(self.his) do
        if it:getID() == itemId then return i end
    end
    return -1
end

-- ---------------------------------------------------------------------------
-- your main inventory, grouped as vanilla's list groups it
-- ---------------------------------------------------------------------------
local function nameLess(a, b)
    if string.sort then return not string.sort(a, b) end   -- (Kahlua's, as vanilla sorts)
    return a < b
end
local function groupLess(a, b)
    if a.equipped and not b.equipped then return false end
    if b.equipped and not a.equipped then return true end
    if a.inHotbar and not b.inHotbar then return true end
    if b.inHotbar and not a.inHotbar then return false end
    return nameLess(a.name, b.name)
end

-- vanilla's addInventoryItemToGroup (the berries and mushrooms a herbalist knows renamed as its
-- list renames them)
local function addToGroup(self, tables, item, isEquipped, isInHotbar)
    local player = self.player
    if player:isEquipped(item) or player:isEquippedClothing(item) then return end
    if item:isFavorite() then return end
    if item:isHidden() then return end
    if self:isOffered(item) then return end
    local itemName = item:getName(player)
    if item:IsFood() and item:getHerbalistType() and item:getHerbalistType() ~= "" then
        if player:isRecipeActuallyKnown("Herbalist") then
            if item:getHerbalistType() == "Berry" then
                itemName = (item:getPoisonPower() > 0) and getText("IGUI_PoisonousBerry") or getText("IGUI_Berry")
            end
            if item:getHerbalistType() == "Mushroom" then
                itemName = (item:getPoisonPower() > 0) and getText("IGUI_PoisonousMushroom") or getText("IGUI_Mushroom")
            end
        else
            if item:getHerbalistType() == "Berry" then itemName = getText("IGUI_UnknownBerry") end
            if item:getHerbalistType() == "Mushroom" then itemName = getText("IGUI_UnknownMushroom") end
        end
        if itemName ~= item:getDisplayName() then item:setName(itemName) end
        itemName = item:getName(player)
    end
    local label = itemName
    local equipped = false
    if isEquipped[item] then
        itemName = "equipped:" .. itemName
        equipped = true
    elseif item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING) then
        itemName = "keyring:" .. itemName
        equipped = true
    end
    local inHotbar = isInHotbar[item]
    if inHotbar and not equipped then itemName = "hotbar:" .. itemName end
    local g = tables[itemName]
    if not g then
        g = { name = itemName, label = label, items = {} }
        tables[itemName] = g
    end
    if #g.items >= maxItems() then return end
    g.equipped, g.inHotbar = equipped, inHotbar
    g.items[#g.items + 1] = item
end

--- Rebuild the groups of your main inventory that can go on the offer.
function Session:rebuild()
    local player = self.player
    local isEquipped, isInHotbar = {}, {}
    local ok = pcall(function()
        local worn = player:getWornItems()
        for i = 1, worn:size() do isEquipped[worn:get(i - 1):getItem()] = true end
        local it = player:getPrimaryHandItem()
        if it then isEquipped[it] = true end
        it = player:getSecondaryHandItem()
        if it then isEquipped[it] = true end
        local hotbar = getPlayerHotbar and getPlayerHotbar(player:getIndex())
        if hotbar and hotbar.attachedItems then
            for _, a in pairs(hotbar.attachedItems) do isInHotbar[a] = true end
        end
    end)
    if not ok then return end
    local tables = {}
    local items = player:getInventory():getItems()
    for i = 1, items:size() do
        local item = items:get(i - 1)
        local aok, err = pcall(addToGroup, self, tables, item, isEquipped, isInHotbar)
        if not aok then ZeD.logOnce("Trade group", err) end
    end
    local list = {}
    for _, g in pairs(tables) do list[#list + 1] = g end
    table.sort(list, groupLess)
    self.groups = list
end

-- ---------------------------------------------------------------------------
-- every frame (vanilla's update): them gone or too far, an offered item that left
-- ---------------------------------------------------------------------------
function Session:update()
    if not self.open then return end
    local player = self.player
    if player:isDead() then return end
    -- ZeD stepped aside (safe mode, the World window given back, or the window now another player's):
    -- the trade ends as Cancel does, so the game's guards never hold a player with no card to answer them
    if not TR.canOpen(player) then self:cancel(); return end
    -- they closed, refused or left: the game's guards let go at once (the card keeps their words and
    -- Close); once the card is gone too, the trade is over
    if self.released then
        local c = ZeD_WorldWindow and ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard()
        local ce = c and c.entry
        if not (ce and ce.t and ce.t.s == self) then self:cancel() end
        return
    end
    if self.flashCD and self.flashCD > 0 then self.flashCD = self.flashCD - 1 end
    local other = getPlayerByOnlineID(self.other:getOnlineID())
    if not other then
        self.blocking = getText("IGUI_TradingUI_ClosedTrade", self.other:getDisguisedDisplayName())
        self:release()
    end
    if not self.blocking and other and (math.abs(other:getX() - player:getX()) > 2 or
            math.abs(other:getY() - player:getY()) > 2) then
        self.blocking2 = getText("IGUI_TradingUI_TooFarAway", self.other:getDisguisedDisplayName())
    else
        self.blocking2 = nil
    end
    -- an item on the offer that is no longer in your main inventory comes off it (one a frame, as vanilla)
    for _, item in ipairs(self.your) do
        if luautils.haveToBeTransferedWhileTrading(player, item) then
            self:removeItem(item)
            break
        end
    end
    -- the card is pinned (the director, Nov 7 2026): only Cancel, their close, distance or them leaving
    -- end the trade. Shut World window: the trade waits and its card is back when the window opens
    -- again (or at the next thing the other player does: TR.onEvent). Another object card in the
    -- drawer: the trade comes back when it closes. An item card shows over it (the drawer's own order).
    self:reshow(false)
end

--- Put the trade card back in the drawer when it is not there and nothing else holds it. open = true
--- opens a shut World window for it (an event from the other player); false waits for the window.
function Session:reshow(open)
    if not (self.open and ZeD_WorldWindow) then return end
    local win = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if not win and not open then return end
    -- (split screen: never on another player's World window)
    if win and win._playerObj and win._playerObj ~= self.player then return end
    if win then
        local d = win._drawerObject
        if d and d.t and d.t.s == self then
            if win._drawerOpen ~= false then return end   -- (shown, or under an item card)
        elseif d then
            return                                          -- another object card: wait for it to close
        end
        if win._drawerItem ~= nil then return end           -- an item card over it: back when it closes
    end
    local ok, err = pcall(ZeD.ObjectCards.open, self.player, "trade", self)
    if not ok then ZeD.logOnce("Trade reshow", err) end
end

-- after the other player's event: their trade on screen again (the window opened if it was shut)
function TR.onEvent(player)
    local s = TR.get(player)
    if s then s:reshow(true) end
end

local function tick()
    -- (copied first: an update that ends a trade takes it out of TR.sessions)
    local open = nil
    for _, s in pairs(TR.sessions) do
        if s and s.open then open = open or {}; open[#open + 1] = s end
    end
    if not open then return end
    for _, s in ipairs(open) do
        local ok, err = pcall(Session.update, s)
        if not ok then ZeD.logOnce("Trade update", err) end
    end
end
if Events and Events.OnTick and not TR._tickAdded then
    TR._tickAdded = true
    Events.OnTick.Add(function() tick() end)
end

-- ---------------------------------------------------------------------------
-- the game's trade events, for a ZeD trade (Overrides/TradeMedic.lua routes them here when the
-- player's trade is ZeD's, else to vanilla's own handlers)
-- ---------------------------------------------------------------------------
-- (vanilla's AcceptedTrade) the other player answered your request
function TR.onAccepted(otherPlayer, player, accepted)
    local s = TR.get(player)
    if not s then return end
    s.pending = false
    s.blocking = nil
    if not accepted then
        s.blocking = getText("IGUI_TradingUI_RefusedTrade", otherPlayer:getDisguisedDisplayName())
        s:release()
    end
end

-- (vanilla's OtherAddNewItem) they put an item on their offer
function TR.onOtherAdd(otherPlayer, player, item)
    local s = TR.get(player)
    if not (s and item) then return end
    if s:hisIndex(item:getID()) ~= -1 then return end
    s.his[#s.his + 1] = item
    s:history(getText("IGUI_TradingUI_AddedItem", otherPlayer:getDisplayName(), item:getName()), true, true, false)
    s.sealed = false
    s.otherSealed = false
end

-- (vanilla's RemoveItem) they took one off theirs
function TR.onOtherRemove(otherPlayer, player, itemId)
    local s = TR.get(player)
    if not s then return end
    local i = s:hisIndex(itemId)
    if i == -1 then return end
    local removed = s.his[i]
    table.remove(s.his, i)
    s:history(getText("IGUI_TradingUI_RemovedItem", otherPlayer:getDisplayName(), removed:getName()), true, false, true)
    s.sealed = false
    s.otherSealed = false
end

-- the request question still up (vanilla's ISTradingUI.tradeQuestionUI), put away as vanilla does
local function dropQuestion()
    local q = ISTradingUI and ISTradingUI.tradeQuestionUI
    if not q then return false end
    local ok, vis = pcall(function() return q:isVisible() end)
    if not (ok and vis) then return false end
    if q.kind ~= nil then q._dead = true end   -- (a ZeD prompt: a stray press can no longer answer it)
    q:setVisible(false)
    q:removeFromUIManager()
    return true
end
TR.dropQuestion = dropQuestion

-- (vanilla's UpdateState) they closed, sealed, unsealed or accepted
function TR.onState(otherPlayer, player, state)
    local s = TR.get(player)
    if state == TradingState.WindowWasClosed then
        if dropQuestion() then
            -- (their request was still being asked: nothing else, as vanilla)
        elseif s and s.other == otherPlayer then
            s.blocking = getText("IGUI_TradingUI_ClosedTrade", otherPlayer:getDisplayName())
            s:release()
        end
    end
    if s and s.open then
        if state == TradingState.DealWasSealed then
            s.otherSealed = true
            s:history(getText("IGUI_TradingUI_OtherPlayerSealedOffer", s.other:getDisguisedDisplayName()), true, false, false)
        end
        if state == TradingState.DealWasUnsealed then
            s.otherSealed = false
            s:history(getText("IGUI_TradingUI_OtherPlayerUnSealedOffer", s.other:getDisguisedDisplayName()), true, false, false)
        end
        if state == TradingState.DealWasFinalized then
            s:finish()
        end
    end
end

print("[ZeD] Trade: trading sessions loaded")
return TR
