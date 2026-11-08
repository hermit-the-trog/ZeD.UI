-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardTrade.lua
-- ============================================================================
-- OBJECT CARD: TRADE (HOOK_MAP row 18b; the director, Nov 7 2026: B10 as a World window card)
-- The trade with another player in the World window's card drawer, in place of vanilla's
-- ISTradingUI window. The session and every rule are ZeD_Trade.lua's (vanilla's, kept); this
-- file only draws it:
--   header   Trade with <name> (the game's words), the swap icon, a tag while you wait for
--            their answer or when both offers are sealed
--   body     why the trade is blocked (their answer, too far, closed, refused) or the last thing
--            that happened; your offer and theirs side by side (stacked on a narrow card), each
--            "n / 20" with its sealed line; your main inventory to add from (Add, Add all for a
--            stack); the trade log (vanilla's separate Trade Log window, folded in)
--   band     Seal offer (the check), Cancel (Close once it is over) and Accept deal, the main
--            one last; a grayed one says why in the help line
-- Mouse and controller: every Add, Remove and band control is a stop; B or the close key is
-- vanilla's Cancel. The card has no leash of its own: vanilla's 2-tile rule blocks it instead.
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ZeD_Trade"

local OC = ZeD.ObjectCards
local UI = OC.ui
local TR = ZeD.Trade

local def = { id = "trade", vehicleOk = true }

function def.resolve(player, s)
    if not (s and s.other) then return nil end
    local key = "trade:" .. tostring(OC.call(s.other, "getOnlineID") or s.other)
    return { s = s, key = key }
end

function def.valid(t) return t.s ~= nil and t.s.open == true end

-- pinned (the director, Nov 7 2026): tab switches and item cards leave it in the drawer; an item card
-- opens over it and the trade shows again when that closes
function def.pinned(t) return t.s ~= nil and t.s.open == true end

-- the card's own close (its close key, B) is vanilla's Cancel; another object card taking the drawer is
-- not: the trade waits and comes back when that card closes (ZeD_Trade.lua, Session:update)
function def.onClose(t, card)
    if t.s and t.s.open and ZeD_WorldWindow and ZeD_WorldWindow._closingCard then t.s:cancel() end
end

function def.refresh(t, player)
    t.verbs = t.verbs or {}
    t.d = true
    if t.s and t.s.open then t.s:rebuild() end
end

local function otherName(s) return OC.call(s.other, "getDisguisedDisplayName") or "?" end

function def.title(t) return getText("ContextMenu_Trade", otherName(t.s)) end
function def.icon(t) return nil end
function def.pxIcon(t) return "swap" end

function def.pill(t)
    local s, T = t.s, ZeD.T
    if s.pending then return ZeD.tr("UI_ZeD_Trade_TagWaiting"), T.warning end
    if not s:isBlocked() and s.sealed and s.otherSealed then return ZeD.tr("UI_ZeD_Trade_TagReady"), T.positive end
    return nil
end

-- where the controller lands: Cancel while the trade is blocked, else the first Add, else Seal offer
function def.openFocus(t)
    local s = t.s
    if s:isBlocked() then return "oc:foot:cancel" end
    local g = s.groups and s.groups[1]
    if g then return "tr:add:" .. g.name end
    return "oc:foot:seal"
end

function def.foot(t, player, card)
    local s = t.s
    local blocked = s:isBlocked()
    local canAcc, why = s:canAccept()
    return {
        check = { id = "seal", label = getText("IGUI_TradingUI_SealOffer"), on = s.sealed, disabled = blocked,
            help = blocked and s:blockText() or getText("IGUI_TradingUI_SealOfferTooltip"),
            run = function(p, tt) tt.s:setSealed(not tt.s.sealed) end },
        buttons = {
            { id = "cancel", label = blocked and getText("IGUI_CraftUI_Close") or getText("UI_Cancel"),
              help = ZeD.tr("UI_ZeD_Trade_HelpCancel"), run = function(p, tt) tt.s:cancel() end },
            { id = "accept", label = getText("IGUI_TradingUI_AcceptDeal"), variant = (canAcc and "primary") or nil,
              disabled = not canAcc, primary = canAcc or nil,
              help = canAcc and ZeD.tr("UI_ZeD_Trade_HelpAccept") or why, run = function(p, tt) tt.s:accept() end },
        },
    }
end

-- ---------------------------------------------------------------------------
-- body pieces
-- ---------------------------------------------------------------------------
local function col(c) return c.r, c.g, c.b end

-- why Add is grayed (nil when it can run)
local function addWhy(s)
    if s:isBlocked() then return s:blockText() end
    if s.sealed then return getText("IGUI_TradingUI_OfferSealed") end
    if #s.your >= s:max() then return getText("IGUI_TradingUI_MaxItemReached", s:max()) end
    return nil
end

-- a section head with the words cut to leave room for the count on its right
local function head(card, x, y, w, label, right)
    local T, A = ZeD.T, ZeD.Atoms
    local inset = T.px(8)
    local rw = right and (ZeD.TM:MeasureStringX(T.fontF1, right) + T.px(12)) or 0
    local s = A.truncateText(A.textCase(label or ""), T.fontF1, math.max(T.px(30), w - inset * 2 - rw))
    return UI.section(card, x, y, w, s, right)
end

-- one row of an offer: yours with Remove, theirs read-only
local function offerRow(card, x, y, w, s, item, mine)
    local T = ZeD.T
    local tex = OC.call(item, "getTex")
    local name = OC.call(item, "getName") or "?"
    if not mine then return UI.row(card, x, y, w, tex, name, nil) end
    local why = s:isBlocked() and s:blockText() or (s.sealed and getText("IGUI_TradingUI_OfferSealed")) or nil
    local id = OC.call(item, "getID") or name
    return UI.pick(card, x, y, w, { tex = tex, name = name, button = getText("IGUI_TradingUI_RemoveItem"),
        fid = "tr:rm:" .. tostring(id), enabled = why == nil,
        help = why or ZeD.tr("UI_ZeD_Trade_HelpRemove", name),
        run = function() s:removeItem(item) end })
end

-- one side's offer: the head ("Your offer ... 3 / 20"), its sealed line, the rows
local function offerColumn(card, x, y, w, s, mine)
    local T, M = ZeD.T, ZeD.Molecules
    local y0 = y
    local list = mine and s.your or s.his
    local label = mine and getText("IGUI_TradingUI_YourOffer") or getText("IGUI_TradingUI_HisOffer", otherName(s))
    y = y + head(card, x, y, w, label, tostring(#list) .. " / " .. tostring(s:max())) + T.px(6)
    if mine and s.sealed then
        y = y + UI.note(card, x + T.px(8), y, w - T.px(8), getText("IGUI_TradingUI_OfferSealed"), T.positive) + T.px(6)
    elseif (not mine) and s.otherSealed then
        y = y + UI.note(card, x + T.px(8), y, w - T.px(8), getText("IGUI_TradingUI_OtherPlayerSealedOffer", otherName(s)), T.positive) + T.px(6)
    end
    if #list == 0 then
        y = y + M.drawEmptyLine(card, x + T.px(8), y, w - T.px(8), ZeD.tr("UI_ZeD_Trade_EmptyOffer")) + T.px(4)
    else
        for _, item in ipairs(list) do y = y + offerRow(card, x, y, w, s, item, mine) end
    end
    return y - y0
end

-- one kind of thing in your main inventory: icon, name (and how many), Add all for a stack, Add
local function groupRow(card, x, y, w, s, g, why)
    local T, tm = ZeD.T, ZeD.TM
    local h = math.max(T.px(26), T.buttonH)
    local isz = T.px(16)
    local first = g.items[1]
    local tex = OC.call(first, "getTex")
    if tex then
        card:drawTextureScaledAspect(tex, x + T.px(2), y + math.floor((h - isz) / 2), isz, isz, 1,
            OC.call(first, "getR") or 1, OC.call(first, "getG") or 1, OC.call(first, "getB") or 1)
    end
    local bh = T.buttonH - T.px(4)
    local by = y + math.floor((h - bh) / 2)
    local addL = getText("IGUI_TradingUI_AddItem")
    local bw = UI.buttonW(addL)
    local bx = x + w - bw - T.px(2)
    local fid = "tr:add:" .. g.name
    UI.button(card, bx, by, addL, { w = bw, h = bh, disabled = why ~= nil, fid = fid, body = true,
        focus = card:focusOf(fid), help = why or ZeD.tr("UI_ZeD_Trade_HelpAdd", g.label),
        run = function()
            for _, it in ipairs(g.items) do
                if not s:isOffered(it) then s:addItem(it); break end
            end
            s:rebuild()
        end })
    local rx = bx - T.px(8)
    if #g.items > 1 then
        local allL = getText("ContextMenu_AddAll")
        local aw = UI.buttonW(allL)
        rx = rx - aw
        local afid = "tr:all:" .. g.name
        UI.button(card, rx, by, allL, { w = aw, h = bh, disabled = why ~= nil, fid = afid, body = true,
            focus = card:focusOf(afid), help = why or ZeD.tr("UI_ZeD_Trade_HelpAddAll", g.label),
            run = function() s:addGroup(g) end })
        rx = rx - T.px(8)
    end
    local name = g.label or "?"
    if #g.items > 1 then name = name .. " (" .. tostring(#g.items) .. ")" end
    local nx = x + T.px(2) + isz + T.px(8)
    local nstr = ZeD.CraftingCore and ZeD.CraftingCore.truncText(name, T.fontF2, math.max(T.px(20), rx - nx)) or name
    local tc = T.text
    card:drawText(nstr, nx, y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.border.a, col(T.border))
    return h
end

function def.body(card, x, y, w, t, player)
    local T, M = ZeD.T, ZeD.Molecules
    local s = t.s
    if not s then return 0 end
    local y0 = y
    -- the state: why it is blocked, else the last thing that happened (for a few seconds, as vanilla)
    if s:isBlocked() then
        y = y + UI.warn(card, x, y, w, s:blockText()) + T.px(10)
    else
        local f = s:flashText()
        if f then y = y + UI.note(card, x, y, w, f, nil) + T.px(10) end
    end
    -- the two offers: side by side on the full card, theirs over yours on a narrow one
    if w >= T.px(400) then
        local gap = T.px(16)
        local cw = math.floor((w - gap) / 2)
        local hl = offerColumn(card, x, y, cw, s, true)
        local hr = offerColumn(card, x + cw + gap, y, w - cw - gap, s, false)
        y = y + math.max(hl, hr) + T.px(12)
    else
        y = y + offerColumn(card, x, y, w, s, false) + T.px(12)
        y = y + offerColumn(card, x, y, w, s, true) + T.px(12)
    end
    -- your main inventory, to add from
    local groups = s.groups or {}
    y = y + head(card, x, y, w, ZeD.tr("UI_ZeD_Trade_MainInventory"), tostring(#groups)) + T.px(6)
    if #groups == 0 then
        y = y + M.drawEmptyLine(card, x + T.px(8), y, w - T.px(8), ZeD.tr("UI_ZeD_Trade_EmptyInv")) + T.px(4)
    else
        local why = addWhy(s)
        for _, g in ipairs(groups) do y = y + groupRow(card, x, y, w, s, g, why) end
    end
    -- the trade log, newest first
    if #s.log > 0 then
        y = y + T.px(12)
        y = y + head(card, x, y, w, getText("IGUI_TradingUI_Historical"), nil) + T.px(6)
        for i = #s.log, 1, -1 do
            local m = s.log[i]
            local mark = (m.add and T.positive) or (m.remove and T.warning) or nil
            y = y + UI.note(card, x + T.px(8), y, w - T.px(8), m.message, mark) + T.px(4)
        end
    end
    return y - y0
end

OC.register(def)
print("[ZeD] ObjectCardTrade: trade card loaded")
return def
