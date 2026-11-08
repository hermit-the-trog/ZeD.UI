-- ZeD-UI/42/media/lua/client/ZeD/Overrides/TradeMedic.lua
-- ============================================================================
-- TRADING AND THE MEDICAL CHECK OF ANOTHER PLAYER — HOOK_MAP rows 17 and 18b (the director,
-- Nov 7 2026: B10 and B11, both World window cards)
--
-- Trade (multiplayer; the game offers it on a server only):
--   ISWorldObjectContextMenu.onTrade        Trade with <name>: ZeD's trade card, blocked until they
--                                           answer (requestTrading, as vanilla)
--   ISTradingUI.onAnswerTradeRequest        Yes to their request (the game's question, already a ZeD
--                                           prompt: Overrides/Prompts.lua): any open trade ends, the
--                                           card opens, acceptTrading; No is vanilla's
--   Events AcceptedTrade, TradingUIAddItem, TradingUIRemoveItem, TradingUIUpdateState
--                                           vanilla's handlers come off the events; one handler each
--                                           sends the event to ZeD's trade when the player's open trade
--                                           is ZeD's, else to vanilla's own (a trade opened in safe mode
--                                           keeps vanilla's window to its end)
-- Medical check (a server, single player and split screen):
--   ISMedicalCheckAction.perform            the game's timed action, at its end: ZeD's medical check card
--                                           in place of vanilla's health panel window, and the doctor
--                                           receives the patient's body as vanilla's perform does
-- Vanilla runs whenever ZeD declines: safe mode or the World window given back, the World window open
-- for another split-screen player, or a card that cannot open.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ObjectCards"
require "ZeD/ZeD_Trade"
require "ZeD/ObjectCardTrade"
require "ZeD/ObjectCardMedic"
require "ISUI/ISTradingUI"
require "ISUI/ISWorldObjectContextMenu"
require "TimedActions/ISMedicalCheckAction"
require "XpSystem/ISUI/ISHealthPanel"

local TR = ZeD.Trade
local MC = ZeD.Medic

-- ---------------------------------------------------------------------------
-- Trade with <name>
-- ---------------------------------------------------------------------------
local function hookOnTrade()
    if not (ISWorldObjectContextMenu and ISWorldObjectContextMenu.onTrade) or ISWorldObjectContextMenu._zedTradeHooked then return end
    ISWorldObjectContextMenu._zedTradeHooked = true
    local orig = ISWorldObjectContextMenu.onTrade
    ISWorldObjectContextMenu.onTrade = function(worldobjects, player, otherPlayer)
        if TR.canOpen(player) then
            local ok, opened = pcall(TR.open, player, otherPlayer, true)
            if ok and opened then return end
            if not ok then print("[ZeD] TradeMedic: trade kept vanilla's: " .. tostring(opened)) end
        end
        return orig(worldobjects, player, otherPlayer)
    end
end

-- ---------------------------------------------------------------------------
-- Yes to their request
-- ---------------------------------------------------------------------------
local function hookAnswer()
    if not (ISTradingUI and ISTradingUI.onAnswerTradeRequest) or ISTradingUI._zedAnswerHooked then return end
    ISTradingUI._zedAnswerHooked = true
    local orig = ISTradingUI.onAnswerTradeRequest
    ISTradingUI.onAnswerTradeRequest = function(target, button)
        local q = button and button.parent
        local player, other = q and q.playerObj, q and q.requester
        if button and button.internal == "YES" and player and other and TR.canOpen(player) then
            -- an open trade ends first, as vanilla's does (ZeD's, or the game's own window)
            local s = TR.get(player)
            if s then s:cancel() end
            local ui = ISTradingUI.GetUIForPlayer(player)
            if ui and ui.zedTrade == nil and ui:isVisible() then
                tradingUISendUpdateState(ui.player, ui.otherPlayer, TradingState.WindowWasClosed)
                ui:close()
            end
            ISTradingUI.tradeQuestionUI = nil
            local ok, opened = pcall(TR.open, player, other, false)
            if ok and opened then
                acceptTrading(player, other, true)
                return
            end
            if not ok then print("[ZeD] TradeMedic: trade kept vanilla's: " .. tostring(opened)) end
        end
        return orig(target, button)
    end
end

-- ---------------------------------------------------------------------------
-- The game's trade events: ZeD's trade, else vanilla's handlers
-- ---------------------------------------------------------------------------
local ROUTES = {
    { event = "AcceptedTrade",        name = "AcceptedTrade",  zed = function(...) return TR.onAccepted(...) end },
    { event = "TradingUIAddItem",     name = "OtherAddNewItem", zed = function(...) return TR.onOtherAdd(...) end },
    { event = "TradingUIRemoveItem",  name = "RemoveItem",     zed = function(...) return TR.onOtherRemove(...) end },
    { event = "TradingUIUpdateState", name = "UpdateState",    zed = function(...) return TR.onState(...) end },
}

local function hookEvents()
    if not ISTradingUI or ISTradingUI._zedEventsHooked or not Events then return end
    for _, r in ipairs(ROUTES) do
        if not (Events[r.event] and Events[r.event].Add) then return end
    end
    ISTradingUI._zedEventsHooked = true
    for _, r in ipairs(ROUTES) do
        local ev = Events[r.event]
        local vanilla = ISTradingUI[r.name]
        if vanilla and ev.Remove then ev.Remove(vanilla) end
        local route = r
        ev.Add(function(otherPlayer, player, arg)
            -- (the player's open trade decides; the event's player is the local one)
            if TR.get(player) then
                local ok, err = pcall(route.zed, otherPlayer, player, arg)
                if not ok then print("[ZeD] TradeMedic: " .. route.event .. " failed: " .. tostring(err)) end
                pcall(TR.onEvent, player)   -- (a pinned trade on screen again if its window was shut)
                return
            end
            local v = ISTradingUI[route.name]
            if v then return v(otherPlayer, player, arg) end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- The medical check's end
-- ---------------------------------------------------------------------------
local function hookMedical()
    if not ISMedicalCheckAction or ISMedicalCheckAction._zedMedicHooked then return end
    ISMedicalCheckAction._zedMedicHooked = true
    local orig = ISMedicalCheckAction.perform
    ISMedicalCheckAction.perform = function(self)
        local doctor, patient = self.character, self.otherPlayer
        if doctor and patient and MC.canOpen(doctor) then
            local ok, opened = pcall(MC.open, doctor, patient)
            if ok and opened then
                -- (vanilla's perform: the doctor receives the patient's body while the panel is up)
                pcall(function() doctor:startReceivingBodyDamageUpdates(patient) end)
                ISBaseTimedAction.perform(self)
                return
            end
            if not ok then print("[ZeD] TradeMedic: medical check kept vanilla's: " .. tostring(opened)) end
        end
        return orig(self)
    end
end

local function apply()
    hookOnTrade()
    hookAnswer()
    hookEvents()
    hookMedical()
    if not _G._zedTradeMedicAnnounced then
        _G._zedTradeMedicAnnounced = true
        print("[ZeD] Overrides/TradeMedic: trading and the medical check of another player open as World window cards")
    end
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
