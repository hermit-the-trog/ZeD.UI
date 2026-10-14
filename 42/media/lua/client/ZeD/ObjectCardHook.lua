-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardHook.lua
-- ============================================================================
-- OBJECT CARD: BUTCHER HOOK (HOOK_MAP row 22; mockup zed_animal_cards_v1.html)
-- Vanilla's Butcher Hook window becomes a work card in the World window's
-- card drawer:
--   * empty hook: DEAD ANIMALS NEARBY (within 2 tiles of you or carried) with
--     HANG; the ones the hook does not take say so in vanilla's words;
--   * a carcass: vanilla's 3D figure (an ISCharacterScreenAvatar child of the
--     card, as the vanilla window builds it) beside LEATHER / BLOOD / HEAD /
--     MEAT, each with GATHER; BLOOD gathers into a container picked under
--     COLLECT INTO or BLEEDs onto the ground; a progress band while you work
--     (STOP for your own actions); REMOVE CORPSE; the knife as the NEEDS line.
-- Vanilla's butchering actions talk to their window ("luaHook": doingAction,
-- actionText, updateProgressBar, updateCorpseDatas, onAddedCorpse,
-- onClickRemoveCorpse, resetCorpse, getBuckets; Java calls back through
-- ISButcherHookUI.onStopBleedingAnimal / onHookReceivedNetUpdate). The card
-- hands them a small bridge with exactly that surface. Closes past 4 tiles.
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local function txt(k, fb, arg)
    if arg ~= nil then
        local s = getTextOrNull and getTextOrNull(k)
        return s and getText(k, arg) or ((fb or k) .. " " .. tostring(arg))
    end
    local s = getTextOrNull and getTextOrNull(k)
    return s or fb or k
end
local function col(c) return c.r, c.g, c.b end
local function notBroken(item) return not item:isBroken() end
local function L(v) return string.format("%.2f L", v or 0) end

local AV_W, AV_H, PART_H = 118, 176, 30

-- ---------------------------------------------------------------------------
-- The bridge: what vanilla's actions expect of their window
-- ---------------------------------------------------------------------------
ZeD_HookBridge = ZeD_HookBridge or {}
local Bridge = ZeD_HookBridge
Bridge.__index = Bridge

function Bridge.new(hook, chr)
    local o = setmetatable({}, Bridge)
    o.hook, o.chr, o.playerNum = hook, chr, chr:getPlayerNum()
    o.doingAction, o.actionText = false, nil
    o.progressBar = { progress = 0 }   -- Java's onStopBleedingAnimal zeroes this
    o.animal3D = hook:getAnimal()
    o.avatarDirty = true
    o:updateCorpseDatas()
    return o
end

function Bridge:updateProgressBar(p) self.progressBar.progress = p or 0 end

function Bridge:updateCorpseDatas()
    -- fills leather / blood / head / meat; removes a finished carcass
    if ButcheringUtil.updateCorpseDatas(self, self.hook:getAnimal(), self.hook) then
        if self.hook:isRemovingBlood() then
            self.doingAction = true
            self.actionText = txt("IGUI_ButcherHook_Bleed", "Bleed")
        end
    end
end

function Bridge:onAddedCorpse(corpse)
    if not corpse then return end
    ButcheringUtil.onAddedCorpseOnHook(self.hook, corpse, self.chr)
    self.animal3D = self.hook:getAnimal()
    self.avatarDirty = true
    self:updateCorpseDatas()
    return corpse
end

function Bridge:onClickRemoveCorpse()
    local a = self.hook:getAnimal()
    if not a then return end
    local body = ButcheringUtil.onRemoveCorpseFromHook(self.hook, a)
    self.animal3D = nil
    self.avatarDirty = true
    self:updateCorpseDatas()
    return body
end

function Bridge:resetCorpse()
    self.animal3D = self.hook:getAnimal()
    self.avatarDirty = true
    self:updateCorpseDatas()
    if self.animal3D then self.hook:updateAnimalModel() end
end

function Bridge:getBuckets() return ButcheringUtil.getBuckets(self.chr) end

-- ---------------------------------------------------------------------------
-- KIND
-- ---------------------------------------------------------------------------
local def = { id = "hook", leash = 4 }

local function hookOf(o)
    if o and instanceof(o, "IsoButcherHook") then return o end
    return nil
end

function def.resolve(player, obj)
    local h = hookOf(obj)
    if not (h and h:getSquare()) then return nil end
    local t = { obj = h, sq = h:getSquare(), key = OC.keyOf(h:getSquare(), "hook") }
    t.bridge = Bridge.new(h, player)
    h:setLuaHook(t.bridge)
    return t
end

function def.valid(t)
    local h = t.obj
    return h ~= nil and h:getSquare() ~= nil and call(h, "isExistInTheWorld") ~= false
end

function def.nearby(player)
    local out = {}
    OC.eachSquare(player, def.leash + 1, function(sq)
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local h = hookOf(objs:get(i))
            if h then
                local t = { obj = h, sq = h:getSquare(), key = OC.keyOf(h:getSquare(), "hook") }
                out[#out + 1] = t
            end
        end
    end)
    return OC.sortTargets(out)
end

-- vanilla's rules for what the hook takes
local function corpseValid(c)
    local md = c and c:getModData()
    if not md then return false end
    if instanceof(c, "Food") and c:isFrozen() then return false end
    local adef = AnimalAvatarDefinition and AnimalAvatarDefinition[md["AnimalType"]]
    if not (adef and adef.hook) then return false end
    if (md["animalSize"] or 0) < 0.4 then return false end
    return not md["skeleton"]
end

local function corpsesNear(player)
    local out = {}
    local inv = player:getInventory():FindAll("CorpseAnimal")
    if inv then for i = 0, inv:size() - 1 do out[#out + 1] = { c = inv:get(i), where = OC.whereOf(inv:get(i), player) } end end
    local sq0 = player:getCurrentSquare()
    if sq0 then
        local r = 2
        for x = sq0:getX() - r, sq0:getX() + r do
            for y = sq0:getY() - r, sq0:getY() + r do
                local sq = getCell():getGridSquare(x, y, sq0:getZ())
                local list = sq and sq:getStaticMovingObjects()
                if list then
                    for i = 0, list:size() - 1 do
                        local o = list:get(i)
                        if instanceof(o, "IsoDeadBody") and o:isAnimal() then
                            local n = math.floor(OC.squareDist(player, sq) + 0.5)
                            out[#out + 1] = { c = o, where = "GROUND " .. DOT .. " " .. n .. (n == 1 and " TILE" or " TILES") }
                        end
                    end
                end
            end
        end
    end
    for _, r in ipairs(out) do
        local c = r.c
        if instanceof(c, "InventoryItem") then
            r.name = c:getDisplayName()
            r.tex = call(c, "getTex")
        else
            r.name = c:isAnimalSkeleton() and txt("IGUI_Item_AnimalSkeleton", "Skeleton", c:getCustomName()) or txt("IGUI_Item_AnimalCorpse", "Dead animal", c:getCustomName())
            local ic = call(c, "getInvIcon")
            r.tex = ic and getTexture(ic) or nil
        end
        r.valid = corpseValid(c)
    end
    return out
end

-- ---------------------------------------------------------------------------
-- ACTIONS (vanilla's, queued as ISButcherHookUI queues them)
-- ---------------------------------------------------------------------------
local function near(p, t) return luautils.walkAdj(p, t.obj:getSquare(), false) end
local function equipKnife(p, t) ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), t.d.knife, true) end

local function hang(p, t, corpse)
    if near(p, t) then ISTimedActionQueue.add(ISPutAnimalOnHook:new(p, corpse, t.obj, t.bridge)) end
end
local function removeCorpse(p, t)
    if near(p, t) then ISTimedActionQueue.add(ISRemoveAnimalFromHook:new(p, t.obj:getAnimal(), t.obj, t.bridge)) end
end
local function gather(p, t, part)
    if not near(p, t) then return end
    equipKnife(p, t)
    local a, h = t.obj:getAnimal(), t.obj
    if part == "leather" then ISTimedActionQueue.add(ISRemoveLeatherFromAnimal:new(p, a, h, t.bridge))
    elseif part == "head" then ISTimedActionQueue.add(ISRemoveHeadFromAnimal:new(p, a, h, t.bridge))
    elseif part == "meat" then ISTimedActionQueue.add(ISRemoveMeatFromAnimal:new(p, a, h, t.bridge)) end
end
local function bleed(p, t, bucket)
    if not near(p, t) then return end
    equipKnife(p, t)
    local a, h = t.obj:getAnimal(), t.obj
    ISTimedActionQueue.add(ISCutAnimalOnHook:new(p, a, h, t.bridge, bucket))
    if bucket then ISTimedActionQueue.add(ISGatherBloodFromAnimal:new(p, a, h, t.bridge, bucket)) end
end

-- the running action of ours, for STOP
local function currentAction(p)
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local a = q and q.queue and q.queue[1]
    if a and a.luaHook then return a end
    return nil
end

-- ---------------------------------------------------------------------------
-- REFRESH
-- ---------------------------------------------------------------------------
local function carcassName(a)
    local ok, n = pcall(function() return ButcheringUtil.getCarcassName(a) end)
    if ok and n and n ~= "" then return n end
    local cn = call(a, "getCustomName")
    return txt("IGUI_Item_AnimalCorpse", "Dead animal", (cn and cn ~= "") and cn or (call(a, "getFullName") or ""))
end

function def.refresh(t, player)
    local h, br = t.obj, t.bridge
    if not br then
        br = Bridge.new(h, player)
        t.bridge = br
        h:setLuaHook(br)
    end
    br.chr = player
    -- another player or split screen may have changed the hook
    if h:getAnimal() ~= br.animal3D then
        br.animal3D = h:getAnimal()
        br.avatarDirty = true
        br:updateCorpseDatas()
    end
    local d = {}
    d.animal = h:getAnimal()
    d.name = d.animal and carcassName(d.animal) or txt("ContextMenu_ButcherHook", "Butcher Hook")
    d.knife = player:getInventory():getFirstTagEvalRecurse(ItemTag.BUTCHER_ANIMAL, notBroken)
    d.bleeding = h:isRemovingBlood() == true
    d.user = h:getUsingPlayer()
    d.inUse = d.user ~= nil and d.user ~= player
    d.busy = (br.doingAction == true) or d.inUse
    d.skill = player:getPerkLevel(Perks.Butchering)
    local buckets = br:getBuckets()
    d.buckets = {}
    if buckets then
        for i = 0, buckets:size() - 1 do
            local b = buckets:get(i)
            local fc = b:getFluidContainer()
            d.buckets[#d.buckets + 1] = { item = b, tex = call(b, "getTex"), name = b:getDisplayName(),
                where = OC.whereOf(b, player) .. " " .. DOT .. " " .. string.format("%.1f / %.1f L", fc:getAmount(), fc:getCapacity()) }
        end
    end
    if not d.animal then d.corpses = corpsesNear(player) end
    t.d = d

    local verbs, needs = {}, {}
    if d.animal then
        verbs[#verbs + 1] = { id = "remove", label = string.upper(txt("IGUI_ButcherHook_RemoveCorpse", "Remove Corpse")),
            enabled = not d.busy, run = function(p, tt) removeCorpse(p, tt) end }
        if not d.knife then needs[#needs + 1] = txt("Tooltip_Animal_NoKnifeButcher", "Need a Knife.") end
    else
        verbs[#verbs + 1] = { id = "add", label = string.upper(txt("ContextMenu_AddCorpse", "Add Corpse")), primary = true,
            enabled = not d.busy and d.corpses and #d.corpses > 0, jump = "hook:hang:1" }
    end
    if d.inUse then needs[#needs + 1] = "Someone else is using the hook." end
    t.verbs, t.needs = verbs, needs
end

function def.title(t) return t.d and t.d.name or txt("ContextMenu_ButcherHook", "Butcher Hook") end
function def.icon(t)
    local d = t.d
    local a = d and d.animal
    if a and ZeD.AnimalsData then return getTexture(ZeD.AnimalsData.resolvePortrait(a)) end
    return OC.spriteIcon(t.obj)
end
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.inUse then return "IN USE", T.warning end
    if not d.animal then return "EMPTY", T.textDim end
    if d.bleeding then return "BLEEDING", T.warning end
    return "ON THE HOOK", T.positive
end

-- the card goes: the hook stops reporting to it, the figure goes with it
function def.onClose(t, card)
    if t.obj then pcall(function() t.obj:setLuaHook(nil) end) end
    if card and card._hookAvatar then
        pcall(function() card._hookAvatar:setVisible(false); card:removeChild(card._hookAvatar) end)
        card._hookAvatar = nil
    end
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
-- vanilla's 3D carcass (ISButcherHookUI:setAnimalAvatar), rebuilt when the
-- carcass changes, kept inside the card's view
local function placeAvatar(card, t, x, y, w, h)
    local br = t.bridge
    local a = t.obj:getAnimal()
    local av = card._hookAvatar
    if br.avatarDirty or (av and av._zedAnimal ~= a) then
        if av then pcall(function() av:setVisible(false); card:removeChild(av) end) end
        card._hookAvatar, av = nil, nil
        br.avatarDirty = false
        if a then
            local md = a:getModData()
            local adef = AnimalAvatarDefinition and AnimalAvatarDefinition[md["AnimalType"]]
            if adef then
                local ok, made = pcall(function()
                    local p = ISCharacterScreenAvatar:new(x, y, w, h)
                    card:addChild(p)
                    a:setHook(t.obj)
                    p:setZoom(adef.butcherHookZoom)
                    p:setXOffset(adef.butcherHookXoffset)
                    p:setYOffset(adef.butcherHookYoffset)
                    a:setVariable("onhook", true)
                    p:setState("idle")
                    p:setVariable("onhook", true)
                    p:setDirection(IsoDirections.NE)
                    p:setIsometric(false)
                    p:setAnimSetName(a:GetAnimSetName())
                    p:setCharacter(a)
                    p._zedAnimal = a
                    return p
                end)
                if ok then card._hookAvatar, av = made, made
                else print("[ZeD] ObjectCardHook: carcass figure failed: " .. tostring(made)) end
            end
        end
    end
    if av then
        av:setX(x); av:setY(y)
        local vy, vh = card._viewY or 0, card._viewH or card:getHeight()
        av:setVisible(y >= vy and y + h <= vy + vh)
    end
end

local function drawBand(card, x, y, w, t)
    local T, tm = ZeD.T, ZeD.TM
    local br = t.bridge
    local ac = T.accent
    local h = T.px(32)
    card:drawRect(x, y, w, h, 0.10, col(ac))
    card:drawRectBorder(x, y, w, h, 1, col(ac))
    local f1, f3 = T.fontF1, T.fontF3
    local lbl = string.upper(br.actionText or txt("IGUI_ButcherHook_Bleed", "Bleed"))
    if t.d.bleeding and not currentAction(card:player()) then lbl = "BLEEDING ONTO THE GROUND" end
    card:drawText(lbl, x + T.px(8), y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local p = math.max(0, math.min(1, br.progressBar.progress or 0))
    local rx = x + w - T.px(6)
    local act = currentAction(card:player())
    if act then
        local bw = UI.buttonW("STOP")
        rx = rx - bw
        local fid = "hook:stop"
        UI.button(card, rx, y + math.floor((h - T.px(20)) / 2), "STOP", { h = T.px(20), focused = card._fid == fid })
        card:zone({ fid = fid, x = rx, y = y + math.floor((h - T.px(20)) / 2), w = bw, h = T.px(20), body = true,
            run = function() pcall(function() act:forceStop() end) end })
        rx = rx - T.px(10)
    end
    local pct = tostring(math.floor(p * 100 + 0.5)) .. "%"
    local pw = tm:MeasureStringX(f3, pct)
    card:drawText(pct, rx - pw, y + math.floor((h - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f3)
    local bx0 = x + T.px(8) + tm:MeasureStringX(f1, lbl) + T.px(10)
    local bw0 = rx - pw - T.px(10) - bx0
    if bw0 > T.px(20) then
        local by = y + math.floor((h - T.px(8)) / 2)
        card:drawRect(bx0, by, bw0, T.px(8), 1, col(T.surf1))
        card:drawRect(bx0, by, math.floor(bw0 * p), T.px(8), 1, col(ac))
        card:drawRectBorder(bx0, by, bw0, T.px(8), T.borderS.a or 1, col(T.borderS))
    end
    return h
end

local function partRow(card, x, y, w, label, value, have, button, fid, enabled, run)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(PART_H)
    local dy = y + math.floor((h - T.px(7)) / 2)
    if have then ZeD.Atoms.drawStatusDot(card, x + T.px(2), dy, T.positive, T.px(7))
    else ZeD.Atoms.drawStatusRing(card, x + T.px(2), dy, T.textDim, T.px(7)) end
    local f1, f3 = T.fontF1, T.fontF3
    local ac = T.accent
    card:drawText(label, x + T.px(16), y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local vc = have and T.text or T.textDim
    card:drawText(value, x + T.px(84), y + math.floor((h - tm:getFontHeight(f3)) / 2), vc.r, vc.g, vc.b, vc.a or 1, f3)
    if button then
        local bw = math.max(T.px(58), UI.buttonW(button))
        local bx = x + w - bw
        local by = y + math.floor((h - T.px(20)) / 2)
        UI.button(card, bx, by, button, { h = T.px(20), w = bw, disabled = not enabled, focused = card._fid == fid })
        card:zone({ fid = fid, x = bx, y = by, w = bw, h = T.px(20), body = true, run = enabled and run or nil })
    end
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.border.a or 1, col(T.border))
    return h
end

function def.body(card, x, y, w, t, player)
    local T, tm = ZeD.T, ZeD.TM
    local d, br = t.d, t.bridge
    if not (d and br and def.valid(t)) then return 0 end
    local y0 = y
    local gap = T.px(8)

    if not d.animal then
        if card._hookAvatar then def.onClose({ obj = nil }, card) end
        if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + gap end
        y = y + UI.section(card, x, y, w, "DEAD ANIMALS NEARBY", "WITHIN 2 TILES OR CARRIED")
        local anyBad = false
        for i, r in ipairs(d.corpses or {}) do
            local rr = r
            if not r.valid then anyBad = true end
            y = y + UI.pick(card, x, y, w, { tex = r.tex, name = r.name, where = r.where, button = "HANG",
                tag = (not r.valid) and "NOT FOR THE HOOK" or nil, tagC = T.danger,
                fid = "hook:hang:" .. i, enabled = r.valid and not d.busy,
                run = function(c, p) hang(p, t, rr.c) end })
        end
        if #(d.corpses or {}) == 0 then
            y = y + T.px(4)
            y = y + UI.para(card, x + T.px(2), y, w, txt("IGUI_ButcherHook_NoAnimalFound", "No animal corpse found."), T.text)
            y = y + UI.para(card, x + T.px(2), y, w, txt("Tooltip_ButcherUI_AddAnimalCorpse", "The dead animal can be near the Hook or in your inventory."), T.textDim)
        elseif anyBad then
            y = y + T.px(4)
            y = y + UI.needs(card, x, y, w, { txt("Tooltip_ButcherUI_CantAddThis", "Not a valid dead animal for the Butcher Hook.") })
        end
        return y - y0
    end

    -- working: the band
    if br.doingAction or d.bleeding then y = y + drawBand(card, x, y, w, t) + gap end
    if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + gap end

    -- the carcass and its parts
    local aw, ah = T.px(AV_W), T.px(AV_H)
    card:drawRect(x, y, aw, ah, 1, col(T.surf2))
    card:drawRectBorder(x, y, aw, ah, T.borderS.a or 1, col(T.borderS))
    placeAvatar(card, t, x + T.px(1), y + T.px(1), aw - T.px(2), ah - T.px(2))
    local px = x + aw + T.px(12)
    local pw = w - aw - T.px(12)
    local py = y
    local can = d.knife ~= nil and not d.busy
    local blood = br.blood or 0
    local hasBuckets = #d.buckets > 0
    py = py + partRow(card, px, py, pw, string.upper(string.gsub(txt("IGUI_ButcherHook_Leather", "Leather:"), ":%s*$", "")),
        br.leather and txt("IGUI_Yes", "Yes") or "Taken", br.leather, string.upper(txt("IGUI_ButcherHook_Gather", "Gather")), "hook:leather",
        can and br.leather ~= nil, function(c, p) gather(p, t, "leather") end)
    -- blood: while vanilla bleeds it out you may still switch to a container
    local bloodOK = d.knife ~= nil and blood > 0 and (not d.busy or (d.bleeding and hasBuckets and not d.inUse and not currentAction(player)))
    local bloodBtn = hasBuckets and string.upper(txt("IGUI_ButcherHook_Gather", "Gather")) or string.upper(txt("IGUI_ButcherHook_Bleed", "Bleed"))
    py = py + partRow(card, px, py, pw, string.upper(string.gsub(txt("IGUI_ButcherHook_Blood", "Blood:"), ":%s*$", "")),
        blood > 0 and L(blood) or txt("IGUI_No", "No"), blood > 0, bloodBtn, "hook:blood", bloodOK,
        function(c, p)
            if hasBuckets then
                card._jumpTo, card._pendingFocus = "hook:into:1", "hook:into:1"
            else
                bleed(p, t, nil)
            end
        end)
    py = py + partRow(card, px, py, pw, string.upper(string.gsub(txt("IGUI_ButcherHook_Head", "Head:"), ":%s*$", "")),
        br.head and txt("IGUI_Yes", "Yes") or "Taken", br.head, string.upper(txt("IGUI_ButcherHook_Gather", "Gather")), "hook:head",
        can and br.head == true, function(c, p) gather(p, t, "head") end)
    py = py + partRow(card, px, py, pw, string.upper(string.gsub(txt("IGUI_ButcherHook_Meat", "Meat:"), ":%s*$", "")),
        br.meat and txt("IGUI_Yes", "Yes") or "Taken", br.meat ~= nil, string.upper(txt("IGUI_ButcherHook_Gather", "Gather")), "hook:meat",
        can and br.meat ~= nil, function(c, p) gather(p, t, "meat") end)
    py = py + T.px(6)
    py = py + UI.pair(card, px, py, pw, "KNIFE", d.knife and d.knife:getDisplayName() or "None")
    py = py + UI.pair(card, px, py, pw, "BUTCHERING", tostring(d.skill))
    y = math.max(y + ah, py) + gap

    -- the consequence vanilla does silently
    if blood > 0 and (br.meat or br.head) then
        local msg = br.meat and ("Taking the meat now loses the " .. L(blood) .. " of blood still in it; the head splashes it.")
            or ("Taking the head now splashes the " .. L(blood) .. " of blood still in it.")
        y = y + UI.needs(card, x, y, w, { msg }) + gap
    end

    -- where the blood goes
    if blood > 0 then
        y = y + UI.section(card, x, y, w, "COLLECT INTO", string.upper(string.gsub(txt("IGUI_ButcherHook_Blood", "Blood:"), ":%s*$", "")))
        local intoOK = d.knife ~= nil and (not d.busy or (d.bleeding and not d.inUse and not currentAction(player)))
        for i, b in ipairs(d.buckets) do
            local bb = b
            y = y + UI.pick(card, x, y, w, { tex = b.tex, name = b.name, where = b.where, button = "INTO",
                fid = "hook:into:" .. i, enabled = intoOK, run = function(c, p) bleed(p, t, bb.item) end })
        end
        y = y + UI.pick(card, x, y, w, { name = txt("IGUI_None", "None"), where = "BLEED ONTO THE GROUND",
            button = string.upper(txt("IGUI_ButcherHook_Bleed", "Bleed")), fid = "hook:bleed",
            enabled = d.knife ~= nil and not d.busy, run = function(c, p) bleed(p, t, nil) end })
    end
    return y - y0
end

OC.register(def)
print("[ZeD] ObjectCardHook: butcher hook card loaded")
return def
